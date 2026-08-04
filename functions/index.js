const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const REGION = "europe-west1";

// 1. Push Notification Trigger (Gen 2 Firestore Trigger)
exports.onNotificationCreated = onDocumentCreated(
  { document: "users/{userId}/notifications/{notificationId}", region: REGION },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const data = snapshot.data();
    if (!data) return;

    const userId = event.params.userId;
    let title = data.title || "Yeni Bildirim";
    let body = data.body || "";
    const type = data.type || "general";
    const senderId = data.senderId || "";
    const chatId = data.chatId || "";
    const messageId = data.messageId || "";

    try {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (!userDoc.exists) return;

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) return;

      let senderName = "Bir Üye";
      let senderAvatar = "";
      if ((type === "chat" || type === "message" || type === "chat_message") && senderId) {
        try {
          const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
          if (senderDoc.exists) {
            const senderData = senderDoc.data();
            senderName = senderData.name || senderData.fullName || "Bir Üye";
            senderAvatar = (senderData.photoUrls && senderData.photoUrls[0]) || senderData.imageUrl || "";
            title = senderName;
          }
        } catch (e) {
          console.error("Error fetching sender profile for push notify:", e);
        }
      }

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
          messageId: messageId,
          otherUserId: senderId,
          otherUserName: senderName,
          otherUserAvatar: senderAvatar,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "dengim_messages_channel",
            priority: "max",
            visibility: "public",
            icon: "ic_stat_name",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              contentAvailable: true,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log("Successfully sent push notification to:", userId, "responseId:", response);
      return response;
    } catch (error) {
      console.error("Error sending push notification:", error);
      return null;
    }
  }
);

// 2. LiveKit Access Token Generator (Gen 2 Callable Function)
const { AccessToken } = require("livekit-server-sdk");

exports.generateLiveKitToken = onCall(
  {
    region: REGION,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Bu islemi gerceklestirmek icin giris yapmalisiniz.");
    }

    const data = request.data;
    const roomName = data.roomName;

    // Güvenlik: identity'yi her zaman auth.uid'den al, client'a güvenme.
    const identity = request.auth.uid;

    if (!roomName) {
      throw new HttpsError("invalid-argument", "Oda adi (roomName) belirtilmelidir.");
    }

    const apiKey = process.env.LIVEKIT_API_KEY || "APIdbX9XXqxuL84";
    const apiSecret = process.env.LIVEKIT_API_SECRET || "9OGHaMhlAO1hhjPfQS1HJjCoGsiiQbN7GHXo5yaidP";

    try {
      const token = new AccessToken(
        apiKey,
        apiSecret,
        { identity: identity, ttl: "10m" }
      );

      token.addGrant({
        roomJoin: true,
        room: roomName,
        canPublish: true,
        canSubscribe: true,
      });

      const jwt = await token.toJwt();
      return { token: jwt };
    } catch (error) {
      console.error("LiveKit Token Generation Error:", error);
      throw new HttpsError("internal", "Token olusturulurken bir hata olustu.");
    }
  }
);

// 3. Swipe & Match Logic Trigger (Gen 2 Firestore Trigger)
exports.onSwipeCreated = onDocumentCreated(
  { document: "users/{userId}/swipes/{targetId}", region: REGION },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const data = snapshot.data();
    if (!data) return;

    const userId = event.params.userId;
    const targetId = event.params.targetId;
    const swipeType = data.type || "like";

    if (swipeType !== "like" && swipeType !== "super_like") return;

    const db = admin.firestore();

    try {
      await db.collection("users").doc(targetId).collection("likes").doc(userId).set({
        fromUserId: userId,
        type: swipeType,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        viewed: false,
      });

      const targetSwipeDoc = await db.collection("users").doc(targetId).collection("swipes").doc(userId).get();

      if (targetSwipeDoc.exists) {
        const targetSwipeType = targetSwipeDoc.data().type;
        if (targetSwipeType === "like" || targetSwipeType === "super_like") {
          const matchId = userId < targetId ? `${userId}_${targetId}` : `${targetId}_${userId}`;

          await db.collection("matches").doc(matchId).set({
            userIds: [userId, targetId],
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            seenBy: [],
          });

          const userDoc = await db.collection("users").doc(userId).get();
          const targetDoc = await db.collection("users").doc(targetId).get();

          const userProfile = {
            name: userDoc.exists ? (userDoc.data().name || "") : "",
            avatar: userDoc.exists ? (userDoc.data().photoUrls?.[0] || "") : "",
          };

          const targetProfile = {
            name: targetDoc.exists ? (targetDoc.data().name || "") : "",
            avatar: targetDoc.exists ? (targetDoc.data().photoUrls?.[0] || "") : "",
          };

          await db.collection("conversations").doc(matchId).set({
            userIds: [userId, targetId],
            lastMessage: "Eslestiniz! 🎉 Ilk mesaji sen gonder.",
            lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
            lastMessageSenderId: "system",
            unreadCounts: { [userId]: 0, [targetId]: 0 },
            userProfiles: { [userId]: userProfile, [targetId]: targetProfile }
          });

          await db.collection("users").doc(userId).update({ matchCount: admin.firestore.FieldValue.increment(1) });
          await db.collection("users").doc(targetId).update({ matchCount: admin.firestore.FieldValue.increment(1) });

          await db.collection("users").doc(userId).collection("likes").doc(targetId).set({
            fromUserId: targetId, type: targetSwipeType, timestamp: admin.firestore.FieldValue.serverTimestamp(), viewed: true, matched: true,
          }, { merge: true });

          await db.collection("users").doc(targetId).collection("likes").doc(userId).set({
            fromUserId: userId, type: swipeType, timestamp: admin.firestore.FieldValue.serverTimestamp(), viewed: true, matched: true,
          }, { merge: true });

          await db.collection("users").doc(userId).collection("notifications").add({
            type: "match", title: "Eslesme! 🎉", body: "Tebrikler, yeni bir eslesmen var!", senderId: targetId, createdAt: admin.firestore.FieldValue.serverTimestamp(), isRead: false,
          });

          await db.collection("users").doc(targetId).collection("notifications").add({
            type: "match", title: "Eslesme! 🎉", body: "Tebrikler, yeni bir eslesmen var!", senderId: userId, createdAt: admin.firestore.FieldValue.serverTimestamp(), isRead: false,
          });
        }
      } else {
        await db.collection("users").doc(targetId).collection("notifications").add({
          type: "like", title: "Biri seni begendi 💖", body: "Seni begenenleri gormek icin hemen tikla!", senderId: userId, createdAt: admin.firestore.FieldValue.serverTimestamp(), isRead: false,
        });
      }
    } catch (e) {
      console.error("Error in onSwipeCreated trigger:", e);
    }
  }
);

// 4. Cascade User Delete Trigger (Gen 2 Auth Trigger)
exports.onUserDeleted = functions.region("europe-west1").auth.user().onDelete(async (user) => {
  const userId = user.uid;
  const db = admin.firestore();
  const bucket = admin.storage().bucket();

  console.log(`Starting cascade delete for user: ${userId}`);

  try {
    try {
      await bucket.deleteFiles({ prefix: `user_photos/${userId}/` });
      console.log(`Deleted storage files for user: ${userId}`);
    } catch (err) {
      console.error(`Error deleting storage files: ${err.message}`);
    }

    const subCollections = ['swipes', 'likes', 'visitors', 'stats', 'blocked_users', 'notifications'];
    for (const coll of subCollections) {
      const snapshot = await db.collection("users").doc(userId).collection(coll).get();
      if (!snapshot.empty) {
        const batch = db.batch();
        snapshot.docs.forEach((doc) => batch.delete(doc.reference));
        await batch.commit();
      }
      console.log(`Deleted sub-collection ${coll} for user: ${userId}`);
    }

    await db.collection("users").doc(userId).delete();
    console.log(`Deleted user profile document for user: ${userId}`);

    const matchesSnapshot = await db.collection("matches").where("userIds", "arrayContains", userId).get();

    for (const matchDoc of matchesSnapshot.docs) {
      const matchId = matchDoc.id;
      const otherUserId = matchDoc.data().userIds.find(id => id !== userId);

      await matchDoc.reference.delete();

      const convRef = db.collection("conversations").doc(matchId);
      const messagesSnapshot = await convRef.collection("messages").get();
      
      const batch = db.batch();
      messagesSnapshot.docs.forEach((doc) => batch.delete(doc.reference));
      batch.delete(convRef);
      await batch.commit();

      if (otherUserId) {
        await db.collection("users").doc(otherUserId).update({
          matchCount: admin.firestore.FieldValue.increment(-1),
        }).catch(err => console.error(`Failed to decrement matchCount for ${otherUserId}:`, err));
      }
    }
    console.log(`Finished cascade delete for user: ${userId}`);
  } catch (error) {
    console.error(`Cascade delete failed for user ${userId}:`, error);
  }
});

// 5. Profile Update Trigger (Gen 2 Firestore Trigger)
exports.onUserProfileUpdated = onDocumentUpdated(
  { document: "users/{userId}", region: REGION },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const userId = event.params.userId;

    const nameChanged = before.name !== after.name;
    const photoChanged = (before.photoUrls?.[0] || "") !== (after.photoUrls?.[0] || "");

    if (!nameChanged && !photoChanged) return;

    const db = admin.firestore();
    const newName = after.name || "";
    const newAvatar = after.photoUrls?.[0] || "";

    try {
      const conversationsSnapshot = await db.collection("conversations").where("userIds", "arrayContains", userId).get();
      if (conversationsSnapshot.empty) return;

      const batch = db.batch();
      conversationsSnapshot.docs.forEach((doc) => {
        batch.update(doc.reference, {
          [`userProfiles.${userId}.name`]: newName,
          [`userProfiles.${userId}.avatar`]: newAvatar,
        });
      });
      await batch.commit();
      console.log(`Updated userProfiles for user ${userId} in ${conversationsSnapshot.size} conversations.`);
    } catch (e) {
      console.error("Error updating userProfiles in conversations:", e);
    }
  }
);

// 6. Auto Content Moderation Trigger (Gen 2 Firestore Trigger)
exports.autoModerateUserContent = onDocumentWritten(
  { document: "users/{userId}", region: REGION },
  async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists) return;
    const data = after.data();
    const userId = event.params.userId;
    const db = admin.firestore();

    const bio = data.bio || "";
    const forbiddenKeywords = ["sik", "amk", "oc", "orospu", "piç", "siktir", "whatsapp", "0532", "0533", "0541", "0542", "0555", "0505"];

    const hasForbiddenWord = forbiddenKeywords.some(word => bio.toLowerCase().includes(word));

    if (hasForbiddenWord && !data.bioFlagged) {
      console.log(`Auto-moderation flagged user ${userId} bio for forbidden keywords.`);
      await db.collection("users").doc(userId).update({
        bioFlagged: true,
        flaggedReason: "Otomatik AI Moderasyon: İhlal içeren kelime veya telefon numarası tespiti.",
      });

      await db.collection("reports").add({
        reportedUserId: userId,
        reporterId: "SYSTEM_AI_MODERATION",
        reason: "Biyografide yasaklı kelime veya iletişim bilgisi tespiti.",
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);

// 7. Auto Clean-up on User Block (Gen 2 Firestore Trigger)
exports.onUserBlocked = onDocumentCreated(
  { document: "blocks/{blockId}", region: REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const { blockerId, blockedId } = data;
    if (!blockerId || !blockedId) return;

    const db = admin.firestore();
    console.log(`Auto cleanup triggered: ${blockerId} blocked ${blockedId}`);

    try {
      // 1. Hide conversation for both users
      const conversationsSnap = await db.collection("conversations")
        .where("userIds", "arrayContains", blockerId)
        .get();

      const batch = db.batch();
      conversationsSnap.docs.forEach((doc) => {
        const userIds = doc.data().userIds || [];
        if (userIds.includes(blockedId)) {
          batch.update(doc.reference, {
            deletedFor: admin.firestore.FieldValue.arrayUnion(blockerId, blockedId)
          });
        }
      });

      // 2. Remove from matches if exists
      const matchesSnap = await db.collection("matches")
        .where("userIds", "arrayContains", blockerId)
        .get();

      matchesSnap.docs.forEach((doc) => {
        const userIds = doc.data().userIds || [];
        if (userIds.includes(blockedId)) {
          batch.delete(doc.reference);
        }
      });

      await batch.commit();
      console.log(`Successfully cleaned up conversation & matches for block: ${blockerId} -> ${blockedId}`);
    } catch (e) {
      console.error("Error in onUserBlocked trigger:", e);
    }
  }
);
