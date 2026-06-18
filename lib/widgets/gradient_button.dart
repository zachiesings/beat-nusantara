import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/haptics.dart';

/// Juicy glowing pill button: continuous soft glow pulse, a slow shimmer sweep,
/// and a springy press. The unmissable primary CTA.
class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Gradient gradient;
  final bool enabled;
  final double height;
  final bool pulse;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.gradient = AppColors.brandGradient,
    this.enabled = true,
    this.height = 58,
    this.pulse = true,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;
    final glowColor = (widget.gradient is LinearGradient)
        ? (widget.gradient as LinearGradient).colors.first
        : AppColors.violet;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _scale = 0.95) : null,
      onTapUp: enabled ? (_) => setState(() => _scale = 1) : null,
      onTapCancel: enabled ? () => setState(() => _scale = 1) : null,
      onTap: enabled
          ? () {
              Haptics.medium();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _scale,
        duration: AppDur.xfast,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final pulse = widget.pulse && enabled
                  ? 0.5 + 0.5 * (1 + (_c.value * 2 - 1).abs()) / 2
                  : 0.5;
              return Container(
                height: widget.height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.glow(glowColor, blur: 18 + 16 * pulse, y: 8, a: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // shimmer sweep
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment(-1.6 + 3.2 * _c.value, 0),
                          widthFactor: 0.35,
                          child: Transform.rotate(
                            angle: 0.4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: enabled ? 0.30 : 0.0),
                                  Colors.white.withValues(alpha: 0.0),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                          ],
                          Text(widget.label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16.5,
                                  letterSpacing: 0.3)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
