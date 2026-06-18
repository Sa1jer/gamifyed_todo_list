part of '../planning_workspace.dart';

class _QuestPlanList extends StatelessWidget {
  final Skill skill;
  final _PlanningDiagnostics diagnostics;
  final bool isDark;
  final bool archiveExpanded;
  final VoidCallback onArchiveToggle;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;
  final bool showArchive;

  const _QuestPlanList({
    required this.skill,
    required this.diagnostics,
    required this.isDark,
    required this.archiveExpanded,
    required this.onArchiveToggle,
    required this.onEditTask,
    required this.onDeleteTask,
    this.showArchive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (diagnostics.activeTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: EmptyStateMessage(
                isDark: isDark,
                icon: Icons.post_add,
                title: 'Активных квестов нет',
                subtitle: 'Добавьте квест, чтобы связать цель с действием.',
              ),
            )
          else
            ...diagnostics.activeTasks.asMap().entries.map((entry) {
              final task = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == diagnostics.activeTasks.length - 1
                      ? 0
                      : 7,
                ),
                child: MotionListItem(
                  key: ValueKey('planning-active-${task.id}'),
                  index: entry.key,
                  child: _PlanningTaskRow(
                    skill: skill,
                    task: task,
                    isDark: isDark,
                    skillColor: skill.color,
                    onEdit: () => onEditTask(task),
                    onDelete: () => onDeleteTask(task),
                  ),
                ),
              );
            }),
          if (showArchive && diagnostics.completedTasks.isNotEmpty) ...[
            SizedBox(height: diagnostics.activeTasks.isEmpty ? 0 : 10),
            _ArchiveHeader(
              isDark: isDark,
              count: diagnostics.completedTasks.length,
              expanded: archiveExpanded,
              onTap: onArchiveToggle,
            ),
            MotionExpandable(
              expanded: archiveExpanded,
              expandedChild: Column(
                children: [
                  const SizedBox(height: 8),
                  ...diagnostics.completedTasks.asMap().entries.map((entry) {
                    final task = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            entry.key == diagnostics.completedTasks.length - 1
                            ? 0
                            : 7,
                      ),
                      child: _PlanningTaskRow(
                        skill: skill,
                        task: task,
                        isDark: isDark,
                        skillColor: skill.color,
                        done: true,
                        onEdit: () => onEditTask(task),
                        onDelete: () => onDeleteTask(task),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanningTaskRow extends StatelessWidget {
  final Skill skill;
  final Task task;
  final bool isDark;
  final Color skillColor;
  final bool done;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlanningTaskRow({
    required this.skill,
    required this.task,
    required this.isDark,
    required this.skillColor,
    required this.onEdit,
    required this.onDelete,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final reminder = _reminderLabel(task);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF101018) : const Color(0xFFF8F9FD))
            .withAlpha(done ? 145 : 255),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(isDark).withAlpha(210)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: skillColor.withAlpha(done ? 18 : 28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              done ? Icons.inventory_2_outlined : Icons.edit_note,
              color: done ? sub : skillColor,
              size: 14,
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
                  style: TextStyle(
                    color: done ? sub : txt,
                    fontSize: 13,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (task.hasMinimumAction) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Минимум: ${task.minimumAction}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: sub,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    TaskBadge(
                      label: typeLabel[task.type]!,
                      color: typeColor[task.type]!,
                    ),
                    TaskBadge(
                      label: priorityLabel[task.priority]!,
                      color: priorityColor[task.priority]!,
                      icon: Icons.flag,
                    ),
                    TaskBadge(
                      label: '${task.xpReward} XP',
                      color: const Color(0xFF8E8E93),
                      icon: Icons.auto_awesome,
                    ),
                    if (task.type == TaskType.repeating)
                      TaskBadge(
                        label: freqLabel[task.repeatFrequency]!,
                        color: const Color(0xFF4A9EFF),
                        icon: Icons.repeat,
                      ),
                    if (task.subtasks.isNotEmpty)
                      TaskBadge(
                        label:
                            '${task.subtaskCompletedCount}/${task.subtasks.length}',
                        color: const Color(0xFF8E8E93),
                        icon: Icons.checklist,
                      ),
                    if (task.tags.isNotEmpty)
                      TaskBadge(
                        label: '${task.tags.length} конт.',
                        color: const Color(0xFF8E8E93),
                        icon: Icons.sell_outlined,
                      ),
                    if (reminder != null)
                      TaskBadge(
                        label: reminder,
                        color: const Color(0xFFAF52DE),
                        icon: Icons.notifications_active,
                      ),
                    if (task.hasMinimumAction && task.isMinimumActionDone)
                      TaskBadge(
                        label: 'старт сделан',
                        color: const Color(0xFF34C759),
                        icon: Icons.bolt,
                      ),
                    if (!task.hasMinimumAction && !done)
                      TaskBadge(
                        label: 'нет минимума',
                        color: const Color(0xFF8E8E93),
                        icon: Icons.bolt_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              MiniBtn(
                icon: Icons.edit,
                color: const Color(0xFF8E8E93),
                onTap: onEdit,
                tooltip: 'Настроить квест',
              ),
              MiniBtn(
                icon: Icons.delete_outline,
                color: const Color(0xFFFF3B30),
                onTap: onDelete,
                tooltip: 'Удалить квест',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchiveHeader extends StatelessWidget {
  final bool isDark;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  const _ArchiveHeader({
    required this.isDark,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: sub.withAlpha(isDark ? 14 : 10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor(isDark)),
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: sub, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Архив выполненных',
                style: TextStyle(
                  color: sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                color: sub,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: sub,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

String? _reminderLabel(Task task) {
  if (!task.notificationsEnabled ||
      task.notificationHour == null ||
      task.notificationMinute == null) {
    return null;
  }
  final hour = task.notificationHour!.toString().padLeft(2, '0');
  final minute = task.notificationMinute!.toString().padLeft(2, '0');
  return '$hour:$minute';
}
