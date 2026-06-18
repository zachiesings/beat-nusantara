import 'package:flutter/material.dart';
import '../app/theme.dart';

/// "Gunungan" / Kayon — the wayang tree-of-life. A gold leaf-flame silhouette
/// with an ornamented interior (kayon tree + a play glyph tying it to the app).
/// Original stylised art — no traced/trademarked source.
class Gunungan extends StatelessWidget {
  final double size;
  const Gunungan({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size * 1.4,
        child: CustomPaint(painter: _GununganPainter()),
      );
}

class _GununganPainter extends CustomPainter {
  Path _kayon(Size s) {
    final w = s.width, h = s.height, cx = w / 2;
    return Path()
      ..moveTo(cx, h)
      ..cubicTo(cx + w * 0.52, h * 0.86, cx + w * 0.55, h * 0.46, cx + w * 0.22, h * 0.17)
      ..cubicTo(cx + w * 0.15, h * 0.10, cx + w * 0.05, h * 0.05, cx, 0)
      ..cubicTo(cx - w * 0.05, h * 0.05, cx - w * 0.15, h * 0.10, cx - w * 0.22, h * 0.17)
      ..cubicTo(cx - w * 0.55, h * 0.46, cx - w * 0.52, h * 0.86, cx, h)
      ..close();
  }

  void _scaled(Canvas c, Size size, Path p, Paint paint, double s) {
    final center = Offset(size.width / 2, size.height / 2);
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(s);
    c.translate(-center.dx, -center.dy);
    c.drawPath(p, paint);
    c.restore();
  }

  @override
  void paint(Canvas c, Size size) {
    final path = _kayon(size);
    final rect = Offset.zero & size;
    final w = size.width, h = size.height, cx = w / 2;

    // outer glow
    _scaled(c, size, path,
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
        1.0);
    // gold body
    _scaled(
        c,
        size,
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.goldLt, AppColors.gold, AppColors.coral],
          ).createShader(rect),
        1.0);
    // inner dark frame (gives a gold border)
    _scaled(c, size, path, Paint()..color = AppColors.ink, 0.82);
    // outlines
    _scaled(c, size, path,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = AppColors.goldLt, 1.0);
    _scaled(
        c,
        size,
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = AppColors.gold.withValues(alpha: 0.8),
        0.82);

    // ---- interior ornament ----
    final fill = Paint()..color = AppColors.gold;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.goldLt;

    // kayon trunk + symmetric branches
    c.drawLine(Offset(cx, h * 0.80), Offset(cx, h * 0.40), stroke);
    for (final yy in const [0.62, 0.54, 0.47]) {
      final y = h * yy;
      c.drawLine(Offset(cx, y), Offset(cx - w * 0.13, y - h * 0.045), stroke);
      c.drawLine(Offset(cx, y), Offset(cx + w * 0.13, y - h * 0.045), stroke);
    }
    // leaf jewels
    for (final p in [
      Offset(cx, h * 0.38),
      Offset(cx - w * 0.14, h * 0.49),
      Offset(cx + w * 0.14, h * 0.49),
    ]) {
      c.drawCircle(p, 3.2, fill);
    }
    // play glyph (rhythm-app identity) low-centre
    final tri = Path()
      ..moveTo(cx - w * 0.075, h * 0.66)
      ..lineTo(cx + w * 0.11, h * 0.735)
      ..lineTo(cx - w * 0.075, h * 0.81)
      ..close();
    c.drawPath(tri, fill);
    // a small "gapura" base
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h * 0.92), width: w * 0.34, height: h * 0.05),
          const Radius.circular(3)),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _GununganPainter old) => false;
}
