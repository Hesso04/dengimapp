import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/models/user_profile.dart';
import '../../features/auth/services/discovery_service.dart';
import '../utils/log_service.dart';

class LikesProvider extends ChangeNotifier {
  List<UserProfile> _matches = [];
  List<UserProfile> _likedMeUsers = [];
  bool _isLoading = false;
  final DiscoveryService _discoveryService = DiscoveryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _likesSubscription;
  StreamSubscription? _matchesSubscription;

  List<UserProfile> get matches => _matches;
  List<UserProfile> get likedMeUsers => _likedMeUsers;
  bool get isLoading => _isLoading;
  int get pendingLikesCount => _likedMeUsers.length;

  /// Stream ile beğenileri dinle
  void initStreams() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Likes stream
    _likesSubscription?.cancel();
    _likesSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('likes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      await _fetchLikedMeProfiles(snapshot.docs);
    }, onError: (e) {
      LogService.e("Likes stream error", e);
    });

    // Matches stream (In-memory sorting to prevent Firestore composite index exception)
    _matchesSubscription?.cancel();
    _matchesSubscription = _firestore
        .collection('matches')
        .where('userIds', arrayContains: uid)
        .snapshots()
        .listen((snapshot) async {
      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final tA = (a.data())['timestamp'] as Timestamp?;
          final tB = (b.data())['timestamp'] as Timestamp?;
          if (tA == null && tB == null) return 0;
          if (tA == null) return 1;
          if (tB == null) return -1;
          return tB.compareTo(tA);
        });
      await _fetchMatchProfiles(docs, uid);
    }, onError: (e) {
      LogService.e("Matches stream error", e);
    });
  }

  Future<void> _fetchLikedMeProfiles(List<QueryDocumentSnapshot> likeDocs) async {
    if (likeDocs.isEmpty) {
      _likedMeUsers = [];
      notifyListeners();
      return;
    }

    final likerIds = likeDocs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data != null && data['matched'] != true;
        })
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final fromId = data['fromUserId'] as String?;
          return (fromId != null && fromId.isNotEmpty) ? fromId : doc.id;
        })
        .where((id) => id.isNotEmpty)
        .toList();

    if (likerIds.isEmpty) {
      _likedMeUsers = [];
      notifyListeners();
      return;
    }

    // Profilleri getir
    final List<UserProfile> profiles = [];
    for (var i = 0; i < likerIds.length; i += 10) {
      final chunk = likerIds.skip(i).take(10).toList();
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      profiles.addAll(snapshot.docs.map((doc) => UserProfile.fromMap(doc.data())));
    }

    _likedMeUsers = profiles;
    notifyListeners();
  }

  Future<void> _fetchMatchProfiles(List<QueryDocumentSnapshot> matchDocs, String myUid) async {
    if (matchDocs.isEmpty) {
      _matches = [];
      notifyListeners();
      return;
    }

    final otherUserIds = matchDocs.map((doc) {
      final userIds = List<String>.from(doc['userIds']);
      return userIds.firstWhere((id) => id != myUid, orElse: () => '');
    }).where((id) => id.isNotEmpty).toList();

    if (otherUserIds.isEmpty) {
      _matches = [];
      notifyListeners();
      return;
    }

    // Profilleri getir
    final List<UserProfile> profiles = [];
    for (var i = 0; i < otherUserIds.length; i += 10) {
      final chunk = otherUserIds.skip(i).take(10).toList();
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      profiles.addAll(snapshot.docs.map((doc) => UserProfile.fromMap(doc.data())));
    }

    _matches = profiles;
    notifyListeners();
  }

  Future<void> loadMatches() async {
    _isLoading = true;
    notifyListeners();

    try {
      _matches = await _discoveryService.getMatchedUsers();
      LogService.i("Loaded ${_matches.length} matches.");
    } catch (e) {
      LogService.e("Error loading matches", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLikedMeUsers() async {
    try {
      _likedMeUsers = await _discoveryService.getLikedMeUsers();
      LogService.i("Loaded ${_likedMeUsers.length} users who liked me.");
    } catch (e) {
      LogService.e("Error loading liked me users", e);
    }
    notifyListeners();
  }

  /// Beğeniyi kabul et (like back) - eşleşme oluştur
  Future<bool> likeBack(String targetUserId) async {
    try {
      final matched = await _discoveryService.likeBack(targetUserId);
      if (matched) {
        // Listedeki kullanıcıyı kaldır
        _likedMeUsers.removeWhere((u) => u.uid == targetUserId);
        // Eşleşmeleri yeniden yükle
        await loadMatches();
      }
      notifyListeners();
      return matched;
    } catch (e) {
      LogService.e("Like back error in provider", e);
      return false;
    }
  }

  /// Beğeniyi reddet
  Future<void> rejectLike(String targetUserId) async {
    try {
      await _discoveryService.rejectLike(targetUserId);
      _likedMeUsers.removeWhere((u) => u.uid == targetUserId);
      notifyListeners();
    } catch (e) {
      LogService.e("Reject like error in provider", e);
    }
  }

  @override
  void dispose() {
    _likesSubscription?.cancel();
    _matchesSubscription?.cancel();
    super.dispose();
  }
}
