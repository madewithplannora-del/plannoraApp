 const jwt = require("jsonwebtoken");

const authdatabase = require("../models/auth.model");
const freelancerModel = require("../models/freelancer.model");
const freelancerDetailModel = require("../models/freelancerDetails.model");
const freelancerProgressModel = require("../models/freelancerProgress.model");
const {
    uploadFreelancerProfilePicture
} = require("../storage/imagekit.service");

// Create freelancer account
async function createFreelancer(req, res) {
    try {
        const token = req.cookies?.accesstoken;

        if (!token) {
            return res.status(401).json({
                message: "Access token not found"
            });
        }

        let decoded;

        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({
                message: "Invalid or expired access token"
            });
        }

        if (!decoded.id) {
            return res.status(401).json({
                message: "Invalid access token"
            });
        }

        const userId = decoded.id;

        const user = await authdatabase.findById(userId).select("_id");

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        const existing = await freelancerModel.findOne({ userId });

        if (existing) {
            return res.status(409).json({
                message: "Freelancer account already exists"
            });
        }

        const {
            phone,
            linkedin,
            category,
            state,
            city,
            pincode
        } = req.body;

        if (
            !["Professional", "Cultural", "Private"].includes(category)
        ) {
            return res.status(400).json({
                message: "Valid category is required"
            });
        }

        // Validate state, city, pincode
        if (typeof state !== "string" || state.trim().length === 0) {
            return res.status(400).json({
                message: "Invalid state"
            });
        }

        if (typeof city !== "string" || city.trim().length === 0) {
            return res.status(400).json({
                message: "Invalid city"
            });
        }

        if (typeof pincode !== "string" || pincode.trim().length === 0) {
            return res.status(400).json({
                message: "Invalid pincode"
            });
        }

        const trimmedState = state.trim();
        const trimmedCity = city.trim();
        const trimmedPincode = pincode.trim();

        const freelancer = await freelancerModel.create({
            userId,
            phone,
            linkedin,
            state: trimmedState,
            city: trimmedCity,
            pincode: trimmedPincode,
            category
        });

        try {
            await freelancerDetailModel.create({
                freelancerId: freelancer._id,
                category,
                state: trimmedState,
                city: trimmedCity,
                pincode: trimmedPincode
            });

            await freelancerProgressModel.create({
                freelancerId: freelancer._id,
                received: [],
                accepted: [],
                attended: [],
                rejected: [],
                redflag: []
            });
        } catch (error) {
            await Promise.all([
                freelancerModel.deleteOne({ _id: freelancer._id }),
                freelancerDetailModel.deleteOne({ freelancerId: freelancer._id }),
                freelancerProgressModel.deleteOne({ freelancerId: freelancer._id })
            ]);

            throw error;
        }

        return res.status(201).json({
            message: "Freelancer account created successfully",
            freelancer
        });

    } catch (error) {
        if (error.code === 11000) {
            return res.status(409).json({
                message: "Freelancer account already exists"
            });
        }

        return res.status(500).json({
            message: "Error while creating freelancer account",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// Get freelancer account
async function getFreelancer(req, res) {
    try {
        const token = req.cookies?.accesstoken;

        if (!token) {
            return res.status(401).json({
                message: "Access token not found"
            });
        }

        let decoded;

        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({
                message: "Invalid or expired access token"
            });
        }

        if (!decoded.id) {
            return res.status(401).json({
                message: "Invalid access token"
            });
        }

        const userId = decoded.id;

        const freelancer = await freelancerModel.findOne({ userId });

        if (!freelancer) {
            return res.status(404).json({
                message: "Freelancer account not found"
            });
        }

        const [details, progress] = await Promise.all([
            freelancerDetailModel.findOne({ freelancerId: freelancer._id }),
            freelancerProgressModel.findOne({ freelancerId: freelancer._id })
        ]);

        return res.status(200).json({
            freelancer,
            details,
            progress
        });

    } catch (error) {
        return res.status(500).json({
            message: "Error while fetching freelancer account",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// Update freelancer account
async function updateFreelancer(req, res) {
    try {
        const token = req.cookies?.accesstoken;

        if (!token) {
            return res.status(401).json({
                message: "Access token not found"
            });
        }

        let decoded;

        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({
                message: "Invalid or expired access token"
            });
        }

        if (!decoded.id) {
            return res.status(401).json({
                message: "Invalid access token"
            });
        }

        const userId = decoded.id;

        const {
            phone,
            linkedin,
            category,
            state,
            city,
            pincode
        } = req.body;

        if (
            category !== undefined &&
            !["Professional", "Cultural", "Private"].includes(category)
        ) {
            return res.status(400).json({
                message: "Invalid category"
            });
        }

        // Validate state, city, pincode if provided
        if (state !== undefined) {
            if (typeof state !== "string" || state.trim().length === 0) {
                return res.status(400).json({
                    message: "Invalid state"
                });
            }
        }

        if (city !== undefined) {
            if (typeof city !== "string" || city.trim().length === 0) {
                return res.status(400).json({
                    message: "Invalid city"
                });
            }
        }

        if (pincode !== undefined) {
            if (typeof pincode !== "string" || pincode.trim().length === 0) {
                return res.status(400).json({
                    message: "Invalid pincode"
                });
            }
        }

        const updates = {};

        if (phone !== undefined) updates.phone = phone;
        if (linkedin !== undefined) updates.linkedin = linkedin;
        if (state !== undefined) updates.state = state.trim();
        if (city !== undefined) updates.city = city.trim();
        if (pincode !== undefined) updates.pincode = pincode.trim();
        if (category !== undefined) updates.category = category;

        if (Object.keys(updates).length === 0) {
            return res.status(400).json({
                message: "No valid fields provided to update"
            });
        }

        const freelancer = await freelancerModel.findOneAndUpdate(
            { userId },
            { $set: updates },
            { new: true, runValidators: true }
        );

        if (!freelancer) {
            return res.status(404).json({
                message: "Freelancer account not found"
            });
        }

        const detailUpdates = {};

        if (category !== undefined) detailUpdates.category = category;
        if (state !== undefined) detailUpdates.state = state.trim();
        if (city !== undefined) detailUpdates.city = city.trim();
        if (pincode !== undefined) detailUpdates.pincode = pincode.trim();

        if (Object.keys(detailUpdates).length > 0) {
            await freelancerDetailModel.updateOne(
                { freelancerId: freelancer._id },
                { $set: detailUpdates },
                { runValidators: true }
            );
        }

        return res.status(200).json({
            message: "Freelancer account updated successfully",
            freelancer
        });

    } catch (error) {
        return res.status(500).json({
            message: "Error while updating freelancer account",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// Delete freelancer account
async function deleteFreelancer(req, res) {
    try {
        const token = req.cookies?.accesstoken;

        if (!token) {
            return res.status(401).json({
                message: "Access token not found"
            });
        }

        let decoded;

        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({
                message: "Invalid or expired access token"
            });
        }

        if (!decoded.id) {
            return res.status(401).json({
                message: "Invalid access token"
            });
        }

        const userId = decoded.id;

        const freelancer = await freelancerModel.findOne({ userId });

        if (!freelancer) {
            return res.status(404).json({
                message: "Freelancer account not found"
            });
        }

        await Promise.all([
            freelancerModel.deleteOne({ _id: freelancer._id }),
            freelancerDetailModel.deleteOne({ freelancerId: freelancer._id }),
            freelancerProgressModel.deleteOne({ freelancerId: freelancer._id })
        ]);

        return res.status(200).json({
            message: "Freelancer account deleted successfully"
        });

    } catch (error) {
        return res.status(500).json({
            message: "Error while deleting freelancer account",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// Upload freelancer profile picture
async function uploadProfilePicture(req, res) {
    try {
        const token = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);

        if (!token) {
            return res.status(401).json({
                message: "Access token not found"
            });
        }

        let decoded;
        try {
            decoded = jwt.verify(token, process.env.JWT_KEY);
        } catch (error) {
            return res.status(401).json({
                message: "Invalid or expired access token"
            });
        }

        if (!decoded?.id) {
            return res.status(401).json({
                message: "Invalid access token"
            });
        }

        const userId = decoded.id;

        const freelancer = await freelancerModel.findOne({ userId });
        if (!freelancer) {
            return res.status(404).json({
                message: "Freelancer account not found"
            });
        }

        if (!req.file) {
            return res.status(400).json({
                message: "Please select an image file to upload"
            });
        }

        // Upload to ImageKit folder: /plannora/freelancers/profile-pictures
        const uploadResult = await uploadFreelancerProfilePicture(
            req.file.buffer,
            req.file.originalname,
            freelancer._id.toString()
        );


        const profileData = {
            url: uploadResult.url,
            fileId: uploadResult.fileId
        };

        // Update freelancer model
        freelancer.profilePicture = profileData;
        await freelancer.save();

        // Keep freelancerDetailModel and User profilePicture in sync
        await Promise.all([
            freelancerDetailModel.updateOne(
                { freelancerId: freelancer._id },
                { $set: { profilePicture: profileData } }
            ),
            authdatabase.findByIdAndUpdate(userId, {
                $set: {
                    profilePicture: {
                        url: uploadResult.url,
                        publicId: uploadResult.fileId
                    }
                }
            })
        ]);

        return res.status(200).json({
            message: "Profile picture uploaded successfully",
            profilePicture: uploadResult.url,
            fileId: uploadResult.fileId
        });

    } catch (error) {
        return res.status(500).json({
            message: "Error while uploading profile picture",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// Get only the freelancer's profile picture
async function getProfilePicture(req, res) {
    try {
        const targetId = req.params.id || req.query.freelancerId || req.query.id;
        let freelancer;

        if (targetId) {
            freelancer = await freelancerModel.findOne({
                $or: [
                    { _id: targetId.match(/^[0-9a-fA-F]{24}$/) ? targetId : null },
                    { userId: targetId.match(/^[0-9a-fA-F]{24}$/) ? targetId : null }
                ].filter(Boolean)
            }).select("profilePicture");
        } else {
            const token = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);

            if (!token) {
                return res.status(401).json({
                    message: "Access token not found"
                });
            }

            let decoded;
            try {
                decoded = jwt.verify(token, process.env.JWT_KEY);
            } catch (error) {
                return res.status(401).json({
                    message: "Invalid or expired access token"
                });
            }

            if (!decoded?.id) {
                return res.status(401).json({
                    message: "Invalid access token"
                });
            }

            freelancer = await freelancerModel.findOne({ userId: decoded.id }).select("profilePicture");
        }

        if (!freelancer) {
            return res.status(404).json({
                message: "Freelancer account not found"
            });
        }

        // Return only the profile picture
        return res.status(200).json({
            profilePicture: freelancer.profilePicture?.url || null
        });

    } catch (error) {
        return res.status(500).json({
            message: "Error while fetching profile picture",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

module.exports = {
    createFreelancer,
    getFreelancer,
    updateFreelancer,
    deleteFreelancer,
    uploadProfilePicture,
    getProfilePicture
};