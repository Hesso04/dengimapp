import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Typing Indicator Service
/// Kullanıcının yazıyor durumunu yönetir
class TypingIndicatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Yazma durumunu başlat
  Future<void> startTyping(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('conversations')
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .set({
        'isTyping': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error starting typing: $e');
    }
  }

  /// Yazma durumunu durdur
  Future<void> stopTyping(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('conversations')
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .delete();
    } catch (e) {
      debugPrint('Error stopping typing: $e');
    }
  }

  /// Typing stream - Karşı tarafın yazıp yazmadığını dinle
  Stream<bool> getTypingStream(String chatId, String otherUserId) {
    return _firestore
        .collection('conversations')
        .doc(chatId)
        .collection('typing')
        .doc(otherUserId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      
      final data = snapshot.data();
      if (data == null) return false;
      
      final isTyping = data['isTyping'] ?? false;
      final timestamp = data['timestamp'] as Timestamp?;
      
      // 5 saniyeden eski ise false say
      if (timestamp != null) {
        final difference = DateTime.now().difference(timestamp.toDate());
        if (difference.inSeconds > 5) return false;
      }
      
      return isTyping;
    });
  }
}

/// Typing Indicator Widget
/// Kullanıcının yazıyor animasyonunu gösterir
class TypingIndicator extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final Color color;

  const TypingIndicator({
    super.key,
    required this.chatId,
    required this.otherUserId,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: TypingIndicatorService().getTypingStream(chatId, otherUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _TypingDots(color: color),
              const SizedBox(width: 8),
              Text(
                'yazıyor...',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Typing Dots Animation
class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final delay = index * 0.2;
    final scale = 1.0 +
        0.5 *
            ((_controller.value + delay) % 1.0 < 0.5
                ? (_controller.value + delay) % 1.0 * 2
                : 2 - ((_controller.value + delay) % 1.0 * 2));

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Compact Typing Indicator (for chat list)
class CompactTypingIndicator extends StatelessWidget {
  final Color color;

  const CompactTypingIndicator({
    super.key,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TypingDots(color: color),
        const SizedBox(width: 6),
        Text(
          'yazıyor',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
