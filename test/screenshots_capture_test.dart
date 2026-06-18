// Auto-captures each screenshot-mode screen to a real PNG — no device/emulator
// needed. Renders the REAL Flutter widgets + deterministic demo data, then grabs
// the frame via RepaintBoundary.toImage at iPhone-Pro-Max resolution.
//
// Output (one distinctly-named file per screen):
//   build/screenshots/home.png
//   build/screenshots/library.png
//   build/screenshots/gameplay.png
//   build/screenshots/result.png
//   build/screenshots/reward.png
//
// Run locally:  flutter test test/screenshots_capture_test.dart
// In CI:        .github/workflows/screenshots.yml uploads them as an artifact.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:beat_nusantara/app/theme.dart';
import 'package:beat_nusantara/data/song_catalog.dart';
import 'package:beat_nusantara/features/screenshot/screenshot_gallery.dart';
import 'package:beat_nusantara/services/ads/ads_service.dart';
import 'package:beat_nusantara/services/audio/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// iPhone 15/16 Pro Max — App Store 6.7"/6.9" slot.
const _physical = Size(1290, 2796);
const _dpr = 3.0;

Future<void> _loadFonts() async {
  final loader = FontLoader('Jakarta');
  for (final a in const [
    'assets/fonts/PlusJakartaSans-Regular.ttf',
    'assets/fonts/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/PlusJakartaSans-Bold.ttf',
    'assets/fonts/PlusJakartaSans-ExtraBold.ttf',
  ]) {
    loader.addFont(rootBundle.load(a));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFonts);

  for (final name in screenshotRoutes) {
    testWidgets('capture $name.png', (tester) async {
      tester.view.physicalSize = _physical;
      tester.view.devicePixelRatio = _dpr;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final catalog = SongCatalog();
      final audio = AudioService();
      final AdsService ads = StubAdsService();
      await tester.runAsync(() => catalog.load());

      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SongCatalog>.value(value: catalog),
            Provider<AudioService>.value(value: audio),
            Provider<AdsService>.value(value: ads),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            home: RepaintBoundary(
              key: boundaryKey,
              child: Builder(builder: (ctx) => screenshotScreen(ctx, name)),
            ),
          ),
        ),
      );

      // let async asset/chart loads resolve (real time)…
      await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 700)));
      await tester.pump(); // rebuild after any setState (e.g. gameplay engine)
      await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 400)));
      // …then advance the animation clock so count-ups finish & confetti is mid-fall
      await tester.pump(const Duration(milliseconds: 1600));

      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: _dpr);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('build/screenshots')..createSync(recursive: true);
        File('${dir.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });

      expect(File('build/screenshots/$name.png').existsSync(), isTrue);
    });
  }
}
