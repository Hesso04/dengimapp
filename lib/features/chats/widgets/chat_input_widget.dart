import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // YENİ
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/providers/credit_provider.dart';
import '../../ads/services/ad_service.dart';
import '../../../core/services/feature_flag_service.dart';
import '../../payment/premium_offer_screen.dart';
import '../services/chat_service.dart';
import '../../../core/services/typing_indicator_service.dart';
import '../../../core/services/audio_recorder_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../models/chat_models.dart';

class ChatInputWidget extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final ChatMessage? replyingTo;
  final VoidCallback onClearReply;

  const ChatInputWidget({
    super.key,
    required this.chatId,
    required this.otherUserId,
    this.replyingTo,
    required this.onClearReply,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final TypingIndicatorService _typingService = TypingIndicatorService();
  final AudioRecorderService _audioRecorder = AudioRecorderService();

  bool _isUploading = false;
  bool _isRecording = false;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _audioRecorder.onDurationUpdate = (duration) {
      if (mounted) setState(() => _recordingDuration = duration);
    };
  }

  @override
  void dispose() {
    _typingService.stopTyping(widget.chatId);
    _messageController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _showOutOfMessageCreditsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer2<CreditProvider, SubscriptionProvider>(
          builder: (context, creditProvider, subProvider, _) {
            final canWatchAd = creditProvider.canWatchAdForMessageCredit;
            final adWatchesToday = creditProvider.messageAdWatchesToday;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14161B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: isDark ? const Color(0xFF2D313E) : const Color(0xFFEEEEEE)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'GÜNLÜK MESAJ HAKKIN BİTTİ!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bugünkü 8 ücretsiz mesaj hakkını kullandın. Mesajlaşmaya devam etmek için reklam izle veya Gold/Platinum üyeliğe geç!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Option 1: Watch Ad (+1 Message Credit)
                  ElevatedButton(
                    onPressed: canWatchAd
                        ? () {
                            Navigator.pop(context);
                            final tier = subProvider.currentTier;
                            AdService().showRewardedAdForMessageCredit(
                              tier: tier,
                              onReward: () async {
                                final success = await creditProvider.rewardForMessageCreditAd();
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🎉 +1 Mesaj Hakkı Kazandın!'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A2BE2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_fill_rounded, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          canWatchAd
                              ? 'REKLAM İZLE (+1 MESAJ HAKKI)'
                              : 'GÜNLÜK REKLAM LİMİTİ DOLDU ($adWatchesToday/10)',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Buy Subscription (Unlimited)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PremiumOfferScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          '👑 SINIRSIZ MESAJLAŞ (ÜYELİK AL)',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final subProvider = context.read<SubscriptionProvider>();
    final creditProvider = context.read<CreditProvider>();
    final tier = subProvider.currentTier;

    // Free users check daily message credits
    if (tier == 'free') {
      if (creditProvider.messageCreditsRemaining <= 0) {
        _showOutOfMessageCreditsModal();
        return;
      }
      await creditProvider.useMessageCredit();
    }

    final text = _messageController.text.trim();
    _messageController.clear();
    _typingService.stopTyping(widget.chatId);
    
    if (widget.replyingTo != null) {
      _chatService.sendReplyMessage(
        widget.chatId,
        text,
        widget.otherUserId,
        widget.replyingTo!.id,
        widget.replyingTo!.content,
      );
    } else {
      _chatService.sendMessage(
        widget.chatId,
        text,
        widget.otherUserId,
      );
    }

    widget.onClearReply();
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Fotoğraf gönderiliyor...'), duration: Duration(seconds: 1)),
          );
        }
        
        await _chatService.sendImage(widget.chatId, image, widget.otherUserId);
        
        widget.onClearReply();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fotoğraf gönderilemedi.')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _startRecording() async {
    final userProvider = context.read<UserProvider>();
    final userTier = userProvider.currentUser?.subscriptionTier ?? 'free';
    
    if (!FeatureFlagService().isVoiceMessageEnabled(userTier)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumOfferScreen()));
      return;
    }

    final started = await _audioRecorder.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofon erişimi için izin vermeniz gerekiyor'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecording) return;
    
    setState(() => _isUploading = true);
    
    try {
      final filePath = await _audioRecorder.stopRecording();
      final duration = _recordingDuration;
      
      setState(() {
        _isRecording = false;
        _recordingDuration = 0;
      });
      
      if (filePath == null) {
        throw Exception('Ses kaydı alınamadı');
      }
      
      Uint8List bytes;
      if (kIsWeb) {
         final xfile = XFile(filePath);
         bytes = await xfile.readAsBytes();
      } else {
         final file = File(filePath);
         bytes = await file.readAsBytes();
      }
      
      final audioUrl = await CloudinaryService.uploadAudioBytes(bytes);
      
      if (audioUrl != null) {
        await _chatService.sendVoiceMessage(
          widget.chatId, 
          audioUrl, 
          widget.otherUserId,
          durationSeconds: duration,
        );
        
        if (!kIsWeb) {
            final file = File(filePath);
            if (await file.exists()) {
              await file.delete();
            }
        }
        widget.onClearReply();
      } else {
        throw Exception('Ses yüklenemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ses mesajı gönderilemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _cancelRecording() async {
    await _audioRecorder.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) return _buildRecordingUI();
    return _buildInputBar();
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    final iconColor = isDark ? Colors.white : Colors.black;
    final inputTextColor = isDark ? Colors.white : Colors.black;
    final inputFillColor = isDark ? AppColors.surfaceDark : AppColors.scaffold;
    final hintTextColor = isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.3);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: barBg,
          border: Border(
            top: BorderSide(color: borderColor, width: 1.0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: _isUploading 
                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: iconColor))
                  : Icon(Icons.image, color: iconColor),
              onPressed: _isUploading ? null : _pickAndSendImage,
            ),
            IconButton(
              icon: Icon(Icons.mic, color: iconColor),
              onPressed: _startRecording,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.outfit(color: inputTextColor, fontWeight: FontWeight.w700),
                onChanged: (text) {
                  if (text.isNotEmpty) {
                    _typingService.startTyping(widget.chatId);
                  } else {
                    _typingService.stopTyping(widget.chatId);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'MESAJ YAZ...',
                  hintStyle: GoogleFonts.outfit(color: hintTextColor, fontWeight: FontWeight.w900, fontSize: 12),
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor, width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor, width: 1.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
    final textColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: barBg,
          border: Border(
            top: BorderSide(color: borderColor, width: 1.0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.red),
              onPressed: _cancelRecording,
            ),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SES KAYDEDİLİYOR...',
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AudioRecorderService.formatDuration(_recordingDuration),
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: isDark ? [] : [AppColors.neoShadowSmall],
              ),
              child: IconButton(
                icon: _isUploading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _isUploading ? null : _stopAndSendRecording,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
