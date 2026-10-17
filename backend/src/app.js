const express = require("express");
const cookieParser = require("cookie-parser");
const cors = require("cors");

const authroute = require("./routes/auth.route");
const freelancerroute = require("./routes/freelancer.route");
const customerroute = require("./routes/customer.route");
const requestroute = require("./routes/request.route");
const freelancerRequestRoute = require("./routes/freelancerrequest.route");
const notificationRoute = require("./routes/notification.route");

require("dotenv").config();

const app = express();

app.set("trust proxy", 1);

// CORS Configuration - Allow local development and production
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);

    // List of allowed origins
    const allowedOrigins = [
      "https://plannoraapp-1.onrender.com",
      process.env.FRONTEND_URL,
    ];

    // Allow localhost and 127.0.0.1 on any port in development
    if (
      origin.startsWith("http://localhost:") ||
      origin.startsWith("http://127.0.0.1:") ||
      origin === "http://localhost" ||
      origin === "http://127.0.0.1" ||
      origin === "chrome-extension://" ||
      origin.includes("localhost") ||
      origin.includes("127.0.0.1")
    ) {
      return callback(null, true);
    }

    // Check if origin is in allowed list
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    // Not allowed
    callback(new Error("Not allowed by CORS"));
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
  optionsSuccessStatus: 200,
};

app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({
    extended: true
}));
app.use(cookieParser());

// Routes
app.get("/health", (req, res) => {
    res.json({ message: "running 120 code" });
});
app.use("/api/auth", authroute);
app.use("/api/freelancer", freelancerroute);
app.use("/api/customer", customerroute);
app.use("/api/request", requestroute);
app.use("/api/freelancer-request", freelancerRequestRoute);
app.use("/api/notifications", notificationRoute);

module.exports = app;