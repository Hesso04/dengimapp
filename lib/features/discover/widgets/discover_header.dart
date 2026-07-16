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
    final borderColor = isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final elementColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: User Profile Avatar
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  final user = userProvider.currentUser;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profilini görmek için alt menüden Profil sekmesine git!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B1B1D) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: elementColor, width: 2),
                        boxShadow: isDark ? null : const [
                          BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                        ],
                      ),
                      child: ClipOval(
                        child: user?.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: user!.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: AppColors.scaffold),
                                errorWidget: (_, __, ___) => Icon(Icons.person, color: elementColor, size: 20),
                              )
                            : Icon(Icons.person, color: elementColor, size: 20),
                      ),
                    ),
                  );
                },
              ),
              
              // Middle: DENGIM
              Text(
                'DENGİM',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  color: theme.textTheme.titleLarge?.color ?? elementColor,
                ),
              ),
              
              // Right: Icons
              Row(
                children: [
                  _buildHeaderIcon(
                    context,
                    showSearchBar ? Icons.close : Icons.search_rounded,
                    onTap: onSearchToggle,
                  ),
                  const SizedBox(width: 12),
                  _buildHeaderIcon(
                    context,
                    Icons.tune_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => SizedBox(
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: AdvancedFiltersModal(
                            isPremium: context.read<UserProvider>().currentUser?.isPremium ?? false,
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

  Widget _buildHeaderIcon(BuildContext context, IconData icon, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final elementColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1B1D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: elementColor, width: isDark ? 1.5 : 2.5),
          boxShadow: isDark ? null : const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3)),
          ],
        ),
        child: Icon(icon, color: elementColor, size: 22),
      ),
    );
  }
}
