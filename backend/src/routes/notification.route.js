const express = require("express");
const router = express.Router();
const notificationController = require("../controllers/notification.controller");

// Get all notifications for logged-in user/freelancer
router.get("/", notificationController.getNotifications);

// Register device push token for phone notifications
router.post("/register-device", notificationController.registerDeviceToken);

// Mark all as read
router.patch("/read-all", notificationController.markAllAsRead);

// Mark single notification as read
router.patch("/:id/read", notificationController.markAsRead);

module.exports = router;
