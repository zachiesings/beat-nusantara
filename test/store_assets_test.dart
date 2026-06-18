// Renders the new app ICON (1024) and 5 branded App Store screenshots (with
// headline text) from the REAL app, for the 4.3(a) re-submission.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:beat_nusantara/data/song_catalog.dart';
import 'package:beat_nusantara/features/screenshot/store_assets.dart';
import 'package:beat_nusantara/services/ads/ads_service.dart';
import 'package:beat_nusantara/services/audio/audio_service.dart';
import 'package:beat_nusantara/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show rootBundle, FontLoader, MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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
  for (final name in const [
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers.global/events',
    'xyz.luan/audioplayers/events/music',
    'xyz.luan/audioplayers/events/sfx',
    'xyz.luan/audioplayers/events/bgm',
  ]) {
    m.setMockMethodCallHandler(MethodChannel(name), (call) async => call.method == 'create' ? 1 : null);
  }
}

Future<void> _capture(GlobalKey key, WidgetTester tester, String path, double dpr) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final f = File(path)..parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    _silenceAudioplayers();
    await _loadFonts();
  });

  testWidgets('app icon 1024', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(key: key, child: Center(child: appIconArt())),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(key, tester, 'build/store/app_icon_1024.png', 1.0);
    expect(File('build/store/app_icon_1024.png').existsSync(), isTrue);
  });

  for (final name in storeShotCopy.keys) {
    testWidgets('store shot $name', (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final catalog = SongCatalog();
      final audio = AudioService();
      final AdsService ads = StubAdsService();
      await tester.runAsync(() => catalog.load());
      final key = GlobalKey();
      final copy = storeShotCopy[name]!;
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<SongCatalog>.value(value: catalog),
          Provider<AudioService>.value(value: audio),
          Provider<AdsService>.value(value: ads),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: RepaintBoundary(
            key: key,
            child: Builder(builder: (ctx) => storeShot(ctx, name, kicker: copy[0], headline: copy[1])),
          ),
        ),
      ));
      await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 700)));
      await tester.pump();
      await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump(const Duration(milliseconds: 1600));
      await _capture(key, tester, 'build/store/store_$name.png', 3.0);
      expect(File('build/store/store_$name.png').existsSync(), isTrue);
    });
  }
}
