import 'package:flutter/material.dart';

/// Единственные разрешённые значения геометрии в desktop-ветке.
///
/// Любое значение вне этих шкал — дефект: разница в 1–2 px не несёт смысла,
/// но создаёт ощущение неровного интерфейса. Мобильная ветка живёт по своим
/// правилам и сюда не смотрит.
abstract final class DesktopScale {
  /// Радиусы: `8 / 12 / 16` и пилюля.
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusPill = 999;

  /// Границы: только `1 / 2`.
  static const double borderThin = 1;
  static const double borderThick = 2;

  /// Высота полосы прогресса — одна на весь desktop.
  static const double barHeight = 6;

  /// Отступы: `4 / 8 / 12 / 16 / 24 / 32`.
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;

  /// Минимальная зона нажатия для иконочных действий.
  static const double minHitTarget = 32;
}

@immutable
class DesktopResponsiveMetrics {
  final double sidebarWidth;
  final double railWidth;
  final double mainPadding;
  final double sectionGap;

  /// Разрыв между крупными блоками экрана. Раньше считался как
  /// `sectionGap + 10` и уводил отступы за пределы шкалы.
  final double sectionGapLarge;
  final bool showRightRail;

  const DesktopResponsiveMetrics({
    required this.sidebarWidth,
    required this.railWidth,
    required this.mainPadding,
    required this.sectionGap,
    required this.sectionGapLarge,
    required this.showRightRail,
  });

  static const double desktopBreakpoint = 761;

  static bool isDesktopWidth(double width) => width >= desktopBreakpoint;

  factory DesktopResponsiveMetrics.forWidth(double width) {
    if (width < 1024) {
      return const DesktopResponsiveMetrics(
        sidebarWidth: 232,
        railWidth: 0,
        mainPadding: DesktopScale.space12,
        sectionGap: DesktopScale.space12,
        sectionGapLarge: DesktopScale.space16,
        showRightRail: false,
      );
    }
    if (width < 1280) {
      return const DesktopResponsiveMetrics(
        sidebarWidth: 232,
        railWidth: 236,
        mainPadding: DesktopScale.space16,
        sectionGap: DesktopScale.space12,
        sectionGapLarge: DesktopScale.space16,
        showRightRail: true,
      );
    }
    if (width < 1600) {
      return const DesktopResponsiveMetrics(
        sidebarWidth: 248,
        railWidth: 260,
        mainPadding: DesktopScale.space24,
        sectionGap: DesktopScale.space16,
        sectionGapLarge: DesktopScale.space24,
        showRightRail: true,
      );
    }
    return const DesktopResponsiveMetrics(
      sidebarWidth: 264,
      railWidth: 288,
      mainPadding: DesktopScale.space32,
      sectionGap: DesktopScale.space24,
      sectionGapLarge: DesktopScale.space32,
      showRightRail: true,
    );
  }
}

@immutable
class DesktopJournalTokens {
  final Color background;
  final Color sidebarSurface;
  final Color mainSurface;
  final Color railSurface;
  final Color cardSurface;
  final Color raisedSurface;
  final Color outline;
  final Color subtleOutline;
  final Color text;
  final Color mutedText;
  final Color profilePurple;

  /// Чернильные роли: текст и числа. На светлой теме подобраны под контраст
  /// не ниже 4.5:1 — в том числе поверх собственной подложки-пилюли.
  final Color rewardGold;
  final Color successGreen;
  final Color streakAmber;

  /// Графические роли: заливки, иконки, границы, полосы. Насыщеннее чернильных
  /// и держат 3:1 на светлой карточке — порог для нетекстовой графики.
  /// В тёмной теме совпадают с чернильными.
  ///
  /// Золото из этого правила выведено: владелец выбрал для него блестящий
  /// жёлтый, общий с чернильной ролью, и порог 3:1 оно не держит.
  final Color rewardGoldGraphic;
  final Color successGreenGraphic;
  final Color streakAmberGraphic;

  /// Подложка под наградой в строке квеста — заливка внутри контура.
  final Color rewardGoldSurface;

  final Color semanticBlue;
  final Color danger;

  const DesktopJournalTokens({
    required this.background,
    required this.sidebarSurface,
    required this.mainSurface,
    required this.railSurface,
    required this.cardSurface,
    required this.raisedSurface,
    required this.outline,
    required this.subtleOutline,
    required this.text,
    required this.mutedText,
    required this.profilePurple,
    required this.rewardGold,
    required this.successGreen,
    required this.streakAmber,
    required this.rewardGoldGraphic,
    required this.successGreenGraphic,
    required this.streakAmberGraphic,
    required this.rewardGoldSurface,
    required this.semanticBlue,
    required this.danger,
  });

  factory DesktopJournalTokens.resolve(bool isDark) {
    if (!isDark) {
      return const DesktopJournalTokens(
        background: Color(0xFFF5F6FA),
        sidebarSurface: Color(0xFFFBFBFD),
        mainSurface: Color(0xFFF8F9FC),
        railSurface: Color(0xFFFBFBFD),
        cardSurface: Color(0xFFFFFFFF),
        raisedSurface: Color(0xFFF0F2F8),
        outline: Color(0xFFD9DCE7),
        subtleOutline: Color(0xFFE8EAF1),
        text: Color(0xFF181923),
        mutedText: Color(0xFF6F7282),
        profilePurple: Color(0xFF6D55E8),
        // Золото — решение владельца: блестящий жёлтый #FFCF40, тот же
        // оттенок, что и в тёмной теме. Контраст на белом 1.55:1, то есть
        // ниже AA (4.5:1); выбран ради узнаваемого золота, а не читаемости.
        // Любой цвет, проходящий AA на белом, неизбежно уходит в коричневый:
        // потолок насыщенного золота при 4.5:1 — #946800.
        rewardGold: Color(0xFFFFCF40),
        // Зелень и янтарь остаются на пороге AA: их владелец не оспаривал.
        successGreen: Color(0xFF00802F),
        streakAmber: Color(0xFFB25300),
        rewardGoldGraphic: Color(0xFFFFCF40),
        successGreenGraphic: Color(0xFF00A83E),
        streakAmberGraphic: Color(0xFFEB6D00),
        rewardGoldSurface: Color(0x14FAAD00),
        semanticBlue: Color(0xFF1268C7),
        danger: Color(0xFFD83651),
      );
    }
    return const DesktopJournalTokens(
      background: Color(0xFF090A11),
      sidebarSurface: Color(0xFF0C0D15),
      mainSurface: Color(0xFF090A11),
      railSurface: Color(0xFF0B0C14),
      cardSurface: Color(0xFF11121A),
      raisedSurface: Color(0xFF151620),
      outline: Color(0xFF292B38),
      subtleOutline: Color(0xFF1C1E29),
      text: Color(0xFFF3F1F8),
      mutedText: Color(0xFF9491A4),
      profilePurple: Color(0xFF765BFF),
      rewardGold: Color(0xFFFFC21A),
      successGreen: Color(0xFF2ED36F),
      streakAmber: Color(0xFFFF8A1F),
      rewardGoldGraphic: Color(0xFFFFC21A),
      successGreenGraphic: Color(0xFF2ED36F),
      streakAmberGraphic: Color(0xFFFF8A1F),
      rewardGoldSurface: Color(0x17FFC21A),
      semanticBlue: Color(0xFF2D8CFF),
      danger: Color(0xFFFF315B),
    );
  }

  static const Duration fastMotion = Duration(milliseconds: 140);
  static const Duration standardMotion = Duration(milliseconds: 220);
  static const Curve motionCurve = Curves.easeOutCubic;

  static const double navRadius = DesktopScale.radiusM;
  static const double skillRadius = DesktopScale.radiusM;
  static const double statRadius = DesktopScale.radiusL;
  static const double taskRadius = DesktopScale.radiusM;

  // Shared desktop header geometry. Keep the selected-skill panel aligned
  // with the same density system as the rest of the three-panel workspace.
  static const EdgeInsets selectedSkillHeaderPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );
  static const double selectedSkillHeaderIconSize = 76;
  static const double selectedSkillHeaderCompactIconSize = 64;
  static const double selectedSkillHeaderContentGap = 18;
  static const double selectedSkillHeaderRowGap = 8;
  static const double selectedSkillHeaderActionWidth = 176;
}
