const mongoose = require("mongoose");
const crypto = require("crypto");

const requestModel = require("../models/request.model");
const requestProgressModel = require("../models/requestProgress.model");
const freelancerProgressModel = require("../models/freelancerProgress.model");
const waitlistModel = require("../models/waitlist.model");
const { notifyWaitlistSlotAvailable } = require("../services/notification.service");
const {
    ACCEPT_CUTOFF_DAYS,
    MS_PER_DAY,
    getAcceptDeadline,
    getEventEnd,
} = require("../utils/requestRules");

// Re-notify a waitlisted freelancer if their earlier slot notification went
// unanswered for this long and the slot is still open.
const WAITLIST_RETRY_HOURS = 6;

const BATCH_LIMIT = 200;

function idStrings(list) {
    return (list || []).map((x) => x.toString());
}

/*
    Job 1 — auto-reject silence.
    Once a request's accept deadline (ACCEPT_CUTOFF_DAYS before event start)
    has passed, every freelancer who only has it in `sent` (never accepted or
    rejected) is moved to `rejected` + request.auto_rejected. Frees them up for
    re-matching on other requests and un-breaks the "sent" exclusion.
    Idempotent: guarded by deadline_rejection_processed.
*/
async function processDeadlineRejections(now) {
    // Requests whose accept deadline has passed: start_time <= now + cutoff
    const cutoff = new Date(now.getTime() + ACCEPT_CUTOFF_DAYS * MS_PER_DAY);

    const requests = await requestModel
        .find({ deadline_rejection_processed: false, start_time: { $lte: cutoff } })
        .select("start_time end_time auto_rejected")
        .limit(BATCH_LIMIT)
        .lean();

    let processed = 0;
    let autoRejected = 0;

    for (const request of requests) {
        const deadline = getAcceptDeadline(request);

        // Sanity: only act if the deadline truly passed (end verified via start_time filter)
        if (!deadline || deadline > now) continue;

        const progress = await requestProgressModel
            .findOne({ requestId: request._id })
            .select("sent accepted rejected")
            .lean();

        if (progress && progress.sent && progress.sent.length > 0) {
            const silent = new Set(idStrings(progress.sent));

            for (const id of idStrings(progress.accepted)) silent.delete(id);
            for (const id of idStrings(progress.rejected)) silent.delete(id);

            if (silent.size > 0) {
                const ids = [...silent].map(
                    (id) => new mongoose.Types.ObjectId(id)
                );

                await requestProgressModel.updateOne(
                    { requestId: request._id },
                    { $addToSet: { rejected: { $each: ids } } }
                );

                await freelancerProgressModel.updateMany(
                    { freelancerId: { $in: ids } },
                    { $addToSet: { rejected: request._id } }
                );

                await requestModel.updateOne(
                    { _id: request._id },
                    { $addToSet: { auto_rejected: { $each: ids } } }
                );

                autoRejected += ids.length;
            }
        }

        await requestModel.updateOne(
            { _id: request._id },
            { $set: { deadline_rejection_processed: true } }
        );

        processed++;
    }

    return { processed, autoRejected };
}

/*
    Job 2 — mark expired requests so the same finished request is not
    rescanned every tick forever. Atomic updateMany, naturally idempotent.
*/
async function processExpiry(now) {
    const result = await requestModel.updateMany(
        { expiry_handled: false, end_time: { $lte: now } },
        { $set: { expiry_handled: true } }
    );

    return { expired: result.modifiedCount || 0 };
}

/*
    Job 3 — waitlist re-notify.
    For each request where a slot is still open:
      1. Notify the first un-notified waitlister (mark them notified).
      2. If everyone was notified but the slot is STILL open (nobody acted),
         re-notify the oldest stale notification (older than RETRY window).
    Idempotent per tick: each pass either creates a new notification for the
    next person or updates one notifiedAt timestamp.
*/
async function processWaitlistReNotify(now) {
    const staleBefore = new Date(
        now.getTime() - WAITLIST_RETRY_HOURS * 60 * 60 * 1000
    );

    const staleEntries = await waitlistModel
        .find({ notified: true, notifiedAt: { $lt: staleBefore } })
        .select("requestId")
        .limit(BATCH_LIMIT)
        .lean();

    const requestIds = [...new Set(staleEntries.map((e) => e.requestId.toString()))];

    let notified = 0;

    for (const requestId of requestIds) {
        const request = await requestModel
            .findById(requestId)
            .select("no_of_candidates start_time end_time")
            .lean();

        if (!request) continue;

        const end = getEventEnd(request);
        if (end && end <= now) continue;

        const deadline = getAcceptDeadline(request);
        if (deadline && deadline <= now) continue;

        const progress = await requestProgressModel
            .findOne({ requestId })
            .select("accepted")
            .lean();

        if ((progress?.accepted || []).length >= request.no_of_candidates) continue;

        // 1. First un-notified waitlister gets the slot notice
        const next = await waitlistModel
            .findOne({ requestId, notified: false })
            .sort({ attemptedAt: 1 });

        if (next) {
            await waitlistModel.updateOne(
                { _id: next._id },
                { $set: { notified: true, notifiedAt: now } }
            );

            await notifyWaitlistSlotAvailable(requestId, next.freelancerId);
            notified++;
            continue;
        }

        // 2. All notified, slot still open: re-notify the oldest stale one
        const oldest = await waitlistModel
            .findOne({ requestId, notified: true, notifiedAt: { $lt: staleBefore } })
            .sort({ notifiedAt: 1 });

        if (oldest) {
            await waitlistModel.updateOne(
                { _id: oldest._id },
                { $set: { notifiedAt: now } }
            );

            await notifyWaitlistSlotAvailable(requestId, oldest.freelancerId);
            notified++;
        }
    }

    return { waitlistNotified: notified };
}

async function runAll(now = new Date()) {
    const results = {};

    try {
        results.deadlineRejections = await processDeadlineRejections(now);
    } catch (error) {
        console.error("[expiry-worker] processDeadlineRejections failed:", error);
        results.deadlineRejections = { error: error.message };
    }

    try {
        results.expiry = await processExpiry(now);
    } catch (error) {
        console.error("[expiry-worker] processExpiry failed:", error);
        results.expiry = { error: error.message };
    }

    try {
        results.waitlist = await processWaitlistReNotify(now);
    } catch (error) {
        console.error("[expiry-worker] processWaitlistReNotify failed:", error);
        results.waitlist = { error: error.message };
    }

    return results;
}

/*
    Run one pass every minute. Every job is idempotent, so running the worker
    in the server process AND via `npm run expiry-worker` does not double-apply
    anything; it just races harmlessly.
*/
function startExpiryWorker(intervalMs = 60 * 1000) {
    // Random id so log lines from different worker instances are distinguishable
    const instanceId = crypto.randomBytes(4).toString("hex");

    const tick = async () => {
        try {
            const results = await runAll(new Date());
            const summary = JSON.stringify(results);
            console.log(`[expiry-worker ${instanceId}] tick: ${summary}`);
        } catch (error) {
            console.error(`[expiry-worker ${instanceId}] tick failed:`, error);
        }
    };

    const handle = setInterval(tick, intervalMs);

    // Kick off the first pass immediately
    tick();

    return handle;
}

module.exports = { startExpiryWorker, runAll };

// Standalone mode: `npm run expiry-worker`
if (require.main === module) {
    require("dotenv").config();
    const dns = require("dns");
    dns.setServers(["8.8.8.8", "8.8.4.4"]);
    const ConnectDB = require("../db/db");

    (async () => {
        const connected = await ConnectDB();

        if (!connected) {
            console.error("Could not connect to the database, shutting down");
            process.exit(1);
        }

        startExpiryWorker();
        console.log("Expiry worker started");
    })();
}
