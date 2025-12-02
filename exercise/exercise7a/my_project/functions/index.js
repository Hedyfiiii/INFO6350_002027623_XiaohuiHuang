// File: functions/index.js
// Firebase Cloud Functions v2 for automatic push notifications

const {onDocumentUpdated, onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

initializeApp();

// Trigger when face detection completes
exports.sendFaceDetectionNotification = onDocumentUpdated(
    "images/{imageId}",
    async (event) => {
      const newData = event.data.after.data();
      const oldData = event.data.before.data();

      // Check if face detection just completed
      if (
        oldData.face_detection_status === "pending" &&
        newData.face_detection_status === "completed"
      ) {
        const fcmToken = newData.fcm_token;

        if (!fcmToken) {
          console.log("No FCM token found for image:", event.params.imageId);
          return null;
        }

        const faceCount = newData.face_count || 0;
        const hasFace = newData.has_face || false;

        // Prepare notification message
        const message = {
          notification: {
            title: "Face Detection Complete! ✅",
            body: hasFace ?
              `Found ${faceCount} face(s) in your image` :
              "No faces detected in your image",
          },
          data: {
            image_id: event.params.imageId,
            face_count: String(faceCount),
            has_face: String(hasFace),
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "high_importance_channel",
              color: "#4CAF50",
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
          token: fcmToken,
        };

        try {
          const response = await getMessaging().send(message);
          console.log("Successfully sent notification:", response);

          // Mark notification as sent
          await getFirestore()
              .collection("images")
              .doc(event.params.imageId)
              .update({
                notification_sent: true,
                notification_sent_at: FieldValue.serverTimestamp(),
              });

          return response;
        } catch (error) {
          console.error("Error sending notification:", error);

          // Log error in Firestore
          await getFirestore()
              .collection("images")
              .doc(event.params.imageId)
              .update({
                notification_error: error.message,
                notification_sent: false,
              });

          return null;
        }
      }

      return null;
    },
);

// Optional: Send notification when image is uploaded
exports.sendUploadNotification = onDocumentCreated(
    "images/{imageId}",
    async (event) => {
      const data = event.data.data();
      const fcmToken = data.fcm_token;

      if (!fcmToken) {
        console.log("No FCM token found");
        return null;
      }

      const message = {
        notification: {
          title: "Image Uploaded! 📸",
          body: "Your image is being analyzed. " +
            "You'll receive another notification when complete.",
        },
        data: {
          image_id: event.params.imageId,
          status: "uploaded",
        },
        token: fcmToken,
      };

      try {
        const response = await getMessaging().send(message);
        console.log("Upload notification sent:", response);
        return response;
      } catch (error) {
        console.error("Error sending upload notification:", error);
        return null;
      }
    },
);