import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/log_service.dart';

/// Kredi Sistemi Servisi
/// Kullanıcılar kredi kazanabilir (reklam izleme, günlük giriş, başarımlar) 
/// ve harcayabilir (super like, boost, profil ziyareti göster).
class CreditService {
  static final CreditService _instance = CreditService._internal();
  factory CreditService() => _instance;
  CreditService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ══════════════════════════════════════════
  //  KREDİ FİYATLARI (Harcama)
  // ══════════════════════════════════════════
  static const int costSuperLike = 5;
  static const int costBoost = 20;
  static const int costSeeWhoLikedYou = 15;
  static const int costUndoSwipe = 3;
  static const int costProfileHighlight = 10;
  static const int costExtraSwipes10 = 8;

  // ══════════════════════════════════════════
  //  KREDİ KAZANIM MİKTARLARI
  // ══════════════════════════════════════════
  static const int rewardWatchAd = 3;           // Reklam izleme
  static const int rewardDailyLogin = 2;         // Günlük giriş
  static const int rewardProfileComplete = 10;   // Profil tamamlama (bir kez)
  static const int rewardFirstMatch = 5;         // İlk eşleşme (bir kez)
  static const int rewardInviteFriend = 15;      // Arkadaş davet etme
  static const int rewardStreakBonus = 5;         // 7 gün arka arkaya giriş bonusu

  // ══════════════════════════════════════════
  //  GÜNLÜK LİMİTLER
  // ══════════════════════════════════════════
  static const int maxDailyAdWatches = 10;       // Günde max 10 genel reklam izleyebilir
  static const int freeDefaultDailyMessageCredits = 8; // Normal kullanıcı günlük mesaj kredisi
  static const int maxDailyMessageAdWatches = 10;      // Reklamla kazanılabilecek max mesaj kredisi reklamı (10/gün)

  // ══════════════════════════════════════════
  //  MESAJLAŞMA KREDİSİ İŞLEMLERİ
  // ══════════════════════════════════════════

  /// Bugünkü kalan mesaj kredisini ve izlenen mesaj reklamı sayısını getir
  Future<Map<String, int>> getTodayMessageCreditInfo() async {
    if (_uid == null) {
      return {'remaining': freeDefaultDailyMessageCredits, 'adWatches': 0};
    }
    try {
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final doc = await _firestore
          .collection('users').doc(_uid)
          .collection('stats').doc('message_credits')
          .get();

      if (!doc.exists || doc.data()?['lastDate'] != dateKey) {
        // Yeni gün -> 8 kredi tanımla
        await _firestore
            .collection('users').doc(_uid)
            .collection('stats').doc('message_credits')
            .set({
          'lastDate': dateKey,
          'remaining': freeDefaultDailyMessageCredits,
          'adWatches': 0,
        });
        return {'remaining': freeDefaultDailyMessageCredits, 'adWatches': 0};
      }

      final data = doc.data()!;
      return {
        'remaining': data['remaining']?.toInt() ?? freeDefaultDailyMessageCredits,
        'adWatches': data['adWatches']?.toInt() ?? 0,
      };
    } catch (e) {
      LogService.e("Get message credit info error", e);
      return {'remaining': freeDefaultDailyMessageCredits, 'adWatches': 0};
    }
  }

  /// Mesaj kredisi kullan (1 adet düş)
  Future<bool> useMessageCredit() async {
    if (_uid == null) return true;
    try {
      final info = await getTodayMessageCreditInfo();
      final current = info['remaining'] ?? 0;
      if (current <= 0) return false;

      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await _firestore
          .collection('users').doc(_uid)
          .collection('stats').doc('message_credits')
          .update({
        'remaining': current - 1,
        'lastDate': dateKey,
      });
      return true;
    } catch (e) {
      LogService.e("Use message credit error", e);
      return false;
    }
  }

  /// Reklam izleyerek +1 mesaj kredisi kazan
  Future<bool> rewardForMessageCreditAd() async {
    if (_uid == null) return false;
    try {
      final info = await getTodayMessageCreditInfo();
      final adWatches = info['adWatches'] ?? 0;
      final remaining = info['remaining'] ?? 0;

      if (adWatches >= maxDailyMessageAdWatches) {
        LogService.w("Daily message credit ad limit reached: $adWatches/$maxDailyMessageAdWatches");
        return false;
      }

      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await _firestore
          .collection('users').doc(_uid)
          .collection('stats').doc('message_credits')
          .set({
        'lastDate': dateKey,
        'remaining': remaining + 1,
        'adWatches': adWatches + 1,
        'lastWatchAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      LogService.e("Reward for message credit ad error", e);
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  BAKİYE İŞLEMLERİ
  // ══════════════════════════════════════════

  /// Kullanıcının mevcut kredi bakiyesini getir
  Future<int> getBalance() async {
    if (_uid == null) return 0;
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      return doc.data()?['credits']?.toInt() ?? 0;
    } catch (e) {
      LogService.e("Credit getBalance error", e);
      return 0;
    }
  }

  /// Kredi bakiyesini stream olarak dinle (gerçek zamanlı)
  Stream<int> getBalanceStream() {
    if (_uid == null) return Stream.value(0);
    return _firestore.collection('users').doc(_uid).snapshots().map((doc) {
      return doc.data()?['credits']?.toInt() ?? 0;
    });
  }

  /// Kredi ekle (kazanım)
  Future<bool> addCredits(int amount, String reason) async {
    if (_uid == null || amount <= 0) return false;
    try {
      await _firestore.collection('users').doc(_uid).update({
        'credits': FieldValue.increment(amount),
      });

      // İşlem geçmişine kaydet
      await _logTransaction(amount, reason, 'earn');
      LogService.i("Credits added: +$amount ($reason)");
      return true;
    } catch (e) {
      LogService.e("Credit add error", e);
      return false;
    }
  }

  /// Promosyon kodu kullan (Admin panelden oluşturulan kodlar)
  Future<Map<String, dynamic>> redeemPromoCode(String code) async {
    if (_uid == null) {
      return {'success': false, 'message': 'Oturum açmanız gerekmektedir.'};
    }
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return {'success': false, 'message': 'Lütfen geçerli bir kod giriniz.'};
    }

    try {
      final query = await _firestore
          .collection('promo_codes')
          .where('code', isEqualTo: cleanCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {'success': false, 'message': 'Geçersiz veya süresi dolmuş promosyon kodu.'};
      }

      final promoDoc = query.docs.first;
      final promoData = promoDoc.data();
      final promoId = promoDoc.id;

      final int creditAmount = promoData['creditAmount']?.toInt() ?? 0;
      final int maxUses = promoData['maxUses']?.toInt() ?? 999999;
      final int usedCount = promoData['usedCount']?.toInt() ?? 0;
      final List usedByUsers = List.from(promoData['usedByUsers'] ?? []);

      if (usedByUsers.contains(_uid)) {
        return {'success': false, 'message': 'Bu promosyon kodunu daha önce kullandınız.'};
      }

      if (usedCount >= maxUses) {
        return {'success': false, 'message': 'Bu promosyon kodunun kullanım limiti dolmuştur.'};
      }

      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(_uid);
        final promoRef = _firestore.collection('promo_codes').doc(promoId);

        transaction.update(userRef, {
          'credits': FieldValue.increment(creditAmount),
        });

        transaction.update(promoRef, {
          'usedCount': FieldValue.increment(1),
          'usedByUsers': FieldValue.arrayUnion([_uid]),
        });
      });

      await _logTransaction(creditAmount, "Promosyon Kodu: $cleanCode", 'earn');
      LogService.i("Promo code redeemed: $cleanCode (+$creditAmount credits)");

      return {
        'success': true,
        'amount': creditAmount,
        'message': 'Tebrikler! +$creditAmount Kredi hesabınıza tanımlandı.'
      };
    } catch (e) {
      LogService.e("Redeem promo code error", e);
      return {'success': false, 'message': 'Kod kullanılırken bir hata oluştu: $e'};
    }
  }

  /// Kredi harca - Yetersiz bakiyede false döner (Transaction ile güvenli)
  Future<bool> spendCredits(int amount, String reason) async {
    if (_uid == null || amount <= 0) return false;
    
    final userRef = _firestore.collection('users').doc(_uid);
    
    try {
      final success = await _firestore.runTransaction<bool>((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          return false;
        }
        
        final currentBalance = userSnapshot.data()?['credits']?.toInt() ?? 0;
        if (currentBalance < amount) {
          LogService.w("Insufficient credits inside transaction: has $currentBalance, needs $amount");
          return false;
        }
        
        transaction.update(userRef, {
          'credits': currentBalance - amount,
        });
        return true;
      });

      if (success) {
        await _logTransaction(-amount, reason, 'spend');
        LogService.i("Credits spent: -$amount ($reason)");
        return true;
      }
      return false;
    } catch (e) {
      LogService.e("Credit spend transaction error", e);
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  REKLAM İZLEME (Watch & Earn)
  // ══════════════════════════════════════════

  /// Bugün kaç reklam izlenmiş
  Future<int> getTodayAdWatchCount() async {
    if (_uid == null) return 0;
    try {
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final doc = await _firestore
          .collection('users').doc(_uid)
          .collection('stats').doc('ad_watches')
          .get();

      if (!doc.exists) return 0;
      final data = doc.data()!;
      if (data['lastDate'] == dateKey) {
        return data['count']?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      LogService.e("Get ad watch count error", e);
      return 0;
    }
  }

  /// Reklam izleme sonrası kredi ver
  Future<bool> rewardForAdWatch() async {
    if (_uid == null) return false;
    try {
      // Günlük limit kontrolü
      final todayCount = await getTodayAdWatchCount();
      if (todayCount >= maxDailyAdWatches) {
        LogService.w("Daily ad watch limit reached: $todayCount/$maxDailyAdWatches");
        return false;
      }

      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Reklam izleme sayacını güncelle
      await _firestore
          .collection('users').doc(_uid)
          .collection('stats').doc('ad_watches')
          .set({
        'lastDate': dateKey,
        'count': todayCount + 1,
        'lastWatchAt': FieldValue.serverTimestamp(),
      });

      // Kredi ver
      await addCredits(rewardWatchAd, 'ad_watch');
      return true;
    } catch (e) {
      LogService.e("Reward for ad watch error", e);
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  GÜNLÜK GİRİŞ ÖDÜLÜ
  // ══════════════════════════════════════════

  /// Günlük giriş ödülünü kontrol et ve ver
  Future<bool> claimDailyLoginReward() async {
    if (_uid == null) return false;
    try {
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final statsRef = _firestore
          .collection('users').doc(_uid)
          .collection('stats').doc('daily_login');

      final doc = await statsRef.get();
      
      if (doc.exists && doc.data()?['lastClaimDate'] == dateKey) {
        return false; // Zaten bugün alınmış
      }

      // Streak hesapla
      int currentStreak = 1;
      if (doc.exists) {
        final lastDate = doc.data()?['lastClaimDate'] as String?;
        if (lastDate != null) {
          final lastDateTime = DateTime.tryParse(lastDate);
          if (lastDateTime != null) {
            final diff = now.difference(lastDateTime).inDays;
            if (diff == 1) {
              currentStreak = (doc.data()?['streak']?.toInt() ?? 0) + 1;
            }
          }
        }
      }

      int reward = rewardDailyLogin;
      // 7 gün streak bonusu
      if (currentStreak > 0 && currentStreak % 7 == 0) {
        reward += rewardStreakBonus;
      }

      await statsRef.set({
        'lastClaimDate': dateKey,
        'streak': currentStreak,
        'totalLogins': FieldValue.increment(1),
      });

      await addCredits(reward, currentStreak % 7 == 0 ? 'daily_login_streak' : 'daily_login');
      return true;
    } catch (e) {
      LogService.e("Daily login reward error", e);
      return false;
    }
  }

  /// Mevcut streak bilgisini getir
  Future<Map<String, dynamic>> getStreakInfo() async {
    if (_uid == null) return {'streak': 0, 'claimed': false};
    try {
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final doc = await _firestore
          .collection('users').doc(_uid)
          .collection('stats').doc('daily_login')
          .get();

      if (!doc.exists) return {'streak': 0, 'claimed': false};
      
      final data = doc.data()!;
      return {
        'streak': data['streak']?.toInt() ?? 0,
        'claimed': data['lastClaimDate'] == dateKey,
        'totalLogins': data['totalLogins']?.toInt() ?? 0,
      };
    } catch (e) {
      LogService.e("Get streak info error", e);
      return {'streak': 0, 'claimed': false};
    }
  }

  // ══════════════════════════════════════════
  //  İŞLEM GEÇMİŞİ
  // ══════════════════════════════════════════

  Future<void> _logTransaction(int amount, String reason, String type) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users').doc(_uid)
          .collection('credit_transactions')
          .add({
        'amount': amount,
        'reason': reason,
        'type': type, // 'earn' or 'spend'
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      LogService.e("Log transaction error", e);
    }
  }

  /// İşlem geçmişini getir
  Future<List<Map<String, dynamic>>> getTransactionHistory({int limit = 30}) async {
    if (_uid == null) return [];
    try {
      final snap = await _firestore
          .collection('users').doc(_uid)
          .collection('credit_transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
    } catch (e) {
      LogService.e("Get transaction history error", e);
      return [];
    }
  }
}
