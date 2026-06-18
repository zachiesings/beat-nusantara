import 'package:flutter_test/flutter_test.dart';
import 'package:beat_nusantara/game/scoring/judgment.dart';
import 'package:beat_nusantara/game/scoring/score_engine.dart';

void main() {
  group('ScoreBoard', () {
    test('perfect hit scores and builds combo', () {
      final b = ScoreBoard(10);
      b.register(Judgment.perfect);
      expect(b.score, greaterThan(0));
      expect(b.combo, 1);
      expect(b.perfect, 1);
      expect(b.accuracy, 100);
      expect(b.isFullCombo, true);
    });

    test('miss breaks combo and full-combo', () {
      final b = ScoreBoard(10);
      b.register(Judgment.perfect);
      b.register(Judgment.miss);
      expect(b.combo, 0);
      expect(b.isFullCombo, false);
      expect(b.miss, 1);
    });

    test('golden note doubles base score', () {
      final plain = ScoreBoard(1)..register(Judgment.perfect);
      final golden = ScoreBoard(1)..register(Judgment.perfect, golden: true);
      expect(golden.score, greaterThan(plain.score));
    });

    test('grade reflects accuracy + full combo', () {
      final b = ScoreBoard(3);
      b.register(Judgment.perfect);
      b.register(Judgment.perfect);
      b.register(Judgment.perfect);
      expect(b.grade, Grade.sss);
    });

    test('hp drops on misses and can hit fail threshold', () {
      final b = ScoreBoard(100);
      for (var i = 0; i < 20; i++) {
        b.register(Judgment.miss);
      }
      expect(b.hp, 0);
    });

    test('summary computes coins/xp and cleared flag', () {
      final b = ScoreBoard(5);
      b.register(Judgment.perfect);
      final s = b.summary(cleared: true);
      expect(s.cleared, true);
      expect(s.xp, greaterThan(0));
      expect(s.grade.label.isNotEmpty, true);
    });
  });

  group('GradeX', () {
    test('thresholds', () {
      expect(GradeX.fromAccuracy(99.5, fullCombo: true), Grade.sss);
      expect(GradeX.fromAccuracy(99.5, fullCombo: false), Grade.ss);
      expect(GradeX.fromAccuracy(50, fullCombo: false), Grade.d);
    });
  });
}
