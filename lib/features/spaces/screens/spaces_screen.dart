import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/space_provider.dart';
import '../widgets/space_card.dart';
import '../../auth/models/user_profile.dart';
import '../../../core/providers/user_provider.dart';
import '../models/space_model.dart';
import '../widgets/create_space_modal.dart';
import 'space_detail_screen.dart';

class SpacesScreen extends StatefulWidget {
  const SpacesScreen({super.key});

  @override
  State<SpacesScreen> createState() => _SpacesScreenState();
}

class _SpacesScreenState extends State<SpacesScreen> {
  @override
  Widget build(BuildContext context) {
    final spaceProvider = context.watch<SpaceProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            Expanded(
              child: spaceProvider.spaces.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildSpacesList(spaceProvider.spaces),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCreateButton(currentUser, isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
                    boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 18),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
                  boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
                ),
                child: Row(
                  children: [
                    Icon(Icons.graphic_eq_rounded, color: isDark ? Colors.white : Colors.black, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'SESLİ ODALAR',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'NELER KONUŞULUYOR?',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CANLI SOHBETLERE KATILIN VEYA KENDİ ODANIZI OLUŞTURUN.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.5),
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSpacesList(List<SpaceRoom> spaces) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: spaces.length,
      itemBuilder: (context, index) {
        return SpaceCard(
          space: spaces[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SpaceDetailScreen(spaceId: spaces[index].id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
              boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
            ),
            child: Icon(
              Icons.mic_none_rounded,
              size: 64,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'HENÜZ AKTİF ODA YOK',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İLK ODAYI SEN BAŞLATABİLİRSİN!',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.5),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildCreateButton(UserProfile? user, bool isDark) {
    if (user == null) return null;

    // Sadece VIP Premium, Admin veya Moderatörler buton görebilir
    final canCreate = user.isPremium || 
                     user.role == UserRole.admin.name || 
                     user.role == UserRole.moderator.name;

    if (!canCreate) return null;

    return GestureDetector(
      onTap: () => _showCreateSpaceModal(context),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
          boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'ODA BAŞLAT',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showCreateSpaceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateSpaceModal(),
    );
  }
}
