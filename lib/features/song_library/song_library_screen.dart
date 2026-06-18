import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/song_catalog.dart';
import '../../game/models/song.dart';
import '../../state/game_state.dart';
import '../../widgets/song_card.dart';
import '../song_detail/song_detail_screen.dart';

class SongLibraryScreen extends StatefulWidget {
  final String? initialCategory;
  const SongLibraryScreen({super.key, this.initialCategory});
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
    if (_sortByBpm) {
      list = [...list]..sort((a, b) => a.bpm.compareTo(b.bpm));
    }

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              _search(),
              _categoryChips(cats),
              _filterRow(),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Text('Tidak ada lagu.',
                            style: TextStyle(color: AppColors.textLo)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: list.length,
                        itemBuilder: (_, i) => SongCard(
                          song: list[i],
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => SongDetailScreen(song: list[i]))),
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
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
          const Text('Perpustakaan Lagu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _search() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Cari lagu, artis, genre…',
            prefixIcon: const Icon(Icons.search, color: AppColors.textLo),
            filled: true,
            fillColor: AppColors.glass,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      );

  Widget _categoryChips(List<String> cats) => SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final on = cats[i] == _cat;
            return GestureDetector(
              onTap: () => setState(() => _cat = cats[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: on ? AppColors.brandGradient : null,
                  color: on ? null : AppColors.glass,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(cats[i],
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: on ? Colors.white : AppColors.textLo)),
              ),
            );
          },
        ),
      );

  Widget _filterRow() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(children: [
          _toggle('Favorit', _favOnly, () => setState(() => _favOnly = !_favOnly),
              icon: Icons.favorite),
          const SizedBox(width: 8),
          _toggle('Terkunci', _showLocked, () => setState(() => _showLocked = !_showLocked),
              icon: Icons.lock_open),
          const SizedBox(width: 8),
          _toggle('BPM', _sortByBpm, () => setState(() => _sortByBpm = !_sortByBpm),
              icon: Icons.speed),
        ]),
      );

  Widget _toggle(String label, bool on, VoidCallback onTap, {required IconData icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? AppColors.cyan.withValues(alpha: 0.2) : AppColors.glass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? AppColors.cyan : AppColors.glassBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: on ? AppColors.cyan : AppColors.textLo),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: on ? AppColors.cyan : AppColors.textLo,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
