import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/services/feature_flag_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  RewardedAd? _seeLikesAd;
  RewardedAd? _messageCreditAd;
  RewardedAd? _seeVisitorsAd;
  InterstitialAd? _interstitialAd;

  final int maxFailedLoadAttempts = 3;

  // Production AdMob Unit IDs
  static const String _prodBannerId = 'ca-app-pub-6698554585648483/9090704729';
  static const String _prodSeeLikesId = 'ca-app-pub-6698554585648483/8136715701';
  static const String _prodMessageCreditId = 'ca-app-pub-6698554585648483/8899133037';
  static const String _prodSeeVisitorsId = 'ca-app-pub-6698554585648483/4090373496';

  // Test Ad Unit IDs (Fallback)
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  String get bannerAdUnitId {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _prodBannerId : _testBannerId;
  }
  
  String get seeLikesRewardedAdUnitId {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _prodSeeLikesId : _testRewardedId;
  }

  String get messageCreditRewardedAdUnitId {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _prodMessageCreditId : _testRewardedId;
  }

  String get seeVisitorsRewardedAdUnitId {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _prodSeeVisitorsId : _testRewardedId;
  }

  Future<void> init() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  // --- GENERAL REWARDED AD ---

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: messageCreditRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => _rewardedAd = null,
      ),
    );
  }

  void showRewardedAd({required String tier, required Function(int) onReward}) {
    if (!FeatureFlagService().shouldShowAds(tier)) return;

    if (_rewardedAd == null) {
      _loadRewardedAd();
      onReward(1);
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
        onReward(1);
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onReward(reward.amount.toInt() > 0 ? reward.amount.toInt() : 1));
    _rewardedAd = null;
  }

  // --- MESAJ KREDİSİ REWARDED AD ---

  void showRewardedAdForMessageCredit({required String tier, required Function() onReward}) {
    if (!FeatureFlagService().shouldShowAds(tier)) {
      onReward();
      return;
    }

    RewardedAd.load(
      adUnitId: messageCreditRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _messageCreditAd = ad;
          _messageCreditAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onReward();
            },
          );
          _messageCreditAd!.show(onUserEarnedReward: (ad, reward) => onReward());
        },
        onAdFailedToLoad: (error) {
          onReward(); // Fallback reward if ad fails to load in test/dev
        },
      ),
    );
  }

  // --- BEĞENİLERİ GÖR REWARDED AD ---

  void showRewardedAdForSeeLikes({required String tier, required Function() onReward}) {
    if (!FeatureFlagService().shouldShowAds(tier)) {
      onReward();
      return;
    }

    RewardedAd.load(
      adUnitId: seeLikesRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _seeLikesAd = ad;
          _seeLikesAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onReward();
            },
          );
          _seeLikesAd!.show(onUserEarnedReward: (ad, reward) => onReward());
        },
        onAdFailedToLoad: (error) {
          onReward();
        },
      ),
    );
  }

  // --- ZİYARETÇİYİ GÖR REWARDED AD ---

  void showRewardedAdForSeeVisitors({required String tier, required Function() onReward}) {
    if (!FeatureFlagService().shouldShowAds(tier)) {
      onReward();
      return;
    }

    RewardedAd.load(
      adUnitId: seeVisitorsRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _seeVisitorsAd = ad;
          _seeVisitorsAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onReward();
            },
          );
          _seeVisitorsAd!.show(onUserEarnedReward: (ad, reward) => onReward());
        },
        onAdFailedToLoad: (error) {
          onReward();
        },
      ),
    );
  }

  // --- INTERSTITIAL ADS ---

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _testInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  void showInterstitialAd({required String tier}) {
    if (!FeatureFlagService().shouldShowAds(tier)) return;
    if (_interstitialAd == null) {
      _loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
