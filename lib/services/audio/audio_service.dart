import 'package:audioplayers/audioplayers.dart';

/// Wraps audioplayers with two channels: one for the song, one for short SFX.
/// Every call is wrapped so a missing/locked asset can NEVER crash gameplay —
/// the game runs off its own Stopwatch clock, audio is "best effort" on top.
class AudioService {
  final AudioPlayer _music = AudioPlayer(playerId: 'music');
  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx');

  bool musicEnabled = true;
  bool sfxEnabled = true;
  double musicVolume = 0.9;

  /// audioplayers' AssetSource is relative to the `assets/` root, so strip it.
  String _src(String assetPath) =>
      assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;

  Future<void> playSong(String? assetPath, {int startMs = 0}) async {
    if (assetPath == null || !musicEnabled) return;
    try {
      await _music.stop();
      await _music.setVolume(musicVolume);
      await _music.setReleaseMode(ReleaseMode.stop);
      await _music.play(AssetSource(_src(assetPath)));
      if (startMs > 0) {
        await _music.seek(Duration(milliseconds: startMs));
      }
    } catch (_) {/* silent: gameplay continues without audio */}
  }

  Future<void> pauseSong() async {
    try {
      await _music.pause();
    } catch (_) {}
  }

  Future<void> resumeSong() async {
    try {
      await _music.resume();
    } catch (_) {}
  }

  Future<void> stopSong() async {
    try {
      await _music.stop();
    } catch (_) {}
  }

  Future<void> playSfx(String name) async {
    if (!sfxEnabled) return;
    try {
      await _sfx.play(AssetSource('audio/sfx/$name.wav'), volume: 0.8);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _music.dispose();
    await _sfx.dispose();
  }
}
