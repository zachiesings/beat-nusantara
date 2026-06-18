import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/haptics.dart';

/// Smoothly animated selectable chip. Selected = gradient fill + glow + a tiny
/// pop; idle = soft glass. Used for categories, difficulties, filters.
class NeonChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Gradient gradient;
  const NeonChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.gradient = AppColors.brandGradient,
  });

  @override
  Widget build(BuildContext context) {
    final glow = (gradient is LinearGradient) ? (gradient as LinearGradient).colors.first : AppColors.violet;
    return GestureDetector(
      onTap: () {
        Haptics.select();
        onTap();
      },
      child: AnimatedScale(
        scale: selected ? 1.06 : 1.0,
        duration: AppDur.fast,
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: AppDur.fast,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? gradient : null,
            color: selected ? null : AppColors.glass,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: selected ? Colors.white.withValues(alpha: 0.4) : AppColors.glassBorder),
            boxShadow: selected ? AppShadows.glow(glow, blur: 16, y: 4, a: 0.5) : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: selected ? Colors.white : AppColors.textLo),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? Colors.white : AppColors.textLo)),
          ]),
        ),
      ),
    );
  }
}
