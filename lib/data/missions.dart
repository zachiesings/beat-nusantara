import '../state/game_state.dart';

/// Achievement-style missions (NO daily streaks, NO timers, NO punishment).
/// Each is computed from saved best-scores so there is nothing extra to persist
/// and nothing that can expire.
class Mission {
  final String id;
  final String title;
  final String hint;
  final bool Function(GameState s) done;
  const Mission(this.id, this.title, this.hint, this.done);
}

final missions = <Mission>[
  Mission('acc90', 'Akurasi 90%+', 'Capai akurasi 90% di lagu apa pun',
      (s) => s.bestScores.values.any((b) => b.accuracy >= 90)),
  Mission('fc', 'Full Combo', 'Selesaikan satu lagu tanpa Miss',
      (s) => s.bestScores.values.any((b) => b.fullCombo)),
  Mission('nusantara3', 'Cinta Nusantara', 'Mainkan 3 lagu bertema Nusantara',
      (s) => _nusantaraPlayed(s) >= 3),
  Mission('hard', 'Naik Level', 'Tamatkan satu chart Hard',
      (s) => s.bestScores.keys.any((k) => k.endsWith('__Hard'))),
];

int _nusantaraPlayed(GameState s) {
  // count distinct songIds with a saved score whose id hints Nusantara demo set
  const nusantara = {'senja_jakarta', 'gamelan_pulse', 'koplo_neon'};
  final played = <String>{};
  for (final k in s.bestScores.keys) {
    final id = k.split('__').first;
    if (nusantara.contains(id)) played.add(id);
  }
  return played.length;
}
