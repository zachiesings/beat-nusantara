import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/missions.dart';
import '../../data/song_catalog.dart';
import '../../state/game_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/song_card.dart';
import '../about/about_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/rewards_screen.dart';
import '../settings/settings_screen.dart';
import '../song_detail/song_detail_screen.dart';
import '../song_library/song_library_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final catalog = context.read<SongCatalog>();
    final featured = catalog.playable.first;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context, gs)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _featuredCard(context, featured),
                    const SizedBox(height: 18),
                    _quickActions(context),
                    const SizedBox(height: 22),
                    _sectionTitle('Misi', Icons.flag),
                    const SizedBox(height: 10),
                    _missions(gs),
                    const SizedBox(height: 22),
                    _sectionTitle('Untuk Kamu', Icons.auto_awesome),
                    const SizedBox(height: 10),
                    _recommended(context, catalog),
                    const SizedBox(height: 22),
                    _sectionTitle('Kategori', Icons.category),
                    const SizedBox(height: 10),
                    _categories(context, catalog),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, GameState gs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _push(context, const ProfileScreen()),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                gs.playerName.isNotEmpty ? gs.playerName[0].toUpperCase() : 'P',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, ${gs.playerName} 👋',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                Text('Level ${gs.level}',
                    style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
              ],
            ),
          ),
          _coinChip(gs.coins),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textLo),
            onPressed: () => _push(context, const SettingsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _coinChip(int coins) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
          const SizedBox(width: 6),
          Text('$coins',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold)),
        ]),
      );

  Widget _featuredCard(BuildContext context, featured) {
    return GlassPanel(
      padding: const EdgeInsets.all(0),
      onTap: () => _push(context, SongDetailScreen(song: featured)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(featured.coverAssetPath,
                height: 190, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.ink.withValues(alpha: 0.85), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _MiniTag('LAGU UNGGULAN'),
                const SizedBox(height: 38),
                Text(featured.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                Text(featured.artistDisplayName,
                    style: const TextStyle(color: AppColors.textLo)),
                const SizedBox(height: 12),
                SizedBox(
                  width: 150,
                  child: GradientButton(
                    label: 'Main Sekarang',
                    icon: Icons.play_arrow_rounded,
                    height: 46,
                    onTap: () => _push(context, SongDetailScreen(song: featured)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    final items = [
      (Icons.library_music, 'Lagu', () => _push(context, const SongLibraryScreen())),
      (Icons.card_giftcard, 'Hadiah', () => _push(context, const RewardsScreen())),
      (Icons.bar_chart, 'Statistik', () => _push(context, const ProfileScreen())),
      (Icons.info_outline, 'Tentang', () => _push(context, const AboutScreen())),
    ];
    return Row(
      children: items.map((it) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(vertical: 14),
              onTap: it.$3,
              child: Column(children: [
                Icon(it.$1, color: AppColors.cyan),
                const SizedBox(height: 6),
                Text(it.$2, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _missions(GameState gs) {
    return Column(
      children: missions.map((m) {
        final done = m.done(gs);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassPanel(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done ? AppColors.teal : AppColors.textLo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: done ? TextDecoration.lineThrough : null,
                            color: done ? AppColors.textLo : AppColors.textHi)),
                    Text(m.hint,
                        style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _recommended(BuildContext context, SongCatalog catalog) {
    final list = catalog.recommended();
    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(
          width: 170,
          child: SongCard(
            song: list[i],
            compact: true,
            onTap: () => _push(context, SongDetailScreen(song: list[i])),
          ),
        ),
      ),
    );
  }

  Widget _categories(BuildContext context, SongCatalog catalog) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: catalog.categories.map((c) {
        return GestureDetector(
          onTap: () => _push(context, SongLibraryScreen(initialCategory: c)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  static Widget _sectionTitle(String t, IconData icon) => Row(children: [
        Icon(icon, size: 18, color: AppColors.pink),
        const SizedBox(width: 8),
        Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ]);

  static void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cyan),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.cyan)),
    );
  }
}
