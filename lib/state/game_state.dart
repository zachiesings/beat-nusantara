import 'package:flutter/foundation.dart';
import '../core/haptics.dart';
import '../game/models/song.dart';
import '../game/scoring/judgment.dart';
import '../game/scoring/score_engine.dart';
import '../services/storage/storage_service.dart';

class BestScore {
  final int score;
  final String grade;
  final double accuracy;
  final bool fullCombo;
  BestScore(this.score, this.grade, this.accuracy, this.fullCombo);

  Map<String, dynamic> toJson() =>
      {'s': score, 'g': grade, 'a': accuracy, 'fc': fullCombo};
  factory BestScore.fromJson(Map<String, dynamic> j) => BestScore(
        (j['s'] ?? 0) as int,
        (j['g'] ?? 'D') as String,
        (j['a'] as num?)?.toDouble() ?? 0,
        (j['fc'] ?? false) as bool,
      );
}

/// Single source of truth for all persisted user state. Backed by
/// StorageService; notifies listeners (via provider) on every mutation.
class GameState extends ChangeNotifier {
  final StorageService storage;
  GameState(this.storage);

  // --- profile / progression ---
  String playerName = 'Pemain';
  int coins = 0;
  int xp = 0;

  // --- settings ---
  double calibrationMs = 0;
  double noteSpeed = 1.0; // 0.6 (slow) .. 1.8 (fast)
  bool reduceEffects = false;
  bool highContrast = false;
  bool largerHitZone = false;
  bool vibration = true;
  bool music = true;
  bool sfx = true;

  // --- cosmetics ---
  String laneSkin = 'neon';
  String hitEffect = 'spark';
  Set<String> cosmetics = {'neon', 'spark'};

  // --- catalog state ---
  Set<String> _unlocked = {};
  final Set<String> _sessionUnlocks = {}; // in-memory only (ad trials)
  Set<String> favorites = {};
  Map<String, BestScore> bestScores = {};

  bool onboardingDone = false;

  int get level => 1 + xp ~/ 500;
  int get xpIntoLevel => xp % 500;
  double get levelProgress => xpIntoLevel / 500.0;

  // -------------------------------------------------------------------------
  Future<void> load() async {
    playerName = storage.getString('playerName', 'Pemain');
    coins = storage.getInt('coins', 0);
    xp = storage.getInt('xp', 0);
    calibrationMs = storage.getDouble('calibrationMs', 0);
    noteSpeed = storage.getDouble('noteSpeed', 1.0);
    reduceEffects = storage.getBool('reduceEffects', false);
    highContrast = storage.getBool('highContrast', false);
    largerHitZone = storage.getBool('largerHitZone', false);
    vibration = storage.getBool('vibration', true);
    music = storage.getBool('music', true);
    sfx = storage.getBool('sfx', true);
    laneSkin = storage.getString('laneSkin', 'neon');
    hitEffect = storage.getString('hitEffect', 'spark');
    cosmetics = storage.getStringSet('cosmetics');
    if (cosmetics.isEmpty) cosmetics = {'neon', 'spark'};
    _unlocked = storage.getStringSet('unlocked');
    favorites = storage.getStringSet('favorites');
    onboardingDone = storage.getBool('onboardingDone', false);

    final raw = storage.getJson('bestScores');
    bestScores = raw.map((k, v) =>
        MapEntry(k, BestScore.fromJson(v as Map<String, dynamic>)));

    Haptics.enabled = vibration;
    notifyListeners();
  }

  // --- unlock logic (never FOMO; free progression + optional ad trials) ---
  bool isUnlocked(Song s) {
    if (s.unlockType == UnlockType.comingSoon) return false;
    if (s.unlockType == UnlockType.free) return true;
    if (_unlocked.contains(s.id)) return true;
    if (_sessionUnlocks.contains(s.id)) return true;
    if (s.unlockType == UnlockType.level && level >= s.unlockCost) return true;
    return false;
  }

  bool isSessionTrial(Song s) =>
      _sessionUnlocks.contains(s.id) && !_unlocked.contains(s.id);

  bool canAfford(Song s) => coins >= s.unlockCost;

  bool unlockWithCoins(Song s) {
    if (coins < s.unlockCost) return false;
    coins -= s.unlockCost;
    _unlocked.add(s.id);
    storage.setInt('coins', coins);
    storage.setStringSet('unlocked', _unlocked);
    notifyListeners();
    return true;
  }

  /// Grant a session-only trial (from an optional rewarded ad). Lost on restart;
  /// never sold, never timed-pressure.
  void grantSessionTrial(Song s) {
    _sessionUnlocks.add(s.id);
    notifyListeners();
  }

  // --- favorites ---
  void toggleFavorite(String id) {
    if (!favorites.remove(id)) favorites.add(id);
    storage.setStringSet('favorites', favorites);
    notifyListeners();
  }

  // --- results / economy ---
  String _key(String songId, String diff) => '${songId}__$diff';

  BestScore? best(String songId, String diff) => bestScores[_key(songId, diff)];

  void recordResult(String songId, String diff, ResultSummary r) {
    coins += r.coins;
    xp += r.xp;
    final k = _key(songId, diff);
    final prev = bestScores[k];
    if (prev == null || r.score > prev.score) {
      bestScores[k] =
          BestScore(r.score, r.grade.label, r.accuracy, r.fullCombo);
    }
    storage.setInt('coins', coins);
    storage.setInt('xp', xp);
    storage.setJson('bestScores',
        bestScores.map((key, v) => MapEntry(key, v.toJson())));
    notifyListeners();
  }

  void addCoins(int n) {
    coins += n;
    storage.setInt('coins', coins);
    notifyListeners();
  }

  // --- settings setters ---
  void setName(String v) {
    playerName = v.trim().isEmpty ? 'Pemain' : v.trim();
    storage.setString('playerName', playerName);
    notifyListeners();
  }

  void setCalibration(double v) {
    calibrationMs = v;
    storage.setDouble('calibrationMs', v);
    notifyListeners();
  }

  void setNoteSpeed(double v) {
    noteSpeed = v;
    storage.setDouble('noteSpeed', v);
    notifyListeners();
  }

  void setToggle(String key, bool v) {
    switch (key) {
      case 'reduceEffects':
        reduceEffects = v;
        storage.setBool('reduceEffects', v);
      case 'highContrast':
        highContrast = v;
        storage.setBool('highContrast', v);
      case 'largerHitZone':
        largerHitZone = v;
        storage.setBool('largerHitZone', v);
      case 'vibration':
        vibration = v;
        Haptics.enabled = v;
        storage.setBool('vibration', v);
      case 'music':
        music = v;
        storage.setBool('music', v);
      case 'sfx':
        sfx = v;
        storage.setBool('sfx', v);
    }
    notifyListeners();
  }

  void completeOnboarding() {
    onboardingDone = true;
    storage.setBool('onboardingDone', true);
    notifyListeners();
  }

  void selectCosmetic(String kind, String value) {
    if (kind == 'lane') laneSkin = value;
    if (kind == 'hit') hitEffect = value;
    storage.setString('laneSkin', laneSkin);
    storage.setString('hitEffect', hitEffect);
    notifyListeners();
  }

  void grantCosmetic(String id) {
    cosmetics.add(id);
    storage.setStringSet('cosmetics', cosmetics);
    notifyListeners();
  }
}
