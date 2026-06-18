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
  final bool reduceEffects;
  final bool highContrast;

  NotePainter({
    required this.engine,
    required this.approachMs,
    required this.laneCount,
    required this.laneFlash,
    required this.reduceEffects,
    required this.highContrast,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final now = engine.effectiveNow;
    final laneW = size.width / laneCount;
    final hitY = size.height * (1 - K.hitLineFromBottom);

    _paintLanes(canvas, size, laneW, hitY, now);
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
      _paintNote(canvas, n, cx, y, laneW, hitY, now);
    }
  }

  void _paintLanes(Canvas c, Size size, double laneW, double hitY, int now) {
    final sep = Paint()
      ..color = highContrast ? Colors.white24 : AppColors.glassBorder
      ..strokeWidth = 1;
    for (int i = 0; i <= laneCount; i++) {
      c.drawLine(Offset(i * laneW, 0), Offset(i * laneW, size.height), sep);
    }
    // subtle lane tint
    for (int i = 0; i < laneCount; i++) {
      final col = AppColors.lanes[i % AppColors.lanes.length];
      final flash = laneFlash[i];
      double glow = 0;
      if (flash != null) {
        final age = now - flash;
        if (age >= 0 && age < 180) glow = (1 - age / 180) * 0.5;
      }
      final rect = Rect.fromLTWH(i * laneW, 0, laneW, size.height);
      c.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              col.withValues(alpha: 0.10 + glow),
              col.withValues(alpha: 0.0),
            ],
          ).createShader(rect),
      );
    }
  }

  void _paintHitLine(Canvas c, Size size, double laneW, double hitY, int now) {
    // glowing bar
    if (!reduceEffects) {
      c.drawLine(
          Offset(0, hitY),
          Offset(size.width, hitY),
          Paint()
            ..color = AppColors.cyan.withValues(alpha: 0.5)
            ..strokeWidth = 10
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
    c.drawLine(Offset(0, hitY), Offset(size.width, hitY),
        Paint()..color = AppColors.cyan..strokeWidth = 3);

    for (int i = 0; i < laneCount; i++) {
      final cx = (i + 0.5) * laneW;
      final col = AppColors.lanes[i % AppColors.lanes.length];
      // recency of last hit on this lane → burst + pulse
      final flash = laneFlash[i];
      double age = 999;
      if (flash != null) age = (now - flash).toDouble();
      final fresh = age >= 0 && age < 220;
      final pop = fresh ? (1 - age / 220) : 0.0;

      c.drawCircle(Offset(cx, hitY), laneW * 0.30 * (1 + 0.15 * pop),
          Paint()..color = col.withValues(alpha: 0.18 + 0.35 * pop));
      c.drawCircle(
          Offset(cx, hitY),
          laneW * 0.30 * (1 + 0.15 * pop),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 + 2 * pop
            ..color = col.withValues(alpha: 0.8));

      // expanding hit burst ring + spark when freshly hit
      if (fresh && !reduceEffects) {
        final r = laneW * (0.30 + 0.45 * (1 - pop));
        c.drawCircle(
            Offset(cx, hitY),
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5 * pop
              ..color = Colors.white.withValues(alpha: 0.7 * pop));
        c.drawCircle(Offset(cx, hitY), laneW * 0.12 * pop,
            Paint()..color = Colors.white.withValues(alpha: 0.8 * pop));
      }
    }
  }

  void _paintNote(Canvas c, Note n, double cx, double y, double laneW, double hitY, int now) {
    final w = laneW * 0.72;
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

    if (n.holding) return; // head already at the line; only body remains

    final h = laneW * 0.36;

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
          ..color = col.withValues(alpha: n.type == NoteType.fever || n.type == NoteType.golden ? 0.5 : 0.28)
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
