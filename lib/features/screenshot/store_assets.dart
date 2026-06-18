import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/gunungan.dart';
import 'screenshot_gallery.dart';

/// Premium, unmistakably-Indonesian app icon: a gold wayang GUNUNGAN (kayon) on a
/// deep batik-night gradient with a warm gold glow. Rendered at 1024x1024.
/// This is the differentiator for the 4.3(a) review — cultural, original, not a
/// generic tile-game glyph.
Widget appIconArt() {
  return SizedBox(
    width: 1024,
    height: 1024,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB23A4E), Color(0xFF5B4BC4), Color(0xFF170F22)],
              stops: [0.0, 0.52, 1.0],
            ),
          ),
        ),
        // warm radial gold glow behind the gunungan
        Center(
          child: Container(
            width: 820,
            height: 820,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.gold.withValues(alpha: 0.55), AppColors.gold.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ),
        Center(child: Gunungan(size: 680)),
        // soft vignette for depth
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.95,
              colors: [Color(0x00000000), Color(0x55000000)],
              stops: [0.7, 1.0],
            ),
          ),
        ),
      ],
    ),
  );
}

/// A real app screen with a branded headline banner on top — the App Store
/// screenshot style. Text is rendered by Flutter (Plus Jakarta Sans).
Widget storeShot(BuildContext ctx, String name, {required String kicker, required String headline}) {
  return Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(child: screenshotScreen(ctx, name)),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(44, 86, 44, 60),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.ink.withValues(alpha: 0.95),
                AppColors.ink.withValues(alpha: 0.82),
                AppColors.ink.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                kicker.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Jakarta',
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                  letterSpacing: 3,
                  color: AppColors.goldLt,
                ),
              ),
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (r) => AppGradients.brandGradient.createShader(r),
                child: Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Jakarta',
                    fontWeight: FontWeight.w800,
                    fontSize: 50,
                    height: 1.06,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Headlines per screen (Indonesian, emphasising the unique cultural angle).
const storeShotCopy = <String, List<String>>{
  'gameplay': ['Ketuk · Tahan · Geser', 'Rasakan Ritme Nusantara'],
  'home': ['Gamelan · Koplo · Batik', 'Game Ritme Rasa Indonesia'],
  'result': ['Grade C sampai SSS', 'Kejar Skor & Full Combo'],
  'library': ['Semua Lagu Orisinal', '20 Lagu Lintas Genre'],
  'reward': ['Main, Bukan Bayar', 'Buka Skin & Hadiah Gratis'],
};
