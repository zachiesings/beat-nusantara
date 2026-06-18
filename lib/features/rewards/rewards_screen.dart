import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/missions.dart';
import '../../services/ads/ads_service.dart';
import '../../state/game_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/reward_ad_sheet.dart';

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
  _Cosmetic('neon', 'Neon (default)', 'lane', 0, false, [AppColors.violet, AppColors.cyan]),
  _Cosmetic('sunset', 'Senja', 'lane', 120, false, [AppColors.pink, AppColors.gold]),
  _Cosmetic('ocean', 'Samudra', 'lane', 180, false, [AppColors.cyan, AppColors.teal]),
  _Cosmetic('batik', 'Batik Emas', 'lane', 0, true, [AppColors.gold, AppColors.pink]),
  _Cosmetic('spark', 'Spark (default)', 'hit', 0, false, [AppColors.cyan, AppColors.violet]),
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

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context)),
                const Text('Hadiah & Kosmetik',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
                _coin(gs.coins),
              ]),
              const SizedBox(height: 8),
              const _Note(
                  'Semua kosmetik bisa didapat lewat koin (dari bermain gratis) atau '
                  'iklan opsional. Tidak ada mata uang berbayar.'),
              const SizedBox(height: 16),
              _section('Skin Lajur'),
              ...lanes.map((c) => _tile(context, gs, c, gs.laneSkin)),
              const SizedBox(height: 16),
              _section('Efek Ketukan'),
              ...hits.map((c) => _tile(context, gs, c, gs.hitEffect)),
              const SizedBox(height: 16),
              _section('Lencana Prestasi'),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: c.colors),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (isSelected)
            const Chip(label: Text('Dipakai'), backgroundColor: AppColors.violet)
          else if (owned)
            TextButton(
              onPressed: () => gs.selectCosmetic(c.kind, c.id),
              child: const Text('Pakai'),
            )
          else if (c.adOnly)
            OutlinedButton(
              onPressed: () => _unlockViaAd(context, gs, c),
              child: const Text('Iklan'),
            )
          else
            OutlinedButton.icon(
              onPressed: gs.coins >= c.coins
                  ? () {
                      gs.addCoins(-c.coins);
                      gs.grantCosmetic(c.id);
                    }
                  : null,
              icon: const Icon(Icons.monetization_on, size: 16, color: AppColors.gold),
              label: Text('${c.coins}'),
            ),
        ]),
      ),
    );
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: done ? AppColors.gold.withValues(alpha: 0.18) : AppColors.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: done ? AppColors.gold : AppColors.glassBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(done ? Icons.military_tech : Icons.lock,
                size: 16, color: done ? AppColors.gold : AppColors.textLo),
            const SizedBox(width: 6),
            Text(m.title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: done ? AppColors.gold : AppColors.textLo)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      );

  Widget _coin(int coins) => Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
        const SizedBox(width: 4),
        Text('$coins', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold)),
      ]);
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.textLo, fontSize: 12.5, height: 1.4)),
    );
  }
}
