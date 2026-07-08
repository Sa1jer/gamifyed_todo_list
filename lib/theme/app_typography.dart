import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Application-wide semantic type scale.
///
/// Responsive components keep these roles stable and adapt their layout,
/// wrapping, or metadata priority instead of shrinking text per string.
abstract final class AppTypography {
  static TextTheme textTheme(ColorScheme colorScheme) {
    final typography = Typography.material2021(
      platform: defaultTargetPlatform,
      colorScheme: colorScheme,
    );
    final base = colorScheme.brightness == Brightness.dark
        ? typography.white
        : typography.black;

    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        height: 1.12,
        fontWeight: FontWeight.w900,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        height: 1.14,
        fontWeight: FontWeight.w900,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 20,
        height: 1.16,
        fontWeight: FontWeight.w900,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w900,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 15.5,
        height: 1.22,
        fontWeight: FontWeight.w800,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 13.5,
        height: 1.22,
        fontWeight: FontWeight.w800,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.42),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 13, height: 1.38),
      bodySmall: base.bodySmall?.copyWith(fontSize: 11.5, height: 1.34),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 10.5,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    );
  }
}

/// Product-specific roles that do not map cleanly to generic Material roles.
@immutable
class AppTextRoles extends ThemeExtension<AppTextRoles> {
  final TextStyle reward;
  final TextStyle statValue;
  final TextStyle numericRing;
  final TextStyle sectionEyebrow;
  final TextStyle compactMetadata;

  const AppTextRoles({
    required this.reward,
    required this.statValue,
    required this.numericRing,
    required this.sectionEyebrow,
    required this.compactMetadata,
  });

  factory AppTextRoles.fromTheme(
    TextTheme textTheme, {
    required Brightness brightness,
  }) {
    final rewardColor = brightness == Brightness.dark
        ? const Color(0xFFFFC21A)
        : const Color(0xFF9A6200);
    return AppTextRoles(
      reward: textTheme.labelLarge!.copyWith(
        color: rewardColor,
        fontWeight: FontWeight.w900,
      ),
      statValue: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w900),
      numericRing: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w900),
      sectionEyebrow: textTheme.labelSmall!.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
      ),
      compactMetadata: textTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  AppTextRoles copyWith({
    TextStyle? reward,
    TextStyle? statValue,
    TextStyle? numericRing,
    TextStyle? sectionEyebrow,
    TextStyle? compactMetadata,
  }) => AppTextRoles(
    reward: reward ?? this.reward,
    statValue: statValue ?? this.statValue,
    numericRing: numericRing ?? this.numericRing,
    sectionEyebrow: sectionEyebrow ?? this.sectionEyebrow,
    compactMetadata: compactMetadata ?? this.compactMetadata,
  );

  @override
  AppTextRoles lerp(covariant AppTextRoles? other, double t) {
    if (other == null) return this;
    return AppTextRoles(
      reward: TextStyle.lerp(reward, other.reward, t)!,
      statValue: TextStyle.lerp(statValue, other.statValue, t)!,
      numericRing: TextStyle.lerp(numericRing, other.numericRing, t)!,
      sectionEyebrow: TextStyle.lerp(sectionEyebrow, other.sectionEyebrow, t)!,
      compactMetadata: TextStyle.lerp(
        compactMetadata,
        other.compactMetadata,
        t,
      )!,
    );
  }
}

extension AppTypographyContext on BuildContext {
  TextTheme get appTextTheme => Theme.of(this).textTheme;

  AppTextRoles get appTextRoles {
    final theme = Theme.of(this);
    return theme.extension<AppTextRoles>() ??
        AppTextRoles.fromTheme(theme.textTheme, brightness: theme.brightness);
  }
}
