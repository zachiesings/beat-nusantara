import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../state/game_state.dart';
import '../../widgets/gunungan.dart';
import '../../widgets/pulse.dart';
import '../../widgets/shapes.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _go();
    });
  }

  void _go() {
    if (!mounted) return;
    final done = context.read<GameState>().onboardingDone;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => done ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => SplashContent(progress: _c.value),
          ),
        ),
      ),
    );
  }
}

/// The splash composition (no timer) — reused by the real splash and the
/// /screenshot/splash route. Gunungan emblem inside pulse rings, brand name,
/// tagline, a tumpal trim.
class SplashContent extends StatelessWidget {
  final double progress;
  const SplashContent({super.key, this.progress = 1.0});

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0).toDouble();
    final t = Curves.easeOutBack.transform(p);
    return Opacity(
      opacity: p,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 250,
            height: 290,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(child: Twinkles(count: 16, color: AppColors.gold)),
                const PulseRings(color: AppColors.gold, size: 250),
                Transform.scale(scale: 0.7 + 0.3 * t, child: const Gunungan(size: 168)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (r) => AppColors.brandGradient.createShader(r),
            child: const Text(
              K.appName,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: 8),
          const Text(K.tagline, style: TextStyle(color: AppColors.textLo, fontSize: 14)),
          const SizedBox(height: 18),
          const SizedBox(width: 120, child: Tumpal(height: 10)),
        ],
      ),
    );
  }
}
