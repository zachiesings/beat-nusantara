import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../game/models/song.dart';

/// Loads & holds the song manifest. Data-driven: add songs by editing
/// assets/song_manifest.json (+ chart/audio assets) — no code changes needed.
class SongCatalog {
  List<Song> songs = [];
  List<String> categories = [];

  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/song_manifest.json');
    final j = json.decode(raw) as Map<String, dynamic>;
    categories = ((j['categories'] ?? []) as List).map((e) => e as String).toList();
    songs = ((j['songs'] ?? []) as List)
        .map((e) => Song.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Song? byId(String id) {
    for (final s in songs) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<Song> get playable => songs.where((s) => s.playable).toList();

  List<Song> inCategory(String cat) =>
      songs.where((s) => s.category == cat).toList();

  /// "Untuk Kamu" = a friendly recommended mix: playable songs first, then a few
  /// affordable unlocks. Purely a convenience view (no time pressure).
  List<Song> recommended() {
    final play = playable;
    final rest = songs.where((s) => !s.playable).take(4);
    return [...play, ...rest];
  }
}
