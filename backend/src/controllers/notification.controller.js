const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");
const notificationModel = require("../models/notification.model");
const freelancerModel = require("../models/freelancer.model");
const authModel = require("../models/auth.model");

// Helper to authenticate request
async function getAuthenticatedUser(req) {
    const token = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);

    if (!token) return null;

    try {
        const decoded = jwt.verify(token, process.env.JWT_KEY);
        return decoded?.id ? decoded.id : null;
    } catch (e) {
        return null;
    }
}

// Get notifications for current user/freelancer
async function getNotifications(req, res) {
    try {
        const userId = await getAuthenticatedUser(req);
        if (!userId) {
            return res.status(401).json({ message: "Access token not found or invalid" });
        }

        // Find freelancer record if applicable
        const freelancer = await freelancerModel.findOne({ userId }).select("_id").lean();

        const recipientIds = [new mongoose.Types.ObjectId(userId)];
        if (freelancer?._id) {
            recipientIds.push(freelancer._id);
        }

        const query = { recipientId: { $in: recipientIds } };
        if (req.query.unreadOnly === "true") {
            query.read = false;
        }

        const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 30, 1), 100);

        const [notifications, unreadCount] = await Promise.all([
            notificationModel
                .find(query)
                .sort({ createdAt: -1 })
                .limit(limit)
                .populate("requestId", "event_details category date time pay")
                .lean(),
            notificationModel.countDocuments({
                recipientId: { $in: recipientIds },
                read: false
            })
        ]);

        return res.status(200).json({
            notifications,
            unreadCount
        });
    } catch (error) {
        console.error("Error fetching notifications:", error);
        return res.status(500).json({ message: "Error fetching notifications" });
    }
}

// Mark a single notification as read
async function markAsRead(req, res) {
    try {
        const userId = await getAuthenticatedUser(req);
        if (!userId) {
            return res.status(401).json({ message: "Access token not found or invalid" });
        }

        const { id } = req.params;
        if (!mongoose.isValidObjectId(id)) {
            return res.status(400).json({ message: "Invalid notification id" });
        }

        const updated = await notificationModel.findByIdAndUpdate(
            id,
            { $set: { read: true, readAt: new Date() } },
            { new: true }
        );

        if (!updated) {
            return res.status(404).json({ message: "Notification not found" });
        }

        return res.status(200).json({
            message: "Notification marked as read",
            notification: updated
        });
    } catch (error) {
        console.error("Error marking notification as read:", error);
        return res.status(500).json({ message: "Error updating notification" });
    }
}

// Mark all notifications as read
async function markAllAsRead(req, res) {
    try {
        const userId = await getAuthenticatedUser(req);
        if (!userId) {
            return res.status(401).json({ message: "Access token not found or invalid" });
        }

        const freelancer = await freelancerModel.findOne({ userId }).select("_id").lean();
        const recipientIds = [new mongoose.Types.ObjectId(userId)];
        if (freelancer?._id) {
            recipientIds.push(freelancer._id);
        }

        await notificationModel.updateMany(
            { recipientId: { $in: recipientIds }, read: false },
            { $set: { read: true, readAt: new Date() } }
        );

        return res.status(200).json({ message: "All notifications marked as read" });
    } catch (error) {
        console.error("Error marking all notifications as read:", error);
        return res.status(500).json({ message: "Error updating notifications" });
    }
}

// Register or update device push token for phone notifications
async function registerDeviceToken(req, res) {
    try {
        const userId = await getAuthenticatedUser(req);
        if (!userId) {
            return res.status(401).json({ message: "Access token not found or invalid" });
        }

        const { pushToken } = req.body;
        if (!pushToken || typeof pushToken !== "string" || !pushToken.trim()) {
            return res.status(400).json({ message: "Valid pushToken is required" });
        }

        const cleanToken = pushToken.trim();

        await Promise.all([
            authModel.findByIdAndUpdate(userId, { $set: { pushToken: cleanToken } }),
            freelancerModel.findOneAndUpdate({ userId }, { $set: { pushToken: cleanToken } })
        ]);

        return res.status(200).json({
            message: "Device push token registered successfully"
        });
    } catch (error) {
        console.error("Error registering push token:", error);
        return res.status(500).json({ message: "Error registering push token" });
    }
}

module.exports = {
    getNotifications,
    markAsRead,
    markAllAsRead,
    registerDeviceToken
};

