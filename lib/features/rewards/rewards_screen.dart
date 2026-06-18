import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/missions.dart';
import '../../services/ads/ads_service.dart';
import '../../state/game_state.dart';
import '../../widgets/bouncy.dart';
import '../../widgets/mascot.dart';
import '../../widgets/neon_chip.dart';
import '../../widgets/reward_ad_sheet.dart';
import '../../widgets/shapes.dart';
import '../../widgets/soft_card.dart';

class _Cosmetic {
  final String id, name, kind;
  final int coins;
  final bool adOnly;
  final List<Color> colors;
  const _Cosmetic(this.id, this.name, this.kind, this.coins, this.adOnly, this.colors);
  String get rarity => adOnly ? 'Spesial' : (coins == 0 ? 'Gratis' : 'Langka');
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

const _segments = ['Skin Lajur', 'Efek', 'Lencana', 'Profil', 'Spesial'];

class RewardsScreen extends StatefulWidget {
  final bool embedded;
  const RewardsScreen({super.key, this.embedded = false});
  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  int _seg = 0;

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(context, gs),
              _segmentBar(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, widget.embedded ? 120 : 40),
                  children: [_body(context, gs)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, GameState gs) => Padding(
        padding: EdgeInsets.fromLTRB(widget.embedded ? 16 : 6, 12, 16, 8),
        child: Row(children: [
          if (!widget.embedded)
            Bouncy(onTap: () => Navigator.pop(context), child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back_rounded))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Koleksi Beat', style: AppText.title.copyWith(fontSize: 22)),
                const Text('Skin, efek & lencana kamu ✨', style: TextStyle(color: AppColors.textLo, fontSize: 12)),
              ],
            ),
          ),
          _coinCapsule(gs.coins),
        ]),
      );

  Widget _coinCapsule(int coins) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0x33FFCB45), Color(0x22FF7E67)]),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
          boxShadow: AppShadows.glow(AppColors.gold, blur: 14, y: 4, a: 0.4),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.monetization_on, color: AppColors.gold, size: 19),
          const SizedBox(width: 6),
          Text('$coins', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 15)),
        ]),
      );

  Widget _segmentBar() => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _segments.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => Center(
            child: NeonChip(
              label: _segments[i],
              selected: i == _seg,
              gradient: AppGradients.aurora,
              onTap: () => setState(() => _seg = i),
            ),
          ),
        ),
      );

  Widget _body(BuildContext context, GameState gs) {
    switch (_seg) {
      case 0:
        return _grid(context, gs, _cosmetics.where((c) => c.kind == 'lane').toList(), gs.laneSkin);
      case 1:
        return _grid(context, gs, _cosmetics.where((c) => c.kind == 'hit').toList(), gs.hitEffect);
      case 2:
        return _badges(gs);
      default:
        return const _SoonState();
    }
  }

  Widget _grid(BuildContext context, GameState gs, List<_Cosmetic> items, String selected) {
    final w = (MediaQuery.of(context).size.width - 32 - 12) / 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MascotBubble(color: AppColors.gold, mood: Mood.cheer, text: 'Hadiah kecil buat beat besar 🎁'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((c) => SizedBox(width: w, child: _card(context, gs, c, selected))).toList(),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, GameState gs, _Cosmetic c, String selected) {
    final owned = gs.cosmetics.contains(c.id);
    final equipped = selected == c.id;
    final accent = c.colors.first;
    return SoftCard(
      accent: equipped ? accent : (owned ? accent : AppColors.violet),
      glowStrength: equipped ? 0.55 : 0.2,
      padding: const EdgeInsets.all(12),
      onTap: owned ? () => gs.selectCosmetic(c.kind, c.id) : null,
      badge: FloatingBadge(
        text: c.rarity.toUpperCase(),
        gradient: c.adOnly ? AppGradients.dream : (c.coins == 0 ? AppGradients.ocean : AppGradients.candy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            _preview(c),
            if (equipped) Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: const Twinkles(count: 6))),
            if (equipped)
              const Positioned(top: 4, right: 4, child: Sticker(text: '✓', gradient: AppGradients.ocean, angle: 0.0, fontSize: 11)),
            if (!owned)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(AppRadius.sm)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.lock_rounded, color: Colors.white70, size: 22),
                ),
              ),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            Text(c.rarity, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
          ]),
          const SizedBox(height: 8),
          _action(context, gs, c, owned, equipped, accent),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, GameState gs, _Cosmetic c, bool owned, bool equipped, Color accent) {
    if (equipped) return _pill('Dipakai', Icons.check_rounded, accent, filled: true);
    if (owned) return _pill('Pakai', Icons.touch_app_rounded, accent);
    if (c.adOnly) {
      return Bouncy(onTap: () => _unlockViaAd(context, gs, c), child: _pill('Tonton iklan', Icons.slow_motion_video_rounded, AppColors.cyan));
    }
    final can = gs.coins >= c.coins;
    return Bouncy(
      onTap: can ? () { gs.addCoins(-c.coins); gs.grantCosmetic(c.id); } : null,
      child: _pill('${c.coins} koin', Icons.monetization_on, can ? AppColors.gold : AppColors.textLo),
    );
  }

  Widget _pill(String text, IconData icon, Color color, {bool filled = false}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled ? LinearGradient(colors: [color, Color.lerp(color, AppColors.violet, 0.4)!]) : null,
          color: filled ? null : color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: filled ? AppShadows.glow(color, blur: 12, y: 3, a: 0.5) : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: filled ? Colors.white : color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: filled ? Colors.white : color)),
        ]),
      );

  Widget _preview(_Cosmetic c) => Container(
        height: 66,
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
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4)),
                          )),
                )
              : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
        ),
      );

  Future<void> _unlockViaAd(BuildContext context, GameState gs, _Cosmetic c) async {
    final granted = await showRewardAdSheet(context, kind: RewardKind.cosmetic, title: 'Buka "${c.name}"', reward: 'Kosmetik ${c.name} permanen');
    if (granted) gs.grantCosmetic(c.id);
  }

  // -------- collectible medal shelf --------
  Widget _badges(GameState gs) {
    final medals = <(String, IconData, bool)>[
      ('Full Combo', Icons.bolt_rounded, missions[1].done(gs)),
      ('Akurasi 90%+', Icons.center_focus_strong_rounded, missions[0].done(gs)),
      ('Cinta Nusantara', Icons.favorite_rounded, missions[2].done(gs)),
      ('Naik Level', Icons.trending_up_rounded, missions[3].done(gs)),
      ('Kombo 500', Icons.whatshot_rounded, false),
      ('Master Koplo', Icons.music_note_rounded, false),
      ('Gamelan Glow', Icons.auto_awesome_rounded, false),
      ('Beat Santai', Icons.spa_rounded, false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MascotBubble(color: AppColors.gold, mood: Mood.happy, text: 'Kumpulkan lencana dari pencapaianmu! 🏅'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: medals.map((m) => _medal(m.$1, m.$2, m.$3)).toList(),
        ),
      ],
    );
  }

  Widget _medal(String label, IconData icon, bool earned) => SizedBox(
        width: 86,
        child: Column(children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: earned ? AppGradients.goldRush : null,
              color: earned ? null : AppColors.glass,
              border: Border.all(color: earned ? Colors.white.withValues(alpha: 0.5) : AppColors.glassBorder, width: 2),
              boxShadow: earned ? AppShadows.glow(AppColors.gold, blur: 16, y: 4, a: 0.5) : null,
            ),
            child: Icon(earned ? icon : Icons.lock_rounded, color: earned ? Colors.white : AppColors.textLo, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: earned ? AppColors.textHi : AppColors.textLo)),
        ]),
      );
}

class _SoonState extends StatelessWidget {
  const _SoonState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(children: const [
        Mascot(size: 110, mood: Mood.sleepy, color: AppColors.indigo),
        SizedBox(height: 14),
        Text('Segera hadir ✨', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        SizedBox(height: 6),
        Text('Bingkai profil & item spesial akan datang di update berikutnya — santai, tanpa terburu-buru.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLo, fontSize: 13)),
      ]),
    );
  }
}
