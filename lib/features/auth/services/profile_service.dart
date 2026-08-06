import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../../../core/utils/log_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/credit_service.dart';
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
    String? referredByCode,
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

    final myReferralCode = UserProfile.generateReferralCode(user.uid);
    int initialCredits = 0;
    String? inviterUid;

    if (referredByCode != null && referredByCode.trim().isNotEmpty) {
      final cleanCode = referredByCode.trim().toUpperCase();
      try {
        final query = await _firestore
            .collection('users')
            .where('referralCode', isEqualTo: cleanCode)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          inviterUid = query.docs.first.id;
          initialCredits = 10; // Kaydolan kullanıcıya +10 Kredi hoş geldin bonusu

          // Davet eden kullanıcıya +15 Kredi yükle
          await _firestore.collection('users').doc(inviterUid).update({
            'credits': FieldValue.increment(CreditService.rewardInviteFriend),
          });
          LogService.i("Referral rewarded! Inviter $inviterUid received +15 credits");
        }
      } catch (e) {
        LogService.e("Error resolving referral code", e);
      }
    }

    final userProfile = {
      'uid': user.uid,
      'email': user.email ?? '',
      'name': name,
      'age': initialAge,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate) : null,
      'gender': gender,
      'country': country,
      'interests': interests,
      'relationshipGoal': relationshipGoal,
      'bio': bio,
      'job': job,
      'education': education,
      'photoUrls': photoUrls,
      'isPremium': false,
      'subscriptionTier': 'free',
      'credits': initialCredits,
      'referralCode': myReferralCode,
      'referredBy': inviterUid ?? '',
      'hasUsedReferralCode': inviterUid != null,
      'hasReceivedWelcomeBonus': true,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'isOnline': true,
      'blockedUsers': [], 
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

  /// Sonradan Referans Kodu Uygula (Ayarlar Ekranından)
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    final user = _currentUser;
    if (user == null) {
      return {'success': false, 'message': 'Oturum açmanız gerekmektedir.'};
    }
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return {'success': false, 'message': 'Lütfen geçerli bir referans kodu giriniz.'};
    }

    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userSnap = await userDocRef.get();

      if (!userSnap.exists) {
        return {'success': false, 'message': 'Kullanıcı profili bulunamadı.'};
      }

      final userData = userSnap.data()!;
      if (userData['hasUsedReferralCode'] == true || (userData['referredBy'] != null && userData['referredBy'].toString().isNotEmpty)) {
        return {'success': false, 'message': 'Zaten bir referans kodu kullandınız.'};
      }

      final myCode = userData['referralCode'] ?? '';
      if (myCode == cleanCode) {
        return {'success': false, 'message': 'Kendi referans kodunuzu kullanamazsınız.'};
      }

      final inviterQuery = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (inviterQuery.docs.isEmpty) {
        return {'success': false, 'message': 'Geçersiz referans kodu.'};
      }

      final inviterDoc = inviterQuery.docs.first;
      final inviterUid = inviterDoc.id;

      if (inviterUid == user.uid) {
        return {'success': false, 'message': 'Kendi referans kodunuzu kullanamazsınız.'};
      }

      // Kullanıcıya +10 Kredi ve referredBy güncelle
      await userDocRef.update({
        'credits': FieldValue.increment(10),
        'referredBy': inviterUid,
        'hasUsedReferralCode': true,
      });

      // Davet edene +15 Kredi ekle
      await _firestore.collection('users').doc(inviterUid).update({
        'credits': FieldValue.increment(CreditService.rewardInviteFriend),
      });

      LogService.i("Referral code applied manually: $cleanCode -> Inviter: $inviterUid");

      return {
        'success': true,
        'message': 'Tebrikler! Davet kodunu kullandınız, +10 Kredi hesabınıza eklendi! 🎉'
      };
    } catch (e) {
      LogService.e("Apply referral code error", e);
      return {'success': false, 'message': 'Referans kodu uygulanırken bir hata oluştu: $e'};
    }
  }

  Future<UserProfile?> getUserProfile([String? uid]) async {
    final targetUid = uid ?? _currentUser?.uid;
    if (targetUid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(targetUid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['isDeleted'] == true || data['status'] == 'deleted') {
          LogService.w("Requested profile belongs to a deleted account: $targetUid");
          return null;
        }

        // Backfill searchName atomically (yarış koşulunu önlemek için transaction).
        // Not: Asıl güncelleme backend'de onUserProfileUpdated tetikleyicisi ile yapılmalı.
        if (data['searchName'] == null && data['name'] != null) {
          final sName = data['name'].toString().trim().toLowerCase();
          try {
            await _firestore.runTransaction((txn) async {
              final fresh = await txn.get(_firestore.collection('users').doc(targetUid));
              if (!fresh.exists) return;
              if (fresh.data()?['searchName'] != null) return; // başka client yazdı
              txn.update(_firestore.collection('users').doc(targetUid), {
                'searchName': sName,
              });
            });
            data['searchName'] = sName;
          } catch (e) {
            LogService.w("searchName backfill failed (non-critical): $e");
          }
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
        final data = snapshot.data()!;
        if (data['isDeleted'] == true || data['status'] == 'deleted') return null;
        return UserProfile.fromMap(data);
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
      final uid = user.uid;
      await purgeUserFirestoreData(uid);
      await user.delete();
      LogService.i("Account deleted & hard purged: $uid");
    } catch (e) {
      LogService.e("Delete Account Error", e);
      rethrow;
    }
  }

  /// Kullanıcının tüm Firestore verilerini (mesajlar, sohbetler, kaydırmalar, beğeniler, durumlar) kalıcı olarak sil
  Future<void> purgeUserFirestoreData(String uid) async {
    try {
      // 1. Kullanıcı alt koleksiyonlarını sil
      final subcollections = ['swipes', 'stats', 'credit_transactions', 'notifications'];
      for (final sub in subcollections) {
        final subDocs = await _firestore.collection('users').doc(uid).collection(sub).get();
        for (final doc in subDocs.docs) {
          await doc.reference.delete();
        }
      }

      // 2. Ana kullanıcı dokümanını sil
      await _firestore.collection('users').doc(uid).delete();

      // 3. Katıldığı sohbet odalarını ve mesajları sil
      final chatSnap = await _firestore.collection('chats').where('participants', arrayContains: uid).get();
      for (final cDoc in chatSnap.docs) {
        final messages = await cDoc.reference.collection('messages').get();
        for (final mDoc in messages.docs) {
          await mDoc.reference.delete();
        }
        await cDoc.reference.delete();
      }

      // 4. Gönderilen ve alınan beğenileri sil
      final likesSnap1 = await _firestore.collection('likes').where('fromUserId', isEqualTo: uid).get();
      for (final doc in likesSnap1.docs) {
        await doc.reference.delete();
      }
      final likesSnap2 = await _firestore.collection('likes').where('toUserId', isEqualTo: uid).get();
      for (final doc in likesSnap2.docs) {
        await doc.reference.delete();
      }

      // 5. Eşleşmeleri sil
      final matchesSnap = await _firestore.collection('matches').where('users', arrayContains: uid).get();
      for (final doc in matchesSnap.docs) {
        await doc.reference.delete();
      }

      // 6. Silme talebini temizle
      await _firestore.collection('deletion_requests').doc(uid).delete();

      LogService.i("User Firestore data completely purged: $uid");
    } catch (e) {
      LogService.e("Failed to purge user Firestore data: $uid", e);
    }
  }

  Future<void> addCredits(int amount) async {
    await CreditService().addCredits(amount, 'system_reward');
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
    bool? isFrozen,
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
    if (isFrozen != null) updates['isFrozen'] = isFrozen;
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
}
