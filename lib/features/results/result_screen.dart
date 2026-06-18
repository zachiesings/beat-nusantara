import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/haptics.dart';
import '../../game/models/song.dart';
import '../../game/scoring/judgment.dart';
import '../../game/scoring/score_engine.dart';
import '../../services/ads/ads_service.dart';
import '../../state/game_state.dart';
import '../../widgets/count_up.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mascot.dart';
import '../../widgets/pulse.dart';
import '../../widgets/reward_ad_sheet.dart';
import '../../widgets/shapes.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/sparkle.dart';
import '../../widgets/stat_ring.dart';

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
      AnimationController(vsync: this, duration: AppDur.slow)..forward();
  bool _bonusClaimed = false;

  ResultSummary get r => widget.result;

  @override
  void initState() {
    super.initState();
    // celebratory haptic on a clean clear (see docs/MOTION_LANGUAGE.md)
    if (widget.result.cleared) Haptics.success();
  }

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

  (String, Mood) _verdict() {
    if (!r.cleared) return ('Yah, belum berhasil… coba lagi ya! 💪', Mood.sleepy);
    if (r.fullCombo) return ('Keren banget! Full Combo! 🎉', Mood.cheer);
    if (r.accuracy >= 95) return ('Dikit lagi sempurna! ✨', Mood.cheer);
    if (r.miss <= 3) return ('Ayo kejar Full Combo! 🔥', Mood.wink);
    return ('Keren, ritmemu makin rapi! 🎶', Mood.happy);
  }

  @override
  Widget build(BuildContext context) {
    final (verdict, mood) = _verdict();
    final celebrate = r.cleared && r.accuracy >= 85;
    return Scaffold(
      body: Stack(
        children: [
          NeonBackground(
            dim: true,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                child: Column(
                  children: [
                    Text(r.cleared ? 'LAGU SELESAI' : 'COBA LAGI',
                        style: TextStyle(
                            letterSpacing: 5,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: r.cleared ? AppColors.cyan : AppColors.danger)),
                    const SizedBox(height: 4),
                    Text(widget.song.title, style: AppText.title, textAlign: TextAlign.center),
                    Text('${widget.difficulty}  •  ${widget.song.artistDisplayName}',
                        style: const TextStyle(color: AppColors.textLo)),
                    const SizedBox(height: 14),
                    _gradeReveal(),
                    const SizedBox(height: 14),
                    MascotBubble(text: verdict, mood: mood, color: r.grade.color, mascotSize: 58),
                    const SizedBox(height: 16),
                    _scoreBlock(),
                    const SizedBox(height: 16),
                    _statsRow(),
                    const SizedBox(height: 14),
                    _breakdown(),
                    const SizedBox(height: 14),
                    _rewards(),
                    const SizedBox(height: 22),
                    GradientButton(
                      label: 'Main Lagi',
                      icon: Icons.refresh_rounded,
                      gradient: AppGradients.from(r.grade.color),
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      child: const Text('Kembali ke beranda', style: TextStyle(color: AppColors.textLo)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (celebrate) const Positioned.fill(child: CelebrationOverlay()),
        ],
      ),
    );
  }

  Widget _gradeReveal() {
    return SizedBox(
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: Twinkles(count: 12, color: r.grade.color)),
          PulseRings(color: r.grade.color, size: 168),
          if (r.fullCombo)
            const Positioned(
                bottom: -2,
                child: Sticker(text: 'FULL COMBO', icon: Icons.bolt_rounded, gradient: AppGradients.goldRush, angle: -0.06)),
          ScaleTransition(
            scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
            child: Container(
              width: 132,
              height: 132,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [r.grade.color.withValues(alpha: 0.45), Colors.transparent]),
                border: Border.all(color: r.grade.color, width: 3),
                boxShadow: AppShadows.glow(r.grade.color, blur: 36, y: 0, a: 0.6),
              ),
              child: Text(r.grade.label,
                  style: TextStyle(fontSize: 54, fontWeight: FontWeight.w800, color: r.grade.color)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBlock() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (rect) => AppGradients.candy.createShader(rect),
          child: CountUp(
            value: r.score,
            duration: const Duration(milliseconds: 1100),
            style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        const Text('SKOR', style: TextStyle(color: AppColors.textLo, letterSpacing: 3, fontSize: 11)),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StatRing(
            progress: r.accuracy / 100,
            value: '${r.accuracy.toStringAsFixed(1)}%',
            label: 'Akurasi',
            color: AppColors.cyan),
        _miniStat('${r.maxCombo}', 'Combo Maks', AppColors.pink),
        _miniStat(r.fullCombo ? 'FC' : '—', 'Full Combo', r.fullCombo ? AppColors.gold : AppColors.textLo),
      ],
    );
  }

  Widget _miniStat(String value, String label, Color color) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 92,
            child: Center(
              child: Text(value,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.textLo, fontSize: 10)),
        ],
      );

  Widget _breakdown() {
    final rows = [
      ('Perfect', r.perfect, AppColors.gold),
      ('Hebat', r.great, AppColors.cyan),
      ('Oke', r.good, AppColors.teal),
      ('Lewat', r.miss, AppColors.danger),
    ];
    return SoftCard(
      accent: AppColors.violet,
      glowStrength: 0.2,
      child: Column(
        children: rows.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle, boxShadow: AppShadows.glow(e.$3, blur: 8, y: 0, a: 0.7))),
              const SizedBox(width: 12),
              Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${e.$2}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _rewards() {
    return SoftCard(
      accent: AppColors.gold,
      glowStrength: 0.3,
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.monetization_on, color: AppColors.gold),
          const SizedBox(width: 8),
          CountUp(
              value: r.coins,
              prefix: '+',
              suffix: ' koin',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(width: 18),
          const Icon(Icons.bolt_rounded, color: AppColors.violet),
          const SizedBox(width: 6),
          Text('+${r.xp} XP', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        if (!_bonusClaimed)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.gold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            icon: const Icon(Icons.slow_motion_video_rounded, color: AppColors.gold),
            label: const Text('Gandakan koin (iklan opsional)', style: TextStyle(color: AppColors.gold)),
            onPressed: _claimBonus,
          )
        else
          const Text('Koin bonus diterima! 🎉',
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
