import 'package:flutter/material.dart';

import '../app_state.dart';
import 'progress_hub_dialog.dart';

class ProgressWorkspaceDestinations {
  final VoidCallback onOpenDailyVictories;
  final VoidCallback onOpenCharacterTimeline;
  final VoidCallback onOpenWeekly;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenBosses;
  final VoidCallback onOpenAchievements;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenRewards;

  const ProgressWorkspaceDestinations({
    required this.onOpenDailyVictories,
    required this.onOpenCharacterTimeline,
    required this.onOpenWeekly,
    required this.onOpenStats,
    required this.onOpenCalendar,
    required this.onOpenBosses,
    required this.onOpenAchievements,
    required this.onOpenHistory,
    required this.onOpenRewards,
  });
}

class ProgressWorkspace extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final bool showTutorialHint;
  final VoidCallback onClose;
  final VoidCallback? onTutorialComplete;
  final ProgressWorkspaceDestinations destinations;

  const ProgressWorkspace({
    super.key,
    required this.state,
    required this.isDark,
    this.showTutorialHint = false,
    required this.onClose,
    this.onTutorialComplete,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox.expand(
        child: ProgressHubContent(
          state: state,
          isDark: isDark,
          showTutorialHint: showTutorialHint,
          showCloseButton: constraints.maxWidth < 761,
          onClose: onClose,
          onTutorialComplete: onTutorialComplete,
          subtitle: 'Что получилось, какой навык вырос и что продолжить.',
          onOpenDailyVictories: destinations.onOpenDailyVictories,
          onOpenCharacterTimeline: destinations.onOpenCharacterTimeline,
          onOpenWeekly: destinations.onOpenWeekly,
          onOpenStats: destinations.onOpenStats,
          onOpenCalendar: destinations.onOpenCalendar,
          onOpenBosses: destinations.onOpenBosses,
          onOpenAchievements: destinations.onOpenAchievements,
          onOpenHistory: destinations.onOpenHistory,
          onOpenRewards: destinations.onOpenRewards,
        ),
      ),
    );
  }
}
