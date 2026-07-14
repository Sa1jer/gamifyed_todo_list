import 'package:flutter/material.dart';

import '../../feedback_service.dart';
import '../../models.dart';
import '../../theme/app_typography.dart';
import '../../utils.dart';
import '../shared.dart';

class MasteryCollapsibleQuestSection extends StatefulWidget {
  final bool isDark;
  final Color color;
  final String title;
  final String subtitle;
  final int count;
  final Widget child;

  const MasteryCollapsibleQuestSection({
    super.key,
    required this.isDark,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.child,
  });

  @override
  State<MasteryCollapsibleQuestSection> createState() =>
      _MasteryCollapsibleQuestSectionState();
}

class _MasteryCollapsibleQuestSectionState
    extends State<MasteryCollapsibleQuestSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PressFeedback(
          scale: 0.99,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: widget.color.withAlpha(widget.isDark ? 18 : 12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.color.withAlpha(42)),
            ),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: widget.color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor(widget.isDark),
                      fontSize: 12.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(widget.isDark ? 34 : 22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: widget.color.withAlpha(55)),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: kMotionStandard,
          switchInCurve: kMotionCurve,
          switchOutCurve: kMotionExitCurve,
          child: _expanded
              ? Padding(
                  key: const ValueKey('expanded'),
                  padding: const EdgeInsets.only(top: 8),
                  child: widget.child,
                )
              : const SizedBox.shrink(key: ValueKey('collapsed')),
        ),
      ],
    );
  }
}

class MasteryStagePracticeQuestList extends StatelessWidget {
  final bool isDark;
  final Color color;
  final List<Task> activeTasks;
  final List<Task> completedTasks;
  final String emptyText;
  final void Function(Task task, ActionToastOrigin origin) onToggleQuest;
  final void Function(Task task, ActionToastOrigin origin) onMinimumAction;
  final ValueChanged<Task> onEditQuest;
  final ValueChanged<Task> onDeleteQuest;
  final bool shrinkWrap;

  const MasteryStagePracticeQuestList({
    super.key,
    required this.isDark,
    required this.color,
    required this.activeTasks,
    required this.completedTasks,
    required this.emptyText,
    required this.onToggleQuest,
    required this.onMinimumAction,
    required this.onEditQuest,
    required this.onDeleteQuest,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final hasTasks = activeTasks.isNotEmpty || completedTasks.isNotEmpty;

    if (!hasTasks) {
      return Center(
        child: Text(
          emptyText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: sub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: [
        for (final task in activeTasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _MasteryInspectorQuestRow(
              task: task,
              isDark: isDark,
              color: color,
              muted: false,
              onToggle: (position) => onToggleQuest(task, position),
              onMinimumAction: (position) => onMinimumAction(task, position),
              onEdit: () => onEditQuest(task),
              onDelete: () => onDeleteQuest(task),
            ),
          ),
        if (activeTasks.isNotEmpty && completedTasks.isNotEmpty)
          const SizedBox(height: 7),
        for (final task in completedTasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _MasteryInspectorQuestRow(
              task: task,
              isDark: isDark,
              color: color,
              muted: true,
              onToggle: (position) => onToggleQuest(task, position),
              onMinimumAction: (position) => onMinimumAction(task, position),
              onEdit: () => onEditQuest(task),
              onDelete: () => onDeleteQuest(task),
            ),
          ),
      ],
    );
  }
}

class _MasteryInspectorQuestRow extends StatelessWidget {
  final Task task;
  final bool isDark;
  final Color color;
  final bool muted;
  final ValueChanged<ActionToastOrigin> onToggle;
  final ValueChanged<ActionToastOrigin> onMinimumAction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MasteryInspectorQuestRow({
    required this.task,
    required this.isDark,
    required this.color,
    required this.muted,
    required this.onToggle,
    required this.onMinimumAction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final toggleKey = GlobalKey(
      debugLabel: 'roadmap-inspector-toggle-${task.id}',
    );
    final minimumKey = GlobalKey(
      debugLabel: 'roadmap-inspector-minimum-${task.id}',
    );
    final done = task.isDone;
    final sub = subtext(isDark);
    final rowColor = done ? const Color(0xFF34C759) : color;
    final canStartMinimum =
        task.hasMinimumAction && !task.isDone && !task.isMinimumActionDone;
    final metadata = [
      typeLabel[task.type]!,
      priorityLabel[task.priority]!,
      if (task.hasMinimumAction) 'минимум есть',
    ].join(' · ');
    return AnimatedContainer(
      duration: kMotionStandard,
      curve: kMotionCurve,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: muted || done
            ? surface(isDark).withAlpha(isDark ? 112 : 176)
            : (isDark ? const Color(0xFF14141C) : const Color(0xFFF4F5FA)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: done ? rowColor.withAlpha(42) : borderColor(isDark),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PressFeedback(
            key: toggleKey,
            scale: 0.9,
            onTap: () => onToggle(
              actionToastOriginForContext(
                toggleKey.currentContext ?? context,
                kind: ActionToastOriginKind.roadmapInspectorTask,
                zone: ActionToastZone.roadmapInspector,
                sourceId: task.id,
              ),
            ),
            child: MasteryQuestToggleCircle(
              done: done,
              color: rowColor,
              isDark: isDark,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: context.appTextTheme.titleSmall?.copyWith(
                    color: done ? sub : textColor(isDark),
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  done ? 'Завершено' : metadata,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appTextRoles.compactMetadata.copyWith(
                    color: sub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canStartMinimum) ...[
                MasteryRoadmapMinimumButton(
                  key: minimumKey,
                  isDark: isDark,
                  color: color,
                  onTap: () => onMinimumAction(
                    actionToastOriginForContext(
                      minimumKey.currentContext ?? context,
                      kind: ActionToastOriginKind.minimumAction,
                      zone: ActionToastZone.roadmapInspector,
                      sourceId: task.id,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '+${task.xpReward} XP',
                style: context.appTextRoles.reward.copyWith(
                  color: done ? sub : rowColor,
                ),
              ),
              const SizedBox(width: 8),
              PressFeedback(
                scale: 0.9,
                tooltip: 'Редактировать',
                onTap: onEdit,
                child: Icon(Icons.edit_outlined, color: sub, size: 18),
              ),
              const SizedBox(width: 7),
              PressFeedback(
                key: ValueKey('roadmap-delete-task-${task.id}'),
                scale: 0.9,
                tooltip: 'Удалить квест',
                onTap: () {
                  AppFeedback.destructive();
                  onDelete();
                },
                child: Icon(Icons.delete_outline, color: sub, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MasteryQuestToggleCircle extends StatelessWidget {
  final bool done;
  final Color color;
  final bool isDark;
  final double size;

  const MasteryQuestToggleCircle({
    super.key,
    required this.done,
    required this.color,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = done ? const Color(0xFF34C759) : color;
    return AnimatedContainer(
      duration: kMotionStandard,
      curve: kMotionCurve,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? activeColor : Colors.transparent,
        border: Border.all(color: activeColor, width: 2),
        boxShadow: done
            ? [
                BoxShadow(
                  color: activeColor.withAlpha(isDark ? 80 : 52),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: kMotionStandard,
        switchInCurve: kMotionCurve,
        switchOutCurve: kMotionExitCurve,
        child: done
            ? Icon(
                Icons.check,
                key: const ValueKey('done'),
                size: size * 0.58,
                color: Colors.white,
              )
            : const SizedBox(key: ValueKey('active')),
      ),
    );
  }
}

class MasteryRoadmapMinimumButton extends StatelessWidget {
  final bool isDark;
  final Color color;
  final VoidCallback onTap;

  const MasteryRoadmapMinimumButton({
    super.key,
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      scale: 0.92,
      tooltip: 'Сделать минимальный шаг',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 34 : 24),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: color, size: 13),
            const SizedBox(width: 3),
            Text(
              'Минимум',
              style: TextStyle(
                color: color,
                fontSize: 10.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
