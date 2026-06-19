part of '../planning_workspace.dart';

class _MobilePlanningFlow extends StatelessWidget {
  final AppState state;
  final Skill? skill;
  final bool isDark;
  final bool archiveExpanded;
  final VoidCallback onArchiveToggle;
  final VoidCallback onAddSkill;
  final VoidCallback? onEditSkill;
  final VoidCallback? onAddTask;
  final ValueChanged<Task>? onEditTask;
  final ValueChanged<Task> onDeleteTask;
  final VoidCallback? onAddNode;
  final ValueChanged<SkillTreeNode>? onAddQuestToNode;
  final VoidCallback? onOpenMasteryMap;
  final VoidCallback? onDeleteSkill;

  const _MobilePlanningFlow({
    required this.state,
    required this.skill,
    required this.isDark,
    required this.archiveExpanded,
    required this.onArchiveToggle,
    required this.onAddSkill,
    required this.onEditSkill,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onAddNode,
    required this.onAddQuestToNode,
    required this.onOpenMasteryMap,
    required this.onDeleteSkill,
  });

  @override
  Widget build(BuildContext context) {
    final selected = skill;

    if (selected == null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _MobilePlanningSkillSelector(
              state: state,
              isDark: isDark,
              onAddSkill: onAddSkill,
            ),
            const SizedBox(height: 10),
            AppPanel(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: EmptyStateMessage(
                  isDark: isDark,
                  icon: Icons.construction,
                  title: 'Выберите навык',
                  subtitle:
                      'Мастерская покажет один навык, его квесты и ближайшую настройку.',
                ),
              ),
            ),
          ],
        ),
      );
    }

    final tasks = state.tasksForSkill(selected.id);
    final diagnostics = _buildPlanningDiagnostics(
      state,
      selected,
      tasks: tasks,
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          _MobilePlanningSkillSelector(
            state: state,
            isDark: isDark,
            onAddSkill: onAddSkill,
          ),
          const SizedBox(height: 10),
          AppPanel(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MobileSkillPassportHeader(
                  skill: selected,
                  diagnostics: diagnostics,
                  isDark: isDark,
                  onEditSkill: onEditSkill!,
                  onAddTask: onAddTask!,
                ),
                PanelDivider(isDark: isDark),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _SectionTitle(
                    isDark: isDark,
                    icon: Icons.format_list_bulleted,
                    title: 'Активные квесты',
                    subtitle: 'Сначала рабочий план, настройка ниже.',
                    dense: true,
                  ),
                ),
                _QuestPlanList(
                  skill: selected,
                  diagnostics: diagnostics,
                  isDark: isDark,
                  archiveExpanded: false,
                  onArchiveToggle: onArchiveToggle,
                  onEditTask: onEditTask!,
                  onDeleteTask: onDeleteTask,
                  showArchive: false,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: _SetupBacklogSection(
                    diagnostics: diagnostics,
                    isDark: isDark,
                    onEditSkill: onEditSkill!,
                    onAddTask: onAddTask!,
                    onEditTask: onEditTask!,
                    onAddQuestToNode: onAddQuestToNode,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _ReadinessMiniCard(
                    diagnostics: diagnostics,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _MobilePlanningActions(
            diagnostics: diagnostics,
            isDark: isDark,
            onAddTask: onAddTask,
            onEditSkill: onEditSkill,
            onAddNode: onAddNode,
            onAddQuestToNode: onAddQuestToNode,
            onOpenMasteryMap: onOpenMasteryMap,
            onDeleteSkill: onDeleteSkill,
          ),
        ],
      ),
    );
  }
}

class _MobilePlanningSkillSelector extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final VoidCallback onAddSkill;

  const _MobilePlanningSkillSelector({
    required this.state,
    required this.isDark,
    required this.onAddSkill,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final selected = state.selectedSkill;

    return SizedBox(
      height: 98,
      child: AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.construction,
                    color: Color(0xFF4A9EFF),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      selected == null
                          ? 'Мастерская навыка'
                          : 'Настройка: ${selected.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: txt,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SmallBtn(
                    label: 'Навык',
                    icon: Icons.add,
                    color: const Color(0xFF4A9EFF),
                    tooltip: 'Создать навык и первый квест',
                    onTap: onAddSkill,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: state.skills.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Лучший старт — через “Сейчас”: навык сразу получит этап и первый квест.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: sub,
                            fontSize: 11.5,
                            height: 1.2,
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.skills.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 7),
                        itemBuilder: (context, index) {
                          final skill = state.skills[index];
                          return _MobilePlanningSkillChip(
                            skill: skill,
                            isDark: isDark,
                            taskCount: state.activeTaskCountForSkill(skill.id),
                            selected: state.selectedSkillId == skill.id,
                            onTap: () => state.selectSkill(skill.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobilePlanningSkillChip extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final int taskCount;
  final bool selected;
  final VoidCallback onTap;

  const _MobilePlanningSkillChip({
    required this.skill,
    required this.isDark,
    required this.taskCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = skill.color;
    final sub = subtext(isDark);

    return PressFeedback(
      scale: 0.97,
      onTap: onTap,
      child: AnimatedContainer(
        duration: kMotionStandard,
        curve: kMotionCurve,
        constraints: const BoxConstraints(minWidth: 118, maxWidth: 165),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withAlpha(isDark ? 30 : 20)
              : color.withAlpha(isDark ? 12 : 8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color.withAlpha(92) : color.withAlpha(34),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(skill.icon, color: color, size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                skill.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? color : textColor(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$taskCount',
              style: TextStyle(
                color: selected ? color : sub,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSkillPassportHeader extends StatelessWidget {
  final Skill skill;
  final _PlanningDiagnostics diagnostics;
  final bool isDark;
  final VoidCallback onEditSkill;
  final VoidCallback onAddTask;

  const _MobileSkillPassportHeader({
    required this.skill,
    required this.diagnostics,
    required this.isDark,
    required this.onEditSkill,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: skill.color.withAlpha(isDark ? 34 : 25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(skill.icon, color: skill.color, size: 21),
              ),
              const SizedBox(width: 11),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    GoalHeader(skill: skill, isDark: isDark, maxLines: 2),
                  ],
                ),
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
                  height: 6,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'Ур. ${skill.level}',
                style: TextStyle(
                  color: skill.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _SoftPill(
                label: '${diagnostics.activeTasks.length} активных',
                color: const Color(0xFF4A9EFF),
                isDark: isDark,
              ),
              _SoftPill(
                label: '${skill.treeNodes.length} этап.',
                color: const Color(0xFFFF9500),
                isDark: isDark,
              ),
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
                tooltip: 'Создать квест',
                onTap: onAddTask,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobilePlanningActions extends StatelessWidget {
  final _PlanningDiagnostics diagnostics;
  final bool isDark;
  final VoidCallback? onAddTask;
  final VoidCallback? onEditSkill;
  final VoidCallback? onAddNode;
  final ValueChanged<SkillTreeNode>? onAddQuestToNode;
  final VoidCallback? onOpenMasteryMap;
  final VoidCallback? onDeleteSkill;

  const _MobilePlanningActions({
    required this.diagnostics,
    required this.isDark,
    required this.onAddTask,
    required this.onEditSkill,
    required this.onAddNode,
    required this.onAddQuestToNode,
    required this.onOpenMasteryMap,
    required this.onDeleteSkill,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = this.isDark;
    final sub = subtext(isDark);

    return AppPanel(
      isDark: isDark,
      child: PressFeedback(
        scale: 0.985,
        tooltip: 'Открыть настройки навыка',
        onTap: () => _openPlanningMobileDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF4A9EFF), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Настройки навыка',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'этапы · карта · действия',
                style: TextStyle(
                  color: sub,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_up, color: sub, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _openPlanningMobileDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanningMobileDetailsSheet(
        diagnostics: diagnostics,
        isDark: isDark,
        onAddTask: onAddTask,
        onEditSkill: onEditSkill,
        onAddNode: onAddNode,
        onAddQuestToNode: onAddQuestToNode,
        onOpenMasteryMap: onOpenMasteryMap,
        onDeleteSkill: onDeleteSkill,
      ),
    );
  }
}

class _PlanningMobileDetailsSheet extends StatelessWidget {
  final _PlanningDiagnostics diagnostics;
  final bool isDark;
  final VoidCallback? onAddTask;
  final VoidCallback? onEditSkill;
  final VoidCallback? onAddNode;
  final ValueChanged<SkillTreeNode>? onAddQuestToNode;
  final VoidCallback? onOpenMasteryMap;
  final VoidCallback? onDeleteSkill;

  const _PlanningMobileDetailsSheet({
    required this.diagnostics,
    required this.isDark,
    required this.onAddTask,
    required this.onEditSkill,
    required this.onAddNode,
    required this.onAddQuestToNode,
    required this.onOpenMasteryMap,
    required this.onDeleteSkill,
  });

  @override
  Widget build(BuildContext context) {
    final quickQuestNode =
        diagnostics.emptyNodes.firstOrNull ??
        diagnostics.skill.treeNodes
            .where(
              (node) =>
                  diagnostics.skill.treeNodeStatus(node) ==
                  SkillTreeNodeStatus.active,
            )
            .firstOrNull ??
        diagnostics.skill.treeNodes.firstOrNull;
    final reminders = diagnostics.activeTasks
        .where((task) => task.notificationsEnabled)
        .length;

    VoidCallback? closeThen(VoidCallback? action) {
      if (action == null) return null;
      return () {
        Navigator.pop(context);
        action();
      };
    }

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.86,
        child: AppPanel(
          isDark: isDark,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  isDark: isDark,
                  icon: Icons.tune,
                  title: 'Настройки навыка',
                  subtitle: 'Детали системы без перегруза основной ленты.',
                ),
                const SizedBox(height: 12),
                _ReadinessMiniCard(diagnostics: diagnostics, isDark: isDark),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.65,
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
                const SizedBox(height: 12),
                _MasteryMapPlanningCard(
                  diagnostics: diagnostics,
                  isDark: isDark,
                  onAddNode: closeThen(onAddNode),
                  onOpenMasteryMap: closeThen(onOpenMasteryMap),
                  onAddQuestToNode:
                      onAddQuestToNode == null || quickQuestNode == null
                      ? null
                      : closeThen(() => onAddQuestToNode!(quickQuestNode)),
                ),
                const SizedBox(height: 12),
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
                        onTap: closeThen(onAddTask)!,
                      ),
                    if (onAddNode != null)
                      _OutlineActionButton(
                        label: 'Этап',
                        icon: Icons.account_tree,
                        color: const Color(0xFF4A9EFF),
                        isDark: isDark,
                        onTap: closeThen(onAddNode)!,
                      ),
                    if (onOpenMasteryMap != null)
                      _OutlineActionButton(
                        label: 'Открыть карту',
                        icon: Icons.map_outlined,
                        color: const Color(0xFF8E8E93),
                        isDark: isDark,
                        onTap: closeThen(onOpenMasteryMap)!,
                      ),
                    if (onEditSkill != null)
                      _OutlineActionButton(
                        label: 'Редактировать',
                        icon: Icons.edit,
                        color: const Color(0xFF8E8E93),
                        isDark: isDark,
                        onTap: closeThen(onEditSkill)!,
                      ),
                    if (onDeleteSkill != null)
                      _OutlineActionButton(
                        label: 'Удалить навык',
                        icon: Icons.delete_outline,
                        color: const Color(0xFFFF3B30),
                        isDark: isDark,
                        onTap: closeThen(onDeleteSkill)!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
