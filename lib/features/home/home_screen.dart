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
    final continueSong = catalog.byId('koplo_neon') ?? catalog.playable.last;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context, gs)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _hero(context, featured),
                    const SizedBox(height: 14),
                    _continueCard(context, gs, continueSong),
                    const SizedBox(height: 20),
                    _quickActions(context),
                    const SizedBox(height: 22),
                    _missionsHeader(),
                    const SizedBox(height: 10),
                    _missions(context, gs),
                    const SizedBox(height: 22),
                    _sectionTitle('Untuk Kamu', '✨', AppColors.cyan),
                    const Padding(
                      padding: EdgeInsets.only(left: 2, top: 2, bottom: 10),
                      child: Text('Beat pilihan buat kamu hari ini',
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

  // -------- header with cute avatar orb --------
  Widget _header(BuildContext context, GameState gs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Bouncy(
            onTap: () => _goTab(context, 3, const ProfileScreen()),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const PulseRings(color: AppColors.cyan, size: 56, count: 2),
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.aurora,
                      boxShadow: AppShadows.glow(AppColors.violet, blur: 14, y: 3, a: 0.5),
                    ),
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor: AppColors.surface,
                      child: Text(
                        gs.playerName.isNotEmpty ? gs.playerName[0].toUpperCase() : 'P',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppGradients.goldRush,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: Text('${gs.level}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ],
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
                const Text('Yuk, gas satu lagu! 💫',
                    style: TextStyle(color: AppColors.textLo, fontSize: 12)),
              ],
            ),
          ),
          _coinChip(gs.coins),
          const SizedBox(width: 2),
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
          Text('$coins', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold)),
        ]),
      );

  // -------- hero: the event-feeling featured card --------
  Widget _hero(BuildContext context, Song featured) {
    final accent = AppColors.moodFor(featured.category);
    return SoftCard(
      padding: EdgeInsets.zero,
      accent: accent,
      glowStrength: 0.55,
      onTap: () => _push(context, SongDetailScreen(song: featured)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: 226,
          child: Stack(
            children: [
              Positioned.fill(
                child: HoloSheen(
                    radius: 0, intensity: 0.7, child: Image.asset(featured.coverAssetPath, fit: BoxFit.cover)),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [AppColors.ink.withValues(alpha: 0.94), accent.withValues(alpha: 0.28)],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(child: Twinkles(count: 10)),
              Positioned(right: -28, top: -8, child: PulseRings(color: accent, size: 190)),
              const Positioned(
                  right: 30, top: 70, child: Icon(Icons.play_circle_fill, size: 58, color: Colors.white70)),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Sticker(text: 'BEAT PILIHAN', icon: Icons.star_rounded, gradient: AppGradients.candy, angle: -0.05),
                    const Spacer(),
                    Text(featured.title, style: AppText.title.copyWith(fontSize: 26)),
                    Row(children: [
                      Text(featured.artistDisplayName, style: const TextStyle(color: AppColors.textLo)),
                      const Text('  •  Cocok buat kamu ✨', style: TextStyle(color: AppColors.textLo, fontSize: 12)),
                    ]),
                    const SizedBox(height: 8),
                    Opacity(opacity: 0.9, child: Waveform(gradient: AppGradients.from(accent), height: 26, bars: 32)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 170,
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

  // -------- "continue your rhythm" wide card --------
  Widget _continueCard(BuildContext context, GameState gs, Song song) {
    final accent = AppColors.moodFor(song.category);
    final diff = song.availableDifficulties.isNotEmpty ? song.availableDifficulties.last : 'Normal';
    final best = gs.best(song.id, diff);
    return SoftCard(
      accent: accent,
      glowStrength: 0.24,
      padding: const EdgeInsets.all(10),
      onTap: () => _push(context, SongDetailScreen(song: song)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Image.asset(song.coverAssetPath, width: 72, height: 72, fit: BoxFit.cover),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LANJUTKAN RITMEMU 🎶',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: accent, letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(best != null ? 'Skor terbaikmu: ${best.grade} • ${best.accuracy.toStringAsFixed(1)}%' : 'Belum dicoba — ayo mulai!',
                  style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: AppGradients.from(accent),
            shape: BoxShape.circle,
            boxShadow: AppShadows.glow(accent, blur: 12, y: 3, a: 0.5),
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        ),
      ]),
    );
  }

  // -------- glossy quick-action capsules --------
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
                  _glossyIcon(it.$1, it.$3),
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

  Widget _glossyIcon(IconData icon, Color color) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppGradients.from(color),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.glow(color, blur: 10, y: 3, a: 0.5),
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
          Center(child: Icon(icon, color: Colors.white, size: 22)),
        ]),
      );

  // -------- collectible mission cards --------
  Widget _missionsHeader() => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _sectionTitle('Misi', '🎁', AppColors.gold),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text('Misi kecil, reward manis',
                style: TextStyle(color: AppColors.textLo, fontSize: 12)),
          ),
        ],
      );

  Widget _missions(BuildContext context, GameState gs) {
    const accents = [AppColors.pink, AppColors.cyan, AppColors.gold, AppColors.mint];
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: missions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final m = missions[i];
          final accent = accents[i % accents.length];
          final done = m.done(gs);
          final p = m.progress(gs);
          return SizedBox(
            width: 214,
            child: SoftCard(
              accent: accent,
              glowStrength: done ? 0.4 : 0.2,
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppGradients.from(accent),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.glow(accent, blur: 10, y: 2, a: 0.5),
                      ),
                      child: Icon(m.icon, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.monetization_on, size: 13, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text('+${m.reward}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 12)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(m.hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textLo, fontSize: 11, height: 1.2)),
                  const SizedBox(height: 10),
                  if (done)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      alignment: Alignment.center,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.teal, AppColors.mint]),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: const Text('Selesai ✓',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(children: [
                        Container(height: 8, color: AppColors.glass),
                        FractionallySizedBox(
                          widthFactor: p.clamp(0.0, 1.0).toDouble(),
                          child: Container(height: 8, decoration: BoxDecoration(gradient: AppGradients.from(accent))),
                        ),
                      ]),
                    ),
                ],
              ),
            ),
          );
        },
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
              gradient: LinearGradient(colors: g.colors.map((x) => x.withValues(alpha: 0.22)).toList()),
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
