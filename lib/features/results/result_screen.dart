import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../game/models/song.dart';
import '../../game/scoring/judgment.dart';
import '../../game/scoring/score_engine.dart';
import '../../services/ads/ads_service.dart';
import '../../state/game_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/reward_ad_sheet.dart';

class ResultScreen extends StatefulWidget {
  final Song song;
  final String difficulty;
  final ResultSummary result;
  const ResultScreen({
    super.key,
    required this.song,
    required this.difficulty,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
        ..forward();
  bool _bonusClaimed = false;

  ResultSummary get r => widget.result;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _claimBonus() async {
    final granted = await showRewardAdSheet(
      context,
      kind: RewardKind.bonusCoins,
      title: 'Gandakan koin?',
      reward: '+${r.coins} koin bonus (total jadi 2×)',
    );
    if (!mounted) return;
    if (granted) {
      context.read<GameState>().addCoins(r.coins);
      setState(() => _bonusClaimed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleared = r.cleared;
    return Scaffold(
      body: NeonBackground(
        dim: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(cleared ? 'LAGU SELESAI' : 'GAGAL',
                    style: TextStyle(
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                        color: cleared ? AppColors.cyan : AppColors.danger)),
                const SizedBox(height: 4),
                Text(widget.song.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text('${widget.difficulty}  •  ${widget.song.artistDisplayName}',
                    style: const TextStyle(color: AppColors.textLo)),
                const SizedBox(height: 16),
                _gradeReveal(),
                const SizedBox(height: 16),
                _scoreBlock(),
                const SizedBox(height: 14),
                _judgeBreakdown(),
                const SizedBox(height: 14),
                _rewards(),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Main lagi',
                  icon: Icons.refresh,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Selesai', style: TextStyle(color: AppColors.textLo)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradeReveal() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
      child: Container(
        width: 140,
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [r.grade.color.withValues(alpha: 0.4), Colors.transparent]),
          border: Border.all(color: r.grade.color, width: 3),
        ),
        child: Text(r.grade.label,
            style: TextStyle(
                fontSize: 56, fontWeight: FontWeight.w800, color: r.grade.color)),
      ),
    );
  }

  Widget _scoreBlock() {
    return Column(
      children: [
        Text('${r.score}',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
        const Text('SKOR', style: TextStyle(color: AppColors.textLo, letterSpacing: 3)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _stat('Akurasi', '${r.accuracy.toStringAsFixed(2)}%'),
            _stat('Combo Maks', '${r.maxCombo}'),
            _stat('Full Combo', r.fullCombo ? 'YA' : '—',
                color: r.fullCombo ? AppColors.gold : null),
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, String value, {Color? color}) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color ?? AppColors.textHi)),
          Text(label, style: const TextStyle(color: AppColors.textLo, fontSize: 11)),
        ],
      );

  Widget _judgeBreakdown() {
    final rows = [
      ('Perfect', r.perfect, AppColors.gold),
      ('Hebat', r.great, AppColors.cyan),
      ('Oke', r.good, AppColors.teal),
      ('Lewat', r.miss, AppColors.danger),
    ];
    return GlassPanel(
      child: Column(
        children: rows.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${e.$2}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _rewards() {
    return GlassPanel(
      child: Column(children: [
        Row(children: [
          const Icon(Icons.monetization_on, color: AppColors.gold),
          const SizedBox(width: 10),
          Text('+${r.coins} koin', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 16),
          const Icon(Icons.bolt, color: AppColors.violet),
          const SizedBox(width: 6),
          Text('+${r.xp} XP', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        if (!_bonusClaimed)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              side: const BorderSide(color: AppColors.gold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.slow_motion_video, color: AppColors.gold),
            label: const Text('Gandakan koin (iklan opsional)',
                style: TextStyle(color: AppColors.gold)),
            onPressed: _claimBonus,
          )
        else
          const Text('Koin bonus diterima! 🎉',
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
