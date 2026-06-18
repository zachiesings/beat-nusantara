import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio/audio_service.dart';
import '../../widgets/beat_nav_bar.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/rewards_screen.dart';
import '../song_library/song_library_screen.dart';

/// Lets any descendant (e.g. Home's quick actions / avatar) jump to a nav tab
/// without pushing a new route — so the whole app lives under one floating shell.
class ShellScope extends InheritedWidget {
  final void Function(int tab) go;
  const ShellScope({super.key, required this.go, required super.child});

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope old) => false;
}

/// The persistent home of the app: four tabs kept alive in an IndexedStack with
/// the floating [BeatNavBar]. Other screens (song detail, gameplay, settings,
/// about, calibration) push on top of this shell.
class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _tab = widget.initialTab;
  AudioService? _audio;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    _audio!.startMenuMusic(); // soft menu ambience
  }

  @override
  void dispose() {
    _audio?.stopMenuMusic();
    super.dispose();
  }

  void _go(int i) {
    if (i != _tab) setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      go: _go,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _tab,
          children: const [
            HomeScreen(),
            SongLibraryScreen(embedded: true),
            RewardsScreen(embedded: true),
            ProfileScreen(embedded: true),
          ],
        ),
        bottomNavigationBar: BeatNavBar(index: _tab, onTap: _go),
      ),
    );
  }
}
