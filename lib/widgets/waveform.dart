import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// A lively animated equalizer/waveform — gives the hero card a "this is music"
/// pulse without any audio. Cheap: one controller, painted bars.
class Waveform extends StatefulWidget {
  final Gradient gradient;
  final double height;
  final int bars;
  const Waveform({super.key, this.gradient = AppColors.brandGradient, this.height = 44, this.bars = 26});

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _WavePainter(_c.value, widget.gradient, widget.bars),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  final Gradient gradient;
  final int bars;
  _WavePainter(this.t, this.gradient, this.bars);

  @override
  void paint(Canvas canvas, Size size) {
    final shader = gradient.createShader(Offset.zero & size);
    final paint = Paint()..shader = shader;
    final gap = size.width / bars;
    final bw = gap * 0.55;
    for (int i = 0; i < bars; i++) {
      final phase = t * 2 * math.pi + i * 0.6;
      final amp = 0.35 + 0.65 * ((math.sin(phase) + 1) / 2) * (0.5 + 0.5 * math.sin(i * 1.3));
      final h = size.height * amp.clamp(0.12, 1.0).toDouble();
      final x = i * gap + (gap - bw) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - h) / 2, bw, h),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.t != t;
}
