import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/theme/app_colors.dart';
import 'models/chat_models.dart';
import 'widgets/chat_widgets.dart';
import 'services/chat_service.dart';
import 'screens/chat_detail_screen.dart';

import 'package:provider/provider.dart';
import '../../core/providers/chat_provider.dart';
import '../auth/models/user_profile.dart';
import '../auth/services/discovery_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initConversations();
    });
  }

  void _onChatTap(ChatConversation chat) {
    HapticFeedback.lightImpact();
    context.read<ChatProvider>().markAsRead(chat.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chatId: chat.id,
          otherUserId: chat.otherUserId,
          otherUserName: chat.otherUserName,
          otherUserAvatar: chat.otherUserAvatar,
        ),
      ),
    );
  }

  /// Sohbeti sil (swipe ile)
  Future<void> _deleteChat(ChatConversation chat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sohbeti Sil?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          '${chat.otherUserName} ile olan sohbetiniz silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text('Sil', style: GoogleFonts.outfit(color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await ChatService().deleteConversation(chat.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${chat.otherUserName} ile sohbet silindi'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sohbet silinemedi')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildNewMatchesBar(),
            const SizedBox(height: 10),
            // Chat List
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  
                  final chats = provider.conversations;
                  
                  if (chats.isEmpty) {
                     return _buildEmptyChats();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 100, left: 24, right: 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return Slidable(
                        key: Key(chat.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (_) => _deleteChat(chat),
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_rounded,
                              label: 'SİL',
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ],
                        ),
                        child: ChatListItem(
                          chat: chat,
                          onTap: () => _onChatTap(chat),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final headerBg = isDark ? AppColors.scaffoldDark : AppColors.scaffold;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: headerBg,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppColors.neoRadiusSmall),
                  boxShadow: [AppColors.primaryShadow],
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                'Mesajlar',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              _buildIconButton(Icons.more_vert_rounded, () {
                HapticFeedback.lightImpact();
              }),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(AppColors.neoRadius),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (value) {
                context.read<ChatProvider>().filterChats(value);
              },
              decoration: InputDecoration(
                hintText: 'Sohbetlerde ara...',
                hintStyle: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              if (provider.searchQuery.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => provider.clearSearch(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.cancel_rounded, color: AppColors.textSecondary, size: 18),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChats() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final subColor = isDark ? Colors.white.withValues(alpha: 0.45) : AppColors.textSecondary;
    final iconBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                boxShadow: [AppColors.neoShadow],
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz mesajınız yok 💬',
              style: GoogleFonts.outfit(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Eşleşmelerinizle sohbet etmeye\nburadan başlayabilirsiniz.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: subColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Keşfet sekmesine gidip yeni kişilerle eşleş!',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.neoRadiusSmall),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppColors.neoRadius),
                  boxShadow: [AppColors.primaryShadow],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Keşfetmeye Başla',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final iconColor = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppColors.neoRadius),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildNewMatchesBar() {
    final chatProvider = context.watch<ChatProvider>();
    final activeChatUserIds = chatProvider.conversations.map((c) => c.otherUserId).toSet();

    return FutureBuilder<List<UserProfile>>(
      future: DiscoveryService().getMatchedUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final newMatches = snapshot.data!.where((user) => !activeChatUserIds.contains(user.uid)).toList();

        if (newMatches.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final labelColor = isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.textSecondary;
        final nameColor = theme.colorScheme.onSurface;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                'Yeni Eşleşmeler',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: newMatches.length,
                itemBuilder: (context, index) {
                  final match = newMatches[index];
                  return GestureDetector(
                    onTap: () => _startChatFromMatch(match),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2.0,
                              ),
                              boxShadow: [AppColors.neoShadowSmall],
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: CachedNetworkImageProvider(match.imageUrl),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 64,
                            child: Text(
                              match.name,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: nameColor,
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
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Divider(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                height: 1,
              ),
            ),
          ],
        );
      },
    );
  }

  void _startChatFromMatch(UserProfile match) async {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final chatProvider = context.read<ChatProvider>();
      final chatId = await ChatService().startChat(match.uid);
      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chatId,
              otherUserId: match.uid,
              otherUserName: match.name,
              otherUserAvatar: match.imageUrl,
            ),
          ),
        ).then((_) {
          // Refresh conversations when returning
          chatProvider.initConversations();
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sohbet başlatılamadı.')),
        );
      }
    }
  }
}
