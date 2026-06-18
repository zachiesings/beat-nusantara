/// App-wide constants & config flags.
class K {
  static const appName = 'Beat Nusantara';
  static const tagline = 'Rasakan ritme Nusantara';

  /// Master kill-switch for ads. Flip to false to give App Store review a
  /// 100% ad-free build (see docs/APP_STORE_REVIEW_NOTES.md).
  static const bool adsEnabled = true;

  /// When true, use Google's TEST ad units (safe during development — never tap
  /// real ads on your own account). Flip to false for production.
  static const bool useTestAds = bool.fromEnvironment('USE_TEST_ADS', defaultValue: true);

  // ---- AdMob (Beat Nusantara) -------------------------------------------------
  // App ID goes into the native manifest/plist (injected by CI). Ad unit is used
  // by GoogleMobileAdsService. NOTE: AdMob app-ids/units are per-platform — these
  // are the IDs you provided; add separate iOS ids if your AdMob app differs.
  static const admobAppId = 'ca-app-pub-1298950542115439~5662432931';
  static const rewardedAdUnit = 'ca-app-pub-1298950542115439/8932764961';

  // Gameplay tuning ---------------------------------------------------------
  /// How long (ms) a note is visible while falling before it reaches the line.
  static const int approachMs = 1400;
  static const double hitLineFromBottom = 0.18; // fraction of screen height

  // Judgment windows (± ms around the target time)
  static const int wPerfect = 35;
  static const int wGreat = 70;
  static const int wGood = 110;

  // HP / life
  static const double hpStart = 100;
  static const double hpMax = 100;
  static const double hpPerfect = 2;
  static const double hpGreat = 1;
  static const double hpGood = 0;
  static const double hpMiss = -7;

  // Fever
  static const double feverPerHit = 0.04;
  static const double feverOnMiss = -0.12;
  static const int feverDurationMs = 6000;

  static const int reviveHpRestore = 50;
}
