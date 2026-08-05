import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/log_service.dart';

/// Centralized Block Service
/// Engelleme işlemlerini tüm uygulama genelinde tek bir noktadan yönetir.
class BlockService {
  static final BlockService _instance = BlockService._internal();
  factory BlockService() => _instance;
  BlockService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kullanıcıyı engelle
  Future<bool> blockUser(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || targetUserId.isEmpty) return false;

    try {
      final batch = _firestore.batch();

      // 1. users/{currentUserId}/blocked_users/{targetUserId}
      final userBlockRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId);
      batch.set(userBlockRef, {
        'blockedAt': FieldValue.serverTimestamp(),
      });

      // 2. Global blocks collection
      final globalBlockRef = _firestore.collection('blocks').doc('${currentUserId}_$targetUserId');
      batch.set(globalBlockRef, {
        'blockerId': currentUserId,
        'blockedId': targetUserId,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      // 3. User document blockedUsers array
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'blockedUsers': FieldValue.arrayUnion([targetUserId]),
      });

      await batch.commit();
      LogService.i('User blocked successfully via BlockService: $targetUserId');
      return true;
    } catch (e) {
      LogService.e('Error blocking user $targetUserId in BlockService', e);
      return false;
    }
  }

  /// Engeli kaldır
  Future<bool> unblockUser(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || targetUserId.isEmpty) return false;

    try {
      final batch = _firestore.batch();

      // 1. Delete user subcollection entry
      final userBlockRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId);
      batch.delete(userBlockRef);

      // 2. Delete global blocks entry
      final globalBlockRef = _firestore.collection('blocks').doc('${currentUserId}_$targetUserId');
      batch.delete(globalBlockRef);

      // 3. Remove from user document blockedUsers array
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'blockedUsers': FieldValue.arrayRemove([targetUserId]),
      });

      await batch.commit();
      LogService.i('User unblocked successfully via BlockService: $targetUserId');
      return true;
    } catch (e) {
      LogService.e('Error unblocking user $targetUserId in BlockService', e);
      return false;
    }
  }

  /// Geçerli kullanıcının engellediği UID listesini alır
  Future<List<String>> getBlockedUserIds() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists && doc.data() != null) {
        final List<dynamic> blocked = doc.data()!['blockedUsers'] ?? [];
        return blocked.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      LogService.e('Error fetching blocked user ids', e);
      return [];
    }
  }

  /// Hedef kullanıcıyı ben mi engelledim?
  Future<bool> isBlocked(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || targetUserId.isEmpty) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Hedef kullanıcı beni engelledi mi veya ben onu engelledim mi? (Çift Yönlü Kontrol)
  Future<bool> isBlockedOrBlockedBy(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || targetUserId.isEmpty) return false;

    try {
      // 1. Ben onu engelledim mi?
      final iBlocked = await isBlocked(targetUserId);
      if (iBlocked) return true;

      // 2. O beni engelledi mi?
      final targetBlockedMeDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('blocked_users')
          .doc(currentUserId)
          .get();
      if (targetBlockedMeDoc.exists) return true;

      // 3. Global blocks koleksiyonu kontrolü
      final globalBlockDoc1 = await _firestore.collection('blocks').doc('${currentUserId}_$targetUserId').get();
      if (globalBlockDoc1.exists) return true;

      final globalBlockDoc2 = await _firestore.collection('blocks').doc('${targetUserId}_$currentUserId').get();
      if (globalBlockDoc2.exists) return true;

      return false;
    } catch (e) {
      LogService.e('Error checking isBlockedOrBlockedBy for $targetUserId', e);
      return false;
    }
  }

  /// Hem benim engellediğim hem de beni engelleyen tüm kullanıcı UID kümesini döner
  Future<Set<String>> getAllBlockedAndBlockedByIds() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return {};

    final result = <String>{};

    try {
      // 1. Benim engellediklerim
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final List<dynamic> blocked = userDoc.data()!['blockedUsers'] ?? [];
        result.addAll(blocked.map((e) => e.toString()));
      }

      // 2. Beni engelleyenler (blocks koleksiyonu)
      final blockedBySnap = await _firestore
          .collection('blocks')
          .where('blockedId', isEqualTo: currentUserId)
          .get();
      for (var doc in blockedBySnap.docs) {
        final blockerId = doc.data()['blockerId'];
        if (blockerId != null) result.add(blockerId.toString());
      }

      // 3. Benim engellediklerim (blocks koleksiyonu fallback)
      final iBlockedSnap = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: currentUserId)
          .get();
      for (var doc in iBlockedSnap.docs) {
        final blockedId = doc.data()['blockedId'];
        if (blockedId != null) result.add(blockedId.toString());
      }
    } catch (e) {
      LogService.e('Error fetching all blocked and blockedBy IDs', e);
    }

    return result;
  }
}
