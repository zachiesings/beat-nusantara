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
  gs.coins = 2450; // premium-feeling balance, affordable unlocks visible
  gs.xp = 3450; // → Level 7, 90% to next (near-full ring on Profile)
  gs.noteSpeed = 1.1;
  gs.laneSkin = 'sunset'; // equipped → "Dipakai" state
  gs.hitEffect = 'star'; // equipped
  // owned vs locked is intentional: bloom (coins) + batik (ad) stay locked so the
  // Reward shot shows all three states — equipped / buy / watch-ad.
  gs.cosmetics = {'neon', 'spark', 'sunset', 'ocean', 'star'};
  gs.favorites = {'senja_jakarta', 'koplo_neon', 'gamelan_pulse', 'tokyo_kilat'};
  gs.onboardingDone = true;
  // rich, accomplished score wall → grade badges everywhere + all missions done.
  // koplo Expert continues from the Gameplay/Result shots for a cohesive story.
  gs.bestScores = {
    'koplo_neon__Expert': BestScore(1180400, 'SSS', 98.9, true),
    'koplo_neon__Hard': BestScore(942300, 'SS', 96.5, true),
    'gamelan_pulse__Hard': BestScore(705300, 'S', 94.8, false),
    'senja_jakarta__Normal': BestScore(612400, 'SS', 97.4, false),
    'gamelan_pulse__Normal': BestScore(548900, 'S', 93.2, false),
  };
  // session trials so a couple premium tracks read as unlocked in the library
  for (final id in ['tokyo_kilat', 'hujan_neon']) {
    final s = catalog.byId(id);
    if (s != null) gs.grantSessionTrial(s);
  }
  return gs;
}

/// A polished result summary for the Result screenshot — a clean Full-Combo SSS
/// run of "Koplo Neon (Expert)", numbers consistent with a 216-note chart.
ResultSummary demoResult() => ResultSummary(
      score: 1180400,
      maxCombo: 216,
      accuracy: 98.90,
      grade: Grade.sss,
      perfect: 196,
      great: 17,
      good: 3,
      miss: 0,
      fullCombo: true,
      cleared: true,
      coins: 340,
      xp: 560,
    );
