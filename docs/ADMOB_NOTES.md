# AdMob — aktifkan iklan asli (drop-in)

## Kenapa Phase 1 pakai stub
Build saat ini memakai `StubAdsService` (lihat `lib/services/ads/ads_service.dart`):
seluruh **alur UX iklan berhadiah sudah jalan & bisa didemokan** tanpa SDK,
tanpa AdMob app-id di manifest (yang kalau salah konfigurasi bisa membuat build
review **crash saat start**). Jadi build pasti hijau dan aman untuk review.

Semua iklan diinisiasi **hanya** lewat satu komponen:
`lib/widgets/reward_ad_sheet.dart` → disclosure jujur, opsional, bisa ditolak,
tidak pernah otomatis. Mengganti stub → asli tidak mengubah pemanggil mana pun.

## Langkah mengaktifkan google_mobile_ads (±10 menit)

### 1. Tambah dependency
```yaml
# pubspec.yaml
dependencies:
  google_mobile_ads: ^5.1.0
```

### 2. Daftarkan AdMob App ID (WAJIB, kalau tidak app bisa crash)
- **Android** `android/app/src/main/AndroidManifest.xml` di dalam `<application>`:
  ```xml
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-3940256099942544~3347511713"/> <!-- TEST app id -->
  ```
- **iOS** `ios/Runner/Info.plist`:
  ```xml
  <key>GADApplicationIdentifier</key>
  <string>ca-app-pub-3940256099942544~1458002511</string> <!-- TEST app id -->
  ```
  > Karena folder native di-generate di CI, taruh langkah `sed`/patch di
  > workflow, atau commit folder native saat siap rilis dengan id asli.

### 3. Buat implementasi asli (pakai test unit di dev)
```dart
// lib/services/ads/google_mobile_ads_service.dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants.dart';
import 'ads_service.dart';

class GoogleMobileAdsService implements AdsService {
  // Google's official TEST rewarded unit ids:
  static const _testAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testIOS = 'ca-app-pub-3940256099942544/1712485313';

  bool _initDone = false;
  @override
  bool get available => K.adsEnabled;

  Future<void> _ensureInit() async {
    if (_initDone) return;
    await MobileAds.instance.initialize();
    _initDone = true;
  }

  String get _unitId {
    // ganti ke production id lewat --dart-define saat rilis:
    const prod = String.fromEnvironment('REWARDED_AD_UNIT', defaultValue: '');
    if (!K.useTestAds && prod.isNotEmpty) return prod;
    return defaultTargetPlatform == TargetPlatform.iOS ? _testIOS : _testAndroid;
  }

  @override
  Future<bool> showRewarded(RewardKind kind) async {
    if (!available) return false;
    await _ensureInit();
    final completer = Completer<bool>();
    await RewardedAd.load(
      adUnitId: _unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var rewarded = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(rewarded);
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (_, __) => rewarded = true);
        },
        onAdFailedToLoad: (_) =>
            completer.isCompleted ? null : completer.complete(false),
      ),
    );
    return completer.future;
  }

  @override
  void dispose() {}
}
```
(Tambahkan `import 'dart:async';` dan `import 'package:flutter/foundation.dart';`.)

### 4. Tukar di `main.dart`
```dart
final AdsService ads = GoogleMobileAdsService(); // ganti StubAdsService()
```

### 5. Production unit ids
Inject saat build, jangan hardcode:
```bash
flutter build ipa --release --dart-define=REWARDED_AD_UNIT=ca-app-pub-XXXX/YYYY
```
Dan set `K.useTestAds = false` (atau jadikan dart-define juga).

## Etika (sudah dipaksakan di kode)
- Iklan **tidak pernah** otomatis — selalu lewat dialog konfirmasi.
- Tombol tolak (X / "Nanti saja") selalu terlihat.
- Pemain tahu persis hadiahnya sebelum menonton.
- Tanpa interstitial saat gameplay. Banner tidak dipakai di playfield.
- `K.adsEnabled = false` mematikan semua iklan (untuk review Apple).
