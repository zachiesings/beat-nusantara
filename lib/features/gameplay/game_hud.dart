import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/mascot.dart';

/// The in-game HUD, extracted as a pure widget so BOTH the live gameplay screen
/// and the deterministic screenshot route render the *same* component. Takes
/// already-computed values (no engine dependency) → trivially previewable.
class GameHud extends StatelessWidget {
  final String title;
  final String difficulty;
  final String mode;
  final int score;
  final double accuracy;
  final int combo;
  final double hp; // 0..1
  final double fever; // 0..1
  final bool feverActive;
  final double progress; // 0..1
  final VoidCallback? onPause;

  const GameHud({
    super.key,
    required this.title,
    required this.difficulty,
    required this.mode,
    required this.score,
    required this.accuracy,
    required this.combo,
    required this.hp,
    required this.fever,
    required this.feverActive,
    required this.progress,
    this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                  icon: const Icon(Icons.pause_circle, size: 30, color: AppColors.textHi),
                  onPressed: onPause),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('$difficulty • $mode',
                        style: const TextStyle(color: AppColors.textLo, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$score',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.textHi)),
                  Text('${accuracy.toStringAsFixed(1)}%',
                      style: const TextStyle(color: AppColors.textLo, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 6),
              // Melodi cheers you on — lights up (cheer) during FEVER
              Mascot(
                size: 44,
                mood: feverActive ? Mood.cheer : Mood.happy,
                color: feverActive ? AppColors.gold : AppColors.cyan,
                arms: false,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _bar(progress, AppColors.cyan, height: 4),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('COMBO', style: TextStyle(fontSize: 9, color: AppColors.textLo)),
                  ComboCounter(value: combo),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(child: _hpBar(hp)),
            ],
          ),
          const SizedBox(height: 6),
          _feverBar(),
        ],
      ),
    );
  }

  Widget _hpBar(double v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HP', style: TextStyle(fontSize: 9, color: AppColors.textLo)),
          const SizedBox(height: 2),
          _bar(v, v > 0.3 ? AppColors.teal : AppColors.danger, height: 8),
        ],
      );

  Widget _feverBar() {
    return Row(children: [
      Icon(Icons.local_fire_department,
          size: 18, color: feverActive ? AppColors.gold : AppColors.textLo),
      const SizedBox(width: 6),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(children: [
            Container(height: 8, color: AppColors.glass),
            FractionallySizedBox(
              widthFactor: (feverActive ? 1.0 : fever).clamp(0.0, 1.0).toDouble(),
              child: Container(
                height: 8,
                decoration: const BoxDecoration(gradient: AppColors.feverGradient),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 6),
      Text(feverActive ? 'FEVER ×2!' : '',
          style: const TextStyle(
              color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 11)),
    ]);
  }

  Widget _bar(double v, Color color, {double height = 6}) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Stack(children: [
          Container(height: height, color: AppColors.glass),
          FractionallySizedBox(
            widthFactor: v.clamp(0.0, 1.0).toDouble(),
            child: Container(height: height, color: color),
          ),
        ]),
      );
}

/// Combo number that "punches" (scale pop) every time it increases — the most
/// satisfying micro-reward in a rhythm game.
class ComboCounter extends StatefulWidget {
  final int value;
  const ComboCounter({super.key, required this.value});
  @override
  State<ComboCounter> createState() => _ComboCounterState();
}

class _ComboCounterState extends State<ComboCounter> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220), value: 1);

  @override
  void didUpdateWidget(ComboCounter old) {
    super.didUpdateWidget(old);
    if (widget.value > old.value) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final pop = 1 + 0.45 * (1 - Curves.easeOut.transform(_c.value));
        return Transform.scale(scale: pop, alignment: Alignment.centerLeft, child: child);
      },
      child: Text('${widget.value}',
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.pink,
              shadows: [Shadow(color: AppColors.pink, blurRadius: 10)])),
    );
  }
}

