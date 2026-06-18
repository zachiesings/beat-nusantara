import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/missions.dart';
import '../../data/song_catalog.dart';
import '../../game/models/song.dart';
import '../../state/game_state.dart';
import '../../widgets/bouncy.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/holo.dart';
import '../../widgets/mascot.dart';
import '../../widgets/pulse.dart';
import '../../widgets/shapes.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/song_card.dart';
import '../../widgets/waveform.dart';
import '../about/about_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/rewards_screen.dart';
import '../settings/settings_screen.dart';
import '../shell/main_shell.dart';
import '../song_detail/song_detail_screen.dart';
import '../song_library/song_library_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final catalog = context.read<SongCatalog>();
    final featured = catalog.playable.first;
    final doneCount = missions.where((m) => m.done(gs)).length;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context, gs)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _hero(context, featured),
                    const SizedBox(height: 16),
                    _quickActions(context),
                    const SizedBox(height: 22),
                    _missionCard(context, gs, doneCount),
                    const SizedBox(height: 22),
                    _sectionTitle('Untuk Kamu', '✨', AppColors.cyan),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.only(left: 2, bottom: 10),
                      child: Text('Beat pilihan hari ini ✨',
                          style: TextStyle(color: AppColors.textLo, fontSize: 12.5)),
                    ),
                    _recommended(context, catalog),
                    const SizedBox(height: 24),
                    _sectionTitle('Kategori', '🎧', AppColors.pink),
                    const SizedBox(height: 12),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Bouncy(
            onTap: () => _goTab(context, 3, const ProfileScreen()),
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.aurora),
              child: CircleAvatar(
                radius: 23,
                backgroundColor: AppColors.surface,
                child: Text(
                  gs.playerName.isNotEmpty ? gs.playerName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, ${gs.playerName}! 👋',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.heading),
                Text('Yuk, gas beat hari ini! 💫 Lv ${gs.level}',
                    style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
              ],
            ),
          ),
          _coinChip(gs.coins),
          const SizedBox(width: 4),
          Bouncy(
            onTap: () => _push(context, const SettingsScreen()),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.settings_rounded, color: AppColors.textLo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coinChip(int coins) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
          boxShadow: AppShadows.glow(AppColors.gold, blur: 12, y: 3, a: 0.3),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
          const SizedBox(width: 6),
          Text('$coins',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold)),
        ]),
      );

  Widget _hero(BuildContext context, Song featured) {
    final accent = AppColors.accentFor(featured.id);
    return SoftCard(
      padding: EdgeInsets.zero,
      accent: accent,
      glowStrength: 0.5,
      onTap: () => _push(context, SongDetailScreen(song: featured)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: 208,
          child: Stack(
            children: [
              Positioned.fill(
                child: HoloSheen(
                    radius: 0,
                    intensity: 0.7,
                    child: Image.asset(featured.coverAssetPath, fit: BoxFit.cover)),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [AppColors.ink.withValues(alpha: 0.92), accent.withValues(alpha: 0.25)],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(child: Twinkles(count: 9)),
              Positioned(
                right: -30,
                top: -10,
                child: PulseRings(color: accent, size: 180),
              ),
              const Positioned(
                  right: 28, top: 64, child: Icon(Icons.play_circle_fill, size: 56, color: Colors.white70)),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Sticker(text: 'UNGGULAN', icon: Icons.star_rounded, gradient: AppGradients.candy, angle: -0.05, fontSize: 11),
                    const Spacer(),
                    Text(featured.title, style: AppText.title.copyWith(fontSize: 25)),
                    Text(featured.artistDisplayName, style: const TextStyle(color: AppColors.textLo)),
                    const SizedBox(height: 8),
                    Opacity(opacity: 0.9, child: Waveform(gradient: AppGradients.from(accent), height: 26, bars: 30)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 168,
                      child: GradientButton(
                        label: 'Yuk, Gas!',
                        icon: Icons.play_arrow_rounded,
                        height: 46,
                        gradient: AppGradients.from(accent),
                        onTap: () => _push(context, SongDetailScreen(song: featured)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    final items = [
      (Icons.library_music_rounded, 'Lagu', AppColors.cyan, () => _goTab(context, 1, const SongLibraryScreen())),
      (Icons.card_giftcard_rounded, 'Hadiah', AppColors.gold, () => _goTab(context, 2, const RewardsScreen())),
      (Icons.insights_rounded, 'Statistik', AppColors.mint, () => _goTab(context, 3, const ProfileScreen())),
      (Icons.favorite_rounded, 'Tentang', AppColors.pink, () => _push(context, const AboutScreen())),
    ];
    return Row(
      children: items.map((it) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Bouncy(
              onTap: it.$4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [it.$3.withValues(alpha: 0.22), AppColors.surface.withValues(alpha: 0.5)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: it.$3.withValues(alpha: 0.4)),
                  boxShadow: AppShadows.glow(it.$3, blur: 14, y: 6, a: 0.25),
                ),
                child: Column(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppGradients.from(it.$3),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppShadows.glow(it.$3, blur: 10, y: 3, a: 0.5),
                    ),
                    child: Stack(children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: 18,
                          margin: const EdgeInsets.fromLTRB(4, 3, 4, 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
                              Colors.white.withValues(alpha: 0.35),
                              Colors.white.withValues(alpha: 0.0),
                            ]),
                          ),
                        ),
                      ),
                      Center(child: Icon(it.$1, color: Colors.white, size: 22)),
                    ]),
                  ),
                  const SizedBox(height: 7),
                  Text(it.$2, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _missionCard(BuildContext context, GameState gs, int done) {
    final allDone = done == missions.length;
    return SoftCard(
      accent: AppColors.gold,
      glowStrength: 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _sectionTitle('Misi', '⚑', AppColors.gold),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text('$done/${missions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 10),
          MascotBubble(
            mood: allDone ? Mood.cheer : Mood.happy,
            color: AppColors.gold,
            text: allDone ? 'Semua misi beres! Kamu hebat! 🎉' : 'Ayo kejar Full Combo hari ini! 🔥',
          ),
          const SizedBox(height: 6),
          ...missions.take(2).map((m) {
            final ok = m.done(gs);
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: ok ? AppColors.teal : AppColors.textLo, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(m.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ok ? AppColors.textLo : AppColors.textHi,
                          decoration: ok ? TextDecoration.lineThrough : null)),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _recommended(BuildContext context, SongCatalog catalog) {
    final list = catalog.recommended();
    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => SongCard(
          song: list[i],
          compact: true,
          onTap: () => _push(context, SongDetailScreen(song: list[i])),
        ),
      ),
    );
  }

  Widget _categories(BuildContext context, SongCatalog catalog) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: catalog.categories.map((c) {
        final g = AppGradients.forCategory(c);
        final accent = g.colors.first;
        return Bouncy(
          onTap: () => _push(context, SongLibraryScreen(initialCategory: c)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: g.colors.map((x) => x.withValues(alpha: 0.22)).toList()),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(c, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  static Widget _sectionTitle(String t, String emoji, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$emoji ', style: const TextStyle(fontSize: 16)),
          Text(t, style: AppText.heading.copyWith(fontSize: 19)),
        ],
      );

  static void _goTab(BuildContext context, int tab, Widget fallback) {
    final shell = ShellScope.maybeOf(context);
    if (shell != null) {
      shell.go(tab);
    } else {
      _push(context, fallback);
    }
  }

  static void _push(BuildContext context, Widget page) => Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: AppDur.med,
          pageBuilder: (_, a, __) => page,
          transitionsBuilder: (_, a, __, child) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
              child: child,
            ),
          ),
        ),
      );
}
