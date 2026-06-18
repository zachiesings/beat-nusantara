import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Holographic foil sweep — a slow iridescent band drifting across whatever it
/// wraps. Makes covers & premium cards read as collectible trading cards.
class HoloSheen extends StatefulWidget {
  final Widget child;
  final double radius;
  final double intensity;
  const HoloSheen({super.key, required this.child, this.radius = 16, this.intensity = 0.5});

  @override
  State<HoloSheen> createState() => _HoloSheenState();
}

class _HoloSheenState extends State<HoloSheen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => FractionallySizedBox(
                  alignment: Alignment(-2.2 + 4.4 * _c.value, -1 + 2 * _c.value),
                  widthFactor: 0.6,
                  child: Transform.rotate(
                    angle: 0.55,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.cyan.withValues(alpha: 0.0),
                            AppColors.pink.withValues(alpha: 0.16 * widget.intensity),
                            AppColors.gold.withValues(alpha: 0.20 * widget.intensity),
                            AppColors.cyan.withValues(alpha: 0.16 * widget.intensity),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
