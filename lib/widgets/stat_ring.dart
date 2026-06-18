import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Circular progress ring with a glowing sweep + centered value/label. Makes
/// stats feel collectible instead of like table rows.
class StatRing extends StatelessWidget {
  final double progress; // 0..1
  final double size;
  final Color color;
  final String value;
  final String label;
  const StatRing({
    super.key,
    required this.progress,
    required this.value,
    required this.label,
    this.size = 92,
    this.color = AppColors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(progress.clamp(0.0, 1.0).toDouble(), color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * 0.21, color: AppColors.textHi)),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLo)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = AppColors.glass;
    canvas.drawCircle(center, r, track);

    final rect = Rect.fromCircle(center: center, radius: r);
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.4), color, Color.lerp(color, Colors.white, 0.5)!],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, sweep);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.color != color;
}
