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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
        ),
        title: Text('SOHBETİ SİL?', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900)),
        content: Text(
          '${chat.otherUserName} İLE OLAN SOHBETİNİZ SİLİNECEK. BU İŞLEM GERİ ALINAMAZ.',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İPTAL', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w900)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text('SİL', style: GoogleFonts.outfit(color: AppColors.red, fontWeight: FontWeight.w900)),
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
    return Scaffold(
      backgroundColor: Colors.white,
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
                    return const Center(child: CircularProgressIndicator(color: Colors.black));
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                  boxShadow: [AppColors.neoShadowSmall],
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                "MESAJLAR",
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -1.0,
                ),
              ),
              const Spacer(),
              _buildIconButton(Icons.more_vert_rounded, () {
                HapticFeedback.lightImpact();
              }),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
        boxShadow: [AppColors.neoShadowSmall],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) {
                context.read<ChatProvider>().filterChats(value);
              },
              decoration: InputDecoration(
                hintText: "SOHBETLERDE ARA...",
                hintStyle: GoogleFonts.outfit(color: Colors.black.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.bold),
                border: InputBorder.none,
              ),
              style: GoogleFonts.outfit(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              if (provider.searchQuery.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => provider.clearSearch(),
                child: const Icon(Icons.close_rounded, color: Colors.black, size: 20),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChats() {
    return Center(
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 40),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Container(
               width: 100,
               height: 100,
               decoration: BoxDecoration(
                 color: Colors.white,
                 shape: BoxShape.circle,
                 border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                 boxShadow: [AppColors.neoShadowSmall],
               ),
               child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.black),
             ),
             const SizedBox(height: 32),
             Text(
               "Henüz mesajınız yok 💬", 
               style: GoogleFonts.outfit(
                 color: Colors.black, 
                 fontSize: 20, 
                 fontWeight: FontWeight.w900,
               ),
             ),
             const SizedBox(height: 12),
             Text(
               "Eşleşmelerinizle sohbet etmeye\nburadan başlayabilirsiniz.", 
               textAlign: TextAlign.center,
               style: GoogleFonts.outfit(
                 color: Colors.black.withValues(alpha: 0.5), 
                 fontSize: 14, 
                 fontWeight: FontWeight.w800,
                 height: 1.5,
               ),
             ),
             const SizedBox(height: 32),
             GestureDetector(
               onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('KEŞFET SEKMESİNE GİDİP YENİ KİŞİLERLE EŞLEŞ!'.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
                     duration: const Duration(seconds: 2),
                     backgroundColor: Colors.black,
                   ),
                 );
               },
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                 decoration: BoxDecoration(
                   color: AppColors.primary, // Black
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
                   boxShadow: [AppColors.neoShadowSmall],
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
                     const SizedBox(width: 12),
                     Text(
                       "KEŞFETMEYE BAŞLA", 
                       style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Icon(icon, color: Colors.black, size: 22),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                "YENİ EŞLEŞMELER",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withValues(alpha: 0.5),
                  letterSpacing: 1.0,
                ),
              ),
            ),
            SizedBox(
              height: 105,
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
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Divider(color: Color(0xFFEEEEEE), height: 1),
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
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.black)),
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
