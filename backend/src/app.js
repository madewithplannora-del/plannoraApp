const express = require("express");
const cookieParser = require("cookie-parser");

const authroute = require("./routes/auth.route");
const freelancerroute = require("./routes/freelancer.route");
const customerroute = require("./routes/customer.route");
const requestroute = require("./routes/request.route");
const freelancerRequestRoute = require("./routes/freelancerrequest.route");
const notificationRoute = require("./routes/notification.route");

require("dotenv").config();

const app = express();

app.set("trust proxy", 1);

app.use(express.json());

app.use(express.urlencoded({
    extended: true
}));

app.use(cookieParser());

// Routes
app.get("/", (req, res) => {
    res.json({ message: "running" });
});
app.use("/api/auth", authroute);
app.use("/api/freelancer", freelancerroute);
app.use("/api/customer", customerroute);
app.use("/api/request", requestroute);
app.use("/api/freelancer-request", freelancerRequestRoute);
app.use("/api/notifications", notificationRoute);

module.exports = app;