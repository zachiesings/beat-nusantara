import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/haptics.dart';

/// Wrap anything to make it feel touchable: springs down on press, pops back,
/// fires a haptic. The single "highly touchable" primitive used everywhere.
class Bouncy extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  const Bouncy({super.key, required this.child, this.onTap, this.scale = 0.94, this.haptic = true});

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  bool _down = false;
  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) Haptics.light();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: AppDur.xfast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
