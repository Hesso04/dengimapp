import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/agora_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/log_service.dart';

class CallScreen extends StatefulWidget {
  final String userName;
  final String userAvatar;
  final String channelId;
  final bool isVideo;
  final String? otherUserId;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.channelId,
    this.isVideo = false,
    this.otherUserId,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  final _agoraService = AgoraService();
  int? _remoteUid;
  
  Timer? _timer;
  int _seconds = 0;
  bool _isMuted = false;
  bool _isSpeaker = false;

  late AnimationController _pulseController;
  StreamSubscription? _callSubscription;
  bool _isCallConnected = false;
  bool _isOutgoingRinging = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initCallFlow();
  }

  Future<void> _initCallFlow() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      Navigator.pop(context);
      return;
    }

    if (widget.isIncoming) {
      setState(() {
        _isCallConnected = true;
        _isOutgoingRinging = false;
      });
      await _connectToAgora();
      _startTimer();
      _listenToCallDocument();
    } else {
      setState(() {
        _isOutgoingRinging = true;
        _isCallConnected = false;
      });
      
      try {
        await FirebaseFirestore.instance.collection('calls').doc(widget.channelId).set({
          'id': widget.channelId,
          'callerId': currentUserId,
          'callerName': FirebaseAuth.instance.currentUser?.displayName ?? 'Dengim Kullanıcısı',
          'callerAvatar': FirebaseAuth.instance.currentUser?.photoURL ?? '',
          'receiverId': widget.otherUserId ?? '',
          'status': 'ringing',
          'createdAt': FieldValue.serverTimestamp(),
        });

        _listenToCallDocument();

        _timeoutTimer = Timer(const Duration(seconds: 30), () {
          _endCall();
        });
      } catch (e) {
        LogService.e("Failed to create call doc: $e");
        if (mounted) Navigator.pop(context);
      }
    }
  }

  void _listenToCallDocument() {
    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.channelId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'] ?? '';
      if (status == 'accepted') {
        _timeoutTimer?.cancel();
        if (!_isCallConnected) {
          setState(() {
            _isCallConnected = true;
            _isOutgoingRinging = false;
          });
          _connectToAgora();
          _startTimer();
        }
      } else if (status == 'rejected' || status == 'ended') {
        _timeoutTimer?.cancel();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  Future<void> _connectToAgora() async {
    await _agoraService.init();
    
    _agoraService.engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
            });
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (mounted) {
            setState(() {
              _remoteUid = null;
            });
            _endCall();
          }
        },
      ),
    );

    await _agoraService.joinChannel(
      channelId: widget.channelId,
      uid: FirebaseAuth.instance.currentUser?.uid.hashCode.abs() ?? 0,
      isVideo: false,
      isHost: false,
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  Future<void> _endCall() async {
    _timeoutTimer?.cancel();
    _callSubscription?.cancel();
    
    try {
      await FirebaseFirestore.instance.collection('calls').doc(widget.channelId).update({
        'status': 'ended',
      });
    } catch (e) {
      // Document might not exist or already be ended
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _callSubscription?.cancel();
    _pulseController.dispose();
    _timer?.cancel();
    _agoraService.leaveChannel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.userAvatar.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.userAvatar,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.black),
                    errorWidget: (context, url, error) => Container(color: Colors.black),
                  )
                : Container(color: Colors.black),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined, color: Colors.green, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Uçtan Uca Şifreli',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_remoteUid == null)
                          ...List.generate(3, (index) {
                            return AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final progress = (_pulseController.value + index / 3) % 1.0;
                                return Container(
                                  width: 120 + (100 * progress),
                                  height: 120 + (100 * progress),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(alpha: 0.15 * (1.0 - progress)),
                                  ),
                                );
                              },
                            );
                          }),
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.surfaceDark,
                            backgroundImage: CachedNetworkImageProvider(widget.userAvatar),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.userName,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_remoteUid != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatDuration(_seconds),
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Text(
                        _isOutgoingRinging ? 'Aranıyor...' : 'Bağlanıyor...',
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 48, left: 24, right: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionCircle(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: 'Sessiz',
                        isActive: _isMuted,
                        onTap: () {
                          setState(() => _isMuted = !_isMuted);
                          _agoraService.engine.muteLocalAudioStream(_isMuted);
                        },
                      ),
                      GestureDetector(
                        onTap: _endCall,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent,
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kapat',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildActionCircle(
                        icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        label: 'Hoparlör',
                        isActive: _isSpeaker,
                        onTap: () {
                          setState(() => _isSpeaker = !_isSpeaker);
                          _agoraService.engine.setEnableSpeakerphone(_isSpeaker);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
