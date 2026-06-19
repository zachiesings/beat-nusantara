import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ============================================================================
/// DESIGN SYSTEM — "Batik Premium Nusantara"
/// Deep batik-night (warm indigo/aubergine) base, prada-gold hero accent, senja
/// terracotta + marun (maroon) + wedelan indigo + gamelan jade. Kawung-batik
/// background motif, gold glows. Premium & cute, but rooted in tradition —
/// not cyber-neon. Tokens here; components in lib/widgets/*.
/// ============================================================================

class AppColors {
  // base — "malam batik": warm deep indigo/aubergine, not cold black
  static const navy = Color(0xFF0E0A16);
  static const ink = Color(0xFF1A1126);
  static const ink2 = Color(0xFF2A1830);
  static const surface = Color(0xFF33203C);
  static const surfaceHi = Color(0xFF43294C);
  static const glass = Color(0x1FFFFFFF);
  static const glassHi = Color(0x33FFFFFF);
  static const glassBorder = Color(0x2EFFFFFF);

  // accents — batik / songket / gamelan palette
  static const gold = Color(0xFFF2B73C);   // prada gold (hero)
  static const goldLt = Color(0xFFFCD675);
  static const coral = Color(0xFFE8744C);  // senja terracotta
  static const maroon = Color(0xFFB23A4E); // marun batik
  static const pink = Color(0xFFE76A93);   // rose (softer)
  static const indigo = Color(0xFF5B4BC4); // wedelan indigo
  static const violet = Color(0xFF7E55C6);
  static const teal = Color(0xFF2FA987);   // gamelan jade
  static const mint = Color(0xFF74D8B0);
  static const cyan = Color(0xFF45C6D4);   // kingfisher (minor accent only)
  static const danger = Color(0xFFE0566C);

  static const textHi = Color(0xFFF7EFE2); // kuning gading / cream
  static const textLo = Color(0xFFC1B0B6); // warm taupe

  /// Lane accent colors (cycled for 4 / 5 lane modes) — spread hues, warm-led.
  static const lanes = [indigo, coral, gold, teal, pink];

  // Primary brand gradient = "senja emas" (golden dusk). Used on most CTAs.
  static const brandGradient = LinearGradient(
    colors: [gold, coral, maroon],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const feverGradient = LinearGradient(
    colors: [goldLt, gold, coral],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Color mood per library category — gamelan gold, koplo terracotta, chill
  /// jade, challenge marun. Genre identity in batik tones.
  static Color moodFor(String category) {
    switch (category) {
      case 'Koplo/Dangdut':
        return coral;
      case 'Lagu Daerah':
        return gold;
      case 'Lagu Anak':
        return mint;
      case 'Nusantara Beats':
        return gold;
      case 'Chill':
        return teal;
      case 'Challenge':
        return maroon;
      case 'Pop Indonesia':
        return pink;
      case 'EDM':
        return indigo;
      case 'Global Hits Inspired':
        return violet;
      default:
        return gold;
    }
  }

  /// A stable per-song accent (hash → palette) so cards get identity.
  static Color accentFor(String id) {
    const pal = [gold, coral, maroon, teal, indigo, pink, violet];
    var h = 0;
    for (final c in id.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return pal[h % pal.length];
  }
}

/// Reusable gradients with personality.
class AppGradients {
  // royal batik (indigo → marun → emas)
  static const aurora = LinearGradient(
      colors: [AppColors.indigo, AppColors.maroon, AppColors.gold],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  // songket gold-thread warmth
  static const candy = LinearGradient(
      colors: [AppColors.pink, AppColors.coral, AppColors.gold],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  // senja Nusantara (dusk)
  static const sunset = LinearGradient(
      colors: [AppColors.maroon, AppColors.coral, AppColors.gold],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  // gamelan water (jade)
  static const ocean = LinearGradient(
      colors: [AppColors.teal, AppColors.cyan, AppColors.mint],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const goldRush = LinearGradient(
      colors: [AppColors.goldLt, AppColors.coral],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  // wedelan indigo dream
  static const dream = LinearGradient(
      colors: [AppColors.indigo, AppColors.violet, AppColors.pink],
      begin: Alignment.topLeft, end: Alignment.bottomRight);

  /// Each library category gets its own batik identity.
  static LinearGradient forCategory(String c) {
    switch (c) {
      case 'Untuk Kamu':
        return aurora;
      case 'Lagu Daerah':
        return sunset;
      case 'Lagu Anak':
        return candy;
      case 'Pop Indonesia':
        return candy;
      case 'Koplo/Dangdut':
        return sunset;
      case 'Nusantara Beats':
        return const LinearGradient(
            colors: [AppColors.gold, AppColors.teal],
            begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'Global Hits Inspired':
        return dream;
      case 'EDM':
        return const LinearGradient(
            colors: [AppColors.indigo, AppColors.cyan],
            begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'Chill':
        return const LinearGradient(
            colors: [AppColors.teal, AppColors.mint],
            begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'Challenge':
        return const LinearGradient(
            colors: [AppColors.maroon, AppColors.gold],
            begin: Alignment.topLeft, end: Alignment.bottomRight);
      default:
        return AppColors.brandGradient;
    }
  }

  /// Gradient from a single accent (for per-song cards / buttons).
  static LinearGradient from(Color c) => LinearGradient(
        colors: [Color.lerp(c, Colors.white, 0.18)!, c, Color.lerp(c, AppColors.violet, 0.35)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class AppRadius {
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 32.0;
  static const xl = 40.0;
  static const pill = 999.0;
}

class AppDur {
  static const instant = Duration(milliseconds: 90); // press-down
  static const xfast = Duration(milliseconds: 120); // press release / pop
  static const fast = Duration(milliseconds: 200); // chips, toggles, tabs
  static const med = Duration(milliseconds: 360); // page / view changes
  static const slow = Duration(milliseconds: 650); // reveals
  static const celebrate = Duration(milliseconds: 2600); // one-shot confetti
}

/// Curve vocabulary — the "voice" of every motion. Pick by intent.
class AppCurves {
  static const snappy = Curves.easeOutCubic; // default for almost everything
  static const bouncy = Curves.easeOutBack; // selection pops (chips/cards/stickers)
  static const gentle = Curves.easeInOut; // breathing / floating loops
  static const overshoot = Curves.elasticOut; // BIG rewards only (grade reveal) — rare
  static const press = Curves.easeOut; // button squish in/out
}

class AppShadows {
  /// Colored outer glow — the signature "juicy" depth.
  static List<BoxShadow> glow(Color c, {double blur = 28, double y = 12, double a = 0.45}) =>
      [BoxShadow(color: c.withValues(alpha: a), blurRadius: blur, offset: Offset(0, y))];

  static List<BoxShadow> soft = const [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12)),
  ];
}

/// Expressive type scale.
class AppText {
  static const _f = 'Jakarta';
  static const display =
      TextStyle(fontFamily: _f, fontWeight: FontWeight.w800, fontSize: 34, letterSpacing: -1, height: 1.05);
  static const title =
      TextStyle(fontFamily: _f, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.4);
  static const heading =
      TextStyle(fontFamily: _f, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.2);
  static const body = TextStyle(fontFamily: _f, fontWeight: FontWeight.w500, fontSize: 14, height: 1.4);
  static const label =
      TextStyle(fontFamily: _f, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.3);
  static const micro = TextStyle(fontFamily: _f, fontWeight: FontWeight.w600, fontSize: 10.5, color: AppColors.textLo);
}

class AppTheme {
  static ThemeData dark() {
    const font = 'Jakarta';
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ink,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.violet,
        secondary: AppColors.cyan,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: base.textTheme.apply(fontFamily: font, bodyColor: AppColors.textHi).copyWith(
            displaySmall: AppText.display,
            headlineMedium: AppText.title,
            titleLarge: AppText.heading,
            bodyMedium: AppText.body,
            labelLarge: AppText.label,
          ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.pink,
        thumbColor: AppColors.cyan,
        inactiveTrackColor: AppColors.glassBorder,
        overlayColor: Color(0x333DE7FF),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.textLo),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.violet : AppColors.surfaceHi),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

/// Batik motifs — each screen can wear a different traditional pattern.
enum BatikMotif { kawung, parang, ceplok, truntum, megaMendung }

/// A living background: warm batik-night gradient + drifting gold glows + a
/// detailed, per-screen batik motif (static & cached). One controller.
class NeonBackground extends StatefulWidget {
  final Widget child;
  final bool dim;
  final BatikMotif motif;
  const NeonBackground({super.key, required this.child, this.dim = false, this.motif = BatikMotif.kawung});

  @override
  State<NeonBackground> createState() => _NeonBackgroundState();
}

class _NeonBackgroundState extends State<NeonBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.ink2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // animated warm glows (cheap, redrawn each frame)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => CustomPaint(painter: _GlowPainter(_c.value)),
              ),
            ),
          ),
          // detailed batik motif (static → painted once & cached, so the rich
          // kawung/ceplok/isen detail costs nothing per frame)
          Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _BatikPainter(widget.motif)))),
          if (widget.dim) const Positioned.fill(child: ColoredBox(color: Color(0x73000000))),
          widget.child,
        ],
      ),
    );
  }
}

/// Animated warm glows + drifting prada-gold specks (cheap; redrawn each frame).
class _GlowPainter extends CustomPainter {
  final double t;
  _GlowPainter(this.t);

  static const _blobs = [
    (AppColors.gold, 0.16, 0.10, 360.0, 0.0),
    (AppColors.maroon, 0.90, 0.86, 380.0, 0.5),
    (AppColors.indigo, 0.92, 0.16, 300.0, 0.25),
    (AppColors.teal, 0.08, 0.72, 280.0, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _blobs) {
      final phase = (t + b.$5) * 2 * math.pi;
      final cx = b.$2 * size.width + math.sin(phase) * 24;
      final cy = b.$3 * size.height + math.cos(phase) * 24;
      final r = b.$4;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            b.$1.withValues(alpha: 0.26),
            b.$1.withValues(alpha: 0.0),
          ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }
    final spark = Paint();
    for (int i = 0; i < 12; i++) {
      final seed = i * 0.137;
      final x = ((seed + 0.05) % 1.0) * size.width;
      final prog = (t * (0.4 + seed) + seed) % 1.0;
      final y = size.height * (1.05 - prog);
      final a = math.sin(prog * math.pi) * 0.20;
      final rad = 1.6 + (i % 3);
      spark.color = (i.isEven ? AppColors.gold : AppColors.goldLt).withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), rad, spark);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.t != t;
}

/// Detailed batik motifs, one per screen. Static & cached, so the hand-drawn
/// density is essentially free per frame.
class _BatikPainter extends CustomPainter {
  final BatikMotif motif;
  const _BatikPainter(this.motif);

  Paint _stroke(double a, double w) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..color = AppColors.gold.withValues(alpha: a);
  Paint _fill(double a) => Paint()..color = AppColors.gold.withValues(alpha: a);

  @override
  void paint(Canvas canvas, Size size) {
    switch (motif) {
      case BatikMotif.kawung:
        _kawung(canvas, size);
      case BatikMotif.parang:
        _parang(canvas, size);
      case BatikMotif.ceplok:
        _ceplok(canvas, size);
      case BatikMotif.truntum:
        _truntum(canvas, size);
      case BatikMotif.megaMendung:
        _megaMendung(canvas, size);
    }
  }

  // KAWUNG — four diagonal petals in a ceplok ring + center jewel + isen cecek.
  void _kawung(Canvas c, Size size) {
    final petal = _stroke(0.10, 1.1), faint = _stroke(0.055, 0.9);
    final jewel = _fill(0.09);
    final cecekP = Paint()..color = AppColors.goldLt.withValues(alpha: 0.06);
    const gap = 64.0, r = gap * 0.5;
    for (double y = -gap; y < size.height + gap; y += gap) {
      for (double x = -gap; x < size.width + gap; x += gap) {
        final center = Offset(x + gap / 2, y + gap / 2);
        c.drawCircle(center, r * 0.94, faint);
        for (int k = 0; k < 4; k++) {
          final ang = math.pi / 4 + k * math.pi / 2;
          final oc = center + Offset(math.cos(ang), math.sin(ang)) * (r * 0.46);
          c.save();
          c.translate(oc.dx, oc.dy);
          c.rotate(ang);
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 1.02, height: r * 0.5), petal);
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 0.62, height: r * 0.28), faint);
          c.restore();
        }
        c.drawCircle(center, 2.4, jewel);
        for (int k = 0; k < 4; k++) {
          final ang = k * math.pi / 2;
          c.drawCircle(center + Offset(math.cos(ang), math.sin(ang)) * r, 1.3, cecekP);
        }
      }
    }
  }

  // PARANG — diagonal flowing "lereng" rows with mlinjon diamonds.
  void _parang(Canvas c, Size size) {
    final stroke = _stroke(0.09, 1.3), faint = _stroke(0.05, 0.9);
    c.save();
    c.translate(size.width / 2, size.height / 2);
    c.rotate(-math.pi / 4);
    final diag = math.sqrt(size.width * size.width + size.height * size.height);
    const gap = 46.0;
    for (double row = -diag; row < diag; row += gap) {
      final path = Path()..moveTo(-diag, row);
      for (double x = -diag; x < diag; x += 24) {
        path.quadraticBezierTo(x + 12, row + 11, x + 24, row);
      }
      c.drawPath(path, stroke);
      for (double x = -diag; x < diag; x += gap) {
        c.drawPath(
          Path()
            ..moveTo(x, row + gap / 2)
            ..lineTo(x + 5, row + gap / 2 - 5)
            ..lineTo(x + 10, row + gap / 2)
            ..lineTo(x + 5, row + gap / 2 + 5)
            ..close(),
          faint,
        );
      }
    }
    c.restore();
  }

  // CEPLOK — grid of geometric medallions (rings + inscribed diamond + petals).
  void _ceplok(Canvas c, Size size) {
    final stroke = _stroke(0.09, 1.1), faint = _stroke(0.05, 0.9), jewel = _fill(0.08);
    const gap = 60.0, r = gap * 0.5;
    for (double y = -gap; y < size.height + gap; y += gap) {
      for (double x = -gap; x < size.width + gap; x += gap) {
        final ct = Offset(x + gap / 2, y + gap / 2);
        c.drawCircle(ct, r * 0.9, stroke);
        c.drawCircle(ct, r * 0.55, faint);
        c.drawPath(
          Path()
            ..moveTo(ct.dx, ct.dy - r * 0.9)
            ..lineTo(ct.dx + r * 0.9, ct.dy)
            ..lineTo(ct.dx, ct.dy + r * 0.9)
            ..lineTo(ct.dx - r * 0.9, ct.dy)
            ..close(),
          faint,
        );
        for (int k = 0; k < 4; k++) {
          final ang = math.pi / 4 + k * math.pi / 2;
          c.drawCircle(ct + Offset(math.cos(ang), math.sin(ang)) * (r * 0.66), 2, jewel);
        }
        c.drawCircle(ct, 2.4, jewel);
      }
    }
  }

  // TRUNTUM — a field of small eight-point stars / flowers (celebratory).
  void _truntum(Canvas c, Size size) {
    final stroke = _stroke(0.08, 1.0), jewel = _fill(0.09);
    const gap = 44.0;
    var rowi = 0;
    for (double y = -gap; y < size.height + gap; y += gap, rowi++) {
      final off = rowi.isEven ? 0.0 : gap / 2;
      for (double x = -gap; x < size.width + gap; x += gap) {
        final cx = x + off, cy = y;
        const rr = 7.0, d = rr * 0.7;
        c.drawLine(Offset(cx - rr, cy), Offset(cx + rr, cy), stroke);
        c.drawLine(Offset(cx, cy - rr), Offset(cx, cy + rr), stroke);
        c.drawLine(Offset(cx - d, cy - d), Offset(cx + d, cy + d), stroke);
        c.drawLine(Offset(cx - d, cy + d), Offset(cx + d, cy - d), stroke);
        c.drawCircle(Offset(cx, cy), 1.6, jewel);
      }
    }
  }

  // MEGA MENDUNG — rows of nested cloud scallops (Cirebon).
  void _megaMendung(Canvas c, Size size) {
    final stroke = _stroke(0.085, 1.3), faint = _stroke(0.05, 1.0);
    const gap = 56.0, bump = 28.0;
    for (double y = 0; y < size.height + gap; y += gap) {
      for (int layer = 0; layer < 3; layer++) {
        final yy = y + layer * 4.5;
        final p = layer == 0 ? stroke : faint;
        final path = Path()..moveTo(-bump, yy);
        for (double x = -bump; x < size.width + bump; x += bump) {
          path.arcToPoint(Offset(x + bump, yy), radius: const Radius.circular(bump / 2), clockwise: false);
        }
        c.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BatikPainter old) => old.motif != motif;
}
