import 'package:flutter/foundation.dart';
import 'ad_service_mobile.dart' if (dart.library.html) 'ad_service_web.dart' as ads;

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final ads.AdService _platformService = ads.AdService();

  Future<void> init() async {
    await _platformService.init();
  }

  void showRewardedAd({required String tier, required Function(int) onReward}) {
    _platformService.showRewardedAd(tier: tier, onReward: onReward);
  }

  void showRewardedAdForMessageCredit({required String tier, required Function() onReward}) {
    _platformService.showRewardedAdForMessageCredit(tier: tier, onReward: onReward);
  }

  void showRewardedAdForSeeLikes({required String tier, required Function() onReward}) {
    _platformService.showRewardedAdForSeeLikes(tier: tier, onReward: onReward);
  }

  void showRewardedAdForSeeVisitors({required String tier, required Function() onReward}) {
    _platformService.showRewardedAdForSeeVisitors(tier: tier, onReward: onReward);
  }

  void showInterstitialAd({required String tier}) {
    _platformService.showInterstitialAd(tier: tier);
  }

  String get bannerAdUnitId => _platformService.bannerAdUnitId;
  String get seeLikesRewardedAdUnitId => _platformService.seeLikesRewardedAdUnitId;
  String get messageCreditRewardedAdUnitId => _platformService.messageCreditRewardedAdUnitId;
  String get seeVisitorsRewardedAdUnitId => _platformService.seeVisitorsRewardedAdUnitId;
}
