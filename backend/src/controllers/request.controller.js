const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const mongoose = require("mongoose");

const requestModel = require("../models/request.model");
const customerModel = require("../models/customer.model");
const requestProgressModel = require("../models/requestProgress.model");
const freelancerProgressModel = require("../models/freelancerProgress.model");
const waitlistModel = require("../models/waitlist.model");
const {
    notifyWaitlistSlotAvailable,
    notifyAllPendingAttendance
} = require("../services/notification.service");
const { sendRequestToAllFreelancers } = require("../utils/matchFreelancers");
const {
    canCustomerModifyList,
    getListLockMessage,
    hasEventEnded,
    getEventEnd,
} = require("../utils/requestRules");

// create request
const createRequest = async (req, res) => {
    try {
        const token = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);

        if (!token) {
            return res.status(401).json({ message: "Authentication required" });
        }

        let decoded;

        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({ message: "Invalid or expired token" });
        }

        if (!decoded.id || !mongoose.isValidObjectId(decoded.id)) {
            return res.status(401).json({ message: "Invalid token payload" });
        }

        const customer = await customerModel.findOne({ account: decoded.id });

        if (!customer) {
            return res.status(403).json({ message: "Customer profile not found" });
        }

        const {
            event_details,
            pay,
            city,
            pincode,
            state,
            location,
            category,
            time,
            start_time,
            end_time,
            no_of_candidates,
            date,
            additional_description
        } = req.body;

        if (
            !event_details ||
            pay === undefined ||
            !city ||
            !pincode ||
            !state ||
            !location ||
            !category ||
            !time ||
            !start_time ||
            !end_time ||
            !no_of_candidates ||
            !date
        ) {
            return res.status(400).json({ message: "Please provide all required fields" });
        }

        const startDate = new Date(start_time);
        const endDate = new Date(end_time);
        const eventDate = new Date(date);

        if (
            isNaN(startDate.getTime()) ||
            isNaN(endDate.getTime()) ||
            isNaN(eventDate.getTime())
        ) {
            return res.status(400).json({ message: "Invalid date or time value" });
        }

        if (endDate <= startDate) {
            return res.status(400).json({ message: "End time must be after start time" });
        }

        if (!Number.isFinite(Number(pay)) || Number(pay) < 0) {
            return res.status(400).json({ message: "Pay must be a valid non-negative number" });
        }

        if (
            !Number.isInteger(Number(no_of_candidates)) ||
            Number(no_of_candidates) < 1
        ) {
            return res.status(400).json({ message: "Number of candidates must be at least 1" });
        }

        if (!["Professional", "Cultural", "Private"].includes(category)) {
            return res.status(400).json({ message: "Invalid category" });
        }

        // generate a completion code and store only its hash
        const completionCode = crypto.randomInt(100000, 1000000).toString();
        const completionCodeHash = crypto
            .createHash("sha256")
            .update(completionCode)
            .digest("hex");

        const request = await requestModel.create({
            customer: customer._id,
            event_details,
            pay: Number(pay),
            city,
            pincode,
            state,
            location,
            category,
            time,
            start_time: startDate,
            end_time: endDate,
            no_of_candidates: Number(no_of_candidates),
            date: eventDate,
            additional_description: additional_description || "",
            completion_code_hash: completionCodeHash
        });

        customer.sent_request.addToSet(request._id);
        await customer.save();

        // ✅ Create requestProgress immediately when request is created
        await requestProgressModel.create({
            requestId: request._id,
            sent: [],
            accepted: [],
            rejected: []
        });

        // Fan out to ALL eligible freelancers in the background (idempotent:
        // already sent / accepted / rejected freelancers are skipped by the util).
        sendRequestToAllFreelancers(request._id)
            .then((result) => {
                console.log(`[createRequest] Sent request ${request._id} to ${result.sent.length} eligible freelancers`);
            })
            .catch((error) => {
                console.error("Background matching error for request", request._id, error);
            });

        return res.status(201).json({
            message: "Request created successfully",
            request: {
                _id: request._id,
                customer: request.customer,
                event_details: request.event_details,
                pay: request.pay,
                city: request.city,
                state: request.state,
                pincode: request.pincode,
                location: request.location,
                category: request.category,
                time: request.time,
                start_time: request.start_time,
                end_time: request.end_time,
                no_of_candidates: request.no_of_candidates,
                date: request.date,
                additional_description: request.additional_description,
                createdAt: request.createdAt,
                updatedAt: request.updatedAt
            },
            completion_code: completionCode
        });
    } catch (error) {
        console.error("Create request error:", error);
        return res.status(500).json({ message: "Error creating request" });
    }
};

// get all requests created by the logged-in customer
const getRequests = async (req, res) => {
    try {
        const token = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);

        if (!token) {
            return res.status(401).json({ message: "Authentication required" });
        }

        let decoded;

        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({ message: "Invalid or expired token" });
        }

        if (!decoded.id || !mongoose.isValidObjectId(decoded.id)) {
            return res.status(401).json({ message: "Invalid token payload" });
        }

        const customer = await customerModel.findOne({ account: decoded.id });

        if (!customer) {
            return res.status(403).json({ message: "Customer profile not found" });
        }

        const requests = await requestModel
            .find({ customer: customer._id })
            .sort({ createdAt: -1 });

        return res.status(200).json({
            message: "Requests fetched successfully",
            count: requests.length,
            requests
        });
    } catch (error) {
        console.error("Get requests error:", error);
        return res.status(500).json({ message: "Error fetching requests" });
    }
};

// get one request owned by the logged-in customer
const getRequestById = async (req, res) => {
    try {
        const token = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);

        if (!token) {
            return res.status(401).json({ message: "Authentication required" });
        }

        let decoded;

        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({ message: "Invalid or expired token" });
        }

        if (!decoded.id || !mongoose.isValidObjectId(decoded.id)) {
            return res.status(401).json({ message: "Invalid token payload" });
        }

        const customer = await customerModel.findOne({ account: decoded.id });

        if (!customer) {
            return res.status(403).json({ message: "Customer profile not found" });
        }

        if (!mongoose.isValidObjectId(req.params.id)) {
            return res.status(400).json({ message: "Invalid request ID" });
        }

        const request = await requestModel.findOne({
            _id: req.params.id,
            customer: customer._id
        });

        if (!request) {
            return res.status(404).json({ message: "Request not found" });
        }

        // Get the request progress with populated accepted freelancers
        const requestProgress = await requestProgressModel.findOne({
            requestId: req.params.id
        }).populate({
            path: "accepted",
            model: "freelancers",
            select: "_id freelancer_category linkedin phone_no profile_picture"
        });

        return res.status(200).json({
            message: "Request fetched successfully",
            request,
            acceptedFreelancers: requestProgress?.accepted || []
        });
    } catch (error) {
        console.error("Get request error:", error);
        return res.status(500).json({ message: "Error fetching request" });
    }
};

// update a request owned by the logged-in customer
const updateRequest = async (req, res) => {
    try {
        const token = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);

        if (!token) {
            return res.status(401).json({ message: "Authentication required" });
        }

        let decoded;

        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({ message: "Invalid or expired token" });
        }

        if (!decoded.id || !mongoose.isValidObjectId(decoded.id)) {
            return res.status(401).json({ message: "Invalid token payload" });
        }

        const customer = await customerModel.findOne({ account: decoded.id });

        if (!customer) {
            return res.status(403).json({ message: "Customer profile not found" });
        }

        if (!mongoose.isValidObjectId(req.params.id)) {
            return res.status(400).json({ message: "Invalid request ID" });
        }

        const allowedFields = [
            "event_details",
            "pay",
            "city",
            "pincode",
            "state",
            "location",
            "category",
            "time",
            "start_time",
            "end_time",
            "no_of_candidates",
            "date",
            "additional_description"
        ];

        const updates = {};

        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                updates[field] = req.body[field];
            }
        }

        if (Object.keys(updates).length === 0) {
            return res.status(400).json({ message: "No valid fields provided for update" });
        }

        if (updates.pay !== undefined) {
            updates.pay = Number(updates.pay);

            if (!Number.isFinite(updates.pay) || updates.pay < 0) {
                return res.status(400).json({ message: "Pay must be a valid non-negative number" });
            }
        }

        if (updates.no_of_candidates !== undefined) {
            updates.no_of_candidates = Number(updates.no_of_candidates);

            if (
                !Number.isInteger(updates.no_of_candidates) ||
                updates.no_of_candidates < 1
            ) {
                return res.status(400).json({ message: "Number of candidates must be at least 1" });
            }
        }

        for (const field of ["start_time", "end_time", "date"]) {
            if (updates[field] !== undefined) {
                updates[field] = new Date(updates[field]);

                if (isNaN(updates[field].getTime())) {
                    return res.status(400).json({ message: `Invalid ${field} value` });
                }
            }
        }

        if (
            updates.category !== undefined &&
            !["Professional", "Cultural", "Private"].includes(updates.category)
        ) {
            return res.status(400).json({ message: "Invalid category" });
        }

        const existingRequest = await requestModel.findOne({
            _id: req.params.id,
            customer: customer._id
        });

        if (!existingRequest) {
            return res.status(404).json({ message: "Request not found" });
        }

        const finalStart = updates.start_time ?? existingRequest.start_time;
        const finalEnd = updates.end_time ?? existingRequest.end_time;

        if (finalEnd <= finalStart) {
            return res.status(400).json({ message: "End time must be after start time" });
        }

        // Slots can never be reduced below the number of freelancers who already accepted
        if (updates.no_of_candidates !== undefined) {
            const progress = await requestProgressModel.findOne({ requestId: existingRequest._id }).lean();
            const acceptedCount = (progress?.accepted || []).length;

            if (updates.no_of_candidates < acceptedCount) {
                return res.status(409).json({
                    message: `Cannot reduce slots below the current accepted count (${acceptedCount})`
                });
            }
        }

        // Event-timing changes follow the same accepted-list lock as freelancer removals
        const changesEventTiming =
            updates.start_time !== undefined ||
            updates.end_time !== undefined ||
            updates.date !== undefined;

        if (changesEventTiming && !canCustomerModifyList(existingRequest)) {
            return res.status(403).json({
                message: `${getListLockMessage(existingRequest)}. Event timing cannot be changed after the lock.`
            });
        }

        const request = await requestModel.findOneAndUpdate(
            { _id: req.params.id, customer: customer._id },
            { $set: updates },
            { new: true, runValidators: true }
        );

        return res.status(200).json({
            message: "Request updated successfully",
            request
        });
    } catch (error) {
        console.error("Update request error:", error);
        return res.status(500).json({ message: "Error updating request" });
    }
};

// delete a request owned by the logged-in customer
const deleteRequest = async (req, res) => {
    try {
        const token = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);

        if (!token) {
            return res.status(401).json({ message: "Authentication required" });
        }

        let decoded;

        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({ message: "Invalid or expired token" });
        }

        if (!decoded.id || !mongoose.isValidObjectId(decoded.id)) {
            return res.status(401).json({ message: "Invalid token payload" });
        }

        const customer = await customerModel.findOne({ account: decoded.id });

        if (!customer) {
            return res.status(403).json({ message: "Customer profile not found" });
        }

        if (!mongoose.isValidObjectId(req.params.id)) {
            return res.status(400).json({ message: "Invalid request ID" });
        }

        const request = await requestModel.findOne({
            _id: req.params.id,
            customer: customer._id
        });

        if (!request) {
            return res.status(404).json({ message: "Request not found" });
        }

        // Never orphan accepted freelancers by deleting an in-progress request
        const acceptedProgress = await requestProgressModel.findOne({ requestId: request._id }).lean();
        if ((acceptedProgress?.accepted || []).length > 0) {
            return res.status(409).json({
                message: "Cannot delete a request with accepted freelancers — remove them from the accepted list first"
            });
        }

        const deleted = await requestModel.findOneAndDelete({
            _id: req.params.id,
            customer: customer._id
        });

        if (!deleted) {
            return res.status(404).json({ message: "Request not found" });
        }

        await customerModel.updateOne(
            { _id: customer._id },
            { $pull: { sent_request: request._id } }
        );

        // Cleanup requestProgress for this request
        try {
            await requestProgressModel.deleteOne({ requestId: request._id });
        } catch (error) {
            console.error(`Error deleting requestProgress for request ${request._id}:`, error);
        }

        // Cleanup freelancerProgress: remove this requestId from received/accepted/rejected arrays
        try {
            await freelancerProgressModel.updateMany(
                {},
                {
                    $pull: {
                        received: request._id,
                        accepted: request._id,
                        rejected: request._id
                    }
                }
            );
        } catch (error) {
            console.error(`Error cleaning up freelancerProgress for request ${request._id}:`, error);
        }

        return res.status(200).json({ message: "Request deleted successfully" });
    } catch (error) {
        console.error("Delete request error:", error);
        return res.status(500).json({ message: "Error deleting request" });
    }
};

// Remove a freelancer from accepted list and notify waitlisters
const removeFreelancerFromAccepted = async (req, res) => {
    try {
        const token = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);

        if (!token) {
            return res.status(401).json({ message: "Authentication required" });
        }

        let decoded;

        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({ message: "Invalid or expired token" });
        }

        if (!decoded.id || !mongoose.isValidObjectId(decoded.id)) {
            return res.status(401).json({ message: "Invalid token payload" });
        }

        const customer = await customerModel.findOne({ account: decoded.id });

        if (!customer) {
            return res.status(403).json({ message: "Customer profile not found" });
        }

        const { requestId, freelancerId } = req.params;

        if (!mongoose.isValidObjectId(requestId) || !mongoose.isValidObjectId(freelancerId)) {
            return res.status(400).json({ message: "Invalid request or freelancer ID" });
        }

        const request = await requestModel.findOne({
            _id: requestId,
            customer: customer._id
        });

        if (!request) {
            return res.status(404).json({ message: "Request not found" });
        }

        // Check if list can still be modified (within LIST_LOCK_DAYS)
        if (!canCustomerModifyList(request)) {
            return res.status(403).json({
                message: `${getListLockMessage(request)}. Cannot modify accepted list after 2 days of request creation.`
            });
        }

        // Check if event has ended
        const end = getEventEnd(request);
        if (end && end <= new Date()) {
            return res.status(410).json({
                message: "Event has already ended. Cannot modify list."
            });
        }

        // Remove from requestProgress accepted array.
        // Requiring membership in the filter makes "was not accepted" detectable:
        // $pull alone "succeeds" even when nothing was removed.
        const updated = await requestProgressModel.findOneAndUpdate(
            { requestId, accepted: freelancerId },
            { $pull: { accepted: freelancerId } },
            { new: true }
        );

        if (!updated) {
            return res.status(404).json({
                message: "Freelancer was not in the accepted list"
            });
        }

        try {
            // Remove from freelancer's progress
            await freelancerProgressModel.updateOne(
                { freelancerId },
                { $pull: { accepted: requestId } }
            );

            // Add to manually rejected in request
            await requestModel.updateOne(
                { _id: requestId },
                { $addToSet: { manually_rejected: freelancerId } }
            );
        } catch (error) {
            console.error("Error updating freelancer progress:", error);
            // But continue to notify waitlisters
        }

        // Notify first person on waitlist
        await notifyWaitlistedFreelancers(requestId);

        return res.status(200).json({
            message: "Freelancer removed successfully. Waitlisted freelancers have been notified.",
            slots_available: 1
        });
    } catch (error) {
        console.error("Remove freelancer error:", error);
        return res.status(500).json({ message: "Error removing freelancer" });
    }
};

// Notify waitlisted freelancers about available slots
const notifyWaitlistedFreelancers = async (requestId) => {
    try {
        if (!mongoose.isValidObjectId(requestId)) {
            console.error("Invalid requestId for waitlist notification:", requestId);
            return;
        }

        const request = await requestModel.findById(requestId).lean();
        if (!request) {
            console.error("Request not found for waitlist notification:", requestId);
            return;
        }

        // Get current accepted count
        const progress = await requestProgressModel.findOne({ requestId }).lean();
        const acceptedCount = (progress?.accepted || []).length;

        if (acceptedCount >= request.no_of_candidates) {
            // No slots available
            console.log(`Request ${requestId} still at capacity`);
            return;
        }

        // Get first un-notified freelancer from waitlist
        const waitlisted = await waitlistModel.findOne(
            {
                requestId,
                notified: false
            },
            {},
            { sort: { attemptedAt: 1 } }
        );

        if (!waitlisted) {
            console.log(`No more waitlisted freelancers for request ${requestId}`);
            return;
        }

        // Mark as notified
        await waitlistModel.updateOne(
            { _id: waitlisted._id },
            {
                $set: {
                    notified: true,
                    notifiedAt: new Date()
                }
            }
        );

        // Send in-app phone notification to waitlisted freelancer (No email)
        await notifyWaitlistSlotAvailable(requestId, waitlisted.freelancerId);

        return {
            success: true,
            notifiedFreelancerId: waitlisted.freelancerId,
            message: "Waitlisted freelancer notified via in-app notification"
        };
    } catch (error) {
        console.error("Error notifying waitlist:", error);
    }
};

// Remind accepted freelancers who have not entered attendance code yet
// (Sends BOTH Email + In-App Phone Notification)
// Owner-only: authenticated customer reminding on THEIR OWN request.
const remindAttendance = async (req, res) => {
    try {
        const token = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);

        if (!token) {
            return res.status(401).json({ message: "Authentication required" });
        }

        let decoded;

        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({ message: "Invalid or expired token" });
        }

        if (!decoded.id || !mongoose.isValidObjectId(decoded.id)) {
            return res.status(401).json({ message: "Invalid token payload" });
        }

        const customer = await customerModel.findOne({ account: decoded.id });

        if (!customer) {
            return res.status(403).json({ message: "Customer profile not found" });
        }

        const { requestId } = req.params;

        if (!mongoose.isValidObjectId(requestId)) {
            return res.status(400).json({ message: "Invalid request id" });
        }

        const request = await requestModel.findOne({
            _id: requestId,
            customer: customer._id
        });

        if (!request) {
            return res.status(404).json({ message: "Request not found" });
        }

        const result = await notifyAllPendingAttendance(requestId);

        return res.status(200).json({
            message: result.message,
            notifiedCount: result.count
        });
    } catch (error) {
        console.error("Error sending attendance reminders:", error);
        return res.status(500).json({ message: "Error sending attendance reminders" });
    }
};

module.exports = {
    createRequest,
    getRequests,
    getRequestById,
    updateRequest,
    deleteRequest,
    removeFreelancerFromAccepted,
    notifyWaitlistedFreelancers,
    remindAttendance
};

