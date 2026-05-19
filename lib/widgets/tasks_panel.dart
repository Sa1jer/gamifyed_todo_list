import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import '../feedback_service.dart';
import '../models.dart';
import '../app_state.dart';
import '../utils.dart';
import 'shared.dart';
import 'dialogs.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TASKS PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class TasksPanel extends StatefulWidget {
  final Function(String id, Offset pos) onComplete;
  final Function(String id, Offset pos) onMinimumAction;
  final bool planningMode;
  const TasksPanel({
    super.key,
    required this.onComplete,
    required this.onMinimumAction,
    this.planningMode = false,
  });
  @override
  State<TasksPanel> createState() => _TasksPanelState();
}

class _TasksPanelState extends State<TasksPanel> {
  bool _checklistExpanded = false;
  String? _lastSkillId;

  @override
  Widget build(BuildContext context) {
    final s = AppStateProvider.of(context);
    final isDark = s.isDark;
    final sfc = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final skill = s.selectedSkill;

    if (s.selectedSkillId != _lastSkillId) {
      _lastSkillId = s.selectedSkillId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _checklistExpanded) {
          setState(() => _checklistExpanded = false);
        }
      });
    }

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
                          : 'Задачи откроются здесь')
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
    final hasChecklist = skill.checklist.isNotEmpty;
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
                // Name + goal (no longer a toggle — checklist button is separate)
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
                      if (skill.goal.isNotEmpty)
                        Text(
                          skill.goal,
                          style: TextStyle(color: sub, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // FIX: Checklist toggle button — same style as SmallBtn, parallel to it
                if (hasChecklist)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ChecklistBtn(
                      done: skill.checklistCompletedCount,
                      total: skill.checklist.length,
                      expanded: _checklistExpanded,
                      color: skill.color,
                      onTap: () => setState(
                        () => _checklistExpanded = !_checklistExpanded,
                      ),
                    ),
                  ),
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
                    label: 'Новая задача',
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

          // ── Expandable Checklist ─────────────────────────────────────────────────
          if (hasChecklist)
            AnimatedSize(
              duration: kMotionSlow,
              curve: kMotionCurve,
              child: _checklistExpanded
                  ? Container(
                      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: skill.color.withAlpha(12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: skill.color.withAlpha(50)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(skill.checklist.length, (i) {
                          final isDone = skill.checklistDone[i];
                          return MotionListItem(
                            key: ValueKey('skill-check-${skill.id}-$i'),
                            index: i,
                            slide: 4,
                            child: GestureDetector(
                              onTap: () => s.toggleChecklistItem(skill.id, i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: kMotionStandard,
                                      curve: kMotionCurve,
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: isDone ? skill.color : sub,
                                          width: 1.5,
                                        ),
                                        color: isDone
                                            ? skill.color
                                            : Colors.transparent,
                                      ),
                                      child: isDone
                                          ? const Icon(
                                              Icons.check,
                                              size: 11,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        skill.checklist[i],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDone
                                              ? sub
                                              : textColor(isDark),
                                          decoration: isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationColor: sub,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    )
                  : const SizedBox.shrink(),
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

  const _EmptyTasksState({
    super.key,
    required this.isDark,
    required this.skillColor,
    required this.skillName,
    required this.onAdd,
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
              'Для “$skillName” пока нет действий. Начните с маленького квеста или лёгкого старта.',
              textAlign: TextAlign.center,
              style: TextStyle(color: sub, fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 14),
            HoverScale(
              child: SmallBtn(
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

// ─── Checklist Button ─────────────────────────────────────────────────────────
// Same visual weight as SmallBtn, placed inline before "+ Задача"

class _ChecklistBtn extends StatefulWidget {
  final int done, total;
  final bool expanded;
  final Color color;
  final VoidCallback onTap;
  const _ChecklistBtn({
    required this.done,
    required this.total,
    required this.expanded,
    required this.color,
    required this.onTap,
  });
  @override
  State<_ChecklistBtn> createState() => _ChecklistBtnState();
}

class _ChecklistBtnState extends State<_ChecklistBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    final accent = widget.expanded ? darken(widget.color) : widget.color;
    return Tooltip(
      message: widget.expanded
          ? 'Скрыть чек-лист цели'
          : 'Показать чек-лист цели',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _p = true),
        onTapUp: (_) {
          setState(() => _p = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _p = false),
        child: AnimatedScale(
          scale: _p ? 0.94 : 1.0,
          duration: kMotionFast,
          curve: kMotionCurve,
          child: AnimatedContainer(
            duration: kMotionFast,
            curve: kMotionCurve,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _p ? accent.withAlpha(24) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.expanded
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: accent,
                  size: 10,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.done}/${widget.total}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
                      ? 'Вернуть задачу в активные и откатить XP'
                      : 'Выполнить задачу и начислить XP',
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
                      Text(
                        t.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: t.isDone ? sub : txt,
                          decoration: t.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: sub,
                        ),
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
                          if (t.priority != Priority.medium)
                            TaskBadge(
                              label: priorityLabel[t.priority]!,
                              color: priorityColor[t.priority]!,
                            ),
                          TaskBadge(
                            label: typeLabel[t.type]!,
                            color: typeColor[t.type]!,
                          ),
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
                              label: 'бафф +${widget.previewBuffBonus}',
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
                          if (!t.isDone &&
                              t.type == TaskType.repeating &&
                              previewMultiplier > 1)
                            TaskBadge(
                              icon: Icons.local_fire_department,
                              label: '×$previewMultiplier',
                              color: const Color(0xFFFF9500),
                            ),
                          if (t.streak > 0 && t.type == TaskType.repeating)
                            Text(
                              '${t.streak} д.',
                              style: TextStyle(color: sub, fontSize: 11),
                            ),
                          if (t.type == TaskType.repeating) ...[
                            TaskBadge(
                              icon: Icons.repeat,
                              label: freqLabel[t.repeatFrequency]!,
                              color: const Color(0xFF4A9EFF),
                            ),
                            if (t.isDone && t.nextResetAt != null)
                              Text(
                                formatResetLabel(t.nextResetAt),
                                style: TextStyle(color: sub, fontSize: 11),
                              ),
                          ],
                          if (t.subtasks.isNotEmpty)
                            TaskBadge(
                              icon: Icons.checklist,
                              label:
                                  '${t.subtaskCompletedCount}/${t.subtasks.length}',
                              color: const Color(0xFF34C759),
                            ),
                          if (t.notificationsEnabled)
                            TaskBadge(
                              icon: Icons.notifications_active,
                              label:
                                  t.notificationHour != null &&
                                      t.notificationMinute != null
                                  ? '${t.notificationHour.toString().padLeft(2, '0')}:${t.notificationMinute.toString().padLeft(2, '0')}'
                                  : 'Напоминание',
                              color: const Color(0xFFAF52DE),
                            ),
                          ...t.tags
                              .take(3)
                              .map(
                                (tag) => TaskBadge(label: '#$tag', color: sub),
                              ),
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
                            tooltip: 'Редактировать задачу',
                            onTap: _edit,
                          ),
                          MiniBtn(
                            icon: Icons.delete_outline,
                            color: const Color(0xFFFF3B30),
                            tooltip: 'Удалить задачу',
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
