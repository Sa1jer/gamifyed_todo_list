part of '../mastery_map_workspace.dart';

class _MasteryMobileSelectionSummary extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final _MasterySelection? selection;
  final ValueChanged<Skill> onSelectSkill;
  final VoidCallback? onOpenDetails;

  const _MasteryMobileSelectionSummary({
    required this.state,
    required this.isDark,
    required this.selection,
    required this.onSelectSkill,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final currentSelection = selection;
    final skill = currentSelection == null
        ? null
        : state.skills
              .where((candidate) => candidate.id == currentSelection.skillId)
              .firstOrNull;
    final node = skill == null || currentSelection?.nodeId == null
        ? null
        : skill.treeNodes
              .where((candidate) => candidate.id == currentSelection!.nodeId)
              .firstOrNull;
    final task = currentSelection?.taskId == null
        ? null
        : state.tasks
              .where((candidate) => candidate.id == currentSelection!.taskId)
              .firstOrNull;
    final sub = subtext(isDark);

    if (skill == null) {
      return AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InspectorTitle(
                icon: Icons.touch_app_outlined,
                color: const Color(0xFF4A9EFF),
                title: 'Выберите навык',
                subtitle: 'карта покажет этапы',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              Text(
                'На карте видны навыки как сферы. Выберите навык, чтобы увидеть путь и практику.',
                style: TextStyle(
                  color: sub,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: state.skills
                    .map(
                      (skill) => _MobileMasterySkillChip(
                        skill: skill,
                        isDark: isDark,
                        onTap: () => onSelectSkill(skill),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );
    }

    final title = switch (currentSelection?.type) {
      _MasterySelectionType.node when node != null => 'Этап: ${node.title}',
      _MasterySelectionType.quest when task != null =>
        'Практика: ${task.title}',
      _ => 'Путь: ${skill.name}',
    };
    final subtitle = switch (currentSelection?.type) {
      _MasterySelectionType.node when node != null =>
        '${state.completedTasksForTreeNode(skill.id, node.id)}/${node.questTarget} практики · ${skillTreeNodeStatusLabel[skill.treeNodeStatus(node)]}',
      _MasterySelectionType.quest when task != null =>
        task.isDone
            ? 'засчитано в прогресс пути'
            : 'выполнять лучше в «Действовать»',
      _ =>
        skill.goal.trim().isEmpty
            ? 'Цель пути пока не задана'
            : 'Цель пути: ${skill.goal}',
    };

    return AppPanel(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: skill.color.withAlpha(isDark ? 32 : 22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                currentSelection?.type == _MasterySelectionType.node
                    ? Icons.bolt_rounded
                    : currentSelection?.type == _MasterySelectionType.quest
                    ? Icons.flag
                    : skill.icon,
                color: skill.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: sub,
                      fontSize: 11.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onOpenDetails != null) ...[
              const SizedBox(width: 8),
              SmallBtn(
                label: 'Детали',
                icon: Icons.expand_less,
                color: const Color(0xFF4A9EFF),
                onTap: onOpenDetails!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MobileMasterySelectionPanel extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final _MasterySelection? selection;
  final GlobalKey? practiceTutorialKey;
  final ValueChanged<Skill> onSelectSkill;
  final ValueChanged<Skill> onAddRoot;
  final void Function(Skill skill, SkillTreeNode node) onExtendPath;
  final void Function(Skill skill, SkillTreeNode node) onRenameNode;
  final void Function(Skill skill, SkillTreeNode? node) onAddQuest;
  final void Function(Task task, Offset position) onToggleQuest;
  final void Function(Task task, Offset position) onMinimumAction;
  final void Function(Skill skill, Task task) onEditQuest;
  final ValueChanged<Task> onDeleteQuest;
  final void Function(Skill skill, SkillTreeNode node) onMasterNode;
  final void Function(Skill skill, SkillTreeNode node) onDeleteNode;

  const _MobileMasterySelectionPanel({
    required this.state,
    required this.isDark,
    required this.selection,
    this.practiceTutorialKey,
    required this.onSelectSkill,
    required this.onAddRoot,
    required this.onExtendPath,
    required this.onRenameNode,
    required this.onAddQuest,
    required this.onToggleQuest,
    required this.onMinimumAction,
    required this.onEditQuest,
    required this.onDeleteQuest,
    required this.onMasterNode,
    required this.onDeleteNode,
  });

  @override
  Widget build(BuildContext context) {
    final currentSelection = selection;
    final skill = currentSelection == null
        ? null
        : state.skills
              .where((candidate) => candidate.id == currentSelection.skillId)
              .firstOrNull;
    final nodeId = currentSelection?.nodeId;
    final taskId = currentSelection?.taskId;
    final node = skill == null || nodeId == null
        ? null
        : skill.treeNodes
              .where((candidate) => candidate.id == nodeId)
              .firstOrNull;
    final task = taskId == null
        ? null
        : state.tasks.where((candidate) => candidate.id == taskId).firstOrNull;

    return AppPanel(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: switch (currentSelection?.type) {
          _MasterySelectionType.quest when skill != null && task != null =>
            _MobileQuestMasteryPanel(
              isDark: isDark,
              skill: skill,
              node: node,
              task: task,
              onEdit: () => onEditQuest(skill, task),
              onDelete: () => onDeleteQuest(task),
            ),
          _MasterySelectionType.node when skill != null && node != null =>
            _MobileNodeMasteryPanel(
              state: state,
              isDark: isDark,
              skill: skill,
              node: node,
              practiceTutorialKey: practiceTutorialKey,
              onRename: () => onRenameNode(skill, node),
              onExtendPath: () => onExtendPath(skill, node),
              onAddQuest: () => onAddQuest(skill, node),
              onToggleQuest: onToggleQuest,
              onMinimumAction: onMinimumAction,
              onEditQuest: (task) => onEditQuest(skill, task),
              onDeleteQuest: onDeleteQuest,
              onMaster: () => onMasterNode(skill, node),
              onDelete: () => onDeleteNode(skill, node),
            ),
          _MasterySelectionType.skill when skill != null =>
            _MobileSkillMasteryPanel(
              state: state,
              isDark: isDark,
              skill: skill,
              onToggleQuest: onToggleQuest,
              onMinimumAction: onMinimumAction,
              onEditQuest: (task) => onEditQuest(skill, task),
              onDeleteQuest: onDeleteQuest,
            ),
          _ => _MobileEmptyMasteryPanel(
            state: state,
            isDark: isDark,
            onSelectSkill: onSelectSkill,
          ),
        },
      ),
    );
  }
}

class _MobileEmptyMasteryPanel extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final ValueChanged<Skill> onSelectSkill;

  const _MobileEmptyMasteryPanel({
    required this.state,
    required this.isDark,
    required this.onSelectSkill,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorTitle(
          icon: Icons.touch_app_outlined,
          color: const Color(0xFF4A9EFF),
          title: 'Выберите навык',
          subtitle: 'карта покажет этапы, практика откроется в панели',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Text(
          'На мобильном карта остаётся обзором пути. Практика этапов живёт в этой панели ниже canvas.',
          style: TextStyle(
            color: sub,
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: state.skills
              .map(
                (skill) => _MobileMasterySkillChip(
                  skill: skill,
                  isDark: isDark,
                  onTap: () => onSelectSkill(skill),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _MobileMasterySkillChip extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final VoidCallback onTap;

  const _MobileMasterySkillChip({
    required this.skill,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: skill.color.withAlpha(isDark ? 15 : 10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: skill.color.withAlpha(48)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(skill.icon, color: skill.color, size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                skill.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${skill.masteredTreeNodeCount}/${skill.treeNodes.length}',
              style: TextStyle(
                color: skill.color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSkillMasteryPanel extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final Skill skill;
  final void Function(Task task, Offset position) onToggleQuest;
  final void Function(Task task, Offset position) onMinimumAction;
  final ValueChanged<Task> onEditQuest;
  final ValueChanged<Task> onDeleteQuest;

  const _MobileSkillMasteryPanel({
    required this.state,
    required this.isDark,
    required this.skill,
    required this.onToggleQuest,
    required this.onMinimumAction,
    required this.onEditQuest,
    required this.onDeleteQuest,
  });

  @override
  Widget build(BuildContext context) {
    final freeTasks = state.tasks
        .where((task) => task.skillId == skill.id && task.treeNodeId == null)
        .toList();
    final activeFreeTasks = _sortedActiveQuests(
      freeTasks.where((task) => !task.isDone),
    );
    final completedFreeTasks = _sortedCompletedQuests(
      freeTasks.where((task) => task.isDone),
    );
    final stageGroups = <_StageQuestGroup>[];
    for (final node in skill.treeNodes) {
      final linkedTasks = state.tasksForTreeNode(skill.id, node.id);
      if (linkedTasks.isEmpty) continue;
      stageGroups.add(
        _StageQuestGroup(
          node: node,
          activeTasks: _sortedActiveQuests(
            linkedTasks.where((task) => !task.isDone),
          ),
          completedTasks: _sortedCompletedQuests(
            linkedTasks.where((task) => task.isDone),
          ),
        ),
      );
    }
    final hasFreeTasks =
        activeFreeTasks.isNotEmpty || completedFreeTasks.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorTitle(
          icon: skill.icon,
          color: skill.color,
          title: skill.name,
          subtitle: skill.goal.trim().isEmpty
              ? 'Цель пути пока не задана'
              : 'Цель пути: ${skill.goal}',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        if (hasFreeTasks || stageGroups.isEmpty) ...[
          _MobileStagePracticeList(
            title: hasFreeTasks ? 'Квесты без этапа' : 'Квесты навыка',
            activeTasks: activeFreeTasks,
            completedTasks: completedFreeTasks,
            emptyText: 'Квестов у навыка пока нет.',
            isDark: isDark,
            color: skill.color,
            onToggleQuest: onToggleQuest,
            onMinimumAction: onMinimumAction,
            onEditQuest: onEditQuest,
            onDeleteQuest: onDeleteQuest,
          ),
        ],
        if (stageGroups.isNotEmpty) ...[
          if (hasFreeTasks) const SizedBox(height: 12),
          for (final group in stageGroups) ...[
            _MobileCollapsibleQuestSection(
              title: group.node.title,
              subtitle: 'Квесты, которые двигают этот этап',
              count: group.count,
              isDark: isDark,
              color: skill.color,
              child: _MobileStagePracticeList(
                title: '',
                activeTasks: group.activeTasks,
                completedTasks: group.completedTasks,
                emptyText: 'Создайте практику для этого этапа.',
                isDark: isDark,
                color: skill.color,
                onToggleQuest: onToggleQuest,
                onMinimumAction: onMinimumAction,
                onEditQuest: onEditQuest,
                onDeleteQuest: onDeleteQuest,
                showTitle: false,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _MobileNodeMasteryPanel extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final Skill skill;
  final SkillTreeNode node;
  final GlobalKey? practiceTutorialKey;
  final VoidCallback onRename;
  final VoidCallback onExtendPath;
  final VoidCallback onAddQuest;
  final void Function(Task task, Offset position) onToggleQuest;
  final void Function(Task task, Offset position) onMinimumAction;
  final ValueChanged<Task> onEditQuest;
  final ValueChanged<Task> onDeleteQuest;
  final VoidCallback onMaster;
  final VoidCallback onDelete;

  const _MobileNodeMasteryPanel({
    required this.state,
    required this.isDark,
    required this.skill,
    required this.node,
    this.practiceTutorialKey,
    required this.onRename,
    required this.onExtendPath,
    required this.onAddQuest,
    required this.onToggleQuest,
    required this.onMinimumAction,
    required this.onEditQuest,
    required this.onDeleteQuest,
    required this.onMaster,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = skill.treeNodeStatus(node);
    final statusColor = status == SkillTreeNodeStatus.active
        ? skill.color
        : skillTreeNodeStatusColor[status]!;
    final completed = state.completedTasksForTreeNode(skill.id, node.id);
    final target = node.questTarget;
    final linkedTasks = state.tasksForTreeNode(skill.id, node.id);
    final activeTasks = _sortedActiveQuests(
      linkedTasks.where((task) => !task.isDone),
    );
    final completedTasks = _sortedCompletedQuests(
      linkedTasks.where((task) => task.isDone),
    );
    final ready = state.canMasterSkillTreeNode(skill.id, node.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorTitle(
          icon: switch (status) {
            SkillTreeNodeStatus.locked => Icons.lock,
            SkillTreeNodeStatus.active => Icons.bolt_rounded,
            SkillTreeNodeStatus.mastered => Icons.workspace_premium,
          },
          color: statusColor,
          title: node.title,
          subtitle: 'этап RoadMap · ${skill.name}',
          isDark: isDark,
          trailing: TaskBadge(
            icon: Icons.auto_awesome,
            label: '+${node.xpReward} XP',
            color: const Color(0xFFFFCC00),
          ),
        ),
        const SizedBox(height: 12),
        _MetricCard(
          isDark: isDark,
          color: statusColor,
          title: 'Практика для освоения',
          value: '${math.min(completed, target)} / $target',
          progress: (completed / target).clamp(0.0, 1.0),
          helperText:
              'Практика — закрытый квест этого этапа. Наберите нужное количество, чтобы освоить этап.',
          onEdit: () => _showStagePracticeTargetDialog(
            context,
            state: state,
            skill: skill,
            node: node,
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: practiceTutorialKey,
          child: _MobileStagePracticeList(
            title: '',
            activeTasks: activeTasks,
            completedTasks: completedTasks,
            emptyText: 'Создайте практику для этого этапа.',
            isDark: isDark,
            color: skill.color,
            onToggleQuest: onToggleQuest,
            onMinimumAction: onMinimumAction,
            onEditQuest: onEditQuest,
            onDeleteQuest: onDeleteQuest,
            showTitle: false,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SmallBtn(
              label: 'Переименовать',
              icon: Icons.edit_note,
              color: statusColor,
              onTap: onRename,
            ),
            SmallBtn(
              label: 'Создать квест',
              icon: Icons.add_task,
              color: skill.color,
              onTap: onAddQuest,
            ),
            SmallBtn(
              label: 'Продлить путь',
              icon: Icons.add_road,
              color: const Color(0xFF4A9EFF),
              onTap: onExtendPath,
            ),
            _MasterNodeAction(
              enabled: ready,
              mastered: node.isMastered,
              color: skill.color,
              onTap: onMaster,
            ),
            PressFeedback(
              scale: 0.94,
              tooltip: 'Удалить этап',
              onTap: onDelete,
              child: Icon(
                Icons.delete_outline,
                color: subtext(isDark),
                size: 21,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MobileQuestMasteryPanel extends StatelessWidget {
  final bool isDark;
  final Skill skill;
  final SkillTreeNode? node;
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MobileQuestMasteryPanel({
    required this.isDark,
    required this.skill,
    required this.node,
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = task.isDone ? const Color(0xFF34C759) : skill.color;
    final sub = subtext(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorTitle(
          icon: task.isDone ? Icons.check_circle : Icons.flag,
          color: color,
          title: task.title,
          subtitle: node == null
              ? 'практика навыка'
              : 'практика этапа: ${node!.title}',
          isDark: isDark,
        ),
        if (task.hasMinimumAction) ...[
          const SizedBox(height: 10),
          Text(
            'Минимум: ${task.minimumAction}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: sub,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            TaskBadge(
              icon: Icons.auto_awesome,
              label: '+${task.xpReward} XP',
              color: const Color(0xFF4A9EFF),
            ),
            TaskBadge(
              label: typeLabel[task.type]!,
              color: typeColor[task.type]!,
            ),
            if (task.hasMinimumAction)
              TaskBadge(
                icon: Icons.bolt,
                label: 'лёгкий старт',
                color: const Color(0xFFFF9500),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          task.isDone
              ? 'Эта практика уже засчитана в прогресс пути.'
              : 'Карта показывает, что тренирует этот квест. Выполнять его лучше в разделе «Действовать».',
          style: TextStyle(
            color: sub,
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SmallBtn(
              label: 'Редактировать',
              icon: Icons.edit,
              color: const Color(0xFF4A9EFF),
              onTap: onEdit,
            ),
            PressFeedback(
              scale: 0.94,
              tooltip: 'Удалить квест',
              onTap: onDelete,
              child: Icon(Icons.delete_outline, color: sub, size: 21),
            ),
          ],
        ),
      ],
    );
  }
}

class _MobileCollapsibleQuestSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final int count;
  final bool isDark;
  final Color color;
  final Widget child;

  const _MobileCollapsibleQuestSection({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.isDark,
    required this.color,
    required this.child,
  });

  @override
  State<_MobileCollapsibleQuestSection> createState() =>
      _MobileCollapsibleQuestSectionState();
}

class _MobileCollapsibleQuestSectionState
    extends State<_MobileCollapsibleQuestSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PressFeedback(
          scale: 0.98,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: widget.color.withAlpha(widget.isDark ? 18 : 12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.color.withAlpha(42)),
            ),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: widget.color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor(widget.isDark),
                      fontSize: 12.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(widget.isDark ? 34 : 22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: widget.color.withAlpha(55)),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: kMotionStandard,
          switchInCurve: kMotionCurve,
          switchOutCurve: kMotionExitCurve,
          child: _expanded
              ? Padding(
                  key: const ValueKey('expanded'),
                  padding: const EdgeInsets.only(top: 8),
                  child: widget.child,
                )
              : const SizedBox.shrink(key: ValueKey('collapsed')),
        ),
      ],
    );
  }
}

class _MobileStagePracticeList extends StatelessWidget {
  final String title;
  final List<Task> activeTasks;
  final List<Task> completedTasks;
  final String emptyText;
  final bool isDark;
  final Color color;
  final bool showTitle;
  final void Function(Task task, Offset position) onToggleQuest;
  final void Function(Task task, Offset position) onMinimumAction;
  final ValueChanged<Task> onEditQuest;
  final ValueChanged<Task> onDeleteQuest;

  const _MobileStagePracticeList({
    required this.title,
    required this.activeTasks,
    required this.completedTasks,
    required this.emptyText,
    required this.isDark,
    required this.color,
    this.showTitle = true,
    required this.onToggleQuest,
    required this.onMinimumAction,
    required this.onEditQuest,
    required this.onDeleteQuest,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final hasTasks = activeTasks.isNotEmpty || completedTasks.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            title,
            style: TextStyle(
              color: textColor(isDark),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
        ],
        if (!hasTasks)
          Text(
            emptyText,
            style: TextStyle(
              color: sub,
              fontSize: 11.8,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          )
        else ...[
          for (final task in activeTasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _MobileMasteryQuestRow(
                task: task,
                isDark: isDark,
                color: color,
                onToggle: (position) => onToggleQuest(task, position),
                onMinimumAction: (position) => onMinimumAction(task, position),
                onEdit: () => onEditQuest(task),
                onDelete: () => onDeleteQuest(task),
              ),
            ),
          if (activeTasks.isNotEmpty && completedTasks.isNotEmpty)
            const SizedBox(height: 7),
          for (final task in completedTasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _MobileMasteryQuestRow(
                task: task,
                isDark: isDark,
                color: color,
                onToggle: (position) => onToggleQuest(task, position),
                onMinimumAction: (position) => onMinimumAction(task, position),
                onEdit: () => onEditQuest(task),
                onDelete: () => onDeleteQuest(task),
              ),
            ),
        ],
      ],
    );
  }
}

class _MobileMasteryQuestRow extends StatelessWidget {
  final Task task;
  final bool isDark;
  final Color color;
  final ValueChanged<Offset> onToggle;
  final ValueChanged<Offset> onMinimumAction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MobileMasteryQuestRow({
    required this.task,
    required this.isDark,
    required this.color,
    required this.onToggle,
    required this.onMinimumAction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final canStartMinimum =
        task.hasMinimumAction && !task.isDone && !task.isMinimumActionDone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14141C) : const Color(0xFFF4F5FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Builder(
            builder: (iconContext) => PressFeedback(
              scale: 0.9,
              onTap: () => onToggle(_feedbackOriginFor(iconContext)),
              child: _QuestToggleCircle(
                done: task.isDone,
                color: color,
                isDark: isDark,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: task.isDone ? sub : textColor(isDark),
                    fontSize: _adaptiveQuestTitleFontSize(task.title),
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    decoration: task.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  task.isDone
                      ? 'Завершено'
                      : task.hasMinimumAction
                      ? 'Минимум есть'
                      : typeLabel[task.type]!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sub,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (canStartMinimum) ...[
            Builder(
              builder: (minimumContext) => _RoadmapMinimumButton(
                isDark: isDark,
                color: color,
                onTap: () =>
                    onMinimumAction(_feedbackOriginFor(minimumContext)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '+${task.xpReward} XP',
            style: TextStyle(
              color: task.isDone ? sub : color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          PressFeedback(
            scale: 0.9,
            tooltip: 'Редактировать',
            onTap: onEdit,
            child: Icon(Icons.edit_outlined, color: sub, size: 18),
          ),
          const SizedBox(width: 7),
          PressFeedback(
            scale: 0.9,
            tooltip: 'Удалить квест',
            onTap: () {
              AppFeedback.destructive();
              onDelete();
            },
            child: Icon(Icons.delete_outline, color: sub, size: 18),
          ),
        ],
      ),
    );
  }
}
