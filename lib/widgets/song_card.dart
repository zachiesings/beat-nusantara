import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../game/models/song.dart';
import '../state/game_state.dart';
import 'bouncy.dart';
import 'holo.dart';
import 'shapes.dart';
import 'soft_card.dart';

/// Collectible, premium song card. Two layouts:
///  - compact (vertical poster) → horizontal scrollers
///  - list (horizontal) → library lists
/// Each card carries its song's own accent color (identity), a glossy cover,
/// floating badges, favorite heart, grade badge, and a clear non-FOMO lock state.
class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final bool compact;
  const SongCard({super.key, required this.song, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final unlocked = gs.isUnlocked(song);
    final accent = AppColors.moodFor(song.category); // genre-mood identity
    final best = song.availableDifficulties.isNotEmpty
        ? gs.best(song.id, song.availableDifficulties.first)
        : null;
    return compact
        ? _compact(context, gs, accent, unlocked, best)
        : _list(context, gs, accent, unlocked, best);
  }

  // ---------- vertical poster ----------
  Widget _compact(BuildContext c, GameState gs, Color accent, bool unlocked, best) {
    return Bouncy(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          boxShadow: AppShadows.glow(accent, blur: 22, y: 10, a: 0.32),
          color: AppColors.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cover(accent, unlocked, best, height: 132),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  Text(song.artistDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textLo, fontSize: 11.5)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _pill('${song.bpm} BPM', accent),
                    const SizedBox(width: 6),
                    _unlockHint(gs, accent),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- horizontal list card ----------
  Widget _list(BuildContext c, GameState gs, Color accent, bool unlocked, best) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        onTap: onTap,
        accent: accent,
        glowStrength: 0.26,
        padding: const EdgeInsets.all(10),
        radius: AppRadius.md,
        child: Row(children: [
          SizedBox(
            width: 88,
            height: 88,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: _cover(accent, unlocked, best, height: 88, thumb: true),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                  ),
                  Icon(gs.favorites.contains(song.id) ? Icons.favorite : Icons.favorite_border,
                      size: 18, color: AppColors.pink),
                ]),
                Text(song.artistDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textLo, fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: [
                  _pill('${song.bpm} BPM', accent),
                  const SizedBox(width: 6),
                  Flexible(child: _pill(song.genre, accent, faint: true)),
                  const Spacer(),
                  _unlockHint(gs, accent),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ---------- cover with overlays ----------
  Widget _cover(Color accent, bool unlocked, best, {required double height, bool thumb = false}) {
    return Stack(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: song.playable
              ? HoloSheen(
                  radius: 0,
                  child: Image.asset(song.coverAssetPath, fit: BoxFit.cover, width: double.infinity,
                      errorBuilder: (_, __, ___) => ColoredBox(color: accent.withValues(alpha: 0.4))))
              : Image.asset(song.coverAssetPath, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(color: accent.withValues(alpha: 0.4))),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent.withValues(alpha: 0.0), AppColors.ink.withValues(alpha: thumb ? 0.4 : 0.8)],
              ),
            ),
          ),
        ),
        if (song.playable && !thumb)
          const Positioned(
              top: 10, left: 8, child: Sticker(text: 'DEMO', icon: Icons.bolt_rounded, gradient: AppGradients.ocean)),
        if (best != null)
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.goldRush,
                boxShadow: AppShadows.glow(AppColors.gold, blur: 12, y: 2, a: 0.6),
              ),
              child: Text(best.grade,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white)),
            ),
          ),
        if (!unlocked)
          Positioned.fill(
            child: ClipRect(
              child: Container(
                color: AppColors.ink.withValues(alpha: 0.32),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Icon(Icons.lock, size: 16, color: AppColors.textHi),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _pill(String text, Color accent, {bool faint = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: faint ? AppColors.glass : accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: faint ? AppColors.glassBorder : accent.withValues(alpha: 0.4)),
        ),
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: faint ? AppColors.textLo : accent)),
      );

  Widget _unlockHint(GameState gs, Color accent) {
    if (gs.isUnlocked(song)) {
      if (gs.isSessionTrial(song)) {
        return const Icon(Icons.timelapse, size: 17, color: AppColors.cyan);
      }
      return Icon(Icons.play_circle_fill, size: 19, color: accent);
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
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    ]);
  }
}
