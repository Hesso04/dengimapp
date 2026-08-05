import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/credit_service.dart';
import '../../payment/premium_offer_screen.dart';
import '../../ads/services/ad_service.dart';

enum DiscoverFeatureType {
  superLike,
  rewind,
  boost,
}

class FeatureActionModal extends StatefulWidget {
  final DiscoverFeatureType featureType;
  final VoidCallback onActivated;

  const FeatureActionModal({
    super.key,
    required this.featureType,
    required this.onActivated,
  });

  static Future<void> show({
    required BuildContext context,
    required DiscoverFeatureType featureType,
    required VoidCallback onActivated,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => FeatureActionModal(
        featureType: featureType,
        onActivated: onActivated,
      ),
    );
  }

  @override
  State<FeatureActionModal> createState() => _FeatureActionModalState();
}

class _FeatureActionModalState extends State<FeatureActionModal> {
  bool _isAdLoading = false;

  String get _featureTitle {
    switch (widget.featureType) {
      case DiscoverFeatureType.superLike:
        return 'SÜPER BEĞENİ';
      case DiscoverFeatureType.rewind:
        return 'GERİ AL (REWIND)';
      case DiscoverFeatureType.boost:
        return 'PROFİL BOOST';
    }
  }

  String get _featureDescription {
    switch (widget.featureType) {
      case DiscoverFeatureType.superLike:
        return 'Profilinizi doğrudan öncelikli olarak gösterir ve eşleşme şansınızı 3 katına çıkarır!';
      case DiscoverFeatureType.rewind:
        return 'Son kaydırdığınız profili geri getirin ve kararınızı değiştirin!';
      case DiscoverFeatureType.boost:
        return 'Profilinizi 30 dakika boyunca bölgenizdeki en üst sıraya taşıyın!';
    }
  }

  IconData get _featureIcon {
    switch (widget.featureType) {
      case DiscoverFeatureType.superLike:
        return Icons.star_rounded;
      case DiscoverFeatureType.rewind:
        return Icons.undo_rounded;
      case DiscoverFeatureType.boost:
        return Icons.bolt_rounded;
    }
  }

  int get _creditCost {
    switch (widget.featureType) {
      case DiscoverFeatureType.superLike:
        return CreditService.costSuperLike;
      case DiscoverFeatureType.rewind:
        return CreditService.costUndoSwipe;
      case DiscoverFeatureType.boost:
        return CreditService.costBoost;
    }
  }

  Future<void> _useWithCredits() async {
    final creditProvider = context.read<CreditProvider>();
    if (creditProvider.balance < _creditCost) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yetersiz Bakiye! Bu işlem için $_creditCost Kredi gerekiyor. (Mevcut: ${creditProvider.balance})',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await creditProvider.spendCredits(_creditCost, "$_featureTitle Kullanımı");
    if (success && mounted) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
      widget.onActivated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚀 $_featureTitle aktif edildi! (-$_creditCost Kredi)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _useWithAd() {
    setState(() => _isAdLoading = true);
    final tier = context.read<SubscriptionProvider>().currentTier;

    AdService().showRewardedAd(
      tier: tier,
      onReward: (amount) async {
        if (mounted) {
          setState(() => _isAdLoading = false);
          Navigator.pop(context);
          widget.onActivated();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎬 Reklam ödülü ile $_featureTitle aktif edildi!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isAdLoading) {
        setState(() => _isAdLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF14161B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // İkon
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(_featureIcon, color: Colors.black, size: 36),
          ),
          const SizedBox(height: 16),

          Text(
            _featureTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _featureDescription,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: subtitleColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // 1. Seçenek: Kredi İle Kullan
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E212A) : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF262934) : const Color(0xFFEEEEEE)),
            ),
            child: ListTile(
              leading: const Icon(Icons.bolt_rounded, color: Color(0xFFFFD700), size: 28),
              title: Text('Kredi İle Aktif Et', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
              subtitle: Text('$_creditCost Kredi harcayarak tek seferlik kullanın', style: GoogleFonts.outfit(color: subtitleColor, fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: _useWithCredits,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('-$_creditCost Kredi', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Seçenek: Reklam İzleyerek Kullan
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E212A) : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF262934) : const Color(0xFFEEEEEE)),
            ),
            child: ListTile(
              leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 28),
              title: Text('Ücretsiz Reklam İzle', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
              subtitle: Text('Kısa bir video reklam izleyin, ücretsiz aktif olsun', style: GoogleFonts.outfit(color: subtitleColor, fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: _isAdLoading ? null : _useWithAd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isAdLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('İZLE & AÇ', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Seçenek: Premium Pakete Geç
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E212A) : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF262934) : const Color(0xFFEEEEEE)),
            ),
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF9C27B0), size: 28),
              title: Text('Sınırsız Premium Paket', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
              subtitle: Text('Tüm ayrıcalıklara ve sınırsız haklara sahip olun', style: GoogleFonts.outfit(color: subtitleColor, fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('PAKETLER', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
          ),

          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('VAZGEÇ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: subtitleColor)),
          ),
        ],
      ),
    );
  }
}
