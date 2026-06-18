import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';
import 'theme.dart';

class BeatNusantaraApp extends StatelessWidget {
  const BeatNusantaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beat Nusantara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
