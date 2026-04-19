import 'package:flutter/material.dart';
import '../models.dart';
import '../app_state.dart';
import '../utils.dart';
import 'shared.dart';
import 'dialogs.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TASKS PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class TasksPanel extends StatefulWidget {
  final AppState state;
  final Function(String id, Offset pos) onComplete;
  const TasksPanel({super.key, required this.state, required this.onComplete});
  @override
  State<TasksPanel> createState() => _TasksPanelState();
}

class _TasksPanelState extends State<TasksPanel> {
  bool _checklistExpanded = false;

  @override
  void didUpdateWidget(TasksPanel old) {
    super.didUpdateWidget(old);
    // Collapse checklist when a different skill is selected
    if (old.state.selectedSkillId != widget.state.selectedSkillId) {
      _checklistExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final isDark = s.isDark;
    final sfc = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final skill = s.selectedSkill;

    // No skill selected state
    if (skill == null) {
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
                'Выберите навык',
                style: TextStyle(
                  color: sub,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Задачи откроются здесь',
                style: TextStyle(color: sub.withAlpha(160), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final allTasks = s.tasksForSkill(skill.id);
    final active = allTasks.where((t) => !t.isDone).toList();
    final done = allTasks.where((t) => t.isDone).toList();
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
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
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
                        // Tapping the goal expands/collapses the checklist
                        GestureDetector(
                          onTap: hasChecklist
                              ? () => setState(
                                  () =>
                                      _checklistExpanded = !_checklistExpanded,
                                )
                              : null,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  skill.goal,
                                  style: TextStyle(color: sub, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasChecklist) ...[
                                const SizedBox(width: 4),
                                // Progress label  e.g. "1/3"
                                Text(
                                  '${skill.checklistCompletedCount}/${skill.checklist.length}',
                                  style: TextStyle(
                                    color: skill.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  _checklistExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 14,
                                  color: sub,
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SmallBtn(
                  label: ' Задача',
                  icon: Icons.add,
                  color: skill.color,
                  onTap: () => _addTask(context, skill),
                ),
              ],
            ),
          ),

          // ── Skill XP bar ─────────────────────────────────────────────────────
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

          // ── Expandable Checklist ──────────────────────────────────────────────
          if (hasChecklist)
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
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
                          final done = skill.checklistDone[i];
                          return GestureDetector(
                            onTap: () =>
                                widget.state.toggleChecklistItem(skill.id, i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: done ? skill.color : sub,
                                        width: 1.5,
                                      ),
                                      color: done
                                          ? skill.color
                                          : Colors.transparent,
                                    ),
                                    child: done
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
                                        color: done ? sub : textColor(isDark),
                                        decoration: done
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: sub,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

          Container(height: 1, color: borderColor(isDark)),

          // ── Task list ─────────────────────────────────────────────────────────
          Expanded(
            child: allTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task, color: sub, size: 38),
                        const SizedBox(height: 10),
                        Text(
                          'Нет задач',
                          style: TextStyle(
                            color: sub,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Нажмите « Задача»',
                          style: TextStyle(
                            color: sub.withAlpha(150),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      ...active.map(
                        (t) => TaskTile(
                          task: t,
                          isDark: isDark,
                          skillColor: skill.color,
                          onToggle: (pos) => widget.onComplete(t.id, pos),
                          onUncomplete: () => s.uncompleteTask(t.id),
                          onDelete: () => s.removeTask(t.id),
                          onEdit: () => _editTask(context, skill, t),
                        ),
                      ),
                      if (done.isNotEmpty) ...[
                        Padding(
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
                                'Выполнено сегодня (${done.length})',
                                style: TextStyle(
                                  color: sub,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...done.map(
                          (t) => TaskTile(
                            task: t,
                            isDark: isDark,
                            skillColor: skill.color,
                            onToggle: (_) => s.uncompleteTask(t.id),
                            onUncomplete: () => s.uncompleteTask(t.id),
                            onDelete: () => s.removeTask(t.id),
                            onEdit: () => _editTask(context, skill, t),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _addTask(BuildContext ctx, Skill skill) => showDialog(
    context: ctx,
    builder: (_) => AddTaskDialog(
      isDark: widget.state.isDark,
      skillColor: skill.color,
      onSave: (title, xp, type, freq, customDays) => widget.state.addTask(
        Task(
          id: uid(),
          title: title,
          skillId: skill.id,
          xpReward: xp,
          type: type,
          repeatFrequency: freq,
          repeatCustomDays: customDays,
        ),
      ),
    ),
  );

  void _editTask(BuildContext ctx, Skill skill, Task task) => showDialog(
    context: ctx,
    builder: (_) => AddTaskDialog(
      isDark: widget.state.isDark,
      skillColor: skill.color,
      existing: task,
      onSave: (title, xp, type, freq, customDays) {
        task.title = title;
        task.xpReward = xp;
        task.type = type;
        task.repeatFrequency = freq;
        task.repeatCustomDays = customDays;
        widget.state.refresh();
      },
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TASK TILE
// ═══════════════════════════════════════════════════════════════════════════════

class TaskTile extends StatefulWidget {
  final Task task;
  final bool isDark;
  final Color skillColor;
  final Function(Offset) onToggle;
  final VoidCallback onUncomplete, onDelete, onEdit;
  const TaskTile({
    super.key,
    required this.task,
    required this.isDark,
    required this.skillColor,
    required this.onToggle,
    required this.onUncomplete,
    required this.onDelete,
    required this.onEdit,
  });
  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  final _cbKey = GlobalKey();
  bool _h = false;

  String _formatReset(DateTime? dt) {
    if (dt == null) return '';
    return 'Обновится ${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} в 03:00';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final isDark = widget.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final tileBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF8F8FA);
    final bdr = borderColor(isDark);
    final mult = t.activeMultiplier;

    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _h
              ? (isDark ? const Color(0xFF1E1E2A) : const Color(0xFFECECF8))
              : tileBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bdr),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              PressFeedback(
                scale: 0.85,
                onTap: () {
                  if (t.isDone) {
                    widget.onUncomplete();
                  } else {
                    final box =
                        _cbKey.currentContext?.findRenderObject() as RenderBox?;
                    widget.onToggle(
                      box?.localToGlobal(Offset.zero) ?? Offset.zero,
                    );
                  }
                },
                child: AnimatedContainer(
                  key: _cbKey,
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: t.isDone ? widget.skillColor : sub,
                      width: 2,
                    ),
                    color: t.isDone ? widget.skillColor : Colors.transparent,
                  ),
                  child: t.isDone
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
              ),
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
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        TaskBadge(
                          label: typeLabel[t.type]!,
                          color: typeColor[t.type]!,
                        ),
                        TaskBadge(
                          icon: Icons.auto_awesome,
                          label: t.isDone
                              ? '-${t.earnedXP} XP'
                              : '+${t.xpReward * mult} XP',
                          color: t.isDone ? sub : const Color(0xFF4A9EFF),
                        ),
                        if (t.showStreakBadge)
                          TaskBadge(
                            icon: Icons.local_fire_department,
                            label: '×$mult',
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
                              _formatReset(t.nextResetAt),
                              style: TextStyle(color: sub, fontSize: 11),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Hover actions
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _h ? 44 : 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 44,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MiniBtn(
                          icon: Icons.edit,
                          color: sub,
                          onTap: widget.onEdit,
                        ),
                        MiniBtn(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFFF3B30),
                          onTap: widget.onDelete,
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
    );
  }
}
