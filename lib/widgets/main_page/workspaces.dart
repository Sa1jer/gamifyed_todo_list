part of '../main_page.dart';

class _ActWorkspace extends StatelessWidget {
  final void Function(String taskId, Offset position) onComplete;
  final void Function(String taskId, Offset position) onMinimumAction;
  final VoidCallback onCreateFirstSkill;
  final ValueChanged<Skill> onOpenRoadmap;
  final Key? createFirstSkillButtonKey;
  final Key? createFirstQuestButtonKey;
  final Key? nextQuestActionKey;

  const _ActWorkspace({
    super.key,
    required this.onComplete,
    required this.onMinimumAction,
    required this.onCreateFirstSkill,
    required this.onOpenRoadmap,
    this.createFirstSkillButtonKey,
    this.createFirstQuestButtonKey,
    this.nextQuestActionKey,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (MobileResponsiveMetrics.isMobileWidth(constraints.maxWidth)) {
          return _MobileActJournal(
            onComplete: onComplete,
            onMinimumAction: onMinimumAction,
            onCreateSkill: onCreateFirstSkill,
            createFirstSkillButtonKey: createFirstSkillButtonKey,
            createFirstQuestButtonKey: createFirstQuestButtonKey,
            nextQuestActionKey: nextQuestActionKey,
          );
        }

        return Column(
          children: [
            TodayDashboard(
              onComplete: onComplete,
              onMinimumAction: onMinimumAction,
              onCreateFirstSkill: onCreateFirstSkill,
              createFirstSkillButtonKey: createFirstSkillButtonKey,
              nextQuestActionKey: nextQuestActionKey,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _SkillTaskWorkspace(
                onComplete: onComplete,
                onMinimumAction: onMinimumAction,
                onOpenRoadmap: onOpenRoadmap,
                createFirstQuestButtonKey: createFirstQuestButtonKey,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MasteryWorkspace extends StatelessWidget {
  final bool isDark;
  final String? focusSkillId;
  final GlobalKey? canvasTutorialKey;
  final GlobalKey? inspectorTutorialKey;
  final GlobalKey? practiceTutorialKey;
  final Function(String taskId, Offset pos) onComplete;
  final Function(String taskId, Offset pos) onMinimumAction;

  const _MasteryWorkspace({
    super.key,
    required this.isDark,
    this.focusSkillId,
    this.canvasTutorialKey,
    this.inspectorTutorialKey,
    this.practiceTutorialKey,
    required this.onComplete,
    required this.onMinimumAction,
  });

  @override
  Widget build(BuildContext context) {
    return MasteryMapWorkspace(
      isDark: isDark,
      focusSkillId: focusSkillId,
      canvasTutorialKey: canvasTutorialKey,
      inspectorTutorialKey: inspectorTutorialKey,
      practiceTutorialKey: practiceTutorialKey,
      onCompleteTask: onComplete,
      onMinimumAction: onMinimumAction,
    );
  }
}

class _ProgressWorkspace extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final bool showTutorialHint;
  final VoidCallback onClose;
  final VoidCallback? onTutorialComplete;
  final VoidCallback onOpenDailyVictories;
  final VoidCallback onOpenCharacterTimeline;
  final VoidCallback onOpenWeekly;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenBosses;
  final VoidCallback onOpenAchievements;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenRewards;

  const _ProgressWorkspace({
    super.key,
    required this.state,
    required this.isDark,
    this.showTutorialHint = false,
    required this.onClose,
    this.onTutorialComplete,
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

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ProgressHubContent(
        state: state,
        isDark: isDark,
        showTutorialHint: showTutorialHint,
        showCloseButton: true,
        onClose: onClose,
        onTutorialComplete: onTutorialComplete,
        subtitle: 'Что получилось, какой навык вырос и что продолжить.',
        onOpenDailyVictories: onOpenDailyVictories,
        onOpenCharacterTimeline: onOpenCharacterTimeline,
        onOpenWeekly: onOpenWeekly,
        onOpenStats: onOpenStats,
        onOpenCalendar: onOpenCalendar,
        onOpenBosses: onOpenBosses,
        onOpenAchievements: onOpenAchievements,
        onOpenHistory: onOpenHistory,
        onOpenRewards: onOpenRewards,
      ),
    );
  }
}

class _SkillTaskWorkspace extends StatelessWidget {
  final void Function(String taskId, Offset position) onComplete;
  final void Function(String taskId, Offset position) onMinimumAction;
  final ValueChanged<Skill> onOpenRoadmap;
  final Key? createFirstQuestButtonKey;

  const _SkillTaskWorkspace({
    required this.onComplete,
    required this.onMinimumAction,
    required this.onOpenRoadmap,
    this.createFirstQuestButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (MobileResponsiveMetrics.isMobileWidth(constraints.maxWidth)) {
          return Column(
            children: [
              const _CompactSkillSelector(),
              const SizedBox(height: 8),
              Expanded(
                child: TasksPanel(
                  onComplete: onComplete,
                  onMinimumAction: onMinimumAction,
                  createFirstQuestButtonKey: createFirstQuestButtonKey,
                ),
              ),
            ],
          );
        }

        final skillsWidth = constraints.maxWidth < 1050 ? 330.0 : 380.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: skillsWidth,
              child: SkillsPanel(onOpenRoadmap: onOpenRoadmap),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TasksPanel(
                onComplete: onComplete,
                onMinimumAction: onMinimumAction,
                createFirstQuestButtonKey: createFirstQuestButtonKey,
              ),
            ),
          ],
        );
      },
    );
  }
}
