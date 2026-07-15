import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../theme/app_typography.dart';
import '../../utils.dart';
import '../desktop_journal_tokens.dart';
import '../shared.dart';

/// Desktop focus and weekly activity rail with a local hover rebuild boundary.
class DesktopRightRail extends StatelessWidget {
  const DesktopRightRail({
    super.key,
    required this.state,
    required this.tokens,
    required this.onComplete,
  });

  final AppState state;
  final DesktopJournalTokens tokens;
  final void Function(String taskId, ActionToastOrigin origin) onComplete;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.appTextTheme;
    final roles = context.appTextRoles;
    final today = DateTime.now();
    final completedToday = state.tasks
        .where(
          (task) =>
              task.isSkillTask &&
              task.isDone &&
              task.lastCompletedAt != null &&
              isSameDate(task.lastCompletedAt!, today),
        )
        .toList(growable: false);
    final active = state.tasks
        .where((task) => task.isSkillTask && !task.isDone)
        .toList(growable: false);
    final focusTasks = <Task>[...completedToday, ...active];
    final completedCount = completedToday.length;
    final totalCount = focusTasks.length;
    final focusProgress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final weekly = _weekActivity(state, today);
    final maxWeekly = weekly.fold<int>(0, math.max);
    final skills = state.roadmapSkills;

    return ColoredBox(
      color: tokens.railSurface,
      child: Scrollbar(
        child: ListView(
          key: const ValueKey('desktop-right-rail-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            _RailHeading(
              icon: Icons.adjust_rounded,
              title: 'Фокус на сегодня',
              color: tokens.profilePurple,
              tokens: tokens,
            ),
            const SizedBox(height: 16),
            Semantics(
              label:
                  'Фокус на сегодня, выполнено $completedCount из $totalCount квестов, ${(focusProgress * 100).round()} процентов',
              child: Row(
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: focusProgress,
                          strokeWidth: 5,
                          backgroundColor: tokens.profilePurple.withValues(
                            alpha: 0.13,
                          ),
                          valueColor: AlwaysStoppedAnimation(
                            tokens.profilePurple,
                          ),
                        ),
                        Center(
                          child: Text(
                            '${(focusProgress * 100).round()}%',
                            style: roles.numericRing.copyWith(
                              color: tokens.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedCount/$totalCount',
                          style: roles.statValue.copyWith(color: tokens.text),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'квестов выполнено',
                          style: roles.compactMetadata.copyWith(
                            color: tokens.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: tokens.subtleOutline),
            const SizedBox(height: 16),
            if (focusTasks.isEmpty)
              _RailEmpty(tokens: tokens, text: 'Квестов для фокуса пока нет')
            else
              ...focusTasks
                  .take(4)
                  .map(
                    (task) => Padding(
                      key: ValueKey('desktop-focus-task-${task.id}'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _FocusTask(
                        state: state,
                        task: task,
                        tokens: tokens,
                        onComplete: onComplete,
                      ),
                    ),
                  ),
            const SizedBox(height: 18),
            Divider(height: 1, color: tokens.subtleOutline),
            const SizedBox(height: 18),
            Text(
              'ЗА НЕДЕЛЮ',
              key: const ValueKey('desktop-weekly-section-title'),
              style: roles.sectionEyebrow.copyWith(color: tokens.mutedText),
            ),
            const SizedBox(height: 10),
            _WeeklyBars(
              values: weekly,
              maxValue: maxWeekly,
              todayIndex: today.weekday - 1,
              tokens: tokens,
            ),
            const SizedBox(height: 20),
            Divider(
              key: const ValueKey('desktop-weekly-xp-divider'),
              height: 1,
              color: tokens.subtleOutline,
            ),
            const SizedBox(height: 20),
            Text(
              'XP ПО НАВЫКАМ',
              key: const ValueKey('desktop-skill-xp-section-title'),
              style: roles.sectionEyebrow.copyWith(color: tokens.mutedText),
            ),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              _RailEmpty(tokens: tokens, text: 'Навыки появятся после создания')
            else
              ...skills.map(
                (skill) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Semantics(
                    label: '${skill.name}, ${skill.xp} XP текущего уровня',
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: skill.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            skill.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${skill.xp}',
                          style: roles.compactMetadata.copyWith(
                            color: skill.color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailHeading extends StatelessWidget {
  const _RailHeading({
    required this.icon,
    required this.title,
    required this.color,
    required this.tokens,
  });

  final IconData icon;
  final String title;
  final Color color;
  final DesktopJournalTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: context.appTextTheme.titleMedium?.copyWith(
              color: tokens.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _FocusTask extends StatefulWidget {
  const _FocusTask({
    required this.state,
    required this.task,
    required this.tokens,
    required this.onComplete,
  });

  final AppState state;
  final Task task;
  final DesktopJournalTokens tokens;
  final void Function(String taskId, ActionToastOrigin origin) onComplete;

  @override
  State<_FocusTask> createState() => _FocusTaskState();
}

class _FocusTaskState extends State<_FocusTask> {
  bool _hovered = false;
  bool _focused = false;
  ActionToastOrigin? _origin;
  final GlobalKey _checkKey = GlobalKey();

  ActionToastOrigin _checkOrigin() => actionToastOriginForContext(
    _checkKey.currentContext ?? context,
    kind: ActionToastOriginKind.focusTask,
    zone: ActionToastZone.rightRail,
    sourceId: widget.task.id,
  );

  void _activate(ActionToastOrigin? origin) {
    final task = widget.task;
    if (task.isDone) {
      widget.state.uncompleteTask(task.id);
      return;
    }
    widget.onComplete(task.id, origin ?? _checkOrigin());
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final task = widget.task;
    final tokens = widget.tokens;
    final skill = state.roadmapSkills
        .where((item) => item.id == task.skillId)
        .firstOrNull;
    final color = skill?.color ?? tokens.profilePurple;
    final reward = task.isDone
        ? math.max(task.earnedXP, task.xpReward)
        : state.previewEarnedXP(task);
    final active = _hovered || _focused;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final textTheme = context.appTextTheme;
    final roles = context.appTextRoles;
    return Semantics(
      button: true,
      checked: task.isDone,
      label: task.isDone
          ? '${task.title}, выполнено, вернуть квест'
          : '${task.title}, выполнить квест, +$reward XP',
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) {
          if (_hovered != value) setState(() => _hovered = value);
        },
        onShowFocusHighlight: (value) {
          if (_focused != value) setState(() => _focused = value);
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate(null);
              return null;
            },
          ),
        },
        child: AnimatedContainer(
          key: ValueKey('desktop-focus-surface-${task.id}'),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 110),
          curve: DesktopJournalTokens.motionCurve,
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? Color.alphaBlend(
                    color.withValues(alpha: 0.045),
                    tokens.raisedSurface,
                  )
                : task.isDone
                ? Color.alphaBlend(
                    tokens.successGreen.withValues(alpha: 0.045),
                    tokens.cardSurface,
                  )
                : tokens.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.34)
                  : task.isDone
                  ? tokens.successGreen.withValues(alpha: 0.18)
                  : tokens.outline,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final reflowReward =
                  constraints.maxWidth < 205 || textScale >= 1.6;
              final compact = constraints.maxWidth < 188 && textScale < 1.6;
              final titleMaxLines = textScale >= 1.6
                  ? 3
                  : compact
                  ? 1
                  : 2;
              final titleStyle =
                  (compact ? textTheme.labelLarge : textTheme.titleSmall)
                      ?.copyWith(
                        color: task.isDone ? tokens.mutedText : tokens.text,
                        fontWeight: FontWeight.w800,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      );
              final metadata = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      skill?.name ?? 'Навык',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: roles.compactMetadata.copyWith(
                        color: tokens.mutedText,
                      ),
                    ),
                  ),
                ],
              );
              final rewardText = Text(
                '+$reward',
                key: ValueKey('desktop-focus-reward-${task.id}'),
                maxLines: 1,
                style: roles.reward.copyWith(
                  color: task.isDone ? tokens.successGreen : tokens.rewardGold,
                ),
              );
              final title = Text(
                task.title,
                key: ValueKey('desktop-focus-title-${task.id}'),
                maxLines: titleMaxLines,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    button: true,
                    checked: task.isDone,
                    label: task.isDone
                        ? 'Вернуть квест ${task.title}'
                        : 'Выполнить квест ${task.title}',
                    child: InkResponse(
                      key: _checkKey,
                      radius: 22,
                      onTapDown: (_) => _origin = _checkOrigin(),
                      onTapCancel: () => _origin = null,
                      onTap: () {
                        final origin = _origin;
                        _origin = null;
                        _activate(origin);
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: task.isDone
                              ? tokens.successGreen
                              : color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: task.isDone ? tokens.successGreen : color,
                          ),
                        ),
                        child: task.isDone
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 15,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 4),
                        if (reflowReward)
                          Row(
                            children: [
                              Expanded(child: metadata),
                              const SizedBox(width: 8),
                              rewardText,
                            ],
                          )
                        else
                          metadata,
                      ],
                    ),
                  ),
                  if (!reflowReward) ...[
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 32),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: rewardText,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({
    required this.values,
    required this.maxValue,
    required this.todayIndex,
    required this.tokens,
  });

  final List<int> values;
  final int maxValue;
  final int todayIndex;
  final DesktopJournalTokens tokens;

  @override
  Widget build(BuildContext context) {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final chartHeight = textScale >= 1.6 ? 104.0 : 66.0;
    final summary = List.generate(
      7,
      (index) => '${labels[index]}: ${values[index]}',
    ).join(', ');
    return Semantics(
      label: 'Активность за неделю: $summary',
      child: SizedBox(
        key: const ValueKey('desktop-weekly-chart'),
        height: chartHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            final value = values[index];
            final fraction = maxValue == 0 ? 0.0 : value / maxValue;
            final isToday = index == todayIndex;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: '${labels[index]}: $value выполнено',
                      child: AnimatedContainer(
                        duration: DesktopJournalTokens.standardMotion,
                        curve: DesktopJournalTokens.motionCurve,
                        width: 8,
                        height: 7 + 32 * fraction,
                        decoration: BoxDecoration(
                          color: isToday
                              ? tokens.profilePurple
                              : tokens.profilePurple.withValues(alpha: 0.43),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      labels[index],
                      style: context.appTextTheme.labelSmall?.copyWith(
                        color: isToday
                            ? tokens.profilePurple
                            : tokens.mutedText,
                        letterSpacing: 0,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _RailEmpty extends StatelessWidget {
  const _RailEmpty({required this.tokens, required this.text});

  final DesktopJournalTokens tokens;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.appTextTheme.bodySmall?.copyWith(
        color: tokens.mutedText,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

List<int> _weekActivity(AppState state, DateTime now) {
  final weekStart = startOfWeek(now);
  return List.generate(7, (index) {
    final date = weekStart.add(Duration(days: index));
    return state.completionHistoryByDate[date]?.length ?? 0;
  }, growable: false);
}
