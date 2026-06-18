import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/song_catalog.dart';
import '../../game/models/song.dart';
import '../../state/game_state.dart';
import '../../widgets/bouncy.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/holo.dart';
import '../../widgets/neon_chip.dart';
import '../../widgets/shapes.dart';
import '../../widgets/song_card.dart';
import '../song_detail/song_detail_screen.dart';

class SongLibraryScreen extends StatefulWidget {
  final String? initialCategory;
  final bool embedded;
  const SongLibraryScreen({super.key, this.initialCategory, this.embedded = false});
  @override
  State<SongLibraryScreen> createState() => _SongLibraryScreenState();
}

class _SongLibraryScreenState extends State<SongLibraryScreen> {
  String _cat = 'Semua';
  String _query = '';
  bool _favOnly = false;
  bool _showLocked = true;
  bool _sortByBpm = false;

  @override
  void initState() {
    super.initState();
    _cat = widget.initialCategory ?? 'Semua';
  }

  void _open(Song s) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailScreen(song: s)));

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<SongCatalog>();
    final gs = context.watch<GameState>();
    final cats = ['Semua', 'Untuk Kamu', ...catalog.categories];

    List<Song> list;
    if (_cat == 'Untuk Kamu') {
      list = catalog.recommended();
    } else if (_cat == 'Semua') {
      list = catalog.songs;
    } else {
      list = catalog.inCategory(_cat);
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artistDisplayName.toLowerCase().contains(q) ||
              s.genre.toLowerCase().contains(q))
          .toList();
    }
    if (_favOnly) list = list.where((s) => gs.favorites.contains(s.id)).toList();
    if (!_showLocked) list = list.where(gs.isUnlocked).toList();
    if (_sortByBpm) list = [...list]..sort((a, b) => a.bpm.compareTo(b.bpm));

    final showFeatured = _cat == 'Semua' && _query.isEmpty && !_favOnly;
    final featured = catalog.byId('koplo_neon') ?? catalog.playable.first;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _header(context),
                    _search(),
                    _categoryChips(cats),
                    const SizedBox(height: 12),
                    _filterRow(),
                    if (showFeatured) _featured(featured),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 16, 2),
                      child: Row(children: [
                        Text(showFeatured ? 'Koleksi Beat 🎵' : '$_cat 🎵',
                            style: AppText.heading.copyWith(fontSize: 18)),
                      ]),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, widget.embedded ? 120 : 100),
                sliver: list.isEmpty
                    ? const SliverToBoxAdapter(child: _Empty())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => SongCard(song: list[i], onTap: () => _open(list[i])),
                          childCount: list.length,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(widget.embedded ? 18 : 6, 12, 16, 0),
        child: Row(children: [
          if (!widget.embedded)
            Bouncy(
                onTap: () => Navigator.pop(context),
                child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back_rounded))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Perpustakaan Beat', style: AppText.title),
                const Text('Cari beat favoritmu 🎧',
                    style: TextStyle(color: AppColors.textLo, fontSize: 12.5)),
              ],
            ),
          ),
        ]),
      );

  Widget _search() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Cari lagu, artis, genre…',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.cyan),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      );

  Widget _categoryChips(List<String> cats) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => Center(
            child: NeonChip(
              label: cats[i],
              selected: cats[i] == _cat,
              gradient: AppGradients.forCategory(cats[i]),
              onTap: () => setState(() => _cat = cats[i]),
            ),
          ),
        ),
      );

  Widget _filterRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          NeonChip(label: 'Favoritmu', icon: Icons.favorite_rounded, selected: _favOnly, gradient: AppGradients.sunset, onTap: () => setState(() => _favOnly = !_favOnly)),
          const SizedBox(width: 8),
          NeonChip(label: 'Terkunci', icon: Icons.lock_open_rounded, selected: _showLocked, gradient: AppGradients.aurora, onTap: () => setState(() => _showLocked = !_showLocked)),
          const SizedBox(width: 8),
          NeonChip(label: 'BPM', icon: Icons.speed_rounded, selected: _sortByBpm, gradient: AppGradients.ocean, onTap: () => setState(() => _sortByBpm = !_sortByBpm)),
        ]),
      );

  // big, rich featured card — "lagi nyala"
  Widget _featured(Song song) {
    final accent = AppColors.moodFor(song.category);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Bouncy(
        onTap: () => _open(song),
        scale: 0.97,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
            boxShadow: AppShadows.glow(accent, blur: 28, y: 12, a: 0.45),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 182,
            child: Stack(
              children: [
                Positioned.fill(child: HoloSheen(radius: 0, child: Image.asset(song.coverAssetPath, fit: BoxFit.cover))),
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
                const Positioned.fill(child: Twinkles(count: 8)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Sticker(text: 'LAGI NYALA', icon: Icons.local_fire_department_rounded, gradient: AppGradients.candy, angle: -0.05),
                      const Spacer(),
                      Text(song.title, style: AppText.title.copyWith(fontSize: 22)),
                      Text('${song.artistDisplayName}  •  ${song.bpm} BPM',
                          style: const TextStyle(color: AppColors.textLo, fontSize: 12.5)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 150,
                        child: GradientButton(
                          label: 'Mainkan',
                          icon: Icons.play_arrow_rounded,
                          height: 42,
                          gradient: AppGradients.from(accent),
                          onTap: () => _open(song),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(child: Text('Tidak ada lagu di sini 🎵', style: TextStyle(color: AppColors.textLo))),
    );
  }
}
