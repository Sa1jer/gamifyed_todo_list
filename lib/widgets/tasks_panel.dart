import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'dialogs.dart';
import 'shared.dart';

typedef TaskCompleteCallback = void Function(String taskId, Offset position);

// ═══════════════════════════════════════════════════════════════════════════════
// TASKS PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class TasksPanel extends StatefulWidget {
  final AppState state;
  final TaskCompleteCallback onComplete;

  const TasksPanel({super.key, required this.state, required this.onComplete});

  @override
  State<TasksPanel> createState() => _TasksPanelState();
}

class _TasksPanelState extends State<TasksPanel> {
  bool _checklistExpanded = false;

  @override
  void didUpdateWidget(covariant TasksPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedSkillId != widget.state.selectedSkillId) {
      _checklistExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final skill = state.selectedSkill;

    if (skill == null) {
      return _TasksSelectionPlaceholder(isDark: state.isDark);
    }

    final taskSections = state.taskSectionsForSkill(skill.id);
    final hasTasks =
        taskSections.active.isNotEmpty || taskSections.completed.isNotEmpty;

    return AppPanel(
      isDark: state.isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectedSkillHeader(
            isDark: state.isDark,
            skill: skill,
            checklistExpanded: _checklistExpanded,
            onToggleChecklist: skill.checklist.isEmpty
                ? null
                : () =>
                      setState(() => _checklistExpanded = !_checklistExpanded),
            onAddTask: () => _addTask(context, skill),
          ),
          if (skill.checklist.isNotEmpty)
            _SkillChecklist(
              skill: skill,
              isDark: state.isDark,
              isExpanded: _checklistExpanded,
              onToggleItem: (index) =>
                  state.toggleChecklistItem(skill.id, index),
            ),
          PanelDivider(isDark: state.isDark),
          Expanded(
            child: hasTasks
                ? _TaskList(
                    state: state,
                    skill: skill,
                    activeTasks: taskSections.active,
                    completedTasks: taskSections.completed,
                    onComplete: widget.onComplete,
                    onEditTask: (task) => _editTask(context, skill, task),
                  )
                : EmptyStateMessage(
                    isDark: state.isDark,
                    icon: Icons.task,
                    title: 'Нет задач',
                    subtitle: 'Нажмите «Задача»',
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
        if (type != TaskType.repeating) {
          task.nextResetAt = null;
        }
        widget.state.refresh();
      },
    ),
  );
}

class _TasksSelectionPlaceholder extends StatelessWidget {
  final bool isDark;

  const _TasksSelectionPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      isDark: isDark,
      child: SizedBox.expand(
        child: EmptyStateMessage(
          isDark: isDark,
          icon: Icons.arrow_back,
          title: 'Выберите навык',
          subtitle: 'Задачи откроются здесь',
        ),
      ),
    );
  }
}

class _SelectedSkillHeader extends StatelessWidget {
  final bool isDark;
  final Skill skill;
  final bool checklistExpanded;
  final VoidCallback? onToggleChecklist;
  final VoidCallback onAddTask;

  const _SelectedSkillHeader({
    required this.isDark,
    required this.skill,
    required this.checklistExpanded,
    required this.onToggleChecklist,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      GestureDetector(
                        onTap: onToggleChecklist,
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
                            if (onToggleChecklist != null) ...[
                              const SizedBox(width: 6),
                              AnimatedRotation(
                                turns: checklistExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  Icons.expand_more,
                                  size: 18,
                                  color: sub,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SmallBtn(
                label: 'Задача',
                icon: Icons.add,
                color: skill.color,
                onTap: onAddTask,
              ),
            ],
          ),
        ),
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
      ],
    );
  }
}

class _SkillChecklist extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final bool isExpanded;
  final ValueChanged<int> onToggleItem;

  const _SkillChecklist({
    required this.skill,
    required this.isDark,
    required this.isExpanded,
    required this.onToggleItem,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: isExpanded
          ? Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: skill.color.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: skill.color.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(skill.checklist.length, (index) {
                  final isDone = skill.checklistDone[index];

                  return GestureDetector(
                    onTap: () => onToggleItem(index),
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
                                color: isDone ? skill.color : sub,
                                width: 1.5,
                              ),
                              color: isDone ? skill.color : Colors.transparent,
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
                              skill.checklist[index],
                              style: TextStyle(
                                fontSize: 13,
                                color: isDone ? sub : textColor(isDark),
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
                  );
                }),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _TaskList extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final List<Task> activeTasks;
  final List<Task> completedTasks;
  final TaskCompleteCallback onComplete;
  final ValueChanged<Task> onEditTask;

  const _TaskList({
    required this.state,
    required this.skill,
    required this.activeTasks,
    required this.completedTasks,
    required this.onComplete,
    required this.onEditTask,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDark;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ...activeTasks.map(
          (task) => TaskTile(
            task: task,
            isDark: isDark,
            skillColor: skill.color,
            onToggle: (position) => onComplete(task.id, position),
            onUncomplete: () => state.uncompleteTask(task.id),
            onDelete: () => state.removeTask(task.id),
            onEdit: () => onEditTask(task),
          ),
        ),
        if (completedTasks.isNotEmpty) ...[
          _TaskSectionHeader(isDark: isDark, count: completedTasks.length),
          ...completedTasks.map(
            (task) => TaskTile(
              task: task,
              isDark: isDark,
              skillColor: skill.color,
              onToggle: (_) => state.uncompleteTask(task.id),
              onUncomplete: () => state.uncompleteTask(task.id),
              onDelete: () => state.removeTask(task.id),
              onEdit: () => onEditTask(task),
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskSectionHeader extends StatelessWidget {
  final bool isDark;
  final int count;

  const _TaskSectionHeader({required this.isDark, required this.count});

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: sub, size: 14),
          const SizedBox(width: 6),
          Text(
            'Выполнено сегодня ($count)',
            style: TextStyle(
              color: sub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Task Tile ────────────────────────────────────────────────────────────────

class TaskTile extends StatefulWidget {
  final Task task;
  final bool isDark;
  final Color skillColor;
  final ValueChanged<Offset> onToggle;
  final VoidCallback onUncomplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

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
  final _checkboxKey = GlobalKey();
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDark = widget.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final tileBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF8F8FA);
    final hoverBg = isDark ? const Color(0xFF1E1E2A) : const Color(0xFFECECF8);
    final mult = task.activeMultiplier;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _isHovered ? hoverBg : tileBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor(isDark)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PressFeedback(
                scale: 0.85,
                onTap: () {
                  if (task.isDone) {
                    widget.onUncomplete();
                    return;
                  }

                  widget.onToggle(_resolveCheckboxPosition());
                },
                child: AnimatedContainer(
                  key: _checkboxKey,
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isDone ? widget.skillColor : sub,
                      width: 2,
                    ),
                    color: task.isDone ? widget.skillColor : Colors.transparent,
                  ),
                  child: task.isDone
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
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: task.isDone ? sub : txt,
                        decoration: task.isDone
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
                          label: typeLabel[task.type]!,
                          color: typeColor[task.type]!,
                        ),
                        TaskBadge(
                          icon: Icons.auto_awesome,
                          label: task.isDone
                              ? '-${task.earnedXP} XP'
                              : '+${task.xpReward * mult} XP',
                          color: task.isDone ? sub : const Color(0xFF4A9EFF),
                        ),
                        if (task.showStreakBadge)
                          TaskBadge(
                            icon: Icons.local_fire_department,
                            label: '×$mult',
                            color: Color(0xFFFF9500),
                          ),
                        if (task.streak > 0 && task.type == TaskType.repeating)
                          Text(
                            '${task.streak} д.',
                            style: TextStyle(color: sub, fontSize: 11),
                          ),
                        if (task.type == TaskType.repeating) ...[
                          TaskBadge(
                            icon: Icons.repeat,
                            label: freqLabel[task.repeatFrequency]!,
                            color: const Color(0xFF4A9EFF),
                          ),
                          if (task.isDone && task.nextResetAt != null)
                            Text(
                              formatResetLabel(task.nextResetAt),
                              style: TextStyle(color: sub, fontSize: 11),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _isHovered ? 44 : 0,
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

  Offset _resolveCheckboxPosition() {
    final box = _checkboxKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero) ?? Offset.zero;
  }
}
