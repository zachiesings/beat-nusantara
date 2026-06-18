import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants.dart';
import 'ads_service.dart';

/// Real AdMob rewarded-ads implementation. SDK is initialized lazily (on the
/// first ad request) so app launch never depends on it. All callers go through
/// the [AdsService] abstraction + the ethical disclosure sheet, so the rules
/// (optional, disclosed, never auto-triggered) still hold.
class GoogleMobileAdsService implements AdsService {
  bool _init = false;

  @override
  bool get available => K.adsEnabled;

  Future<void> _ensureInit() async {
    if (_init) return;
    await MobileAds.instance.initialize();
    _init = true;
  }

  // Google's official TEST rewarded units (used while K.useTestAds is true).
  String get _unitId {
    if (K.useTestAds) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    return K.rewardedAdUnit;
  }

  @override
  Future<bool> showRewarded(RewardKind kind) async {
    if (!available) return false;
    try {
      await _ensureInit();
    } catch (_) {
      return false; // SDK not ready (e.g. missing app-id) → fail gracefully
    }
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
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  @override
  void dispose() {}
}
