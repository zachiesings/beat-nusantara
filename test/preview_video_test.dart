// Renders a ~15s App Store PREVIEW reel from the REAL gameplay (note painter +
// HUD), frame by frame, at 886x1920 (an accepted App-preview size). The
// preview.yml workflow encodes the frames + the song into an .mp4.
//
// Not a mock: it advances the real GameEngine clock and uses the real NotePainter
// + GameHud, simulating hits so bursts/dissolve/FEVER show.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:beat_nusantara/app/theme.dart';
import 'package:beat_nusantara/features/gameplay/game_hud.dart';
import 'package:beat_nusantara/game/chart_loader/chart_loader.dart';
import 'package:beat_nusantara/game/engine/game_engine.dart';
import 'package:beat_nusantara/game/rendering/note_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show rootBundle, FontLoader, MethodChannel;
import 'package:flutter_test/flutter_test.dart';

const _physical = Size(886, 1920); // accepted App-preview size (6.7")
const _dpr = 2.0;
const _fps = 24;
const _durMs = 15000;

Future<void> _loadFonts() async {
  final j = FontLoader('Jakarta');
  for (final a in const [
    'assets/fonts/PlusJakartaSans-Regular.ttf',
    'assets/fonts/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/PlusJakartaSans-Bold.ttf',
    'assets/fonts/PlusJakartaSans-ExtraBold.ttf',
  ]) {
    j.addFont(rootBundle.load(a));
  }
  await j.load();
  for (final p in const ['fonts/MaterialIcons-Regular.otf', 'packages/flutter/fonts/MaterialIcons-Regular.otf']) {
    try {
      final mi = FontLoader('MaterialIcons')..addFont(rootBundle.load(p));
      await mi.load();
      break;
    } catch (_) {}
  }
}

void _silenceAudioplayers() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in const ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
    m.setMockMethodCallHandler(MethodChannel(name), (call) async => call.method == 'create' ? 1 : null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('render preview frames', timeout: const Timeout(Duration(minutes: 9)), (tester) async {
    _silenceAudioplayers();
    await _loadFonts();
    tester.view.physicalSize = _physical;
    tester.view.devicePixelRatio = _dpr;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final chart = await ChartLoader.load('assets/charts/koplo_neon__expert.json');
    expect(chart, isNotNull);
    final engine = GameEngine(chart!);
    final repaint = ValueNotifier<int>(0);
    final laneFlash = <int, int>{};
    final laneMiss = <int, int>{};
    final lanePress = <int, int>{};
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: RepaintBoundary(
          key: boundaryKey,
          child: Scaffold(
            backgroundColor: AppColors.navy,
            body: Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.ink2, AppColors.navy],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: NotePainter(
                      engine: engine,
                      approachMs: 1400,
                      laneCount: engine.laneCount,
                      laneFlash: laneFlash,
                      laneMiss: laneMiss,
                      lanePress: lanePress,
                      reduceEffects: false,
                      highContrast: false,
                      repaint: repaint,
                    ),
                  ),
                ),
                SafeArea(
                  child: ValueListenableBuilder<int>(
                    valueListenable: repaint,
                    builder: (_, __, ___) {
                      final t = engine.songTimeMs;
                      final prog = (t / _durMs).clamp(0.0, 1.0).toDouble();
                      return GameHud(
                        title: 'Koplo Neon',
                        difficulty: 'Expert',
                        mode: 'Speed',
                        score: (prog * 1284500).round(),
                        accuracy: 99.1,
                        combo: (prog * 247).round(),
                        hp: 0.86,
                        fever: engine.feverActive ? 1.0 : (t % 4000) / 4000.0,
                        feverActive: engine.feverActive,
                        progress: prog,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final dir = Directory('build/preview')..createSync(recursive: true);
    final total = _durMs * _fps ~/ 1000;
    final frameMs = (1000 / _fps).round();
    for (int f = 0; f < total; f++) {
      final t = (f * 1000 / _fps).round();
      engine.songTimeMs = t;
      engine.feverActive = t > 8000 && t < 12500;
      // simulate hits: notes crossing the line get judged → bursts + dissolve
      for (final n in chart.notes) {
        if (!n.judged && t >= n.startTimeMs && (t - n.startTimeMs) < frameMs + 20) {
          n.judged = true;
          n.judgedAt = t;
          laneFlash[n.lane] = t;
          if (n.lane.isEven) lanePress[n.lane] = t;
        }
      }
      repaint.value++;
      await tester.pump(Duration(milliseconds: frameMs));
      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: _dpr);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('${dir.path}/frame_${f.toString().padLeft(4, '0')}.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
        img.dispose();
      });
    }
    expect(Directory('build/preview').listSync().length, total);
  });
}
