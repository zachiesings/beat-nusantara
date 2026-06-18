import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// A tilted, glowing sticker badge — the playful "slapped-on" label that makes
/// UI feel like a game, not a form. Slight rotation by default.
class Sticker extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Gradient gradient;
  final double angle;
  final double fontSize;
  const Sticker({
    super.key,
    required this.text,
    this.icon,
    this.gradient = AppGradients.candy,
    this.angle = -0.09,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final glow = (gradient is LinearGradient) ? (gradient as LinearGradient).colors.first : AppColors.pink;
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: icon != null ? 9 : 11, vertical: 6),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.5),
          boxShadow: AppShadows.glow(glow, blur: 14, y: 4, a: 0.6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: fontSize + 2, color: Colors.white), const SizedBox(width: 4)],
          Text(text,
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: fontSize, letterSpacing: 0.4)),
        ]),
      ),
    );
  }
}

/// A field of gently twinkling stars — decorative sparkle for hero areas / behind
/// celebratory content. Drop into a Positioned.fill.
class Twinkles extends StatefulWidget {
  final int count;
  final Color color;
  const Twinkles({super.key, this.count = 10, this.color = Colors.white});

  @override
  State<Twinkles> createState() => _TwinklesState();
}

class _TwinklesState extends State<Twinkles> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

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
        builder: (_, __) => CustomPaint(painter: _TwinklePainter(_c.value, widget.count, widget.color)),
      ),
    );
  }
}

class _TwinklePainter extends CustomPainter {
  final double t;
  final int count;
  final Color color;
  _TwinklePainter(this.t, this.count, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..strokeCap = StrokeCap.round;
    for (int i = 0; i < count; i++) {
      final sx = ((i * 0.61803) % 1.0) * size.width;
      final sy = ((i * 0.31831 + 0.13) % 1.0) * size.height;
      final tw = (math.sin((t * 2 * math.pi) + i * 1.7) + 1) / 2; // 0..1
      final r = 1.5 + 3.5 * tw;
      p.color = color.withValues(alpha: 0.15 + 0.6 * tw);
      // 4-point sparkle
      canvas.drawLine(Offset(sx - r, sy), Offset(sx + r, sy), p..strokeWidth = 1.4);
      canvas.drawLine(Offset(sx, sy - r), Offset(sx, sy + r), p);
    }
  }

  @override
  bool shouldRepaint(covariant _TwinklePainter old) => old.t != t;
}

/// Tumpal — the gold sawtooth triangle border from songket/tenun cloth. A small
/// band of it along a card edge instantly reads "Nusantara textile".
class Tumpal extends StatelessWidget {
  final double height;
  final Gradient gradient;
  const Tumpal({super.key, this.height = 12, this.gradient = AppGradients.goldRush});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _TumpalPainter(gradient)),
      );
}

class _TumpalPainter extends CustomPainter {
  final Gradient gradient;
  _TumpalPainter(this.gradient);

  @override
  void paint(Canvas c, Size size) {
    final paint = Paint()..shader = gradient.createShader(Offset.zero & size);
    const w = 18.0;
    final path = Path();
    for (double x = -w; x < size.width + w; x += w) {
      path.moveTo(x, size.height);
      path.lineTo(x + w / 2, 0);
      path.lineTo(x + w, size.height);
      path.close();
    }
    c.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TumpalPainter old) => false;
}

/// A soft wavy section divider — breaks up the "stacked rectangles" rhythm.
class WavyDivider extends StatelessWidget {
  final Gradient gradient;
  final double height;
  const WavyDivider({super.key, this.gradient = AppColors.brandGradient, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _WavyPainter(gradient)),
    );
  }
}

class _WavyPainter extends CustomPainter {
  final Gradient gradient;
  _WavyPainter(this.gradient);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height / 2);
    final amp = size.height * 0.32;
    for (double x = 0; x <= size.width; x += 6) {
      path.lineTo(x, size.height / 2 + math.sin(x / 26) * amp);
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  @override
  bool shouldRepaint(covariant _WavyPainter old) => false;
}
