import 'dart:async';
import 'package:flutter/material.dart';
import '../services/credit_service.dart';
import '../utils/log_service.dart';

/// Kredi bakiyesini ve streak bilgisini yöneten Provider
class CreditProvider extends ChangeNotifier {
  final CreditService _creditService = CreditService();

  int _balance = 0;
  int _streak = 0;
  bool _dailyRewardClaimed = false;
  int _todayAdWatches = 0;
  int _messageCreditsRemaining = CreditService.freeDefaultDailyMessageCredits;
  int _messageAdWatchesToday = 0;
  bool _isLoading = false;

  StreamSubscription? _balanceSubscription;

  // Getters
  int get balance => _balance;
  int get streak => _streak;
  bool get dailyRewardClaimed => _dailyRewardClaimed;
  int get todayAdWatches => _todayAdWatches;
  int get remainingAdWatches => CreditService.maxDailyAdWatches - _todayAdWatches;
  bool get canWatchAd => _todayAdWatches < CreditService.maxDailyAdWatches;

  // Message Credits Getters
  int get messageCreditsRemaining => _messageCreditsRemaining;
  int get messageAdWatchesToday => _messageAdWatchesToday;
  int get remainingMessageAdWatches => CreditService.maxDailyMessageAdWatches - _messageAdWatchesToday;
  bool get canWatchAdForMessageCredit => _messageAdWatchesToday < CreditService.maxDailyMessageAdWatches;
  bool get isLoading => _isLoading;

  /// Provider'ı başlat
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Bakiye stream'ini dinle
      _balanceSubscription?.cancel();
      _balanceSubscription = _creditService.getBalanceStream().listen((balance) {
        _balance = balance;
        notifyListeners();
      });

      // Streak bilgisini çek
      final streakInfo = await _creditService.getStreakInfo();
      _streak = streakInfo['streak'] ?? 0;
      _dailyRewardClaimed = streakInfo['claimed'] ?? false;

      // Bugünkü reklam izleme sayısını çek
      _todayAdWatches = await _creditService.getTodayAdWatchCount();

      // Bugünkü mesaj kredisi bilgisini çek
      final msgInfo = await _creditService.getTodayMessageCreditInfo();
      _messageCreditsRemaining = msgInfo['remaining'] ?? CreditService.freeDefaultDailyMessageCredits;
      _messageAdWatchesToday = msgInfo['adWatches'] ?? 0;

      LogService.i("CreditProvider initialized - Balance: $_balance, MessageCredits: $_messageCreditsRemaining");
    } catch (e) {
      LogService.e("CreditProvider init error", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 1 Mesaj Kredisi Harca
  Future<bool> useMessageCredit() async {
    if (_messageCreditsRemaining <= 0) return false;
    final success = await _creditService.useMessageCredit();
    if (success) {
      _messageCreditsRemaining--;
      notifyListeners();
    }
    return success;
  }

  /// Mesaj Reklamı İzleyerek +1 Mesaj Kredisi Kazan
  Future<bool> rewardForMessageCreditAd() async {
    if (!canWatchAdForMessageCredit) return false;
    final success = await _creditService.rewardForMessageCreditAd();
    if (success) {
      _messageCreditsRemaining++;
      _messageAdWatchesToday++;
      notifyListeners();
    }
    return success;
  }

  /// Günlük giriş ödülünü al
  Future<bool> claimDailyReward() async {
    if (_dailyRewardClaimed) return false;

    final success = await _creditService.claimDailyLoginReward();
    if (success) {
      _dailyRewardClaimed = true;
      final streakInfo = await _creditService.getStreakInfo();
      _streak = streakInfo['streak'] ?? 0;
      notifyListeners();
    }
    return success;
  }

  /// Reklam izleme sonrası ödül al
  Future<bool> rewardAdWatch() async {
    if (!canWatchAd) return false;

    final success = await _creditService.rewardForAdWatch();
    if (success) {
      _todayAdWatches++;
      notifyListeners();
    }
    return success;
  }

  /// Kredi harca (genel amaçlı)
  Future<bool> spend(int amount, String reason) async {
    if (_balance < amount) return false;
    final success = await _creditService.spendCredits(amount, reason);
    if (success) {
      // Optimistic local update - stream will sync the real value
      _balance -= amount;
      notifyListeners();
    }
    return success;
  }

  /// Kredi harca (FeatureActionModal uyumluluğu için alias)
  Future<bool> spendCredits(int amount, String reason) => spend(amount, reason);

  /// Super Like harca
  Future<bool> spendSuperLike() => spend(CreditService.costSuperLike, 'super_like');

  /// Boost harca
  Future<bool> spendBoost() => spend(CreditService.costBoost, 'boost');

  /// Beğenenleri gör harca
  Future<bool> spendSeeWhoLiked() => spend(CreditService.costSeeWhoLikedYou, 'see_who_liked');

  /// Geri al harca
  Future<bool> spendUndo() => spend(CreditService.costUndoSwipe, 'undo_swipe');

  /// Promosyon kodu kullan
  Future<Map<String, dynamic>> redeemPromoCode(String code) async {
    final result = await _creditService.redeemPromoCode(code);
    if (result['success'] == true) {
      notifyListeners();
    }
    return result;
  }

  @override
  void dispose() {
    _balanceSubscription?.cancel();
    super.dispose();
  }
}
