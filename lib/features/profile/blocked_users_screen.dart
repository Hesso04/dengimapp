import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../auth/models/user_profile.dart';
import '../auth/services/block_service.dart';

/// Engellenen kullanıcılar listesi ekranı
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final BlockService _blockService = BlockService();
  List<UserProfile> _blockedUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _blockService.getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unblockUser(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10, width: 1.0),
        ),
        title: Text(
          'ENGELİ KALDIR?',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          '${user.name} İSİMLİ KULLANICININ ENGELİNİ KALDIRMAK İSTEDİĞİNİZE EMİN MİSİNİZ?',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İPTAL',
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w900),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
              ),
              elevation: 0,
            ),
            child: Text('EVET, KALDIR', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _blockService.unblockUser(user.uid);
      if (success && mounted) {
        setState(() {
          _blockedUsers.removeWhere((u) => u.uid == user.uid);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black,
            content: Text('${user.name.toUpperCase()} ENGELİ KALDIRILDI', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121418),
        elevation: 0,
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ENGELLENENLER',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('BİR HATA OLUŞTU', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.black)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBlockedUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
                ),
                elevation: 0,
              ),
              child: Text('TEKRAR DENE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_blockedUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                  boxShadow: [AppColors.neoShadowSmall],
                ),
                child: const Icon(Icons.block, size: 48, color: Colors.black),
              ),
              const SizedBox(height: 32),
              Text(
                'ENGELLENEN KİMSE YOK',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
              ),
              const SizedBox(height: 12),
              Text(
                'ENGELLEDİĞİNİZ KULLANICILAR BURADA LİSTELENİR.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBlockedUsers,
      color: Colors.black,
      backgroundColor: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _blockedUsers.length,
        itemBuilder: (context, index) => _buildUserTile(_blockedUsers[index]),
      ),
    );
  }

  Widget _buildUserTile(UserProfile user) {
    final photoUrl = user.photoUrls?.isNotEmpty == true
        ? user.photoUrls!.first
        : 'https://api.dicebear.com/7.x/avataaars/svg?seed=${user.uid}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
        boxShadow: [AppColors.neoShadowSmall],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.scaffold),
                errorWidget: (_, __, ___) => const Icon(Icons.person, color: Colors.black),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.name}, ${user.age}'.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.block, size: 14, color: AppColors.red),
                    const SizedBox(width: 4),
                    Text(
                      'ENGELLENDİ',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.red,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Unblock Button
          GestureDetector(
            onTap: () => _unblockUser(user),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
              ),
              child: Text(
                'KALDIR',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
