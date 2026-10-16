const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({

    username: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        minlength: 3,
        maxlength: 30
    },

    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true,
        match: [
            /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
            "Invalid email"
        ]
    },

    password: {
        type: String,
        required: true,
        select: false
    },

    profilePicture: {

        url: {
            type: String,
            default: null
        },

        publicId: {
            type: String,
            default: null
        }

    },

    emailVerified: {
        type: Boolean,
        default: false
    },

    pushToken: {
        type: String,
        default: null
    }
}, {
    timestamps: true
});


const usermodel = mongoose.model("users",userSchema);

module.exports = usermodel;