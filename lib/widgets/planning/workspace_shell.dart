part of '../planning_workspace.dart';

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
                return _MobilePlanningFlow(
                  state: state,
                  skill: skill,
                  isDark: isDark,
                  archiveExpanded: _archiveExpanded,
                  onArchiveToggle: () =>
                      setState(() => _archiveExpanded = !_archiveExpanded),
                  onAddSkill: () => _addSkill(context),
                  onEditSkill: skill == null
                      ? null
                      : () => _editSkill(context, skill),
                  onAddTask: skill == null
                      ? null
                      : () => _addTask(context, skill),
                  onEditTask: skill == null
                      ? null
                      : (task) => _editTask(context, skill, task),
                  onDeleteTask: (task) => state.removeTask(task.id),
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
                      internalScroll: true,
                      onArchiveToggle: () =>
                          setState(() => _archiveExpanded = !_archiveExpanded),
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
        onSave:
            (
              name,
              goal,
              checklist,
              color,
              icon,
              initialTreeNodes,
              initialQuest,
            ) {
              final skillId = uid();
              state.addSkill(
                Skill(
                  id: skillId,
                  name: name,
                  goal: goal,
                  color: color,
                  icon: icon,
                  checklist: checklist,
                  treeNodes: initialTreeNodes,
                ),
              );
              state.selectSkill(skillId);
              if (initialQuest != null) {
                state.addTask(
                  Task(
                    id: uid(),
                    title: initialQuest.title,
                    skillId: skillId,
                    xpReward: 20,
                    type: TaskType.shortTerm,
                    priority: Priority.medium,
                    minimumAction: initialQuest.minimumAction,
                    treeNodeId: initialQuest.treeNodeId,
                  ),
                );
              }
            },
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
        onSave: (name, goal, checklist, color, icon, _, _) => state.updateSkill(
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
