import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../services/audio/audio_service.dart';
import '../../state/game_state.dart';
import '../../widgets/bouncy.dart';
import '../../widgets/soft_card.dart';
import '../screenshot/screenshot_gallery.dart';
import 'calibration_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final audio = context.read<AudioService>();

    return Scaffold(
      body: NeonBackground(
        motif: BatikMotif.parang,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Row(children: [
                Bouncy(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back_rounded))),
                Text('Pengaturan', style: AppText.title.copyWith(fontSize: 20)),
              ]),
              const SizedBox(height: 8),
              _group('Profil', [
                ListTile(
                  leading: const Icon(Icons.person, color: AppColors.cyan),
                  title: const Text('Nama pemain'),
                  subtitle: Text(gs.playerName),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () => _editName(context, gs),
                ),
              ]),
              _group('Gameplay', [
                ListTile(
                  leading: const Icon(Icons.tune, color: AppColors.pink),
                  title: const Text('Kalibrasi audio'),
                  subtitle: Text('${gs.calibrationMs.toStringAsFixed(0)} ms'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CalibrationScreen())),
                ),
                _sliderTile(
                  'Kecepatan not',
                  '${gs.noteSpeed.toStringAsFixed(2)}×',
                  gs.noteSpeed,
                  0.6,
                  1.8,
                  (v) => gs.setNoteSpeed(v),
                ),
              ]),
              _group('Aksesibilitas', [
                _switch('Kurangi efek visual', gs.reduceEffects,
                    (v) => gs.setToggle('reduceEffects', v)),
                _switch('Kontras tinggi', gs.highContrast,
                    (v) => gs.setToggle('highContrast', v)),
                _switch('Zona ketuk lebih besar', gs.largerHitZone,
                    (v) => gs.setToggle('largerHitZone', v)),
                _switch('Getaran (haptic)', gs.vibration,
                    (v) => gs.setToggle('vibration', v)),
              ]),
              _group('Audio', [
                _switch('Musik', gs.music, (v) {
                  gs.setToggle('music', v);
                  audio.musicEnabled = v;
                  if (v) {
                    audio.startMenuMusic();
                  } else {
                    audio.stopMenuMusic();
                  }
                }),
                _switch('Efek suara', gs.sfx, (v) {
                  gs.setToggle('sfx', v);
                  audio.sfxEnabled = v;
                }),
              ]),
              if (kDebugMode)
                _group('Developer', [
                  ListTile(
                    leading: const Icon(Icons.photo_camera, color: AppColors.gold),
                    title: const Text('Mode Screenshot'),
                    subtitle: const Text('Layar demo deterministik untuk App Store'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ScreenshotGallery())),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _group(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Text(title.toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.textLo, fontSize: 12, letterSpacing: 1)),
            ),
            SoftCard(
                accent: AppColors.indigo,
                glowStrength: 0.16,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: children)),
          ],
        ),
      );

  Widget _switch(String label, bool v, ValueChanged<bool> onChanged) => SwitchListTile(
        title: Text(label),
        value: v,
        onChanged: onChanged,
      );

  Widget _sliderTile(String label, String value, double v, double min, double max,
          ValueChanged<double> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(label),
              const Spacer(),
              Text(value, style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700)),
            ]),
            Slider(value: v, min: min, max: max, onChanged: onChanged),
          ],
        ),
      );

  void _editName(BuildContext context, GameState gs) {
    final ctrl = TextEditingController(text: gs.playerName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Nama pemain'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              gs.setName(ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
