part of '../main_page.dart';

class _ActWorkspace extends StatelessWidget {
  final void Function(String taskId, Offset position) onComplete;
  final void Function(String taskId, Offset position) onMinimumAction;
  final VoidCallback onCreateFirstSkill;
  final ValueChanged<Skill> onOpenSkillSettings;

  const _ActWorkspace({
    super.key,
    required this.onComplete,
    required this.onMinimumAction,
    required this.onCreateFirstSkill,
    required this.onOpenSkillSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TodayDashboard(
          onComplete: onComplete,
          onMinimumAction: onMinimumAction,
          onCreateFirstSkill: onCreateFirstSkill,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _SkillTaskWorkspace(
            onComplete: onComplete,
            onMinimumAction: onMinimumAction,
            onOpenSkillSettings: onOpenSkillSettings,
          ),
        ),
      ],
    );
  }
}

class _PlanWorkspace extends StatelessWidget {
  final bool isDark;
  final VoidCallback onOpenMasteryMap;

  const _PlanWorkspace({
    super.key,
    required this.isDark,
    required this.onOpenMasteryMap,
  });

  @override
  Widget build(BuildContext context) {
    return PlanningWorkspace(
      isDark: isDark,
      onOpenMasteryMap: onOpenMasteryMap,
    );
  }
}

class _MasteryWorkspace extends StatelessWidget {
  final bool isDark;
  final Function(String taskId, Offset pos) onComplete;
  final ValueChanged<Skill> onOpenSkillSettings;

  const _MasteryWorkspace({
    super.key,
    required this.isDark,
    required this.onComplete,
    required this.onOpenSkillSettings,
  });

  @override
  Widget build(BuildContext context) {
    return MasteryMapWorkspace(
      isDark: isDark,
      onCompleteTask: onComplete,
      onOpenSkillSettings: onOpenSkillSettings,
    );
  }
}

class _ProgressWorkspace extends StatelessWidget {
  final AppState state;
  final bool isDark;
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
  final ValueChanged<Skill> onOpenSkillSettings;

  const _SkillTaskWorkspace({
    required this.onComplete,
    required this.onMinimumAction,
    required this.onOpenSkillSettings,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              const _CompactSkillSelector(),
              const SizedBox(height: 8),
              Expanded(
                child: TasksPanel(
                  onComplete: onComplete,
                  onMinimumAction: onMinimumAction,
                  onOpenSkillSettings: onOpenSkillSettings,
                ),
              ),
            ],
          );
        }

        final skillsWidth = constraints.maxWidth < 1050 ? 330.0 : 380.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: skillsWidth, child: const SkillsPanel()),
            const SizedBox(width: 12),
            Expanded(
              child: TasksPanel(
                onComplete: onComplete,
                onMinimumAction: onMinimumAction,
                onOpenSkillSettings: onOpenSkillSettings,
              ),
            ),
          ],
        );
      },
    );
  }
}
