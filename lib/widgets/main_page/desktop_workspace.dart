import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../engines/return_context_resolver.dart';
import '../../models.dart';
import '../desktop_journal_tokens.dart';
import '../shared.dart';
import 'desktop_main_workspace.dart';
import 'desktop_right_rail.dart';
import 'desktop_sidebar.dart';
import 'desktop_workspace_support.dart';
import 'mode.dart';

export 'desktop_workspace_support.dart'
    show DesktopCompactButton, DesktopInteractiveSurface;

class DesktopWorkspaceShell extends StatelessWidget {
  final AppState state;
  final WorkspaceMode mode;
  final DesktopResponsiveMetrics metrics;
  final ValueChanged<WorkspaceMode> onModeChanged;
  final VoidCallback onAddSkill;
  final VoidCallback onOpenRewards;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenProfile;
  final VoidCallback? onDebugAppTap;
  final ValueChanged<Skill> onOpenRoadmap;
  final void Function(String taskId, ActionToastOrigin origin) onComplete;
  final void Function(String taskId, ActionToastOrigin origin) onMinimumAction;
  final Widget? alternateWorkspace;
  final GlobalKey? profileKey;
  final GlobalKey? rewardsKey;
  final GlobalKey? roadmapKey;
  final GlobalKey? statsKey;
  final GlobalKey? contextualToastHostKey;
  final GlobalKey? rightRailKey;
  final ReturnContextCandidate? returnContext;
  final VoidCallback? onContinueReturnContext;
  final VoidCallback? onAnotherReturnContext;
  final VoidCallback? onDismissReturnContext;

  const DesktopWorkspaceShell({
    super.key,
    required this.state,
    required this.mode,
    required this.metrics,
    required this.onModeChanged,
    required this.onAddSkill,
    required this.onOpenRewards,
    required this.onOpenStatistics,
    required this.onOpenSettings,
    required this.onOpenProfile,
    this.onDebugAppTap,
    required this.onOpenRoadmap,
    required this.onComplete,
    required this.onMinimumAction,
    this.alternateWorkspace,
    this.profileKey,
    this.rewardsKey,
    this.roadmapKey,
    this.statsKey,
    this.contextualToastHostKey,
    this.rightRailKey,
    this.returnContext,
    this.onContinueReturnContext,
    this.onAnotherReturnContext,
    this.onDismissReturnContext,
  }) : assert(
         returnContext == null ||
             (onContinueReturnContext != null &&
                 onAnotherReturnContext != null &&
                 onDismissReturnContext != null),
       );

  @override
  Widget build(BuildContext context) {
    final tokens = DesktopJournalTokens.resolve(state.isDark);
    final selected = state.selectedSkill;
    final actMode = mode == WorkspaceMode.act;
    final effectiveSkill = mode == WorkspaceMode.mastery
        ? selected?.id == kInboxSkillId
              ? null
              : selected
        : selected ?? state.roadmapSkills.firstOrNull;

    return ColoredBox(
      key: const ValueKey('desktop-three-panel-shell'),
      color: tokens.background,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const ValueKey('desktop-sidebar-region'),
              width: metrics.sidebarWidth,
              child: DesktopSidebar(
                state: state,
                tokens: tokens,
                mode: mode,
                effectiveSkill: effectiveSkill,
                onModeChanged: onModeChanged,
                onAddSkill: onAddSkill,
                onOpenRewards: onOpenRewards,
                onOpenStatistics: onOpenStatistics,
                onOpenSettings: onOpenSettings,
                onOpenProfile: onOpenProfile,
                onDebugAppTap: onDebugAppTap,
                onEditSkill: (skill) =>
                    showDesktopEditSkill(context, state, skill),
                onDeleteSkill: (skill) =>
                    showDesktopDeleteSkill(context, state, skill),
                onOpenRoadmap: onOpenRoadmap,
                profileKey: profileKey,
                rewardsKey: rewardsKey,
                roadmapKey: roadmapKey,
                statsKey: statsKey,
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: tokens.outline),
            Expanded(
              key: const ValueKey('desktop-main-region'),
              child: KeyedSubtree(
                key: contextualToastHostKey,
                child: actMode
                    ? DesktopMainWorkspace(
                        state: state,
                        skill: effectiveSkill,
                        tokens: tokens,
                        metrics: metrics,
                        onAddSkill: onAddSkill,
                        onAddTask: (skill) =>
                            showDesktopAddTask(context, state, skill),
                        onEditTask: (skill, task) =>
                            showDesktopEditTask(context, state, skill, task),
                        onComplete: onComplete,
                        onMinimumAction: onMinimumAction,
                        returnContext: returnContext,
                        onContinueReturnContext: onContinueReturnContext,
                        onAnotherReturnContext: onAnotherReturnContext,
                        onDismissReturnContext: onDismissReturnContext,
                      )
                    : Padding(
                        padding: EdgeInsets.all(metrics.mainPadding),
                        child: alternateWorkspace ?? const SizedBox.shrink(),
                      ),
              ),
            ),
            if (actMode && metrics.showRightRail) ...[
              VerticalDivider(width: 1, thickness: 1, color: tokens.outline),
              KeyedSubtree(
                key: const ValueKey('desktop-right-rail-region'),
                child: SizedBox(
                  key: rightRailKey,
                  width: metrics.railWidth,
                  child: DesktopRightRail(
                    state: state,
                    tokens: tokens,
                    onComplete: onComplete,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
