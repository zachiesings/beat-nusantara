import 'package:flutter/material.dart';
import '../state/game_state.dart';

/// Achievement-style missions (NO daily streaks, NO timers, NO punishment).
/// Each carries an icon, a coin reward, a done-check AND a 0..1 progress so the
/// Home cards can show cute progress bars. All computed from saved best-scores —
/// nothing extra to persist, nothing that can expire.
class Mission {
  final String id;
  final String title;
  final String hint;
  final IconData icon;
  final int reward;
  final bool Function(GameState s) done;
  final double Function(GameState s) progress;
  const Mission(this.id, this.title, this.hint, this.icon, this.reward, this.done, this.progress);
}

double _maxAcc(GameState s) =>
    s.bestScores.values.fold(0.0, (m, b) => b.accuracy > m ? b.accuracy : m);

int _nusantara(GameState s) {
  const ids = {'senja_jakarta', 'gamelan_pulse', 'koplo_neon'};
  final played = <String>{};
  for (final k in s.bestScores.keys) {
    final id = k.split('__').first;
    if (ids.contains(id)) played.add(id);
  }
  return played.length;
}

bool _anyFc(GameState s) => s.bestScores.values.any((b) => b.fullCombo);
bool _anyHard(GameState s) => s.bestScores.keys.any((k) => k.endsWith('__Hard'));

final missions = <Mission>[
  Mission('acc90', 'Akurasi 90%+', 'Capai akurasi 90% di lagu apa pun',
      Icons.center_focus_strong_rounded, 60,
      (s) => _maxAcc(s) >= 90, (s) => (_maxAcc(s) / 90).clamp(0.0, 1.0).toDouble()),
  Mission('fc', 'Full Combo', 'Selesaikan satu lagu tanpa Miss',
      Icons.bolt_rounded, 80,
      _anyFc, (s) => _anyFc(s) ? 1.0 : 0.0),
  Mission('nusantara3', 'Cinta Nusantara', 'Mainkan 3 lagu bertema Nusantara',
      Icons.favorite_rounded, 50,
      (s) => _nusantara(s) >= 3, (s) => (_nusantara(s) / 3).clamp(0.0, 1.0).toDouble()),
  Mission('hard', 'Naik Level', 'Tamatkan satu chart Hard',
      Icons.trending_up_rounded, 70,
      _anyHard, (s) => _anyHard(s) ? 1.0 : 0.0),
];
