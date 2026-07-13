import 'package:flutter/material.dart';

@immutable
class DesktopResponsiveMetrics {
  final double sidebarWidth;
  final double railWidth;
  final double mainPadding;
  final double sectionGap;
  final bool showRightRail;

  const DesktopResponsiveMetrics({
    required this.sidebarWidth,
    required this.railWidth,
    required this.mainPadding,
    required this.sectionGap,
    required this.showRightRail,
  });

  static const double desktopBreakpoint = 761;

  static bool isDesktopWidth(double width) => width >= desktopBreakpoint;

  factory DesktopResponsiveMetrics.forWidth(double width) {
    if (width < 1024) {
      return const DesktopResponsiveMetrics(
        sidebarWidth: 232,
        railWidth: 0,
        mainPadding: 14,
        sectionGap: 12,
        showRightRail: false,
      );
    }
    if (width < 1280) {
      return const DesktopResponsiveMetrics(
        sidebarWidth: 232,
        railWidth: 236,
        mainPadding: 16,
        sectionGap: 14,
        showRightRail: true,
      );
    }
    if (width < 1600) {
      return const DesktopResponsiveMetrics(
        sidebarWidth: 248,
        railWidth: 260,
        mainPadding: 22,
        sectionGap: 18,
        showRightRail: true,
      );
    }
    return const DesktopResponsiveMetrics(
      sidebarWidth: 264,
      railWidth: 288,
      mainPadding: 28,
      sectionGap: 20,
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
  final Color rewardGold;
  final Color successGreen;
  final Color semanticBlue;
  final Color streakAmber;
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
    required this.semanticBlue,
    required this.streakAmber,
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
        rewardGold: Color(0xFFB47700),
        successGreen: Color(0xFF168B4A),
        semanticBlue: Color(0xFF1268C7),
        streakAmber: Color(0xFFB76500),
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
      semanticBlue: Color(0xFF2D8CFF),
      streakAmber: Color(0xFFFF8A1F),
      danger: Color(0xFFFF315B),
    );
  }

  static const Duration fastMotion = Duration(milliseconds: 140);
  static const Duration standardMotion = Duration(milliseconds: 220);
  static const Curve motionCurve = Curves.easeOutCubic;

  static const double navRadius = 12;
  static const double skillRadius = 13;
  static const double statRadius = 15;
  static const double taskRadius = 13;

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
