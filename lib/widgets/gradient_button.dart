import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/haptics.dart';

/// Chunky "candy/clay" CTA: a 3D bottom rim that the button physically presses
/// into, a glossy top sheen, a moving shimmer, and a breathing glow. This is the
/// single biggest game-feel signal — every primary action feels squishy & alive.
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
    this.height = 56,
    this.pulse = true,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  static const _rim = 7.0;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;
    final colors = (widget.gradient is LinearGradient)
        ? (widget.gradient as LinearGradient).colors
        : const [AppColors.violet, AppColors.pink];
    final glow = colors.first;
    final rimColor = Color.lerp(colors.last, Colors.black, 0.4)!;

    return GestureDetector(
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled
          ? () {
              Haptics.medium();
              widget.onTap!();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: SizedBox(
          height: widget.height + _rim,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final pulse = widget.pulse && enabled ? (_c.value * 2 - 1).abs() : 0.4;
              return AnimatedContainer(
                duration: AppDur.xfast,
                curve: Curves.easeOut,
                height: widget.height,
                margin: EdgeInsets.only(top: _down ? _rim - 2 : 0),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    // chunky rim (the "candy" base it presses into)
                    BoxShadow(color: rimColor, offset: Offset(0, _down ? 2 : _rim), blurRadius: 0),
                    // breathing glow
                    ...AppShadows.glow(glow, blur: 14 + 16 * pulse, y: 7, a: 0.5),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // glossy top sheen
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: widget.height * 0.42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0.0)],
                            ),
                          ),
                        ),
                      ),
                      // shimmer sweep
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment(-1.8 + 3.6 * _c.value, 0),
                          widthFactor: 0.3,
                          child: Transform.rotate(
                            angle: 0.4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: enabled ? 0.35 : 0.0),
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
                            Icon(widget.icon, color: Colors.white, size: 23),
                            const SizedBox(width: 9),
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
