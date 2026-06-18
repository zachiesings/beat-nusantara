/// How a song becomes available. Note: NONE of these are FOMO/timed — locked
/// songs are unlocked by free progression (coins/level) or an OPTIONAL rewarded
/// ad that grants a session trial. Songs never disappear.
enum UnlockType { free, coins, level, sessionAd, comingSoon }

UnlockType _unlockFrom(String s) {
  switch (s) {
    case 'coins':
      return UnlockType.coins;
    case 'level':
      return UnlockType.level;
    case 'sessionAd':
      return UnlockType.sessionAd;
    case 'comingSoon':
      return UnlockType.comingSoon;
    default:
      return UnlockType.free;
  }
}

class Song {
  final String id;
  final String title;
  final String artistDisplayName;
  final String genre;
  final String regionTag;
  final String category; // library category bucket
  final int bpm;
  final int durationMs;
  final String? audioAssetPath; // null until a (placeholder/licensed) asset exists
  final String coverAssetPath;
  final List<String> availableDifficulties;
  final Map<String, String> chartPaths; // difficulty -> asset path
  final UnlockType unlockType;
  final int unlockCost; // coins or required level
  final int previewStartTimeMs;
  final bool playable; // has a real chart + audio bundled now

  Song({
    required this.id,
    required this.title,
    required this.artistDisplayName,
    required this.genre,
    required this.regionTag,
    required this.category,
    required this.bpm,
    required this.durationMs,
    required this.audioAssetPath,
    required this.coverAssetPath,
    required this.availableDifficulties,
    required this.chartPaths,
    required this.unlockType,
    required this.unlockCost,
    required this.previewStartTimeMs,
    required this.playable,
  });

  factory Song.fromJson(Map<String, dynamic> j) {
    final charts = <String, String>{};
    final cp = j['chartPaths'];
    if (cp is Map) {
      cp.forEach((k, v) => charts[k as String] = v as String);
    }
    return Song(
      id: j['id'] as String,
      title: j['title'] as String,
      artistDisplayName: (j['artistDisplayName'] ?? 'Licensed Artist') as String,
      genre: (j['genre'] ?? '') as String,
      regionTag: (j['regionTag'] ?? 'Nusantara') as String,
      category: (j['category'] ?? 'Untuk Kamu') as String,
      bpm: (j['bpm'] ?? 120) as int,
      durationMs: (j['durationMs'] ?? 0) as int,
      audioAssetPath: j['audioAssetPath'] as String?,
      coverAssetPath: (j['coverAssetPath'] ?? 'assets/images/cover_locked.png') as String,
      availableDifficulties:
          ((j['availableDifficulties'] ?? const []) as List).map((e) => e as String).toList(),
      chartPaths: charts,
      unlockType: _unlockFrom((j['unlockType'] ?? 'free') as String),
      unlockCost: (j['unlockCost'] ?? 0) as int,
      previewStartTimeMs: (j['previewStartTimeMs'] ?? 0) as int,
      playable: (j['playable'] ?? false) as bool,
    );
  }
}
