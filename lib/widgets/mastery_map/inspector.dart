part of '../mastery_map_workspace.dart';

void _showStagePracticeTargetDialog(
  BuildContext context, {
  required AppState state,
  required Skill skill,
  required SkillTreeNode node,
}) {
  var target = node.questTarget;
  var xpReward = node.xpReward;
  final isDark = state.isDark;
  final bg = surface(isDark);
  final txt = textColor(isDark);
  final sub = subtext(isDark);
  final color = skill.color;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          void setTarget(int value) {
            setDialogState(() => target = value.clamp(1, 30).toInt());
          }

          Widget chip(String label, int value) {
            final selected = target == value;
            return PressFeedback(
              scale: 0.96,
              onTap: () => setTarget(value),
              child: AnimatedContainer(
                duration: kMotionStandard,
                curve: kMotionCurve,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? color.withAlpha(34) : surface(isDark),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? color : borderColor(isDark),
                    width: selected ? 1.3 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? color : sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }

          return Dialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: SizedBox(
              width: 390,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DlgHeader(title: 'Практики и XP', txtColor: txt),
                    const SizedBox(height: 8),
                    Text(
                      'Практика — это закрытый квест, привязанный к этапу. Когда набирается нужное количество практик, этап можно освоить.',
                      style: TextStyle(
                        color: sub,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withAlpha(isDark ? 18 : 12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withAlpha(42)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Нужно практик',
                              style: TextStyle(
                                color: txt,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _PracticeTargetStepButton(
                            isDark: isDark,
                            color: color,
                            icon: Icons.remove,
                            enabled: target > 1,
                            onTap: () => setTarget(target - 1),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '$target',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: color,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _PracticeTargetStepButton(
                            isDark: isDark,
                            color: color,
                            icon: Icons.add,
                            enabled: target < 30,
                            onTap: () => setTarget(target + 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip('Лёгкий · 1', 1),
                        chip('Обычный · 3', 3),
                        chip('Глубокий · 5', 5),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'XP за освоение',
                            style: TextStyle(
                              color: txt,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        TaskBadge(
                          icon: Icons.auto_awesome,
                          label: '+$xpReward XP',
                          color: const Color(0xFFFFCC00),
                        ),
                      ],
                    ),
                    Slider(
                      value: xpReward.toDouble(),
                      min: 10,
                      max: 200,
                      divisions: 19,
                      activeColor: color,
                      inactiveColor: color.withAlpha(42),
                      onChanged: (value) =>
                          setDialogState(() => xpReward = value.round()),
                    ),
                    const SizedBox(height: 18),
                    DlgActions(
                      onCancel: () => Navigator.pop(dialogContext),
                      onSave: () {
                        state.updateSkillTreeNodePracticeTarget(
                          skill.id,
                          node.id,
                          target,
                          xpReward: xpReward,
                        );
                        Navigator.pop(dialogContext);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _PracticeTargetStepButton extends StatelessWidget {
  final bool isDark;
  final Color color;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PracticeTargetStepButton({
    required this.isDark,
    required this.color,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final button = AnimatedContainer(
      duration: kMotionStandard,
      curve: kMotionCurve,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: enabled ? color.withAlpha(26) : surface(isDark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled ? color.withAlpha(135) : borderColor(isDark),
        ),
      ),
      child: Icon(
        icon,
        color: enabled ? color : subtext(isDark).withAlpha(110),
        size: 17,
      ),
    );
    if (!enabled) return button;
    return PressFeedback(scale: 0.92, onTap: onTap, child: button);
  }
}

class _MasteryMapInspector extends StatelessWidget {
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

  const _MasteryMapInspector({
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
  });

  @override
  Widget build(BuildContext context) {
    final currentSelection = selection;
    if (currentSelection == null) {
      return AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _EmptyMapInspector(
            state: state,
            isDark: isDark,
            onSelectSkill: onSelectSkill,
          ),
        ),
      );
    }

    final skill = state.skills
        .where((candidate) => candidate.id == currentSelection.skillId)
        .firstOrNull;
    if (skill == null) {
      return AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _EmptyMapInspector(
            state: state,
            isDark: isDark,
            onSelectSkill: onSelectSkill,
          ),
        ),
      );
    }

    final node = skill.treeNodes
        .where((candidate) => candidate.id == currentSelection.nodeId)
        .firstOrNull;
    final task = state.tasks
        .where((candidate) => candidate.id == currentSelection.taskId)
        .firstOrNull;

    return AppPanel(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: switch (currentSelection.type) {
          _MasterySelectionType.quest when task != null =>
            _QuestPracticeInspector(
              isDark: isDark,
              skill: skill,
              task: task,
              node: node,
              onEdit: () => onEditQuest(skill, task),
              onDelete: () => onDeleteQuest(task),
            ),
          _MasterySelectionType.node when node != null => _NodeInspector(
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
          ),
          _ => _SkillInspector(
            state: state,
            isDark: isDark,
            skill: skill,
            onSelectQuest: (task) => onSelectQuest(skill, task),
            onToggleQuest: onToggleQuest,
            onEditQuest: (task) => onEditQuest(skill, task),
          ),
        },
      ),
    );
  }
}

class _EmptyMapInspector extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final ValueChanged<Skill> onSelectSkill;

  const _EmptyMapInspector({
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
          subtitle: 'шар раскроет свою ветку мастерства',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Text(
          'Карта показывает все навыки как сферы. Нажмите на любую сферу, чтобы увидеть этапы, практику и следующий шаг освоения.',
          style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: state.skills.length,
            separatorBuilder: (_, _) => const SizedBox(height: 7),
            itemBuilder: (context, index) {
              final skill = state.skills[index];
              return PressFeedback(
                scale: 0.98,
                onTap: () => onSelectSkill(skill),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF14141C)
                        : const Color(0xFFF4F5FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor(isDark)),
                  ),
                  child: Row(
                    children: [
                      Icon(skill.icon, color: skill.color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          skill.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor(isDark),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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
            },
          ),
        ),
      ],
    );
  }
}

class _RoadmapSummaryCard extends StatelessWidget {
  final bool isDark;
  final Color color;
  final RoadmapSnapshot snapshot;

  const _RoadmapSummaryCard({
    required this.isDark,
    required this.color,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final current = snapshot.currentStage;
    final next = snapshot.nextStage;
    final progressLabel = '${(snapshot.overallProgress * 100).round()}%';

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withAlpha(42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: color, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Roadmap навыка',
                  style: TextStyle(
                    color: txt,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                progressLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XPBar(
            progress: snapshot.overallProgress.clamp(0.0, 1.0),
            color: color,
            height: 5,
          ),
          const SizedBox(height: 8),
          GoalHeader(
            skill: snapshot.skill,
            isDark: isDark,
            maxLines: 2,
            emptyText: 'Roadmap пока без цели',
          ),
          const SizedBox(height: 9),
          _RoadmapFocusLine(
            isDark: isDark,
            color: color,
            icon: Icons.bolt_rounded,
            label: 'Сейчас',
            value: current == null
                ? 'Добавьте первый этап'
                : current.node.title,
            meta: current == null
                ? 'roadmap пока пуст'
                : '${math.min(current.completedLinkedQuests, current.questTarget)} / ${current.questTarget} практики',
          ),
          const SizedBox(height: 7),
          _RoadmapFocusLine(
            isDark: isDark,
            color: const Color(0xFF4A9EFF),
            icon: Icons.trending_flat_rounded,
            label: 'Дальше',
            value: next == null ? 'После текущего этапа' : next.node.title,
            meta: next == null
                ? 'новый этап появится в плане'
                : 'следующая ступень',
          ),
        ],
      ),
    );
  }
}

class _RoadmapFocusLine extends StatelessWidget {
  final bool isDark;
  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final String meta;

  const _RoadmapFocusLine({
    required this.isDark,
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label · $value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor(isDark),
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtext(isDark),
                  fontSize: 10.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkillInspector extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final Skill skill;
  final ValueChanged<Task> onSelectQuest;
  final void Function(Task task, Offset position) onToggleQuest;
  final ValueChanged<Task> onEditQuest;

  const _SkillInspector({
    required this.state,
    required this.isDark,
    required this.skill,
    required this.onSelectQuest,
    required this.onToggleQuest,
    required this.onEditQuest,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = state.tasksForSkill(skill.id);
    final activeSkillTasks = _sortedActiveQuests(
      tasks.where((task) => !task.isDone),
    );
    final completedSkillTasks = _sortedCompletedQuests(
      tasks.where((task) => task.isDone),
    );
    final activeTasks = activeSkillTasks.length;
    final doneTasks = completedSkillTasks.length;
    final txt = textColor(isDark);

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
            TaskBadge(
              label: '${skill.treeNodes.length} этап.',
              color: skill.color,
            ),
            TaskBadge(
              label: '${skill.masteredTreeNodeCount} освоено',
              color: const Color(0xFF34C759),
            ),
            TaskBadge(
              label: '$activeTasks активн.',
              color: const Color(0xFF4A9EFF),
            ),
            TaskBadge(
              label: '$doneTasks закрыто',
              color: const Color(0xFF8E8E93),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Практика навыка',
          style: TextStyle(
            color: txt,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _StagePracticeQuestList(
            isDark: isDark,
            color: skill.color,
            activeTasks: activeSkillTasks,
            completedTasks: completedSkillTasks,
            emptyText: 'Выберите этап на карте, чтобы создать практику.',
            onSelectQuest: onSelectQuest,
            onToggleQuest: onToggleQuest,
            onEditQuest: onEditQuest,
          ),
        ),
      ],
    );
  }
}

class _NodeInspector extends StatelessWidget {
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

  const _NodeInspector({
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
    final activeNodeTasks = _sortedActiveQuests(
      linkedTasks.where((task) => !task.isDone),
    );
    final completedNodeTasks = _sortedCompletedQuests(
      linkedTasks.where((task) => task.isDone),
    );
    final ready = state.canMasterSkillTreeNode(skill.id, node.id);
    final sub = subtext(isDark);

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
          subtitle: skillTreeNodeStatusLabel[status]!,
          isDark: isDark,
          trailing: TaskBadge(
            icon: Icons.auto_awesome,
            label: '+${node.xpReward} XP',
            color: const Color(0xFFFFCC00),
          ),
        ),
        if (node.description.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            node.description,
            style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
          ),
        ],
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        Text(
          'Практика этапа',
          style: TextStyle(
            color: textColor(isDark),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _StagePracticeQuestList(
            isDark: isDark,
            color: skill.color,
            activeTasks: activeNodeTasks,
            completedTasks: completedNodeTasks,
            emptyText: 'Создайте практику для этого этапа.',
            onSelectQuest: onSelectQuest,
            onToggleQuest: onToggleQuest,
            onEditQuest: onEditQuest,
          ),
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
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MasterNodeAction(
                enabled: ready,
                mastered: node.isMastered,
                color: skill.color,
                onTap: onMaster,
              ),
            ),
            const SizedBox(width: 10),
            PressFeedback(
              scale: 0.94,
              tooltip: 'Удалить этап',
              onTap: onDelete,
              child: Icon(Icons.delete_outline, color: sub, size: 21),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuestPracticeInspector extends StatelessWidget {
  final bool isDark;
  final Skill skill;
  final Task task;
  final SkillTreeNode? node;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestPracticeInspector({
    required this.isDark,
    required this.skill,
    required this.task,
    required this.node,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;
    final color = done ? const Color(0xFF34C759) : skill.color;
    final sub = subtext(isDark);

    return ListView(
      children: [
        _InspectorTitle(
          icon: done ? Icons.check_circle : Icons.flag,
          color: color,
          title: task.title,
          subtitle: node == null
              ? 'практика навыка'
              : 'практика этапа: ${node!.title}',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            TaskBadge(
              label: typeLabel[task.type]!,
              color: typeColor[task.type]!,
            ),
            TaskBadge(label: '+${task.xpReward} XP', color: skill.color),
            if (done)
              const TaskBadge(
                icon: Icons.check_circle,
                label: 'засчитано',
                color: Color(0xFF34C759),
              ),
          ],
        ),
        if (task.hasMinimumAction) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9500).withAlpha(55)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt, color: Color(0xFFFF9500), size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Минимальный шаг: ${task.minimumAction}',
                    style: TextStyle(
                      color: textColor(isDark),
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          done
              ? 'Эта практика уже засчитана в прогресс этапа. Если нужно изменить квест, откройте редактирование.'
              : node == null
              ? 'Это свободная практика навыка. Выполнять квест лучше в разделе «Действовать», чтобы сохранить дневной фокус.'
              : 'Эта практика двигает этап «${node!.title}». Выполнение остаётся в разделе «Действовать», а карта показывает путь.',
          style: TextStyle(
            color: sub,
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (done && task.lastCompletedAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Засчитано: ${formatShortDate(task.lastCompletedAt!)}',
            style: TextStyle(
              color: sub,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SmallBtn(
                label: 'Редактировать',
                icon: Icons.edit,
                color: const Color(0xFF4A9EFF),
                onTap: onEdit,
              ),
            ),
            const SizedBox(width: 10),
            PressFeedback(
              scale: 0.94,
              tooltip: 'Удалить квест',
              onTap: () {
                AppFeedback.destructive();
                onDelete();
              },
              child: Icon(Icons.delete_outline, color: sub, size: 22),
            ),
          ],
        ),
      ],
    );
  }
}

class _InspectorTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget? trailing;

  const _InspectorTitle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final titleFontSize = _adaptiveInspectorTitleFontSize(title);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor(isDark),
                  fontSize: titleFontSize,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtext(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final bool isDark;
  final Color color;
  final String title;
  final String value;
  final double progress;
  final String? helperText;
  final VoidCallback? onEdit;

  const _MetricCard({
    required this.isDark,
    required this.color,
    required this.title,
    required this.value,
    required this.progress,
    this.helperText,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: 6),
                PressFeedback(
                  scale: 0.9,
                  onTap: onEdit!,
                  child: Icon(Icons.edit, color: color, size: 16),
                ),
              ],
              const SizedBox(width: 5),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XPBar(progress: progress.clamp(0.0, 1.0), color: color, height: 6),
          if (helperText != null) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                helperText!,
                style: TextStyle(
                  color: subtext(isDark),
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StagePracticeQuestList extends StatelessWidget {
  final bool isDark;
  final Color color;
  final List<Task> activeTasks;
  final List<Task> completedTasks;
  final String emptyText;
  final ValueChanged<Task> onSelectQuest;
  final void Function(Task task, Offset position) onToggleQuest;
  final ValueChanged<Task> onEditQuest;

  const _StagePracticeQuestList({
    required this.isDark,
    required this.color,
    required this.activeTasks,
    required this.completedTasks,
    required this.emptyText,
    required this.onSelectQuest,
    required this.onToggleQuest,
    required this.onEditQuest,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final hasTasks = activeTasks.isNotEmpty || completedTasks.isNotEmpty;

    if (!hasTasks) {
      return Center(
        child: Text(
          emptyText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: sub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    return ListView(
      children: [
        for (final task in activeTasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _InspectorQuestRow(
              task: task,
              isDark: isDark,
              color: color,
              muted: false,
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
            child: _InspectorQuestRow(
              task: task,
              isDark: isDark,
              color: color,
              muted: true,
              onSelect: () => onSelectQuest(task),
              onToggle: (position) => onToggleQuest(task, position),
              onEdit: () => onEditQuest(task),
            ),
          ),
      ],
    );
  }
}

class _InspectorQuestRow extends StatelessWidget {
  final Task task;
  final bool isDark;
  final Color color;
  final bool muted;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onToggle;
  final VoidCallback onEdit;

  const _InspectorQuestRow({
    required this.task,
    required this.isDark,
    required this.color,
    required this.muted,
    required this.onSelect,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;
    final sub = subtext(isDark);
    final rowColor = done ? const Color(0xFF34C759) : color;
    final metadata = [
      typeLabel[task.type]!,
      priorityLabel[task.priority]!,
      if (task.hasMinimumAction) 'минимум есть',
    ].join(' · ');
    final titleFontSize = _adaptiveQuestTitleFontSize(task.title);

    return PressFeedback(
      scale: 0.985,
      onTap: onSelect,
      child: AnimatedContainer(
        duration: kMotionStandard,
        curve: kMotionCurve,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: muted || done
              ? surface(isDark).withAlpha(isDark ? 112 : 176)
              : (isDark ? const Color(0xFF14141C) : const Color(0xFFF4F5FA)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: done ? rowColor.withAlpha(42) : borderColor(isDark),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (iconContext) => PressFeedback(
                scale: 0.9,
                onTap: () => onToggle(_feedbackOriginFor(iconContext)),
                child: _QuestToggleCircle(
                  done: done,
                  color: rowColor,
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
                    softWrap: true,
                    style: TextStyle(
                      color: done ? sub : textColor(isDark),
                      fontSize: titleFontSize,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    done ? 'Завершено' : metadata,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${task.xpReward} XP',
                  style: TextStyle(
                    color: done ? sub : rowColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                PressFeedback(
                  scale: 0.9,
                  tooltip: 'Редактировать',
                  onTap: onEdit,
                  child: Icon(Icons.edit_outlined, color: sub, size: 17),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestToggleCircle extends StatelessWidget {
  final bool done;
  final Color color;
  final bool isDark;
  final double size;

  const _QuestToggleCircle({
    required this.done,
    required this.color,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = done ? const Color(0xFF34C759) : color;
    return AnimatedContainer(
      duration: kMotionStandard,
      curve: kMotionCurve,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? activeColor : Colors.transparent,
        border: Border.all(color: activeColor, width: 2),
        boxShadow: done
            ? [
                BoxShadow(
                  color: activeColor.withAlpha(isDark ? 80 : 52),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: kMotionStandard,
        switchInCurve: kMotionCurve,
        switchOutCurve: kMotionExitCurve,
        child: done
            ? Icon(
                Icons.check,
                key: const ValueKey('done'),
                size: size * 0.58,
                color: Colors.white,
              )
            : const SizedBox(key: ValueKey('active')),
      ),
    );
  }
}

class _MasterNodeAction extends StatelessWidget {
  final bool enabled;
  final bool mastered;
  final Color color;
  final VoidCallback onTap;

  const _MasterNodeAction({
    required this.enabled,
    required this.mastered,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mastered) {
      return TaskBadge(
        icon: Icons.check_circle,
        label: 'Освоено',
        color: const Color(0xFF34C759),
      );
    }

    final child = AnimatedOpacity(
      duration: kMotionStandard,
      curve: kMotionCurve,
      opacity: enabled ? 1 : 0.45,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Освоить',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );

    if (!enabled) return child;
    return PressFeedback(scale: 0.96, onTap: onTap, child: child);
  }
}
