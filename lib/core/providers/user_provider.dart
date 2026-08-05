import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/auth/models/user_profile.dart';
import '../../features/auth/services/profile_service.dart';
import '../utils/log_service.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = false;
  StreamSubscription<UserProfile?>? _profileSubscription;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  final ProfileService _profileService = ProfileService();

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Önce tek seferlik çek
      _currentUser = await _profileService.getUserProfile();
      
      // Sonra stream'i başlat
      _profileSubscription?.cancel();
      _profileSubscription = _profileService.getProfileStream().listen((profile) async {
        if (profile != null) {
          // MASTER ADMIN AUTO-PREMIUM PATCH
          final masterEmails = ['omerbedirhano@gmail.com', 'admin@dengim.com'];
          if (masterEmails.contains(profile.email.toLowerCase()) && (!profile.isPremium || profile.subscriptionTier != 'platinum')) {
            LogService.i("Master account detected: ${profile.email}. Upgrading to Platinum Premium...");
            try {
              await _profileService.updateProfile(
                isPremium: true, 
                isVerified: true,
                subscriptionTier: 'platinum'
              );
            } catch (e) {
              LogService.e("Failed to auto-upgrade master account", e);
            }
          }

          // WELCOME BONUS PATCH FOR ALL USERS
          if (!profile.hasReceivedWelcomeBonus) {
            LogService.i("Granting welcome bonus to ${profile.email}...");
            try {
              await _profileService.updateProfile(
                isPremium: true,
                subscriptionTier: 'gold',
                credits: profile.credits + 1000,
                hasReceivedWelcomeBonus: true,
              );
            } catch (e) {
               LogService.e("Failed to grant welcome bonus", e);
            }
          }

          _currentUser = profile;
          notifyListeners();
        }
      });

      LogService.i("User profile monitoring started: ${_currentUser?.name}");
    } catch (e) {
      LogService.e("Error loading user profile", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  void updateProfile(UserProfile profile) {
    _currentUser = profile;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
