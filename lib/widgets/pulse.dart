import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Expanding concentric "rhythm pulse" rings — the heartbeat motif. Sits behind
/// hero emblems, the splash logo, and result celebrations.
class PulseRings extends StatefulWidget {
  final Color color;
  final double size;
  final int count;
  const PulseRings({super.key, this.color = AppColors.cyan, this.size = 160, this.count = 3});

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) =>
              CustomPaint(painter: _RingPainter(_c.value, widget.color, widget.count)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  final Color color;
  final int count;
  _RingPainter(this.t, this.color, this.count);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.width / 2;
    for (int i = 0; i < count; i++) {
      final p = (t + i / count) % 1.0;
      final r = maxR * (0.28 + 0.72 * p);
      final a = (1 - p) * 0.5;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = color.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.t != t;
}
