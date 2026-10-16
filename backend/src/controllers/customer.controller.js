const jwt = require("jsonwebtoken");

const authdatabase = require("../models/auth.model");
const customerModel = require("../models/customer.model");
const {
    uploadCustomerProfilePicture
} = require("../storage/imagekit.service");

// create customer account
async function createCustomer(req, res) {
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

        if (!decoded.id) {
            return res.status(401).json({
                message: "Invalid access token"
            });
        }

        const account = decoded.id;

        const user = await authdatabase.findById(account).select("_id");

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        const existing = await customerModel.findOne({ account });

        if (existing) {
            return res.status(409).json({
                message: "Customer account already exists"
            });
        }

        const {
            phoneno,
            state,
            city,
            pincode
        } = req.body;

        if (
            typeof phoneno !== "string" || !phoneno.trim() ||
            typeof state !== "string" || !state.trim() ||
            typeof city !== "string" || !city.trim() ||
            typeof pincode !== "string" || !pincode.trim()
        ) {
            return res.status(400).json({
                message: "Phone number, state, city and pincode are required"
            });
        }

        const customer = await customerModel.create({
            account,
            phoneno: phoneno.trim(),
            state: state.trim(),
            city: city.trim(),
            pincode: pincode.trim(),
            sent_request: []
        });

        return res.status(201).json({
            message: "Customer account created successfully",
            customer
        });

    } catch (error) {
        if (error.code === 11000) {
            return res.status(409).json({
                message: "Customer account already exists"
            });
        }

        return res.status(500).json({
            message: "Error while creating customer account",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// get customer account
async function getCustomer(req, res) {
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

        if (!decoded.id) {
            return res.status(401).json({
                message: "Invalid access token"
            });
        }

        const account = decoded.id;

        const customer = await customerModel.findOne({ account });

        if (!customer) {
            return res.status(404).json({
                message: "Customer account not found"
            });
        }

        return res.status(200).json({
            customer
        });

    } catch (error) {
        return res.status(500).json({
            message: "Error while fetching customer account",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// update customer account
async function updateCustomer(req, res) {
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

        if (!decoded.id) {
            return res.status(401).json({
                message: "Invalid access token"
            });
        }

        const account = decoded.id;

        const {
            phoneno,
            state,
            city,
            pincode
        } = req.body;

        const updates = {};

        if (phoneno !== undefined) {
            if (typeof phoneno !== "string" || !phoneno.trim()) {
                return res.status(400).json({
                    message: "Invalid phone number"
                });
            }

            updates.phoneno = phoneno.trim();
        }

        if (state !== undefined) {
            if (typeof state !== "string" || !state.trim()) {
                return res.status(400).json({
                    message: "Invalid state"
                });
            }

            updates.state = state.trim();
        }

        if (city !== undefined) {
            if (typeof city !== "string" || !city.trim()) {
                return res.status(400).json({
                    message: "Invalid city"
                });
            }

            updates.city = city.trim();
        }

        if (pincode !== undefined) {
            if (typeof pincode !== "string" || !pincode.trim()) {
                return res.status(400).json({
                    message: "Invalid pincode"
                });
            }

            updates.pincode = pincode.trim();
        }

        if (Object.keys(updates).length === 0) {
            return res.status(400).json({
                message: "No valid fields provided to update"
            });
        }

        const customer = await customerModel.findOneAndUpdate(
            { account },
            { $set: updates },
            { new: true, runValidators: true }
        );

        if (!customer) {
            return res.status(404).json({
                message: "Customer account not found"
            });
        }

        return res.status(200).json({
            message: "Customer account updated successfully",
            customer
        });

    } catch (error) {
        return res.status(500).json({
            message: "Error while updating customer account",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// delete customer account
async function deleteCustomer(req, res) {
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

        if (!decoded.id) {
            return res.status(401).json({
                message: "Invalid access token"
            });
        }

        const account = decoded.id;

        const customer = await customerModel.findOneAndDelete({
            account
        });

        if (!customer) {
            return res.status(404).json({
                message: "Customer account not found"
            });
        }

        return res.status(200).json({
            message: "Customer account deleted successfully"
        });

    } catch (error) {
        return res.status(500).json({
            message: "Error while deleting customer account",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// Upload customer profile picture
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

        const account = decoded.id;

        const customer = await customerModel.findOne({ account });
        if (!customer) {
            return res.status(404).json({
                message: "Customer account not found"
            });
        }

        if (!req.file) {
            return res.status(400).json({
                message: "Please select an image file to upload"
            });
        }

        // Upload to ImageKit folder: /plannora/customers/profile-pictures
        const uploadResult = await uploadCustomerProfilePicture(
            req.file.buffer,
            req.file.originalname,
            customer._id.toString()
        );


        const profileData = {
            url: uploadResult.url,
            fileId: uploadResult.fileId
        };

        customer.profilePicture = profileData;
        await customer.save();

        // Keep User profilePicture in sync
        await authdatabase.findByIdAndUpdate(account, {
            $set: {
                profilePicture: {
                    url: uploadResult.url,
                    publicId: uploadResult.fileId
                }
            }
        });

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

// Get only customer's profile picture
async function getProfilePicture(req, res) {
    try {
        const targetId = req.params.id || req.query.customerId || req.query.id;
        let customer;

        if (targetId) {
            customer = await customerModel.findOne({
                $or: [
                    { _id: targetId.match(/^[0-9a-fA-F]{24}$/) ? targetId : null },
                    { account: targetId.match(/^[0-9a-fA-F]{24}$/) ? targetId : null }
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

            customer = await customerModel.findOne({ account: decoded.id }).select("profilePicture");
        }

        if (!customer) {
            return res.status(404).json({
                message: "Customer account not found"
            });
        }

        // Return only the profile picture
        return res.status(200).json({
            profilePicture: customer.profilePicture?.url || null
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
    createCustomer,
    getCustomer,
    updateCustomer,
    deleteCustomer,
    uploadProfilePicture,
    getProfilePicture
};
