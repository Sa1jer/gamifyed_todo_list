part of '../planning_workspace.dart';

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
  final List<Task> repeatingTasks;
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
    required this.repeatingTasks,
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
  _PlanningIssue? get primaryIssue => issues.isEmpty ? null : issues.first;
  List<_PlanningIssue> get secondaryIssues =>
      issues.length <= 1 ? const [] : issues.skip(1).toList();
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
        title: 'Квест без этапа',
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
        title: 'Этап без практики',
        subtitle: node.title,
        actionLabel: 'Создать квест',
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
    repeatingTasks: repeatingTasks,
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

bool _looksLarge(Task task) {
  return task.xpReward >= 80 ||
      task.type == TaskType.midTerm ||
      task.type == TaskType.longTerm;
}

int _compareCompletedTasksNewestFirst(Task a, Task b) {
  final aDate = a.lastCompletedAt ?? a.updatedAt;
  final bDate = b.lastCompletedAt ?? b.updatedAt;
  final byCompletion = bDate.compareTo(aDate);
  if (byCompletion != 0) return byCompletion;
  return b.createdAt.compareTo(a.createdAt);
}
