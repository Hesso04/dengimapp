import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/providers/discovery_provider.dart';
import '../../../core/services/credit_service.dart';
import '../../../core/widgets/promo_code_dialog.dart';
import '../services/ad_service.dart';

/// İzle & Kazan ve Kredi Yönetim Ekranı
class WatchAndEarnScreen extends StatefulWidget {
  const WatchAndEarnScreen({super.key});

  @override
  State<WatchAndEarnScreen> createState() => _WatchAndEarnScreenState();
}

class _WatchAndEarnScreenState extends State<WatchAndEarnScreen>
    with SingleTickerProviderStateMixin {
  bool _isAdLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _watchAd() {
    final creditProvider = context.read<CreditProvider>();
    if (!creditProvider.canWatchAd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GÜNLÜK REKLAM LİMİTİNE ULAŞILDINI (10/10). YARIN TEKRAR GELİN! 🎬',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAdLoading = true);
    final tier = context.read<SubscriptionProvider>().currentTier;

    AdService().showRewardedAd(
      tier: tier,
      onReward: (amount) async {
        final success = await creditProvider.rewardAdWatch();
        if (mounted) {
          setState(() => _isAdLoading = false);
          if (success) {
            _showRewardDialog(3);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ödül işlenirken bir hata oluştu.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
    );

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isAdLoading) {
        setState(() => _isAdLoading = false);
      }
    });
  }

  void _showRewardDialog(int amount) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF14161B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              Text(
                'TEBRİKLER! 🎉',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+$amount Kredi Hesabına Tanımlandı',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'HARCAMAYA BAŞLA',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSpendCredit(String action, int cost, Future<bool> Function() actionFn) async {
    final creditProvider = context.read<CreditProvider>();
    if (creditProvider.balance < cost) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yetersiz bakiye! Bu işlem için $cost Kredi gerekiyor.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await actionFn();
    if (success && mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚀 $action işlemi başarıyla gerçekleştirildi! (-$cost Kredi)'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF090A0C) : const Color(0xFFF7F8FA);
    final cardColor = isDark ? const Color(0xFF14161B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'İZLE & KAZAN (KREDİ SİSTEMİ)',
          style: GoogleFonts.outfit(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<CreditProvider>(
        builder: (context, creditProvider, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Balance Header Card
                _buildBalanceCard(creditProvider, isDark, cardColor, textColor),
                const SizedBox(height: 20),

                // 2. Daily Watch Counter Card
                _buildWatchProgressCard(creditProvider, isDark, cardColor, textColor),
                const SizedBox(height: 20),

                // 3. Watch Ad Main Action Button
                _buildWatchAdButton(creditProvider, isDark),
                const SizedBox(height: 24),

                // 4. Daily Login Streak Card
                _buildDailyStreakCard(creditProvider, isDark, cardColor, textColor),
                const SizedBox(height: 20),

                // 4.5 Promo Code Card
                _buildPromoCodeShortcutCard(isDark, cardColor, textColor),
                const SizedBox(height: 28),

                // 5. Spend Credits Section
                Text(
                  'KREDİLERİNİ KULLAN',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white70 : const Color(0xFF333333),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),

                _buildSpendOptionsList(creditProvider, isDark, cardColor, textColor),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(CreditProvider creditProvider, bool isDark, Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF262934) : const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${creditProvider.balance}',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MEVCUT KREDİ BAKİYESİ',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : const Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (creditProvider.streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${creditProvider.streak} GÜN',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWatchProgressCard(CreditProvider creditProvider, bool isDark, Color cardColor, Color textColor) {
    final watched = creditProvider.todayAdWatches;
    final maxWatches = CreditService.maxDailyAdWatches;
    final progress = (watched / maxWatches).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF262934) : const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GÜNLÜK REKLAM İZLEME HAKKI',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white70 : const Color(0xFF333333),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$watched / $maxWatches İZLENDİ',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: isDark ? const Color(0xFF262934) : const Color(0xFFE5E8EE),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Her reklam +3 Kredi kazandırır',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF555555),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Kalan Hak: ${creditProvider.remainingAdWatches}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatchAdButton(CreditProvider creditProvider, bool isDark) {
    final canWatch = creditProvider.canWatchAd;

    return ScaleTransition(
      scale: canWatch ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: canWatch && !_isAdLoading ? _watchAd : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: canWatch
                ? const LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFF6A0DAD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(colors: [Colors.grey, Colors.grey]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: canWatch
                ? [
                    BoxShadow(
                      color: const Color(0xFF8A2BE2).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isAdLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              else ...[
                const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  canWatch ? 'REKLAM İZLE (+3 KREDİ KAZAN)' : 'GÜNLÜK LİMİT DOLDU (10/10)',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyStreakCard(CreditProvider creditProvider, bool isDark, Color cardColor, Color textColor) {
    final claimed = creditProvider.dailyRewardClaimed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF262934) : const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'GÜNLÜK GİRİŞ ÖDÜLÜ',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+2 KREDİ/GÜN',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: claimed
                ? null
                : () async {
                    HapticFeedback.heavyImpact();
                    final success = await creditProvider.claimDailyReward();
                    if (success && mounted) {
                      _showRewardDialog(2);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: isDark ? const Color(0xFF262934) : const Color(0xFFE5E8EE),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              claimed ? 'BUGÜNKÜ ÖDÜL ALINDI ✔' : 'BUGÜNKÜ ÖDÜLÜ AL (+2 KREDİ)',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: claimed
                    ? (isDark ? Colors.white54 : Colors.black54)
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendOptionsList(CreditProvider creditProvider, bool isDark, Color cardColor, Color textColor) {
    final spendItems = [
      {
        'title': 'Profil Boost (30 Dk)',
        'subtitle': 'Profilini en üst sıraya taşı',
        'cost': CreditService.costBoost,
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFFFF9800),
        'action': () => creditProvider.spendBoost(),
      },
      {
        'title': 'Süper Beğeni',
        'subtitle': 'Karşı tarafa özel bildirim gönder',
        'cost': CreditService.costSuperLike,
        'icon': Icons.star_rounded,
        'color': const Color(0xFF2196F3),
        'action': () => creditProvider.spendSuperLike(),
      },
      {
        'title': 'Seni Beğenenleri Gör',
        'subtitle': 'Profilini beğenenleri anında aç',
        'cost': CreditService.costSeeWhoLikedYou,
        'icon': Icons.visibility_rounded,
        'color': const Color(0xFFE91E63),
        'action': () => creditProvider.spendSeeWhoLiked(),
      },
      {
        'title': 'Geçilen Profili Geri Al',
        'subtitle': 'Yanlışlıkla geçtiğin profili çağır',
        'cost': CreditService.costUndoSwipe,
        'icon': Icons.replay_rounded,
        'color': const Color(0xFF4CAF50),
        'action': () => creditProvider.spendUndo(),
      },
    ];

    return Column(
      children: List.generate(spendItems.length, (index) {
        final item = spendItems[index];
        final cost = item['cost'] as int;
        final color = item['color'] as Color;
        final icon = item['icon'] as IconData;
        final actionFn = item['action'] as Future<bool> Function();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? const Color(0xFF262934) : const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    Text(
                      item['subtitle'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _handleSpendCredit(
                  item['title'] as String,
                  cost,
                  actionFn,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$cost Kredi',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPromoCodeShortcutCard(bool isDark, Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF262934) : const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.confirmation_number_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROMOSYON KODU GİR',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                Text(
                  'Kampanya kodun varsa hemen yükle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => PromoCodeDialog.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'KODU GİR',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
