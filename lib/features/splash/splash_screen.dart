import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../state/game_state.dart';
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
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
        ..forward();

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
        pageBuilder: (_, __, ___) =>
            done ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
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
            builder: (_, __) {
              final t = Curves.easeOutBack.transform(_c.value.clamp(0.0, 1.0).toDouble());
              return Opacity(
                opacity: _c.value.clamp(0.0, 1.0).toDouble(),
                child: Transform.scale(
                  scale: 0.7 + 0.3 * t,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulseLogo(progress: _c.value),
                      const SizedBox(height: 24),
                      ShaderMask(
                        shaderCallback: (r) =>
                            AppColors.brandGradient.createShader(r),
                        child: const Text(
                          K.appName,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(K.tagline,
                          style: TextStyle(color: AppColors.textLo, fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PulseLogo extends StatelessWidget {
  final double progress;
  const _PulseLogo({required this.progress});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final r in [1.0, 0.7, 0.45])
            Container(
              width: 120 * r,
              height: 120 * r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.25 + 0.4 * progress),
                    width: 2),
              ),
            ),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                gradient: AppColors.brandGradient, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}
