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

const { RtcTokenBuilder, RtcRole } = require("agora-access-token");

const AGORA_APP_ID = "0b227b12c2e54a2e9f5f20b30653c198";
const AGORA_APP_CERTIFICATE = "8b5ba9f9ef6f4606ac52ff53022228a7";

exports.generateAgoraToken = functions.https.onCall((data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Bu islemi gerceklestirmek icin giris yapmalisiniz."
    );
  }

  const channelName = data.channelName;
  const uid = data.uid || 0;
  const role = data.role === "publisher" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

  if (!channelName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Kanal adi (channelName) belirtilmelidir."
    );
  }

  const expirationTimeInSeconds = 3600; // 1 saat gecerli
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  try {
    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      uid,
      role,
      privilegeExpiredTs
    );
    return { token: token };
  } catch (error) {
    console.error("Agora Token Generation Error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Token olusturulurken bir hata olustu."
    );
  }
});

exports.onSwipeCreated = functions.firestore
  .document("users/{userId}/swipes/{targetId}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (!data) return null;

    const userId = context.params.userId;
    const targetId = context.params.targetId;
    const swipeType = data.type || "like";

    if (swipeType !== "like" && swipeType !== "super_like") {
      return null;
    }

    const db = admin.firestore();

    try {
      // 1. Add to target user's likes sub-collection (who liked them)
      await db.collection("users").doc(targetId).collection("likes").doc(userId).set({
        fromUserId: userId,
        type: swipeType,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        viewed: false,
      });

      // 2. Check if target user also swiped like/super_like on us
      const targetSwipeDoc = await db
        .collection("users")
        .doc(targetId)
        .collection("swipes")
        .doc(userId)
        .get();

      if (targetSwipeDoc.exists) {
        const targetSwipeType = targetSwipeDoc.data().type;
        if (targetSwipeType === "like" || targetSwipeType === "super_like") {
          // MATCH FOUND!
          const matchId = userId < targetId ? `${userId}_${targetId}` : `${targetId}_${userId}`;

          // Create match record
          await db.collection("matches").doc(matchId).set({
            userIds: [userId, targetId],
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            seenBy: [],
          });

          // Create conversation record
          await db.collection("conversations").doc(matchId).set({
            userIds: [userId, targetId],
            lastMessage: "Eslestiniz! 🎉 Ilk mesaji sen gonder.",
            lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
            lastMessageSenderId: "system",
            unreadCounts: {
              [userId]: 0,
              [targetId]: 0,
            },
          });

          // Increment match counts
          await db.collection("users").doc(userId).update({
            matchCount: admin.firestore.FieldValue.increment(1),
          });
          await db.collection("users").doc(targetId).update({
            matchCount: admin.firestore.FieldValue.increment(1),
          });

          // Update likes status
          await db.collection("users").doc(userId).collection("likes").doc(targetId).set({
            fromUserId: targetId,
            type: targetSwipeType,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            viewed: true,
            matched: true,
          }, { merge: true });

          await db.collection("users").doc(targetId).collection("likes").doc(userId).set({
            fromUserId: userId,
            type: swipeType,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            viewed: true,
            matched: true,
          }, { merge: true });

          // Send match notifications via triggers
          await db.collection("users").doc(userId).collection("notifications").add({
            type: "match",
            title: "Eslesme! 🎉",
            body: "Tebrikler, yeni bir eslesmen var!",
            senderId: targetId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
          });

          await db.collection("users").doc(targetId).collection("notifications").add({
            type: "match",
            title: "Eslesme! 🎉",
            body: "Tebrikler, yeni bir eslesmen var!",
            senderId: userId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
          });
        }
      } else {
        // Send like notification
        await db.collection("users").doc(targetId).collection("notifications").add({
          type: "like",
          title: "Biri seni begendi 💖",
          body: "Seni begenenleri gormek icin hemen tikla!",
          senderId: userId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
        });
      }
    } catch (e) {
      console.error("Error in onSwipeCreated trigger:", e);
    }
    return null;
  });
