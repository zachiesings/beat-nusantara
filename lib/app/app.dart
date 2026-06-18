import 'package:flutter/material.dart';
import '../features/screenshot/screenshot_gallery.dart';
import '../features/splash/splash_screen.dart';
import 'theme.dart';

/// Set at build time to launch straight into a deterministic screenshot screen,
/// e.g. `flutter run --dart-define=SCREENSHOT=gameplay`. Empty → normal app.
const _screenshot = String.fromEnvironment('SCREENSHOT');

class BeatNusantaraApp extends StatelessWidget {
  const BeatNusantaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beat Nusantara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      // Literal named routes so each screenshot state is reachable as
      // /screenshot/home, /screenshot/library, … (handy for flutter drive /
      // integration_test capture). They reuse the SAME real widgets + demo data.
      routes: {
        for (final r in screenshotRoutes) '/screenshot/$r': (ctx) => screenshotScreen(ctx, r),
      },
      home: _screenshot.isEmpty
          ? const SplashScreen()
          : Builder(builder: (ctx) => screenshotScreen(ctx, _screenshot)),
    );
  }
}
