import 'package:flutter/material.dart';

/// Premium neon-cultural palette. Deep ink background, neon violet→pink→cyan
/// accents, warm gold for "golden"/reward moments. Tuned to feel modern-arcade
/// with an Indonesian dusk warmth — not childish, not generic.
class AppColors {
  static const ink = Color(0xFF0B0B18);
  static const ink2 = Color(0xFF14132A);
  static const surface = Color(0xFF1B1A33);
  static const glass = Color(0x22FFFFFF);
  static const glassBorder = Color(0x33FFFFFF);

  static const violet = Color(0xFF7C3AED);
  static const pink = Color(0xFFEC4899);
  static const cyan = Color(0xFF22D3EE);
  static const gold = Color(0xFFFBBF24);
  static const teal = Color(0xFF2DD4BF);
  static const danger = Color(0xFFFB7185);

  static const textHi = Color(0xFFF5F3FF);
  static const textLo = Color(0xFFA9A7C4);

  /// Lane accent colors (cycled for 4 / 5 lane modes).
  static const lanes = [violet, pink, cyan, teal, gold];

  static const brandGradient = LinearGradient(
    colors: [violet, pink, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const feverGradient = LinearGradient(
    colors: [gold, pink, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
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
      textTheme: base.textTheme.apply(fontFamily: font).copyWith(
            displaySmall: const TextStyle(
                fontFamily: font, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            headlineMedium: const TextStyle(
                fontFamily: font, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            titleLarge: const TextStyle(
                fontFamily: font, fontWeight: FontWeight.w700),
            bodyMedium: const TextStyle(
                fontFamily: font, color: AppColors.textHi),
            labelLarge: const TextStyle(
                fontFamily: font, fontWeight: FontWeight.w700),
          ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.pink,
        thumbColor: AppColors.cyan,
        inactiveTrackColor: AppColors.glassBorder,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.cyan : AppColors.textLo),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.violet : AppColors.surface),
      ),
      fontFamily: font,
    );
  }
}

/// A reusable full-screen background: deep gradient + soft radial neon glows +
/// faint diagonal "batik-grid" texture. Cheap to paint, used behind most screens.
class NeonBackground extends StatelessWidget {
  final Widget child;
  final bool dim;
  const NeonBackground({super.key, required this.child, this.dim = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.ink, AppColors.ink2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(top: -120, left: -80, child: _Glow(AppColors.violet, 320)),
          const Positioned(bottom: -140, right: -100, child: _Glow(AppColors.cyan, 360)),
          const Positioned(top: 220, right: -120, child: _Glow(AppColors.pink, 260)),
          Positioned.fill(child: CustomPaint(painter: _BatikGridPainter())),
          if (dim) const Positioned.fill(child: ColoredBox(color: Color(0x66000000))),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow(this.color, this.size);
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}

/// Subtle repeating diamond grid evoking batik/kawung geometry — kept very low
/// opacity so it reads as texture, not decoration.
class _BatikGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x0CFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const gap = 46.0;
    for (double y = -gap; y < size.height + gap; y += gap) {
      for (double x = -gap; x < size.width + gap; x += gap) {
        final path = Path()
          ..moveTo(x + gap / 2, y)
          ..lineTo(x + gap, y + gap / 2)
          ..lineTo(x + gap / 2, y + gap)
          ..lineTo(x, y + gap / 2)
          ..close();
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
