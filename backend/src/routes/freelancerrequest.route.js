const express = require("express");

const router = express.Router();

const freelancerRequestController = require("../controllers/freelancerrequest.controller");
const ratelimiter = require("../middlewares/ratelimiter.middleware");

// Accept a request
router.post(
    "/:requestId/accept",
    ratelimiter.ActionRateLimiter,
    freelancerRequestController.acceptRequest
);

// Reject a request
router.post(
    "/:requestId/reject",
    ratelimiter.ActionRateLimiter,
    freelancerRequestController.rejectRequest
);

// Submit attendance code (6-digit code is paid-on-success, so attempts must be bounded)
router.post(
    "/:requestId/attendance",
    ratelimiter.CompleteRateLimiter,
    freelancerRequestController.submitAttendance
);

// Submit redflag code (same code, same brute-force surface)
router.post(
    "/:requestId/redflag",
    ratelimiter.CompleteRateLimiter,
    freelancerRequestController.submitRedflag
);

module.exports = router;
