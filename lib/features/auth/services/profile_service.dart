import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../../../core/utils/log_service.dart';
import '../../../core/services/cloudinary_service.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  Future<void> createProfile({
    required String name,
    DateTime? birthDate,
    required String gender,
    required String country,
    required List<String> interests,
    String? relationshipGoal,
    List<String>? photoUrls,
    String? bio,
    String? job,
    String? education,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception("Kullanıcı bulunamadı");

    int initialAge = 18;
    if (birthDate != null) {
      final now = DateTime.now();
      initialAge = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        initialAge--;
      }
    }

    final userProfile = {
      'uid': user.uid,
      'email': user.email ?? '',
      'name': name,
      'age': initialAge, // ← YENİ: Security rules için gerekli
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate) : null,
      'gender': gender,
      'country': country,
      'interests': interests,
      'relationshipGoal': relationshipGoal,
      'bio': bio,
      'job': job,
      'education': education,
      'photoUrls': photoUrls,
      'isPremium': true,
      'subscriptionTier': 'gold',
      'credits': 1000,
      'hasReceivedWelcomeBonus': true,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'isOnline': true,
      'blockedUsers': [], // Initialize empty
      'searchName': name.trim().toLowerCase(),
    };

    try {
      await _firestore.collection('users').doc(user.uid).set(userProfile);
      LogService.i("Profile created for: ${user.uid}");
    } catch (e) {
      LogService.e("Firestore error in createProfile", e);
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfile([String? uid]) async {
    final targetUid = uid ?? _currentUser?.uid;
    if (targetUid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(targetUid).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Backfill searchName if missing
        if (data['searchName'] == null && data['name'] != null) {
          final sName = data['name'].toString().trim().toLowerCase();
          await _firestore.collection('users').doc(targetUid).update({'searchName': sName});
          data['searchName'] = sName;
        }
        return UserProfile.fromMap(data);
      }
      return null;
    } catch (e) {
      LogService.e("Error fetching profile: $targetUid", e);
      return null;
    }
  }

  /// Profil Değişikliklerini Dinle (Realtime)
  Stream<UserProfile?> getProfileStream() {
    final uid = _currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  Future<String> uploadProfilePhoto(XFile file, String userId) async {
    try {
      final imageUrl = await CloudinaryService.uploadImage(file);
      
      if (imageUrl != null) {
        return imageUrl;
      }
      
      throw Exception("Upload returned null");
    } catch (e) {
      LogService.e("Upload failed (XFile), reverting to placeholder. UserId: $userId", e);
      return 'https://ui-avatars.com/api/?name=$userId&background=random&color=fff&size=128&font-size=0.4';
    }
  }

  Future<String?> uploadProfileVideo(XFile file) async {
    try {
      return await CloudinaryService.uploadVideo(file);
    } catch (e) {
      LogService.e("Video upload failed", e);
      return null;
    }
  }

  Future<String> uploadProfilePhotoBytes(Uint8List bytes, String userId) async {
    try {
      final imageUrl = await CloudinaryService.uploadImageBytes(bytes);
      
      if (imageUrl != null) {
        return imageUrl;
      }
      
      throw Exception("Byte upload returned null");
    } catch (e) {
      LogService.e("Upload failed (Bytes), reverting to placeholder. UserId: $userId", e);
      return 'https://ui-avatars.com/api/?name=$userId&background=random&color=fff&size=128&font-size=0.4';
    }
  }


  Future<void> updateLocation(double latitude, double longitude) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;

    String? city;
    String? district;

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=12&addressdetails=1');
      final response = await http.get(url, headers: {'User-Agent': 'DengimApp/1.0'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        if (address != null) {
          city = address['province'] ?? address['city'] ?? address['state'];
          district = address['district'] ?? address['county'] ?? address['town'] ?? address['suburb'];
          if (city != null) city = city.replaceAll(' İli', '');
        }
      }
    } catch (e) {
      LogService.e("Reverse geocoding failed", e);
    }

    try {
      final updates = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'lastActive': FieldValue.serverTimestamp(),
        'isOnline': true,
      };
      if (city != null) updates['city'] = city;
      if (district != null) updates['district'] = district;

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      LogService.e("Location update failed", e);
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
       // Silently fail for online status to avoid spamming
    }
  }

  Future<void> deleteAccount() async {
    final user = _currentUser;
    if (user == null) throw Exception("Kullanıcı bulunamadı");

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      LogService.i("Account deleted: ${user.uid}");
    } catch (e) {
      LogService.e("Delete Account Error", e);
      rethrow;
    }
  }

  Future<void> addCredits(int amount) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;
    
    try {
      await _firestore.collection('users').doc(uid).update({
        'credits': FieldValue.increment(amount),
      });
    } catch (e) {
      LogService.e("Add credits error", e);
    }
  }

  /// Kullanıcı profilini güncelle
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? job,
    String? education,
    int? age,
    String? country,
    List<String>? interests,
    String? relationshipGoal,
    List<String>? photoUrls,
    String? videoUrl,
    String? profileVoiceUrl,
    bool? isPremium,
    bool? isVerified,
    bool? isGhostMode,
    bool? isIncognitoMode,
    String? subscriptionTier,
    int? credits,
    bool? hasReceivedWelcomeBonus,
  }) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;

    final Map<String, dynamic> updates = {
      'lastActive': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      updates['name'] = name;
      updates['searchName'] = name.trim().toLowerCase();
    }
    if (bio != null) updates['bio'] = bio;
    if (job != null) updates['job'] = job;
    if (education != null) updates['education'] = education;
    if (age != null) {
      updates['age'] = age;
      // Yaş güncellenince doğum tarihini de yaklaşık olarak güncelle
      final estimatedYear = DateTime.now().year - age;
      updates['birthDate'] = Timestamp.fromDate(DateTime(estimatedYear, 1, 1));
    }
    if (country != null) updates['country'] = country;
    if (interests != null) updates['interests'] = interests;
    if (relationshipGoal != null) updates['relationshipGoal'] = relationshipGoal;
    if (photoUrls != null) updates['photoUrls'] = photoUrls;
    if (videoUrl != null) updates['videoUrl'] = videoUrl;
    if (profileVoiceUrl != null) updates['profileVoiceUrl'] = profileVoiceUrl;
    if (isPremium != null) updates['isPremium'] = isPremium;
    if (isVerified != null) updates['isVerified'] = isVerified;
    if (isGhostMode != null) updates['isGhostMode'] = isGhostMode;
    if (isIncognitoMode != null) updates['isIncognitoMode'] = isIncognitoMode;
    if (subscriptionTier != null) updates['subscriptionTier'] = subscriptionTier;
    if (credits != null) updates['credits'] = credits;
    if (hasReceivedWelcomeBonus != null) updates['hasReceivedWelcomeBonus'] = hasReceivedWelcomeBonus;

    try {
      await _firestore.collection('users').doc(uid).update(updates);
      LogService.i("Profile updated for: $uid");
    } catch (e) {
      LogService.e("Profile update error", e);
      rethrow;
    }
  }

  Future<void> requestVerification(XFile selfieImage) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      // 1. Upload selfie to secure storage (using Cloudinary for now)
      // Note: Ideally this should go to a private bucket
      final imageUrl = await CloudinaryService.uploadImage(selfieImage);
      
      if (imageUrl == null) throw Exception("Selfie upload failed");

      // 2. Create verification request
      await _firestore.collection('verification_requests').add({
        'userId': user.uid,
        'email': user.email,
        'selfieUrl': imageUrl,
        'status': 'pending', // pending, approved, rejected
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      LogService.i("Verification requested for: ${user.uid}");
    } catch (e) {
      LogService.e("Verification request failed", e);
      rethrow;
    }
  }

  Future<void> updateFcmToken(String token) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;
    
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(),
      });
      LogService.i("FCM Token updated");
    } catch (e) {
      LogService.e("FCM update error", e);
    }
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    final currentUid = _currentUser?.uid;
    if (query.isEmpty || currentUid == null) return [];

    try {
      final searchKey = query.trim().toLowerCase();
      final snapshot = await _firestore
          .collection('users')
          .where('searchName', isGreaterThanOrEqualTo: searchKey)
          .where('searchName', isLessThanOrEqualTo: '$searchKey\uf8ff')
          .limit(20)
          .get();

      // Kendini filtrele
      final results = snapshot.docs
          .where((doc) => doc.id != currentUid)
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();

      LogService.i("Search found ${results.length} users for: $query");
      return results;
    } catch (e) {
      LogService.e("Search users error", e);
      return [];
    }
  }

  /// Takip Et
  Future<void> followUser(String targetUid) async {
    final currentUid = _currentUser?.uid;
    if (currentUid == null || currentUid == targetUid) return;

    try {
      final batch = _firestore.batch();
      
      // 1. Kendi following listeme ekle
      final currentUserRef = _firestore.collection('users').doc(currentUid);
      batch.update(currentUserRef, {
        'following': FieldValue.arrayUnion([targetUid])
      });
      
      // 2. Karşı tarafın followers listesine ekle
      final targetUserRef = _firestore.collection('users').doc(targetUid);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayUnion([currentUid])
      });

      await batch.commit();
      LogService.i("User $currentUid started following $targetUid");
    } catch (e) {
      LogService.e("Follow user error", e);
      rethrow;
    }
  }

  /// Takipten Çık
  Future<void> unfollowUser(String targetUid) async {
    final currentUid = _currentUser?.uid;
    if (currentUid == null || currentUid == targetUid) return;

    try {
      final batch = _firestore.batch();
      
      // 1. Kendi following listemden çıkar
      final currentUserRef = _firestore.collection('users').doc(currentUid);
      batch.update(currentUserRef, {
        'following': FieldValue.arrayRemove([targetUid])
      });
      
      // 2. Karşı tarafın followers listesinden çıkar
      final targetUserRef = _firestore.collection('users').doc(targetUid);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayRemove([currentUid])
      });

      await batch.commit();
      LogService.i("User $currentUid unfollowed $targetUid");
    } catch (e) {
      LogService.e("Unfollow user error", e);
      rethrow;
    }
  }
}
