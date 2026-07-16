import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_profile.dart';
import '../user_profile_detail_screen.dart';

class DiscoverSearchBar extends StatelessWidget {
  final bool showSearchBar;
  final TextEditingController searchController;
  final String searchQuery;
  final bool isSearching;
  final List<UserProfile> searchResults;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const DiscoverSearchBar({
    super.key,
    required this.showSearchBar,
    required this.searchController,
    required this.searchQuery,
    required this.isSearching,
    required this.searchResults,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final containerBg = isDark ? AppColors.cardDark : Colors.white;
    final inputFill = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: showSearchBar ? null : 0,
      child: showSearchBar
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: containerBg,
                boxShadow: [AppColors.neoShadowSmall],
              ),
              child: Column(
                children: [
                  // Arama input — border yok, soft fill
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(AppColors.neoRadius),
                      boxShadow: [AppColors.neoShadowSmall],
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      autofocus: true,
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Profil ara...',
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: onClear,
                                child: Icon(
                                  Icons.cancel_rounded,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        fillColor: Colors.transparent,
                        filled: true,
                      ),
                    ),
                  ),

                  // Arama sonuçları
                  if (isSearching)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Aranıyor...',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final user = searchResults[index];
                          return _buildSearchResultItem(context, user, isDark);
                        },
                      ),
                    )
                  else if (searchQuery.length >= 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'Sonuç bulunamadı',
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSearchResultItem(
      BuildContext context, UserProfile user, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final itemBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileDetailScreen(user: user),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: itemBg,
          borderRadius: BorderRadius.circular(AppColors.neoRadius),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [AppColors.neoShadowSmall],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: user.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.surfaceLight,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // İsim ve bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.outfit(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded,
                            color: Colors.blue, size: 14),
                      ],
                      if (user.isPremium) ...[
                        const SizedBox(width: 4),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.goldGradient.createShader(bounds),
                          child: const Icon(Icons.star_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.age} • ${user.location}',
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
