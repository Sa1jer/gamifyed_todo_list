import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'shared.dart';

Skill? todayDashboardSkillFor(AppState state, Task task) {
  if (!task.isSkillTask) return null;
  return state.skills.where((skill) => skill.id == task.skillId).firstOrNull;
}

SkillTreeNode? todayDashboardStageFor(AppState state, Task task) {
  final skill = todayDashboardSkillFor(state, task);
  final nodeId = task.treeNodeId;
  if (skill == null || nodeId == null) return null;
  return skill.treeNodes.where((node) => node.id == nodeId).firstOrNull;
}

bool todayDashboardShouldRecommendMinimumAction(Task task) {
  return task.hasMinimumAction &&
      !task.isDone &&
      !task.isMinimumActionDone &&
      (task.type == TaskType.midTerm ||
          task.type == TaskType.longTerm ||
          task.subtasks.length >= 3 ||
          task.xpReward >= 80);
}

class TodayStatsGrid extends StatelessWidget {
  final bool isDark;
  final int todayTasks;
  final int todayXp;
  final int activeQuests;
  final int dailyQuests;

  const TodayStatsGrid({
    super.key,
    required this.isDark,
    required this.todayTasks,
    required this.todayXp,
    required this.activeQuests,
    required this.dailyQuests,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _TodayStatTile(
                  isDark: isDark,
                  label: 'Сделано',
                  value: '$todayTasks',
                  icon: Icons.check_circle,
                  color: const Color(0xFF34C759),
                  muted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TodayStatTile(
                  isDark: isDark,
                  label: 'XP сегодня',
                  value: '$todayXp',
                  icon: Icons.bolt,
                  color: const Color(0xFFFFCC00),
                  muted: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _TodayStatTile(
                  isDark: isDark,
                  label: 'Активно',
                  value: '$activeQuests',
                  icon: Icons.list_alt,
                  color: const Color(0xFF4A9EFF),
                  muted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TodayStatTile(
                  isDark: isDark,
                  label: 'Повтор.',
                  value: '$dailyQuests',
                  icon: Icons.repeat,
                  color: const Color(0xFFFF9500),
                  muted: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TodayQuestQueue extends StatelessWidget {
  final AppState state;
  final String title;
  final String subtitle;
  final List<Task> tasks;
  final bool isDark;
  final void Function(String id, ActionToastOrigin origin) onComplete;
  final void Function(String id, ActionToastOrigin origin) onMinimumAction;

  const TodayQuestQueue({
    super.key,
    required this.state,
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return TodaySoftCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: txt,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: sub, fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: MotionFadeSlideSwitcher(
              child: tasks.isEmpty
                  ? Center(
                      key: const ValueKey('quest-queue-empty'),
                      child: Text(
                        'Добавьте один маленький квест',
                        style: TextStyle(color: sub, fontSize: 12),
                      ),
                    )
                  : ListView.separated(
                      key: const ValueKey('quest-queue-list'),
                      padding: EdgeInsets.zero,
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, index) {
                        final task = tasks[index];
                        final skill = state.skills
                            .where((s) => s.id == task.skillId)
                            .firstOrNull;
                        return MotionListItem(
                          key: ValueKey('quest-row-${task.id}'),
                          index: index,
                          slide: 5,
                          child: TodayQuestMiniRow(
                            task: task,
                            skill: skill,
                            stage: todayDashboardStageFor(state, task),
                            xp: state.previewEarnedXP(task),
                            buffBonus: state.previewBuffBonusXP(task),
                            minimumXp: state.previewMinimumActionXP(task),
                            isDark: isDark,
                            onComplete: onComplete,
                            onMinimumAction: onMinimumAction,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayQuestMiniRow extends StatelessWidget {
  final Task task;
  final Skill? skill;
  final SkillTreeNode? stage;
  final int xp;
  final int buffBonus;
  final int minimumXp;
  final bool isDark;
  final void Function(String id, ActionToastOrigin origin) onComplete;
  final void Function(String id, ActionToastOrigin origin) onMinimumAction;

  const TodayQuestMiniRow({
    super.key,
    required this.task,
    required this.skill,
    required this.stage,
    required this.xp,
    required this.buffBonus,
    required this.minimumXp,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = skill?.color ?? const Color(0xFF4A9EFF);
    final recommendsMinimum = todayDashboardShouldRecommendMinimumAction(task);
    final title = recommendsMinimum
        ? 'Минимум: ${task.minimumAction}'
        : task.title;
    final xpText = buffBonus > 0
        ? '+${xp + buffBonus} XP • эффект +$buffBonus'
        : '+$xp XP';
    final subtitle = recommendsMinimum
        ? 'Лёгкий старт • +$minimumXp XP'
        : stage != null
        ? 'Этап: ${stage!.title} • $xpText'
        : task.type == TaskType.repeating
        ? '${typeLabel[task.type]} • $xpText'
        : xpText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withAlpha(26)),
      ),
      child: Row(
        children: [
          Icon(skill?.icon ?? Icons.bolt, color: accent, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                recommendsMinimum
                    ? Text(
                        title,
                        style: TextStyle(
                          color: txt,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : TaskTitleWithDescription(
                        task: task,
                        maxLines: 1,
                        titleStyle: TextStyle(
                          color: txt,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        descriptionColor: sub,
                      ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(color: sub, fontSize: 9.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TodayQuickActionButton(
            task: task,
            color: accent,
            label: recommendsMinimum ? 'Старт' : 'OK',
            tooltip: recommendsMinimum
                ? 'Сделать лёгкий старт: ${task.minimumAction}'
                : 'Выполнить квест “${task.title}”',
            icon: recommendsMinimum ? Icons.play_arrow : Icons.check,
            compact: true,
            primary: false,
            originKind: recommendsMinimum
                ? ActionToastOriginKind.minimumAction
                : ActionToastOriginKind.questCheckbox,
            onTrigger: recommendsMinimum ? onMinimumAction : onComplete,
          ),
        ],
      ),
    );
  }
}

class TodayQuickActionButton extends StatelessWidget {
  final Task task;
  final Color color;
  final String label;
  final String tooltip;
  final IconData icon;
  final bool compact;
  final bool primary;
  final ActionToastZone zone;
  final ActionToastOriginKind originKind;
  final void Function(String id, ActionToastOrigin origin) onTrigger;

  const TodayQuickActionButton({
    super.key,
    required this.task,
    required this.color,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.compact,
    this.primary = true,
    this.zone = ActionToastZone.mainWorkspace,
    this.originKind = ActionToastOriginKind.questCheckbox,
    required this.onTrigger,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : color;
    final controlKey = GlobalKey(
      debugLabel: 'today-dashboard-action-control-${task.id}',
    );
    return Tooltip(
      message: tooltip,
      child: PressFeedback(
        scale: 0.96,
        onTap: () {
          final controlContext = controlKey.currentContext;
          onTrigger(
            task.id,
            actionToastOriginForContext(
              controlContext ?? context,
              kind: originKind,
              zone: zone,
              sourceId: task.id,
            ),
          );
        },
        child: Container(
          key: controlKey,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: primary ? color : color.withAlpha(18),
            borderRadius: BorderRadius.circular(9),
            border: primary ? null : Border.all(color: color.withAlpha(50)),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: color.withAlpha(58),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: compact
              ? Icon(icon, color: fg, size: 15)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: fg, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TodayStatTile extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool muted;

  const _TodayStatTile({
    required this.isDark,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return TodaySoftCard(
      isDark: isDark,
      accent: muted ? null : color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            right: 38,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: txt,
                      fontSize: 17,
                      fontWeight: muted ? FontWeight.w800 : FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(color: sub, fontSize: 10.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                icon,
                color: color.withAlpha(muted ? 210 : 255),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayDashboardCollapseButton extends StatelessWidget {
  final bool expanded;
  final Color color;
  final VoidCallback onTap;

  const TodayDashboardCollapseButton({
    super.key,
    required this.expanded,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: expanded
          ? 'Свернуть блок “Действовать сегодня”'
          : 'Показать блок “Действовать сегодня”',
      child: Semantics(
        button: true,
        expanded: expanded,
        child: PressFeedback(
          scale: 0.94,
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: color,
                  size: 19,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayTinyProgressLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TodayTinyProgressLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: color.withAlpha(190), fontSize: 10),
            ),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayStatusLabelData {
  final String label;
  final String value;
  final Color color;

  const TodayStatusLabelData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class TodayStatusRow extends StatelessWidget {
  final List<TodayStatusLabelData> labels;
  final bool compact;

  const TodayStatusRow({
    super.key,
    required this.labels,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    final visibleLabels = compact ? labels.take(3).toList() : labels;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < visibleLabels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _TodayTinyProgressLabel(
            label: visibleLabels[i].label,
            value: visibleLabels[i].value,
            color: visibleLabels[i].color,
          ),
        ],
      ],
    );
  }
}

class TodaySoftCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final bool prominent;

  const TodaySoftCard({
    super.key,
    required this.isDark,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(12),
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? borderColor(isDark);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131A) : const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(
            prominent
                ? 120
                : accent == null
                ? 48
                : 65,
          ),
        ),
        boxShadow: prominent
            ? [
                BoxShadow(
                  color: color.withAlpha(isDark ? 28 : 22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
