import 'note.dart';

/// A single playable beatmap for one (song, difficulty).
class Chart {
  final String songId;
  final String difficulty;
  final int bpm;
  final int offsetMs;
  final List<Note> notes;

  Chart({
    required this.songId,
    required this.difficulty,
    required this.bpm,
    required this.offsetMs,
    required this.notes,
  });

  int get noteCount => notes.length;

  /// Number of lanes the chart actually uses (max lane index + 1).
  int get laneCount {
    var max = 3;
    for (final n in notes) {
      if (n.lane > max) max = n.lane;
    }
    return max + 1;
  }

  factory Chart.fromJson(Map<String, dynamic> j) => Chart(
        songId: (j['songId'] ?? '') as String,
        difficulty: (j['difficulty'] ?? 'Normal') as String,
        bpm: (j['bpm'] ?? 120) as int,
        offsetMs: (j['offsetMs'] ?? 0) as int,
        notes: ((j['notes'] ?? []) as List)
            .map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
