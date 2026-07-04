import 'package:flutter/material.dart';

enum MobileWidthBucket { compact, normal, largePhone, tablet }

class MobileResponsiveMetrics {
  static const minTapTarget = 48.0;
  static const compactMax = 360.0;
  static const normalMax = 393.0;
  static const largePhoneMax = 430.0;
  static const mobileMax = 760.0;

  static bool isMobileWidth(double width) => width <= mobileMax;

  const MobileResponsiveMetrics._({
    required this.bucket,
    required this.pagePadding,
    required this.cardPadding,
    required this.questRowVerticalPadding,
  });

  final MobileWidthBucket bucket;
  final double pagePadding;
  final double cardPadding;
  final double questRowVerticalPadding;

  factory MobileResponsiveMetrics.fromWidth(double width) {
    if (width <= compactMax) {
      return const MobileResponsiveMetrics._(
        bucket: MobileWidthBucket.compact,
        pagePadding: 12,
        cardPadding: 12,
        questRowVerticalPadding: 8,
      );
    }
    if (width <= normalMax) {
      return const MobileResponsiveMetrics._(
        bucket: MobileWidthBucket.normal,
        pagePadding: 14,
        cardPadding: 14,
        questRowVerticalPadding: 9,
      );
    }
    if (width <= largePhoneMax) {
      return const MobileResponsiveMetrics._(
        bucket: MobileWidthBucket.largePhone,
        pagePadding: 16,
        cardPadding: 16,
        questRowVerticalPadding: 10,
      );
    }
    return const MobileResponsiveMetrics._(
      bucket: MobileWidthBucket.tablet,
      pagePadding: 18,
      cardPadding: 18,
      questRowVerticalPadding: 11,
    );
  }

  factory MobileResponsiveMetrics.of(BuildContext context) =>
      MobileResponsiveMetrics.fromWidth(MediaQuery.sizeOf(context).width);
}

abstract final class MobileMotion {
  static bool reduced(BuildContext context, {bool appReducedMotion = false}) =>
      appReducedMotion || MediaQuery.disableAnimationsOf(context);

  static Duration duration(
    BuildContext context, {
    bool appReducedMotion = false,
    Duration normal = const Duration(milliseconds: 220),
  }) => reduced(context, appReducedMotion: appReducedMotion)
      ? Duration.zero
      : normal;

  static Offset movement(
    BuildContext context,
    Offset normal, {
    bool appReducedMotion = false,
  }) => reduced(context, appReducedMotion: appReducedMotion)
      ? Offset.zero
      : normal;
}

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
  static const backgroundLight = Color(0xFFF4EFE5);
  static const surfaceLight = Color(0xFFFFFBF3);
  static const raisedLight = Color(0xFFF1EBDD);
  static const questRowLight = Color(0xFFF8F2E7);
  static const outlineLight = Color(0xFFCFC5B5);
  static const textLight = Color(0xFF211D1A);
  static const mutedLight = Color(0xFF6D655D);

  static const violet = Color(0xFF7562FF);
  static const amber = Color(0xFFFF8A1F);
  static const inbox = Color(0xFF35C76F);
  static const rewardGold = Color(0xFFFFB020);

  static const radiusLarge = 24.0;
  static const radiusMedium = 18.0;
  static const minTapTarget = MobileResponsiveMetrics.minTapTarget;
  static const motion = Duration(milliseconds: 220);
  static const curve = Curves.easeOutCubic;

  static Color background(bool isDark) =>
      isDark ? backgroundDark : backgroundLight;

  static Color surface(bool isDark) => isDark ? surfaceDark : surfaceLight;

  static Color raised(bool isDark) => isDark ? raisedDark : raisedLight;

  static Color questRow(bool isDark) => isDark ? questRowDark : questRowLight;

  static Color outline(bool isDark) => isDark ? outlineDark : outlineLight;

  static Color text(bool isDark) => isDark ? textDark : textLight;

  static Color muted(bool isDark) => isDark ? mutedDark : mutedLight;

  static Color rewardGoldBackground(bool isDark) =>
      isDark ? rewardGold.withAlpha(23) : const Color(0xFFFFE7B5);

  static Color rewardGoldBorder(bool isDark) =>
      isDark ? rewardGold.withAlpha(88) : const Color(0xFFC68A16);

  static Color rewardGoldForeground(bool isDark) =>
      isDark ? rewardGold : const Color(0xFF7A4D00);

  static Color skillAccentSoft(Color skillColor, bool isDark) =>
      skillColor.withAlpha(isDark ? 24 : 22);

  static Color skillAccentBorder(Color skillColor, bool isDark) =>
      skillColor.withAlpha(isDark ? 92 : 105);

  static Color readableAccent(Color color, bool isDark) {
    if (isDark) return color;
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(hsl.saturation.clamp(0.45, 0.9))
        .withLightness(hsl.lightness.clamp(0.28, 0.43))
        .toColor();
  }

  static TextTheme textTheme(BuildContext context, bool isDark) {
    final base = Theme.of(context).textTheme;
    final strong = text(isDark);
    final secondary = muted(isDark);
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        color: strong,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: strong,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: strong,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: strong,
        fontSize: 13,
        height: 1.35,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: secondary,
        fontSize: 11.5,
        height: 1.3,
      ),
      labelLarge: base.labelLarge?.copyWith(
        color: strong,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  static Color skillAccentSurfaceTint(Color skillColor, bool isDark) {
    final hue = HSVColor.fromColor(skillColor).hue;
    final isWarm = hue <= 48 || hue >= 338;
    final alpha = isDark ? (isWarm ? 13 : 18) : (isWarm ? 8 : 11);
    return skillColor.withAlpha(alpha);
  }
}

@immutable
class CompletionToastColors {
  static const fallbackSourceAccent = MobileJournalTokens.rewardGold;

  final Color sourceAccentColor;
  final Color rewardColor;

  const CompletionToastColors({
    required this.sourceAccentColor,
    this.rewardColor = MobileJournalTokens.rewardGold,
  });

  const CompletionToastColors.fallback()
    : sourceAccentColor = fallbackSourceAccent,
      rewardColor = MobileJournalTokens.rewardGold;

  factory CompletionToastColors.resolve({
    Color? skillColor,
    bool isInbox = false,
  }) => CompletionToastColors(
    sourceAccentColor: isInbox
        ? MobileJournalTokens.inbox
        : skillColor ?? fallbackSourceAccent,
  );

  Color surfaceTint(Color baseColor, {required bool isDark}) =>
      Color.alphaBlend(
        sourceAccentColor.withAlpha(isDark ? 14 : 10),
        baseColor,
      );

  Color borderColor({required bool isDark}) =>
      sourceAccentColor.withAlpha(isDark ? 112 : 125);

  Color glowColor({required bool isDark}) =>
      sourceAccentColor.withAlpha(isDark ? 34 : 28);

  Color rewardSoft({required bool isDark}) =>
      rewardColor.withAlpha(isDark ? 32 : 24);
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
