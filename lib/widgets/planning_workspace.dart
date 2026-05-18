import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'dialogs.dart';
import 'shared.dart';

class PlanningWorkspace extends StatefulWidget {
  final bool isDark;

  const PlanningWorkspace({super.key, required this.isDark});

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
                        onOpenTree: skill == null
                            ? null
                            : () => _openTree(context, skill),
                        onAddTask: skill == null
                            ? null
                            : () => _addTask(context, skill),
                        onEditTask: (task) => _editTask(context, skill!, task),
                        onDeleteTask: (task) => state.removeTask(task.id),
                      ),
                      const SizedBox(height: 10),
                      _PlanningInspector(
                        state: state,
                        skill: skill,
                        isDark: isDark,
                        onOpenTree: skill == null
                            ? null
                            : () => _openTree(context, skill),
                        onAddTask: skill == null
                            ? null
                            : () => _addTask(context, skill),
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
                      onOpenTree: skill == null
                          ? null
                          : () => _openTree(context, skill),
                      onAddTask: skill == null
                          ? null
                          : () => _addTask(context, skill),
                      onEditTask: (task) => _editTask(context, skill!, task),
                      onDeleteTask: (task) => state.removeTask(task.id),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: constraints.maxWidth < 1220 ? 300 : 330,
                    child: _PlanningInspector(
                      state: state,
                      skill: skill,
                      isDark: isDark,
                      onOpenTree: skill == null
                          ? null
                          : () => _openTree(context, skill),
                      onAddTask: skill == null
                          ? null
                          : () => _addTask(context, skill),
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

  void _openTree(BuildContext context, Skill skill) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => SkillTreeDialog(state: state, skill: skill),
    );
  }

  void _addTask(BuildContext context, Skill skill) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        isDark: state.isDark,
        skillColor: skill.color,
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
                    'Навыки, цели, квесты и дерево живут здесь. Это режим спокойной настройки, без давления “сделай сейчас”.',
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
                const Icon(Icons.account_tree, color: Color(0xFF4A9EFF)),
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
    final rank = skillRankForLevel(skill.level);
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
                          rank.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.route, color: sub.withAlpha(150), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '${skill.masteredTreeNodeCount}/${skill.treeNodes.length}',
                          style: TextStyle(
                            color: sub,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.taskCount}',
                          style: TextStyle(
                            color: sub,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
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
  final VoidCallback? onOpenTree;
  final VoidCallback? onAddTask;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  const _SkillBlueprintPanel({
    required this.state,
    required this.skill,
    required this.isDark,
    required this.archiveExpanded,
    required this.expandTaskList,
    required this.onArchiveToggle,
    required this.onAddSkill,
    required this.onEditSkill,
    required this.onOpenTree,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
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
    final active = tasks.where((task) => !task.isDone).toList();
    final done = tasks.where((task) => task.isDone).toList();
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkillPassportHeader(
          skill: selected,
          isDark: isDark,
          activeCount: active.length,
          doneCount: done.length,
          onEditSkill: onEditSkill!,
          onOpenTree: onOpenTree!,
          onAddTask: onAddTask!,
        ),
        PanelDivider(isDark: isDark),
        _SkillChecklistCard(state: state, skill: selected, isDark: isDark),
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
              activeTasks: active,
              doneTasks: done,
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
            activeTasks: active,
            doneTasks: done,
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

class _SkillPassportHeader extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final int activeCount;
  final int doneCount;
  final VoidCallback onEditSkill;
  final VoidCallback onOpenTree;
  final VoidCallback onAddTask;

  const _SkillPassportHeader({
    required this.skill,
    required this.isDark,
    required this.activeCount,
    required this.doneCount,
    required this.onEditSkill,
    required this.onOpenTree,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final rank = skillRankForLevel(skill.level);

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
                  _OutlineActionButton(
                    label: 'Дерево',
                    icon: Icons.account_tree,
                    color: const Color(0xFF4A9EFF),
                    isDark: isDark,
                    onTap: onOpenTree,
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
              RankBadge(label: rank.label, color: rank.color),
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
  final List<Task> activeTasks;
  final List<Task> doneTasks;
  final bool isDark;
  final bool archiveExpanded;
  final bool scrollable;
  final VoidCallback onArchiveToggle;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;

  const _QuestPlanList({
    required this.skill,
    required this.activeTasks,
    required this.doneTasks,
    required this.isDark,
    required this.archiveExpanded,
    required this.scrollable,
    required this.onArchiveToggle,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          if (activeTasks.isEmpty)
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
            ...activeTasks.asMap().entries.map((entry) {
              final task = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == activeTasks.length - 1 ? 0 : 8,
                ),
                child: MotionListItem(
                  key: ValueKey('planning-active-task-${task.id}'),
                  index: entry.key,
                  child: _PlanningTaskRow(
                    task: task,
                    isDark: isDark,
                    skillColor: skill.color,
                    onEdit: () => onEditTask(task),
                    onDelete: () => onDeleteTask(task),
                  ),
                ),
              );
            }),
          if (doneTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ArchiveHeader(
              isDark: isDark,
              count: doneTasks.length,
              expanded: archiveExpanded,
              onTap: onArchiveToggle,
            ),
            MotionExpandable(
              expanded: archiveExpanded,
              expandedChild: Column(
                children: [
                  const SizedBox(height: 8),
                  ...doneTasks.asMap().entries.map((entry) {
                    final task = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == doneTasks.length - 1 ? 0 : 8,
                      ),
                      child: _PlanningTaskRow(
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
}

class _PlanningTaskRow extends StatelessWidget {
  final Task task;
  final bool isDark;
  final Color skillColor;
  final bool done;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlanningTaskRow({
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
  final VoidCallback? onOpenTree;
  final VoidCallback? onAddTask;
  final VoidCallback? onDeleteSkill;

  const _PlanningInspector({
    required this.state,
    required this.skill,
    required this.isDark,
    required this.onOpenTree,
    required this.onAddTask,
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
                subtitle: 'Выберите навык, чтобы увидеть подсказки.',
              ),
              const SizedBox(height: 32),
              EmptyStateMessage(
                isDark: isDark,
                icon: Icons.rule,
                title: 'План пока не выбран',
                subtitle: 'Инспектор проверит структуру квестов.',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    final tasks = state.tasksForSkill(selected.id);
    final active = tasks.where((task) => !task.isDone).toList();
    final done = tasks.length - active.length;
    final repeating = active.where((task) => task.type == TaskType.repeating);
    final reminders = active.where((task) => task.notificationsEnabled).length;
    final missingMinimum = active
        .where((task) => !task.hasMinimumAction)
        .length;
    final largeWithoutSteps = active
        .where((task) => _looksLarge(task) && task.subtasks.isEmpty)
        .length;
    final insights = _insightsFor(
      skill: selected,
      active: active,
      missingMinimum: missingMinimum,
      largeWithoutSteps: largeWithoutSteps,
    );

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
              subtitle: 'Мягко показывает, где систему стоит уточнить.',
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.35,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _PlanningMetric(
                  isDark: isDark,
                  icon: Icons.playlist_add_check,
                  label: 'Активно',
                  value: '${active.length}',
                  color: const Color(0xFF4A9EFF),
                ),
                _PlanningMetric(
                  isDark: isDark,
                  icon: Icons.inventory_2_outlined,
                  label: 'Архив',
                  value: '$done',
                  color: const Color(0xFF8E8E93),
                ),
                _PlanningMetric(
                  isDark: isDark,
                  icon: Icons.repeat,
                  label: 'Повторы',
                  value: '${repeating.length}',
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
            _TreeProgressCard(skill: selected, isDark: isDark),
            const SizedBox(height: 14),
            Text(
              'Что уточнить',
              style: TextStyle(
                color: txt,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (insights.isEmpty)
              _InspectorHint(
                isDark: isDark,
                icon: Icons.check_circle,
                color: const Color(0xFF34C759),
                title: 'Структура выглядит устойчиво',
                subtitle: 'Есть квесты, дерево или понятные маленькие шаги.',
              )
            else
              ...insights.map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: insight,
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onOpenTree != null)
                  _OutlineActionButton(
                    label: 'Дерево',
                    icon: Icons.account_tree,
                    color: const Color(0xFF4A9EFF),
                    isDark: isDark,
                    onTap: onOpenTree!,
                  ),
                if (onAddTask != null)
                  _OutlineActionButton(
                    label: 'Квест',
                    icon: Icons.add_task,
                    color: const Color(0xFF4A9EFF),
                    isDark: isDark,
                    onTap: onAddTask!,
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

  List<Widget> _insightsFor({
    required Skill skill,
    required List<Task> active,
    required int missingMinimum,
    required int largeWithoutSteps,
  }) {
    final result = <Widget>[];
    if (active.isEmpty) {
      result.add(
        _InspectorHint(
          isDark: isDark,
          icon: Icons.post_add,
          color: const Color(0xFF4A9EFF),
          title: 'Добавить первый квест',
          subtitle: 'У цели есть направление, но пока нет следующего шага.',
        ),
      );
    }
    if (largeWithoutSteps > 0) {
      result.add(
        _InspectorHint(
          isDark: isDark,
          icon: Icons.splitscreen,
          color: const Color(0xFFFF9500),
          title: 'Разбить крупные квесты',
          subtitle: '$largeWithoutSteps задач выглядят большими без подзадач.',
        ),
      );
    }
    if (missingMinimum > 0) {
      result.add(
        _InspectorHint(
          isDark: isDark,
          icon: Icons.bolt_outlined,
          color: const Color(0xFF4A9EFF),
          title: 'Добавить лёгкий старт',
          subtitle: '$missingMinimum активных задач без минимального действия.',
        ),
      );
    }
    if (skill.treeNodes.isEmpty) {
      result.add(
        _InspectorHint(
          isDark: isDark,
          icon: Icons.account_tree,
          color: const Color(0xFF8E8E93),
          title: 'Собрать дерево навыка',
          subtitle: 'Дерево поможет видеть структуру роста.',
        ),
      );
    }
    final repeatingWithoutReminder = active
        .where(
          (task) =>
              task.type == TaskType.repeating && !task.notificationsEnabled,
        )
        .length;
    if (repeatingWithoutReminder > 0) {
      result.add(
        _InspectorHint(
          isDark: isDark,
          icon: Icons.notifications_none,
          color: const Color(0xFFAF52DE),
          title: 'Проверить напоминания',
          subtitle:
              '$repeatingWithoutReminder повторяющихся квестов без сигнала.',
        ),
      );
    }
    return result.take(4).toList();
  }
}

class _TreeProgressCard extends StatelessWidget {
  final Skill skill;
  final bool isDark;

  const _TreeProgressCard({required this.skill, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A9EFF).withAlpha(isDark ? 14 : 10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A9EFF).withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_tree,
                color: Color(0xFF4A9EFF),
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Дерево навыка',
                  style: TextStyle(
                    color: txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${skill.masteredTreeNodeCount}/${skill.treeNodes.length}',
                style: TextStyle(
                  color: sub,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          XPBar(
            progress: skill.treeProgress,
            color: const Color(0xFF4A9EFF),
            height: 6,
          ),
          const SizedBox(height: 7),
          Text(
            skill.treeNodes.isEmpty
                ? 'Узлы ещё не настроены.'
                : '${skill.activeTreeNodeCount} активных узлов ждут настройки.',
            style: TextStyle(
              color: sub,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
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
