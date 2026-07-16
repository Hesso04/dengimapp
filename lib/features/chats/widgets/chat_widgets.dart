import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_models.dart';


/// Sohbet listesi öğesi - Modern Dating App Tasarımı
class ChatListItem extends StatelessWidget {
  final ChatConversation chat;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
  });

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nameColor = theme.colorScheme.onSurface;
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.40)
        : AppColors.textSecondary;
    final timeColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        child: Row(
          children: [
            // Avatar — gradient placeholder
            Stack(
              children: [
                _buildAvatar(isDark),
                if (chat.isOnline)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.scaffoldDark : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat.userName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: nameColor,
                        ),
                      ),
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: timeColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: chat.unreadCount > 0
                                ? nameColor
                                : subColor,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    final hasAvatar = chat.userAvatar.isNotEmpty;
    final initial = chat.userName.isNotEmpty
        ? chat.userName[0].toUpperCase()
        : '?';

    if (hasAvatar) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: CachedNetworkImage(
          imageUrl: chat.userAvatar,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildGradientPlaceholder(initial),
          errorWidget: (_, __, ___) => _buildGradientPlaceholder(initial),
        ),
      );
    }
    return _buildGradientPlaceholder(initial);
  }

  Widget _buildGradientPlaceholder(String initial) {
    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Mesaj balonu - Modern "Custom Shape" Tasarım (Ses mesajı destekli)
class ChatBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.message.type == MessageType.audio) {
      _initAudio();
    }
  }

  void _initAudio() {
    final parts = widget.message.content.split('|');
    if (parts.length > 1) {
      _duration = Duration(seconds: int.tryParse(parts[1]) ?? 0);
    }

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null && mounted) {
        setState(() {
          _duration = dur;
        });
      }
    });
  }

  Future<void> _togglePlay() async {
    final parts = widget.message.content.split('|');
    final audioUrl = parts[0];

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        if (_audioPlayer.audioSource == null) {
          await _audioPlayer.setUrl(audioUrl);
        }
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('Audio play error: $e');
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.senderId == FirebaseAuth.instance.currentUser?.uid;
    final hasReactions = widget.message.reactions.isNotEmpty;
    final hasReply = widget.message.replyToContent != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final otherBubbleBg = isDark ? AppColors.surfaceDark : const Color(0xFFF2F2F2);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    final textColor = isDark ? Colors.white : Colors.black;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Yanıt gösterimi (varsa)
          if (hasReply)
            Container(
              margin: EdgeInsets.fromLTRB(isMe ? 64 : 0, 4, isMe ? 0 : 64, 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: isMe ? AppColors.primary : (isDark ? Colors.white54 : Colors.black),
                    width: AppColors.neoBorderWidthSmall,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.message.replyToContent!,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          
          // Ana mesaj balonu
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(
                  isMe ? 64 : 0,
                  4,
                  isMe ? 0 : 64,
                  hasReactions ? 12 : 4,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : otherBubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                    topRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                    bottomLeft: const Radius.circular(20),
                    bottomRight: const Radius.circular(20),
                  ),
                  border: Border.all(
                    color: borderColor,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (widget.message.storyReply != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.message.storyReply!['storyUrl'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: widget.message.storyReply!['storyUrl'],
                                  width: 40,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.white24),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "HİKAYEYE YANIT", 
                                    style: GoogleFonts.outfit(
                                      fontSize: 10, 
                                      color: isMe ? Colors.white : textColor, 
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Icon(Icons.reply, color: isMe ? Colors.white70 : textColor, size: 14),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    _buildMessageContent(isMe, isDark, textColor),
                    
                    // Zaman damgası
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(widget.message.timestamp),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: isMe ? Colors.white70 : (isDark ? Colors.white60 : Colors.black54),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildReadReceipt(isMe),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Tepkiler (mesajın altında)
              if (hasReactions)
                Positioned(
                  bottom: 0,
                  right: isMe ? 8 : null,
                  left: isMe ? null : 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1.0),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.message.reactions.values.map((emoji) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Text(emoji, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageContent(bool isMe, bool isDark, Color textColor) {
    switch (widget.message.type) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: widget.message.content,
            placeholder: (context, url) => Container(
              height: 200, width: 250,
              color: isDark ? Colors.black26 : Colors.black12,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => const SizedBox(
              height: 100, width: 100,
              child: Icon(Icons.broken_image, color: Colors.white54),
            ),
            fit: BoxFit.cover,
            width: 250,
          ),
        );
      
      case MessageType.audio:
        return _buildAudioPlayer(isMe, isDark, textColor);
      
      case MessageType.text:
        return Text(
          widget.message.content,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: isMe ? Colors.white : textColor,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        );
    }
  }

  Widget _buildAudioPlayer(bool isMe, bool isDark, Color textColor) {
    final progress = _duration.inMilliseconds > 0 
        ? _position.inMilliseconds / _duration.inMilliseconds 
        : 0.0;
        
    final progressColor = isMe ? Colors.white : (isDark ? Colors.white70 : Colors.black);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause Button
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isMe ? Colors.black.withValues(alpha: 0.15) : AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: isMe ? Colors.white : Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Waveform / Progress
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isMe ? Colors.white30 : (isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Duration
              Text(
                _isPlaying ? _formatDuration(_position) : _formatDuration(_duration),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: isMe ? Colors.white70 : (isDark ? Colors.white60 : Colors.black54),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        
        // Microphone icon
        Icon(
          Icons.mic,
          size: 16,
          color: isMe ? Colors.white54 : (isDark ? Colors.white54 : Colors.black38),
        ),
      ],
    );
  }

  /// Read Receipt Indicator
  Widget _buildReadReceipt(bool isMe) {
    final bool isRead = widget.message.isRead;
    final bool isDelivered = widget.message.isDelivered;
    
    IconData icon;
    Color color;
    
    if (isRead) {
      icon = Icons.done_all_rounded; // ✓✓
      // Görüldü tick has AppColors.primary (Rose-Red) with a circular white background for contrast
      return Container(
        padding: const EdgeInsets.all(1.5),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 11, color: AppColors.primary),
      );
    } else if (isDelivered) {
      icon = Icons.done_all_rounded; // ✓✓
      color = isMe ? Colors.white70 : Colors.black38;
    } else {
      icon = Icons.done_rounded; // ✓
      color = isMe ? Colors.white70 : Colors.black38; 
    }
    
    return Icon(icon, size: 14, color: color);
  }
}
