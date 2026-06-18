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
}
