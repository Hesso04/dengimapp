import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../utils/log_service.dart';

class FeatureFlagService {
  static final FeatureFlagService _instance = FeatureFlagService._internal();
  factory FeatureFlagService() => _instance;
  FeatureFlagService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _premiumConfig = {};

  Future<void> init() async {
    // 1. Remote Config'i başlat (Fallback olarak kalacak)
    try {
      await _remoteConfig.setDefaults({
        "free_daily_swipe_limit": 25,
        "gold_daily_swipe_limit": 999999,
        "platinum_daily_swipe_limit": 999999,
        
        "free_super_likes_per_day": 0,
        "gold_super_likes_per_day": 5,
        "platinum_super_likes_per_day": 10,
        
        "free_voice_message_enabled": false,
        "gold_voice_message_enabled": true,
        "platinum_voice_message_enabled": true,
        
        "free_video_call_enabled": false,
        "gold_video_call_enabled": false,
        "platinum_video_call_enabled": true,
        
        "free_read_receipts_enabled": false,
        "gold_read_receipts_enabled": true,
        "platinum_read_receipts_enabled": true,
        
        "show_ads": true,
        "stories_enabled": false,
      });

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig.fetchAndActivate();
      LogService.i("Remote Config initialized and activated");
    } catch (e) {
      LogService.e("Error initializing Remote Config", e);
    }

    // 2. Firestore'dan /system/premium_config belgesini yükle ve dinle
    try {
      final docSnap = await _firestore.collection('system').doc('premium_config').get();
      if (docSnap.exists && docSnap.data() != null) {
        _premiumConfig = docSnap.data()!;
        LogService.i("Loaded premium config from Firestore system/premium_config");
      }

      // Değişiklikleri anlık olarak dinle
      _firestore.collection('system').doc('premium_config').snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          _premiumConfig = snapshot.data()!;
          LogService.i("Premium config updated in real-time");
        }
      }, onError: (err) {
        LogService.w("Error listening to premium config updates: $err");
      });
    } catch (e) {
      LogService.e("Error loading premium config from Firestore on startup", e);
    }
  }

  // Getters for specific features based on user tier
  int getDailySwipeLimit(String tier) {
    final lowerTier = tier.toLowerCase();
    
    // Firestore values first
    if (_premiumConfig.isNotEmpty) {
      if (lowerTier == 'platinum') {
        return _premiumConfig['platinumDailyLikes'] ?? 999999;
      } else if (lowerTier == 'gold') {
        return _premiumConfig['goldDailyLikes'] ?? 100;
      } else {
        return _premiumConfig['freeDailyLikes'] ?? 25;
      }
    }

    // Remote Config fallback
    try {
      final val = _remoteConfig.getInt("${tier}_daily_swipe_limit");
      if (val > 0) return val;
    } catch (_) {}

    // Hardcoded Fallbacks
    if (lowerTier == 'gold' || lowerTier == 'platinum') return 999999;
    return 25;
  }

  int getSuperLikesLimit(String tier) {
    final lowerTier = tier.toLowerCase();

    // Firestore values first
    if (_premiumConfig.isNotEmpty) {
      if (lowerTier == 'platinum') {
        return _premiumConfig['platinumDailySuperLikes'] ?? 10;
      } else if (lowerTier == 'gold') {
        return _premiumConfig['goldDailySuperLikes'] ?? 5;
      } else {
        return _premiumConfig['freeDailySuperLikes'] ?? 0;
      }
    }

    // Remote Config fallback
    try {
      final val = _remoteConfig.getInt("${tier}_super_likes_per_day");
      if (val > 0) return val;
    } catch (_) {}

    // Hardcoded Fallbacks
    if (lowerTier == 'platinum') return 10;
    if (lowerTier == 'gold') return 5;
    return 0;
  }

  bool isVoiceMessageEnabled(String tier) {
    final lowerTier = tier.toLowerCase();

    // Firestore values first
    if (_premiumConfig.isNotEmpty) {
      if (lowerTier == 'platinum') {
        return _premiumConfig['platinumVoiceMessage'] ?? true;
      } else if (lowerTier == 'gold') {
        return _premiumConfig['goldVoiceMessage'] ?? true;
      } else {
        return _premiumConfig['freeVoiceMessage'] ?? false;
      }
    }

    // Remote Config fallback
    return _remoteConfig.getBool("${tier}_voice_message_enabled");
  }

  bool isVideoCallEnabled(String tier) {
    final lowerTier = tier.toLowerCase();

    // Firestore values first
    if (_premiumConfig.isNotEmpty) {
      if (lowerTier == 'platinum') {
        return _premiumConfig['platinumVideoCall'] ?? true;
      } else {
        return false;
      }
    }

    // Remote Config fallback
    return _remoteConfig.getBool("${tier}_video_call_enabled");
  }

  bool isReadReceiptsEnabled(String tier) {
    final lowerTier = tier.toLowerCase();

    // Firestore values first
    if (_premiumConfig.isNotEmpty) {
      if (lowerTier == 'platinum') {
        return _premiumConfig['platinumReadReceipts'] ?? true;
      } else if (lowerTier == 'gold') {
        return _premiumConfig['goldReadReceipts'] ?? true;
      } else {
        return false;
      }
    }

    // Remote Config fallback
    return _remoteConfig.getBool("${tier}_read_receipts_enabled");
  }

  bool shouldShowAds(String tier) {
    final lowerTier = tier.toLowerCase();

    // Firestore values first
    if (_premiumConfig.isNotEmpty) {
      if (lowerTier == 'platinum') {
        final noAds = _premiumConfig['platinumNoAds'] ?? true;
        return !noAds;
      } else if (lowerTier == 'gold') {
        final noAds = _premiumConfig['goldNoAds'] ?? true;
        return !noAds;
      } else {
        return true; // free users see ads
      }
    }

    // Remote Config fallback
    if (tier == 'platinum' || tier == 'gold') return false;
    return _remoteConfig.getBool("show_ads");
  }

  bool isStoryEnabled() {
    return _remoteConfig.getBool("stories_enabled");
  }
}
