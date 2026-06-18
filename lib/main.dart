import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/constants.dart';
import 'data/song_catalog.dart';
import 'services/ads/ads_service.dart';
import 'services/ads/google_mobile_ads_service.dart';
import 'services/audio/audio_service.dart';
import 'services/storage/storage_service.dart';
import 'state/game_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  final storage = StorageService();
  await storage.init();

  final gameState = GameState(storage);
  await gameState.load();

  final catalog = SongCatalog();
  await catalog.load();

  final audio = AudioService()
    ..musicEnabled = gameState.music
    ..sfxEnabled = gameState.sfx;

  final AdsService ads = K.adsEnabled ? GoogleMobileAdsService() : StubAdsService();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<GameState>.value(value: gameState),
        Provider<SongCatalog>.value(value: catalog),
        Provider<AudioService>.value(value: audio),
        Provider<AdsService>.value(value: ads),
      ],
      child: const BeatNusantaraApp(),
    ),
  );
}
