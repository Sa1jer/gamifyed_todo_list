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
                subtitle: 'карта раскроет этапы, детали откроются отдельно',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              Text(
                'На карте виден путь мастерства. Нажмите на сферу навыка, чтобы посмотреть этапы.',
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
        '${skill.masteredTreeNodeCount}/${skill.treeNodes.length} этапов освоено · ${state.tasksForSkill(skill.id).where((task) => !task.isDone).length} активн.',
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
  final ValueChanged<Skill> onSelectSkill;
  final void Function(Skill skill, Task task) onSelectQuest;
  final ValueChanged<Skill> onAddRoot;
  final void Function(Skill skill, SkillTreeNode node) onExtendPath;
  final void Function(Skill skill, SkillTreeNode? node) onAddQuest;
  final void Function(Task task, Offset position) onToggleQuest;
  final void Function(Skill skill, Task task) onEditQuest;
  final ValueChanged<Task> onDeleteQuest;
  final void Function(Skill skill, SkillTreeNode node) onMasterNode;
  final void Function(Skill skill, SkillTreeNode node) onDeleteNode;
  final ValueChanged<Skill>? onOpenSkillSettings;

  const _MobileMasterySelectionPanel({
    required this.state,
    required this.isDark,
    required this.selection,
    required this.onSelectSkill,
    required this.onSelectQuest,
    required this.onAddRoot,
    required this.onExtendPath,
    required this.onAddQuest,
    required this.onToggleQuest,
    required this.onEditQuest,
    required this.onDeleteQuest,
    required this.onMasterNode,
    required this.onDeleteNode,
    required this.onOpenSkillSettings,
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
              onExtendPath: () => onExtendPath(skill, node),
              onAddQuest: () => onAddQuest(skill, node),
              onSelectQuest: (task) => onSelectQuest(skill, task),
              onToggleQuest: onToggleQuest,
              onEditQuest: (task) => onEditQuest(skill, task),
              onMaster: () => onMasterNode(skill, node),
              onDelete: () => onDeleteNode(skill, node),
              onOpenSkillSettings: onOpenSkillSettings == null
                  ? null
                  : () => onOpenSkillSettings!(skill),
            ),
          _MasterySelectionType.skill when skill != null =>
            _MobileSkillMasteryPanel(
              state: state,
              isDark: isDark,
              skill: skill,
              onSelectQuest: (task) => onSelectQuest(skill, task),
              onToggleQuest: onToggleQuest,
              onEditQuest: (task) => onEditQuest(skill, task),
              onOpenSkillSettings: onOpenSkillSettings == null
                  ? null
                  : () => onOpenSkillSettings!(skill),
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
  final ValueChanged<Task> onSelectQuest;
  final void Function(Task task, Offset position) onToggleQuest;
  final ValueChanged<Task> onEditQuest;
  final VoidCallback? onOpenSkillSettings;

  const _MobileSkillMasteryPanel({
    required this.state,
    required this.isDark,
    required this.skill,
    required this.onSelectQuest,
    required this.onToggleQuest,
    required this.onEditQuest,
    required this.onOpenSkillSettings,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = state.tasksForSkill(skill.id);
    final activeTasks = _sortedActiveQuests(
      tasks.where((task) => !task.isDone),
    );
    final completedCount = tasks.where((task) => task.isDone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorTitle(
          icon: skill.icon,
          color: skill.color,
          title: skill.name,
          subtitle: 'roadmap навыка',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        if (_showRoadmapSummaryInInspector) ...[
          _RoadmapSummaryCard(
            isDark: isDark,
            color: skill.color,
            snapshot: _roadmapSnapshotFor(state, skill),
          ),
          const SizedBox(height: 10),
        ],
        _MetricCard(
          isDark: isDark,
          color: skill.color,
          title: 'Прогресс навыка',
          value: '${skill.xp} / ${skill.xpNeeded} XP',
          progress: skill.progress,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            if (onOpenSkillSettings != null)
              SmallBtn(
                label: 'Настроить',
                icon: Icons.tune,
                color: skill.color,
                onTap: onOpenSkillSettings!,
              ),
            TaskBadge(
              label: '${skill.treeNodes.length} этап.',
              color: skill.color,
            ),
            TaskBadge(
              label: '${skill.masteredTreeNodeCount} освоено',
              color: const Color(0xFF34C759),
            ),
            TaskBadge(
              label: '${activeTasks.length} активн.',
              color: const Color(0xFF4A9EFF),
            ),
            TaskBadge(
              label: '$completedCount закрыто',
              color: const Color(0xFF8E8E93),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MobileMasteryQuestPreview(
          title: 'Практика навыка',
          tasks: activeTasks.take(3).toList(),
          emptyText: 'Выберите этап на карте, чтобы создать практику.',
          isDark: isDark,
          color: skill.color,
          onSelectQuest: onSelectQuest,
          onToggleQuest: onToggleQuest,
          onEditQuest: onEditQuest,
        ),
      ],
    );
  }
}

class _MobileNodeMasteryPanel extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final Skill skill;
  final SkillTreeNode node;
  final VoidCallback onExtendPath;
  final VoidCallback onAddQuest;
  final ValueChanged<Task> onSelectQuest;
  final void Function(Task task, Offset position) onToggleQuest;
  final ValueChanged<Task> onEditQuest;
  final VoidCallback onMaster;
  final VoidCallback onDelete;
  final VoidCallback? onOpenSkillSettings;

  const _MobileNodeMasteryPanel({
    required this.state,
    required this.isDark,
    required this.skill,
    required this.node,
    required this.onExtendPath,
    required this.onAddQuest,
    required this.onSelectQuest,
    required this.onToggleQuest,
    required this.onEditQuest,
    required this.onMaster,
    required this.onDelete,
    required this.onOpenSkillSettings,
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
          subtitle: 'этап мастерства · ${skill.name}',
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
        _MobileStagePracticeList(
          title: 'Практика этапа',
          activeTasks: activeTasks,
          completedTasks: completedTasks,
          emptyText: 'Создайте практику для этого этапа.',
          isDark: isDark,
          color: skill.color,
          onSelectQuest: onSelectQuest,
          onToggleQuest: onToggleQuest,
          onEditQuest: onEditQuest,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
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
            if (onOpenSkillSettings != null)
              SmallBtn(
                label: 'Настроить',
                icon: Icons.tune,
                color: skill.color,
                onTap: onOpenSkillSettings!,
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

class _MobileMasteryQuestPreview extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final String emptyText;
  final bool isDark;
  final Color color;
  final ValueChanged<Task> onSelectQuest;
  final void Function(Task task, Offset position) onToggleQuest;
  final ValueChanged<Task> onEditQuest;

  const _MobileMasteryQuestPreview({
    required this.title,
    required this.tasks,
    required this.emptyText,
    required this.isDark,
    required this.color,
    required this.onSelectQuest,
    required this.onToggleQuest,
    required this.onEditQuest,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor(isDark),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        if (tasks.isEmpty)
          Text(
            emptyText,
            style: TextStyle(
              color: sub,
              fontSize: 11.8,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _MobileMasteryQuestRow(
                task: task,
                isDark: isDark,
                color: color,
                onSelect: () => onSelectQuest(task),
                onToggle: (position) => onToggleQuest(task, position),
                onEdit: () => onEditQuest(task),
              ),
            ),
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
  final ValueChanged<Task> onSelectQuest;
  final void Function(Task task, Offset position) onToggleQuest;
  final ValueChanged<Task> onEditQuest;

  const _MobileStagePracticeList({
    required this.title,
    required this.activeTasks,
    required this.completedTasks,
    required this.emptyText,
    required this.isDark,
    required this.color,
    required this.onSelectQuest,
    required this.onToggleQuest,
    required this.onEditQuest,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final hasTasks = activeTasks.isNotEmpty || completedTasks.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor(isDark),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
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
                onSelect: () => onSelectQuest(task),
                onToggle: (position) => onToggleQuest(task, position),
                onEdit: () => onEditQuest(task),
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
                onSelect: () => onSelectQuest(task),
                onToggle: (position) => onToggleQuest(task, position),
                onEdit: () => onEditQuest(task),
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
  final VoidCallback onSelect;
  final ValueChanged<Offset> onToggle;
  final VoidCallback onEdit;

  const _MobileMasteryQuestRow({
    required this.task,
    required this.isDark,
    required this.color,
    required this.onSelect,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return PressFeedback(
      scale: 0.985,
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14141C) : const Color(0xFFF4F5FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor(isDark)),
        ),
        child: Row(
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
                    task.hasMinimumAction
                        ? 'Минимум есть · +${task.xpReward} XP'
                        : '+${task.xpReward} XP',
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
            PressFeedback(
              scale: 0.9,
              tooltip: 'Редактировать',
              onTap: onEdit,
              child: Icon(Icons.edit_outlined, color: sub, size: 17),
            ),
          ],
        ),
      ),
    );
  }
}
