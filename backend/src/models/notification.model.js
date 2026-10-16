const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
    {
        recipientId: {
            type: mongoose.Schema.Types.ObjectId,
            required: true,
            refPath: "recipientModel"
        },

        recipientModel: {
            type: String,
            required: true,
            enum: ["freelancers", "users", "customers"],
            default: "freelancers"
        },

        title: {
            type: String,
            required: true,
            trim: true
        },

        message: {
            type: String,
            required: true,
            trim: true
        },

        type: {
            type: String,
            enum: ["WAITLIST_SLOT_AVAILABLE", "ATTENDANCE_CODE_REMINDER", "GENERAL"],
            default: "GENERAL"
        },

        requestId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "requests",
            default: null
        },

        read: {
            type: Boolean,
            default: false
        },

        readAt: {
            type: Date,
            default: null
        }
    },
    {
        timestamps: true
    }
);

notificationSchema.index({ recipientId: 1, read: 1, createdAt: -1 });

const notificationModel = mongoose.model("notifications", notificationSchema);

module.exports = notificationModel;
