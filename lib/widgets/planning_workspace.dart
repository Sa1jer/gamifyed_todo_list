import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'dialogs.dart';
import 'shared.dart';

enum _PlanningIssueKind {
  missingGoal,
  noActiveQuests,
  missingMinimum,
  missingNode,
  emptyNode,
  longTermWithoutSteps,
  shortTitle,
  repeatingWithoutReminder,
  heavyArchive,
}

class _PlanningIssue {
  final _PlanningIssueKind kind;
  final int priority;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Task? task;
  final SkillTreeNode? node;

  const _PlanningIssue({
    required this.kind,
    required this.priority,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.task,
    this.node,
  });
}

class _PlanningDiagnostics {
  final Skill skill;
  final List<Task> activeTasks;
  final List<Task> completedTasks;
  final List<Task> attentionTasks;
  final List<Task> freeTasks;
  final List<Task> repeatingTasks;
  final List<Task> longTermTasks;
  final List<Task> unlinkedTasks;
  final List<Task> missingMinimumTasks;
  final List<Task> largeWithoutStepsTasks;
  final List<Task> repeatingWithoutReminderTasks;
  final List<SkillTreeNode> emptyNodes;
  final List<_PlanningIssue> issues;
  final int readinessPercent;
  final int linkedActiveTaskCount;
  final int activeNodeCount;
  final int lockedNodeCount;

  const _PlanningDiagnostics({
    required this.skill,
    required this.activeTasks,
    required this.completedTasks,
    required this.attentionTasks,
    required this.freeTasks,
    required this.repeatingTasks,
    required this.longTermTasks,
    required this.unlinkedTasks,
    required this.missingMinimumTasks,
    required this.largeWithoutStepsTasks,
    required this.repeatingWithoutReminderTasks,
    required this.emptyNodes,
    required this.issues,
    required this.readinessPercent,
    required this.linkedActiveTaskCount,
    required this.activeNodeCount,
    required this.lockedNodeCount,
  });

  int get masteredNodeCount => skill.masteredTreeNodeCount;
}

_PlanningDiagnostics _buildPlanningDiagnostics(
  AppState state,
  Skill skill, {
  List<Task>? tasks,
}) {
  final skillTasks = tasks ?? state.tasksForSkill(skill.id);
  final validNodeIds = skill.treeNodes.map((node) => node.id).toSet();
  final activeTasks = _sortPlanningTasks(
    skillTasks.where((task) => !task.isDone),
  );
  final completedTasks = skillTasks.where((task) => task.isDone).toList()
    ..sort(_compareCompletedTasksNewestFirst);
  final repeatingTasks = _sortPlanningTasks(
    activeTasks.where((task) => task.type == TaskType.repeating),
  );
  final longTermTasks = _sortPlanningTasks(
    activeTasks.where((task) => task.type == TaskType.longTerm),
  );
  final unlinkedTasks = _sortPlanningTasks(
    activeTasks.where(
      (task) =>
          task.treeNodeId == null || !validNodeIds.contains(task.treeNodeId),
    ),
  );
  final missingMinimumTasks = _sortPlanningTasks(
    activeTasks.where((task) => !task.hasMinimumAction),
  );
  final largeWithoutStepsTasks = _sortPlanningTasks(
    activeTasks.where((task) => _looksLarge(task) && task.subtasks.isEmpty),
  );
  final shortTitleTasks = _sortPlanningTasks(
    activeTasks.where((task) => task.title.trim().length < 3),
  );
  final repeatingWithoutReminderTasks = _sortPlanningTasks(
    activeTasks.where(
      (task) => task.type == TaskType.repeating && !task.notificationsEnabled,
    ),
  );
  final emptyNodes = skill.treeNodes.where((node) {
    return !skillTasks.any((task) => task.treeNodeId == node.id);
  }).toList();
  final linkedActiveTaskCount = activeTasks.length - unlinkedTasks.length;
  final activeNodeCount = skill.treeNodes
      .where((node) => skill.treeNodeStatus(node) == SkillTreeNodeStatus.active)
      .length;
  final lockedNodeCount = skill.treeNodes
      .where((node) => skill.treeNodeStatus(node) == SkillTreeNodeStatus.locked)
      .length;

  final attentionIds = <String>{
    ...missingMinimumTasks.map((task) => task.id),
    ...largeWithoutStepsTasks.map((task) => task.id),
    ...shortTitleTasks.map((task) => task.id),
    ...repeatingWithoutReminderTasks.map((task) => task.id),
  };
  final attentionTasks = _sortPlanningTasks(
    activeTasks.where((task) => attentionIds.contains(task.id)),
  );

  var readiness = 0;
  if (skill.goal.trim().isNotEmpty) readiness += 15;
  if (activeTasks.isNotEmpty) readiness += 15;
  if (repeatingTasks.isNotEmpty) readiness += 10;
  if (_atLeastHalf(
    activeTasks.length,
    activeTasks.where((t) => t.hasMinimumAction).length,
  )) {
    readiness += 15;
  }
  if (skill.treeNodes.isNotEmpty) readiness += 15;
  if (_atLeastHalf(activeTasks.length, linkedActiveTaskCount)) readiness += 15;
  if (skill.treeNodes.isNotEmpty && emptyNodes.isEmpty) readiness += 10;
  if (longTermTasks.isEmpty || largeWithoutStepsTasks.isEmpty) readiness += 5;

  final issues = <_PlanningIssue>[];
  if (skill.goal.trim().isEmpty) {
    issues.add(
      const _PlanningIssue(
        kind: _PlanningIssueKind.missingGoal,
        priority: 0,
        icon: Icons.flag_outlined,
        color: Color(0xFFFF9500),
        title: 'Нет цели навыка',
        subtitle: 'Опишите, зачем этот навык прокачивается.',
        actionLabel: 'Цель',
      ),
    );
  }
  if (activeTasks.isEmpty) {
    issues.add(
      const _PlanningIssue(
        kind: _PlanningIssueKind.noActiveQuests,
        priority: 1,
        icon: Icons.post_add,
        color: Color(0xFF4A9EFF),
        title: 'Нет активных квестов',
        subtitle: 'Добавьте следующий практический шаг.',
        actionLabel: 'Квест',
      ),
    );
  }
  for (final task in missingMinimumTasks.take(4)) {
    issues.add(
      _PlanningIssue(
        kind: _PlanningIssueKind.missingMinimum,
        priority: 2,
        icon: Icons.bolt_outlined,
        color: const Color(0xFF4A9EFF),
        title: 'Нет лёгкого старта',
        subtitle: task.title,
        actionLabel: 'Исправить',
        task: task,
      ),
    );
  }
  for (final task in unlinkedTasks.take(4)) {
    issues.add(
      _PlanningIssue(
        kind: _PlanningIssueKind.missingNode,
        priority: 3,
        icon: Icons.account_tree_outlined,
        color: const Color(0xFFFF9500),
        title: 'Квест без узла карты',
        subtitle: task.title,
        actionLabel: 'Связать',
        task: task,
      ),
    );
  }
  for (final node in emptyNodes.take(3)) {
    issues.add(
      _PlanningIssue(
        kind: _PlanningIssueKind.emptyNode,
        priority: 4,
        icon: Icons.hub_outlined,
        color: const Color(0xFFFF9500),
        title: 'Узел без практики',
        subtitle: node.title,
        actionLabel: 'Квест',
        node: node,
      ),
    );
  }
  for (final task in largeWithoutStepsTasks.take(3)) {
    issues.add(
      _PlanningIssue(
        kind: _PlanningIssueKind.longTermWithoutSteps,
        priority: 5,
        icon: Icons.splitscreen,
        color: const Color(0xFFFF9500),
        title: 'Большой квест без шагов',
        subtitle: task.title,
        actionLabel: 'Разбить',
        task: task,
      ),
    );
  }
  for (final task in shortTitleTasks.take(2)) {
    issues.add(
      _PlanningIssue(
        kind: _PlanningIssueKind.shortTitle,
        priority: 6,
        icon: Icons.short_text,
        color: const Color(0xFF8E8E93),
        title: 'Слишком короткое название',
        subtitle: task.title,
        actionLabel: 'Уточнить',
        task: task,
      ),
    );
  }
  for (final task in repeatingWithoutReminderTasks.take(2)) {
    issues.add(
      _PlanningIssue(
        kind: _PlanningIssueKind.repeatingWithoutReminder,
        priority: 7,
        icon: Icons.notifications_none,
        color: const Color(0xFFAF52DE),
        title: 'Повтор без напоминания',
        subtitle: task.title,
        actionLabel: 'Настроить',
        task: task,
      ),
    );
  }
  if (completedTasks.length >= 20) {
    issues.add(
      _PlanningIssue(
        kind: _PlanningIssueKind.heavyArchive,
        priority: 9,
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF8E8E93),
        title: 'Архив разросся',
        subtitle: '${completedTasks.length} выполненных квестов в истории.',
        actionLabel: 'Архив',
      ),
    );
  }
  issues.sort((a, b) => a.priority.compareTo(b.priority));

  return _PlanningDiagnostics(
    skill: skill,
    activeTasks: activeTasks,
    completedTasks: completedTasks,
    attentionTasks: attentionTasks,
    freeTasks: unlinkedTasks,
    repeatingTasks: repeatingTasks,
    longTermTasks: longTermTasks,
    unlinkedTasks: unlinkedTasks,
    missingMinimumTasks: missingMinimumTasks,
    largeWithoutStepsTasks: largeWithoutStepsTasks,
    repeatingWithoutReminderTasks: repeatingWithoutReminderTasks,
    emptyNodes: emptyNodes,
    issues: issues,
    readinessPercent: readiness.clamp(0, 100),
    linkedActiveTaskCount: linkedActiveTaskCount,
    activeNodeCount: activeNodeCount,
    lockedNodeCount: lockedNodeCount,
  );
}

bool _atLeastHalf(int total, int value) {
  if (total == 0) return false;
  return value / total >= 0.5;
}

List<Task> _sortPlanningTasks(Iterable<Task> tasks) {
  final list = tasks.toList();
  list.sort((a, b) {
    final priority = a.priority.index.compareTo(b.priority.index);
    if (priority != 0) return priority;
    return b.updatedAt.compareTo(a.updatedAt);
  });
  return list;
}

Color _readinessColor(int value) {
  if (value >= 75) return const Color(0xFF34C759);
  if (value >= 45) return const Color(0xFFFF9500);
  return const Color(0xFFFF3B30);
}

class PlanningWorkspace extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onOpenMasteryMap;

  const PlanningWorkspace({
    super.key,
    required this.isDark,
    this.onOpenMasteryMap,
  });

  @override
  State<PlanningWorkspace> createState() => _PlanningWorkspaceState();
}

class _PlanningWorkspaceState extends State<PlanningWorkspace> {
  bool _archiveExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final skill = state.selectedSkill;
    final isDark = widget.isDark;

    return Column(
      children: [
        _PlanningHero(isDark: isDark),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 980) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 315,
                        child: _PlanningSkillRail(
                          state: state,
                          isDark: isDark,
                          onAddSkill: () => _addSkill(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SkillBlueprintPanel(
                        state: state,
                        skill: skill,
                        isDark: isDark,
                        archiveExpanded: _archiveExpanded,
                        expandTaskList: false,
                        onArchiveToggle: () => setState(
                          () => _archiveExpanded = !_archiveExpanded,
                        ),
                        onAddSkill: () => _addSkill(context),
                        onEditSkill: skill == null
                            ? null
                            : () => _editSkill(context, skill),
                        onAddTask: skill == null
                            ? null
                            : () => _addTask(context, skill),
                        onEditTask: (task) => _editTask(context, skill!, task),
                        onDeleteTask: (task) => state.removeTask(task.id),
                        onAddQuestToNode: skill == null
                            ? null
                            : (node) => _addTaskForNode(
                                context,
                                skill,
                                treeNodeId: node.id,
                              ),
                      ),
                      const SizedBox(height: 10),
                      _PlanningInspector(
                        state: state,
                        skill: skill,
                        isDark: isDark,
                        onAddTask: skill == null
                            ? null
                            : () => _addTask(context, skill),
                        onEditSkill: skill == null
                            ? null
                            : () => _editSkill(context, skill),
                        onEditTask: skill == null
                            ? null
                            : (task) => _editTask(context, skill, task),
                        onAddNode: skill == null
                            ? null
                            : () => _addNode(context, skill),
                        onAddQuestToNode: skill == null
                            ? null
                            : (node) => _addTaskForNode(
                                context,
                                skill,
                                treeNodeId: node.id,
                              ),
                        onOpenMasteryMap: widget.onOpenMasteryMap,
                        onDeleteSkill: skill == null
                            ? null
                            : () => state.removeSkill(skill.id),
                      ),
                    ],
                  ),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: constraints.maxWidth < 1220 ? 300 : 330,
                    child: _PlanningSkillRail(
                      state: state,
                      isDark: isDark,
                      onAddSkill: () => _addSkill(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SkillBlueprintPanel(
                      state: state,
                      skill: skill,
                      isDark: isDark,
                      archiveExpanded: _archiveExpanded,
                      expandTaskList: true,
                      onArchiveToggle: () =>
                          setState(() => _archiveExpanded = !_archiveExpanded),
                      onAddSkill: () => _addSkill(context),
                      onEditSkill: skill == null
                          ? null
                          : () => _editSkill(context, skill),
                      onAddTask: skill == null
                          ? null
                          : () => _addTask(context, skill),
                      onEditTask: (task) => _editTask(context, skill!, task),
                      onDeleteTask: (task) => state.removeTask(task.id),
                      onAddQuestToNode: skill == null
                          ? null
                          : (node) => _addTaskForNode(
                              context,
                              skill,
                              treeNodeId: node.id,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: constraints.maxWidth < 1220 ? 300 : 330,
                    child: _PlanningInspector(
                      state: state,
                      skill: skill,
                      isDark: isDark,
                      onAddTask: skill == null
                          ? null
                          : () => _addTask(context, skill),
                      onEditSkill: skill == null
                          ? null
                          : () => _editSkill(context, skill),
                      onEditTask: skill == null
                          ? null
                          : (task) => _editTask(context, skill, task),
                      onAddNode: skill == null
                          ? null
                          : () => _addNode(context, skill),
                      onAddQuestToNode: skill == null
                          ? null
                          : (node) => _addTaskForNode(
                              context,
                              skill,
                              treeNodeId: node.id,
                            ),
                      onOpenMasteryMap: widget.onOpenMasteryMap,
                      onDeleteSkill: skill == null
                          ? null
                          : () => state.removeSkill(skill.id),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _addSkill(BuildContext context) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => AddSkillDialog(
        isDark: state.isDark,
        onSave: (name, goal, checklist, color, icon) => state.addSkill(
          Skill(
            id: uid(),
            name: name,
            goal: goal,
            color: color,
            icon: icon,
            checklist: checklist,
          ),
        ),
      ),
    );
  }

  void _editSkill(BuildContext context, Skill skill) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => AddSkillDialog(
        isDark: state.isDark,
        existing: skill,
        onSave: (name, goal, checklist, color, icon) => state.updateSkill(
          skill,
          name: name,
          goal: goal,
          checklist: checklist,
          color: color,
          icon: icon,
        ),
      ),
    );
  }

  void _addTask(BuildContext context, Skill skill) {
    _addTaskForNode(context, skill, treeNodeId: null);
  }

  void _addNode(BuildContext context, Skill skill) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => AddSkillTreeNodeDialog(
        isDark: state.isDark,
        skill: skill,
        onSave: (title, description, xpReward, requiredQuestCompletions) {
          state.addSkillTreeNode(
            skill.id,
            SkillTreeNode(
              id: uid(),
              title: title,
              description: description,
              xpReward: xpReward,
              requiredQuestCompletions: requiredQuestCompletions,
            ),
          );
        },
      ),
    );
  }

  void _addTaskForNode(
    BuildContext context,
    Skill skill, {
    String? treeNodeId,
  }) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        isDark: state.isDark,
        skillColor: skill.color,
        skill: skill,
        initialTreeNodeId: treeNodeId,
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
            ) => state.addTask(
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

  void _editTask(BuildContext context, Skill skill, Task task) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        isDark: state.isDark,
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
            ) => state.updateTask(
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

class _PlanningHero extends StatelessWidget {
  final bool isDark;

  const _PlanningHero({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4A9EFF);
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return AppPanel(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_note, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Планировать систему',
                    style: TextStyle(
                      color: txt,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Навыки, цели и квесты живут здесь. Это режим спокойной настройки, без давления “сделай сейчас”.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: sub,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
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

class _PlanningSkillRail extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final VoidCallback onAddSkill;

  const _PlanningSkillRail({
    required this.state,
    required this.isDark,
    required this.onAddSkill,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return AppPanel(
      isDark: isDark,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.view_list_rounded, color: Color(0xFF4A9EFF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Навыки системы',
                    style: TextStyle(
                      color: txt,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SmallBtn(
                  label: 'Навык',
                  icon: Icons.add,
                  color: const Color(0xFF4A9EFF),
                  onTap: onAddSkill,
                  tooltip: 'Добавить навык',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                state.selectedSkill == null
                    ? 'Выберите навык для настройки'
                    : 'Настройка: ${state.selectedSkill!.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: sub,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          PanelDivider(isDark: isDark),
          Expanded(
            child: state.skills.isEmpty
                ? EmptyStateMessage(
                    isDark: isDark,
                    icon: Icons.bolt,
                    title: 'Навыков пока нет',
                    subtitle: 'Создайте первый навык для планирования.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.skills.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final skill = state.skills[index];
                      final taskCount = state.tasksForSkill(skill.id).length;
                      return MotionListItem(
                        key: ValueKey('planning-skill-${skill.id}'),
                        index: index,
                        child: _PlanningSkillTile(
                          skill: skill,
                          isDark: isDark,
                          taskCount: taskCount,
                          selected: state.selectedSkillId == skill.id,
                          onTap: () => state.selectSkill(skill.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlanningSkillTile extends StatefulWidget {
  final Skill skill;
  final bool isDark;
  final int taskCount;
  final bool selected;
  final VoidCallback onTap;

  const _PlanningSkillTile({
    required this.skill,
    required this.isDark,
    required this.taskCount,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PlanningSkillTile> createState() => _PlanningSkillTileState();
}

class _PlanningSkillTileState extends State<_PlanningSkillTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final isDark = widget.isDark;
    final color = skill.color;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final selected = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: kMotionStandard,
          curve: kMotionCurve,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? color.withAlpha(isDark ? 22 : 18)
                : _hovered
                ? color.withAlpha(isDark ? 12 : 10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color.withAlpha(140) : borderColor(isDark),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 34 : 24),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(skill.icon, color: color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            skill.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: txt,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _SoftPill(
                          label: 'Ур. ${skill.level}',
                          color: color,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          'Квесты',
                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.route, color: sub.withAlpha(150), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '${widget.taskCount}',
                          style: TextStyle(
                            color: sub,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: XPBar(
                            progress: skill.progress,
                            color: color,
                            height: 5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${skill.xp}/${skill.xpNeeded}',
                          style: TextStyle(color: sub, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillBlueprintPanel extends StatelessWidget {
  final AppState state;
  final Skill? skill;
  final bool isDark;
  final bool archiveExpanded;
  final bool expandTaskList;
  final VoidCallback onArchiveToggle;
  final VoidCallback onAddSkill;
  final VoidCallback? onEditSkill;
  final VoidCallback? onAddTask;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;
  final ValueChanged<SkillTreeNode>? onAddQuestToNode;

  const _SkillBlueprintPanel({
    required this.state,
    required this.skill,
    required this.isDark,
    required this.archiveExpanded,
    required this.expandTaskList,
    required this.onArchiveToggle,
    required this.onAddSkill,
    required this.onEditSkill,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onAddQuestToNode,
  });

  @override
  Widget build(BuildContext context) {
    final selected = skill;
    if (selected == null) {
      return AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyStateMessage(
            isDark: isDark,
            icon: Icons.keyboard_backspace,
            title: 'Выберите навык',
            subtitle: 'Паспорт навыка и план квестов откроются здесь.',
          ),
        ),
      );
    }

    final tasks = state.tasksForSkill(selected.id);
    final diagnostics = _buildPlanningDiagnostics(
      state,
      selected,
      tasks: tasks,
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkillPassportHeader(
          skill: selected,
          isDark: isDark,
          activeCount: diagnostics.activeTasks.length,
          doneCount: diagnostics.completedTasks.length,
          onEditSkill: onEditSkill!,
          onAddTask: onAddTask!,
        ),
        PanelDivider(isDark: isDark),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _SystemStateCard(diagnostics: diagnostics, isDark: isDark),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: _SetupBacklogSection(
            diagnostics: diagnostics,
            isDark: isDark,
            onEditSkill: onEditSkill!,
            onAddTask: onAddTask!,
            onEditTask: onEditTask,
            onAddQuestToNode: onAddQuestToNode,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _SectionTitle(
            isDark: isDark,
            icon: Icons.format_list_bulleted,
            title: 'План квестов',
            subtitle:
                'Здесь квесты настраиваются, а не закрываются в один клик.',
          ),
        ),
        if (expandTaskList)
          Expanded(
            child: _QuestPlanList(
              skill: selected,
              diagnostics: diagnostics,
              isDark: isDark,
              archiveExpanded: archiveExpanded,
              scrollable: true,
              onArchiveToggle: onArchiveToggle,
              onEditTask: onEditTask,
              onDeleteTask: onDeleteTask,
            ),
          )
        else
          _QuestPlanList(
            skill: selected,
            diagnostics: diagnostics,
            isDark: isDark,
            archiveExpanded: archiveExpanded,
            scrollable: false,
            onArchiveToggle: onArchiveToggle,
            onEditTask: onEditTask,
            onDeleteTask: onDeleteTask,
          ),
      ],
    );

    return AppPanel(isDark: isDark, child: content);
  }
}

class _SystemStateCard extends StatelessWidget {
  final _PlanningDiagnostics diagnostics;
  final bool isDark;

  const _SystemStateCard({required this.diagnostics, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _readinessColor(diagnostics.readinessPercent);
    final skill = diagnostics.skill;
    final rows = [
      _SystemCheckData(
        ok: skill.goal.trim().isNotEmpty,
        label: skill.goal.trim().isNotEmpty
            ? 'Цель описана'
            : 'Нет цели навыка',
        warning: 'Опишите, зачем прокачивать навык.',
      ),
      _SystemCheckData(
        ok: diagnostics.activeTasks.isNotEmpty,
        label: diagnostics.activeTasks.isNotEmpty
            ? 'Есть активные квесты'
            : 'Нет активных квестов',
        warning: 'Добавьте хотя бы один следующий шаг.',
      ),
      _SystemCheckData(
        ok: diagnostics.missingMinimumTasks.isEmpty,
        label: diagnostics.missingMinimumTasks.isEmpty
            ? 'Лёгкие старты настроены'
            : '${diagnostics.missingMinimumTasks.length} без минимума',
        warning: 'Добавьте минимальное действие.',
      ),
      _SystemCheckData(
        ok: diagnostics.unlinkedTasks.isEmpty,
        label: diagnostics.unlinkedTasks.isEmpty
            ? 'Квесты связаны с картой'
            : '${diagnostics.unlinkedTasks.length} без узла',
        warning: 'Привяжите квесты к узлам мастерства.',
      ),
      _SystemCheckData(
        ok: diagnostics.emptyNodes.isEmpty,
        label: diagnostics.emptyNodes.isEmpty
            ? 'Узлы имеют практику'
            : '${diagnostics.emptyNodes.length} узл. без практики',
        warning: 'Создайте квесты для пустых узлов.',
      ),
      _SystemCheckData(
        ok: diagnostics.largeWithoutStepsTasks.isEmpty,
        label: diagnostics.largeWithoutStepsTasks.isEmpty
            ? 'Большие квесты разбиты'
            : '${diagnostics.largeWithoutStepsTasks.length} без подзадач',
        warning: 'Разбейте долгосрочные квесты.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 13 : 9),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rule_folder_outlined, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Состояние системы',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${diagnostics.readinessPercent}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XPBar(
            progress: diagnostics.readinessPercent / 100,
            color: color,
            height: 7,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: rows
                .map((row) => _SystemCheckChip(data: row, isDark: isDark))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SystemCheckData {
  final bool ok;
  final String label;
  final String warning;

  const _SystemCheckData({
    required this.ok,
    required this.label,
    required this.warning,
  });
}

class _SystemCheckChip extends StatelessWidget {
  final _SystemCheckData data;
  final bool isDark;

  const _SystemCheckChip({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = data.ok ? const Color(0xFF34C759) : const Color(0xFFFF9500);
    return Tooltip(
      message: data.ok ? data.label : data.warning,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 14 : 10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              data.ok ? Icons.check_circle : Icons.warning_amber_rounded,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              data.label,
              style: TextStyle(
                color: data.ok ? textColor(isDark) : color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupBacklogSection extends StatelessWidget {
  final _PlanningDiagnostics diagnostics;
  final bool isDark;
  final VoidCallback onEditSkill;
  final VoidCallback onAddTask;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<SkillTreeNode>? onAddQuestToNode;

  const _SetupBacklogSection({
    required this.diagnostics,
    required this.isDark,
    required this.onEditSkill,
    required this.onAddTask,
    required this.onEditTask,
    required this.onAddQuestToNode,
  });

  @override
  Widget build(BuildContext context) {
    final issues = diagnostics.issues.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withAlpha(
          isDark ? 24 : 120,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            isDark: isDark,
            icon: Icons.construction,
            title: 'Требует настройки',
            subtitle: issues.isEmpty
                ? 'Система навыка собрана устойчиво.'
                : 'Быстрые правки, которые улучшат структуру навыка.',
            dense: true,
          ),
          const SizedBox(height: 10),
          if (issues.isEmpty)
            _InspectorHint(
              isDark: isDark,
              icon: Icons.check_circle,
              color: const Color(0xFF34C759),
              title: 'Завала нет',
              subtitle: 'Можно спокойно планировать следующий слой квестов.',
            )
          else
            ...issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SetupIssueRow(
                  issue: issue,
                  isDark: isDark,
                  onTap: _actionFor(issue),
                ),
              ),
            ),
        ],
      ),
    );
  }

  VoidCallback? _actionFor(_PlanningIssue issue) {
    if (issue.task != null) return () => onEditTask(issue.task!);
    if (issue.node != null && onAddQuestToNode != null) {
      return () => onAddQuestToNode!(issue.node!);
    }
    return switch (issue.kind) {
      _PlanningIssueKind.missingGoal => onEditSkill,
      _PlanningIssueKind.noActiveQuests => onAddTask,
      _ => null,
    };
  }
}

class _SetupIssueRow extends StatelessWidget {
  final _PlanningIssue issue;
  final bool isDark;
  final VoidCallback? onTap;

  const _SetupIssueRow({
    required this.issue,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: issue.color.withAlpha(isDark ? 12 : 8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: issue.color.withAlpha(38)),
      ),
      child: Row(
        children: [
          Icon(issue.icon, color: issue.color, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  issue.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtext(isDark),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            PressFeedback(
              onTap: onTap!,
              tooltip: issue.actionLabel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: issue.color.withAlpha(isDark ? 18 : 12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: issue.color.withAlpha(55)),
                ),
                child: Text(
                  issue.actionLabel,
                  style: TextStyle(
                    color: issue.color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkillPassportHeader extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final int activeCount;
  final int doneCount;
  final VoidCallback onEditSkill;
  final VoidCallback onAddTask;

  const _SkillPassportHeader({
    required this.skill,
    required this.isDark,
    required this.activeCount,
    required this.doneCount,
    required this.onEditSkill,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: skill.color.withAlpha(isDark ? 34 : 25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(skill.icon, color: skill.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: txt,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      skill.goal.isEmpty ? 'Цель пока не описана' : skill.goal,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: sub,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  _OutlineActionButton(
                    label: 'Редактировать',
                    icon: Icons.edit,
                    color: const Color(0xFF8E8E93),
                    isDark: isDark,
                    onTap: onEditSkill,
                  ),
                  SmallBtn(
                    label: 'Квест',
                    icon: Icons.add,
                    color: const Color(0xFF4A9EFF),
                    onTap: onAddTask,
                    tooltip: 'Создать квест',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              LvlBadge(level: skill.level, color: skill.color),
              _SoftPill(
                label: '$activeCount активных',
                color: const Color(0xFF4A9EFF),
                isDark: isDark,
              ),
              _SoftPill(
                label: '$doneCount в архиве',
                color: const Color(0xFF8E8E93),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: XPBar(
                  progress: skill.progress,
                  color: skill.color,
                  height: 7,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${skill.xp} / ${skill.xpNeeded} XP',
                style: TextStyle(
                  color: sub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillChecklistCard extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final bool isDark;

  const _SkillChecklistCard({
    required this.state,
    required this.skill,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final items = skill.checklist;
    final done = skill.checklistCompletedCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withAlpha(
            isDark ? 28 : 120,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor(isDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              isDark: isDark,
              icon: Icons.checklist,
              title: 'Чек-лист навыка',
              subtitle: items.isEmpty
                  ? 'Добавьте шаги в редактировании навыка.'
                  : '$done/${items.length} шагов отмечено',
              dense: true,
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...items.asMap().entries.take(4).map((entry) {
                final index = entry.key;
                final checked = index < skill.checklistDone.length
                    ? skill.checklistDone[index]
                    : false;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => state.toggleChecklistItem(skill.id, index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          checked
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: checked ? skill.color : sub,
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            entry.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: checked ? sub : textColor(isDark),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              decoration: checked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (items.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Ещё ${items.length - 4} шагов в редактировании навыка',
                    style: TextStyle(
                      color: sub,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestPlanList extends StatelessWidget {
  final Skill skill;
  final _PlanningDiagnostics diagnostics;
  final bool isDark;
  final bool archiveExpanded;
  final bool scrollable;
  final VoidCallback onArchiveToggle;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  const _QuestPlanList({
    required this.skill,
    required this.diagnostics,
    required this.isDark,
    required this.archiveExpanded,
    required this.scrollable,
    required this.onArchiveToggle,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    final child = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          if (diagnostics.activeTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: EmptyStateMessage(
                isDark: isDark,
                icon: Icons.post_add,
                title: 'Активных квестов нет',
                subtitle: 'Добавьте квест, чтобы связать цель с действием.',
              ),
            )
          else
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuestPlanSection(
                  skill: skill,
                  section: section,
                  isDark: isDark,
                  onEditTask: onEditTask,
                  onDeleteTask: onDeleteTask,
                ),
              ),
            ),
          if (diagnostics.completedTasks.isNotEmpty) ...[
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
                            : 8,
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

    return scrollable ? SingleChildScrollView(child: child) : child;
  }

  List<_QuestPlanSectionData> _buildSections() {
    final assigned = <String>{};

    List<Task> take(List<Task> tasks) {
      final result = tasks.where((task) => assigned.add(task.id)).toList();
      return result;
    }

    final sections = <_QuestPlanSectionData>[];
    void addSection(
      String title,
      String subtitle,
      IconData icon,
      List<Task> tasks,
    ) {
      if (tasks.isEmpty) return;
      sections.add(
        _QuestPlanSectionData(
          title: title,
          subtitle: subtitle,
          icon: icon,
          tasks: tasks,
        ),
      );
    }

    addSection(
      'Требуют внимания',
      'Качество задачи можно улучшить',
      Icons.construction,
      take(diagnostics.attentionTasks),
    );
    addSection(
      'Без узла',
      'Эти квесты пока не двигают карту мастерства',
      Icons.account_tree_outlined,
      take(diagnostics.freeTasks),
    );
    addSection(
      'Повторяющиеся',
      'Ритм и привычки навыка',
      Icons.repeat,
      take(diagnostics.repeatingTasks),
    );
    addSection(
      'Долгосрочные',
      'Большие направления и проекты',
      Icons.flag,
      take(diagnostics.longTermTasks),
    );
    addSection(
      'Активные',
      'Остальные настроенные квесты',
      Icons.playlist_add_check,
      take(diagnostics.activeTasks),
    );

    return sections;
  }
}

class _QuestPlanSectionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Task> tasks;

  const _QuestPlanSectionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tasks,
  });
}

class _QuestPlanSection extends StatelessWidget {
  final Skill skill;
  final _QuestPlanSectionData section;
  final bool isDark;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  const _QuestPlanSection({
    required this.skill,
    required this.section,
    required this.isDark,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(section.icon, color: const Color(0xFF4A9EFF), size: 15),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                section.title,
                style: TextStyle(
                  color: textColor(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${section.tasks.length}',
              style: TextStyle(
                color: sub,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            section.subtitle,
            style: TextStyle(
              color: sub,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...section.tasks.asMap().entries.map((entry) {
          final task = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == section.tasks.length - 1 ? 0 : 8,
            ),
            child: MotionListItem(
              key: ValueKey('planning-${section.title}-${task.id}'),
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
      ],
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
      padding: const EdgeInsets.all(12),
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: skillColor.withAlpha(done ? 18 : 28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              done ? Icons.inventory_2_outlined : Icons.edit_note,
              color: done ? sub : skillColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: done ? sub : txt,
                    fontSize: 14,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
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
                        label: '${task.tags.length} тег.',
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
                color: const Color(0xFF4A9EFF),
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

class _PlanningInspector extends StatelessWidget {
  final AppState state;
  final Skill? skill;
  final bool isDark;
  final VoidCallback? onAddTask;
  final VoidCallback? onEditSkill;
  final ValueChanged<Task>? onEditTask;
  final VoidCallback? onAddNode;
  final ValueChanged<SkillTreeNode>? onAddQuestToNode;
  final VoidCallback? onOpenMasteryMap;
  final VoidCallback? onDeleteSkill;

  const _PlanningInspector({
    required this.state,
    required this.skill,
    required this.isDark,
    required this.onAddTask,
    required this.onEditSkill,
    required this.onEditTask,
    required this.onAddNode,
    required this.onAddQuestToNode,
    required this.onOpenMasteryMap,
    required this.onDeleteSkill,
  });

  @override
  Widget build(BuildContext context) {
    final selected = skill;
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    if (selected == null) {
      return AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SectionTitle(
                isDark: isDark,
                icon: Icons.manage_search,
                title: 'Инспектор',
                subtitle: 'Выберите навык, чтобы увидеть диагностику.',
              ),
              const SizedBox(height: 32),
              EmptyStateMessage(
                isDark: isDark,
                icon: Icons.construction,
                title: 'Мастерская системы',
                subtitle:
                    'Здесь видно, что в навыке плохо настроено и что улучшить первым.',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    final diagnostics = _buildPlanningDiagnostics(state, selected);
    final reminders = diagnostics.activeTasks
        .where((task) => task.notificationsEnabled)
        .length;
    final topIssues = diagnostics.issues.take(3).toList();
    final quickQuestNode =
        diagnostics.emptyNodes.firstOrNull ??
        selected.treeNodes
            .where(
              (node) =>
                  selected.treeNodeStatus(node) == SkillTreeNodeStatus.active,
            )
            .firstOrNull ??
        selected.treeNodes.firstOrNull;

    return AppPanel(
      isDark: isDark,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              isDark: isDark,
              icon: Icons.manage_search,
              title: 'Инспектор планирования',
              subtitle: 'Что можно улучшить прямо сейчас.',
            ),
            const SizedBox(height: 8),
            _ReadinessMiniCard(diagnostics: diagnostics, isDark: isDark),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.55,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _PlanningMetric(
                  isDark: isDark,
                  icon: Icons.playlist_add_check,
                  label: 'Активно',
                  value: '${diagnostics.activeTasks.length}',
                  color: const Color(0xFF4A9EFF),
                ),
                _PlanningMetric(
                  isDark: isDark,
                  icon: Icons.inventory_2_outlined,
                  label: 'Архив',
                  value: '${diagnostics.completedTasks.length}',
                  color: const Color(0xFF8E8E93),
                ),
                _PlanningMetric(
                  isDark: isDark,
                  icon: Icons.repeat,
                  label: 'Повторы',
                  value: '${diagnostics.repeatingTasks.length}',
                  color: const Color(0xFF34C759),
                ),
                _PlanningMetric(
                  isDark: isDark,
                  icon: Icons.notifications_active,
                  label: 'Напомин.',
                  value: '$reminders',
                  color: const Color(0xFFAF52DE),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MasteryMapPlanningCard(
              diagnostics: diagnostics,
              isDark: isDark,
              onAddNode: onAddNode,
              onOpenMasteryMap: onOpenMasteryMap,
              onAddQuestToNode:
                  onAddQuestToNode == null || quickQuestNode == null
                  ? null
                  : () => onAddQuestToNode?.call(quickQuestNode),
            ),
            const SizedBox(height: 14),
            _SkillChecklistCard(state: state, skill: selected, isDark: isDark),
            const SizedBox(height: 14),
            Text(
              'Главные проблемы',
              style: TextStyle(
                color: txt,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (topIssues.isEmpty)
              _InspectorHint(
                isDark: isDark,
                icon: Icons.check_circle,
                color: const Color(0xFF34C759),
                title: 'Структура выглядит устойчиво',
                subtitle: 'Можно проектировать следующий слой навыка.',
              )
            else
              ...topIssues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SetupIssueRow(
                    issue: issue,
                    isDark: isDark,
                    onTap: _actionFor(issue),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onAddTask != null)
                  _OutlineActionButton(
                    label: 'Квест',
                    icon: Icons.add_task,
                    color: const Color(0xFF4A9EFF),
                    isDark: isDark,
                    onTap: onAddTask!,
                  ),
                if (onAddNode != null)
                  _OutlineActionButton(
                    label: 'Узел',
                    icon: Icons.account_tree,
                    color: const Color(0xFF4A9EFF),
                    isDark: isDark,
                    onTap: onAddNode!,
                  ),
                if (onOpenMasteryMap != null)
                  _OutlineActionButton(
                    label: 'Карта',
                    icon: Icons.map_outlined,
                    color: const Color(0xFF8E8E93),
                    isDark: isDark,
                    onTap: onOpenMasteryMap!,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: borderColor(isDark)),
            const SizedBox(height: 8),
            Text(
              'Опасная зона',
              style: TextStyle(
                color: sub,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (onDeleteSkill != null)
              _OutlineActionButton(
                label: 'Удалить навык',
                icon: Icons.delete_outline,
                color: const Color(0xFFFF3B30),
                isDark: isDark,
                onTap: onDeleteSkill!,
              ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _actionFor(_PlanningIssue issue) {
    if (issue.task != null && onEditTask != null) {
      return () => onEditTask!(issue.task!);
    }
    if (issue.node != null && onAddQuestToNode != null) {
      return () => onAddQuestToNode!(issue.node!);
    }
    return switch (issue.kind) {
      _PlanningIssueKind.missingGoal => onEditSkill,
      _PlanningIssueKind.noActiveQuests => onAddTask,
      _ => null,
    };
  }
}

class _ReadinessMiniCard extends StatelessWidget {
  final _PlanningDiagnostics diagnostics;
  final bool isDark;

  const _ReadinessMiniCard({required this.diagnostics, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _readinessColor(diagnostics.readinessPercent);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 13 : 9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: color, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Готовность системы',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${diagnostics.readinessPercent}%',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XPBar(
            progress: diagnostics.readinessPercent / 100,
            color: color,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _MasteryMapPlanningCard extends StatelessWidget {
  final _PlanningDiagnostics diagnostics;
  final bool isDark;
  final VoidCallback? onAddNode;
  final VoidCallback? onOpenMasteryMap;
  final VoidCallback? onAddQuestToNode;

  const _MasteryMapPlanningCard({
    required this.diagnostics,
    required this.isDark,
    required this.onAddNode,
    required this.onOpenMasteryMap,
    required this.onAddQuestToNode,
  });

  @override
  Widget build(BuildContext context) {
    final skill = diagnostics.skill;
    final total = skill.treeNodes.length;
    final mastered = diagnostics.masteredNodeCount;
    final active = diagnostics.activeNodeCount;
    final locked = diagnostics.lockedNodeCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A9EFF).withAlpha(isDark ? 12 : 8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A9EFF).withAlpha(42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            isDark: isDark,
            icon: Icons.account_tree,
            title: 'Карта мастерства',
            subtitle: total == 0
                ? 'У навыка пока нет узлов.'
                : '$total узл. · $mastered освоено · $active активно · $locked закрыто',
            dense: true,
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SoftPill(
                label: '${diagnostics.emptyNodes.length} без практики',
                color: diagnostics.emptyNodes.isEmpty
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF9500),
                isDark: isDark,
              ),
              _SoftPill(
                label: '${diagnostics.unlinkedTasks.length} квест. без узла',
                color: diagnostics.unlinkedTasks.isEmpty
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF9500),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (onAddNode != null)
                _OutlineActionButton(
                  label: 'Узел',
                  icon: Icons.add,
                  color: const Color(0xFF4A9EFF),
                  isDark: isDark,
                  onTap: onAddNode!,
                ),
              if (onAddQuestToNode != null)
                _OutlineActionButton(
                  label: 'Квест к узлу',
                  icon: Icons.add_task,
                  color: const Color(0xFFFF9500),
                  isDark: isDark,
                  onTap: onAddQuestToNode!,
                ),
              if (onOpenMasteryMap != null)
                _OutlineActionButton(
                  label: 'Открыть карту',
                  icon: Icons.map_outlined,
                  color: const Color(0xFF8E8E93),
                  isDark: isDark,
                  onTap: onOpenMasteryMap!,
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

class _PlanningMetric extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PlanningMetric({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 15 : 10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 17),
          Text(
            value,
            style: TextStyle(
              color: textColor(isDark),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subtext(isDark),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorHint extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _InspectorHint({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 14 : 10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withAlpha(42)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtext(isDark),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool dense;

  const _SectionTitle({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF4A9EFF), size: dense ? 16 : 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor(isDark),
                  fontSize: dense ? 13 : 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: dense ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtext(isDark),
                  fontSize: dense ? 11.5 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      onTap: onTap,
      tooltip: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 12 : 8),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withAlpha(65)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _SoftPill({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 22 : 16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

bool _looksLarge(Task task) {
  return task.xpReward >= 80 ||
      task.type == TaskType.midTerm ||
      task.type == TaskType.longTerm;
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

int _compareCompletedTasksNewestFirst(Task a, Task b) {
  final aDate = a.lastCompletedAt ?? a.updatedAt;
  final bDate = b.lastCompletedAt ?? b.updatedAt;
  final byCompletion = bDate.compareTo(aDate);
  if (byCompletion != 0) return byCompletion;
  return b.createdAt.compareTo(a.createdAt);
}
