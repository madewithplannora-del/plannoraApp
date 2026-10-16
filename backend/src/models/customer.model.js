const mongoose = require("mongoose");

const customerSchema = new mongoose.Schema(
    {
        account: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "users",
            required: true,
            unique: true
        },

        phoneno: {
            type: String,
            required: true
        },

        state: {
            type: String,
            required: true
        },

        city: {
            type: String,
            required: true
        },

        pincode: {
            type: String,
            required: true
        },

        sent_request: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: "requests"
            }
        ],

        profilePicture: {
            url: {
                type: String,
                default: null
            },
            fileId: {
                type: String,
                default: null
            }
        }
    },
    {
        timestamps: true
    }
);

const customerModel = mongoose.model("customers",customerSchema);

module.exports = customerModel;