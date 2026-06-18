import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'bouncy.dart';

/// The workhorse panel: big rounded, layered, with a soft colored glow and a
/// subtle top sheen. Optional [gradient] for hero/featured cards, optional
/// [accent] for a tinted glow + border, optional [badge] sticker, [onTap] makes
/// it springy.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? accent;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Widget? badge;
  final double glowStrength;
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.lg,
    this.accent,
    this.gradient,
    this.onTap,
    this.badge,
    this.glowStrength = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    final a = accent ?? AppColors.violet;
    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? AppColors.surface.withValues(alpha: 0.62) : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent != null ? a.withValues(alpha: 0.55) : AppColors.glassBorder),
        boxShadow: AppShadows.glow(a, blur: 30, y: 14, a: glowStrength),
      ),
      child: child,
    );

    // top sheen for depth
    card = Stack(children: [
      card,
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: radius + 18,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ),
      ),
      if (badge != null) Positioned(top: -6, right: -4, child: badge!),
    ]);

    if (onTap != null) card = Bouncy(onTap: onTap, scale: 0.97, child: card);
    return card;
  }
}

/// A little floating sticker badge (e.g. "DEMO", "HOT", a grade).
class FloatingBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Gradient gradient;
  const FloatingBadge({super.key, required this.text, this.icon, this.gradient = AppGradients.candy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 9 : 11, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: AppShadows.glow((gradient as LinearGradient).colors.first, blur: 14, y: 4, a: 0.6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: Colors.white), const SizedBox(width: 4)],
        Text(text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10.5, letterSpacing: 0.4)),
      ]),
    );
  }
}
