import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/missions.dart';
import '../../data/song_catalog.dart';
import '../../state/game_state.dart';
import '../../widgets/bouncy.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/stat_ring.dart';

class ProfileScreen extends StatelessWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  String _rank(int level) {
    if (level >= 10) return 'Maestro Nusantara';
    if (level >= 6) return 'Bintang Panggung';
    if (level >= 3) return 'Penari Irama';
    return 'Pemula Ceria';
  }

  String _favGenre(GameState gs, SongCatalog catalog) {
    final count = <String, int>{};
    for (final k in gs.bestScores.keys) {
      final s = catalog.byId(k.split('__').first);
      if (s != null) count[s.genre] = (count[s.genre] ?? 0) + 1;
    }
    if (count.isEmpty) return '—';
    return (count.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final catalog = context.read<SongCatalog>();
    final plays = gs.bestScores.length;
    final fcCount = gs.bestScores.values.where((b) => b.fullCombo).length;
    final missionsDone = missions.where((m) => m.done(gs)).length;

    return Scaffold(
      body: NeonBackground(
        motif: BatikMotif.parang,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, embedded ? 14 : 8, 16, embedded ? 120 : 40),
            children: [
              Row(children: [
                if (!embedded)
                  Bouncy(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back_rounded)))
                else
                  const SizedBox(width: 4),
                Text('Profil & Statistik', style: AppText.title.copyWith(fontSize: 20)),
              ]),
              const SizedBox(height: 8),
              _heroCard(gs),
              const SizedBox(height: 14),
              Row(children: [
                _glowStat('Lagu', '$plays', Icons.library_music_rounded, AppColors.cyan),
                const SizedBox(width: 12),
                _glowStat('Full Combo', '$fcCount', Icons.bolt_rounded, AppColors.gold),
                const SizedBox(width: 12),
                _glowStat('Misi', '$missionsDone/${missions.length}', Icons.flag_rounded, AppColors.mint),
              ]),
              const SizedBox(height: 14),
              SoftCard(
                accent: AppColors.pink,
                glowStrength: 0.22,
                child: Row(children: [
                  const Icon(Icons.queue_music_rounded, color: AppColors.pink),
                  const SizedBox(width: 12),
                  const Text('Genre favorit', style: TextStyle(color: AppColors.textLo)),
                  const Spacer(),
                  Text(_favGenre(gs, catalog),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.pink)),
                ]),
              ),
              const SizedBox(height: 18),
              Text('🏆  Skor Terbaik', style: AppText.heading.copyWith(fontSize: 17)),
              const SizedBox(height: 10),
              if (gs.bestScores.isEmpty)
                const _Empty()
              else
                ...gs.bestScores.entries.map((e) => _scoreRow(catalog, e.key, e.value)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard(GameState gs) {
    return SoftCard(
      gradient: AppGradients.dream,
      accent: AppColors.violet,
      glowStrength: 0.5,
      child: Column(
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.candy,
                boxShadow: AppShadows.glow(AppColors.pink, blur: 18, y: 4, a: 0.6),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.ink,
                child: Text(gs.playerName.isNotEmpty ? gs.playerName[0].toUpperCase() : 'P',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gs.playerName, style: AppText.title.copyWith(fontSize: 22)),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('✦ ${_rank(gs.level)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(height: 4),
                  Text('${gs.coins} koin', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            StatRing(
              progress: gs.levelProgress,
              value: '${gs.level}',
              label: 'Level',
              size: 78,
              color: AppColors.cyan,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _glowStat(String label, String value, IconData icon, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: AppShadows.glow(color, blur: 14, y: 6, a: 0.22),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AppColors.textLo)),
          ]),
        ),
      );

  Widget _scoreRow(SongCatalog catalog, String key, best) {
    final parts = key.split('__');
    final song = catalog.byId(parts.first);
    final diff = parts.length > 1 ? parts[1] : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        accent: AppColors.gold,
        glowStrength: 0.16,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.goldRush,
              boxShadow: AppShadows.glow(AppColors.gold, blur: 12, y: 2, a: 0.5),
            ),
            child: Text(best.grade,
                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song?.title ?? parts.first, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('$diff • ${best.accuracy.toStringAsFixed(1)}%${best.fullCombo ? ' • FC' : ''}',
                    style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
              ],
            ),
          ),
          Text('${best.score}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const SoftCard(
      accent: AppColors.cyan,
      child: MascotBubble(
        text: 'Belum ada skor. Yuk mainkan lagu pertamamu! 🎵',
        mood: Mood.happy,
      ),
    );
  }
}
