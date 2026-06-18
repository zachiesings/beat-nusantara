import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// "Melodi" — the Beat Nusantara rhythm spirit. An original, minimal, glowing
/// beat-creature (no copyrighted characters). Gentle bob; a few expressions for
/// onboarding, empty states, missions and rewards. Painted, so it's tiny & sharp.
enum Mood { happy, cheer, wink, sleepy }

class Mascot extends StatefulWidget {
  final double size;
  final Mood mood;
  final Color color;
  final bool animate;
  const Mascot({
    super.key,
    this.size = 96,
    this.mood = Mood.happy,
    this.color = AppColors.cyan,
    this.animate = true,
  });

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: widget.animate ? _c : const AlwaysStoppedAnimation(0.5),
        builder: (_, __) {
          final v = widget.animate ? _c.value : 0.5;
          final bob = math.sin(v * math.pi) * widget.size * 0.04;
          return Transform.translate(
            offset: Offset(0, bob),
            child: CustomPaint(painter: _MascotPainter(widget.mood, widget.color, v)),
          );
        },
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final Mood mood;
  final Color color;
  final double t;
  _MascotPainter(this.mood, this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;

    // glow halo
    canvas.drawCircle(
      Offset(cx, s * 0.55),
      s * 0.5,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.0)])
            .createShader(Rect.fromCircle(center: Offset(cx, s * 0.55), radius: s * 0.5)),
    );

    // antenna with glowing note bulb
    final bulb = Offset(cx, s * 0.10);
    canvas.drawLine(
        Offset(cx, s * 0.28),
        bulb,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..strokeWidth = s * 0.02);
    final bulbColor = mood == Mood.sleepy ? AppColors.textLo : AppColors.gold;
    canvas.drawCircle(bulb, s * 0.06,
        Paint()..color = bulbColor.withValues(alpha: 0.9)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(bulb, s * 0.045, Paint()..color = bulbColor);

    // body — rounded blob with gradient
    final bodyRect = Rect.fromCenter(center: Offset(cx, s * 0.58), width: s * 0.74, height: s * 0.7);
    final body = RRect.fromRectAndRadius(bodyRect, Radius.circular(s * 0.32));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(color, Colors.white, 0.25)!, color, Color.lerp(color, AppColors.violet, 0.4)!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bodyRect),
    );
    // sheen
    canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, s * 0.5), width: s * 0.5, height: s * 0.34),
        math.pi, math.pi, false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.05
          ..strokeCap = StrokeCap.round);

    // cheeks
    final blush = Paint()..color = AppColors.pink.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(cx - s * 0.22, s * 0.64), s * 0.05, blush);
    canvas.drawCircle(Offset(cx + s * 0.22, s * 0.64), s * 0.05, blush);

    // eyes + mouth per mood
    final eyeY = s * 0.55;
    final lx = cx - s * 0.14, rx = cx + s * 0.14;
    final dark = Paint()..color = const Color(0xFF12103A);
    final white = Paint()..color = Colors.white;
    final line = Paint()
      ..color = const Color(0xFF12103A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round;

    void roundEye(double ex) {
      canvas.drawCircle(Offset(ex, eyeY), s * 0.075, white);
      canvas.drawCircle(Offset(ex, eyeY), s * 0.042, dark);
      canvas.drawCircle(Offset(ex - s * 0.014, eyeY - s * 0.016), s * 0.016, white);
    }

    void arcEye(double ex) {
      // happy closed eye ∩
      canvas.drawArc(Rect.fromCircle(center: Offset(ex, eyeY + s * 0.02), radius: s * 0.06),
          math.pi, math.pi, false, line);
    }

    void sleepyEye(double ex) {
      canvas.drawArc(Rect.fromCircle(center: Offset(ex, eyeY), radius: s * 0.05),
          0.1 * math.pi, 0.8 * math.pi, false, line);
    }

    switch (mood) {
      case Mood.happy:
        roundEye(lx);
        roundEye(rx);
        canvas.drawArc(Rect.fromCircle(center: Offset(cx, s * 0.62), radius: s * 0.07),
            0.15 * math.pi, 0.7 * math.pi, false, line);
      case Mood.cheer:
        arcEye(lx);
        arcEye(rx);
        // open happy mouth
        final m = Path()
          ..addArc(Rect.fromCircle(center: Offset(cx, s * 0.63), radius: s * 0.075),
              0.05 * math.pi, 0.9 * math.pi);
        canvas.drawPath(m, Paint()..color = const Color(0xFF2A1340));
      case Mood.wink:
        roundEye(lx);
        // winking eye (downward arc)
        canvas.drawArc(Rect.fromCircle(center: Offset(rx, eyeY), radius: s * 0.06),
            1.05 * math.pi, 0.9 * math.pi, false, line);
        canvas.drawArc(Rect.fromCircle(center: Offset(cx + s * 0.02, s * 0.62), radius: s * 0.06),
            0.1 * math.pi, 0.8 * math.pi, false, line);
      case Mood.sleepy:
        sleepyEye(lx);
        sleepyEye(rx);
        canvas.drawCircle(Offset(cx, s * 0.66), s * 0.02, dark);
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) => old.mood != mood || old.t != t || old.color != color;
}

/// Mascot + a charming speech bubble. Great for onboarding / empty states /
/// missions: "Yuk main lagi!", "Ayo kejar Full Combo!".
class MascotBubble extends StatelessWidget {
  final String text;
  final Mood mood;
  final double mascotSize;
  final Color color;
  const MascotBubble({
    super.key,
    required this.text,
    this.mood = Mood.happy,
    this.mascotSize = 64,
    this.color = AppColors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Mascot(size: mascotSize, mood: mood, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.glassHi,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(text,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textHi)),
          ),
        ),
      ],
    );
  }
}
