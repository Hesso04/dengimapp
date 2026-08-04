import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/audio_recorder_service.dart';
import '../../../core/services/cloudinary_service.dart';

/// Voice Message Player Widget
/// Ses mesajlarını oynatmak için kullanılır
class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int duration; // Saniye cinsinden
  final bool isMe;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.isMe,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _totalDuration = Duration(seconds: widget.duration);
      
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() => _currentPosition = position);
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _currentPosition = Duration.zero;
              _audioPlayer.seek(Duration.zero);
            }
          });
        }
      });

      _audioPlayer.durationStream.listen((duration) {
        if (duration != null && mounted) {
          setState(() => _totalDuration = duration);
        }
      });
    } catch (e) {
      debugPrint('Error initializing player: $e');
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() => _isLoading = true);
        if (_audioPlayer.processingState == ProcessingState.idle) {
          await _audioPlayer.setUrl(widget.audioUrl);
        }
        setState(() => _isLoading = false);
        await _audioPlayer.play();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error toggling playback: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: widget.isMe
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.primary,
                ],
              )
            : null,
        color: widget.isMe ? null : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: widget.isMe
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayback,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.isMe ? Colors.black : AppColors.primary,
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isMe ? Colors.black : AppColors.primary,
                      size: 20,
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Waveform & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform
                SizedBox(
                  height: 24,
                  child: _buildWaveform(),
                ),
                const SizedBox(height: 4),
                // Time Progress
                Text(
                  _formatDuration(_isPlaying ? _currentPosition : _totalDuration),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: widget.isMe
                        ? Colors.black.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Mic Icon
          Icon(
            Icons.mic,
            size: 16,
            color: widget.isMe
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(30, (index) {
        final heights = [0.3, 0.8, 0.5, 0.9, 0.4, 0.7, 0.6, 0.8, 0.5, 0.9];
        final height = heights[index % heights.length];
        final isPassed = (index / 30) <= progress;

        return Container(
          width: 2,
          height: 24 * height,
          decoration: BoxDecoration(
            color: isPassed
                ? (widget.isMe ? Colors.black : AppColors.primary)
                : (widget.isMe
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// Voice Message Recorder Button
/// Ses mesajı kaydetmek için basılı tutma butonu
class VoiceRecorderButton extends StatefulWidget {
  final Function(String audioPath, int durationSeconds) onRecordComplete;
  final VoidCallback? onRecordStart;
  final VoidCallback? onRecordCancel;

  const VoiceRecorderButton({
    super.key,
    required this.onRecordComplete,
    this.onRecordStart,
    this.onRecordCancel,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressCancel: () => _cancelRecording(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isRecording
                  ? Colors.red.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: _isRecording
                  ? Border.all(
                      color: Colors.red
                          .withValues(alpha: 0.3 + _animationController.value * 0.4),
                      width: 2 + _animationController.value * 2,
                    )
                  : null,
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: _isRecording ? Colors.red : AppColors.primary,
              size: 24,
            ),
          );
        },
      ),
    );
  }

  final AudioRecorderService _audioRecorder = AudioRecorderService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  void _startRecording() async {
    final success = await _audioRecorder.startRecording();
    if (success) {
      setState(() => _isRecording = true);
      widget.onRecordStart?.call();
    }
  }

  void _stopRecording() async {
    final audioPath = await _audioRecorder.stopRecording();
    final duration = _audioRecorder.recordingDuration;
    setState(() => _isRecording = false);

    if (audioPath != null && audioPath.isNotEmpty) {
      final downloadUrl = await _cloudinaryService.uploadAudio(audioPath);
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        widget.onRecordComplete(downloadUrl, duration > 0 ? duration : 1);
      }
    }
  }

  void _cancelRecording() async {
    await _audioRecorder.cancelRecording();
    setState(() => _isRecording = false);
    widget.onRecordCancel?.call();
  }
}
