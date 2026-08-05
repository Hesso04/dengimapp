import 'dart:math';
import 'package:flutter/material.dart';

/// Gold & Platinum kullanıcı kartları için hareketli, parıldayan mikro-yıldızlar efekti
class GoldSparkleBackground extends StatefulWidget {
  final Widget child;
  final String tier; // 'gold' or 'platinum'
  final bool isDark;

  const GoldSparkleBackground({
    super.key,
    required this.child,
    required this.tier,
    required this.isDark,
  });

  @override
  State<GoldSparkleBackground> createState() => _GoldSparkleBackgroundState();
}

class _GoldSparkleBackgroundState extends State<GoldSparkleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_StarParticle> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Generate 15 random micro-stars
    for (int i = 0; i < 15; i++) {
      _stars.add(
        _StarParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3 + 1.5,
          speed: _random.nextDouble() * 0.4 + 0.2,
          phase: _random.nextDouble() * 2 * pi,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlatinum = widget.tier.toLowerCase() == 'platinum';

    final gradientColors = isPlatinum
        ? [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
            const Color(0xFF334155),
          ]
        : [
            widget.isDark ? const Color(0xFF2A2000) : const Color(0xFFFFFBEB),
            widget.isDark ? const Color(0xFF181300) : const Color(0xFFFEF3C7),
          ];

    final borderColor = isPlatinum
        ? const Color(0xFF94A3B8)
        : const Color(0xFFF59E0B);

    final glowColor = isPlatinum
        ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
        : const Color(0xFFF59E0B).withValues(alpha: 0.3);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Moving Stars Custom Painter
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    painter: _SparkleStarsPainter(
                      stars: _stars,
                      progress: _controller.value,
                      isPlatinum: isPlatinum,
                    ),
                  ),
                ),
              ),
              // Actual content inside
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _StarParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;

  _StarParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}

class _SparkleStarsPainter extends CustomPainter {
  final List<_StarParticle> stars;
  final double progress;
  final bool isPlatinum;

  _SparkleStarsPainter({
    required this.stars,
    required this.progress,
    required this.isPlatinum,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var star in stars) {
      final opacity = (sin(progress * 2 * pi * star.speed + star.phase) + 1) / 2;
      final color = isPlatinum
          ? Colors.cyanAccent.withValues(alpha: opacity * 0.8)
          : const Color(0xFFFBBF24).withValues(alpha: opacity * 0.9);

      paint.color = color;
      final dx = (star.x * size.width);
      final dy = ((star.y + progress * star.speed * 0.2) % 1.0) * size.height;

      // Draw a 4-point micro-star sparkle
      _drawSparkleStar(canvas, Offset(dx, dy), star.size * opacity, paint);
    }
  }

  void _drawSparkleStar(Canvas canvas, Offset center, double size, Paint paint) {
    if (size <= 0.2) return;
    final path = Path();
    path.moveTo(center.dx, center.dy - size * 2);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size * 2, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size * 2);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size * 2, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size * 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkleStarsPainter oldDelegate) => true;
}
