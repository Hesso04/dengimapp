import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/space_model.dart';
import '../../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SpaceCard extends StatelessWidget {
  final SpaceRoom space;
  final VoidCallback onTap;

  const SpaceCard({
    super.key,
    required this.space,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
          boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (space.status == SpaceStatus.live)
                  _buildLiveIndicator(isDark),
                const Spacer(),
                Text(
                  _getCategoryName(space.category).toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.4),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              space.title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (space.description != null && space.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                space.description!.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                _buildSpeakerAvatars(isDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${space.hostName} ve ${space.speakers.length + space.listenerIds.length - 1} kişi'.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                _buildListenerCount(isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
        boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.graphic_eq_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'CANLI',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerAvatars(bool isDark) {
    final speakers = space.speakers.take(3).toList();
    return SizedBox(
      height: 36,
      width: 36.0 + (speakers.length > 1 ? (speakers.length - 1) * 22 : 0),
      child: Stack(
        children: List.generate(speakers.length, (index) {
          return Positioned(
            left: index * 22.0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
                boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: speakers[index].avatarUrl ?? 'https://ui-avatars.com/api/?name=${speakers[index].name}&background=random&color=fff&size=128&font-size=0.4',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.black12),
                  errorWidget: (context, url, error) => Icon(Icons.person, size: 18, color: isDark ? Colors.white24 : Colors.black),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildListenerCount(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE), width: 1.0),
        boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
      ),
      child: Row(
        children: [
          Icon(Icons.headset_rounded, size: 14, color: isDark ? Colors.white : Colors.black),
          const SizedBox(width: 6),
          Text(
            '${space.listenerCount}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(SpaceCategory category) {
    switch (category) {
      case SpaceCategory.chat: return 'SOHBET';
      case SpaceCategory.music: return 'MÜZİK';
      case SpaceCategory.dating: return 'TANIŞMA';
      case SpaceCategory.advice: return 'TAVSİYE';
      case SpaceCategory.fun: return 'EĞLENCE';
    }
  }
}
