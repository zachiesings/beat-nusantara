import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/song_catalog.dart';
import '../../state/game_state.dart';
import '../../widgets/glass_panel.dart';
import '../home/home_screen.dart';
import '../results/result_screen.dart';
import '../rewards/rewards_screen.dart';
import '../song_library/song_library_screen.dart';
import 'demo_data.dart';
import 'screenshot_gameplay.dart';

/// Names map 1:1 to the requested routes: screenshot/home, screenshot/library,
/// screenshot/gameplay, screenshot/result, screenshot/reward.
const screenshotRoutes = ['home', 'library', 'gameplay', 'result', 'reward'];

/// Returns a screenshot-ready screen built from REAL app widgets + deterministic
/// demo data. Reachable via `--dart-define=SCREENSHOT=<name>` at launch, or from
/// the in-app gallery (debug builds, Settings → Developer).
Widget screenshotScreen(BuildContext context, String name) {
  final catalog = context.read<SongCatalog>();
  final demo = buildDemoGameState(catalog);

  Widget wrap(Widget child) =>
      ChangeNotifierProvider<GameState>.value(value: demo, child: child);

  switch (name) {
    case 'home':
      return wrap(const HomeScreen());
    case 'library':
      return wrap(const SongLibraryScreen());
    case 'reward':
      return wrap(const RewardsScreen());
    case 'gameplay':
      return wrap(const ScreenshotGameplay());
    case 'result':
      final song = catalog.byId('koplo_neon')!;
      return wrap(ResultScreen(
        song: song,
        difficulty: 'Expert',
        result: demoResult(),
      ));
    default:
      return const _Unknown();
  }
}

class _Unknown extends StatelessWidget {
  const _Unknown();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Unknown screenshot route')),
      );
}

/// In-app launcher (debug only) — pick a screen, capture, repeat.
class ScreenshotGallery extends StatelessWidget {
  const ScreenshotGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context)),
                const Text('Mode Screenshot',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                    'Layar deterministik dengan data fiktif untuk screenshot App Store. '
                    'Semua memakai widget asli aplikasi. Tangkap dari sini, lalu lihat '
                    'docs/SCREENSHOT_DIRECTION.md.',
                    style: TextStyle(color: AppColors.textLo, fontSize: 13)),
              ),
              const SizedBox(height: 16),
              ...screenshotRoutes.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassPanel(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => screenshotScreen(ctx, r)),
                      ),
                      child: Row(children: [
                        Icon(_iconFor(r), color: AppColors.cyan),
                        const SizedBox(width: 14),
                        Text('screenshot/$r',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: AppColors.textLo),
                      ]),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String r) => switch (r) {
        'home' => Icons.home,
        'library' => Icons.library_music,
        'gameplay' => Icons.sports_esports,
        'result' => Icons.emoji_events,
        'reward' => Icons.card_giftcard,
        _ => Icons.image,
      };
}
