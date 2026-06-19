import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// "Melodi" — the Beat Nusantara rhythm spirit. An original, glowing beat-creature
/// (no copyrighted characters), now a *lively* character: gentle breathing bob,
/// a soft body sway, little waving arms, periodic eye-blinks, a wayang-style
/// shadow for depth, and a few mood expressions. All painted, so it stays tiny,
/// sharp and free of image assets.
enum Mood { happy, cheer, wink, sleepy }

class Mascot extends StatefulWidget {
  final double size;
  final Mood mood;
  final Color color;
  final bool animate;

  /// Little waving arms + wayang shadow. On by default; turn off for a flatter
  /// emblem (e.g. very small inline uses).
  final bool arms;
  const Mascot({
    super.key,
    this.size = 96,
    this.mood = Mood.happy,
    this.color = AppColors.cyan,
    this.animate = true,
    this.arms = true,
  });

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  // One looping clock (non-reversing) so we can derive several independent
  // motions (bob / sway / blink / arm-wave) at different frequencies.
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))
        ..repeat();

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
        animation: widget.animate ? _c : const AlwaysStoppedAnimation(0.0),
        builder: (_, __) {
          final t = widget.animate ? _c.value : 0.0;
          final s = widget.size;
          // breathing bob + tiny sway
          final bob = math.sin(t * 2 * math.pi) * s * 0.035;
          final sway = math.sin(t * 2 * math.pi * 0.5) * 0.05; // radians
          return Transform.translate(
            offset: Offset(0, bob),
            child: Transform.rotate(
              angle: widget.mood == Mood.sleepy ? sway * 0.4 : sway,
              child: CustomPaint(
                painter: _MascotPainter(widget.mood, widget.color, t, widget.arms),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final Mood mood;
  final Color color;
  final double t; // 0..1 loop
  final bool arms;
  _MascotPainter(this.mood, this.color, this.t, this.arms);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;

    // blink: eyes shut briefly ~twice per loop (skip when sleepy = already shut)
    final blinkPhase = (t * 2.0) % 1.0;
    final blinking = mood != Mood.sleepy && blinkPhase < 0.06;
    // arm wave swing
    final swing = math.sin(t * 2 * math.pi * 1.0);

    // ---- wayang-style shadow (offset silhouette, painted first) ----
    if (arms) {
      final shadowRect = Rect.fromCenter(
          center: Offset(cx + s * 0.05, s * 0.62), width: s * 0.74, height: s * 0.7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(shadowRect, Radius.circular(s * 0.32)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // glow halo
    canvas.drawCircle(
      Offset(cx, s * 0.55),
      s * 0.5,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.0)])
            .createShader(Rect.fromCircle(center: Offset(cx, s * 0.55), radius: s * 0.5)),
    );

    // antenna topped with a GUNUNGAN (wayang kayon) crown — Nusantara identity
    final crownColor = mood == Mood.sleepy ? AppColors.textLo : AppColors.gold;
    canvas.drawLine(
        Offset(cx, s * 0.30),
        Offset(cx, s * 0.23),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = s * 0.02);
    final crownC = Offset(cx, s * 0.12);
    final cw = s * 0.12, ch = s * 0.14;
    final crown = Path()
      ..moveTo(crownC.dx, crownC.dy + ch)
      ..quadraticBezierTo(crownC.dx - cw * 1.25, crownC.dy, crownC.dx, crownC.dy - ch)
      ..quadraticBezierTo(crownC.dx + cw * 1.25, crownC.dy, crownC.dx, crownC.dy + ch)
      ..close();
    canvas.drawPath(
        crown,
        Paint()
          ..color = crownColor.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(
        crown,
        Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.goldLt, AppColors.gold, AppColors.coral],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromCenter(center: crownC, width: cw * 2.5, height: ch * 2)));
    canvas.drawPath(
        crown,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012
          ..color = AppColors.goldLt);
    // little maroon "isen" jewel inside the gunungan
    canvas.drawCircle(crownC, s * 0.022, Paint()..color = AppColors.maroon.withValues(alpha: 0.85));

    // ---- arms (drawn behind body so shoulders tuck in) ----
    if (arms) {
      final armPaint = Paint()
        ..color = Color.lerp(color, AppColors.violet, 0.25)!
        ..strokeWidth = s * 0.066
        ..strokeCap = StrokeCap.round;
      // cheer = both arms up; otherwise gentle alternating wave
      final upL = mood == Mood.cheer ? -1.0 : swing;
      final upR = mood == Mood.cheer ? -1.0 : -swing;
      final shoulderY = s * 0.56;
      canvas.drawLine(Offset(cx - s * 0.32, shoulderY),
          Offset(cx - s * 0.40, shoulderY + upL * s * 0.14 - s * 0.02), armPaint);
      canvas.drawLine(Offset(cx + s * 0.32, shoulderY),
          Offset(cx + s * 0.40, shoulderY + upR * s * 0.14 - s * 0.02), armPaint);
      // little hand dots
      final hand = Paint()..color = Color.lerp(color, Colors.white, 0.3)!;
      canvas.drawCircle(Offset(cx - s * 0.40, shoulderY + upL * s * 0.14 - s * 0.02), s * 0.05, hand);
      canvas.drawCircle(Offset(cx + s * 0.40, shoulderY + upR * s * 0.14 - s * 0.02), s * 0.05, hand);
    }

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

    // a small batik "kawung" dot motif on the belly → traditional touch
    final motif = Paint()..color = Colors.white.withValues(alpha: 0.14);
    for (final d in const [Offset(0, 0.0), Offset(-0.12, 0.06), Offset(0.12, 0.06), Offset(0, 0.13)]) {
      canvas.drawCircle(Offset(cx + d.dx * s, s * 0.72 + d.dy * s), s * 0.012, motif);
    }

    // songket gold band + tumpal teeth across the waist (only when big enough)
    if (s > 70) {
      final bandY = s * 0.84;
      canvas.drawLine(Offset(cx - s * 0.28, bandY), Offset(cx + s * 0.28, bandY),
          Paint()..color = AppColors.goldLt.withValues(alpha: 0.5)..strokeWidth = s * 0.018);
      for (double dx = -0.22; dx <= 0.221; dx += 0.073) {
        final tx = cx + dx * s;
        canvas.drawPath(
          Path()
            ..moveTo(tx - s * 0.022, bandY - s * 0.006)
            ..lineTo(tx, bandY - s * 0.04)
            ..lineTo(tx + s * 0.022, bandY - s * 0.006)
            ..close(),
          Paint()..color = AppColors.gold.withValues(alpha: 0.6),
        );
      }
    }

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

    void blinkLine(double ex) {
      canvas.drawLine(Offset(ex - s * 0.06, eyeY), Offset(ex + s * 0.06, eyeY), line);
    }

    void roundEye(double ex) {
      if (blinking) {
        blinkLine(ex);
        return;
      }
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
        // floating "z" to read as sleepy
        final zP = Paint()
          ..color = AppColors.textLo.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.018;
        final zx = cx + s * 0.34, zy = s * 0.2 - math.sin(t * 2 * math.pi) * s * 0.03;
        canvas.drawPath(
          Path()
            ..moveTo(zx, zy)
            ..lineTo(zx + s * 0.06, zy)
            ..lineTo(zx, zy + s * 0.06)
            ..lineTo(zx + s * 0.06, zy + s * 0.06),
          zP,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) =>
      old.mood != mood || old.t != t || old.color != color || old.arms != arms;
}

/// Mascot + a charming speech bubble. Great for onboarding / empty states /
/// missions / the home greeting: "Yuk main lagi!", "Ayo kejar Full Combo!".
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
