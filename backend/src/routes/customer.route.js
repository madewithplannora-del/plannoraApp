const express = require("express");

const router = express.Router();

const customerController = require("../controllers/customer.controller");
const {
    uploadProfilePictureMiddleware,
    validateImageSignature
} = require("../middlewares/upload.middleware");

// Create customer account
router.post("/create", customerController.createCustomer);

// Get customer account
router.get("/", customerController.getCustomer);

// Update customer account
router.put("/update", customerController.updateCustomer);

// Delete customer account
router.delete("/delete", customerController.deleteCustomer);

// Upload customer profile picture
router.post("/upload-profile-picture", uploadProfilePictureMiddleware, validateImageSignature, customerController.uploadProfilePicture);
router.post("/profile-picture", uploadProfilePictureMiddleware, validateImageSignature, customerController.uploadProfilePicture);

// Get customer profile picture only
router.get("/profile-picture", customerController.getProfilePicture);
router.get("/profile-picture/:id", customerController.getProfilePicture);

module.exports = router;

