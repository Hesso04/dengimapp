import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/log_service.dart';
import '../../features/auth/services/profile_service.dart';

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

  /// Mesaj kredisi kullan (1 adet düş) - Transaction ile atomik
  Future<bool> useMessageCredit() async {
    if (_uid == null) return true;
    try {
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final docRef = _firestore
          .collection('users').doc(_uid)
          .collection('stats').doc('message_credits');

      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(docRef);

        int remaining = freeDefaultDailyMessageCredits;
        int adWatches = 0;

        if (doc.exists && doc.data()?['lastDate'] == dateKey) {
          remaining = doc.data()?['remaining']?.toInt() ?? 0;
          adWatches = doc.data()?['adWatches']?.toInt() ?? 0;
        }

        if (remaining <= 0) return false;

        transaction.set(docRef, {
          'lastDate': dateKey,
          'remaining': remaining - 1,
          'adWatches': adWatches,
        });
        return true;
      });
    } catch (e) {
      LogService.e("Use message credit error", e);
      return false;
    }
  }

  /// Reklam izleyerek +1 mesaj kredisi kazan - Transaction ile atomik
  Future<bool> rewardForMessageCreditAd() async {
    if (_uid == null) return false;
    try {
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final docRef = _firestore
          .collection('users').doc(_uid)
          .collection('stats').doc('message_credits');

      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(docRef);

        int remaining = freeDefaultDailyMessageCredits;
        int adWatches = 0;

        if (doc.exists && doc.data()?['lastDate'] == dateKey) {
          remaining = doc.data()?['remaining']?.toInt() ?? 0;
          adWatches = doc.data()?['adWatches']?.toInt() ?? 0;
        }

        if (adWatches >= maxDailyMessageAdWatches) {
          LogService.w("Daily message credit ad limit reached: $adWatches/$maxDailyMessageAdWatches");
          return false;
        }

        transaction.set(docRef, {
          'lastDate': dateKey,
          'remaining': remaining + 1,
          'adWatches': adWatches + 1,
        });
        return true;
      });
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

  /// Promosyon kodu kullan (Admin panelden oluşturulan kodlar veya Referans Kodları)
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
        // Promosyon kodu bulunamadıysa, referans kodu olarak dene!
        try {
          final refResult = await ProfileService().applyReferralCode(cleanCode);
          if (refResult['success'] == true) {
            return refResult;
          }
          // Eğer hata "Geçersiz referans kodu." değilse (yani kod geçerli ama iş mantığı hatası varsa),
          // bu spesifik hatayı kullanıcıya göster.
          if (refResult['message'] != 'Geçersiz referans kodu.') {
            return refResult;
          }
        } catch (_) {}
        return {'success': false, 'message': 'Geçersiz veya süresi dolmuş promosyon/referans kodu.'};
      }

      final promoDoc = query.docs.first;
      final promoData = promoDoc.data();
      final promoId = promoDoc.id;

      final int creditAmount = promoData['creditAmount']?.toInt() ?? 0;
      final int maxUses = promoData['maxUses']?.toInt() ?? 999999;

      final userRef = _firestore.collection('users').doc(_uid);
      final promoRef = _firestore.collection('promo_codes').doc(promoId);

      // Firestore transaction: ÖNCE OKUMA, SONRA YAZMA
      await _firestore.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        final promoSnap = await transaction.get(promoRef);

        if (!userSnap.exists) {
          throw Exception("Kullanıcı profili bulunamadı.");
        }
        if (!promoSnap.exists) {
          throw Exception("Promosyon kuralı bulunamadı.");
        }

        final pData = promoSnap.data()!;
        final int currentUsedCount = pData['usedCount']?.toInt() ?? 0;
        final List usedByUsers = List.from(pData['usedByUsers'] ?? pData['usedBy'] ?? []);

        if (usedByUsers.contains(_uid)) {
          throw Exception("Bu promosyon kodunu daha önce kullandınız.");
        }

        if (currentUsedCount >= maxUses) {
          throw Exception("Bu promosyon kodunun kullanım limiti dolmuştur.");
        }

        final int currentCredits = userSnap.data()?['credits']?.toInt() ?? 0;

        transaction.update(userRef, {
          'credits': currentCredits + creditAmount,
        });

        usedByUsers.add(_uid);
        transaction.update(promoRef, {
          'usedCount': currentUsedCount + 1,
          'usedByUsers': usedByUsers,
          'usedBy': usedByUsers,
        });
      });

      await _logTransaction(creditAmount, "Promosyon Kodu: $cleanCode", 'earn');
      LogService.i("Promo code redeemed: $cleanCode (+$creditAmount credits)");

      return {
        'success': true,
        'amount': creditAmount,
        'message': 'Tebrikler! +$creditAmount Kredi hesabınıza tanımlandı. 🎉'
      };
    } catch (e) {
      LogService.e("Redeem promo code error", e);
      final msg = e.toString().replaceAll("Exception: ", "");
      return {'success': false, 'message': msg.contains("FirebaseException") ? 'Kod işlenirken veritabanı hatası oluştu.' : msg};
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

  /// Reklam izleme sonrası kredi ver - Transaction ile atomik
  Future<bool> rewardForAdWatch() async {
    if (_uid == null) return false;
    try {
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final adDocRef = _firestore
          .collection('users').doc(_uid)
          .collection('stats').doc('ad_watches');
      final userRef = _firestore.collection('users').doc(_uid);

      final success = await _firestore.runTransaction<bool>((transaction) async {
        // READ PHASE - tüm okumalar önce
        final adDoc = await transaction.get(adDocRef);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) return false;

        int todayCount = 0;
        if (adDoc.exists && adDoc.data()?['lastDate'] == dateKey) {
          todayCount = adDoc.data()?['count']?.toInt() ?? 0;
        }

        if (todayCount >= maxDailyAdWatches) {
          LogService.w("Daily ad watch limit reached: $todayCount/$maxDailyAdWatches");
          return false;
        }

        // WRITE PHASE
        transaction.set(adDocRef, {
          'lastDate': dateKey,
          'count': todayCount + 1,
        });

        final currentCredits = userDoc.data()?['credits']?.toInt() ?? 0;
        transaction.update(userRef, {
          'credits': currentCredits + rewardWatchAd,
        });

        return true;
      });

      if (success) {
        await _logTransaction(rewardWatchAd, 'ad_watch', 'earn');
        LogService.i("Credits added: +$rewardWatchAd (ad_watch)");
      }
      return success;
    } catch (e) {
      LogService.e("Reward for ad watch error", e);
      return false;
    }
  }

  // ══════════════════════════════════════════
  //  GÜNLÜK GİRİŞ ÖDÜLÜ
  // ══════════════════════════════════════════

  /// Günlük giriş ödülünü kontrol et ve ver - Transaction ile atomik
  Future<bool> claimDailyLoginReward() async {
    if (_uid == null) return false;
    try {
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final statsRef = _firestore
          .collection('users').doc(_uid)
          .collection('stats').doc('daily_login');
      final userRef = _firestore.collection('users').doc(_uid);

      int finalReward = 0;
      String rewardReason = 'daily_login';

      final success = await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(statsRef);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) return false;

        if (doc.exists && doc.data()?['lastClaimDate'] == dateKey) {
          return false; // Zaten bugün alınmış
        }

        int currentStreak = 1;
        int totalLogins = 0;
        if (doc.exists) {
          totalLogins = doc.data()?['totalLogins']?.toInt() ?? 0;
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

        finalReward = rewardDailyLogin;
        if (currentStreak > 0 && currentStreak % 7 == 0) {
          finalReward += rewardStreakBonus;
          rewardReason = 'daily_login_streak';
        }

        transaction.set(statsRef, {
          'lastClaimDate': dateKey,
          'streak': currentStreak,
          'totalLogins': totalLogins + 1,
        });

        final currentCredits = userDoc.data()?['credits']?.toInt() ?? 0;
        transaction.update(userRef, {
          'credits': currentCredits + finalReward,
        });

        return true;
      });

      if (success) {
        await _logTransaction(finalReward, rewardReason, 'earn');
        LogService.i("Daily login reward claimed: +$finalReward credits");
      }
      return success;
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
