import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum Judgment { perfect, great, good, miss }

extension JudgmentX on Judgment {
  String get label => switch (this) {
        Judgment.perfect => 'PERFECT',
        Judgment.great => 'GREAT',
        Judgment.good => 'GOOD',
        Judgment.miss => 'MISS',
      };

  String get labelId => switch (this) {
        Judgment.perfect => 'PERFECT',
        Judgment.great => 'HEBAT',
        Judgment.good => 'OKE',
        Judgment.miss => 'LEWAT',
      };

  Color get color => switch (this) {
        Judgment.perfect => AppColors.gold,
        Judgment.great => AppColors.cyan,
        Judgment.good => AppColors.teal,
        Judgment.miss => AppColors.danger,
      };

  /// Accuracy weight (1.0 = perfect).
  double get weight => switch (this) {
        Judgment.perfect => 1.0,
        Judgment.great => 0.66,
        Judgment.good => 0.33,
        Judgment.miss => 0.0,
      };

  /// Base score before combo/fever multipliers.
  int get base => switch (this) {
        Judgment.perfect => 300,
        Judgment.great => 200,
        Judgment.good => 100,
        Judgment.miss => 0,
      };
}

enum Grade { sss, ss, s, a, b, c, d }

extension GradeX on Grade {
  String get label => switch (this) {
        Grade.sss => 'SSS',
        Grade.ss => 'SS',
        Grade.s => 'S',
        Grade.a => 'A',
        Grade.b => 'B',
        Grade.c => 'C',
        Grade.d => 'D',
      };

  Color get color => switch (this) {
        Grade.sss => AppColors.gold,
        Grade.ss => AppColors.pink,
        Grade.s => AppColors.cyan,
        Grade.a => AppColors.teal,
        Grade.b => AppColors.violet,
        _ => AppColors.textLo,
      };

  static Grade fromAccuracy(double acc, {required bool fullCombo}) {
    if (acc >= 99.0 && fullCombo) return Grade.sss;
    if (acc >= 96.0) return Grade.ss;
    if (acc >= 92.0) return Grade.s;
    if (acc >= 85.0) return Grade.a;
    if (acc >= 75.0) return Grade.b;
    if (acc >= 60.0) return Grade.c;
    return Grade.d;
  }
}
