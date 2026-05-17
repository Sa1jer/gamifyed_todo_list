import 'dart:async';

import 'package:flutter/services.dart';

import 'sfx_service.dart';

class AppFeedback {
  const AppFeedback._();

  static Future<void> selection() {
    unawaited(SfxService.instance.play(SfxCue.selection));
    return HapticFeedback.selectionClick();
  }

  static Future<void> light() {
    unawaited(SfxService.instance.play(SfxCue.light));
    return HapticFeedback.lightImpact();
  }

  static Future<void> success() {
    unawaited(SfxService.instance.play(SfxCue.success));
    return HapticFeedback.mediumImpact();
  }

  static Future<void> milestone() {
    unawaited(SfxService.instance.play(SfxCue.milestone));
    return HapticFeedback.heavyImpact();
  }

  static Future<void> reward() {
    unawaited(SfxService.instance.play(SfxCue.reward));
    return HapticFeedback.heavyImpact();
  }

  static Future<void> destructive() {
    unawaited(SfxService.instance.play(SfxCue.destructive));
    return HapticFeedback.mediumImpact();
  }

  static Future<void> questResult(String message, {bool isMinimum = false}) {
    if (isMilestoneMessage(message)) {
      return milestone();
    }
    return isMinimum ? light() : success();
  }

  static bool isMilestoneMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('побеждён') ||
        normalized.contains('ранг') ||
        normalized.contains('ур.');
  }
}
