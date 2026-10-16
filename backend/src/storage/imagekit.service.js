require("dotenv").config();

const ImageKit = require("imagekit");

const imagekit = new ImageKit({
    publicKey: process.env.IMAGEKIT_PUBLIC_KEY,
    privateKey: process.env.IMAGEKIT_PRIVATE_KEY,
    urlEndpoint: process.env.IMAGEKIT_URL_ENDPOINT
});

/**
 * Upload freelancer profile picture to /plannoraApp/freelancers/profile-pictures
 */
async function uploadFreelancerProfilePicture(buffer, fileName, freelancerId = "") {
    const cleanFileName = freelancerId
        ? `freelancer_${freelancerId}_${Date.now()}_${fileName}`
        : `freelancer_${Date.now()}_${fileName}`;

    const result = await imagekit.upload({
        file: buffer.toString("base64"),
        fileName: cleanFileName,
        folder: "/plannoraApp/freelancers/profile-pictures",
        useUniqueFileName: true,
        isPrivateFile: false
    });

    return result;
}

/**
 * Upload customer profile picture to /plannoraApp/customers/profile-pictures
 */
async function uploadCustomerProfilePicture(buffer, fileName, customerId = "") {
    const cleanFileName = customerId
        ? `customer_${customerId}_${Date.now()}_${fileName}`
        : `customer_${Date.now()}_${fileName}`;

    const result = await imagekit.upload({
        file: buffer.toString("base64"),
        fileName: cleanFileName,
        folder: "/plannoraApp/customers/profile-pictures",
        useUniqueFileName: true,
        isPrivateFile: false
    });

    return result;
}

module.exports = {
    uploadFreelancerProfilePicture,
    uploadCustomerProfilePicture
};