import 'package:audioplayers/audioplayers.dart';

/// Wraps audioplayers with two channels: one for the song, one for short SFX.
/// Every call is wrapped so a missing/locked asset can NEVER crash gameplay —
/// the game runs off its own Stopwatch clock, audio is "best effort" on top.
class AudioService {
  // Lazily created — constructing AudioService no longer touches the audio plugin
  // (so it's safe in tests / screenshot capture; audio only inits on first play).
  AudioPlayer? _musicP;
  AudioPlayer? _sfxP;
  AudioPlayer? _bgmP; // soft looping menu music
  AudioPlayer get _music => _musicP ??= AudioPlayer(playerId: 'music');
  AudioPlayer get _sfx => _sfxP ??= AudioPlayer(playerId: 'sfx');
  AudioPlayer get _bgm => _bgmP ??= AudioPlayer(playerId: 'bgm');

  bool musicEnabled = true;
  bool sfxEnabled = true;
  double musicVolume = 0.9;
  bool _bgmOn = false;

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

  // ---- soft looping menu music (separate channel from the in-game song) ----
  Future<void> startMenuMusic() async {
    if (!musicEnabled || _bgmOn) return;
    try {
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.setVolume(0.45);
      await _bgm.play(AssetSource('audio/bgm/menu_loop.wav'));
      _bgmOn = true;
    } catch (_) {}
  }

  Future<void> stopMenuMusic() async {
    _bgmOn = false;
    try {
      await _bgmP?.stop();
    } catch (_) {}
  }

  Future<void> pauseMenuMusic() async {
    try {
      await _bgmP?.pause();
    } catch (_) {}
  }

  Future<void> resumeMenuMusic() async {
    if (!musicEnabled) return;
    try {
      if (_bgmOn) {
        await _bgm.resume();
      } else {
        await startMenuMusic();
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _musicP?.dispose();
    await _sfxP?.dispose();
    await _bgmP?.dispose();
  }
}
