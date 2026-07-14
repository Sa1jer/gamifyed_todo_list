import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import '../feedback_service.dart';
import '../models.dart';
import '../app_state.dart';
import '../utils.dart';
import 'shared.dart';
import 'dialogs.dart';
import 'goal_header.dart';
import 'inbox_panel.dart';
import 'mobile_journal_tokens.dart';
import 'skill_goal_progress.dart';
import 'tasks/task_tile.dart';

export 'tasks/task_tile.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TASKS PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class TasksPanel extends StatefulWidget {
  final void Function(String id, ActionToastOrigin origin) onComplete;
  final void Function(String id, ActionToastOrigin origin) onMinimumAction;
  final bool planningMode;
  final bool mobileFocus;
  final VoidCallback? onMobileOverview;
  final VoidCallback? onMobileDeleteSkill;
  final Key? createFirstQuestButtonKey;
  const TasksPanel({
    super.key,
    required this.onComplete,
    required this.onMinimumAction,
    this.planningMode = false,
    this.mobileFocus = false,
    this.onMobileOverview,
    this.onMobileDeleteSkill,
    this.createFirstQuestButtonKey,
  });
  @override
  State<TasksPanel> createState() => _TasksPanelState();
}

class _TasksPanelState extends State<TasksPanel> {
  String? _lastSkillId;
  bool _completedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = AppStateProvider.of(context);
    final isDark = s.isDark;
    final sfc = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final skill = s.selectedSkill;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;

    if (skill == null) {
      final hasSkills = s.roadmapSkills.isNotEmpty;
      return Container(
        key: widget.mobileFocus
            ? const ValueKey('mobile-skill-focus-empty')
            : null,
        decoration: BoxDecoration(
          color: sfc,
          borderRadius: BorderRadius.circular(widget.mobileFocus ? 18 : 14),
          border: widget.mobileFocus ? null : Border.all(color: bdr),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.mobileFocus
                    ? Icons.touch_app_outlined
                    : Icons.arrow_back,
                color: sub,
                size: widget.mobileFocus ? 26 : 30,
              ),
              const SizedBox(height: 12),
              Text(
                hasSkills
                    ? (widget.mobileFocus
                          ? 'Выбери навык для фокуса'
                          : widget.planningMode
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
                    ? (widget.mobileFocus
                          ? 'Здесь появятся цель, прогресс и квесты.'
                          : widget.planningMode
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

    if (skill.id == kInboxSkillId) {
      return InboxPanel(
        onComplete: widget.onComplete,
        embedded: widget.mobileFocus,
      );
    }

    final allTasks = s.tasksForSkill(skill.id);
    final active = allTasks.where((t) => !t.isDone).toList();
    final done = allTasks.where((t) => t.isDone && !t.isArchived).toList()
      ..sort(_compareCompletedTasksNewestFirst);
    final archived = allTasks.where((t) => t.isDone && t.isArchived).toList()
      ..sort(_compareCompletedTasksNewestFirst);
    if (_lastSkillId != skill.id) {
      _lastSkillId = skill.id;
      _completedExpanded = false;
    }
    if (widget.mobileFocus) {
      return _buildMobileFocus(
        context,
        state: s,
        skill: skill,
        active: active,
        done: done,
        archived: archived,
        isDark: isDark,
      );
    }
    return Container(
      key: widget.mobileFocus
          ? ValueKey('mobile-selected-skill-focus-${skill.id}')
          : null,
      decoration: BoxDecoration(
        color: widget.mobileFocus ? null : sfc,
        gradient: widget.mobileFocus
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [skill.color.withAlpha(isDark ? 10 : 7), sfc, sfc],
              )
            : null,
        borderRadius: BorderRadius.circular(widget.mobileFocus ? 24 : 14),
        border: widget.mobileFocus
            ? Border.all(color: skill.color.withAlpha(isDark ? 50 : 58))
            : Border.all(color: bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────────
          if (widget.mobileFocus)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SkillIcon(skill: skill),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          skill.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: txt,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  GoalHeader(skill: skill, isDark: isDark, maxLines: 2),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _SkillIcon(skill: skill),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: txt,
                          ),
                        ),
                        GoalHeader(skill: skill, isDark: isDark, maxLines: 1),
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
                      key: ValueKey('add-task-button-${skill.id}'),
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
            child: widget.mobileFocus && largeText
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      XPBar(
                        progress: skill.progress,
                        color: skill.color,
                        height: 6,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Ур. ${skill.level} · ${skill.xp}/${skill.xpNeeded} XP',
                        style: TextStyle(color: sub, fontSize: 10.5),
                      ),
                    ],
                  )
                : Row(
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
                        widget.mobileFocus
                            ? 'Ур. ${skill.level} · ${skill.xp}/${skill.xpNeeded} XP'
                            : '${skill.xp} / ${skill.xpNeeded} XP  •  Ур.${skill.level}',
                        style: TextStyle(color: sub, fontSize: 11),
                      ),
                    ],
                  ),
          ),

          if (widget.mobileFocus)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
              child: SkillGoalProgress(
                skill: skill,
                isDark: isDark,
                compact: true,
              ),
            ),

          if (widget.mobileFocus)
            const SizedBox(height: 1)
          else
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
                      mobileJournal: widget.mobileFocus,
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
                              onToggle: (origin) =>
                                  widget.onComplete(t.id, origin),
                              onMinimumAction: (origin) =>
                                  widget.onMinimumAction(t.id, origin),
                              onUncomplete: () => s.uncompleteTask(t.id),
                              onArchive: () => s.archiveCompletedTask(t.id),
                              onRestoreArchive: () =>
                                  s.restoreArchivedTask(t.id),
                              onDelete: () => s.removeTask(t.id),
                              onEdit: () => _editTask(context, skill, t),
                            ),
                          );
                        }),
                        ...done.asMap().entries.map((entry) {
                          final index = active.length + entry.key;
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
                              onArchive: () => s.archiveCompletedTask(t.id),
                              onRestoreArchive: () =>
                                  s.restoreArchivedTask(t.id),
                              onDelete: () => s.removeTask(t.id),
                              onEdit: () => _editTask(context, skill, t),
                            ),
                          );
                        }),
                        if (widget.mobileFocus)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                            child: SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton.icon(
                                key: ValueKey('add-task-button-${skill.id}'),
                                onPressed: () => _addTask(context, skill),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: skill.color,
                                  side: BorderSide(
                                    color: skill.color.withAlpha(95),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 19),
                                label: const Text(
                                  'Новый квест',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ),
                        if (archived.isNotEmpty) ...[
                          if (widget.mobileFocus)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                              child: TextButton.icon(
                                key: ValueKey('done-header-${archived.length}'),
                                onPressed: () => setState(
                                  () =>
                                      _completedExpanded = !_completedExpanded,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: sub,
                                  minimumSize: const Size(0, 44),
                                ),
                                icon: Icon(
                                  _completedExpanded
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  size: 18,
                                ),
                                label: Text('Выполнено (${archived.length})'),
                              ),
                            )
                          else
                            MotionListItem(
                              key: ValueKey('done-header-${archived.length}'),
                              index: active.length,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  6,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: sub,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Выполнено (${archived.length})',
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
                          if (!widget.mobileFocus || _completedExpanded)
                            ...archived.asMap().entries.map((entry) {
                              final index =
                                  active.length + done.length + entry.key + 1;
                              final t = entry.value;
                              return MotionListItem(
                                key: ValueKey('task-archived-${t.id}'),
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
                                  onArchive: () => s.archiveCompletedTask(t.id),
                                  onRestoreArchive: () =>
                                      s.restoreArchivedTask(t.id),
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

  Widget _buildMobileFocus(
    BuildContext context, {
    required AppState state,
    required Skill skill,
    required List<Task> active,
    required List<Task> done,
    required List<Task> archived,
    required bool isDark,
  }) {
    final txt = MobileJournalTokens.text(isDark);
    final sub = MobileJournalTokens.muted(isDark);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;

    return KeyedSubtree(
      key: ValueKey('mobile-selected-skill-focus-${skill.id}'),
      child: Semantics(
        container: true,
        label: '${skill.name}, уровень ${skill.level}',
        child: MobileSkillFocusSurface(
          skillColor: skill.color,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onMobileOverview != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                  child: TextButton.icon(
                    key: const ValueKey('mobile-overview-action'),
                    onPressed: widget.onMobileOverview,
                    style: TextButton.styleFrom(
                      foregroundColor: sub,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 17),
                    label: const Text(
                      'Навыки',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: MobileJournalTokens.skillAccentSoft(
                              skill.color,
                              isDark,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: MobileJournalTokens.skillAccentBorder(
                                skill.color,
                                isDark,
                              ),
                            ),
                          ),
                          child: Icon(skill.icon, color: skill.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            skill.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: txt,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: MobileJournalTokens.skillAccentSoft(
                              skill.color,
                              isDark,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: MobileJournalTokens.skillAccentBorder(
                                skill.color,
                                isDark,
                              ),
                            ),
                          ),
                          child: Text(
                            'Ур. ${skill.level}',
                            style: TextStyle(
                              color: skill.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (skill.goal.trim().isNotEmpty) ...[
                      const SizedBox(height: 9),
                      GoalHeader(skill: skill, isDark: isDark, maxLines: 2),
                    ],
                    const SizedBox(height: 10),
                    Semantics(
                      label:
                          'Прогресс навыка ${skill.xp} из ${skill.xpNeeded} XP',
                      value: '${(skill.progress * 100).round()} процентов',
                      child: largeText
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                XPBar(
                                  progress: skill.progress,
                                  color: skill.color,
                                  height: 6,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${skill.xp}/${skill.xpNeeded} XP',
                                  style: TextStyle(color: sub, fontSize: 12),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: XPBar(
                                    progress: skill.progress,
                                    color: skill.color,
                                    height: 6,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${skill.xp}/${skill.xpNeeded} XP',
                                  style: TextStyle(color: sub, fontSize: 12),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: MobileJournalTokens.outline(isDark).withAlpha(150),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 6),
                child: Text(
                  'КВЕСТЫ НА СЕГОДНЯ',
                  style: TextStyle(
                    color: sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (active.isEmpty && done.isEmpty && archived.isEmpty)
                _MobileFocusEmptyState(
                  isDark: isDark,
                  skillColor: skill.color,
                  skillName: skill.name,
                  onAdd: () => _addTask(context, skill),
                  createFirstQuestButtonKey: widget.createFirstQuestButtonKey,
                )
              else ...[
                for (final task in active)
                  _MobileFocusTaskTile(
                    key: ValueKey('task-active-${task.id}'),
                    task: task,
                    isDark: isDark,
                    skillColor: skill.color,
                    previewEarnedXP: state.previewEarnedXP(task),
                    onToggle: (origin) => widget.onComplete(task.id, origin),
                    onMinimumAction: (origin) =>
                        widget.onMinimumAction(task.id, origin),
                    onUncomplete: () => state.uncompleteTask(task.id),
                    onArchive: () => state.archiveCompletedTask(task.id),
                    onRestoreArchive: () => state.restoreArchivedTask(task.id),
                    onDelete: () => state.removeTask(task.id),
                    onEdit: () => _editTask(context, skill, task),
                  ),
                for (final task in done)
                  _MobileFocusTaskTile(
                    key: ValueKey('task-done-${task.id}'),
                    task: task,
                    isDark: isDark,
                    skillColor: skill.color,
                    previewEarnedXP: task.earnedXP,
                    onToggle: (_) => state.uncompleteTask(task.id),
                    onMinimumAction: (_) {},
                    onUncomplete: () => state.uncompleteTask(task.id),
                    onArchive: () => state.archiveCompletedTask(task.id),
                    onRestoreArchive: () => state.restoreArchivedTask(task.id),
                    onDelete: () => state.removeTask(task.id),
                    onEdit: () => _editTask(context, skill, task),
                  ),
                _MobileAddQuestAction(
                  key: ValueKey('add-task-button-${skill.id}'),
                  skillColor: skill.color,
                  isDark: isDark,
                  label: 'Новый квест',
                  onPressed: () => _addTask(context, skill),
                ),
                if (archived.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                    child: TextButton.icon(
                      key: ValueKey('done-header-${archived.length}'),
                      onPressed: () => setState(
                        () => _completedExpanded = !_completedExpanded,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: sub,
                        minimumSize: const Size(0, 44),
                      ),
                      icon: Icon(
                        _completedExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                      ),
                      label: Text('Выполнено (${archived.length})'),
                    ),
                  ),
                  if (_completedExpanded)
                    for (final task in archived)
                      _MobileFocusTaskTile(
                        key: ValueKey('task-archived-${task.id}'),
                        task: task,
                        isDark: isDark,
                        skillColor: skill.color,
                        previewEarnedXP: task.earnedXP,
                        onToggle: (_) => state.uncompleteTask(task.id),
                        onMinimumAction: (_) {},
                        onUncomplete: () => state.uncompleteTask(task.id),
                        onArchive: () => state.archiveCompletedTask(task.id),
                        onRestoreArchive: () =>
                            state.restoreArchivedTask(task.id),
                        onDelete: () => state.removeTask(task.id),
                        onEdit: () => _editTask(context, skill, task),
                      ),
                ],
              ],
              const SizedBox(height: 8),
              if (widget.onMobileDeleteSkill != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      key: ValueKey('mobile-delete-skill-${skill.id}'),
                      onPressed: widget.onMobileDeleteSkill,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF3B30),
                        side: const BorderSide(color: Color(0xFFFF3B30)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text(
                        'Удалить навык',
                        style: TextStyle(fontWeight: FontWeight.w900),
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

  void _addTask(BuildContext ctx, Skill skill) {
    final s = AppStateProvider.of(ctx);
    showAdaptiveCreationForm<void>(
      context: ctx,
      builder: (_, fullScreen) => AddTaskDialog(
        isDark: s.isDark,
        fullScreen: fullScreen,
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
    showAdaptiveCreationForm<void>(
      context: ctx,
      builder: (_, fullScreen) => AddTaskDialog(
        isDark: s.isDark,
        fullScreen: fullScreen,
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

class _SkillIcon extends StatelessWidget {
  final Skill skill;

  const _SkillIcon({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: skill.color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(skill.icon, color: skill.color, size: 16),
    );
  }
}

class _EmptyTasksState extends StatelessWidget {
  final bool isDark;
  final Color skillColor;
  final String skillName;
  final VoidCallback onAdd;
  final Key? createFirstQuestButtonKey;
  final bool mobileJournal;

  const _EmptyTasksState({
    super.key,
    required this.isDark,
    required this.skillColor,
    required this.skillName,
    required this.onAdd,
    this.createFirstQuestButtonKey,
    this.mobileJournal = false,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = mobileJournal || constraints.maxHeight < 220;
        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 10 : 22),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.task_alt,
                  color: skillColor,
                  size: compact ? 26 : 38,
                ),
                SizedBox(height: compact ? 6 : 12),
                Text(
                  mobileJournal
                      ? 'Добавь первый квест'
                      : 'Добавь квест, чтобы начать движение',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: txt,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  mobileJournal
                      ? 'Начни с маленького действия — так легче вернуться завтра.'
                      : 'У “$skillName” пока нет активных действий. Создай небольшой квест и добавь минимальный шаг — так начать будет легче.',
                  textAlign: TextAlign.center,
                  maxLines: compact ? 2 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style: TextStyle(color: sub, fontSize: 12, height: 1.3),
                ),
                SizedBox(height: compact ? 8 : 14),
                HoverScale(
                  child: SmallBtn(
                    key: createFirstQuestButtonKey,
                    label: 'Создать квест',
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
      },
    );
  }
}

class _MobileFocusEmptyState extends StatelessWidget {
  final bool isDark;
  final Color skillColor;
  final String skillName;
  final VoidCallback onAdd;
  final Key? createFirstQuestButtonKey;

  const _MobileFocusEmptyState({
    required this.isDark,
    required this.skillColor,
    required this.skillName,
    required this.onAdd,
    this.createFirstQuestButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final txt = MobileJournalTokens.text(isDark);
    final sub = MobileJournalTokens.muted(isDark);
    return Padding(
      key: const ValueKey('tasks-empty-state'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: MobileJournalTokens.skillAccentSoft(skillColor, isDark),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.task_alt_rounded, color: skillColor, size: 25),
          ),
          const SizedBox(height: 10),
          Text(
            'Добавь первый квест',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: txt,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Начни с маленького действия — так легче вернуться завтра.',
            textAlign: TextAlign.center,
            style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          _MobileAddQuestAction(
            key: createFirstQuestButtonKey,
            skillColor: skillColor,
            isDark: isDark,
            label: 'Создать квест',
            semanticsLabel: 'Создать первый квест для навыка $skillName',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _MobileAddQuestAction extends StatelessWidget {
  final Color skillColor;
  final bool isDark;
  final String label;
  final String? semanticsLabel;
  final VoidCallback onPressed;

  const _MobileAddQuestAction({
    super.key,
    required this.skillColor,
    required this.isDark,
    required this.label,
    required this.onPressed,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 8),
      child: Semantics(
        button: true,
        label: semanticsLabel,
        child: DashedBorderContainer(
          key: const ValueKey('mobile-dashed-add-quest'),
          color: MobileJournalTokens.skillAccentBorder(skillColor, isDark),
          backgroundColor: MobileJournalTokens.skillAccentSoft(
            skillColor,
            isDark,
          ).withAlpha(isDark ? 11 : 8),
          borderRadius: BorderRadius.circular(16),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPressed,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 20, color: skillColor),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: skillColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileFocusTaskTile extends StatefulWidget {
  final Task task;
  final bool isDark;
  final Color skillColor;
  final int previewEarnedXP;
  final ValueChanged<ActionToastOrigin> onToggle;
  final ValueChanged<ActionToastOrigin> onMinimumAction;
  final VoidCallback onUncomplete;
  final VoidCallback onArchive;
  final VoidCallback onRestoreArchive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _MobileFocusTaskTile({
    super.key,
    required this.task,
    required this.isDark,
    required this.skillColor,
    required this.previewEarnedXP,
    required this.onToggle,
    required this.onMinimumAction,
    required this.onUncomplete,
    required this.onArchive,
    required this.onRestoreArchive,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_MobileFocusTaskTile> createState() => _MobileFocusTaskTileState();
}

class _MobileFocusTaskTileState extends State<_MobileFocusTaskTile> {
  final _checkboxKey = GlobalKey();
  final _minimumKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final txt = MobileJournalTokens.text(widget.isDark);
    final sub = MobileJournalTokens.muted(widget.isDark);
    final canStartMinimum =
        task.hasMinimumAction && !task.isDone && !task.isMinimumActionDone;
    final rewardXp = task.isDone
        ? (task.earnedXP > 0 ? task.earnedXP : task.xpReward)
        : widget.previewEarnedXP;
    final hasDescription = task.description.trim().isNotEmpty;
    final baseRowColor = MobileJournalTokens.questRow(widget.isDark);
    final rowColor = task.isDone
        ? Color.alphaBlend(widget.skillColor.withAlpha(22), baseRowColor)
        : baseRowColor;

    final row = Container(
      key: ValueKey('mobile-focus-quest-row-${task.id}'),
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: EdgeInsets.fromLTRB(
        11,
        hasDescription ? 12 : 7,
        12,
        hasDescription ? 12 : 7,
      ),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: task.isDone
              ? widget.skillColor.withAlpha(82)
              : MobileJournalTokens.outline(widget.isDark),
        ),
      ),
      child: Row(
        crossAxisAlignment: hasDescription
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            checked: task.isDone,
            label: task.isDone
                ? 'Квест ${task.title} выполнен, вернуть в активные'
                : 'Выполнить квест ${task.title}',
            child: Tooltip(
              message: task.isDone
                  ? 'Вернуть квест в активные'
                  : 'Выполнить квест',
              child: PressFeedback(
                scale: 0.94,
                onTap: () => task.isDone
                    ? _uncomplete()
                    : _complete(_checkboxKey.currentContext ?? context),
                child: SizedBox.square(
                  dimension: 42,
                  child: Center(
                    child: AnimatedContainer(
                      key: _checkboxKey,
                      duration: kMotionStandard,
                      curve: kMotionCurve,
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isDone
                            ? widget.skillColor
                            : Colors.transparent,
                        border: Border.all(
                          color: task.isDone
                              ? widget.skillColor
                              : sub.withAlpha(145),
                          width: 2,
                        ),
                      ),
                      child: task.isDone
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stackReward =
                    constraints.maxWidth < 245 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final title = _MobileQuestCopy(
                  task: task,
                  titleColor: task.isDone ? sub : txt,
                  descriptionColor: sub,
                );
                final reward = XpRewardPill(
                  key: ValueKey('quest-xp-${task.id}'),
                  xp: rewardXp,
                  isDark: widget.isDark,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stackReward) ...[
                      title,
                      const SizedBox(height: 8),
                      reward,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: title),
                          const SizedBox(width: 8),
                          reward,
                        ],
                      ),
                    if (task.hasMinimumAction && !task.isDone) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        button: canStartMinimum,
                        label: canStartMinimum
                            ? 'Сделать минимальный шаг ${task.minimumAction}'
                            : 'Минимальный шаг выполнен',
                        child: InkWell(
                          key: _minimumKey,
                          borderRadius: BorderRadius.circular(10),
                          onTap: canStartMinimum
                              ? () => _completeMinimum(
                                  _minimumKey.currentContext ?? context,
                                )
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  task.isMinimumActionDone
                                      ? Icons.check_circle_rounded
                                      : Icons.play_circle_outline_rounded,
                                  size: 16,
                                  color: task.isMinimumActionDone
                                      ? const Color(0xFF35C76F)
                                      : widget.skillColor,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Минимум: ${task.minimumAction}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: task.isMinimumActionDone
                                          ? const Color(0xFF35C76F)
                                          : sub,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );

    return Slidable(
      key: ValueKey('slidable-${task.id}-${task.isDone}'),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: canStartMinimum && !task.isDone ? 0.46 : 0.28,
        children: [
          if (task.isDone)
            SlidableAction(
              onPressed: (_) =>
                  task.isArchived ? _restoreArchive() : _archive(),
              backgroundColor: const Color(0xFF8E8E93),
              foregroundColor: Colors.white,
              icon: task.isArchived
                  ? Icons.undo_rounded
                  : Icons.archive_outlined,
              label: task.isArchived ? 'Вернуть' : 'В Выполнено',
              borderRadius: BorderRadius.circular(16),
            )
          else ...[
            SlidableAction(
              onPressed: (actionContext) => _complete(actionContext),
              backgroundColor: const Color(0xFF35C76F),
              foregroundColor: Colors.white,
              icon: Icons.check_rounded,
              label: 'Готово',
              borderRadius: BorderRadius.circular(16),
            ),
            if (canStartMinimum)
              SlidableAction(
                onPressed: (actionContext) => _completeMinimum(actionContext),
                backgroundColor: widget.skillColor,
                foregroundColor: Colors.white,
                icon: Icons.play_arrow_rounded,
                label: 'Старт',
                borderRadius: BorderRadius.circular(16),
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
            icon: Icons.edit_rounded,
            label: 'Править',
            borderRadius: BorderRadius.circular(16),
          ),
          SlidableAction(
            onPressed: (_) => _delete(),
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: 'Удалить',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Semantics(
        hint: 'Удерживайте, чтобы редактировать',
        child: GestureDetector(
          key: ValueKey('mobile-focus-quest-long-press-${task.id}'),
          behavior: HitTestBehavior.opaque,
          onLongPress: _edit,
          child: row,
        ),
      ),
    );
  }

  ActionToastOrigin _originFor(
    BuildContext context,
    ActionToastOriginKind kind,
  ) {
    return actionToastOriginForContext(
      context,
      kind: kind,
      zone: ActionToastZone.mobileContent,
      sourceId: widget.task.id,
    );
  }

  void _complete(BuildContext context) {
    widget.onToggle(_originFor(context, ActionToastOriginKind.questCheckbox));
  }

  void _completeMinimum(BuildContext context) {
    widget.onMinimumAction(
      _originFor(context, ActionToastOriginKind.minimumAction),
    );
  }

  void _uncomplete() {
    AppFeedback.selection();
    widget.onUncomplete();
  }

  void _archive() {
    AppFeedback.selection();
    widget.onArchive();
  }

  void _restoreArchive() {
    AppFeedback.selection();
    widget.onRestoreArchive();
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

class _MobileQuestCopy extends StatelessWidget {
  final Task task;
  final Color titleColor;
  final Color descriptionColor;

  const _MobileQuestCopy({
    required this.task,
    required this.titleColor,
    required this.descriptionColor,
  });

  @override
  Widget build(BuildContext context) {
    final description = task.description.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: TextStyle(
            color: titleColor,
            fontSize: 15.5,
            height: 1.2,
            fontWeight: FontWeight.w800,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            decorationColor: descriptionColor,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: descriptionColor,
              fontSize: 12.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
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
