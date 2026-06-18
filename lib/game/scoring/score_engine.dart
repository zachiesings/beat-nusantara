import '../../core/constants.dart';
import 'judgment.dart';

/// Running scoreboard for one play session. Pure logic, no Flutter — easy to
/// unit-test. Tracks score, combo, accuracy, HP and exposes a final summary.
class ScoreBoard {
  final int totalNotes;
  ScoreBoard(this.totalNotes);

  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int perfect = 0;
  int great = 0;
  int good = 0;
  int miss = 0;
  double hp = K.hpStart;
  bool _broken = false; // any miss/early-release → not a full combo

  int get judged => perfect + great + good + miss;

  /// Combo multiplier grows every 10 combo, capped at 2.0×.
  double get comboMult {
    final m = 1.0 + (combo ~/ 10) * 0.1;
    return m > 2.0 ? 2.0 : m;
  }

  double get accuracy {
    if (judged == 0) return 0;
    final w = perfect * 1.0 + great * 0.66 + good * 0.33;
    return (w / judged) * 100.0;
  }

  bool get isFullCombo => !_broken && miss == 0 && judged > 0;

  Grade get grade => GradeX.fromAccuracy(accuracy, fullCombo: isFullCombo);

  /// Register one judgment. [golden] doubles the base; [feverMult] applies the
  /// active fever multiplier (1.0 normally, 2.0 in fever).
  void register(Judgment j, {bool golden = false, double feverMult = 1.0}) {
    switch (j) {
      case Judgment.miss:
        miss++;
        combo = 0;
        _broken = true;
        hp += K.hpMiss;
      case Judgment.good:
        good++;
        _bump(K.hpGood);
      case Judgment.great:
        great++;
        _bump(K.hpGreat);
      case Judgment.perfect:
        perfect++;
        _bump(K.hpPerfect);
    }
    if (j != Judgment.miss) {
      final base = j.base * (golden ? 2 : 1);
      score += (base * comboMult * feverMult).round();
    }
    if (hp < 0) hp = 0;
    if (hp > K.hpMax) hp = K.hpMax;
  }

  void _bump(double hpDelta) {
    combo++;
    if (combo > maxCombo) maxCombo = combo;
    hp += hpDelta;
  }

  void revive() {
    hp = K.reviveHpRestore.toDouble();
  }

  ResultSummary summary({required bool cleared}) {
    final coins = (score / 1200).round() + perfect ~/ 4 + (isFullCombo ? 25 : 0);
    final xp = judged + maxCombo + (cleared ? 50 : 0);
    return ResultSummary(
      score: score,
      maxCombo: maxCombo,
      accuracy: accuracy,
      grade: grade,
      perfect: perfect,
      great: great,
      good: good,
      miss: miss,
      fullCombo: isFullCombo,
      cleared: cleared,
      coins: coins,
      xp: xp,
    );
  }
}

class ResultSummary {
  final int score;
  final int maxCombo;
  final double accuracy;
  final Grade grade;
  final int perfect, great, good, miss;
  final bool fullCombo;
  final bool cleared;
  final int coins;
  final int xp;

  ResultSummary({
    required this.score,
    required this.maxCombo,
    required this.accuracy,
    required this.grade,
    required this.perfect,
    required this.great,
    required this.good,
    required this.miss,
    required this.fullCombo,
    required this.cleared,
    required this.coins,
    required this.xp,
  });
}
