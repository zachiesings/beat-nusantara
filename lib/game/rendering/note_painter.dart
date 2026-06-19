import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../engine/game_engine.dart';
import '../models/note.dart';

/// Renders the falling-note playfield. Pure painting — all state lives in the
/// [GameEngine]; the screen ticks a repaint notifier each frame. Kept lean:
/// O(notes) per frame with early-out for off-screen notes, optional glow.
class NotePainter extends CustomPainter {
  final GameEngine engine;
  final double approachMs;
  final int laneCount;
  final Map<int, int> laneFlash; // lane -> clockMs of last hit (for glow)
  final Map<int, int> laneMiss; // lane -> clockMs of last miss (for red flash)
  final Map<int, int> lanePress; // lane -> clockMs of last tap (ripple feedback)
  final bool reduceEffects;
  final bool highContrast;

  NotePainter({
    required this.engine,
    required this.approachMs,
    required this.laneCount,
    required this.laneFlash,
    required this.laneMiss,
    required this.lanePress,
    required this.reduceEffects,
    required this.highContrast,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final now = engine.effectiveNow;
    final laneW = size.width / laneCount;
    final hitY = size.height * (1 - K.hitLineFromBottom);
    final fever = engine.feverActive;

    _paintLanes(canvas, size, laneW, hitY, now, fever);
    _paintHitLine(canvas, size, laneW, hitY, now);

    for (final n in engine.chart.notes) {
      if (n.judged && !n.holding) continue;
      final delta = n.startTimeMs - now; // ms until this note hits the line
      if (delta > approachMs) continue; // not visible yet
      // already gone — but keep drawing an active hold's body past its head
      if (!n.holding && delta < -(K.wGood + 60)) continue;

      final frac = 1 - delta / approachMs;
      final y = frac * hitY;
      final cx = (n.lane + 0.5) * laneW;
      _paintNote(canvas, n, cx, y, laneW, hitY, now, fever);
    }

    // DISSOLVE — a freshly-hit note shatters into lane-colour shards at the line
    if (!reduceEffects) {
      for (final n in engine.chart.notes) {
        final ja = n.judgedAt;
        if (ja == null || n.holding) continue;
        final age = now - ja;
        if (age < 0 || age > 280) continue;
        final p = 1 - age / 280.0;
        final cx = (n.lane + 0.5) * laneW;
        final col = _noteColor(n);
        // expanding ghost of the note fading out
        final s = 1 + (1 - p) * 0.7;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, hitY), width: laneW * 0.72 * s, height: laneW * 0.36 * s),
              const Radius.circular(13)),
          Paint()..color = col.withValues(alpha: 0.45 * p),
        );
        // shards flying outward
        for (int k = 0; k < 7; k++) {
          final a = k * (2 * math.pi / 7) + n.lane;
          final dist = (1 - p) * laneW * 0.95;
          final o = Offset(cx + math.cos(a) * dist, hitY + math.sin(a) * dist * 0.7);
          canvas.drawCircle(o, 3.4 * p + 0.8, Paint()..color = col.withValues(alpha: 0.85 * p));
        }
      }
    }
  }

  void _paintLanes(Canvas c, Size size, double laneW, double hitY, int now, bool fever) {
    // songket gold lane dividers (brighter toward the hit line)
    for (int i = 0; i <= laneCount; i++) {
      final r = Rect.fromLTWH(i * laneW - 1, 0, 2, size.height);
      c.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gold.withValues(alpha: 0.0), AppColors.gold.withValues(alpha: highContrast ? 0.5 : 0.22)],
          ).createShader(r),
      );
    }
    for (int i = 0; i < laneCount; i++) {
      final col = AppColors.lanes[i % AppColors.lanes.length];
      final flash = laneFlash[i];
      double glow = 0;
      if (flash != null) {
        final age = now - flash;
        if (age >= 0 && age < 180) glow = (1 - age / 180) * 0.5;
      }
      final feverBase = fever ? 0.12 : 0.0;
      final rect = Rect.fromLTWH(i * laneW, 0, laneW, size.height);
      c.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              col.withValues(alpha: 0.14 + glow + feverBase),
              col.withValues(alpha: 0.02),
              col.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect),
      );

      // TAP RIPPLE — pressing a lane lights it gold from the hit line up,
      // even with no note there → the screen always answers your touch.
      final press = lanePress[i];
      if (press != null) {
        final age = now - press;
        if (age >= 0 && age < 300) {
          final p = 1 - age / 300;
          c.drawRect(
            rect,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.goldLt.withValues(alpha: 0.26 * p), AppColors.gold.withValues(alpha: 0.0)],
                stops: const [0.0, 0.55],
              ).createShader(rect),
          );
        }
      }

      // miss flash — clear but soft red, never harsh
      final miss = laneMiss[i];
      if (miss != null) {
        final age = now - miss;
        if (age >= 0 && age < 260) {
          final m = 1 - age / 260;
          c.drawRect(
            rect,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.danger.withValues(alpha: 0.3 * m), AppColors.danger.withValues(alpha: 0.0)],
              ).createShader(rect),
          );
        }
      }
    }
  }

  void _paintHitLine(Canvas c, Size size, double laneW, double hitY, int now) {
    // gong "denyut": a pulse synced to the song's BPM (gamelan heartbeat)
    final beatMs = engine.chart.bpm > 0 ? 60000.0 / engine.chart.bpm : 500.0;
    final beat = 1 - (engine.songTimeMs % beatMs) / beatMs; // 1 right on the beat → 0

    // glowing gold hit bar (pulses on the beat)
    if (!reduceEffects) {
      c.drawLine(
          Offset(0, hitY),
          Offset(size.width, hitY),
          Paint()
            ..color = AppColors.gold.withValues(alpha: 0.35 + 0.3 * beat)
            ..strokeWidth = 9 + 7 * beat
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
    c.drawLine(Offset(0, hitY), Offset(size.width, hitY),
        Paint()..color = AppColors.goldLt..strokeWidth = 2.5);

    for (int i = 0; i < laneCount; i++) {
      final cx = (i + 0.5) * laneW;
      final center = Offset(cx, hitY);
      final col = AppColors.lanes[i % AppColors.lanes.length];
      final flash = laneFlash[i];
      double age = 999;
      if (flash != null) age = (now - flash).toDouble();
      final fresh = age >= 0 && age < 240;
      final pop = fresh ? (1 - age / 240) : 0.0;

      final baseR = laneW * 0.30;
      final r = baseR * (1 + 0.14 * pop + 0.05 * beat);

      // BONANG gong: gold disc + rim + lane-colour accent + center "pencu" knob
      c.drawCircle(center, r,
          Paint()..color = AppColors.gold.withValues(alpha: 0.10 + 0.10 * beat + 0.30 * pop));
      c.drawCircle(center, r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2 + 2 * pop
            ..color = AppColors.goldLt.withValues(alpha: 0.7));
      c.drawCircle(center, r * 0.66,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = col.withValues(alpha: 0.55 + 0.4 * pop));
      c.drawCircle(center, r * 0.26,
          Paint()..color = AppColors.gold.withValues(alpha: 0.5 + 0.45 * pop));

      // GOLD BURST on a fresh hit — expanding ring + 8 rays + white core
      if (fresh && !reduceEffects) {
        c.drawCircle(
            center,
            baseR * (0.4 + 0.7 * (1 - pop)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 * pop
              ..color = AppColors.goldLt.withValues(alpha: 0.85 * pop));
        final ray = Paint()
          ..strokeWidth = 2.5 * pop
          ..strokeCap = StrokeCap.round
          ..color = AppColors.gold.withValues(alpha: 0.8 * pop);
        for (int k = 0; k < 8; k++) {
          final a = k * math.pi / 4;
          final d = Offset(math.cos(a), math.sin(a));
          c.drawLine(center + d * (r * 0.7), center + d * (r + laneW * 0.55 * (1 - pop)), ray);
        }
        c.drawCircle(center, laneW * 0.12 * pop, Paint()..color = Colors.white.withValues(alpha: 0.9 * pop));
      }
    }
  }

  void _paintNote(Canvas c, Note n, double cx, double y, double laneW, double hitY, int now, bool fever) {
    final w = laneW * 0.78;
    final col = _noteColor(n);

    // hold/slide body
    if (n.isHold) {
      final tailDelta = n.tail - now;
      final tailFrac = (1 - tailDelta / approachMs).clamp(-1.0, 2.0).toDouble();
      final tailY = tailFrac * hitY;
      final top = tailY < y ? tailY : y;
      final bottom = n.holding ? hitY : y;
      final body = RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - w * 0.34, top, cx + w * 0.34, bottom),
        const Radius.circular(10),
      );
      c.drawRRect(body, Paint()..color = col.withValues(alpha: 0.35));
      c.drawRRect(
          body,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = col.withValues(alpha: 0.8));
    }

    if (n.holding) {
      // ENERGY while a hold is kept down — a pulsing glow + sparks streaming up
      // the lane at the hit line, so a long note feels alive (not a dead "flop").
      final pulse = 0.5 + 0.5 * math.sin(now / 60.0);
      c.drawCircle(
          Offset(cx, hitY),
          laneW * (0.34 + 0.10 * pulse),
          Paint()
            ..color = col.withValues(alpha: 0.30 + 0.30 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      c.drawCircle(Offset(cx, hitY), laneW * 0.30,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 3 + 2 * pulse..color = AppColors.goldLt.withValues(alpha: 0.6 + 0.4 * pulse));
      c.drawCircle(Offset(cx, hitY), laneW * (0.12 + 0.04 * pulse), Paint()..color = Colors.white.withValues(alpha: 0.85));
      if (!reduceEffects) {
        for (int k = 0; k < 6; k++) {
          final sp = ((now / 5.0 + k * 45) % 130) / 130.0;
          final sy = hitY - sp * laneW * 1.9;
          c.drawCircle(
              Offset(cx + math.sin(now / 90.0 + k * 1.3) * laneW * 0.22, sy),
              (1 - sp) * 3.2 + 0.8,
              Paint()..color = (k.isEven ? col : AppColors.goldLt).withValues(alpha: 0.85 * (1 - sp)));
        }
      }
      return; // head already at the line; only body + this effect remain
    }

    final h = laneW * 0.40;

    // motion trail (a fading comet tail above the falling note)
    if (!reduceEffects) {
      final trailRect = Rect.fromLTRB(cx - w * 0.26, y - h * 2.4, cx + w * 0.26, y);
      c.drawRRect(
        RRect.fromRectAndRadius(trailRect, Radius.circular(w * 0.26)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [col.withValues(alpha: 0.0), col.withValues(alpha: 0.35)],
          ).createShader(trailRect),
      );
      // soft outer glow
      c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, y), width: w * 1.18, height: h * 1.3),
            Radius.circular(w * 0.3)),
        Paint()
          ..color = col.withValues(
              alpha: (n.type == NoteType.fever || n.type == NoteType.golden ? 0.5 : 0.28) + (fever ? 0.18 : 0.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }

    final rect = Rect.fromCenter(center: Offset(cx, y), width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(13));
    // glossy gradient body (lighter top → color → darker base)
    c.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(col, Colors.white, 0.5)!, col, Color.lerp(col, Colors.black, 0.25)!],
        ).createShader(rect),
    );
    // top highlight
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(rect.left + 4, rect.top + 3, rect.width - 8, h * 0.3), const Radius.circular(8)),
        Paint()..color = Colors.white.withValues(alpha: 0.45));
    c.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.85));

    // type adornments
    switch (n.type) {
      case NoteType.golden:
        _icon(c, Icons.star, cx, y, AppColors.ink, laneW * 0.22);
      case NoteType.fever:
        _icon(c, Icons.local_fire_department, cx, y, Colors.white, laneW * 0.24);
      case NoteType.flick:
        _icon(c, _arrow(n.direction), cx, y, Colors.white, laneW * 0.26);
      default:
        break;
    }
  }

  IconData _arrow(String? dir) => switch (dir) {
        'left' => Icons.keyboard_arrow_left,
        'right' => Icons.keyboard_arrow_right,
        'down' => Icons.keyboard_arrow_down,
        _ => Icons.keyboard_arrow_up,
      };

  Color _noteColor(Note n) {
    if (n.type == NoteType.golden) return AppColors.gold;
    if (n.type == NoteType.fever) return AppColors.pink;
    if (highContrast) return Colors.white;
    return AppColors.lanes[n.lane % AppColors.lanes.length];
  }

  void _icon(Canvas c, IconData icon, double cx, double cy, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant NotePainter oldDelegate) => true;
}
