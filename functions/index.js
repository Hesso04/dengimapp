const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onNotificationCreated = functions.firestore
  .document("users/{userId}/notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (!data) return null;

    const userId = context.params.userId;
    const title = data.title || "Yeni Bildirim";
    const body = data.body || "";
    const type = data.type || "general";
    const senderId = data.senderId || "";
    const chatId = data.chatId || "";

    try {
      // Get target user profile to read their FCM token
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (!userDoc.exists) {
        console.log(`User ${userId} does not exist.`);
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        console.log(`User ${userId} has no FCM token.`);
        return null;
      }

      // Build payload
      const message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type,
          senderId: senderId,
          chatId: chatId,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
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
      };

      // Send via Firebase Admin SDK (V1 API compatible)
      const response = await admin.messaging().send(message);
      console.log("Successfully sent push notification to:", userId, "responseId:", response);
      return response;
    } catch (error) {
      console.error("Error sending push notification:", error);
      return null;
    }
  });
