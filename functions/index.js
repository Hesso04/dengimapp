const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onNotificationCreated = functions.firestore
  .document("users/{userId}/notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (!data) return null;

    const userId = context.params.userId;
    let title = data.title || "Yeni Bildirim";
    let body = data.body || "";
    const type = data.type || "general";
    const senderId = data.senderId || "";
    const chatId = data.chatId || "";
    const messageId = data.messageId || "";

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

      // If it's a message/chat notification, fetch sender name dynamically for WhatsApp-style notification
      if ((type === "chat" || type === "message" || type === "chat_message") && senderId) {
        try {
          const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
          if (senderDoc.exists) {
            const senderData = senderDoc.data();
            const senderName = senderData.name || senderData.fullName || "Bir Üye";
            title = senderName;
          }
        } catch (e) {
          console.error("Error fetching sender profile for push notify:", e);
        }
      }

      // Build FCM payload (WhatsApp / Tinder style)
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

      // Send via Firebase Admin SDK
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
  const uid = data.uid !== undefined && data.uid !== null ? Number(data.uid) : 0;
  const role = data.role === "publisher" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

  if (!channelName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Kanal adi (channelName) belirtilmelidir."
    );
  }

  const expirationTimeInSeconds = 86400; // 24 saat gecerli
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

          // Fetch profiles for both users to store denormalized names and avatars
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
            userProfiles: {
              [userId]: userProfile,
              [targetId]: targetProfile,
            }
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

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const userId = user.uid;
  const db = admin.firestore();
  const bucket = admin.storage().bucket();

  console.log(`Starting cascade delete for user: ${userId}`);

  try {
    // 1. Delete user photo folder in Firebase Storage
    try {
      await bucket.deleteFiles({
        prefix: `user_photos/${userId}/`
      });
      console.log(`Deleted storage files for user: ${userId}`);
    } catch (err) {
      console.error(`Error deleting storage files: ${err.message}`);
    }

    // 2. Delete sub-collections (swipes, likes, visitors, stats, blocked_users, notifications)
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

    // 3. Delete user document from users collection
    await db.collection("users").doc(userId).delete();
    console.log(`Deleted user profile document for user: ${userId}`);

    // 4. Handle Matches & Conversations
    const matchesSnapshot = await db
      .collection("matches")
      .where("userIds", "arrayContains", userId)
      .get();

    for (const matchDoc of matchesSnapshot.docs) {
      const matchId = matchDoc.id;
      const otherUserId = matchDoc.data().userIds.find(id => id !== userId);

      // Delete match document
      await matchDoc.reference.delete();

      // Delete conversation and messages
      const convRef = db.collection("conversations").doc(matchId);
      const messagesSnapshot = await convRef.collection("messages").get();
      
      const batch = db.batch();
      messagesSnapshot.docs.forEach((doc) => batch.delete(doc.reference));
      batch.delete(convRef);
      await batch.commit();

      // Decrement other user's matchCount
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
  return null;
});

exports.onUserProfileUpdated = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;

    const nameChanged = before.name !== after.name;
    const photoChanged = (before.photoUrls?.[0] || "") !== (after.photoUrls?.[0] || "");

    if (!nameChanged && !photoChanged) return null;

    const db = admin.firestore();
    const newName = after.name || "";
    const newAvatar = after.photoUrls?.[0] || "";

    try {
      const conversationsSnapshot = await db
        .collection("conversations")
        .where("userIds", "arrayContains", userId)
        .get();

      if (conversationsSnapshot.empty) return null;

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
    return null;
  });

// Auto Content Moderation Trigger
exports.autoModerateUserContent = functions.firestore
  .document("users/{userId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null;
    const data = change.after.data();
    const userId = context.params.userId;
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

      // Add entry to pending moderation queue
      await db.collection("reports").add({
        reportedUserId: userId,
        reporterId: "SYSTEM_AI_MODERATION",
        reason: "Biyografide yasaklı kelime veya iletişim bilgisi tespiti.",
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return null;
  });
