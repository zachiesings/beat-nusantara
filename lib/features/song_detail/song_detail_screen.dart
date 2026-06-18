import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../game/models/song.dart';
import '../../services/ads/ads_service.dart';
import '../../state/game_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/reward_ad_sheet.dart';
import '../gameplay/gameplay_screen.dart';

/// Gameplay modes — flavor variations of the same chart (no separate assets).
enum GameMode { classic, speed, chill }

extension GameModeX on GameMode {
  String get label => switch (this) {
        GameMode.classic => 'Klasik',
        GameMode.speed => 'Speed',
        GameMode.chill => 'Santai',
      };
  IconData get icon => switch (this) {
        GameMode.classic => Icons.grid_view,
        GameMode.speed => Icons.bolt,
        GameMode.chill => Icons.spa,
      };
  double get speed => switch (this) {
        GameMode.classic => 1.0,
        GameMode.speed => 1.4,
        GameMode.chill => 0.75,
      };
}

class SongDetailScreen extends StatefulWidget {
  final Song song;
  const SongDetailScreen({super.key, required this.song});
  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late String _diff = widget.song.availableDifficulties.isNotEmpty
      ? widget.song.availableDifficulties.first
      : 'Normal';
  GameMode _mode = GameMode.classic;

  Song get song => widget.song;

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final unlocked = gs.isUnlocked(song);
    final canPlay = unlocked && song.playable && song.chartPaths.containsKey(_diff);

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _hero(context, gs),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _meta(),
                            const SizedBox(height: 18),
                            if (!unlocked) _lockedPanel(context, gs) else _playSetup(gs),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (unlocked)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: canPlay
                      ? GradientButton(
                          label: 'Main — ${_mode.label}',
                          icon: Icons.play_arrow_rounded,
                          onTap: () => _play(context, gs),
                        )
                      : const _ComingSoonNote(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, GameState gs) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: Image.asset(song.coverAssetPath,
              height: 240, width: double.infinity, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.ink],
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: Icon(gs.favorites.contains(song.id) ? Icons.favorite : Icons.favorite_border,
                color: AppColors.pink),
            onPressed: () => gs.toggleFavorite(song.id),
          ),
        ),
        Positioned(
          left: 18,
          bottom: 14,
          right: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(song.title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              Text(song.artistDisplayName,
                  style: const TextStyle(color: AppColors.textLo, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _meta() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chip(Icons.speed, '${song.bpm} BPM'),
          _chip(Icons.queue_music, song.genre),
          _chip(Icons.public, song.regionTag),
          _chip(Icons.category, song.category),
        ],
      );

  Widget _chip(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 15, color: AppColors.cyan),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(fontSize: 12.5)),
        ]),
      );

  // ---- locked: honest unlock options (coins / optional ad trial / level) ----
  Widget _lockedPanel(BuildContext context, GameState gs) {
    if (song.unlockType == UnlockType.comingSoon) {
      return GlassPanel(
        child: Row(children: const [
          Icon(Icons.schedule, color: AppColors.textLo),
          SizedBox(width: 12),
          Expanded(
            child: Text(
                'Lagu finale akan hadir di update mendatang. Tidak ada hitung mundur — '
                'datang saja kapan pun kamu siap.',
                style: TextStyle(color: AppColors.textLo)),
          ),
        ]),
      );
    }
    final isLevel = song.unlockType == UnlockType.level;
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lock, color: AppColors.gold),
            const SizedBox(width: 10),
            Text(
              isLevel
                  ? 'Terbuka di Level ${song.unlockCost}'
                  : 'Buka lagu ini',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            isLevel
                ? 'Naik level dengan bermain lagu gratis — terbuka otomatis. Sekarang Level ${gs.level}.'
                : 'Pilih caranya. Keduanya opsional dan tanpa tekanan waktu.',
            style: const TextStyle(color: AppColors.textLo, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (!isLevel)
            GradientButton(
              label: 'Buka dengan ${song.unlockCost} koin',
              icon: Icons.monetization_on,
              gradient: const LinearGradient(colors: [AppColors.gold, AppColors.pink]),
              enabled: gs.canAfford(song),
              onTap: gs.canAfford(song)
                  ? () {
                      gs.unlockWithCoins(song);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lagu terbuka! 🎉')));
                    }
                  : null,
            ),
          if (!isLevel && !gs.canAfford(song))
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Koin belum cukup — mainkan lagu gratis untuk menambah koin.',
                  style: TextStyle(color: AppColors.textLo, fontSize: 12)),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.cyan),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.slow_motion_video, color: AppColors.cyan),
            label: const Text('Coba sesi ini lewat iklan (opsional)',
                style: TextStyle(color: AppColors.cyan)),
            onPressed: () => _trialViaAd(context, gs),
          ),
        ],
      ),
    );
  }

  Future<void> _trialViaAd(BuildContext context, GameState gs) async {
    final granted = await showRewardAdSheet(
      context,
      kind: RewardKind.songTrial,
      title: 'Coba "${song.title}"',
      reward: 'Akses lagu ini untuk sesi bermain sekarang',
    );
    if (granted) {
      gs.grantSessionTrial(song);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trial sesi aktif untuk lagu ini.')));
      }
    }
  }

  // ---- unlocked: difficulty + mode + best score ----
  Widget _playSetup(GameState gs) {
    final diffs = song.playable
        ? song.availableDifficulties.where(song.chartPaths.containsKey).toList()
        : song.availableDifficulties;
    final best = gs.best(song.id, _diff);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gs.isSessionTrial(song))
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _TrialBanner(),
          ),
        const Text('Kesulitan',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: diffs.map((d) {
            final on = d == _diff;
            return ChoiceChip(
              label: Text(d),
              selected: on,
              onSelected: (_) => setState(() => _diff = d),
              selectedColor: AppColors.violet,
              backgroundColor: AppColors.glass,
              labelStyle: TextStyle(color: on ? Colors.white : AppColors.textLo),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text('Mode', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: GameMode.values.map((m) {
            final on = m == _mode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _mode = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: on ? AppColors.brandGradient : null,
                      color: on ? null : AppColors.glass,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Column(children: [
                      Icon(m.icon, color: on ? Colors.white : AppColors.textLo),
                      const SizedBox(height: 4),
                      Text(m.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: on ? Colors.white : AppColors.textLo)),
                    ]),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (best != null)
          GlassPanel(
            child: Row(children: [
              const Icon(Icons.emoji_events, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Skor terbaik ($_diff): ${best.score}  •  ${best.grade}'
                    '${best.fullCombo ? '  •  FC' : ''}'),
              ),
            ]),
          ),
      ],
    );
  }

  void _play(BuildContext context, GameState gs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameplayScreen(
          song: song,
          difficulty: _diff,
          chartPath: song.chartPaths[_diff]!,
          speedMult: _mode.speed,
          modeLabel: _mode.label,
        ),
      ),
    );
  }
}

class _ComingSoonNote extends StatelessWidget {
  const _ComingSoonNote();
  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(children: const [
        Icon(Icons.construction, color: AppColors.gold),
        SizedBox(width: 12),
        Expanded(
          child: Text(
              'Chart untuk lagu ini segera hadir setelah audio berlisensi ditambahkan. '
              'Lagu sudah ada di koleksimu.',
              style: TextStyle(color: AppColors.textLo, fontSize: 13)),
        ),
      ]),
    );
  }
}

class _TrialBanner extends StatelessWidget {
  const _TrialBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan),
      ),
      child: Row(children: const [
        Icon(Icons.timelapse, color: AppColors.cyan, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text('Trial sesi aktif — nikmati lagu ini sekarang.',
              style: TextStyle(color: AppColors.cyan, fontSize: 12.5)),
        ),
      ]),
    );
  }
}
