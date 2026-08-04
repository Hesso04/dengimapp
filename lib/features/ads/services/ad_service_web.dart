// Stub file for web - AdService
// google_mobile_ads is not supported on web (Web test simulation)

import '../../../core/utils/log_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  Future<void> init() async {
    LogService.i("AdService: Web platform - ads disabled.");
  }

  void showRewardedAd({required String tier, required Function(int) onReward}) {
    LogService.w("Ads simulated on web.");
    onReward(1);
  }

  void showRewardedAdForMessageCredit({required String tier, required Function() onReward}) {
    LogService.w("Message credit ad simulated on web.");
    onReward();
  }

  void showRewardedAdForSeeLikes({required String tier, required Function() onReward}) {
    LogService.w("See likes ad simulated on web.");
    onReward();
  }

  void showRewardedAdForSeeVisitors({required String tier, required Function() onReward}) {
    LogService.w("See visitors ad simulated on web.");
    onReward();
  }

  void showInterstitialAd({required String tier}) {
    LogService.w("Ads simulated on web.");
  }

  String get bannerAdUnitId => "ca-app-pub-6698554585648483/9090704729";
  String get seeLikesRewardedAdUnitId => "ca-app-pub-6698554585648483/8136715701";
  String get messageCreditRewardedAdUnitId => "ca-app-pub-6698554585648483/8899133037";
  String get seeVisitorsRewardedAdUnitId => "ca-app-pub-6698554585648483/4090373496";
}
