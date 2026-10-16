const express = require("express");

const router = express.Router();

const requestController = require("../controllers/request.controller");
const ratelimiter = require("../middlewares/ratelimiter.middleware");

// Create request (enqueues fan-out work — must not be spammable)
router.post("/create", ratelimiter.RequestRateLimiter, requestController.createRequest);

// Get all requests by logged-in customer
router.get("/", requestController.getRequests);

// Get one request by ID
router.get("/:id", requestController.getRequestById);

// Update request
router.put("/:id", requestController.updateRequest);

// Delete request
router.delete("/:id", requestController.deleteRequest);

// Remove a freelancer from accepted list (customer action)
router.delete(
    "/:requestId/freelancer/:freelancerId",
    ratelimiter.ActionRateLimiter,
    requestController.removeFreelancerFromAccepted
);

// Remind accepted freelancers who have not entered attendance code (Email + In-App Notification)
router.post(
    "/:requestId/remind-attendance",
    ratelimiter.ActionRateLimiter,
    requestController.remindAttendance
);

module.exports = router;
