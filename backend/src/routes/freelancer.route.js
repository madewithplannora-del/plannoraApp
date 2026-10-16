const express = require("express");

const router = express.Router();

const freelancerController = require("../controllers/freelancer.controller");
const {
    uploadProfilePictureMiddleware,
    validateImageSignature
} = require("../middlewares/upload.middleware");

// Create freelancer account
router.post("/create", freelancerController.createFreelancer);

// Get freelancer account
router.get("/", freelancerController.getFreelancer);

// Update freelancer account
router.put("/update", freelancerController.updateFreelancer);

// Delete freelancer account
router.delete("/delete", freelancerController.deleteFreelancer);

// Upload freelancer profile picture
router.post("/upload-profile-picture", uploadProfilePictureMiddleware, validateImageSignature, freelancerController.uploadProfilePicture);
router.post("/profile-picture", uploadProfilePictureMiddleware, validateImageSignature, freelancerController.uploadProfilePicture);

// Get freelancer profile picture only
router.get("/profile-picture", freelancerController.getProfilePicture);
router.get("/profile-picture/:id", freelancerController.getProfilePicture);

module.exports = router;

