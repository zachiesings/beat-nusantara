import 'package:flutter/services.dart';

/// Thin haptics wrapper so the rest of the app never touches HapticFeedback
/// directly — lets a single user setting disable all vibration.
class Haptics {
  static bool enabled = true;

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void select() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  /// Composite "you did it" pattern — for result clear & mission complete.
  static Future<void> success() async {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    HapticFeedback.lightImpact();
  }

  /// Gentle "nope" pattern — for tapping a locked item (never harsh).
  static Future<void> error() async {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    HapticFeedback.lightImpact();
  }
}
