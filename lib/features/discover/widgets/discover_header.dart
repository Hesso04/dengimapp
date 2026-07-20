import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/discovery_provider.dart';
import 'advanced_filters_modal.dart';
import 'filter_bottom_sheet.dart';
import '../../profile/profile_screen.dart';

class DiscoverHeader extends StatelessWidget {
  final bool showSearchBar;
  final VoidCallback onSearchToggle;
  final FilterSettings filterSettings;
  final ValueChanged<FilterSettings> onFiltersApplied;

  const DiscoverHeader({
    super.key,
    required this.showSearchBar,
    required this.onSearchToggle,
    required this.filterSettings,
    required this.onFiltersApplied,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.scaffoldDark : AppColors.scaffold;

    return Container(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sol: Kullanıcı avatarı
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  final user = userProvider.currentUser;
                  final initial = user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : '?';

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [AppColors.neoShadowSmall],
                      ),
                      child: ClipOval(
                        child: user?.imageUrl != null && user!.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: user.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _gradientPlaceholder(initial),
                                errorWidget: (_, __, ___) => _gradientPlaceholder(initial),
                              )
                            : _gradientPlaceholder(initial),
                      ),
                    ),
                  );
                },
              ),

              // Orta: DENGİM logosu
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  'DENGİM',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: Colors.white,
                  ),
                ),
              ),

              // Sağ: İkonlar — border yok, soft fill
              Row(
                children: [
                  _buildHeaderIcon(
                    context,
                    showSearchBar ? Icons.close_rounded : Icons.search_rounded,
                    onTap: onSearchToggle,
                  ),
                  const SizedBox(width: 10),
                  _buildHeaderIcon(
                    context,
                    Icons.tune_rounded,
                    isAccent: true,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => SizedBox(
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: AdvancedFiltersModal(
                            isPremium:
                                context.read<UserProvider>().currentUser?.isPremium ?? false,
                            currentFilters: filterSettings.toMap(),
                            onApplyFilters: (filters) {
                              final List<String> interests = filters['interests'] != null
                                  ? List<String>.from(filters['interests'])
                                  : [];

                              final newSettings = FilterSettings(
                                gender: filters['gender'] ?? 'all',
                                ageRange: RangeValues(
                                  (filters['minAge'] ?? 18).toDouble(),
                                  (filters['maxAge'] ?? 50).toDouble(),
                                ),
                                distance: (filters['maxDistance'] ?? 100).toDouble(),
                                interests: interests,
                                verifiedOnly: filters['verifiedOnly'] ?? false,
                                hasPhotoOnly: filters['hasPhotoOnly'] ?? true,
                                onlineOnly: filters['onlineOnly'] ?? false,
                                relationshipGoal: filters['relationshipGoal'],
                              );

                              onFiltersApplied(newSettings);

                              context.read<DiscoveryProvider>().loadDiscoveryUsers(
                                gender: filters['gender'] ?? 'all',
                                minAge: filters['minAge'] ?? 18,
                                maxAge: filters['maxAge'] ?? 50,
                                interests: interests.isNotEmpty ? interests : null,
                                maxDistance: filters['maxDistance'],
                                verifiedOnly: filters['verifiedOnly'] ?? false,
                                hasPhotoOnly: filters['hasPhotoOnly'] ?? true,
                                onlineOnly: filters['onlineOnly'] ?? false,
                                relationshipGoal: filters['relationshipGoal'],
                                forceRefresh: true,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientPlaceholder(String initial) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(
    BuildContext context,
    IconData icon, {
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Normal ikon: surfaceLight / surfaceDark fill
    // Accent (filtre) ikonu: primary rengi
    final bg = isAccent
        ? AppColors.primary
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final iconColor = isAccent
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppColors.neoRadius),
          boxShadow: isAccent ? [AppColors.primaryShadow] : [AppColors.neoShadowSmall],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
