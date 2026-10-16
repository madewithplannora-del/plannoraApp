const https = require("https");
const notificationModel = require("../models/notification.model");
const requestModel = require("../models/request.model");
const freelancerModel = require("../models/freelancer.model");
const authModel = require("../models/auth.model");
const requestProgressModel = require("../models/requestProgress.model");
const freelancerProgressModel = require("../models/freelancerProgress.model");
const sendmail = require("./email.service");

/**
 * Send push notification to a mobile device
 * Supports Expo Push Notifications (standard for mobile apps)
 */
async function sendPushNotificationToDevice(pushToken, { title, message, data = {} }) {
    if (!pushToken || typeof pushToken !== "string") {
        return false;
    }

    try {
        const payload = JSON.stringify({
            to: pushToken,
            sound: "default",
            title: title,
            body: message,
            data: data,
            priority: "high"
        });

        return new Promise((resolve) => {
            const req = https.request(
                "https://exp.host/--/api/v2/push/send",
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "Content-Length": Buffer.byteLength(payload),
                        "Accept": "application/json",
                        "Accept-Encoding": "gzip, deflate"
                    },
                    timeout: 5000
                },
                (res) => {
                    let responseData = "";
                    res.on("data", (chunk) => (responseData += chunk));
                    res.on("end", () => {
                        console.log(`[Push Notification: Phone] Sent to ${pushToken.substring(0, 20)}... (Status ${res.statusCode})`);
                        resolve(true);
                    });
                }
            );

            req.on("error", (err) => {
                console.error("Push notification network error:", err.message);
                resolve(false);
            });

            req.on("timeout", () => {
                req.destroy();
                resolve(false);
            });

            req.write(payload);
            req.end();
        });
    } catch (err) {
        console.error("Failed to send push notification:", err.message);
        return false;
    }
}

/**
 * Create an in-app phone notification and trigger push if device token exists
 */
async function createInAppNotification({
    recipientId,
    recipientModel = "freelancers",
    title,
    message,
    type = "GENERAL",
    requestId = null,
    pushToken = null
}) {
    try {
        const notification = await notificationModel.create({
            recipientId,
            recipientModel,
            title,
            message,
            type,
            requestId
        });

        // If a device push token is available, buzz their phone screen
        if (pushToken) {
            sendPushNotificationToDevice(pushToken, {
                title,
                message,
                data: {
                    notificationId: notification._id.toString(),
                    type,
                    requestId: requestId ? requestId.toString() : null
                }
            });
        }

        return notification;
    } catch (error) {
        console.error("Error creating in-app notification:", error.message);
        return null;
    }
}

/**
 * Notify waitlisted freelancer that a spot is now free
 * (PHONE NOTIFICATION ONLY - In-App + Lock Screen Push - No Email)
 */
async function notifyWaitlistSlotAvailable(requestId, freelancerId) {
    try {
        const [request, freelancer] = await Promise.all([
            requestModel.findById(requestId).lean(),
            freelancerModel.findById(freelancerId).lean()
        ]);

        const eventName = request?.event_details || request?.category || "an event";
        const title = "Spot Available!";
        const message = `A slot just opened up for "${eventName}". You can now accept this request before slots fill up!`;

        let pushToken = freelancer?.pushToken || null;
        if (!pushToken && freelancer?.userId) {
            const user = await authModel.findById(freelancer.userId).select("pushToken").lean();
            pushToken = user?.pushToken || null;
        }

        const notification = await createInAppNotification({
            recipientId: freelancerId,
            recipientModel: "freelancers",
            title,
            message,
            type: "WAITLIST_SLOT_AVAILABLE",
            requestId,
            pushToken
        });

        console.log(`[Notification: Phone] Waitlist slot notification dispatched for freelancer ${freelancerId}`);
        return notification;
    } catch (error) {
        console.error("Error notifying waitlist slot available:", error.message);
        return null;
    }
}

/**
 * Notify freelancer who accepted but has NOT entered the attendance code yet
 * (BOTH EMAIL + PHONE NOTIFICATION)
 */
async function notifyAttendanceCodeReminder(requestId, freelancerId) {
    try {
        const [request, freelancer] = await Promise.all([
            requestModel.findById(requestId).lean(),
            freelancerModel.findById(freelancerId).lean()
        ]);

        if (!request || !freelancer) {
            console.error("Request or Freelancer not found for attendance reminder");
            return;
        }

        const user = await authModel.findById(freelancer.userId).lean();
        const eventName = request.event_details || request.category || "your accepted event";
        const pushToken = freelancer.pushToken || user?.pushToken || null;

        // 1. Send Phone Notification (In-App inbox + Lock Screen banner)
        const title = "Action Required: Enter Attendance Code";
        const message = `You have not yet entered the attendance code for "${eventName}". Please ask the host for the code and submit it in the app to mark your attendance.`;

        await createInAppNotification({
            recipientId: freelancerId,
            recipientModel: "freelancers",
            title,
            message,
            type: "ATTENDANCE_CODE_REMINDER",
            requestId,
            pushToken
        });
        console.log(`[Notification: Phone] Attendance code reminder phone notification sent to freelancer ${freelancerId}`);

        // 2. Send Email Notification
        if (user && user.email) {
            const subject = `Urgent Reminder: Enter Attendance Code for ${eventName}`;
            const text = `Hi ${user.username || "Freelancer"},\n\nYou have accepted the request for "${eventName}", but have not yet submitted the attendance code.\n\nPlease ask the event host for the 6-digit attendance code and submit it in the Plannora app to complete your attendance.\n\nThank you,\nTeam Plannora`;
            const html = `
                <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 8px; padding: 20px;">
                    <h2 style="color: #2563eb; margin-top: 0;">Attendance Code Required</h2>
                    <p>Hi <strong>${user.username || "Freelancer"}</strong>,</p>
                    <p>You have accepted the request for <strong>${eventName}</strong>, but our records show that you have not entered the event attendance code yet.</p>
                    <div style="background-color: #f3f4f6; border-left: 4px solid #2563eb; padding: 12px 16px; margin: 16px 0;">
                        <p style="margin: 0; font-weight: bold;">How to complete your attendance:</p>
                        <ol style="margin: 8px 0 0 16px; padding: 0;">
                            <li>Ask the customer/host at the venue for the 6-digit attendance code.</li>
                            <li>Open the Plannora app and navigate to your accepted request.</li>
                            <li>Enter the code to verify your presence.</li>
                        </ol>
                    </div>
                    <p style="color: #6b7280; font-size: 14px;">Once submitted, your attendance will be recorded immediately.</p>
                    <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;" />
                    <p style="color: #9ca3af; font-size: 12px; margin-bottom: 0;">Team Plannora</p>
                </div>
            `;

            try {
                await sendmail(user.email, subject, text, html);
                console.log(`[Notification: Email] Attendance code reminder email sent to ${user.email}`);
            } catch (mailErr) {
                console.error("Failed to send attendance email:", mailErr.message);
            }
        }
    } catch (error) {
        console.error("Error sending attendance code reminder:", error.message);
    }
}

/**
 * Notify all accepted freelancers for a request who have not yet submitted attendance code
 */
async function notifyAllPendingAttendance(requestId) {
    try {
        const progress = await requestProgressModel.findOne({ requestId }).lean();
        if (!progress || !progress.accepted || progress.accepted.length === 0) {
            return { count: 0, message: "No accepted freelancers for this request" };
        }

        let notifiedCount = 0;

        for (const freelancerId of progress.accepted) {
            const alreadyAttended = await freelancerProgressModel.findOne({
                freelancerId,
                attended: requestId
            }).lean();

            if (!alreadyAttended) {
                await notifyAttendanceCodeReminder(requestId, freelancerId);
                notifiedCount++;
            }
        }

        return {
            count: notifiedCount,
            message: `Attendance reminder sent to ${notifiedCount} pending freelancer(s)`
        };
    } catch (error) {
        console.error("Error in notifyAllPendingAttendance:", error.message);
        throw error;
    }
}

module.exports = {
    createInAppNotification,
    sendPushNotificationToDevice,
    notifyWaitlistSlotAvailable,
    notifyAttendanceCodeReminder,
    notifyAllPendingAttendance
};
