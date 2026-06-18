import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/haptics.dart';
import '../../services/audio/audio_service.dart';
import '../../state/game_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_button.dart';

/// Latency calibration. A steady pulse plays; the player taps along. We measure
/// the average signed offset between taps and beats and suggest it as the
/// calibration value. A manual slider is also provided.
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});
  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen>
    with SingleTickerProviderStateMixin {
  static const int _beatMs = 600; // 100 BPM pulse
  final Stopwatch _sw = Stopwatch()..start();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _beatMs),
  )..repeat();

  final List<int> _offsets = [];
  late double _manual;
  int _lastBeatTick = -1;

  @override
  void initState() {
    super.initState();
    _manual = context.read<GameState>().calibrationMs;
    _pulse.addListener(_onPulse);
  }

  void _onPulse() {
    // play a tick sound once per cycle near its start
    final cycle = _sw.elapsedMilliseconds ~/ _beatMs;
    if (cycle != _lastBeatTick) {
      _lastBeatTick = cycle;
      context.read<AudioService>().playSfx('hit');
    }
    setState(() {});
  }

  void _tap() {
    final e = _sw.elapsedMilliseconds;
    final phase = e % _beatMs;
    final signed = phase > _beatMs / 2 ? phase - _beatMs : phase;
    Haptics.light();
    setState(() {
      _offsets.add(signed);
      if (_offsets.length > 12) _offsets.removeAt(0);
    });
  }

  double get _avg =>
      _offsets.isEmpty ? 0 : _offsets.reduce((a, b) => a + b) / _offsets.length;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.read<GameState>();
    final scale = 0.7 + 0.3 * (1 - _pulse.value);
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context)),
                const Text('Kalibrasi Audio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                    'Ketuk lingkaran tepat saat membesar & bunyi terdengar. '
                    'Kami hitung rata-rata selisihnya.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textLo)),
              ),
              const Spacer(),
              GestureDetector(
                onTapDown: (_) => _tap(),
                child: Container(
                  width: 220,
                  height: 220,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.glass),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, gradient: AppColors.brandGradient),
                      child: const Icon(Icons.touch_app, size: 56, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _offsets.isEmpty
                    ? 'Ketuk untuk mulai…'
                    : 'Rata-rata: ${_avg.toStringAsFixed(0)} ms (${_offsets.length} ketukan)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('Manual', style: TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('${_manual.toStringAsFixed(0)} ms',
                            style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700)),
                      ]),
                      Slider(
                        value: _manual.clamp(-300.0, 300.0).toDouble(),
                        min: -300,
                        max: 300,
                        onChanged: (v) => setState(() => _manual = v),
                      ),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _offsets.isEmpty
                                ? null
                                : () => setState(() => _manual = _avg),
                            child: const Text('Pakai hasil ketukan'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GradientButton(
                            label: 'Simpan',
                            height: 46,
                            onTap: () {
                              gs.setCalibration(_manual);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
