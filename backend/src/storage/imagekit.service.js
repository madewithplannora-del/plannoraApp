require("dotenv").config();

const ImageKit = require("imagekit");

const imagekit = new ImageKit({
    publicKey: process.env.IMAGEKIT_PUBLIC_KEY,
    privateKey: process.env.IMAGEKIT_PRIVATE_KEY,
    urlEndpoint: process.env.IMAGEKIT_URL_ENDPOINT
});

/**
 * Upload single file with optimization for minimal storage
 * Uses WebP format and automatic quality optimization
 */
async function uploadFile(buffer, fileName, folder = "/plannora") {
    const result = await imagekit.upload({
        file: buffer.toString("base64"),
        fileName: fileName,
        folder: folder,
        isPrivateFile: false
    });

    return result;
}

/**
 * Upload vendor profile picture with optimized transformations
 * Designed specifically for profile pictures with minimal storage footprint
 */
async function uploadVendorProfilePicture(buffer, vendorID, fileName) {
    const result = await imagekit.upload({
        file: buffer.toString("base64"),
        fileName: fileName,
        folder: "/plannora/vendor-profiles",
        useUniqueFileName: true,
        isPrivateFile: false
    });

    // Add transformation query params to URL for optimization
    const transformedUrl = result.url + "?tr=w-400,h-400,c-thumb,g-face,fo-auto,q-auto,f-webp";

    return {
        ...result,
        url: transformedUrl
    };
}

/**
 * Upload multiple files with optimization
 */
async function uploadMultipleFiles(files, folder = "/plannora") {
    const uploadedImages = [];

    for (const file of files) {
        const result = await uploadFile(
            file.buffer,
            `${Date.now()}-${file.originalname}`,
            folder
        );

        uploadedImages.push(result.url);
    }

    return uploadedImages;
}

module.exports = {
    uploadFile,
    uploadMultipleFiles,
    uploadVendorProfilePicture
};