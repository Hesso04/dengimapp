import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/typing_indicator_service.dart';
import '../../../core/widgets/online_status_indicator.dart';
import '../../../core/providers/user_provider.dart';

import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../widgets/chat_list_item_data.dart';
import '../widgets/chat_input_widget.dart';
import '../../auth/services/report_service.dart';
import '../../payment/premium_offer_screen.dart';
import 'call_screen.dart';
import '../../../core/utils/error_handler.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  
  ChatMessage? _replyingTo;
  bool _isSubmittingReport = false;
  
  // Tepki emojileri
  static const List<String> _reactionEmojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];

  StreamSubscription? _conversationSubscription;

  @override
  void initState() {
    super.initState();
    _chatService.markAsRead(widget.chatId);
    
    // Mark all messages as read (for read receipt indicators)
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // ReadReceiptService().markAllAsRead(chatId: widget.chatId, userId: uid);
    }    
    // Listen for new messages while in this screen to clear unread count
    _conversationSubscription = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.chatId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final unreadCounts = data?['unreadCounts'] as Map<String, dynamic>?;
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && (unreadCounts?[uid] ?? 0) > 0) {
          _chatService.markAsRead(widget.chatId);
        }
      }
    });
  }

  @override
  void dispose() {
    _conversationSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.amber),
              title: Text(
                'Kullanıcıyı Raporla',
                style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.w800),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: Text(
                'Kullanıcıyı Engelle',
                style: GoogleFonts.outfit(color: Colors.orange, fontWeight: FontWeight.w800),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
                    ),
                    title: Text('KULLANICIYI ENGELLE?', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900)),
                    content: Text(
                      '${widget.otherUserName} ENGELLENSİN Mİ? SİZE MESAJ GÖNDEREMEYECEK.',
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
                        child: Text('ENGELLE', style: GoogleFonts.outfit(color: AppColors.red, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await _chatService.blockUser(widget.otherUserId);
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('${widget.otherUserName} engellendi')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: Text(
                'Sohbeti Sil',
                style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w800),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
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
                      'BU SOHBET SİLİNECEK. BU İŞLEM GERİ ALINAMAZ.',
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
                  await _chatService.deleteConversation(widget.chatId);
                  navigator.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            OnlineStatusBadge(
              userId: widget.otherUserId,
              badgeSize: 12,
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(widget.otherUserAvatar),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.otherUserName.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  LastSeenText(
                    userId: widget.otherUserId,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.black, size: 22),
            onPressed: () {
              final userProvider = context.read<UserProvider>();
              final userTier = userProvider.currentUser?.subscriptionTier ?? 'free';
              
              if (userTier == 'free') {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => PremiumOfferScreen()));
                 return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallScreen(
                    channelId: widget.chatId,
                    userName: widget.otherUserName,
                    userAvatar: widget.otherUserAvatar,
                    isVideo: false,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black, size: 24),
            onPressed: _showChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'HENÜZ MESAJ YOK',
                      style: GoogleFonts.outfit(color: Colors.black.withValues(alpha: 0.3), fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  );
                }

                final messages = snapshot.data!
                    .where((m) => !m.deletedFor.contains(currentUser.uid))
                    .toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.isMe(currentUser.uid);

                    return ChatListItemData(
                      message: message,
                      isMe: isMe,
                      onReply: _setReply,
                      onDelete: _deleteMessage,
                      onQuickReact: _quickReact,
                      onLongPress: _showReactionPicker,
                    );
                  },
                );
              },
            ),
          ),
          
          // Typing Indicator
          TypingIndicator(
            chatId: widget.chatId,
            otherUserId: widget.otherUserId,
            color: AppColors.primary,
          ),
          
          // Yanıt önizlemesi
          if (_replyingTo != null) _buildReplyPreview(),
          
          ChatInputWidget(
            chatId: widget.chatId,
            otherUserId: widget.otherUserId,
            replyingTo: _replyingTo,
            onClearReply: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  /// Yanıt önizlemesi
  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
          left: BorderSide(color: AppColors.primary, width: AppColors.neoBorderWidthLarge),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'YANIT VERİLİYOR',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!.content.length > 50 
                      ? '${_replyingTo!.content.substring(0, 50)}...'
                      : _replyingTo!.content,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 20),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  /// Yanıt modunu ayarla
  void _setReply(ChatMessage message) {
    setState(() => _replyingTo = message);
    // Klavyeyi aç
    FocusScope.of(context).requestFocus(FocusNode());
  }

  /// Hızlı tepki ekle (double-tap)
  void _quickReact(ChatMessage message, String emoji) {
    _chatService.addReaction(widget.chatId, message.id, emoji);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$emoji tepkisi eklendi!'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceLight,
      ),
    );
  }

  /// Tepki seçici aç
  void _showReactionPicker(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 100,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [AppColors.neoShadowSmall],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _reactionEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _chatService.addReaction(widget.chatId, message.id, emoji);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
        ),
        title: Text('RAPOR NEDENİ', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ReportReason.values.length,
            itemBuilder: (context, index) {
              final reason = ReportReason.values[index];
              if (reason == ReportReason.other) return const SizedBox.shrink(); 
              
              return ListTile(
                title: Text(reason.displayName, style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(context);
                  _submitReport(reason);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(ReportReason reason) async {
    if (_isSubmittingReport) return;
    setState(() => _isSubmittingReport = true);

    try {
      final success = await ReportService().reportUser(
        reportedUserId: widget.otherUserId,
        reason: reason,
      );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Raporunuz alındı. Teşekkür ederiz.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errMsg = e.toString().contains('already-reported')
            ? 'Bu kullanıcıyı zaten şikayet ettiniz.'
            : ErrorHandler.getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingReport = false);
      }
    }
  }

  /// Mesajı sil (swipe ile)
  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      await _chatService.deleteMessage(widget.chatId, message.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesaj silindi'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesaj silinemedi')),
        );
      }
    }
  }


}

