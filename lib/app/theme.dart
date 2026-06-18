import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ============================================================================
/// DESIGN SYSTEM — "Cute Premium Rhythm Arcade, rasa Nusantara"
/// Deep indigo/navy base, juicy neon accents (pink, cyan, gold, coral, mint),
/// big rounded shapes, colored glows, animated life. Tokens here; components in
/// lib/widgets/*.
/// ============================================================================

class AppColors {
  // base (deep, premium, a touch warmer/indigo than pure black)
  static const navy = Color(0xFF06061A);
  static const ink = Color(0xFF0B0A20);
  static const ink2 = Color(0xFF16133A);
  static const surface = Color(0xFF1E1B47);
  static const surfaceHi = Color(0xFF2A2560);
  static const glass = Color(0x1FFFFFFF);
  static const glassHi = Color(0x33FFFFFF);
  static const glassBorder = Color(0x2EFFFFFF);

  // accents (brighter + cuter than before)
  static const violet = Color(0xFF8B5CF6);
  static const indigo = Color(0xFF6366F1);
  static const pink = Color(0xFFFF5C9A);
  static const cyan = Color(0xFF3DE7FF);
  static const gold = Color(0xFFFFCB45);
  static const teal = Color(0xFF36E0B0);
  static const mint = Color(0xFF6BF2C9);
  static const coral = Color(0xFFFF7E67);
  static const danger = Color(0xFFFF6B81);

  static const textHi = Color(0xFFF6F3FF);
  static const textLo = Color(0xFFAEA9D6);

  /// Lane accent colors (cycled for 4 / 5 lane modes).
  static const lanes = [violet, pink, cyan, mint, gold];

  // Kept for backwards-compat with existing screens.
  static const brandGradient = LinearGradient(
    colors: [violet, pink, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const feverGradient = LinearGradient(
    colors: [gold, coral, pink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Color mood per library category — Koplo = warm coral/gold, Gamelan = teal,
  /// Chill = cyan/mint, Challenge = magenta-violet, etc. Gives the library genre
  /// identity instead of a uniform palette.
  static Color moodFor(String category) {
    switch (category) {
      case 'Koplo/Dangdut':
        return coral;
      case 'Nusantara Beats':
        return teal;
      case 'Chill':
        return cyan;
      case 'Challenge':
        return pink;
      case 'Pop Indonesia':
        return pink;
      case 'EDM':
        return indigo;
      case 'Global Hits Inspired':
        return violet;
      default:
        return cyan;
    }
  }

  /// A cute, stable per-song accent (hash → palette) so cards get identity.
  static Color accentFor(String id) {
    const pal = [pink, cyan, gold, mint, coral, violet, teal, indigo];
    var h = 0;
    for (final c in id.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return pal[h % pal.length];
  }
}

/// Reusable gradients with personality.
class AppGradients {
  static const aurora = LinearGradient(
      colors: [AppColors.violet, AppColors.indigo, AppColors.cyan],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const candy = LinearGradient(
      colors: [AppColors.pink, AppColors.coral, AppColors.gold],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const sunset = LinearGradient(
      colors: [AppColors.coral, AppColors.pink, AppColors.violet],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const ocean = LinearGradient(
      colors: [AppColors.cyan, AppColors.teal, AppColors.mint],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const goldRush = LinearGradient(
      colors: [AppColors.gold, AppColors.coral],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const dream = LinearGradient(
      colors: [AppColors.indigo, AppColors.violet, AppColors.pink],
      begin: Alignment.topLeft, end: Alignment.bottomRight);

  /// Each library category gets its own identity.
  static LinearGradient forCategory(String c) {
    switch (c) {
      case 'Untuk Kamu':
        return aurora;
      case 'Pop Indonesia':
        return candy;
      case 'Koplo/Dangdut':
        return sunset;
      case 'Nusantara Beats':
        return ocean;
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
        return goldRush;
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

/// A living background: deep gradient + slowly drifting neon blobs + faint
/// floating note sparks + low-opacity batik diamonds. One controller, cheap
/// CustomPaint — gives every screen motion language without per-screen work.
class NeonBackground extends StatefulWidget {
  final Widget child;
  final bool dim;
  const NeonBackground({super.key, required this.child, this.dim = false});

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
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => CustomPaint(painter: _LivingBgPainter(_c.value)),
              ),
            ),
          ),
          if (widget.dim) const Positioned.fill(child: ColoredBox(color: Color(0x73000000))),
          widget.child,
        ],
      ),
    );
  }
}

class _LivingBgPainter extends CustomPainter {
  final double t;
  _LivingBgPainter(this.t);

  static const _blobs = [
    (AppColors.violet, 0.18, 0.10, 360.0, 0.0),
    (AppColors.cyan, 0.88, 0.86, 380.0, 0.5),
    (AppColors.pink, 0.92, 0.18, 300.0, 0.25),
    (AppColors.mint, 0.10, 0.7, 280.0, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // drifting glows
    for (final b in _blobs) {
      final phase = (t + b.$5) * 2 * math.pi;
      final cx = b.$2 * size.width + math.sin(phase) * 26;
      final cy = b.$3 * size.height + math.cos(phase) * 26;
      final r = b.$4;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            b.$1.withValues(alpha: 0.34),
            b.$1.withValues(alpha: 0.0),
          ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }
    // diagonal rhythm streaks (energy + a touch of asymmetry)
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.42);
    canvas.rotate(-0.7);
    for (int i = 0; i < 5; i++) {
      final base = (i / 5 + t * 0.35) % 1.0;
      final x = (base * 2.0 - 1.0) * size.width;
      final col = AppColors.lanes[i % AppColors.lanes.length];
      canvas.drawRect(
        Rect.fromLTWH(x, -size.height, 3, size.height * 2),
        Paint()
          ..color = col.withValues(alpha: 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.restore();

    // batik diamond grid (very faint)
    final grid = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const gap = 50.0;
    for (double y = -gap; y < size.height + gap; y += gap) {
      for (double x = -gap; x < size.width + gap; x += gap) {
        final p = Path()
          ..moveTo(x + gap / 2, y)
          ..lineTo(x + gap, y + gap / 2)
          ..lineTo(x + gap / 2, y + gap)
          ..lineTo(x, y + gap / 2)
          ..close();
        canvas.drawPath(p, grid);
      }
    }
    // floating note sparks rising slowly
    final spark = Paint();
    for (int i = 0; i < 14; i++) {
      final seed = i * 0.137;
      final x = ((seed + 0.05) % 1.0) * size.width;
      final prog = (t * (0.4 + seed) + seed) % 1.0;
      final y = size.height * (1.05 - prog);
      final a = (math.sin(prog * math.pi)) * 0.22;
      final rad = 2.0 + (i % 3);
      spark.color = AppColors.lanes[i % 5].withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), rad, spark);
    }
  }

  @override
  bool shouldRepaint(covariant _LivingBgPainter old) => old.t != t;
}
