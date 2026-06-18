import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../game/models/song.dart';
import '../state/game_state.dart';

/// Premium song card: cover art, title/artist, BPM + genre, lock state with a
/// CLEAR, non-FOMO unlock condition, best grade badge and favorite toggle.
class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final bool compact;
  const SongCard({super.key, required this.song, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final unlocked = gs.isUnlocked(song);
    final best = song.availableDifficulties.isNotEmpty
        ? gs.best(song.id, song.availableDifficulties.first)
        : null;
    final w = compact ? 156.0 : double.infinity;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
          color: AppColors.surface.withValues(alpha: 0.55),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: compact ? 1.4 : 2.6,
                  child: Image.asset(song.coverAssetPath,
                      fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                    return const ColoredBox(color: AppColors.surface);
                  }),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.ink.withValues(alpha: 0.85)],
                      ),
                    ),
                  ),
                ),
                if (song.playable)
                  const Positioned(
                      top: 8, left: 8, child: _Tag('DEMO', AppColors.cyan)),
                if (!unlocked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock, size: 16, color: AppColors.textLo),
                    ),
                  ),
                if (best != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _GradeBadge(best.grade),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textHi)),
                  const SizedBox(height: 2),
                  Text(song.artistDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Pill('${song.bpm} BPM'),
                      const SizedBox(width: 6),
                      Flexible(child: _Pill(song.genre)),
                      const Spacer(),
                      _unlockHint(gs),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unlockHint(GameState gs) {
    if (gs.isUnlocked(song)) {
      if (gs.isSessionTrial(song)) {
        return const Icon(Icons.timelapse, size: 16, color: AppColors.cyan);
      }
      return const Icon(Icons.play_circle_fill, size: 18, color: AppColors.teal);
    }
    final (icon, text, color) = switch (song.unlockType) {
      UnlockType.coins => (Icons.monetization_on, '${song.unlockCost}', AppColors.gold),
      UnlockType.level => (Icons.military_tech, 'Lv${song.unlockCost}', AppColors.violet),
      UnlockType.comingSoon => (Icons.schedule, 'Segera', AppColors.textLo),
      _ => (Icons.lock, '', AppColors.textLo),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      if (text.isNotEmpty) ...[
        const SizedBox(width: 3),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    ]);
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: AppColors.textHi)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  final String grade;
  const _GradeBadge(this.grade);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold),
      ),
      child: Text(grade,
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.gold)),
    );
  }
}
