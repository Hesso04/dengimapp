import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // YENİ
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
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

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

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
