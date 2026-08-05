import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/credit_provider.dart';
import '../../features/payment/premium_offer_screen.dart';
import '../../features/ads/screens/watch_and_earn_screen.dart';

/// Premium veya Kredi gerektiren özellikler için modal
class PremiumRequiredModal extends StatelessWidget {
  final String featureName;
  final String requiredTier; // 'gold' or 'platinum'
  final int? creditCost; // Kredi ile satın alınabilecek özellikler için

  const PremiumRequiredModal({
    super.key,
    required this.featureName,
    this.requiredTier = 'gold',
    this.creditCost,
  });

  static void show(BuildContext context, {
    required String featureName, 
    String requiredTier = 'gold',
    int? creditCost,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PremiumRequiredModal(
        featureName: featureName,
        requiredTier: requiredTier,
        creditCost: creditCost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPlatinum = requiredTier == 'platinum';
    final color = isPlatinum ? const Color(0xFFE5E4E2) : AppColors.primary;
    final creditProvider = context.watch<CreditProvider>();

    final modalBg = isDark ? const Color(0xFF14161B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? const Color(0xFF262934) : const Color(0xFFEEEEEE);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: modalBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(
              isPlatinum ? Icons.workspace_premium_rounded : Icons.star_rounded,
              color: isPlatinum ? Colors.black : Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            featureName.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'BU ÖZELLİĞİ KULLANMAK İÇİN ${requiredTier.toUpperCase()} ÜYELİĞİNE SAHİP OLMALISIN.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: subTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildBenefitRow(Icons.check_circle_outline_rounded, 'DAHA FAZLA EŞLEŞME ŞANSI', textColor),
          _buildBenefitRow(Icons.check_circle_outline_rounded, 'ÖNCELİKLİ GÖRÜNÜRLÜK', textColor),
          _buildBenefitRow(Icons.check_circle_outline_rounded, 'SINIRLARI KALDIR', textColor),
          
          const SizedBox(height: 32),

          // Kredi ile satın alınabilir
          if (creditCost != null) ...[
            GestureDetector(
              onTap: () async {
                final success = await creditProvider.spend(creditCost!, featureName.toLowerCase());
                if (context.mounted) {
                  if (success) {
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ $featureName aktif edildi! (-$creditCost kredi)',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '❌ Yetersiz kredi. ${creditCost! - creditProvider.balance} kredi daha lazım.',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F222A) : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '$creditCost KREDİ İLE KULLAN',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // İzle & Kazan butonu
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WatchAndEarnScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'REKLAM İZLE & KREDİ KAZAN',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Premium yükselt butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PremiumOfferScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'HEMEN YÜKSELT',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900, 
                  fontSize: 16, 
                  color: isPlatinum ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'DAHA SONRA',
              style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
