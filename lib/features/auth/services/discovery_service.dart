import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/log_service.dart';
import '../models/user_profile.dart';
import '../../../core/services/notification_service.dart';

class DiscoveryService {
  static final DiscoveryService _instance = DiscoveryService._internal();
  factory DiscoveryService() => _instance;
  DiscoveryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  Future<List<UserProfile>> getUsersToMatch({
    int limit = 100,
    String? gender,
    int? minAge,
    int? maxAge,
    List<String>? interests,
    int? maxDistance,
    bool verifiedOnly = false,
    bool hasPhotoOnly = true,
    bool onlineOnly = false,
    String? relationshipGoal,
  }) async {
    final user = _currentUser;
    if (user == null) return [];

    try {
      // 1. Get swipe history to exclude
      final swipedIdsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('swipes')
          .get();
      
      final Set<String> swipedIds = swipedIdsSnapshot.docs.map((doc) => doc.id).toSet();
      swipedIds.add(user.uid); 
      
      // 1.5 Engellenen kullanıcıları elenenler listesine ekle
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final blockedUsers = List<String>.from(userDoc.data()?['blockedUsers'] ?? []);
        swipedIds.addAll(blockedUsers);
      }

      // Get current user's location for distance filtering
      UserProfile? currentUserProfile;
      if (maxDistance != null && userDoc.exists) {
        currentUserProfile = UserProfile.fromMap(userDoc.data()!);
      }

      // 2. Fetch users with basic filters
      Query activeQuery = _firestore.collection('users');
      // Relax server-side: removed isIncognitoMode = false filter because existing 
      // users might miss this field.
      
      // Gender Filter
      if (gender != null && gender != 'all' && gender != 'other') {
        activeQuery = activeQuery.where('gender', isEqualTo: gender == 'male' ? 'Erkek' : 'Kadın');
      }

      // Interests Filter (Optimization: Use array-contains-any for server-side filtering)
      if (interests != null && interests.isNotEmpty) {
        // Firestore limits array-contains-any to 10 elements
        activeQuery = activeQuery.where('interests', arrayContainsAny: interests.take(10).toList());
      }
      
      QuerySnapshot snapshot;
      try {
        snapshot = await activeQuery.limit(limit * 3).get();
      } catch (e) {
        LogService.w("Query failed, trying fallback: $e");
        snapshot = await _firestore.collection('users').limit(limit * 3).get();
      }


      final users = snapshot.docs
          .where((doc) => !swipedIds.contains(doc.id))
          .map((doc) {
            try {
              return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
            } catch (e) {
              LogService.e("Error parsing user profile for ${doc.id}", e);
              return null;
            }
          })
          .where((profile) => profile != null)
          .cast<UserProfile>()
          .where((profile) {
            // Incognito filter (Client-side to handle missing fields)
            if (profile.isIncognitoMode) return false;

            // Relax completion check to allow showing all registered users
            // if (!profile.isComplete) return false;
            
            if (profile.name.isEmpty) return false;
            
            if (profile.name.toLowerCase().contains('test') || 
                profile.email.toLowerCase().contains('test')) {
              return false;
            }
            // Age filter - only if we have enough results
            if (snapshot.docs.length > 5) {
              if (minAge != null && profile.age < minAge) return false;
              if (maxAge != null && profile.age > maxAge) return false;
            }

            // === ADVANCED FILTERS (Client-side) ===

            // Distance filter
            if (maxDistance != null && currentUserProfile != null &&
                currentUserProfile.latitude != null && currentUserProfile.longitude != null) {
              if (profile.latitude != null && profile.longitude != null) {
                final distanceKm = _calculateDistanceKm(
                  currentUserProfile.latitude!, currentUserProfile.longitude!,
                  profile.latitude!, profile.longitude!,
                );
                if (distanceKm > maxDistance) return false;
              }
              // Eğer profilde konum yoksa ve mesafe filtresi varsa, gösterme
              // (ancak az kullanıcı varsa yine de göster)
              else if (snapshot.docs.length > 10) {
                return false;
              }
            }

            // Verified-only filter
            if (verifiedOnly && profile.isVerified != true) return false;

            // Photo filter
            if (hasPhotoOnly) {
              if (profile.imageUrl.isEmpty) {
                return false;
              }
            }

            // Online-only filter (active in last 15 minutes)
            if (onlineOnly) {
              final minutesSinceActive = DateTime.now().difference(profile.lastActive).inMinutes;
              if (minutesSinceActive > 15) return false;
            }

            // Relationship goal filter
            if (relationshipGoal != null && relationshipGoal != 'all' && relationshipGoal.isNotEmpty) {
              if (profile.relationshipGoal != null && profile.relationshipGoal!.isNotEmpty) {
                if (profile.relationshipGoal != relationshipGoal) return false;
              }
            }

            return true;
          })
          .toList();

      // SMART RANKING v2.0
      final currentProfile = currentUserProfile ?? await _getProfileSync(user.uid);
      if (currentProfile != null) {
        users.sort((a, b) {
          final scoreA = _calculateCompatibilityScore(currentProfile, a);
          final scoreB = _calculateCompatibilityScore(currentProfile, b);
          return scoreB.compareTo(scoreA); // High score first
        });
      }

      LogService.i("Final discovery fetch: Found ${users.length} users ranked by score (filters: gender=$gender, age=$minAge-$maxAge, dist=$maxDistance, verified=$verifiedOnly, photo=$hasPhotoOnly, online=$onlineOnly, goal=$relationshipGoal)");
      return users.take(limit).toList();
    } catch (e) {
      LogService.e("Critical failure in discovery query", e);
      return [];
    }
  }

  /// Calculate approximate distance between two coordinates in kilometers (Haversine)
  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }


  Future<bool> swipeUser(String targetUserId, {String swipeType = 'like'}) async {
    final user = _currentUser;
    if (user == null) return false;

    final isLike = swipeType == 'like' || swipeType == 'super_like';

    try {
      // 1. Record Swipe in my swipes collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('swipes')
          .doc(targetUserId)
          .set({
        'type': swipeType,
        'targetId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      LogService.i("Swipe recorded for $targetUserId: ${isLike ? 'like' : 'dislike'}");

      if (!isLike) return false;

      // Beğeniler, eşleşmeler ve bildirimler artık onSwipeCreated veritabanı 
      // tetikleyicisi (Cloud Function) ile sunucu tarafında güvenli olarak işlenmektedir.
      LogService.i("Checking for match with $targetUserId (read-only)...");
      
      final matchDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('swipes')
          .doc(user.uid)
          .get();

      if (matchDoc.exists && (matchDoc.data()?['type'] == 'like' || matchDoc.data()?['type'] == 'super_like')) {
        LogService.i("MATCH DETECTED! Handled by server.");
        return true; // Eşleşme gerçekleşti UI feedback tetiklenebilir
      }

      return false;
    } catch (e) {
      LogService.e("Swipe Error", e);
      return false;
    }
  }

  Future<void> incrementSwipeCount() async {
    final user = _currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month}-${now.day}";

    final statsRef = _firestore.collection('users').doc(user.uid).collection('stats').doc('swipes');
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(statsRef);
      if (!snapshot.exists) {
        transaction.set(statsRef, {
          'lastSwipeDate': dateKey,
          'count': 1,
        });
      } else {
        final data = snapshot.data()!;
        if (data['lastSwipeDate'] == dateKey) {
          transaction.update(statsRef, {'count': FieldValue.increment(1)});
        } else {
          transaction.update(statsRef, {
            'lastSwipeDate': dateKey,
            'count': 1,
          });
        }
      }
    });
  }

  Future<int> getDailySwipeCount() async {
    final user = _currentUser;
    if (user == null) return 0;

    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month}-${now.day}";

    final snapshot = await _firestore.collection('users').doc(user.uid).collection('stats').doc('swipes').get();
    if (!snapshot.exists) return 0;

    final data = snapshot.data()!;
    if (data['lastSwipeDate'] == dateKey) {
      return data['count'] ?? 0;
    }
    return 0;
  }

  Future<void> incrementSuperLikeCount() async {
    final user = _currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month}-${now.day}";

    final statsRef = _firestore.collection('users').doc(user.uid).collection('stats').doc('super_likes');
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(statsRef);
      if (!snapshot.exists) {
        transaction.set(statsRef, {
          'lastDate': dateKey,
          'count': 1,
        });
      } else {
        final data = snapshot.data()!;
        if (data['lastDate'] == dateKey) {
          transaction.update(statsRef, {'count': FieldValue.increment(1)});
        } else {
          transaction.update(statsRef, {
            'lastDate': dateKey,
            'count': 1,
          });
        }
      }
    });
  }

  Future<int> getDailySuperLikeCount() async {
    final user = _currentUser;
    if (user == null) return 0;

    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month}-${now.day}";

    final snapshot = await _firestore.collection('users').doc(user.uid).collection('stats').doc('super_likes').get();
    if (!snapshot.exists) return 0;

    final data = snapshot.data()!;
    if (data['lastDate'] == dateKey) {
      return data['count'] ?? 0;
    }
    return 0;
  }

  Future<void> activateBoost() async {
    final user = _currentUser;
    if (user == null) return;

    // Boost duration: 30 minutes
    final boostUntil = DateTime.now().add(const Duration(minutes: 30));
    
    await _firestore.collection('users').doc(user.uid).update({
      'boostUntil': Timestamp.fromDate(boostUntil),
    });
    
    LogService.i("Boost activated for ${user.uid} until $boostUntil");
  }

  Future<void> sendNotification(String targetUid, {required String type, required String title, required String body}) async {
    try {
      await _firestore.collection('users').doc(targetUid).collection('notifications').add({
        'type': type,
        'title': title,
        'body': body,
        'senderId': _currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      // REAL PUSH NOTIFICATION VIA NEXT.JS
      await NotificationService().sendPushNotification(
        targetUid: targetUid,
        title: title,
        body: body,
        data: {
          'type': type,
          'senderId': _currentUser?.uid,
          'clickAction': 'FLUTTER_NOTIFICATION_CLICK'
        }
      );
    } catch (e) {
      LogService.e("Notification delivery failed", e);
    }
  }




  Future<List<UserProfile>> getMatchedUsers() async {
    final user = _currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('matches')
          .where('userIds', arrayContains: user.uid)
          .get();

      final matchesDataList = snapshot.docs.map((doc) => doc.data()).toList();
      
      // Sort by timestamp descending in memory
      matchesDataList.sort((a, b) {
        final tA = a['timestamp'] as Timestamp?;
        final tB = b['timestamp'] as Timestamp?;
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });

      final otherUserIds = matchesDataList.map((data) {
        List userIds = data['userIds'];
        var otherId = userIds.firstWhere((id) => id != user.uid, orElse: () => null);
        return otherId;
      }).where((id) => id != null).cast<String>().toList();

      if (otherUserIds.isEmpty) return [];

      // chunking results for 'whereIn' limitation (max 10)
      final List<UserProfile> matches = [];
      for (var i = 0; i < otherUserIds.length; i += 10) {
        final chunk = otherUserIds.skip(i).take(10).toList();
        final usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        matches.addAll(usersSnapshot.docs.map((doc) => UserProfile.fromMap(doc.data())));
      }

      return matches;
    } catch (e) {
      LogService.e("Get Matched Users Error", e);
      return [];
    }
  }

  Future<List<UserProfile>> getActiveUsers({int limit = 15}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('lastActive', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();
    } catch (e) {
      LogService.e("Error fetching active users", e);
      return [];
    }
  }
  Stream<List<String>> getMatchedUserIdsStream() {
    final user = _currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('matches')
        .where('userIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            List userIds = doc['userIds'];
            return userIds.firstWhere((id) => id != user.uid, orElse: () => '') as String;
          }).where((id) => id.isNotEmpty).toList();
        });
  }

  /// Beni beğenen kullanıcıları getir
  Future<List<UserProfile>> getLikedMeUsers() async {
    final user = _currentUser;
    if (user == null) return [];

    try {
      // Direkt kendi likes koleksiyonumdan beğenenleri çek
      final likesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('likes')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      if (likesSnapshot.docs.isEmpty) {
        LogService.i("No likes found for current user");
        return [];
      }

      // Beğenen kullanıcı ID'lerini çıkar
      final likerUids = likesSnapshot.docs
          .map((doc) => doc.data()['fromUserId'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();

      LogService.i("Found ${likerUids.length} users who liked me");

      if (likerUids.isEmpty) return [];

      // Profilleri getir (10'arlık chunk'lar halinde)
      final List<UserProfile> likers = [];
      for (var i = 0; i < likerUids.length; i += 10) {
        final chunk = likerUids.skip(i).take(10).toList();
        final usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        likers.addAll(usersSnapshot.docs.map((doc) => UserProfile.fromMap(doc.data())));
      }

      return likers;
    } catch (e) {
      LogService.e("Get Liked Me Users Error", e);
      return [];
    }
  }

  /// Beğeniyi kabul et (like back) - Eşleşme oluştur
  Future<bool> likeBack(String targetUserId) async {
    final user = _currentUser;
    if (user == null) return false;

    try {
      // Bu aslında normal bir beğeni, ama zaten bizi beğenmiş biri olduğu için eşleşme olacak
      final matched = await swipeUser(targetUserId, swipeType: 'like');
      
      if (matched) {
        // Eşleşme olduysa, likes koleksiyonundan kaldırılabilir (viewed olarak işaretle)
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('likes')
            .doc(targetUserId)
            .update({'viewed': true, 'matched': true});
      }
      
      return matched;
    } catch (e) {
      LogService.e("Like back error", e);
      return false;
    }
  }

  /// Beğeniyi reddet
  Future<void> rejectLike(String targetUserId) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      // Kendi swipes koleksiyonuma 'dislike' olarak kaydet
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('swipes')
          .doc(targetUserId)
          .set({
        'type': 'dislike',
        'targetId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Likes koleksiyonundan kaldır veya işaretle
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('likes')
          .doc(targetUserId)
          .delete();

      LogService.i("Rejected like from $targetUserId");
    } catch (e) {
      LogService.e("Reject like error", e);
    }
  }

  // --- PRIVATE HELPERS ---

  Future<UserProfile?> _getProfileSync(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  int _calculateCompatibilityScore(UserProfile current, UserProfile other) {
    int score = 0;

    // 1. Common Interests (+10 each)
    final commonInterests = current.interests.where((i) => other.interests.contains(i)).length;
    score += commonInterests * 10;

    // 2. Profile Completeness (+5 bio, +5 many photos)
    if (other.bio != null && other.bio!.isNotEmpty) score += 5;
    if ((other.photoUrls?.length ?? 0) >= 3) score += 5;

    // 3. Activity (+5 if active in last 24h)
    final hoursSinceActive = DateTime.now().difference(other.lastActive).inHours;
    if (hoursSinceActive < 24) score += 5;

    // 4. Distance Penalty (-1 per 10km, max -30)
    if (current.latitude != null && current.longitude != null && 
        other.latitude != null && other.longitude != null) {
      // Very basic distance approximation for scoring (not for precision)
      final dLat = (current.latitude! - other.latitude!).abs();
      final dLon = (current.longitude! - other.longitude!).abs();
      final approxKm = (dLat + dLon) * 111; // 1 degree ~ 111km
      score -= (approxKm / 10).clamp(0, 30).toInt();
    }

    // 5. Premium Boost (+100)
    if (other.isBoosted) score += 100;

    return score;
  }

  /// Profil ziyaretini kaydet
  Future<void> trackVisit(String targetUserId) async {
    final myUid = _currentUser?.uid;
    if (myUid == null || myUid == targetUserId) return;

    try {
      final visitRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('visitors')
          .doc(myUid);

      // Sadece 24 saatte bir güncelle (spam önlemek için)
      final doc = await visitRef.get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['timestamp'] != null) {
          final lastVisit = (data['timestamp'] as Timestamp).toDate();
          if (DateTime.now().difference(lastVisit) < const Duration(hours: 24)) {
            return;
          }
        }
      }

      await visitRef.set({
        'fromUserId': myUid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      LogService.d("Tracked visit from $myUid to $targetUserId");
    } catch (e) {
      LogService.e("Track visit error", e);
    }
  }

  /// Profilimi ziyaret edenleri getir
  Future<List<UserProfile>> getProfileVisitors() async {
    final uid = _currentUser?.uid;
    if (uid == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('visitors')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      if (snapshot.docs.isEmpty) return [];

      final visitorIds = snapshot.docs.map((doc) => doc.id).toList();
      
      final List<UserProfile> visitors = [];
      for (var i = 0; i < visitorIds.length; i += 10) {
        final chunk = visitorIds.skip(i).take(10).toList();
        final usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        visitors.addAll(usersSnapshot.docs.map((doc) => UserProfile.fromMap(doc.data())));
      }

      return visitors;
    } catch (e) {
      LogService.e("Get visitors error", e);
      return [];
    }
  }
}


