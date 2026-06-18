import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../game/chart_loader/chart_loader.dart';
import '../../game/engine/game_engine.dart';
import '../../game/rendering/note_painter.dart';
import '../gameplay/game_hud.dart';

/// A FROZEN, deterministic gameplay frame for App-Store screenshots. Uses the
/// REAL playfield renderer (`NotePainter`) and the REAL `GameHud` widget — only
/// the clock is fixed and HUD numbers are preset. Not a mock: same components
/// the live game draws.
class ScreenshotGameplay extends StatefulWidget {
  const ScreenshotGameplay({super.key});
  @override
  State<ScreenshotGameplay> createState() => _ScreenshotGameplayState();
}

class _ScreenshotGameplayState extends State<ScreenshotGameplay> {
  GameEngine? _engine;
  final _repaint = ValueNotifier<int>(0); // never changes → static frame
  static const _frozenMs = 14000; // a dense moment in the chart

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chart = await ChartLoader.load('assets/charts/koplo_neon__expert.json');
    if (chart == null || !mounted) return;
    final e = GameEngine(chart)..songTimeMs = _frozenMs;
    setState(() => _engine = e);
  }

  @override
  void dispose() {
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = _engine;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: e == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
          : Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: NotePainter(
                      engine: e,
                      // wider approach window → more notes on screen, prettier still frame
                      approachMs: 2400,
                      laneCount: e.laneCount,
                      laneFlash: const {2: _frozenMs}, // glow one lane like a fresh hit
                      laneMiss: const {},
                      reduceEffects: false,
                      highContrast: false,
                      repaint: _repaint,
                    ),
                  ),
                ),
                const SafeArea(
                  child: GameHud(
                    title: 'Koplo Neon',
                    difficulty: 'Expert',
                    mode: 'Speed',
                    score: 742500,
                    accuracy: 98.7,
                    combo: 188,
                    hp: 0.86,
                    fever: 1.0,
                    feverActive: true,
                    progress: 0.58,
                  ),
                ),
                // a frozen judgment flourish above the hit line
                _judgment(context),
              ],
            ),
    );
  }

  Widget _judgment(BuildContext context) {
    final hitY = MediaQuery.of(context).size.height * (1 - K.hitLineFromBottom);
    return Positioned(
      top: hitY - 96,
      left: 0,
      right: 0,
      child: const IgnorePointer(
        child: Center(
          child: Text(
            'PERFECT',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
              shadows: [Shadow(color: AppColors.gold, blurRadius: 14)],
            ),
          ),
        ),
      ),
    );
  }
}
