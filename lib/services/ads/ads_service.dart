import 'package:flutter/foundation.dart';
import '../../core/constants.dart';

/// What a rewarded ad grants. Used only for analytics/labels — the reward is
/// applied by the caller after [showRewarded] returns true.
enum RewardKind { songTrial, revive, bonusCoins, cosmetic }

/// Abstraction so gameplay code never imports an ad SDK directly. Phase 1 ships
/// [StubAdsService]; drop in [GoogleMobileAdsService] later (see ADMOB_NOTES.md)
/// with zero changes to callers.
abstract class AdsService {
  bool get available;

  /// Show a rewarded ad. Returns true only if the user finished it and the
  /// reward should be granted. MUST be called only after the user explicitly
  /// confirmed via the disclosure dialog (see widgets/reward_ad_sheet.dart).
  Future<bool> showRewarded(RewardKind kind);

  void dispose() {}
}

/// Development / review-safe stub. Simulates a short rewarded ad and always
/// grants the reward. No network, no SDK, no tracking — guarantees a green build
/// and lets the full reward UX be demoed today.
class StubAdsService implements AdsService {
  @override
  bool get available => K.adsEnabled;

  @override
  Future<bool> showRewarded(RewardKind kind) async {
    if (!K.adsEnabled) return false;
    debugPrint('[ads:stub] simulating rewarded ad for $kind');
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    return true; // stub always rewards
  }

  @override
  void dispose() {}
}
