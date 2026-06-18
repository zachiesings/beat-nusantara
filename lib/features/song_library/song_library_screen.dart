import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/song_catalog.dart';
import '../../game/models/song.dart';
import '../../state/game_state.dart';
import '../../widgets/bouncy.dart';
import '../../widgets/neon_chip.dart';
import '../../widgets/song_card.dart';
import '../song_detail/song_detail_screen.dart';

class SongLibraryScreen extends StatefulWidget {
  final String? initialCategory;
  final bool embedded; // true when shown as a shell tab (no back arrow)
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

    final showHits = _cat == 'Semua' && _query.isEmpty && !_favOnly;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _topBar(context),
                    _search(),
                    _categoryChips(cats),
                    const SizedBox(height: 12),
                    _filterRow(),
                    if (showHits) _hits(context, catalog),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, widget.embedded ? 120 : 100),
                sliver: list.isEmpty
                    ? const SliverToBoxAdapter(child: _Empty())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => SongCard(
                            song: list[i],
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => SongDetailScreen(song: list[i]))),
                          ),
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

  Widget _topBar(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(widget.embedded ? 18 : 6, 12, 16, 0),
        child: Row(children: [
          if (!widget.embedded)
            Bouncy(
                onTap: () => Navigator.pop(context),
                child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back_rounded))),
          Text('Perpustakaan Lagu', style: AppText.title),
        ]),
      );

  Widget _search() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
          NeonChip(
              label: 'Favorit',
              icon: Icons.favorite_rounded,
              selected: _favOnly,
              gradient: AppGradients.sunset,
              onTap: () => setState(() => _favOnly = !_favOnly)),
          const SizedBox(width: 8),
          NeonChip(
              label: 'Terkunci',
              icon: Icons.lock_open_rounded,
              selected: _showLocked,
              gradient: AppGradients.aurora,
              onTap: () => setState(() => _showLocked = !_showLocked)),
          const SizedBox(width: 8),
          NeonChip(
              label: 'BPM',
              icon: Icons.speed_rounded,
              selected: _sortByBpm,
              gradient: AppGradients.ocean,
              onTap: () => setState(() => _sortByBpm = !_sortByBpm)),
        ]),
      );

  Widget _hits(BuildContext context, SongCatalog catalog) {
    final hits = catalog.playable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 10),
          child: Text('Lagi Hits 🔥', style: AppText.heading.copyWith(fontSize: 18)),
        ),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hits.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => SongCard(
              song: hits[i],
              compact: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SongDetailScreen(song: hits[i]))),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 16, 0),
          child: Text('Semua Lagu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: Text('Tidak ada lagu di sini 🎵',
            style: TextStyle(color: AppColors.textLo)),
      ),
    );
  }
}
