import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// A one-shot celebration layer: confetti rains + sparkle stars burst. Drop it
/// in a Stack on the result screen for that satisfying "you did it!" moment.
class CelebrationOverlay extends StatefulWidget {
  final List<Color> colors;
  final int pieces;
  const CelebrationOverlay({
    super.key,
    this.colors = const [AppColors.pink, AppColors.cyan, AppColors.gold, AppColors.mint, AppColors.coral],
    this.pieces = 90,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_c.value, widget.colors, widget.pieces),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  final int n;
  _ConfettiPainter(this.t, this.colors, this.n);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < n; i++) {
      final seed = i * 0.6180339887;
      final x0 = ((seed * 7.13) % 1.0) * size.width;
      final delay = (i % 10) / 22.0;
      final p = ((t - delay) / (1 - delay)).clamp(0.0, 1.0).toDouble();
      if (p <= 0) continue;
      final drift = math.sin((p * 6) + i) * 26;
      final x = x0 + drift;
      final y = -24 + p * (size.height + 48);
      final rot = (p * 8 + i) * 1.3;
      final fade = (1 - p);
      paint.color = colors[i % colors.length].withValues(alpha: fade.clamp(0.0, 1.0).toDouble());
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      final s = 5.0 + (i % 3) * 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s, height: s * 1.8),
            const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
    // central sparkle pop (first ~50% of timeline)
    final sp = (t / 0.55).clamp(0.0, 1.0).toDouble();
    if (sp < 1) {
      final center = Offset(size.width / 2, size.height * 0.32);
      for (int i = 0; i < 8; i++) {
        final ang = i * math.pi / 4;
        final dist = sp * 80;
        final o = center + Offset(math.cos(ang) * dist, math.sin(ang) * dist);
        paint.color = AppColors.gold.withValues(alpha: (1 - sp) * 0.9);
        _star(canvas, o, 6 * (1 - sp) + 3, paint);
      }
    }
  }

  void _star(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      path.moveTo(o.dx, o.dy);
      path.lineTo(o.dx + math.cos(a) * r, o.dy + math.sin(a) * r);
    }
    c.drawPath(
        path,
        p
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
    p.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
