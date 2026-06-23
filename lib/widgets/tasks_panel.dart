import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import '../feedback_service.dart';
import '../models.dart';
import '../app_state.dart';
import '../utils.dart';
import 'shared.dart';
import 'dialogs.dart';
import 'goal_header.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TASKS PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class TasksPanel extends StatefulWidget {
  final Function(String id, Offset pos) onComplete;
  final Function(String id, Offset pos) onMinimumAction;
  final bool planningMode;
  final Key? createFirstQuestButtonKey;
  const TasksPanel({
    super.key,
    required this.onComplete,
    required this.onMinimumAction,
    this.planningMode = false,
    this.createFirstQuestButtonKey,
  });
  @override
  State<TasksPanel> createState() => _TasksPanelState();
}

class _TasksPanelState extends State<TasksPanel> {
  @override
  Widget build(BuildContext context) {
    final s = AppStateProvider.of(context);
    final isDark = s.isDark;
    final sfc = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final skill = s.selectedSkill;

    if (skill == null) {
      final hasSkills = s.skills.isNotEmpty;
      return Container(
        decoration: BoxDecoration(
          color: sfc,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bdr),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, color: sub, size: 30),
              const SizedBox(height: 12),
              Text(
                hasSkills
                    ? (widget.planningMode
                          ? 'Выберите навык для настройки'
                          : 'Выберите навык')
                    : 'Сначала создайте навык',
                style: TextStyle(
                  color: txt,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasSkills
                    ? (widget.planningMode
                          ? 'Здесь откроются цель, прогресс и квесты навыка'
                          : 'Квесты откроются здесь')
                    : 'После навыка можно будет добавить первый квест',
                textAlign: TextAlign.center,
                style: TextStyle(color: sub.withAlpha(180), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final allTasks = s.tasksForSkill(skill.id);
    final active = allTasks.where((t) => !t.isDone).toList();
    final done = allTasks.where((t) => t.isDone).toList()
      ..sort(_compareCompletedTasksNewestFirst);
    return Container(
      decoration: BoxDecoration(
        color: sfc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Skill icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: skill.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(skill.icon, color: skill.color, size: 16),
                ),
                const SizedBox(width: 10),
                // Name + goal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: txt,
                        ),
                      ),
                      GoalHeader(skill: skill, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.planningMode) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: sub.withAlpha(16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: sub.withAlpha(45)),
                    ),
                    child: Text(
                      'структура',
                      style: TextStyle(
                        color: sub,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                HoverScale(
                  child: SmallBtn(
                    label: 'Новый квест',
                    icon: Icons.add,
                    color: skill.color,
                    tooltip: 'Создать квест для навыка “${skill.name}”',
                    onTap: () => _addTask(context, skill),
                  ),
                ),
              ],
            ),
          ),

          // ── Skill XP bar ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: XPBar(
                    progress: skill.progress,
                    color: skill.color,
                    height: 6,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${skill.xp} / ${skill.xpNeeded} XP  •  Ур.${skill.level}',
                  style: TextStyle(color: sub, fontSize: 11),
                ),
              ],
            ),
          ),

          Container(height: 1, color: borderColor(isDark)),

          // ── Task list ────────────────────────────────────────────────────────────
          Expanded(
            child: MotionFadeSlideSwitcher(
              child: allTasks.isEmpty
                  ? _EmptyTasksState(
                      key: const ValueKey('tasks-empty-state'),
                      isDark: isDark,
                      skillColor: skill.color,
                      skillName: skill.name,
                      onAdd: () => _addTask(context, skill),
                      createFirstQuestButtonKey:
                          widget.createFirstQuestButtonKey,
                    )
                  : ListView(
                      key: const ValueKey('tasks-list'),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        ...active.asMap().entries.map((entry) {
                          final index = entry.key;
                          final t = entry.value;
                          return MotionListItem(
                            key: ValueKey('task-active-${t.id}'),
                            index: index,
                            child: TaskTile(
                              task: t,
                              isDark: isDark,
                              skillColor: skill.color,
                              previewEarnedXP: s.previewEarnedXP(t),
                              previewBuffBonus: s.previewBuffBonusXP(t),
                              onToggle: (pos) => widget.onComplete(t.id, pos),
                              onMinimumAction: (pos) =>
                                  widget.onMinimumAction(t.id, pos),
                              onUncomplete: () => s.uncompleteTask(t.id),
                              onDelete: () => s.removeTask(t.id),
                              onEdit: () => _editTask(context, skill, t),
                            ),
                          );
                        }),
                        if (done.isNotEmpty) ...[
                          MotionListItem(
                            key: ValueKey('done-header-${done.length}'),
                            index: active.length,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: sub,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Выполнено (${done.length})',
                                    style: TextStyle(
                                      color: sub,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ...done.asMap().entries.map((entry) {
                            final index = active.length + entry.key + 1;
                            final t = entry.value;
                            return MotionListItem(
                              key: ValueKey('task-done-${t.id}'),
                              index: index,
                              child: TaskTile(
                                task: t,
                                isDark: isDark,
                                skillColor: skill.color,
                                previewEarnedXP: t.earnedXP,
                                previewBuffBonus: t.bonusXpEarned,
                                onToggle: (_) => s.uncompleteTask(t.id),
                                onMinimumAction: (_) {},
                                onUncomplete: () => s.uncompleteTask(t.id),
                                onDelete: () => s.removeTask(t.id),
                                onEdit: () => _editTask(context, skill, t),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTask(BuildContext ctx, Skill skill) {
    final s = AppStateProvider.of(ctx);
    showDialog(
      context: ctx,
      builder: (_) => AddTaskDialog(
        isDark: s.isDark,
        skillColor: skill.color,
        skill: skill,
        onSave:
            (
              title,
              description,
              xp,
              type,
              freq,
              customDays,
              priority,
              minimumAction,
              subtasks,
              tags,
              notificationsEnabled,
              notificationHour,
              notificationMinute,
              treeNodeId,
            ) => s.addTask(
              Task(
                id: uid(),
                title: title,
                description: description,
                skillId: skill.id,
                xpReward: xp,
                type: type,
                repeatFrequency: freq,
                repeatCustomDays: customDays,
                priority: priority,
                minimumAction: minimumAction,
                subtasks: subtasks,
                tags: tags,
                treeNodeId: treeNodeId,
                notificationsEnabled: notificationsEnabled,
                notificationHour: notificationHour,
                notificationMinute: notificationMinute,
              ),
            ),
      ),
    );
  }

  void _editTask(BuildContext ctx, Skill skill, Task task) {
    final s = AppStateProvider.of(ctx);
    showDialog(
      context: ctx,
      builder: (_) => AddTaskDialog(
        isDark: s.isDark,
        skillColor: skill.color,
        skill: skill,
        existing: task,
        onSave:
            (
              title,
              description,
              xp,
              type,
              freq,
              customDays,
              priority,
              minimumAction,
              subtasks,
              tags,
              notificationsEnabled,
              notificationHour,
              notificationMinute,
              treeNodeId,
            ) => s.updateTask(
              task,
              title: title,
              description: description,
              xpReward: xp,
              type: type,
              repeatFrequency: freq,
              repeatCustomDays: customDays,
              priority: priority,
              minimumAction: minimumAction,
              subtasks: subtasks,
              tags: tags,
              notificationsEnabled: notificationsEnabled,
              notificationHour: notificationHour,
              notificationMinute: notificationMinute,
              treeNodeId: treeNodeId,
            ),
      ),
    );
  }
}

class _EmptyTasksState extends StatelessWidget {
  final bool isDark;
  final Color skillColor;
  final String skillName;
  final VoidCallback onAdd;
  final Key? createFirstQuestButtonKey;

  const _EmptyTasksState({
    super.key,
    required this.isDark,
    required this.skillColor,
    required this.skillName,
    required this.onAdd,
    this.createFirstQuestButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, color: skillColor, size: 38),
            const SizedBox(height: 12),
            Text(
              'Добавьте первый квест',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: txt,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Для “$skillName” пока нет действий. Добавьте один маленький квест и минимальный шаг.',
              textAlign: TextAlign.center,
              style: TextStyle(color: sub, fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 14),
            HoverScale(
              child: SmallBtn(
                key: createFirstQuestButtonKey,
                label: 'Первый квест',
                icon: Icons.add,
                color: skillColor,
                tooltip: 'Создать первый квест для навыка “$skillName”',
                onTap: onAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _compareCompletedTasksNewestFirst(Task a, Task b) {
  final aDate = a.lastCompletedAt ?? a.updatedAt;
  final bDate = b.lastCompletedAt ?? b.updatedAt;
  final byCompletion = bDate.compareTo(aDate);
  if (byCompletion != 0) return byCompletion;
  return b.createdAt.compareTo(a.createdAt);
}

// ═══════════════════════════════════════════════════════════════════════════════
// TASK TILE  (unchanged from uploaded version)
// ═══════════════════════════════════════════════════════════════════════════════

class TaskTile extends StatefulWidget {
  final Task task;
  final bool isDark;
  final Color skillColor;
  final int previewEarnedXP;
  final int previewBuffBonus;
  final Function(Offset) onToggle;
  final Function(Offset) onMinimumAction;
  final VoidCallback onUncomplete, onDelete, onEdit;
  const TaskTile({
    super.key,
    required this.task,
    required this.isDark,
    required this.skillColor,
    required this.previewEarnedXP,
    required this.previewBuffBonus,
    required this.onToggle,
    required this.onMinimumAction,
    required this.onUncomplete,
    required this.onDelete,
    required this.onEdit,
  });
  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  final _cbKey = GlobalKey();
  final _minKey = GlobalKey();
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final isDark = widget.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final tileBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF8F8FA);
    final bdr = borderColor(isDark);
    final previewMultiplier = t.xpReward == 0
        ? 1
        : (widget.previewEarnedXP / t.xpReward).round();
    final canStartMinimum =
        t.hasMinimumAction && !t.isDone && !t.isMinimumActionDone;
    final showStartedBadge = t.isMinimumActionDone && !t.isDone;

    final tile = MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedScale(
        scale: 1,
        alignment: Alignment.center,
        duration: kMotionStandard,
        curve: kMotionCurve,
        child: AnimatedContainer(
          duration: kMotionStandard,
          curve: kMotionCurve,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _h
                ? (isDark ? const Color(0xFF181820) : const Color(0xFFF1F2FA))
                : tileBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _h ? widget.skillColor.withAlpha(55) : bdr,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Tooltip(
                  message: t.isDone
                      ? 'Вернуть квест в активные и откатить XP'
                      : 'Выполнить квест и начислить XP',
                  child: PressFeedback(
                    scale: 0.94,
                    onTap: () {
                      if (t.isDone) {
                        _uncomplete();
                      } else {
                        _complete(_cbKey.currentContext ?? context);
                      }
                    },
                    child: AnimatedContainer(
                      key: _cbKey,
                      duration: kMotionStandard,
                      curve: kMotionCurve,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: t.isDone
                              ? widget.skillColor
                              : _h
                              ? widget.skillColor
                              : sub.withAlpha(145),
                          width: 2,
                        ),
                        color: t.isDone
                            ? widget.skillColor
                            : _h
                            ? widget.skillColor.withAlpha(18)
                            : Colors.transparent,
                      ),
                      child: t.isDone
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
                if (t.hasMinimumAction) ...[
                  const SizedBox(width: 8),
                  canStartMinimum
                      ? Tooltip(
                          message: 'Сделать лёгкий старт: ${t.minimumAction}',
                          child: PressFeedback(
                            scale: 0.96,
                            onTap: () {
                              _completeMinimum(
                                _minKey.currentContext ?? context,
                              );
                            },
                            child: Container(
                              key: _minKey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: widget.skillColor.withAlpha(10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: widget.skillColor.withAlpha(46),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: widget.skillColor.withAlpha(210),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Минимум',
                                    style: TextStyle(
                                      color: widget.skillColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Tooltip(
                          message: 'Лёгкий старт уже сделан',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withAlpha(16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFF34C759).withAlpha(76),
                              ),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFF34C759),
                              size: 14,
                            ),
                          ),
                        ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TaskTitleWithDescription(
                        task: t,
                        titleStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: t.isDone ? sub : txt,
                        ),
                        descriptionColor: sub,
                        titleDecoration: t.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: sub,
                      ),
                      if (t.hasMinimumAction) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Минимум: ${t.minimumAction}',
                          style: TextStyle(
                            color: showStartedBadge
                                ? widget.skillColor
                                : sub.withAlpha(220),
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          TaskBadge(
                            icon: Icons.auto_awesome,
                            label: t.isDone
                                ? '-${t.earnedXP} XP'
                                : '+${widget.previewEarnedXP} XP',
                            color: t.isDone ? sub : const Color(0xFF4A9EFF),
                          ),
                          if (!t.isDone && widget.previewBuffBonus > 0)
                            TaskBadge(
                              icon: Icons.bolt,
                              label: 'эффект +${widget.previewBuffBonus}',
                              color: const Color(0xFF34C759),
                            ),
                          if (t.isDone && t.bonusXpEarned > 0)
                            TaskBadge(
                              icon: Icons.bolt,
                              label: '+${t.bonusXpEarned} бонус',
                              color: const Color(0xFF34C759),
                            ),
                          if (showStartedBadge)
                            TaskBadge(
                              icon: Icons.play_circle_fill,
                              label: 'Старт сделан',
                              color: const Color(0xFF34C759),
                            ),
                          if (showStartedBadge)
                            TaskBadge(
                              icon: Icons.bolt,
                              label: '+${t.minimumActionEarnedXP} XP',
                              color: widget.skillColor,
                            ),
                          if (t.type == TaskType.repeating) ...[
                            TaskBadge(
                              icon: Icons.repeat,
                              label: freqLabel[t.repeatFrequency]!,
                              color: const Color(0xFF4A9EFF),
                            ),
                            if (!t.isDone && previewMultiplier > 1)
                              TaskBadge(
                                icon: Icons.local_fire_department,
                                label: '×$previewMultiplier',
                                color: const Color(0xFFFF9500),
                              ),
                            if (t.streak > 0)
                              Text(
                                '${t.streak} д.',
                                style: TextStyle(color: sub, fontSize: 11),
                              ),
                            if (t.isDone && t.nextResetAt != null)
                              Text(
                                formatResetLabel(t.nextResetAt),
                                style: TextStyle(color: sub, fontSize: 11),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: AnimatedOpacity(
                    duration: kMotionStandard,
                    curve: kMotionCurve,
                    opacity: _h ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !_h,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MiniBtn(
                            icon: Icons.edit,
                            color: sub,
                            tooltip: 'Редактировать квест',
                            onTap: _edit,
                          ),
                          MiniBtn(
                            icon: Icons.delete_outline,
                            color: const Color(0xFFFF3B30),
                            tooltip: 'Удалить квест',
                            onTap: _delete,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Slidable(
      key: ValueKey('slidable-${t.id}-${t.isDone}'),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: canStartMinimum && !t.isDone ? 0.46 : 0.28,
        children: [
          if (t.isDone)
            SlidableAction(
              onPressed: (_) => _uncomplete(),
              backgroundColor: const Color(0xFF8E8E93),
              foregroundColor: Colors.white,
              icon: Icons.undo,
              label: 'Вернуть',
              borderRadius: BorderRadius.circular(10),
            )
          else ...[
            SlidableAction(
              onPressed: (actionContext) => _complete(actionContext),
              backgroundColor: const Color(0xFF34C759),
              foregroundColor: Colors.white,
              icon: Icons.check,
              label: 'Готово',
              borderRadius: BorderRadius.circular(10),
            ),
            if (canStartMinimum)
              SlidableAction(
                onPressed: (actionContext) => _completeMinimum(actionContext),
                backgroundColor: widget.skillColor,
                foregroundColor: Colors.white,
                icon: Icons.play_arrow_rounded,
                label: 'Старт',
                borderRadius: BorderRadius.circular(10),
              ),
          ],
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.42,
        children: [
          SlidableAction(
            onPressed: (_) => _edit(),
            backgroundColor: const Color(0xFF4A9EFF),
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Править',
            borderRadius: BorderRadius.circular(10),
          ),
          SlidableAction(
            onPressed: (_) => _delete(),
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Удалить',
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
      child: tile,
    );
  }

  Offset _globalOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero) ?? Offset.zero;
  }

  void _complete(BuildContext context) {
    widget.onToggle(_globalOrigin(context));
  }

  void _completeMinimum(BuildContext context) {
    widget.onMinimumAction(_globalOrigin(context));
  }

  void _uncomplete() {
    AppFeedback.selection();
    widget.onUncomplete();
  }

  void _edit() {
    AppFeedback.selection();
    widget.onEdit();
  }

  void _delete() {
    AppFeedback.destructive();
    widget.onDelete();
  }
}
