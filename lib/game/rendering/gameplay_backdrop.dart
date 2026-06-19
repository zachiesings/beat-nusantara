import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../engine/game_engine.dart';

/// A LIVING, reactive gameplay background — warm batik-night base + drifting
/// gamelan glows that pulse on the beat and grow brighter/warmer as your combo
/// climbs and during FEVER. A faint kawung dot field keeps it Nusantara. Cheap:
/// a handful of radial gradients + a dot grid, repainted from the game's frame
/// notifier (same one the notes use). Shared by the live screen and the
/// deterministic screenshot so what you see is what ships.
class GameplayBackdrop extends CustomPainter {
  final GameEngine engine;
  GameplayBackdrop({required this.engine, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas c, Size size) {
    final t = engine.songTimeMs / 1000.0;
    final bpm = engine.chart.bpm > 0 ? engine.chart.bpm : 120;
    final beatMs = 60000.0 / bpm;
    final beat = 1 - (engine.songTimeMs % beatMs) / beatMs; // 1 on the beat → 0
    final comboNorm = (engine.board.combo / 80).clamp(0.0, 1.0).toDouble();
    final fever = engine.feverActive;
    final intensity = 0.25 + 0.45 * comboNorm + (fever ? 0.30 : 0.0);
    final rect = Offset.zero & size;

    // base warm batik-night gradient
    c.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.ink2, AppColors.navy],
          ).createShader(rect));

    // drifting reactive glows (brighter on the beat + with combo/fever)
    final blobs = <List<dynamic>>[
      [0.18, 0.15, AppColors.gold],
      [0.84, 0.22, AppColors.maroon],
      [0.50, 0.92, fever ? AppColors.gold : AppColors.indigo],
      [0.10, 0.68, AppColors.teal],
    ];
    for (var i = 0; i < blobs.length; i++) {
      final b = blobs[i];
      final phase = t * 0.3 + i;
      final cx = (b[0] as double) * size.width + math.sin(phase) * 26;
      final cy = (b[1] as double) * size.height + math.cos(phase) * 26;
      final r = size.width * (0.52 + 0.10 * beat);
      final col = b[2] as Color;
      c.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            col.withValues(alpha: (0.10 + 0.18 * intensity) * (0.7 + 0.3 * beat)),
            col.withValues(alpha: 0.0),
          ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }

    // faint kawung batik motif field — petals + dot, fills the dark space so the
    // playfield never reads as empty; warms slightly as combo grows
    final petalA = 0.05 + 0.05 * comboNorm;
    final petal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.gold.withValues(alpha: petalA);
    final dotP = Paint()..color = AppColors.gold.withValues(alpha: petalA + 0.02);
    const gap = 64.0, pr = gap * 0.28;
    for (double y = gap / 2; y < size.height + gap; y += gap) {
      for (double x = gap / 2; x < size.width + gap; x += gap) {
        for (var k = 0; k < 4; k++) {
          final ang = math.pi / 4 + k * math.pi / 2;
          final oc = Offset(x + math.cos(ang) * pr, y + math.sin(ang) * pr);
          c.save();
          c.translate(oc.dx, oc.dy);
          c.rotate(ang);
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: pr * 1.6, height: pr * 0.8), petal);
          c.restore();
        }
        c.drawCircle(Offset(x, y), 1.4, dotP);
      }
    }

    // a large, very faint GUNUNGAN silhouette up top — quietly Nusantara
    final gx = size.width / 2, gTop = size.height * 0.06, gBot = size.height * 0.34;
    final gw = size.width * 0.22;
    final gun = Path()
      ..moveTo(gx, gBot)
      ..quadraticBezierTo(gx - gw, (gTop + gBot) / 2, gx, gTop)
      ..quadraticBezierTo(gx + gw, (gTop + gBot) / 2, gx, gBot)
      ..close();
    c.drawPath(gun, Paint()..color = AppColors.gold.withValues(alpha: 0.03 + 0.03 * (fever ? 1 : 0)));

    // gamelan "denyut" — a ring pulsing out from the hit zone on every beat
    final pulseR = size.width * (0.30 + 0.55 * beat) * (fever ? 1.3 : 1.0);
    c.drawCircle(
      Offset(size.width / 2, size.height * 0.82),
      pulseR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.gold.withValues(alpha: 0.10 * beat * (0.5 + intensity)),
    );
  }

  @override
  bool shouldRepaint(covariant GameplayBackdrop old) => true;
}
