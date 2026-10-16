const express = require("express");

const router = express.Router();

const customerController = require("../controllers/customer.controller");
const {
    uploadProfilePictureMiddleware,
    validateImageSignature
} = require("../middlewares/upload.middleware");

// Create customer account (supports text fields + optional profile image)
router.post("/create", uploadProfilePictureMiddleware, validateImageSignature, customerController.createCustomer);

// Get customer account
router.get("/", customerController.getCustomer);

// Update customer account (supports text fields + optional profile image)
router.put("/update", uploadProfilePictureMiddleware, validateImageSignature, customerController.updateCustomer);

// Delete customer account
router.delete("/delete", customerController.deleteCustomer);

// Get customer profile picture only
router.get("/profile-picture", customerController.getProfilePicture);
router.get("/profile-picture/:id", customerController.getProfilePicture);

module.exports = router;

