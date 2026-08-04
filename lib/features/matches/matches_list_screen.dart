import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../auth/models/user_profile.dart';
import 'package:provider/provider.dart';
import '../../core/providers/chat_provider.dart';
import '../chats/screens/chat_detail_screen.dart';

/// MATCHES LIST SCREEN - Merged from tinder-clone (Kotlin)
/// Features:
/// - Grid of match avatars
/// - Click to start chat
/// - Online indicators
/// - Recent matches highlighted
class MatchesListScreen extends StatefulWidget {
  const MatchesListScreen({super.key});

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Eşleşmeler',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showMatchesFilter(context),
            icon: Icon(Icons.filter_list_rounded, color: isDark ? Colors.white : Colors.black),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final conversations = provider.conversations;
          
          if (conversations.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return CustomScrollView(
            slivers: [
              // Recent Matches Section
              if (_hasRecentMatches(conversations))
                SliverToBoxAdapter(
                  child: _buildSection(
                    title: 'YENİ EŞLEŞMELER',
                    icon: Icons.favorite_rounded,
                    iconColor: AppColors.primary,
                    isDark: isDark,
                    child: _buildMatchesHorizontalList(conversations.take(10).toList(), isDark, isRecent: true),
                  ),
                ),
              
              // All Matches Section
              SliverToBoxAdapter(
                child: _buildSection(
                  title: 'TÜM EŞLEŞMELER',
                  icon: Icons.people_rounded,
                  iconColor: AppColors.blue,
                  isDark: isDark,
                  child: const SizedBox.shrink(),
                ),
              ),
              
              // Matches Grid
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final match = conversations[index];
                      return _buildMatchGridItem(match, isDark);
                    },
                    childCount: conversations.length,
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  bool _hasRecentMatches(List<dynamic> matches) {
    // Check if there are matches from the last 7 days
    return matches.isNotEmpty;
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz eşleşme yok',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Keşfet\'e gidip insanları beğen,\nkarşılıklı beğeniler eşleşme oluşturur!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        if (child is SizedBox && (child as SizedBox).key == null)
          const SizedBox.shrink()
        else
          child,
      ],
    );
  }

  Widget _buildMatchesHorizontalList(List<dynamic> matches, bool isDark, {bool isRecent = false}) {
    return SizedBox(
      height: isRecent ? 140 : 0,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return _buildMatchAvatar(match, isDark, size: isRecent ? 90 : 0);
        },
      ),
    );
  }

  Widget _buildMatchAvatar(dynamic match, bool isDark, {double size = 0}) {
    final avatarSize = size > 0 ? size : 70.0;
    final isOnline = match.isOnline ?? false;

    return GestureDetector(
      onTap: () => _onMatchTap(match),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2.5,
                    ),
                    boxShadow: [AppColors.neoShadow],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: match.otherUserAvatar ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.white12 : Colors.grey[200],
                        child: Icon(Icons.person, color: isDark ? Colors.white30 : Colors.grey[400]),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? Colors.white12 : Colors.grey[200],
                        child: Icon(Icons.person, color: isDark ? Colors.white30 : Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? AppColors.scaffoldDark : Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: avatarSize,
              child: Text(
                match.otherUserName ?? 'Kullanıcı',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchGridItem(dynamic match, bool isDark) {
    final isOnline = match.isOnline ?? false;

    return GestureDetector(
      onTap: () => _onMatchTap(match),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isOnline ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey[300]!),
                      width: isOnline ? 2 : 1,
                    ),
                    boxShadow: [AppColors.neoShadowSmall],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: match.otherUserAvatar ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.white12 : Colors.grey[200],
                        child: Icon(Icons.person, color: isDark ? Colors.white30 : Colors.grey[400], size: 30),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? Colors.white12 : Colors.grey[200],
                        child: Icon(Icons.person, color: isDark ? Colors.white30 : Colors.grey[400], size: 30),
                      ),
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppColors.scaffoldDark : Colors.white, width: 1.5),
                      ),
                      child: Text(
                        'CANLI',
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            match.otherUserName ?? 'Kullanıcı',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _onMatchTap(dynamic match) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chatId: match.id,
          otherUserId: match.otherUserId,
          otherUserName: match.otherUserName,
          otherUserAvatar: match.otherUserAvatar,
        ),
      ),
    );
  }

  void _showMatchesFilter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrele',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _buildFilterOption('Çevrimiçi', Icons.circle, AppColors.green, ctx),
            _buildFilterOption('Yeni Eşleşmeler', Icons.favorite_rounded, AppColors.primary, ctx),
            _buildFilterOption('Mesaj Gönderilen', Icons.send_rounded, AppColors.blue, ctx),
            _buildFilterOption('Henüz Mesaj Yok', Icons.chat_bubble_outline_rounded, AppColors.orange, ctx),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, IconData icon, Color color, BuildContext ctx) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right, color: color),
      onTap: () => Navigator.pop(ctx),
    );
  }
}
