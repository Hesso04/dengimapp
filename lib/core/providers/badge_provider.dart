import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/log_service.dart';

class BadgeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _chatUnreadCount = 0;
  int _matchCount = 0;
  int _likeCount = 0;

  int get chatBadge => _chatUnreadCount;
  int get likesBadge => _matchCount + _likeCount;
  int get totalBadges => chatBadge + likesBadge;

  void initialize() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Listen to unread messages (conversations collection with unreadCount or unreadCounts map)
    _firestore
        .collection('conversations')
        .where('userIds', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      int unreadCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final deletedFor = List<String>.from(data['deletedFor'] ?? []);
        if (deletedFor.contains(uid)) continue;

        final unreadMap = (data['unreadCount'] ?? data['unreadCounts']) as Map<String, dynamic>?;
        if (unreadMap != null) {
          final count = (unreadMap[uid] as num?)?.toInt() ?? 0;
          if (count > 0) {
            unreadCount += count;
          }
        }
      }
      _chatUnreadCount = unreadCount;
      notifyListeners();
    }, onError: (e) {
      LogService.e("Badge Provider: Chat listener error", e);
    });

    // Listen to new matches (unseen ones)
    _firestore
        .collection('matches')
        .where('userIds', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      _matchCount = snapshot.docs.where((doc) {
        final seenBy = List<String>.from(doc.data()['seenBy'] ?? []);
        return !seenBy.contains(uid);
      }).length;
      notifyListeners();
    }, onError: (e) {
      LogService.e("Badge Provider: Match listener error", e);
    });

    // Listen to new likes
    _firestore
        .collection('users')
        .doc(uid)
        .collection('likes')
        .where('viewed', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _likeCount = snapshot.docs.length;
      notifyListeners();
    }, onError: (e) {
      LogService.e("Badge Provider: Like listener error", e);
    });
  }

  void markChatAsRead(String conversationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCount.$uid': 0,
        'readBy': FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      LogService.e("Failed to mark chat as read", e);
    }
  }

  void markMatchesAsViewed() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _matchCount = 0;
    notifyListeners();

    try {
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('userIds', arrayContains: uid)
          .get();

      final batch = _firestore.batch();
      bool hasUpdates = false;

      for (var doc in matchesSnapshot.docs) {
        final seenBy = List<String>.from(doc.data()['seenBy'] ?? []);
        if (!seenBy.contains(uid)) {
          batch.update(doc.reference, {
            'seenBy': FieldValue.arrayUnion([uid])
          });
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) await batch.commit();
    } catch (e) {
      LogService.e("Failed to mark matches as viewed", e);
    }
  }

  void markLikesAsViewed() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _likeCount = 0;
    _matchCount = 0;
    notifyListeners();

    // Also mark matches as viewed
    markMatchesAsViewed();

    try {
      final likesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('likes')
          .where('viewed', isEqualTo: false)
          .get();

      if (likesSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in likesSnapshot.docs) {
        batch.update(doc.reference, {'viewed': true});
      }
      await batch.commit();
    } catch (e) {
      LogService.e("Failed to mark likes as viewed", e);
    }
  }
}
