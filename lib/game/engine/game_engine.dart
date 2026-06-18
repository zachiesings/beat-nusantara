import '../../core/constants.dart';
import '../models/chart.dart';
import '../models/note.dart';
import '../scoring/judgment.dart';
import '../scoring/score_engine.dart';

/// The "conductor". Owns the authoritative song clock comparison and all input
/// judging. The screen feeds it a monotonic clock each frame via [update]; the
/// engine is otherwise framework-agnostic (no Flutter import) so it stays testable.
///
/// Timing model: the screen's Stopwatch is the master clock (audio is started
/// alongside but never used for sample-accurate timing — that avoids jitter from
/// platform audio position callbacks). [calibrationMs] shifts the judge window
/// to compensate for output latency; players tune it on the Calibration screen.
class GameEngine {
  final Chart chart;
  final int laneCount;
  final ScoreBoard board;
  double calibrationMs;

  GameEngine(this.chart, {this.calibrationMs = 0})
      : laneCount = chart.laneCount,
        board = ScoreBoard(chart.noteCount) {
    // charts are cached by ChartLoader → reset per-play mutable note state so
    // replays don't see notes still flagged as judged from the last run.
    for (final n in chart.notes) {
      n.judged = false;
      n.holding = false;
      n.holdComplete = false;
      n.judgedAt = null;
    }
    _lastNoteMs = chart.notes.isEmpty
        ? 0
        : chart.notes
            .map((n) => n.tail)
            .reduce((a, b) => a > b ? a : b);
  }

  int songTimeMs = 0;
  late final int _lastNoteMs;

  bool paused = false;
  bool finished = false;
  bool cleared = false;
  bool awaitingRevive = false;
  bool reviveUsed = false;

  // fever
  double fever = 0;
  bool feverActive = false;
  int _feverEndsAt = 0;

  // last judgment (for HUD popup)
  Judgment? lastJudgment;
  int lastJudgmentAt = -99999;
  int lastJudgmentLane = 0;

  // callbacks wired by the screen
  void Function(Judgment j, int lane)? onJudge;
  void Function()? onFail;
  void Function()? onFinish;

  int get effectiveNow => (songTimeMs - calibrationMs - chart.offsetMs).round();
  double get feverMult => feverActive ? 2.0 : 1.0;
  double get progress => _lastNoteMs == 0
      ? 0.0
      : (effectiveNow / (_lastNoteMs + 600)).clamp(0.0, 1.0).toDouble();

  /// Advance the simulation to clock time [clockMs].
  void update(int clockMs) {
    if (paused || finished) return;
    songTimeMs = clockMs;
    final now = effectiveNow;

    // fever timeout
    if (feverActive && songTimeMs >= _feverEndsAt) {
      feverActive = false;
      fever = 0;
    }

    for (final n in chart.notes) {
      if (n.judged) {
        // auto-complete holds once their tail passes
        if (n.holding && now >= n.tail) {
          n.holding = false;
          n.holdComplete = true;
          board.score += 150; // tail completion bonus
        }
        continue;
      }
      // note fully passed the latest "good" window without being hit → miss
      if (now - n.startTimeMs > K.wGood) {
        n.judged = true;
        board.register(Judgment.miss);
        _addFever(K.feverOnMiss);
        _emit(Judgment.miss, n.lane);
        _checkFail();
      }
    }

    if (!finished && now > _lastNoteMs + 600) {
      _finish(cleared: !awaitingRevive);
    }
  }

  /// Player pressed [lane]. Judges the nearest eligible note in that lane.
  void pressLane(int lane) {
    if (paused || finished) return;
    final now = effectiveNow;
    Note? best;
    int bestAbs = K.wGood + 1;
    for (final n in chart.notes) {
      if (n.judged || n.lane != lane) continue;
      final d = (now - n.startTimeMs).abs();
      if (d <= K.wGood && d < bestAbs) {
        bestAbs = d;
        best = n;
      }
    }
    if (best == null) return; // forgiving: empty taps cost nothing

    final j = bestAbs <= K.wPerfect
        ? Judgment.perfect
        : bestAbs <= K.wGreat
            ? Judgment.great
            : Judgment.good;

    best.judged = true;
    best.judgedAt = now;
    final golden = best.type == NoteType.golden;
    board.register(j, golden: golden, feverMult: feverMult);

    if (best.isHold) best.holding = true;
    if (best.type == NoteType.fever) {
      _addFever(0.34);
    } else if (j != Judgment.miss) {
      _addFever(K.feverPerHit);
    }
    _emit(j, lane);
  }

  /// Reserved for full hold-release detection (Phase 2). Holds currently
  /// auto-complete at their tail, so release is a no-op today.
  void releaseLane(int lane) {}

  void _addFever(double d) {
    if (feverActive) return;
    fever = (fever + d).clamp(0.0, 1.0).toDouble();
    if (fever >= 1.0) {
      feverActive = true;
      _feverEndsAt = songTimeMs + K.feverDurationMs;
    }
  }

  void _emit(Judgment j, int lane) {
    lastJudgment = j;
    lastJudgmentAt = songTimeMs;
    lastJudgmentLane = lane;
    onJudge?.call(j, lane);
  }

  void _checkFail() {
    if (board.hp <= 0 && !awaitingRevive && !finished) {
      awaitingRevive = true;
      paused = true;
      onFail?.call();
    }
  }

  void revive() {
    board.revive();
    awaitingRevive = false;
    reviveUsed = true;
    paused = false;
  }

  /// Player declined revive → end the run as a fail.
  void giveUp() => _finish(cleared: false);

  void _finish({required bool cleared}) {
    if (finished) return;
    finished = true;
    this.cleared = cleared;
    paused = true;
    onFinish?.call();
  }

  ResultSummary buildResult() => board.summary(cleared: cleared);
}
