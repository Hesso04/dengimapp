import 'package:flutter/material.dart';
import '../../features/auth/models/user_profile.dart';
import '../../features/auth/services/discovery_service.dart';
import '../../features/auth/services/profile_service.dart';
import '../utils/log_service.dart';
import '../../core/services/analytics_service.dart';
import '../../features/ads/services/ad_service.dart';
import '../../core/services/feature_flag_service.dart';


class SwipeResult {
  final bool success;
  final bool isMatch;

  const SwipeResult({required this.success, required this.isMatch});
}

class DiscoveryProvider extends ChangeNotifier {
  List<UserProfile> _users = [];
  List<UserProfile> _activeUsers = [];
  bool _isLoading = false;
  final DiscoveryService _discoveryService = DiscoveryService();
  final ProfileService _profileService = ProfileService();
  
  int _swipeCount = 0;

  List<UserProfile> get users => _users;
  List<UserProfile> get activeUsers => _activeUsers;
  bool get isLoading => _isLoading;

  /// Minimum kullanıcı sayısı (bu sayının altındaysa demo profiller eklenir)


  Future<void> loadDiscoveryUsers({
    String? gender,
    int? minAge,
    int? maxAge,
    List<String>? interests,
    int? maxDistance,
    bool verifiedOnly = false,
    bool hasPhotoOnly = true,
    bool onlineOnly = false,
    String? relationshipGoal,
    bool forceRefresh = false,
  }) async {
    if (_isLoading && !forceRefresh) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final loadedUsers = await _discoveryService.getUsersToMatch(
        gender: gender,
        minAge: minAge,
        maxAge: maxAge,
        interests: interests,
        maxDistance: maxDistance,
        verifiedOnly: verifiedOnly,
        hasPhotoOnly: hasPhotoOnly,
        onlineOnly: onlineOnly,
        relationshipGoal: relationshipGoal,
      );
      
      _users = loadedUsers;
      _activeUsers = loadedUsers.where((u) => u.isOnline).toList();
    } catch (e) {
      LogService.e("Error loading discovery users", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  void removeUserAt(int index) {
    if (index >= 0 && index < _users.length) {
      _users.removeAt(index);
      notifyListeners();
    }
  }

  Future<SwipeResult> swipeUser(String targetUserId, String swipeType, {required String userTier}) async {    
    try {
      // 1. Check Daily Limit
      if (userTier != 'platinum') {
        if (swipeType == 'super_like') {
          final currentSuperCount = await _discoveryService.getDailySuperLikeCount();
          final superLimit = FeatureFlagService().getSuperLikesLimit(userTier);
          if (currentSuperCount >= superLimit) {
            LogService.w("Daily super like limit reached for tier: $userTier");
            return const SwipeResult(success: false, isMatch: false);
          }
        } else {
          final currentCount = await _discoveryService.getDailySwipeCount();
          final limit = FeatureFlagService().getDailySwipeLimit(userTier);
          
          if (currentCount >= limit) {
            LogService.w("Daily swipe limit reached for tier: $userTier");
            return const SwipeResult(success: false, isMatch: false); 
          }
        }
      }

      final isMatch = await _discoveryService.swipeUser(targetUserId, swipeType: swipeType);
      
      AnalyticsService().logSwipe(swipeType, targetUserId);
      
      // Increment counts (the swipe succeeded)
      if (swipeType == 'super_like') {
        await _discoveryService.incrementSuperLikeCount();
      } else {
        await _discoveryService.incrementSwipeCount();
      }

      // --- AD LOGIC ---
      _swipeCount++;
      if (_swipeCount >= 10) {
        _swipeCount = 0;
        final profile = await _profileService.getUserProfile();
        if (profile != null && FeatureFlagService().shouldShowAds(profile.subscriptionTier)) {
          AdService().showInterstitialAd(tier: profile.subscriptionTier);
        }
      }

      return SwipeResult(success: true, isMatch: isMatch);
    } catch (e) {
      LogService.e("Error swiping user", e);
      return const SwipeResult(success: false, isMatch: false);
    }
  }

  Future<void> activateBoost() async {
    try {
      await _discoveryService.activateBoost();
      AnalyticsService().logEvent(name: 'boost_activated', parameters: {});
    } catch (e) {
      LogService.e("Error activating boost", e);
    }
  }
}


