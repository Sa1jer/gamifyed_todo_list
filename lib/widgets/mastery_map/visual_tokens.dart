import 'package:flutter/material.dart';

/// Presentation-only colors shared by desktop and mobile RoadMap canvases.
abstract final class RoadmapVisualTokens {
  static const lightCanvas = Color(0xFFF4F5F8);
  static const mobileDarkCanvas = Color(0xFF11100F);
  static const mobileJournalDark = Color(0xFF0D0E13);

  static Color canvas({required bool isDark, required bool mobile}) {
    if (!isDark) return lightCanvas;
    if (mobile) return mobileDarkCanvas;
    return Color.lerp(const Color(0xFF0D0D12), Colors.black, 0.75)!;
  }
}
