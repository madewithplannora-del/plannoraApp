const crypto = require("crypto");
const mongoose = require("mongoose");

const requestModel = require("../models/request.model");
const freelancerModel = require("../models/freelancer.model");
const requestProgressModel = require("../models/requestProgress.model");
const freelancerProgressModel = require("../models/freelancerProgress.model");
const waitlistModel = require("../models/waitlist.model");
const {
    ACCEPT_CUTOFF_DAYS,
    LIST_LOCK_DAYS,
    ATTENDANCE_OPEN_BEFORE_MIN,
    MS_PER_DAY,
    getEventStart,
    getEventEnd,
    getAcceptDeadline,
    getListLockDeadline,
    canFreelancerAccept,
    canCustomerModifyList,
    hasEventEnded,
    getAcceptDeadlineMessage,
    getListLockMessage,
} = require("../utils/requestRules");

function fail(res, status, message) {
    return res.status(status).json({ success: false, message });
}

function idString(id) {
    return id === undefined || id === null ? "" : id.toString();
}

function hasId(list, id) {
    const target = idString(id);
    return (list || []).some((x) => idString(x) === target);
}

// Resolve logged-in freelancer from req.user, cookie, or Authorization header
async function resolveFreelancer(req) {
    let userId = req.user && (req.user.id || req.user._id || req.user.userId);

    if (!userId) {
        const token = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);
        if (token) {
            try {
                const jwt = require("jsonwebtoken");
                const decoded = jwt.verify(token, process.env.JWT_KEY);
                userId = decoded?.id;
            } catch (e) {
                return null;
            }
        }
    }

    if (!userId) return null;

    return freelancerModel.findOne({ userId }).select("_id").lean();
}

/*
    Compare a submitted code against the SHA-256 hash stored on the request.
    createRequest stores the hash of the code it showed the customer, so the
    same hashing is applied to the freelancer's input before comparing.
*/
function codesMatch(a, storedHash) {
    if (!storedHash) return false;

    const submittedHash = crypto
        .createHash("sha256")
        .update(String(a))
        .digest("hex");

    const x = Buffer.from(submittedHash);
    const y = Buffer.from(String(storedHash));

    return x.length === y.length && crypto.timingSafeEqual(x, y);
}

/*
    POST /:requestId/accept
    Rules:
      - request must have been sent to this freelancer
      - not allowed once the event is within ACCEPT_CUTOFF_DAYS days (1-2 days)
      - not allowed once no_of_candidates freelancers have already accepted
      - if slots full, add to waitlist for future notifications
*/
async function acceptRequest(req, res) {
    try {
        const { requestId } = req.params;

        if (!mongoose.isValidObjectId(requestId)) return fail(res, 400, "Invalid request id");

        const freelancer = await resolveFreelancer(req);
        if (!freelancer) return fail(res, 403, "Only freelancers can accept requests");

        const request = await requestModel
            .findById(requestId)
            .select("start_time date end_time no_of_candidates createdAt")
            .lean();

        if (!request) return fail(res, 404, "Request not found");

        const now = new Date();
        const end = getEventEnd(request);

        if (end && end <= now) return fail(res, 410, "This event has already ended");

        // Check if within cutoff period (1-2 days before event)
        if (!canFreelancerAccept(request, now)) {
            const deadline = getAcceptDeadline(request);
            return fail(
                res,
                403,
                `Cannot accept: requests cannot be accepted within ${ACCEPT_CUTOFF_DAYS} days of the event. Deadline was ${deadline.toLocaleString()}`
            );
        }

        const freelancerId = freelancer._id;

        const updated = await requestProgressModel.findOneAndUpdate(
            {
                requestId,
                sent: freelancerId,
                accepted: { $ne: freelancerId },
                rejected: { $ne: freelancerId },
                $expr: {
                    $lt: [{ $size: { $ifNull: ["$accepted", []] } }, request.no_of_candidates],
                },
            },
            { $addToSet: { accepted: freelancerId } },
            { new: true }
        );

        if (!updated) {
            const p = await requestProgressModel.findOne({ requestId }).lean();

            if (!p || !hasId(p.sent, freelancerId)) {
                return fail(res, 403, "This request was not sent to you");
            }
            if (hasId(p.accepted, freelancerId)) return fail(res, 409, "You already accepted this request");
            if (hasId(p.rejected, freelancerId)) return fail(res, 409, "You already rejected (or missed the deadline for) this request");
            
            if ((p.accepted || []).length >= request.no_of_candidates) {
                // Slots full - add to waitlist
                try {
                    const existingWaitlist = await waitlistModel.findOne({
                        requestId,
                        freelancerId
                    });

                    if (!existingWaitlist) {
                        await waitlistModel.create({
                            requestId,
                            freelancerId,
                            attemptedAt: now
                        });
                    }

                    return fail(
                        res,
                        409,
                        `All ${request.no_of_candidates} slots filled. You've been added to the waitlist. We'll notify you if a slot becomes available.`
                    );
                } catch (error) {
                    console.error("Error adding to waitlist:", error);
                    return fail(res, 409, "All slots filled. Could not add to waitlist.");
                }
            }

            return fail(res, 409, "Could not accept the request, please try again");
        }

        try {
            await freelancerProgressModel.updateOne(
                { freelancerId },
                { $addToSet: { accepted: requestId } },
                { upsert: true, setDefaultsOnInsert: true }
            );

            // Remove from waitlist if they were on it
            await waitlistModel.deleteOne({ requestId, freelancerId });
        } catch (error) {
            // keep both sides consistent
            await requestProgressModel
                .updateOne({ requestId }, { $pull: { accepted: freelancerId } })
                .catch((e) => console.error("acceptRequest: rollback failed", e));

            throw error;
        }

        const acceptedCount = updated.accepted.length;

        return res.status(200).json({
            success: true,
            message: "Request accepted",
            accepted_count: acceptedCount,
            no_of_candidates: request.no_of_candidates,
            slots_left: Math.max(request.no_of_candidates - acceptedCount, 0),
        });
    } catch (error) {
        console.error("acceptRequest error", error);
        return fail(res, 500, "Server error");
    }
}

/*
    POST /:requestId/reject
    Only works on a request that was sent to you and that you have not accepted yet.
*/
async function rejectRequest(req, res) {
    try {
        const { requestId } = req.params;

        if (!mongoose.isValidObjectId(requestId)) return fail(res, 400, "Invalid request id");

        const freelancer = await resolveFreelancer(req);
        if (!freelancer) return fail(res, 403, "Only freelancers can reject requests");

        const request = await requestModel.findById(requestId).select("end_time").lean();
        if (!request) return fail(res, 404, "Request not found");

        const end = getEventEnd(request);
        if (end && end <= new Date()) return fail(res, 410, "This event has already ended");

        const freelancerId = freelancer._id;

        const updated = await requestProgressModel.findOneAndUpdate(
            {
                requestId,
                sent: freelancerId,
                accepted: { $ne: freelancerId },
                rejected: { $ne: freelancerId },
            },
            { $addToSet: { rejected: freelancerId } },
            { new: true }
        );

        if (!updated) {
            const p = await requestProgressModel.findOne({ requestId }).lean();

            if (!p || !hasId(p.sent, freelancerId)) {
                return fail(res, 403, "This request was not sent to you");
            }
            if (hasId(p.accepted, freelancerId)) {
                return fail(res, 409, "You already accepted this request and cannot reject it now");
            }
            if (hasId(p.rejected, freelancerId)) return fail(res, 409, "You already rejected this request");

            return fail(res, 409, "Could not reject the request, please try again");
        }

        try {
            await freelancerProgressModel.updateOne(
                { freelancerId },
                { $addToSet: { rejected: requestId } },
                { upsert: true, setDefaultsOnInsert: true }
            );
        } catch (error) {
            await requestProgressModel
                .updateOne({ requestId }, { $pull: { rejected: freelancerId } })
                .catch((e) => console.error("rejectRequest: rollback failed", e));

            throw error;
        }

        return res.status(200).json({ success: true, message: "Request rejected" });
    } catch (error) {
        console.error("rejectRequest error", error);
        return fail(res, 500, "Server error");
    }
}

/*
    POST /:requestId/attendance   body: { "code": "123456" }
    The customer gives the attendance code at the event. A correct code, entered by a freelancer
    who accepted the request, inside the event window, adds the request to freelancerprogress.attended.
*/
async function submitAttendance(req, res) {
    try {
        const { requestId } = req.params;
        const code = req.body && req.body.code !== undefined ? String(req.body.code).trim() : "";

        if (!mongoose.isValidObjectId(requestId)) return fail(res, 400, "Invalid request id");
        if (!code) return fail(res, 400, "Attendance code is required");

        const freelancer = await resolveFreelancer(req);
        if (!freelancer) return fail(res, 403, "Only freelancers can mark attendance");

        const request = await requestModel
            .findById(requestId)
            .select("+completion_code_hash start_time date end_time")
            .lean();

        if (!request) return fail(res, 404, "Request not found");
        if (!request.completion_code_hash) return fail(res, 409, "No attendance code is set for this event");

        const freelancerId = freelancer._id;

        const p = await requestProgressModel.findOne({ requestId }).lean();

        if (!p || !hasId(p.accepted, freelancerId)) {
            return fail(res, 403, "You have not accepted this request");
        }

        const now = new Date();
        const start = getEventStart(request);
        const end = getEventEnd(request);

        if (start && now < new Date(start.getTime() - ATTENDANCE_OPEN_BEFORE_MIN * 60 * 1000)) {
            return fail(res, 403, "Attendance is not open yet");
        }
        if (end && now > end) {
            return fail(res, 403, "Attendance window is closed, this event has ended");
        }

        if (!codesMatch(code, request.completion_code_hash)) {
            return fail(res, 400, "Invalid attendance code");
        }

        const already = await freelancerProgressModel
            .findOne({ freelancerId, attended: requestId })
            .select("_id")
            .lean();

        if (already) return fail(res, 409, "Attendance already recorded");

        await freelancerProgressModel.updateOne(
            { freelancerId },
            { $addToSet: { attended: requestId }, $pull: { redflag: requestId } },
            { upsert: true, setDefaultsOnInsert: true }
        );

        return res.status(200).json({ success: true, message: "Attendance recorded" });
    } catch (error) {
        console.error("submitAttendance error", error);
        return fail(res, 500, "Server error");
    }
}

/*
    POST /:requestId/redflag   body: { "code": "123456" }
    A freelancer who accepted a request can enter the attendance code to mark it as redflag
    (they arrived but something went wrong or they didn't complete the work as expected).
*/
async function submitRedflag(req, res) {
    try {
        const { requestId } = req.params;
        const code = req.body && req.body.code !== undefined ? String(req.body.code).trim() : "";

        if (!mongoose.isValidObjectId(requestId)) return fail(res, 400, "Invalid request id");
        if (!code) return fail(res, 400, "Attendance code is required");

        const freelancer = await resolveFreelancer(req);
        if (!freelancer) return fail(res, 403, "Only freelancers can mark redflag");

        const request = await requestModel
            .findById(requestId)
            .select("+completion_code_hash start_time date end_time")
            .lean();

        if (!request) return fail(res, 404, "Request not found");
        if (!request.completion_code_hash) return fail(res, 409, "No attendance code is set for this event");

        const freelancerId = freelancer._id;

        const p = await requestProgressModel.findOne({ requestId }).lean();

        if (!p || !hasId(p.accepted, freelancerId)) {
            return fail(res, 403, "You have not accepted this request");
        }

        const now = new Date();
        const start = getEventStart(request);
        const end = getEventEnd(request);

        if (start && now < new Date(start.getTime() - ATTENDANCE_OPEN_BEFORE_MIN * 60 * 1000)) {
            return fail(res, 403, "Redflag window is not open yet");
        }
        if (end && now > end) {
            return fail(res, 403, "Redflag window is closed, this event has ended");
        }

        if (!codesMatch(code, request.completion_code_hash)) {
            return fail(res, 400, "Invalid attendance code");
        }

        const already = await freelancerProgressModel
            .findOne({ freelancerId, redflag: requestId })
            .select("_id")
            .lean();

        if (already) return fail(res, 409, "Redflag already recorded for this request");

        await freelancerProgressModel.updateOne(
            { freelancerId },
            { $addToSet: { redflag: requestId }, $pull: { attended: requestId } },
            { upsert: true, setDefaultsOnInsert: true }
        );

        return res.status(200).json({ success: true, message: "Redflag recorded" });
    } catch (error) {
        console.error("submitRedflag error", error);
        return fail(res, 500, "Server error");
    }
}

module.exports = { acceptRequest, rejectRequest, submitAttendance, submitRedflag };