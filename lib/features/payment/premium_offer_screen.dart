import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/credit_provider.dart';
import '../../core/constants/tier_limits.dart';
import '../../core/utils/log_service.dart';
import '../ads/screens/watch_and_earn_screen.dart';
import '../auth/services/profile_service.dart';

class PremiumOfferScreen extends StatefulWidget {
  const PremiumOfferScreen({super.key});

  @override
  State<PremiumOfferScreen> createState() => _PremiumOfferScreenState();
}

class _PremiumOfferScreenState extends State<PremiumOfferScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  bool _isProcessingMock = false;

  void _grantMockPremium(String tier) async {
    final userProvider = context.read<UserProvider>();
    final uid = userProvider.currentUser?.uid;
    if (uid == null) return;
    
    setState(() {
      _isProcessingMock = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isPremium': true,
        'subscriptionTier': tier,
        'premiumSince': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Tebrikler! Test amaçlı ${tier.toUpperCase()} Premium tanımlandı.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Ekranı kapat
      }
    } catch (e) {
      LogService.e("Error granting mock premium", e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yetki güncelleme sırasında bir hata oluştu.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingMock = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Consumer<SubscriptionProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                return Column(
                  children: [
                    // Top Bar
                    _buildHeader(context, provider),

                    // Promo Banner
                    _buildPromoBanner(),

                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        children: [
                          _buildPlanCard(
                            title: 'GOLD',
                            color: AppColors.primary,
                            icon: Icons.star_rounded,
                            features: TierLimits.getFeaturesFor('gold'),
                            products: provider.products.where((p) => p.id.contains('gold')).toList(),
                            provider: provider,
                          ),
                          _buildPlanCard(
                            title: 'PLATINUM',
                            color: const Color(0xFFC0C0C0), // Silver-ish
                            icon: Icons.workspace_premium_rounded,
                            features: TierLimits.getFeaturesFor('platinum'),
                            products: provider.products.where((p) => p.id.contains('platinum')).toList(),
                            provider: provider,
                          ),
                        ],
                      ),
                    ),

                    // Page Indicator
                    _buildIndicator(),

                    // İzle & Kazan butonu (Freemium için)
                    Consumer<SubscriptionProvider>(
                      builder: (context, sub, _) {
                        if (sub.currentTier != 'free') return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => const WatchAndEarnScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEEEEEE), width: 1.0),
                                boxShadow: [AppColors.neoShadowSmall],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_filled_rounded, color: Colors.black, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'REKLAM İZLE & KREDİ KAZAN',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Restore Button
                    TextButton(
                      onPressed: () => provider.restorePurchases(),
                      child: Text(
                        'SATIN ALIMLARI GERİ YÜKLE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
          if (_isProcessingMock)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SubscriptionProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleIcon(Icons.close, onTap: () => Navigator.pop(context)),
          Row(
            children: [
              // Mevcut Plan Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                  boxShadow: [AppColors.neoShadowSmall],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wallet, color: Colors.black, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      TierLimits.getTierDisplayName(provider.currentTier).toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Kredi Bakiye Badge
              Consumer<CreditProvider>(
                builder: (context, credit, _) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                    boxShadow: [AppColors.neoShadowSmall],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${credit.balance}',
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
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
        boxShadow: [AppColors.neoShadowSmall],
      ),
      child: Center(
        child: Text(
          '🔥 İLK AY %50 İNDİRİM FIRSATI!',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required Color color,
    required IconData icon,
    required List<String> features,
    required List<ProductDetails> products,
    required SubscriptionProvider provider,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
        boxShadow: [AppColors.neoShadowSmall],
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
               color: color,
               shape: BoxShape.circle,
               border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
            ),
            child: Icon(icon, color: color == AppColors.primary ? Colors.white : Colors.black, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: features.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.black, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          features[index].toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Demo Pricing Options
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildDemoPriceButton('1 AY (DEMO)', '₺0.00', color, provider, title.toLowerCase()),
                _buildDemoPriceButton('6 AY (DEMO)', '₺0.00', color, provider, title.toLowerCase()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoPriceButton(String period, String price, Color color, SubscriptionProvider provider, String tier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _grantMockPremium(tier),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
            boxShadow: [AppColors.neoShadowSmall],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                period,
                style: GoogleFonts.outfit(
                  color: color == AppColors.primary ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                price,
                style: GoogleFonts.outfit(
                  color: color == AppColors.primary ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceButton(ProductDetails product, Color color, SubscriptionProvider provider) {
    String period = 'AY';
    if (product.id.contains('3')) period = '3 AY';
    if (product.id.contains('6')) period = '6 AY';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => provider.buyProduct(product),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
            boxShadow: [AppColors.neoShadowSmall],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                period,
                style: GoogleFonts.outfit(
                  color: color == AppColors.primary ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                product.price,
                style: GoogleFonts.outfit(
                  color: color == AppColors.primary ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(2, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentPage == index ? AppColors.primary : Colors.black.withValues(alpha: 0.1),
              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
            ),
          );
        }),
      ),
    );
  }
}
