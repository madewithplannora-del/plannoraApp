//model imports
const authdatabase = require("../models/auth.model");
const otpmodel = require("../models/otp.model");
const forgototp = require("../models/forgototp.model");

//hashing and tokens
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const crypto = require("crypto");

const sendmail = require("../services/email.service");
const { generateOtp, getOtpMsg } = require("../utils/util");

require("dotenv").config();

const isProduction = process.env.NODE_ENV === "production";

const cookieBaseOptions = {
    httpOnly: true,
    secure: isProduction,
    sameSite: isProduction ? "none" : "lax"
};

function readStringField(value) {
    return typeof value === "string" ? value : null;
}

function normalizeEmail(value) {
    const email = readStringField(value);
    return email ? email.trim().toLowerCase() : null;
}

function isOtpValue(value) {
    return typeof value === "string" || (typeof value === "number" && Number.isFinite(value));
}

// Register
async function registerUser(req, res) {
    try {
        const {
            username,
            email: rawEmail,
            password
        } = req.body;

        const email = normalizeEmail(rawEmail);

        if (readStringField(username) === null || !email || readStringField(password) === null || !password) {
            return res.status(400).json({
                message: "Username, email and password are required"
            });
        }

        if (username.length < 3 || username.length > 30) {
            return res.status(400).json({
                message: "Username must be between 3 and 30 characters"
            });
        }

        if (password.length < 8) {
            return res.status(400).json({
                message: "Password must be at least 8 characters"
            });
        }

        const userAlreadyExist = await authdatabase.findOne({
            $or: [
                { email },
                { username }
            ]
        });

        if (userAlreadyExist) {
            return res.status(409).json({
                message: "User already exist"
            });
        }

        const hashedpassword = await bcrypt.hash(password,10);

        const otp = generateOtp();

        const hashedOtp = await bcrypt.hash(otp.toString(),10);

        await otpmodel.deleteMany({
            email
        });

        await otpmodel.create({
            email,
            otp: hashedOtp,
            username,
            password: hashedpassword
        });

        const message = getOtpMsg(otp);

        await sendmail(
            email,
            "Email Verification OTP",
            message.text,
            message.html
        );

        return res.status(201).json({
            message:"OTP sent to email. Verify it to create your account."
        });

    } catch (error) {

        return res.status(500).json({
            message:
                "Error while registering user",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// Verify otp
async function verifyOtp(req, res) {
    try {
        const email = normalizeEmail(req.body.email);

        const { otp } = req.body;

        if (!email || !isOtpValue(otp)) {
            return res.status(400).json({
                message:
                    "Email and OTP are required"
            });
        }

        const otpData = await otpmodel.findOne({
            email
        });

        if (!otpData) {
            return res.status(404).json({
                message:
                    "OTP not found or expired"
            });
        }

        const otpAge = Date.now() - otpData.createdAt.getTime();

        if (otpAge > 10 * 60 * 1000) {
            await otpmodel.deleteOne({
                _id: otpData._id
            });

            return res.status(400).json({
                message:
                    "OTP expired"
            });
        }

        // Check OTP attempt limit
        if (otpData.attempts >= 5) {

            await otpmodel.deleteOne({
                _id: otpData._id
            });

            return res.status(429).json({
                message:
                    "Too many invalid attempts. Please register again."
            });
        }

        const otpMatch = await bcrypt.compare(
            otp.toString(),
            otpData.otp
        );        if (!otpMatch) {

            const updated = await otpmodel.findOneAndUpdate(
                {
                    _id: otpData._id,
                    attempts: {
                        $lt: 5
                    }
                },
                {
                    $inc: {
                        attempts: 1
                    }
                }
            );

            if (!updated) {
                await otpmodel.deleteOne({
                    _id: otpData._id
                });

                return res.status(429).json({
                    message: "Too many invalid attempts. Please register again."
                });
            }

            return res.status(400).json({
                message: "Invalid OTP"
            });
        }

        const consumed = await otpmodel.findOneAndDelete({
            _id: otpData._id
        });

        if (!consumed) {
            return res.status(409).json({
                message: "OTP already used"
            });
        }

        // Check again before creating account
        const userAlreadyExist =
            await authdatabase.findOne({
                $or: [
                    {email},
                    {username:otpData.username}
                ]
            });        if (userAlreadyExist) {

            return res.status(409).json({
                message: "Username or email already exist"
            });
        }

        // Create user account after OTP verification
        const user = await authdatabase.create({
            username:otpData.username,
            email,
            password:otpData.password,
            emailVerified:true
        });

        // Create access token
        const accesstoken = jwt.sign(
            {
                username:user.username,
                id:user._id
            },process.env.JWT_KEY,{
                expiresIn: "15m"
            }
        );

        res.cookie(
            "accesstoken",
            accesstoken,
            {
                ...cookieBaseOptions,
                path: "/",
                maxAge:
                    15 * 60 * 1000
            }
        );

        return res.status(200).json({
            message:
                "Account created and email verified successfully",
            token: accesstoken,
            user: {
                id:user._id,
                username:user.username,
                email:user.email,
                emailVerified:user.emailVerified
            }
        });

    } catch (error) {

        // Two racing verifications can both reach create(); report it cleanly
        // instead of leaking the raw Mongo duplicate key error.
        if (error && error.code === 11000) {
            return res.status(409).json({
                message: "Username or email already exist"
            });
        }

        return res.status(500).json({
            message:"Error while verifying OTP",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });

    }

}

// Login
async function loginUser(req, res) {
    try {
        const {
            username,
            email: rawEmail,
            password
        } = req.body;        const email =
            normalizeEmail(rawEmail);

        const cleanUsername = readStringField(username) ? username.trim() : null;

        if ((!cleanUsername && !email) || readStringField(password) === null || !password) {
            return res.status(400).json({
                message: "Username or email and password are required"
            });
        }

        const userExist = await authdatabase.findOne({
            $or: [
                ...(cleanUsername ? [{ username: cleanUsername }] : []),
                ...(email ? [ { email }] : [])
            ]
        }).select("+password");        
        
        if (!userExist) {
            // Same message as a wrong password so accounts cannot be enumerated.
            return res.status(401).json({
                message: "Invalid credentials"
            });
        }

        if (!userExist.emailVerified) {

            return res.status(403).json({
                message:
                    "Please verify your email first"
            });

        }


        const isMatch =
            await bcrypt.compare(
                password,
                userExist.password
            );

        if (!isMatch) {
            return res.status(401).json({
                message:
                    "Invalid credentials"
            });
        }

        const accesstoken = jwt.sign(
            {
                username:userExist.username,
                id:userExist._id
            },process.env.JWT_KEY,{
                expiresIn: "15m"
            }
        );

        res.cookie("accesstoken",accesstoken,
            {
                ...cookieBaseOptions,
                path: "/",
                maxAge:
                    15 * 60 * 1000
            }
        );

        return res.status(200).json({
            message:"Logged in",
            token: accesstoken,
            user: {
                id:userExist._id,
                username:userExist.username,
                email:userExist.email,
                emailVerified:userExist.emailVerified
            }
        });

    } catch (error) {

        return res.status(500).json({
            message:"Error while logging in",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// Forgot password
async function forgotPassword(req, res) {

    try {        const email = normalizeEmail(req.body.email);

        if (!email) {
            return res.status(400).json({
                message: "Email is required"
            });
        }

        const user = await authdatabase.findOne({
            email
        });

        if (!user) {

            /*
                Same response as the success path: a distinct 404 here lets
                anyone probe which e-mail addresses have an account.
            */
            return res.status(200).json({
                message: "Password reset OTP sent to email"
            });

        }

        const otp = generateOtp();

        const hashedOtp = await bcrypt.hash(
            otp.toString(),
            10
        );

        await forgototp.deleteMany({
            email
        });

        await forgototp.create({

            email,
            otp: hashedOtp,
            attempts: 0

        });

        const message = getOtpMsg(otp);

        await sendmail(

            email,
            "Password Reset OTP",
            message.text,
            message.html

        );

        return res.status(200).json({
            message:
                "Password reset OTP sent to email"
        });

    } catch (error) {

        return res.status(500).json({
            message:"Error while sending password reset OTP",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// Verify forgot password OTP
async function verifyForgotOtp(req, res) {

    try {

        const email = normalizeEmail(req.body.email);

        const { otp } = req.body;

        if (!email || !isOtpValue(otp)) {

            return res.status(400).json({
                message:
                    "Email and OTP are required"
            });

        }

        const otpData = await forgototp.findOne({
            email
        });

        if (!otpData) {

            return res.status(404).json({
                message:
                    "OTP not found or expired"
            });

        }

        const otpAge =
            Date.now() -
            otpData.createdAt.getTime();

        if (otpAge > 10 * 60 * 1000) {

            await forgototp.deleteOne({
                _id:
                    otpData._id
            });

            return res.status(400).json({
                message:
                    "OTP expired"
            });
        }

        if (otpData.attempts >= 5) {

            await forgototp.deleteOne({
                _id:
                    otpData._id
            });

            return res.status(400).json({
                message:
                    "Too many OTP attempts"
            });
        }

        const otpMatch = await bcrypt.compare(
            otp.toString(),
            otpData.otp
        );        if (!otpMatch) {

            // Atomic attempt increment (see verifyOtp).
            const updated = await forgototp.findOneAndUpdate(
                {
                    _id: otpData._id,
                    attempts: {
                        $lt: 5
                    }
                },
                {
                    $inc: {
                        attempts: 1
                    }
                }
            );

            if (!updated) {
                await forgototp.deleteOne({
                    _id: otpData._id
                });

                return res.status(429).json({
                    message: "Too many OTP attempts"
                });
            }

            return res.status(400).json({
                message: "Invalid OTP"
            });
        }

        const user = await authdatabase.findOne({
            email
        });

        if (!user) {
            return res.status(404).json({
                message:
                    "User not found"
            });
        }

        // Atomically consume the OTP so it is single use.
        const consumed = await forgototp.findOneAndDelete({
            _id:
                otpData._id
        });

        if (!consumed) {
            return res.status(409).json({
                message: "OTP already used"
            });
        }

        const resetToken = jwt.sign(
            {
                id:user._id,
                email:user.email,
                purpose:"password-reset"
            },process.env.JWT_KEY,{
                expiresIn:
                    "2m"
            }
        );

        res.cookie("resettoken",resetToken,
            {
                ...cookieBaseOptions,
                path: "/",
                maxAge:
                    2 * 60 * 1000
            }
        );

        return res.status(200).json({
            message:
                "OTP verified successfully"
        });

    } catch (error) {

        return res.status(500).json({
            message:
                "Error while verifying forgot password OTP",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// Reset password
async function resetPassword(req, res) {

    try {

        const { resetpassword } = req.body;

        if (!resetpassword) {
            return res.status(400).json({
                message:
                    "New password is required"
            });
        }

        if (resetpassword.length < 8) {
            return res.status(400).json({
                message:
                    "Password must be at least 8 characters"
            });
        }

        const resetToken =
            req.cookies.resettoken;

        if (!resetToken) {
            return res.status(401).json({
                message:
                    "Reset token not found or expired"
            });
        }

        let decoded;
        try {
            decoded =
                jwt.verify(
                    resetToken,
                    process.env.JWT_KEY
                );
        } catch (error) {
            return res.status(401).json({
                message:
                    "Reset token is invalid or expired"
            });
        }

        if ( decoded.purpose !== "password-reset" ) {
            return res.status(401).json({
                message:
                    "Invalid reset token"
            });
        }

        const user =await authdatabase.findById(decoded.id);

        if (!user) {

            return res.status(404).json({
                message:
                    "User not found"
            });

        }

        const hashedPassword =
            await bcrypt.hash(
                resetpassword,
                10
            );

        user.password =
            hashedPassword;

        await user.save();

        res.clearCookie(
            "resettoken",
            {
                ...cookieBaseOptions,
                path: "/"
            }
        );

        return res.status(200).json({
            message:
                "Password reset successfully"
        });

    } catch (error) {
        return res.status(500).json({
            message:
                "Error while resetting password",
            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });
    }
}

// Logout
async function logoutUser(req, res) {

    try {

        // Clear access token
        res.clearCookie(
            "accesstoken",
            {
                ...cookieBaseOptions,
                path: "/"
            }
        );

        // Clear password reset token
        res.clearCookie(
            "resettoken",
            {
                ...cookieBaseOptions,
                path: "/"
            }
        );

        return res.status(200).json({
            message:
                "Logged out successfully"
        });

    } catch (error) {
        return res.status(500).json({
            message:
                "Error while logging out"
        });

    }

}

// Get current user
async function getMe(req, res) {
    try {

        // Get access token from cookie or Authorization header (Bearer token)
        const accessToken = req.cookies?.accesstoken || (req.headers.authorization && req.headers.authorization.startsWith("Bearer ") ? req.headers.authorization.split(" ")[1] : null);

        if (!accessToken) {
            return res.status(401).json({
                message: "Access token not found"
            });
        }

        // Verify and decode JWT
        let decoded;

        try {

            decoded = jwt.verify(
                accessToken,
                process.env.JWT_KEY
            );

        } catch (error) {

            return res.status(401).json({
                message: "Invalid or expired access token"
            });

        }

        // Get user ID from verified JWT
        const userId = decoded.id;

        if (!userId) {
            return res.status(401).json({
                message: "User ID not found in token"
            });
        }

        // Find user using ID from JWT
        const user = await authdatabase.findById(userId);

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        // Return current user's information
        return res.status(200).json({
            user: {
                id: user._id,
                username: user.username,
                email: user.email,
                profilePicture: user.profilePicture,
                emailVerified: user.emailVerified
            }
        });

    } catch (error) {

        return res.status(500).json({
            message: "Error while getting user",

            ...(process.env.NODE_ENV !== "production" && {
                error: error.message
            })
        });

    }
}

module.exports = {
    registerUser,
    verifyOtp,
    loginUser,
    logoutUser,
    forgotPassword,
    verifyForgotOtp,
    resetPassword,
    getMe
};