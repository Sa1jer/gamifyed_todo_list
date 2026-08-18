part of '../main_page.dart';

String? _validRoadmapSkillId(AppState state, String? requestedId) {
  if (requestedId == null) return null;
  return state.roadmapSkills.any((skill) => skill.id == requestedId)
      ? requestedId
      : null;
}

class _ActWorkspace extends StatelessWidget {
  final void Function(String taskId, ActionToastOrigin origin) onComplete;
  final void Function(String taskId, ActionToastOrigin origin) onMinimumAction;
  final VoidCallback onCreateFirstSkill;
  final ValueChanged<Skill> onOpenRoadmap;
  final Key? createFirstSkillButtonKey;
  final Key? createFirstQuestButtonKey;
  final Key? nextQuestActionKey;
  final GlobalKey<_MobileActJournalState>? mobileJournalKey;
  final ReturnContextCandidate? returnContext;
  final MomentumSnapshot? momentum;
  final VoidCallback? onContinueReturnContext;
  final VoidCallback? onAnotherReturnContext;
  final VoidCallback? onDismissReturnContext;

  const _ActWorkspace({
    super.key,
    required this.onComplete,
    required this.onMinimumAction,
    required this.onCreateFirstSkill,
    required this.onOpenRoadmap,
    this.createFirstSkillButtonKey,
    this.createFirstQuestButtonKey,
    this.nextQuestActionKey,
    this.mobileJournalKey,
    this.returnContext,
    this.momentum,
    this.onContinueReturnContext,
    this.onAnotherReturnContext,
    this.onDismissReturnContext,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (MobileResponsiveMetrics.isMobileWidth(constraints.maxWidth)) {
          return _MobileActJournal(
            key: mobileJournalKey,
            onComplete: onComplete,
            onMinimumAction: onMinimumAction,
            onCreateSkill: onCreateFirstSkill,
            createFirstSkillButtonKey: createFirstSkillButtonKey,
            createFirstQuestButtonKey: createFirstQuestButtonKey,
            nextQuestActionKey: nextQuestActionKey,
            returnContext: returnContext,
            momentum: momentum,
            onContinueReturnContext: onContinueReturnContext,
            onAnotherReturnContext: onAnotherReturnContext,
            onDismissReturnContext: onDismissReturnContext,
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
  final ValueChanged<String?>? onFocusSkillChanged;
  final void Function(String taskId, ActionToastOrigin origin) onComplete;
  final void Function(String taskId, ActionToastOrigin origin) onMinimumAction;

  const _MasteryWorkspace({
    super.key,
    required this.isDark,
    this.focusSkillId,
    this.canvasTutorialKey,
    this.inspectorTutorialKey,
    this.practiceTutorialKey,
    this.onFocusSkillChanged,
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
      onFocusSkillChanged: onFocusSkillChanged,
      onCompleteTask: onComplete,
      onMinimumAction: onMinimumAction,
    );
  }
}

class _SkillTaskWorkspace extends StatelessWidget {
  final void Function(String taskId, ActionToastOrigin origin) onComplete;
  final void Function(String taskId, ActionToastOrigin origin) onMinimumAction;
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
