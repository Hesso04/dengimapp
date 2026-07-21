import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../auth/models/user_profile.dart';
import '../auth/services/discovery_service.dart';
import '../../../core/providers/user_provider.dart';
import '../payment/premium_offer_screen.dart';
import '../discover/user_profile_detail_screen.dart'; // Added for navigation

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  List<UserProfile> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    final visitors = await DiscoveryService().getProfileVisitors();
    if (mounted) {
      setState(() {
        _visitors = visitors;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isPremium = userProvider.currentUser?.isPremium ?? false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final elementColor = isDark ? Colors.white : Colors.black;
    final bgColor = theme.scaffoldBackgroundColor;
    final appBarBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: elementColor, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ZİYARETÇİLER",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: elementColor,
            letterSpacing: -1,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: isDark ? Colors.white10 : Colors.black,
            height: AppColors.neoBorderWidth,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadVisitors,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: elementColor, strokeWidth: 4))
            : _visitors.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: _buildEmptyState(isDark, elementColor, borderColor),
                    ),
                  )
                : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _visitors.length,
                    itemBuilder: (context, index) {
                      return _VisitorCard(
                        user: _visitors[index],
                        isPremium: isPremium,
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color elementColor, Color borderColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.0),
              boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
            ),
            child: const Icon(Icons.visibility_off_rounded, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            "HENÜZ ZİYARETÇİ YOK",
            style: GoogleFonts.outfit(
              color: elementColor, 
              fontSize: 22, 
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Profilini öne çıkararak daha fazla görünürlük elde edebilirsin!",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white70 : Colors.black87, 
                fontSize: 16, 
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitorCard extends StatelessWidget {
  final UserProfile user;
  final bool isPremium;

  const _VisitorCard({required this.user, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);

    return GestureDetector(
      onTap: () {
        if (!isPremium) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileDetailScreen(user: user)));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13), // 16 - 3 border
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: user.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 250,
                placeholder: (context, url) => Container(color: Colors.black12),
              ),
              if (!isPremium)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor, width: 1.0),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? user.name : "Gizli Ziyaretçi",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      if (isPremium)
                        Text(
                          "${user.age} • ${user.location}",
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
