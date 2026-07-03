import 'package:flutter/material.dart';

/// Mobile-only visual tokens for the dark adventure journal presentation.
///
/// These intentionally do not replace the app theme or desktop palette.
abstract final class MobileJournalTokens {
  static const backgroundDark = Color(0xFF090A11);
  static const surfaceDark = Color(0xFF12131D);
  static const raisedDark = Color(0xFF171925);
  static const questRowDark = Color(0xFF1A1B25);
  static const outlineDark = Color(0xFF2B2D3B);
  static const textDark = Color(0xFFF5F2FA);
  static const mutedDark = Color(0xFF9895A7);

  static const violet = Color(0xFF7562FF);
  static const amber = Color(0xFFFF8A1F);
  static const inbox = Color(0xFF35C76F);
  static const rewardGold = Color(0xFFFFB020);

  static const radiusLarge = 24.0;
  static const radiusMedium = 18.0;
  static const motion = Duration(milliseconds: 220);
  static const curve = Curves.easeOutCubic;

  static Color background(bool isDark) =>
      isDark ? backgroundDark : const Color(0xFFF5F1E8);

  static Color surface(bool isDark) =>
      isDark ? surfaceDark : const Color(0xFFFFFCF6);

  static Color raised(bool isDark) =>
      isDark ? raisedDark : const Color(0xFFF2EEE6);

  static Color questRow(bool isDark) =>
      isDark ? questRowDark : const Color(0xFFF8F4ED);

  static Color outline(bool isDark) =>
      isDark ? outlineDark : const Color(0xFFD9D3C8);

  static Color text(bool isDark) => isDark ? textDark : const Color(0xFF17151C);

  static Color muted(bool isDark) =>
      isDark ? mutedDark : const Color(0xFF68636F);

  static Color rewardGoldBackground(bool isDark) =>
      rewardGold.withAlpha(isDark ? 23 : 18);

  static Color rewardGoldBorder(bool isDark) =>
      rewardGold.withAlpha(isDark ? 88 : 100);

  static Color skillAccentSoft(Color skillColor, bool isDark) =>
      skillColor.withAlpha(isDark ? 24 : 16);

  static Color skillAccentBorder(Color skillColor, bool isDark) =>
      skillColor.withAlpha(isDark ? 92 : 78);

  static Color skillAccentSurfaceTint(Color skillColor, bool isDark) {
    final hue = HSVColor.fromColor(skillColor).hue;
    final isWarm = hue <= 48 || hue >= 338;
    final alpha = isDark ? (isWarm ? 13 : 18) : (isWarm ? 8 : 11);
    return skillColor.withAlpha(alpha);
  }
}

class MobileSkillFocusSurface extends StatelessWidget {
  final Color skillColor;
  final bool isDark;
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const MobileSkillFocusSurface({
    super.key,
    required this.skillColor,
    required this.isDark,
    required this.child,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    final base = MobileJournalTokens.raised(isDark);
    final tint = Color.alphaBlend(
      MobileJournalTokens.skillAccentSurfaceTint(skillColor, isDark),
      base,
    );

    return DecoratedBox(
      key: const ValueKey('mobile-skill-focus-surface'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(0.35, 1),
          stops: const [0, 0.36, 1],
          colors: [tint, base, base],
        ),
        borderRadius: radius,
        border: Border.all(
          color: MobileJournalTokens.skillAccentBorder(skillColor, isDark),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: skillColor.withAlpha(9),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );
  }
}
