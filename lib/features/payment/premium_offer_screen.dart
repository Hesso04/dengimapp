import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/credit_provider.dart';
import '../../core/constants/tier_limits.dart';
import '../../core/utils/log_service.dart';
import '../ads/screens/watch_and_earn_screen.dart';

class PremiumOfferScreen extends StatefulWidget {
  const PremiumOfferScreen({super.key});

  @override
  State<PremiumOfferScreen> createState() => _PremiumOfferScreenState();
}

class _PremiumOfferScreenState extends State<PremiumOfferScreen> {
  int _selectedTierIndex = 1; // 0: Gold, 1: Platinum (Default to Platinum)
  int _selectedDurationIndex = 0; // 0: 3 Aylık, 1: 6 Aylık
  bool _isProcessingMock = false;

  final Map<String, Map<String, String>> _planProductIds = {
    'gold': {
      '3ay': 'dengim_gold',         // Google Play Console ID
      '6ay': 'dengim_gold_6ay',     // Google Play Console ID
    },
    'platinum': {
      '3ay': 'dengim_platinum_3ay', // Google Play Console ID
      '6ay': 'dengim_platinum_6ay', // Google Play Console ID
    },
  };

  void _handleRealPurchase(SubscriptionProvider provider, String tierKey, String durationKey) {
    HapticFeedback.selectionClick();
    final productId = _planProductIds[tierKey]?[durationKey];
    if (productId == null) return;

    final matchingProducts = provider.products.where((p) => p.id == productId).toList();
    if (matchingProducts.isNotEmpty) {
      provider.buyProduct(matchingProducts.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mağaza paketleri yükleniyor. Lütfen birkaç saniye sonra tekrar deneyin.'),
          backgroundColor: AppColors.primary,
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

    final currentTierKey = _selectedTierIndex == 0 ? 'gold' : 'platinum';
    final currentDurationKey = _selectedDurationIndex == 0 ? '3ay' : '6ay';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Consumer<SubscriptionProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildHeader(context, provider, isDark, textColor),
                      const SizedBox(height: 16),
                      _buildPromoBanner(),
                      const SizedBox(height: 20),

                      // Tier Selector or VIP status
                      if (provider.currentTier == 'gold') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFD700)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'GOLD ÜYESİSİNİZ — PLATINUM\'A YÜKSELTİN',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: const Color(0xFFFFD700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else if (provider.currentTier == 'free') ...[
                        _buildTierToggle(isDark),
                        const SizedBox(height: 20),
                      ],

                      // Main Offer Card or Platinum Active Card
                      if (provider.currentTier == 'platinum')
                        _buildPlatinumActiveCard(isDark, cardColor, textColor)
                      else
                        _buildMainOfferCard(
                          tierKey: provider.currentTier == 'gold' ? 'platinum' : currentTierKey,
                          durationKey: currentDurationKey,
                          isDark: isDark,
                          cardColor: cardColor,
                          textColor: textColor,
                          provider: provider,
                        ),

                      const SizedBox(height: 20),

                      // Watch & Earn Shortcut for Freemium users
                      if (provider.currentTier == 'free')
                        _buildWatchAndEarnButton(isDark),

                      const SizedBox(height: 12),

                      // Restore Purchases
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          provider.restorePurchases();
                        },
                        child: Text(
                          'SATIN ALIMLARI GERİ YÜKLE',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isProcessingMock)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SubscriptionProvider provider, bool isDark, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F222A) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? const Color(0xFF2D313E) : const Color(0xFFEEEEEE)),
            ),
            child: Icon(Icons.close_rounded, color: textColor, size: 22),
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F222A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF2D313E) : const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    TierLimits.getTierDisplayName(provider.currentTier).toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Consumer<CreditProvider>(
              builder: (context, credit, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${credit.balance} Kr',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF416C).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '🔥 PREMİUM AVANTAJLARLA 10 KAT DAHA FAZLA EŞLEŞ!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14161B) : const Color(0xFFEAEEF4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTierIndex = 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedTierIndex == 0
                      ? const Color(0xFFFFD700)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: _selectedTierIndex == 0 ? Colors.black : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GOLD',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: _selectedTierIndex == 0 ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTierIndex = 1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedTierIndex == 1
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PLATINUM',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: _selectedTierIndex == 1 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainOfferCard({
    required String tierKey,
    required String durationKey,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required SubscriptionProvider provider,
  }) {
    final isPlatinum = tierKey == 'platinum';
    final accentColor = isPlatinum ? AppColors.primary : const Color(0xFFFFD700);

    final platinumFeatures = [
      '⚡ Beğenilerde En Üst Sırada Gösterim (Priority Likes)',
      '💬 Eşleşmeden Önce Mesaj Gönder',
      '👀 Seni Beğenen Tüm Profilleri Gör',
      '🚀 Her Ay 1 Ücretsiz Profil Boost',
      '⭐ Her Hafta 5 Ücretsiz Süper Beğeni',
      '🌍 Pasaport: İstediğin Konumda Eşleş',
      '🔄 Sınırsız Yanlış Swipeları Geri Alma',
      '👑 Profilinde Özel Platinum Rozeti',
    ];

    final goldFeatures = [
      '👀 Seni Beğenen Profilleri Gör',
      '⭐ Her Hafta 5 Ücretsiz Süper Beğeni',
      '🔄 Sınırsız Swipeları Geri Alma',
      '🌍 Konum Değiştirme (Pasaport Modu)',
      '🚫 Reklamsız Deneyim',
      '🌟 Özel Gold Profil Rozeti',
    ];

    final features = isPlatinum ? platinumFeatures : goldFeatures;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPlatinum ? '👑 EN KAPSAMLI VIP DENEYİM' : '⭐ POPÜLER ÜYELİK',
              style: GoogleFonts.outfit(
                color: accentColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            isPlatinum ? 'DENGİM PLATINUM' : 'DENGİM GOLD',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPlatinum ? 'Sınırsız ayrıcalıklar ile ilk sıraya geç' : 'Eşleşme şansını 5 katına çıkar',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),

          // Duration Selector (3 Aylık vs 6 Aylık)
          Row(
            children: [
              Expanded(
                child: _buildDurationOption(
                  durationKey: '3ay',
                  title: '3 AYLIK',
                  badge: 'POPÜLER',
                  price: isPlatinum ? '₺959.99' : '₺719.00',
                  perMonthPrice: isPlatinum ? '₺320.00/ay' : '₺239.66/ay',
                  isSelected: _selectedDurationIndex == 0,
                  accentColor: accentColor,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedDurationIndex = 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDurationOption(
                  durationKey: '6ay',
                  title: '6 AYLIK',
                  badge: 'EN İYİ FİYAT',
                  price: isPlatinum ? '₺1679.99' : '₺1199.99',
                  perMonthPrice: isPlatinum ? '₺280.00/ay' : '₺200.00/ay',
                  isSelected: _selectedDurationIndex == 1,
                  accentColor: accentColor,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedDurationIndex = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Features List
          Column(
            children: List.generate(features.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, color: accentColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        features[index],
                        style: GoogleFonts.outfit(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          ElevatedButton(
            onPressed: () => _handleRealPurchase(provider, tierKey, durationKey),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: isPlatinum ? Colors.white : Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Text(
              'HEMEN ABONE OL',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption({
    required String durationKey,
    required String title,
    required String badge,
    required String price,
    required String perMonthPrice,
    required bool isSelected,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1C1F26) : const Color(0xFFF0F2F5)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: accentColor,
              ),
            ),
            Text(
              perMonthPrice,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchAndEarnButton(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WatchAndEarnScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF191C24) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF2A2E3B) : const Color(0xFFEEEEEE)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              'REKLAM İZLE & ÜCRETSİZ KREDİ KAZAN',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatinumActiveCard(bool isDark, Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            '👑 PLATINUM ÜYELİĞİNİZ AKTİF',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tüm VIP ayrıcalıklardan ve sınırsız özelliklerden aktif olarak faydalanıyorsunuz.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: textColor.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF191C24) : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Sınırsız Beğeni, Pasaport & Öne Çıkarma',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
