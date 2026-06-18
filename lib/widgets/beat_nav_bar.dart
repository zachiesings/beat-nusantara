import 'dart:ui';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/haptics.dart';
import 'bouncy.dart';

/// Floating, glassy, game-style bottom navigation. The active tab blooms into a
/// glowing gradient pill with its label; inactive tabs are quiet icons. This is
/// the single biggest "this is an app/game, not a stack of pages" signal.
class BeatNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const BeatNavBar({super.key, required this.index, required this.onTap});

  static const _items = <(IconData, String, Color)>[
    (Icons.home_rounded, 'Home', AppColors.cyan),
    (Icons.library_music_rounded, 'Lagu', AppColors.pink),
    (Icons.card_giftcard_rounded, 'Hadiah', AppColors.gold),
    (Icons.person_rounded, 'Profil', AppColors.violet),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.glassBorder),
                boxShadow: AppShadows.glow(AppColors.violet, blur: 26, y: 10, a: 0.32),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int i = 0; i < _items.length; i++) _item(i),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final (icon, label, color) = _items[i];
    final active = i == index;
    return Bouncy(
      scale: 0.88,
      onTap: () {
        Haptics.select();
        onTap(i);
      },
      child: AnimatedContainer(
        duration: AppDur.fast,
        curve: AppCurves.bouncy,
        padding: EdgeInsets.symmetric(horizontal: active ? 16 : 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: active ? AppGradients.from(color) : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: active ? AppShadows.glow(color, blur: 16, y: 4, a: 0.55) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: active ? Colors.white : AppColors.textLo),
            if (active) ...[
              const SizedBox(width: 7),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
