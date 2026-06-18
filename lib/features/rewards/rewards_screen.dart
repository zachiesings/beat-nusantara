import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/missions.dart';
import '../../services/ads/ads_service.dart';
import '../../state/game_state.dart';
import '../../widgets/bouncy.dart';
import '../../widgets/mascot.dart';
import '../../widgets/reward_ad_sheet.dart';
import '../../widgets/soft_card.dart';

class _Cosmetic {
  final String id;
  final String name;
  final String kind; // 'lane' or 'hit'
  final int coins; // 0 = free / ad-only
  final bool adOnly;
  final List<Color> colors;
  const _Cosmetic(this.id, this.name, this.kind, this.coins, this.adOnly, this.colors);
}

const _cosmetics = <_Cosmetic>[
  _Cosmetic('neon', 'Neon', 'lane', 0, false, [AppColors.violet, AppColors.cyan]),
  _Cosmetic('sunset', 'Senja', 'lane', 120, false, [AppColors.pink, AppColors.gold]),
  _Cosmetic('ocean', 'Samudra', 'lane', 180, false, [AppColors.cyan, AppColors.teal]),
  _Cosmetic('batik', 'Batik Emas', 'lane', 0, true, [AppColors.gold, AppColors.pink]),
  _Cosmetic('spark', 'Spark', 'hit', 0, false, [AppColors.cyan, AppColors.violet]),
  _Cosmetic('bloom', 'Bloom', 'hit', 100, false, [AppColors.pink, AppColors.violet]),
  _Cosmetic('star', 'Bintang', 'hit', 0, true, [AppColors.gold, AppColors.cyan]),
];

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final lanes = _cosmetics.where((c) => c.kind == 'lane').toList();
    final hits = _cosmetics.where((c) => c.kind == 'hit').toList();
    final w = (MediaQuery.of(context).size.width - 32 - 12) / 2;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Row(children: [
                Bouncy(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back_rounded))),
                Text('Hadiah & Kosmetik', style: AppText.title.copyWith(fontSize: 20)),
                const Spacer(),
                _coin(gs.coins),
              ]),
              const SizedBox(height: 12),
              const MascotBubble(
                color: AppColors.gold,
                mood: Mood.cheer,
                text: 'Kumpulkan kosmetik lucu! Semua dari koin atau iklan opsional — tanpa bayar. ✨',
              ),
              const SizedBox(height: 18),
              _section('Skin Lajur', '🎚️'),
              const SizedBox(height: 10),
              Wrap(spacing: 12, runSpacing: 12, children: lanes.map((c) => SizedBox(width: w, child: _tile(context, gs, c, gs.laneSkin))).toList()),
              const SizedBox(height: 22),
              _section('Efek Ketukan', '💥'),
              const SizedBox(height: 10),
              Wrap(spacing: 12, runSpacing: 12, children: hits.map((c) => SizedBox(width: w, child: _tile(context, gs, c, gs.hitEffect))).toList()),
              const SizedBox(height: 22),
              _section('Lencana Prestasi', '🏅'),
              const SizedBox(height: 10),
              _badges(gs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, GameState gs, _Cosmetic c, String selected) {
    final owned = gs.cosmetics.contains(c.id);
    final isSelected = selected == c.id;
    final accent = c.colors.first;
    return SoftCard(
      accent: isSelected ? accent : (owned ? accent : AppColors.violet),
      glowStrength: isSelected ? 0.55 : 0.22,
      padding: const EdgeInsets.all(12),
      onTap: owned ? () => gs.selectCosmetic(c.kind, c.id) : null,
      badge: c.adOnly && !owned
          ? const FloatingBadge(text: 'IKLAN', icon: Icons.slow_motion_video_rounded, gradient: AppGradients.aurora)
          : (c.coins == 0 && !c.adOnly ? const FloatingBadge(text: 'GRATIS', gradient: AppGradients.ocean) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _preview(c),
          const SizedBox(height: 10),
          Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          if (isSelected)
            _statusPill('Dipakai', Icons.check_rounded, accent, filled: true)
          else if (owned)
            _statusPill('Pakai', Icons.touch_app_rounded, accent)
          else if (c.adOnly)
            Bouncy(onTap: () => _unlockViaAd(context, gs, c), child: _statusPill('Tonton iklan', Icons.slow_motion_video_rounded, AppColors.cyan))
          else
            Bouncy(
              onTap: gs.coins >= c.coins
                  ? () {
                      gs.addCoins(-c.coins);
                      gs.grantCosmetic(c.id);
                    }
                  : null,
              child: _statusPill('${c.coins} koin', Icons.monetization_on, gs.coins >= c.coins ? AppColors.gold : AppColors.textLo),
            ),
        ],
      ),
    );
  }

  Widget _preview(_Cosmetic c) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: c.colors),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppShadows.glow(c.colors.first, blur: 16, y: 4, a: 0.4),
      ),
      child: Center(
        child: c.kind == 'lane'
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    4,
                    (i) => Container(
                          width: 8,
                          height: 30 + (i.isEven ? 8 : 0),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4)),
                        )),
              )
            : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _statusPill(String text, IconData icon, Color color, {bool filled = false}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled ? LinearGradient(colors: [color, Color.lerp(color, AppColors.violet, 0.4)!]) : null,
          color: filled ? null : color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: filled ? Colors.white : color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: filled ? Colors.white : color)),
        ]),
      );

  Future<void> _unlockViaAd(BuildContext context, GameState gs, _Cosmetic c) async {
    final granted = await showRewardAdSheet(
      context,
      kind: RewardKind.cosmetic,
      title: 'Buka "${c.name}"',
      reward: 'Kosmetik ${c.name} permanen',
    );
    if (granted) gs.grantCosmetic(c.id);
  }

  Widget _badges(GameState gs) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: missions.map((m) {
        final done = m.done(gs);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: done ? AppGradients.goldRush : null,
            color: done ? null : AppColors.glass,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: done ? Colors.white.withValues(alpha: 0.4) : AppColors.glassBorder),
            boxShadow: done ? AppShadows.glow(AppColors.gold, blur: 14, y: 4, a: 0.4) : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(done ? Icons.military_tech_rounded : Icons.lock_rounded,
                size: 16, color: done ? Colors.white : AppColors.textLo),
            const SizedBox(width: 6),
            Text(m.title,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: done ? Colors.white : AppColors.textLo)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _section(String t, String emoji) =>
      Text('$emoji  $t', style: AppText.heading.copyWith(fontSize: 17));

  Widget _coin(int coins) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
          const SizedBox(width: 4),
          Text('$coins', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold)),
        ]),
      );
}
