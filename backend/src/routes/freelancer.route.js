const express = require("express");

const router = express.Router();

const freelancerController = require("../controllers/freelancer.controller");
const {
    uploadProfilePictureMiddleware,
    validateImageSignature
} = require("../middlewares/upload.middleware");

// Create freelancer account (supports text fields + optional profile image)
router.post("/create", uploadProfilePictureMiddleware, validateImageSignature, freelancerController.createFreelancer);

// Get freelancer account
router.get("/", freelancerController.getFreelancer);

// Update freelancer account (supports text fields + optional profile image)
router.put("/update", uploadProfilePictureMiddleware, validateImageSignature, freelancerController.updateFreelancer);

// Delete freelancer account
router.delete("/delete", freelancerController.deleteFreelancer);

// Get freelancer profile picture only
router.get("/profile-picture", freelancerController.getProfilePicture);
router.get("/profile-picture/:id", freelancerController.getProfilePicture);

module.exports = router;

