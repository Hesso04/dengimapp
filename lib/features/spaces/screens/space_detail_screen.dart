import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/space_model.dart';
import '../providers/space_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SpaceDetailScreen extends StatefulWidget {
  final String spaceId;

  const SpaceDetailScreen({super.key, required this.spaceId});

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  bool _isMuted = true;

  @override
  Widget build(BuildContext context) {
    final spaceProvider = context.watch<SpaceProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;
    
    // Find the current space
    final space = spaceProvider.spaces.firstWhere(
      (s) => s.id == widget.spaceId,
      orElse: () => spaceProvider.currentSpace ?? SpaceRoom(
        id: '', 
        title: '', 
        hostId: '', 
        hostName: '', 
        hostAvatar: '', 
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (space.id.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isHost = space.hostId == currentUser?.uid;
    final isSpeaker = space.speakers.any((s) => s.userId == currentUser?.uid);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: Stack(
        children: [
          // Upper Gradient
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  radius: 1.2,
                ),
              ),
            ),
          ),

          Column(
            children: [
              _buildTopBar(context, space),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSpaceTitle(space),
                      const SizedBox(height: 32),
                      _buildSpeakersSection(space),
                      const SizedBox(height: 40),
                      _buildListenersSection(space),
                    ],
                  ),
                ),
              ),
              _buildBottomControls(context, space, currentUser, isHost, isSpeaker),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, SpaceRoom space) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.headset_rounded, color: Colors.white38, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    '${space.listenerCount}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildEndButton(context, space),
          ],
        ),
      ),
    );
  }

  Widget _buildEndButton(BuildContext context, SpaceRoom space) {
    final currentUser = context.read<UserProvider>().currentUser;
    if (space.hostId != currentUser?.uid) return const SizedBox.shrink();

    return TextButton(
      onPressed: () {
        // Odayı bitir
      },
      child: Text(
        'BİTİR',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.redAccent,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSpaceTitle(SpaceRoom space) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            space.category.name.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          space.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakersSection(SpaceRoom space) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KONUŞMACILAR',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white38,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 24,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: space.speakers.length,
          itemBuilder: (context, index) {
            final p = space.speakers[index];
            return _buildParticipantItem(p, isLarge: true);
          },
        ),
      ],
    );
  }

  Widget _buildListenersSection(SpaceRoom space) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DİNLEYİCİLER',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white38,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: 8, // Mock count for now
          itemBuilder: (context, index) {
            return _buildParticipantItem(
              const SpaceParticipant(
                agoraUid: 0,
                userId: 'mock',
                name: 'Dinleyici',
                role: SpaceRole.listener,
              ),
              isLarge: false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildParticipantItem(SpaceParticipant p, {required bool isLarge}) {
    final size = isLarge ? 80.0 : 60.0;
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: p.isSpeaking ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1A1D23)),
                child: ClipOval(
                  child: p.avatarUrl != null
                      ? CachedNetworkImage(imageUrl: p.avatarUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: Colors.white24),
                ),
              ),
            ),
            if (p.role == SpaceRole.host)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.star_rounded, size: 12, color: Colors.black),
                ),
              ),
            if (p.isMuted && p.role != SpaceRole.listener)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFF2D3238), shape: BoxShape.circle),
                  child: const Icon(Icons.mic_off_rounded, size: 12, color: Colors.white54),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          p.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isLarge ? 12 : 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context, SpaceRoom space, dynamic currentUser, bool isHost, bool isSpeaker) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D23),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Ayrıl Butonu
          _buildActionButton(
            onTap: () => Navigator.pop(context),
            icon: Icons.exit_to_app_rounded,
            label: 'AYRIL',
            color: Colors.redAccent.withValues(alpha: 0.1),
            iconColor: Colors.redAccent,
          ),

          Row(
            children: [
              if (isSpeaker)
                _buildCircularButton(
                  onTap: () => setState(() => _isMuted = !_isMuted),
                  icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: _isMuted ? Colors.white10 : AppColors.primary,
                  iconColor: _isMuted ? Colors.white38 : Colors.black,
                ),
              if (!isSpeaker)
                _buildActionButton(
                  onTap: () {
                    // El kaldır
                  },
                  icon: Icons.front_hand_rounded,
                  label: 'EL KALDIR',
                  color: AppColors.primary.withValues(alpha: 0.1),
                  iconColor: AppColors.primary,
                ),
              const SizedBox(width: 16),
              _buildCircularButton(
                onTap: () {
                  // Paylaş
                },
                icon: Icons.ios_share_rounded,
                color: Colors.white.withValues(alpha: 0.05),
                iconColor: Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: iconColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}
