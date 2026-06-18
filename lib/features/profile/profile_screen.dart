import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/missions.dart';
import '../../data/song_catalog.dart';
import '../../state/game_state.dart';
import '../../widgets/glass_panel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final catalog = context.read<SongCatalog>();
    final plays = gs.bestScores.length;
    final fcCount = gs.bestScores.values.where((b) => b.fullCombo).length;
    final missionsDone = missions.where((m) => m.done(gs)).length;

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
                const Text('Profil & Statistik',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 8),
              GlassPanel(
                child: Column(children: [
                  Row(children: [
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          gradient: AppColors.brandGradient, shape: BoxShape.circle),
                      child: Text(
                          gs.playerName.isNotEmpty ? gs.playerName[0].toUpperCase() : 'P',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(gs.playerName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          Text('Level ${gs.level}  •  ${gs.coins} koin',
                              style: const TextStyle(color: AppColors.textLo)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Text('Lv ${gs.level}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: gs.levelProgress,
                          minHeight: 8,
                          backgroundColor: AppColors.glass,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${gs.xpIntoLevel}/500 XP', style: const TextStyle(fontSize: 11)),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),
              Row(children: [
                _statCard('Lagu dimainkan', '$plays', Icons.library_music),
                const SizedBox(width: 12),
                _statCard('Full Combo', '$fcCount', Icons.bolt),
                const SizedBox(width: 12),
                _statCard('Misi', '$missionsDone/${missions.length}', Icons.flag),
              ]),
              const SizedBox(height: 18),
              const Text('Skor Terbaik',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              if (gs.bestScores.isEmpty)
                const _Empty()
              else
                ...gs.bestScores.entries.map((e) {
                  final parts = e.key.split('__');
                  final song = catalog.byId(parts.first);
                  final diff = parts.length > 1 ? parts[1] : '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassPanel(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gold),
                          ),
                          child: Text(e.value.grade,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song?.title ?? parts.first,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('$diff • ${e.value.accuracy.toStringAsFixed(1)}%'
                                  '${e.value.fullCombo ? ' • FC' : ''}',
                                  style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('${e.value.score}',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) => Expanded(
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: [
            Icon(icon, color: AppColors.cyan),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textLo)),
          ]),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const GlassPanel(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Belum ada skor. Mainkan lagu pertamamu! 🎵',
            style: TextStyle(color: AppColors.textLo)),
      ),
    );
  }
}
