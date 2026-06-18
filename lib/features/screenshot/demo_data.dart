import '../../data/song_catalog.dart';
import '../../game/scoring/judgment.dart';
import '../../game/scoring/score_engine.dart';
import '../../services/storage/storage_service.dart';
import '../../state/game_state.dart';

/// In-memory storage so demo/screenshot mode NEVER reads or writes the real
/// player's SharedPreferences. Overrides every accessor with a Map.
class MemoryStorageService extends StorageService {
  final Map<String, Object?> _m = {};

  @override
  Future<void> init() async {}

  @override
  String getString(String k, String def) => (_m[k] as String?) ?? def;
  @override
  Future<void> setString(String k, String v) async => _m[k] = v;

  @override
  bool getBool(String k, bool def) => (_m[k] as bool?) ?? def;
  @override
  Future<void> setBool(String k, bool v) async => _m[k] = v;

  @override
  int getInt(String k, int def) => (_m[k] as int?) ?? def;
  @override
  Future<void> setInt(String k, int v) async => _m[k] = v;

  @override
  double getDouble(String k, double def) => (_m[k] as double?) ?? def;
  @override
  Future<void> setDouble(String k, double v) async => _m[k] = v;

  @override
  Set<String> getStringSet(String k) =>
      (_m[k] as Set<String>?) ?? <String>{};
  @override
  Future<void> setStringSet(String k, Set<String> v) async => _m[k] = v;

  @override
  Map<String, dynamic> getJson(String k) =>
      (_m[k] as Map<String, dynamic>?) ?? {};
  @override
  Future<void> setJson(String k, Map<String, dynamic> v) async => _m[k] = v;
}

/// A fully-populated, deterministic GameState for App-Store-ready screenshots.
/// All data is fictional and stable run-to-run.
GameState buildDemoGameState(SongCatalog catalog) {
  final gs = GameState(MemoryStorageService());
  gs.playerName = 'Andini';
  gs.coins = 1480;
  gs.xp = 3260; // → Level 7
  gs.noteSpeed = 1.1;
  gs.laneSkin = 'sunset';
  gs.hitEffect = 'star';
  gs.cosmetics = {'neon', 'spark', 'sunset', 'ocean', 'star', 'bloom'};
  gs.favorites = {'senja_jakarta', 'koplo_neon', 'tokyo_kilat'};
  gs.onboardingDone = true;
  gs.bestScores = {
    'koplo_neon__Expert': BestScore(942300, 'SSS', 98.64, true),
    'koplo_neon__Hard': BestScore(710300, 'SS', 96.0, true),
    'gamelan_pulse__Hard': BestScore(615400, 'S', 94.2, false),
    'senja_jakarta__Normal': BestScore(498200, 'SS', 97.1, false),
  };
  // session trials so a couple premium tracks read as unlocked in the library
  for (final id in ['tokyo_kilat', 'hujan_neon']) {
    final s = catalog.byId(id);
    if (s != null) gs.grantSessionTrial(s);
  }
  return gs;
}

/// A polished result summary for the result screenshot.
ResultSummary demoResult() => ResultSummary(
      score: 942300,
      maxCombo: 410,
      accuracy: 98.64,
      grade: Grade.sss,
      perfect: 388,
      great: 18,
      good: 4,
      miss: 0,
      fullCombo: true,
      cleared: true,
      coins: 320,
      xp: 540,
    );
