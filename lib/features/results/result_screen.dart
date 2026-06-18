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
  const ResultScreen({super.key, required this.song, required this.difficulty, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppDur.slow)..forward();
  bool _bonusClaimed = false;
  ResultSummary get r => widget.result;

  @override
  void initState() {
    super.initState();
    if (r.cleared) Haptics.success();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _claimBonus() async {
    final granted = await showRewardAdSheet(context,
        kind: RewardKind.bonusCoins, title: 'Gandakan koin?', reward: '+${r.coins} koin bonus (total jadi 2×)');
    if (!mounted) return;
    if (granted) {
      context.read<GameState>().addCoins(r.coins);
      setState(() => _bonusClaimed = true);
    }
  }

  (String, Mood) _verdict() {
    if (!r.cleared) return ('Pemanasan dulu, kita gas lagi! 💪', Mood.sleepy);
    switch (r.grade) {
      case Grade.sss:
        return ('Luar biasa, ritmemu sempurna! 🎉', Mood.cheer);
      case Grade.ss:
        return ('Keren banget! ✨', Mood.cheer);
      case Grade.s:
        return ('Mantap, tinggal sedikit lagi! 🔥', Mood.wink);
      case Grade.a:
      case Grade.b:
        return ('Bagus, ayo coba sekali lagi! 🎶', Mood.happy);
      default:
        return ('Pemanasan dulu, kita gas lagi! 💪', Mood.sleepy);
    }
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                child: Column(
                  children: [
                    Text(r.cleared ? 'LAGU SELESAI' : 'COBA LAGI',
                        style: TextStyle(
                            letterSpacing: 5,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: r.cleared ? AppColors.cyan : AppColors.danger)),
                    const SizedBox(height: 4),
                    Text(widget.song.title, style: AppText.title, textAlign: TextAlign.center),
                    Text('${widget.difficulty}  •  ${widget.song.artistDisplayName}',
                        style: const TextStyle(color: AppColors.textLo)),
                    const SizedBox(height: 10),
                    _gradeHero(),
                    const SizedBox(height: 6),
                    Text(verdict,
                        textAlign: TextAlign.center,
                        style: AppText.heading.copyWith(fontSize: 18, color: AppColors.textHi)),
                    const SizedBox(height: 6),
                    Mascot(size: 56, mood: mood, color: r.grade.color),
                    const SizedBox(height: 14),
                    _scoreBlock(),
                    const SizedBox(height: 16),
                    _statsRow(),
                    const SizedBox(height: 14),
                    _judgeChips(),
                    const SizedBox(height: 16),
                    _rewardCapsule(),
                    const SizedBox(height: 22),
                    _ctas(context),
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

  // -------- big shiny grade moment --------
  Widget _gradeHero() {
    final color = r.grade.color;
    return SizedBox(
      height: 196,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: Twinkles(count: 16, color: color)),
          PulseRings(color: color, size: 196, count: 3),
          // halo
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withValues(alpha: 0.35), Colors.transparent]),
            ),
          ),
          if (r.fullCombo)
            const Positioned(
                top: 6,
                child: Sticker(text: 'FULL COMBO', icon: Icons.bolt_rounded, gradient: AppGradients.goldRush, angle: -0.05)),
          ScaleTransition(
            scale: CurvedAnimation(parent: _c, curve: AppCurves.overshoot),
            child: Container(
              width: 138,
              height: 138,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [color.withValues(alpha: 0.5), AppColors.ink.withValues(alpha: 0.4)]),
                border: Border.all(color: color, width: 3.5),
                boxShadow: AppShadows.glow(color, blur: 44, y: 0, a: 0.7),
              ),
              child: ShaderMask(
                shaderCallback: (rect) =>
                    LinearGradient(colors: [Color.lerp(color, Colors.white, 0.6)!, color]).createShader(rect),
                child: Text(r.grade.label,
                    style: const TextStyle(fontSize: 58, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBlock() {
    return Column(
      children: [
        const Text('SKOR', style: TextStyle(color: AppColors.textLo, letterSpacing: 4, fontSize: 11)),
        ShaderMask(
          shaderCallback: (rect) => AppGradients.candy.createShader(rect),
          child: CountUp(
            value: r.score,
            duration: const Duration(milliseconds: 1200),
            style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1),
          ),
        ),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StatRing(progress: r.accuracy / 100, value: '${r.accuracy.toStringAsFixed(1)}%', label: 'Akurasi', color: AppColors.cyan),
        _statCapsule('${r.maxCombo}', 'Combo Maks', AppColors.pink, Icons.local_fire_department_rounded),
        _statCapsule(r.fullCombo ? 'YA' : '—', 'Full Combo', r.fullCombo ? AppColors.gold : AppColors.textLo, Icons.bolt_rounded),
      ],
    );
  }

  Widget _statCapsule(String value, String label, Color color, IconData icon) => Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: AppShadows.glow(color, blur: 14, y: 4, a: 0.25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(color: AppColors.textLo, fontSize: 9.5)),
          ],
        ),
      );

  // judgment as colorful chips, not a table
  Widget _judgeChips() {
    final rows = [
      ('Perfect', r.perfect, AppColors.gold),
      ('Hebat', r.great, AppColors.cyan),
      ('Oke', r.good, AppColors.teal),
      ('Lewat', r.miss, AppColors.danger),
    ];
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      alignment: WrapAlignment.center,
      children: rows.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: e.$3.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: e.$3.withValues(alpha: 0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle, boxShadow: AppShadows.glow(e.$3, blur: 6, y: 0, a: 0.8))),
            const SizedBox(width: 8),
            Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(width: 8),
            Text('${e.$2}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: e.$3)),
          ]),
        );
      }).toList(),
    );
  }

  // shiny reward capsule
  Widget _rewardCapsule() {
    return SoftCard(
      gradient: const LinearGradient(
        colors: [Color(0x33FFCB45), Color(0x22FF7E67)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accent: AppColors.gold,
      glowStrength: 0.35,
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          const SizedBox(height: 44, width: double.infinity, child: Twinkles(count: 8, color: AppColors.gold)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _rewardPill(Icons.monetization_on, '+${r.coins}', 'koin', AppColors.gold),
            const SizedBox(width: 14),
            _rewardPill(Icons.bolt_rounded, '+${r.xp}', 'XP', AppColors.violet),
          ]),
        ]),
        const SizedBox(height: 12),
        if (!_bonusClaimed)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              side: const BorderSide(color: AppColors.gold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            icon: const Icon(Icons.slow_motion_video_rounded, color: AppColors.gold),
            label: const Text('Tonton untuk bonus 2× (opsional)', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
            onPressed: _claimBonus,
          )
        else
          const Text('Koin bonus diterima! 🎉', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _rewardPill(IconData icon, String value, String unit, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: color)),
          const SizedBox(width: 3),
          Text(unit, style: const TextStyle(color: AppColors.textLo, fontSize: 11)),
        ]),
      );

  Widget _ctas(BuildContext context) {
    return Column(children: [
      GradientButton(
        label: 'Main Lagi',
        icon: Icons.refresh_rounded,
        gradient: AppGradients.from(r.grade.color),
        onTap: () => Navigator.pop(context),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.glassBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        icon: const Icon(Icons.library_music_rounded, color: AppColors.textHi),
        label: const Text('Lagu Lain', style: TextStyle(color: AppColors.textHi, fontWeight: FontWeight.w700)),
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
    ]);
  }
}
