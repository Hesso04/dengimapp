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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: showSearchBar ? null : 0,
      child: showSearchBar ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0)),
        ),
        child: Column(
          children: [
            // Arama input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                autofocus: true,
                style: GoogleFonts.outfit(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'PROFİL ARA...',
                  hintStyle: GoogleFonts.outfit(color: Colors.black.withValues(alpha: 0.3), fontSize: 16, fontWeight: FontWeight.bold),
                  prefixIcon: const Icon(Icons.search, color: Colors.black, size: 22),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black, size: 20),
                          onPressed: onClear,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('ARANIYOR...', style: GoogleFonts.outfit(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900)),
                  ],
                ),
              )
            else if (searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final user = searchResults[index];
                    return _buildSearchResultItem(context, user);
                  },
                ),
              )
            else if (searchQuery.length >= 2)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Sonuç bulunamadı',
                  style: GoogleFonts.outfit(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildSearchResultItem(BuildContext context, UserProfile user) {
    return InkWell(
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: user.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surface),
                  errorWidget: (_, __, ___) => const Icon(Icons.person, color: Colors.white38),
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
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.blue, size: 14),
                      ],
                      if (user.isPremium) ...[
                        const SizedBox(width: 4),
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
                          child: const Icon(Icons.star, color: Colors.white, size: 14),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.age} • ${user.location.toUpperCase()}',
                    style: GoogleFonts.outfit(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            
            // Ok ikonu
            Icon(Icons.chevron_right, color: Colors.black.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}
