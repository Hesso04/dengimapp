import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  user,
  moderator,
  admin,
}

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final DateTime? birthDate; // ← YENİ: Doğum tarihi
  final String gender;
  final String country;
  final List<String> interests;
  final String? bio;
  final String? job;
  final String? education;
  final String? relationshipGoal; // New field
  final List<String>? photoUrls;
  final String? videoUrl; // ← YENİ: Video profil URL
  final String? profileVoiceUrl; // YENİ: Sesli profil URL
  
  // Özellikler
  final bool isPremium;
  final String subscriptionTier; // free, gold, platinum
  final int credits;
  final bool isVerified;
  final bool isOnline;
  final String role; // as String for easier mapping
  final String referralCode;
  final String? referredBy;
  final List<String> achievements;
  
  // Konum
  final double distance;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? district;
  final List<String> blockedUsers;
  final String? fcmToken;
  final DateTime? boostUntil;
  final bool isGhostMode;
  final bool isIncognitoMode;
  final bool hasReceivedWelcomeBonus;
  final List<String> followers; // YENİ: Takipçiler
  final List<String> following; // YENİ: Takip ettikleri
  final String searchName;

  // Zamanlar
  final DateTime createdAt;
  final DateTime lastActive;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.birthDate,
    required this.gender,
    required this.country,
    required this.interests,
    this.bio,
    this.job,
    this.education,
    this.relationshipGoal,
    this.photoUrls,
    this.videoUrl, // ← YENİ
    this.profileVoiceUrl, // YENİ
    this.isPremium = false,
    this.subscriptionTier = 'free',
    this.credits = 0,
    this.isVerified = false,
    this.isOnline = false,
    this.role = 'user',
    this.referralCode = '',
    this.referredBy,
    this.achievements = const [],
    this.distance = 0,
    this.latitude,
    this.longitude,
    this.city,
    this.district,
    required this.createdAt,
    required this.lastActive,
    required this.blockedUsers,
    this.fcmToken,
    this.boostUntil,
    this.isGhostMode = false,
    this.isIncognitoMode = false,
    this.hasReceivedWelcomeBonus = false,
    this.followers = const [],
    this.following = const [],
    this.searchName = '',
  });

  // Calculated age from birthDate
  int get age {
    if (birthDate == null) return 25; // Default fallback
    final now = DateTime.now();
    int calculatedAge = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  String get zodiacSign {
    if (birthDate == null) return '';
    int day = birthDate!.day;
    int month = birthDate!.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return '♈ Koç';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return '♉ Boğa';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return '♊ İkizler';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return '♋ Yengeç';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return '♌ Aslan';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return '♍ Başak';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return '♎ Terazi';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return '♏ Akrep';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return '♐ Yay';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return '♑ Oğlak';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return '♒ Kova';
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return '♓ Balık';
    return '';
  }

  bool get isBoosted {
    if (boostUntil == null) return false;
    return boostUntil!.isAfter(DateTime.now());
  }

  // Profil tam mı? (İsim ve en az 1 fotoğraf var mı?)
  bool get isComplete {
    return name.isNotEmpty && name != 'Kullanıcı' && 
           photoUrls != null && photoUrls!.isNotEmpty;
  }

  // UI Yardımcıları
  String get imageUrl => (photoUrls != null && photoUrls!.isNotEmpty) 
      ? photoUrls!.first 
      : 'https://images.unsplash.com/photo-1511367461989-f85a21fda167?w=500&auto=format&fit=crop&q=60'; // Placeholder
  
  String get location => country;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
      'country': country,
      'interests': interests,
      'bio': bio,
      'job': job,
      'education': education,
      'relationshipGoal': relationshipGoal,
      'photoUrls': photoUrls,
      'videoUrl': videoUrl,
      'profileVoiceUrl': profileVoiceUrl,
      'isPremium': isPremium,
      'subscriptionTier': subscriptionTier,
      'credits': credits,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'role': role,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'achievements': achievements,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'district': district,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'blockedUsers': blockedUsers,
      'fcmToken': fcmToken,
      'boostUntil': boostUntil != null ? Timestamp.fromDate(boostUntil!) : null,
      'isGhostMode': isGhostMode,
      'isIncognitoMode': isIncognitoMode,
      'hasReceivedWelcomeBonus': hasReceivedWelcomeBonus,
      'followers': followers,
      'following': following,
      'searchName': searchName,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // If birthDate is missing but age is present (legacy or mismatch), 
    // we can guestimate a birth year, but it's better to just use null and fallback.
    DateTime? bDay;
    if (map['birthDate'] != null) {
      if (map['birthDate'] is Timestamp) {
        bDay = (map['birthDate'] as Timestamp).toDate();
      } else if (map['birthDate'] is String) {
        bDay = DateTime.tryParse(map['birthDate']);
      }
    }

    // Handle name default
    String nameVal = map['name'] ?? '';
    if (nameVal.isEmpty && map['email'] != null) {
      nameVal = map['email'].split('@')[0];
    }

    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: nameVal.isEmpty ? 'Kullanıcı' : nameVal,
      birthDate: bDay,
      gender: map['gender'] ?? 'Belirtilmedi',
      country: map['country'] ?? 'Dünya',
      interests: List<String>.from(map['interests'] ?? []),
      bio: map['bio'],
      job: map['job'],
      education: map['education'],
      relationshipGoal: map['relationshipGoal'],
      photoUrls: map['photoUrls'] != null ? List<String>.from(map['photoUrls']) : null,
      videoUrl: map['videoUrl'],
      profileVoiceUrl: map['profileVoiceUrl'],
      isPremium: map['isPremium'] ?? false,
      subscriptionTier: map['subscriptionTier'] ?? 'free',
      credits: map['credits']?.toInt() ?? 0,
      isVerified: map['isVerified'] ?? false,
      isOnline: map['isOnline'] ?? false,
      role: map['role'] ?? 'user',
      referralCode: map['referralCode'] ?? '',
      referredBy: map['referredBy'],
      achievements: List<String>.from(map['achievements'] ?? []),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      city: map['city'],
      district: map['district'],
      distance: 0.0,
      createdAt: (map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now()),
      lastActive: (map['lastActive'] is Timestamp 
          ? (map['lastActive'] as Timestamp).toDate() 
          : DateTime.now()),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      fcmToken: map['fcmToken'],
      boostUntil: map['boostUntil'] is Timestamp 
          ? (map['boostUntil'] as Timestamp).toDate() 
          : null,
      isGhostMode: map['isGhostMode'] ?? false,
      isIncognitoMode: map['isIncognitoMode'] ?? false,
      hasReceivedWelcomeBonus: map['hasReceivedWelcomeBonus'] ?? false,
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      searchName: map['searchName'] ?? (nameVal).trim().toLowerCase(),
    );
  }
}
