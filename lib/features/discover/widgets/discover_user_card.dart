import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../auth/models/user_profile.dart';

class DiscoverUserCard extends StatefulWidget {
  final UserProfile user;
  final double percentX;
  final double percentY;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onSuperLike;

  const DiscoverUserCard({
    super.key,
    required this.user,
    this.percentX = 0.0,
    this.percentY = 0.0,
    required this.onTap,
    required this.onLike,
    required this.onDislike,
    required this.onSuperLike,
  });

  @override
  State<DiscoverUserCard> createState() => _DiscoverUserCardState();
}

class _DiscoverUserCardState extends State<DiscoverUserCard> {
  int _currentPhotoIndex = 0;

  @override
  void didUpdateWidget(DiscoverUserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _currentPhotoIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLike = widget.percentX > 0.2;
    final showNope = widget.percentX < -0.2;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
            boxShadow: [AppColors.neoShadowLarge],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: _buildStackChildren(showLike, showNope),
            ),
        ),
      ),
    );
  }

  List<Widget> _buildStackChildren(bool showLike, bool showNope) {
    final user = widget.user;
    final percentX = widget.percentX;
    final photoUrls = user.photoUrls ?? [user.imageUrl];
    
    final children = <Widget>[
      // Multi-photo PageView
      PageView.builder(
        itemCount: photoUrls.length,
        onPageChanged: (index) {
          setState(() => _currentPhotoIndex = index);
        },
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: photoUrls[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.black12),
            errorWidget: (context, url, error) => Container(
              color: Colors.white,
              child: const Icon(Icons.person, size: 80, color: Colors.black12),
            ),
          );
        },
      ),
      // Remove gradient overlay
      const SizedBox.shrink(),
      Positioned(
        top: 24,
        right: 24,
        child: Row(
          children: [
            if (user.videoUrl != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 16),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                boxShadow: [AppColors.neoShadowSmall],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10, height: 10, 
                    decoration: BoxDecoration(
                      color: user.isOnline ? AppColors.green : AppColors.red, 
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    )
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.isOnline ? 'AKTİF' : _getLastSeenText(user), 
                    style: GoogleFonts.outfit(
                      fontSize: 10, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.black, 
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Photo Indicators
      if (photoUrls.length > 1)
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              photoUrls.length,
              (index) => Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPhotoIndex == index
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.6),
                  border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, offset: Offset(1, 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      // User Info
      Positioned(
        bottom: 12,
        left: 12,
        right: 12,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
            boxShadow: [AppColors.neoShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${user.name}, ${user.age}'.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Colors.blue, size: 22),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (user.relationshipGoal != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary, // Black
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                      ),
                      child: Text(
                        _getGoalLabel(user.relationshipGoal).toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.white, // White text on black chip
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      (user.job != null && user.job!.isNotEmpty ? user.job! : '').toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (user.latitude != null && user.longitude != null) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final currentUser = context.read<UserProvider>().currentUser;
                    if (currentUser?.latitude == null || currentUser?.longitude == null) return const SizedBox.shrink();
                    
                    final dist = _calculateDistance(
                      currentUser!.latitude!, currentUser.longitude!, 
                      user.latitude!, user.longitude!
                    );
                    
                    return Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.black, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${dist.toStringAsFixed(1)} KM UZAKTA'.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniCircleButton(
                      onTap: widget.onDislike,
                      icon: Icons.close_rounded,
                      color: Colors.redAccent,
                      iconSize: 22,
                      size: 48,
                    ),
                    _buildMiniCircleButton(
                      onTap: widget.onSuperLike,
                      icon: Icons.star_rounded,
                      color: Colors.amber,
                      iconSize: 24,
                      size: 52,
                    ),
                    _buildMiniCircleButton(
                      onTap: widget.onLike,
                      icon: Icons.favorite_rounded,
                      color: AppColors.primary,
                      iconSize: 24,
                      size: 52,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ];
    if (showLike) {
      children.add(Positioned(top: 60, left: 30, child: _buildSwipeLabel('LIKE', AppColors.success, percentX.abs())));
    }
    if (showNope) {
      children.add(Positioned(top: 60, right: 30, child: _buildSwipeLabel('NOPE', AppColors.error, percentX.abs())));
    }
    return children;
  }

  Widget _buildSwipeLabel(String text, Color color, double opacity) {
    return Transform.rotate(
      angle: text == 'NOPE' ? 0.3 : text == 'LIKE' ? -0.3 : 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
          ),
        ),
      ),
    );
  }

  String _getLastSeenText(dynamic user) {
    final lastActive = user.lastActive;
    
    final now = DateTime.now();
    final diff = now.difference(lastActive);
    
    if (diff.inMinutes < 5) return 'AZ ÖNCE';
    if (diff.inMinutes < 60) return '${diff.inMinutes} DK ÖNCE';
    if (diff.inHours < 24) return '${diff.inHours} SAAT ÖNCE';
    if (diff.inDays < 7) return '${diff.inDays} GÜN ÖNCE';
    return 'ÇEVRİMDIŞI';
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a));
  }

  String _getGoalLabel(String? key) {
    switch (key) {
      case 'serious': return '💍 Ciddi';
      case 'casual': return '🥂 Eğlence';
      case 'chat': return '☕ Sohbet';
      case 'unsure': return '🤷‍♂️ Belirsiz';
      default: return '';
    }
  }

  Widget _buildMiniCircleButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    double iconSize = 20,
    double size = 44,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
      ),
    );
  }
}
