require("dotenv").config();
const { v2: cloudinary } = require("cloudinary");

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

//upload single file with WebP optimization
async function uploadFile(buffer, fileName, folder = "plannora") {
    const result = await new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
            {
                resource_type: "image",
                folder: folder,
                public_id: fileName,
                format: "webp", // Convert to WebP for best compression
                quality: "auto", // Auto-optimize quality
                fetch_format: "auto" // Serve best format to client
            },
            (error, result) => {
                if (error) {
                    reject(error);
                } else {
                    resolve(result);
                }
            }
        );

        uploadStream.end(buffer);
    });

    return result;
}

//upload multiple files with WebP optimization
async function uploadMultipleFiles(files, folder = "plannora") {
    const uploadedImages = [];

    for (const file of files) {
        const fileName = `${Date.now()}-${file.originalname
            .split(".")
            .slice(0, -1)
            .join(".")}`;

        const result = await uploadFile(
            file.buffer,
            fileName,
            folder
        );

        uploadedImages.push(result.secure_url);
    }

    return uploadedImages;
}

module.exports = {
    uploadFile,
    uploadMultipleFiles
};