const dns = require("dns");

// DNS resolver fix for MongoDB SRV lookups on Windows
dns.setServers(["8.8.8.8", "8.8.4.4"]);

const app = require("./src/app");
const ConnectDB = require("./src/db/db");
const { startExpiryWorker } = require("./src/workers/request.expiry.worker");

// Load environment variables
require("dotenv").config();

// Fail fast instead of accepting traffic that can only answer 500.
const missingEnv = ["JWT_KEY", "MONGODB"].filter(key => !process.env[key]);

if (missingEnv.length) {
    console.error("Missing required environment variables: " + missingEnv.join(", "));
    process.exit(1);
}

let dbConnected = false;

async function startAll() {
    try {
        dbConnected = await ConnectDB();

        if (!dbConnected) {
            console.error("Could not connect to the database, shutting down");
            process.exit(1);
        }

        console.log("Connected to DATABASE");

        // Start workers
        await startWorkers();

        // Start server
        const port = Number(process.env.PORT) || 3001;

        app.listen(port, () => {
            console.log(`Server running on http://localhost:${port}`);
        });
    } catch (error) {
        console.error("Failed to start server:", error);
        process.exit(1);
    }
}

async function startWorkers() {
    startExpiryWorker();
}

startAll();