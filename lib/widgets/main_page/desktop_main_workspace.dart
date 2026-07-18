import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../engines/return_context_resolver.dart';
import '../../models.dart';
import '../../theme/app_typography.dart';
import '../../utils.dart';
import '../desktop_journal_tokens.dart';
import '../inbox_panel.dart';
import '../return_context_card.dart';
import '../shared.dart';
import 'desktop_quest_row.dart';
import 'desktop_selected_skill_header.dart';
import 'desktop_workspace_support.dart';

class DesktopMainWorkspace extends StatelessWidget {
  final AppState state;
  final Skill? skill;
  final DesktopJournalTokens tokens;
  final DesktopResponsiveMetrics metrics;
  final VoidCallback onAddSkill;
  final ValueChanged<Skill> onAddTask;
  final void Function(Skill skill, Task task) onEditTask;
  final void Function(String taskId, ActionToastOrigin origin) onComplete;
  final void Function(String taskId, ActionToastOrigin origin) onMinimumAction;
  final ReturnContextCandidate? returnContext;
  final VoidCallback? onContinueReturnContext;
  final VoidCallback? onAnotherReturnContext;
  final VoidCallback? onDismissReturnContext;

  const DesktopMainWorkspace({
    super.key,
    required this.state,
    required this.skill,
    required this.tokens,
    required this.metrics,
    required this.onAddSkill,
    required this.onAddTask,
    required this.onEditTask,
    required this.onComplete,
    required this.onMinimumAction,
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
    if (skill?.id == kInboxSkillId) {
      return InboxPanel(onComplete: onComplete, desktopJournal: true);
    }
    final currentSkill = skill;
    final stats = state.todayStats;
    final activeGlobal = state.tasks
        .where((task) => task.isSkillTask && !task.isDone)
        .length;
    final streak = state.tasks
        .where((task) => task.type == TaskType.repeating)
        .fold<int>(0, (value, task) => math.max(value, task.streak));
    final tasks = currentSkill == null
        ? const <Task>[]
        : state.tasksForSkill(currentSkill.id);
    final active = tasks.where((task) => !task.isDone).toList();
    final completed =
        tasks.where((task) => task.isDone && !task.isArchived).toList()
          ..sort((a, b) {
            final aAt = a.lastCompletedAt ?? a.updatedAt;
            final bAt = b.lastCompletedAt ?? b.updatedAt;
            return bAt.compareTo(aAt);
          });
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final hasQuestHistory =
        currentSkill != null &&
        (tasks.isNotEmpty ||
            state.history.any((entry) => entry.skillId == currentSkill.id));

    Widget buildTodaySummary() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tokens.streakAmber.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: tokens.streakAmber,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Действовать сегодня',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextTheme.titleLarge?.copyWith(
                  color: tokens.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 690 ? 4 : 2;
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final childAspectRatio = textScale >= 1.6
                ? (columns == 4 ? 1.25 : 1.6)
                : (columns == 4 ? 2.25 : 2.7);
            return GridView.count(
              key: const ValueKey('desktop-today-stats'),
              crossAxisCount: columns,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DesktopStatCard(
                  icon: Icons.check_rounded,
                  value: '${stats?.tasksCompleted ?? 0}',
                  label: 'Выполнено',
                  color: tokens.successGreen,
                  tokens: tokens,
                ),
                _DesktopStatCard(
                  icon: Icons.bolt_rounded,
                  value: '+${stats?.xpEarned ?? 0}',
                  label: 'XP сегодня',
                  color: tokens.rewardGold,
                  tokens: tokens,
                ),
                _DesktopStatCard(
                  icon: Icons.radio_button_unchecked_rounded,
                  value: '$activeGlobal',
                  label: 'Активных',
                  color: tokens.semanticBlue,
                  tokens: tokens,
                ),
                _DesktopStatCard(
                  icon: Icons.local_fire_department_outlined,
                  value: '$streak дн.',
                  label: 'Серия',
                  color: tokens.streakAmber,
                  tokens: tokens,
                ),
              ],
            );
          },
        ),
      ],
    );

    if (currentSkill != null && !hasQuestHistory) {
      final header = DesktopSelectedSkillHeader(
        skill: currentSkill,
        tokens: tokens,
        totalQuestCount: tasks.length,
        onAddTask: () => onAddTask(currentSkill),
      );
      final firstQuest = _DesktopFirstQuestEmpty(
        tokens: tokens,
        color: currentSkill.color,
      );
      return ColoredBox(
        color: tokens.mainSurface,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = EdgeInsets.fromLTRB(
              metrics.mainPadding,
              22,
              metrics.mainPadding,
              32,
            );
            final needsScrollableLayout =
                constraints.maxHeight < 540 ||
                MediaQuery.textScalerOf(context).scale(1) >= 1.6;
            if (needsScrollableLayout) {
              return ListView(
                key: const ValueKey('desktop-first-quest-scroll'),
                padding: padding,
                children: [
                  buildTodaySummary(),
                  if (returnContext != null) ...[
                    SizedBox(height: metrics.sectionGap + 10),
                    _buildReturnContext(reduceMotion),
                  ],
                  SizedBox(height: metrics.sectionGap + 10),
                  header,
                  const SizedBox(height: 24),
                  firstQuest,
                ],
              );
            }
            return Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTodaySummary(),
                  if (returnContext != null) ...[
                    SizedBox(height: metrics.sectionGap + 10),
                    _buildReturnContext(reduceMotion),
                  ],
                  SizedBox(height: metrics.sectionGap + 10),
                  header,
                  const SizedBox(height: 18),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, workspaceConstraints) => Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: math.min(
                              720,
                              workspaceConstraints.maxWidth,
                            ),
                          ),
                          child: firstQuest,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return ColoredBox(
      color: tokens.mainSurface,
      child: Scrollbar(
        child: ListView(
          key: const ValueKey('desktop-main-scroll'),
          padding: EdgeInsets.fromLTRB(
            metrics.mainPadding,
            22,
            metrics.mainPadding,
            32,
          ),
          children: [
            buildTodaySummary(),
            if (returnContext != null) ...[
              SizedBox(height: metrics.sectionGap + 10),
              _buildReturnContext(reduceMotion),
            ],
            SizedBox(height: metrics.sectionGap + 10),
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : DesktopJournalTokens.standardMotion,
              switchInCurve: DesktopJournalTokens.motionCurve,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topLeft,
                children: [...previousChildren, ?currentChild],
              ),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: currentSkill == null
                  ? _DesktopNoSkillMain(
                      key: const ValueKey('desktop-no-skill'),
                      tokens: tokens,
                      onAdd: onAddSkill,
                    )
                  : Column(
                      key: ValueKey('desktop-selected-${currentSkill.id}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DesktopSelectedSkillHeader(
                          skill: currentSkill,
                          tokens: tokens,
                          totalQuestCount: tasks.length,
                          onAddTask: () => onAddTask(currentSkill),
                        ),
                        const SizedBox(height: 24),
                        if (!hasQuestHistory)
                          _DesktopFirstQuestEmpty(
                            tokens: tokens,
                            color: currentSkill.color,
                          )
                        else ...[
                          _DesktopQuestSectionTitle(
                            label: 'АКТИВНЫЕ',
                            count: active.length,
                            tokens: tokens,
                          ),
                          const SizedBox(height: 10),
                          if (active.isEmpty)
                            Text(
                              'Активных квестов пока нет.',
                              style: TextStyle(
                                color: tokens.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ...active.map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: DesktopQuestRow(
                                key: ValueKey('desktop-active-task-${task.id}'),
                                state: state,
                                task: task,
                                skill: currentSkill,
                                tokens: tokens,
                                onComplete: onComplete,
                                onMinimumAction: onMinimumAction,
                                onEdit: () => onEditTask(currentSkill, task),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _DesktopQuestSectionTitle(
                            label: 'ВЫПОЛНЕНО',
                            count: completed.length,
                            tokens: tokens,
                          ),
                          const SizedBox(height: 10),
                          if (completed.isEmpty)
                            Text(
                              'Завершённые квесты появятся здесь.',
                              style: TextStyle(
                                color: tokens.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ...completed.map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: DesktopQuestRow(
                                key: ValueKey(
                                  'desktop-completed-task-${task.id}',
                                ),
                                state: state,
                                task: task,
                                skill: currentSkill,
                                tokens: tokens,
                                onComplete: onComplete,
                                onMinimumAction: onMinimumAction,
                                onEdit: () => onEditTask(currentSkill, task),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnContext(bool reduceMotion) {
    return ReturnContextCard(
      candidate: returnContext!,
      isDark: state.isDark,
      desktop: true,
      reducedMotion: reduceMotion || state.reducedMotion,
      onContinue: onContinueReturnContext!,
      onAnotherAction: onAnotherReturnContext!,
      onDismiss: onDismissReturnContext!,
    );
  }
}

class _DesktopStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final DesktopJournalTokens tokens;

  const _DesktopStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          // Compact stat cards have a bounded row height. Reclaim a little
          // vertical room before enlarged text would overflow that contract.
          vertical: textScale >= 1.2 ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(DesktopJournalTokens.statRadius),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.mutedText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopQuestSectionTitle extends StatelessWidget {
  final String label;
  final int count;
  final DesktopJournalTokens tokens;

  const _DesktopQuestSectionTitle({
    required this.label,
    required this.count,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label · $count',
      style: TextStyle(
        color: tokens.mutedText,
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.55,
      ),
    );
  }
}

class _DesktopFirstQuestEmpty extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final Color color;

  const _DesktopFirstQuestEmpty({required this.tokens, required this.color});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeText = textScale >= 1.6;
    return Container(
      key: const ValueKey('desktop-first-quest-empty'),
      constraints: BoxConstraints(
        minHeight: largeText ? 178 : 156,
        maxWidth: 720,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: largeText ? 26 : 32,
        vertical: largeText ? 20 : 24,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(DesktopJournalTokens.taskRadius),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded, color: color, size: largeText ? 30 : 34),
          const SizedBox(height: 12),
          Text(
            'Добавь свой первый квест',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.appTextTheme.titleMedium?.copyWith(
              color: tokens.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Начни с небольшого действия, которое поможет двигаться к цели.',
            maxLines: largeText ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.appTextTheme.bodySmall?.copyWith(
              color: tokens.mutedText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNoSkillMain extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final VoidCallback onAdd;

  const _DesktopNoSkillMain({
    super.key,
    required this.tokens,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return _DesktopInlineEmpty(
      tokens: tokens,
      text: 'Создай первый навык, чтобы начать путь.',
      actionLabel: 'Создать навык',
      onAction: onAdd,
    );
  }
}

class _DesktopInlineEmpty extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const _DesktopInlineEmpty({
    required this.tokens,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.cardSurface,
        borderRadius: BorderRadius.circular(DesktopJournalTokens.taskRadius),
        border: Border.all(color: tokens.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: tokens.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          DesktopCompactButton(
            label: actionLabel,
            icon: Icons.add_rounded,
            color: tokens.profilePurple,
            onTap: onAction,
          ),
        ],
      ),
    );
  }
}
