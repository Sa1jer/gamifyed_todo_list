part of '../mastery_map_workspace.dart';

enum _MobileRoadmapMode { path, freeMap }

class _MobileRoadmapJournal extends StatefulWidget {
  final AppState state;
  final bool isDark;
  final _MasterySelection? selection;
  final Widget freeMap;
  final GlobalKey? practiceTutorialKey;
  final ValueChanged<_MasterySelection?> onSelectionChanged;
  final ValueChanged<Skill> onAddRoot;
  final void Function(Skill skill, SkillTreeNode node) onExtendPath;
  final void Function(Skill skill, SkillTreeNode node) onRenameNode;
  final void Function(Skill skill, SkillTreeNode? node) onAddQuest;
  final void Function(Skill skill, RoadmapTemplateConfig config)
  onApplyRoadmapTemplate;
  final void Function(Task task, Offset position) onToggleQuest;
  final void Function(Task task, Offset position) onMinimumAction;
  final void Function(Skill skill, Task task) onEditQuest;
  final ValueChanged<Task> onDeleteQuest;
  final void Function(Skill skill, SkillTreeNode node) onMasterNode;
  final void Function(Skill skill, SkillTreeNode node) onDeleteNode;

  const _MobileRoadmapJournal({
    required this.state,
    required this.isDark,
    required this.selection,
    required this.freeMap,
    this.practiceTutorialKey,
    required this.onSelectionChanged,
    required this.onAddRoot,
    required this.onExtendPath,
    required this.onRenameNode,
    required this.onAddQuest,
    required this.onApplyRoadmapTemplate,
    required this.onToggleQuest,
    required this.onMinimumAction,
    required this.onEditQuest,
    required this.onDeleteQuest,
    required this.onMasterNode,
    required this.onDeleteNode,
  });

  @override
  State<_MobileRoadmapJournal> createState() => _MobileRoadmapJournalState();
}

class _MobileRoadmapJournalState extends State<_MobileRoadmapJournal> {
  _MobileRoadmapMode _mode = _MobileRoadmapMode.path;
  final Map<String, int> _pathIndexBySkill = {};

  @override
  Widget build(BuildContext context) {
    final selection = widget.selection;
    final skill = selection == null
        ? null
        : widget.state.roadmapSkills
              .where((candidate) => candidate.id == selection.skillId)
              .firstOrNull;

    return Column(
      key: const ValueKey('mobile-roadmap-journal'),
      children: [
        _MobileRoadmapHeader(isDark: widget.isDark),
        const SizedBox(height: 10),
        if (skill == null)
          Expanded(
            child: _MobileRoadmapSkillChooser(
              state: widget.state,
              isDark: widget.isDark,
              onSelect: (selected) => widget.onSelectionChanged(
                _MasterySelection.skill(selected.id),
              ),
            ),
          )
        else ...[
          _buildSkillSwitcher(skill),
          const SizedBox(height: 8),
          _buildModeSwitcher(skill),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: _roadmapMotionDuration(context),
              child: _mode == _MobileRoadmapMode.freeMap
                  ? KeyedSubtree(
                      key: const ValueKey('mobile-roadmap-free-map'),
                      child: widget.freeMap,
                    )
                  : _buildPathView(skill),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSkillSwitcher(Skill selectedSkill) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        key: const ValueKey('mobile-roadmap-skill-switcher'),
        scrollDirection: Axis.horizontal,
        itemCount: widget.state.roadmapSkills.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final skill = widget.state.roadmapSkills[index];
          final selected = skill.id == selectedSkill.id;
          return ChoiceChip(
            key: ValueKey('mobile-roadmap-skill-${skill.id}'),
            selected: selected,
            showCheckmark: false,
            avatar: Icon(skill.icon, size: 16, color: skill.color),
            label: Text(skill.name, overflow: TextOverflow.ellipsis),
            onSelected: (_) {
              if (!selected) {
                widget.onSelectionChanged(_MasterySelection.skill(skill.id));
              }
            },
            selectedColor: skill.color.withAlpha(widget.isDark ? 28 : 18),
            backgroundColor: surface(widget.isDark),
            side: BorderSide(
              color: selected
                  ? skill.color.withAlpha(110)
                  : borderColor(widget.isDark),
            ),
            labelStyle: TextStyle(
              color: selected ? skill.color : textColor(widget.isDark),
              fontWeight: FontWeight.w800,
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeSwitcher(Skill skill) {
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<_MobileRoadmapMode>(
            key: const ValueKey('mobile-roadmap-mode-switcher'),
            segments: const [
              ButtonSegment(
                value: _MobileRoadmapMode.path,
                icon: Icon(Icons.route_rounded, size: 18),
                label: Text('Путь навыка'),
              ),
              ButtonSegment(
                value: _MobileRoadmapMode.freeMap,
                icon: Icon(Icons.hub_outlined, size: 18),
                label: Text('Свободная карта'),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() => _mode = value.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? skill.color
                    : subtext(widget.isDark),
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        IconButton.outlined(
          key: const ValueKey('mobile-roadmap-templates'),
          tooltip: 'Шаблоны путей',
          onPressed: () => _showTemplates(skill),
          style: IconButton.styleFrom(minimumSize: const Size.square(44)),
          icon: const Icon(Icons.layers_outlined, size: 19),
        ),
      ],
    );
  }

  Widget _buildPathView(Skill skill) {
    final completedCounts = {
      for (final node in skill.treeNodes)
        node.id: widget.state.completedTasksForTreeNode(skill.id, node.id),
    };
    final snapshot = const RoadmapEngine().buildSnapshot(
      skill,
      completedQuestCountsByNodeId: completedCounts,
    );
    final layout = const RoadmapEngine().buildPathLayout(skill);
    final paths = layout.paths;
    var selectedIndex = _pathIndexBySkill.putIfAbsent(skill.id, () {
      final currentId = snapshot.currentStage?.node.id;
      if (currentId == null) return 0;
      return paths
          .indexWhere((path) => path.nodes.any((n) => n.id == currentId))
          .clamp(0, math.max(0, paths.length - 1));
    });
    if (selectedIndex >= paths.length) selectedIndex = 0;
    final selectedPath = paths.isEmpty ? null : paths[selectedIndex];
    final infoById = {
      for (final stage in snapshot.stages) stage.node.id: stage,
    };

    return DecoratedBox(
      key: ValueKey('mobile-roadmap-path-${skill.id}'),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF0D0E15)
            : const Color(0xFFF6F0E5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor(widget.isDark).withAlpha(150)),
      ),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildProgressCard(skill, snapshot)),
              if (paths.length > 1)
                SliverToBoxAdapter(
                  child: _buildBranchSelector(skill, paths, selectedIndex),
                ),
              if (selectedPath == null || selectedPath.nodes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MobileEmptyPath(
                    skill: skill,
                    isDark: widget.isDark,
                    onAddStage: () => widget.onAddRoot(skill),
                    onTemplates: () => _showTemplates(skill),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 76),
                  sliver: SliverList.builder(
                    itemCount: selectedPath.nodes.length,
                    itemBuilder: (context, index) {
                      final node = selectedPath.nodes[index];
                      final info = infoById[node.id];
                      if (info == null) return const SizedBox.shrink();
                      return _MobileRoadmapStageRow(
                        key: ValueKey('mobile-path-stage-${node.id}'),
                        skill: skill,
                        info: info,
                        isDark: widget.isDark,
                        alternate: index.isOdd,
                        first: index == 0,
                        last: index == selectedPath.nodes.length - 1,
                        onTap: () => _showStageDetails(skill, node),
                      );
                    },
                  ),
                ),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: OutlinedButton.icon(
              key: const ValueKey('mobile-roadmap-path-back-to-skills'),
              onPressed: () => widget.onSelectionChanged(null),
              style: OutlinedButton.styleFrom(
                backgroundColor: surface(widget.isDark),
              ),
              icon: const Icon(Icons.keyboard_return_rounded, size: 18),
              label: const Text('Назад к навыкам'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Skill skill, RoadmapSnapshot snapshot) {
    final progress = const GoalProgressEngine().snapshotForSkill(skill);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: skill.color.withAlpha(widget.isDark ? 15 : 10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: skill.color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: skill.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(skill.icon, color: skill.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Путь: ${skill.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor(widget.isDark),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      snapshot.currentStage == null
                          ? 'Выбери следующий этап пути'
                          : 'Сейчас: ${snapshot.currentStage!.node.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtext(widget.isDark),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showSkillDetails(skill),
                child: const Text('Детали'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Прогресс цели ${skill.name}',
            value: progress.percentLabel,
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress.value,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: skill.color.withAlpha(25),
                    color: skill.color,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  progress.isEmpty ? 'Нет пути' : progress.percentLabel,
                  style: TextStyle(
                    color: progress.isEmpty
                        ? subtext(widget.isDark)
                        : skill.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchSelector(
    Skill skill,
    List<RoadmapPath> paths,
    int selectedIndex,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.call_split_rounded, color: skill.color, size: 16),
              const SizedBox(width: 6),
              Text(
                'Есть развилки',
                style: TextStyle(
                  color: subtext(widget.isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: paths.map((path) {
                final selected = path.index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    label: Text('Путь ${path.index + 1}'),
                    onSelected: (_) => setState(
                      () => _pathIndexBySkill[skill.id] = path.index,
                    ),
                    selectedColor: skill.color.withAlpha(
                      widget.isDark ? 30 : 18,
                    ),
                    side: BorderSide(
                      color: selected
                          ? skill.color.withAlpha(100)
                          : borderColor(widget.isDark),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showTemplates(Skill skill) {
    final applyTemplate = widget.onApplyRoadmapTemplate;
    final isDark = widget.isDark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.72,
          child: Container(
            decoration: BoxDecoration(
              color: surface(isDark),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              child: _RoadmapTemplatePanel(
                key: const ValueKey('mobile-roadmap-template-sheet'),
                skill: skill,
                isDark: isDark,
                sheetMode: true,
                onHide: () => Navigator.pop(sheetContext),
                onApply: (config) {
                  Navigator.pop(sheetContext);
                  applyTemplate(skill, config);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSkillDetails(Skill skill) {
    widget.onSelectionChanged(_MasterySelection.skill(skill.id));
    _showDetails(_MasterySelection.skill(skill.id));
  }

  void _showStageDetails(Skill skill, SkillTreeNode node) {
    final selection = _MasterySelection.node(skill.id, node.id);
    widget.onSelectionChanged(selection);
    _showDetails(selection);
  }

  void _showDetails(_MasterySelection selection) {
    final state = widget.state;
    final isDark = widget.isDark;
    final onSelectionChanged = widget.onSelectionChanged;
    final onAddRoot = widget.onAddRoot;
    final onExtendPath = widget.onExtendPath;
    final onRenameNode = widget.onRenameNode;
    final onAddQuest = widget.onAddQuest;
    final onToggleQuest = widget.onToggleQuest;
    final onMinimumAction = widget.onMinimumAction;
    final onEditQuest = widget.onEditQuest;
    final onDeleteQuest = widget.onDeleteQuest;
    final onMasterNode = widget.onMasterNode;
    final onDeleteNode = widget.onDeleteNode;
    final practiceKey = widget.practiceTutorialKey;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        void closeThen(VoidCallback action) {
          Navigator.pop(sheetContext);
          action();
        }

        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.86,
            child: _MobileMasterySelectionPanel(
              state: state,
              isDark: isDark,
              selection: selection,
              practiceTutorialKey: practiceKey,
              onSelectSkill: (skill) {
                Navigator.pop(sheetContext);
                onSelectionChanged(_MasterySelection.skill(skill.id));
              },
              onAddRoot: (skill) => closeThen(() => onAddRoot(skill)),
              onExtendPath: (skill, node) =>
                  closeThen(() => onExtendPath(skill, node)),
              onRenameNode: (skill, node) =>
                  closeThen(() => onRenameNode(skill, node)),
              onAddQuest: (skill, node) =>
                  closeThen(() => onAddQuest(skill, node)),
              onToggleQuest: onToggleQuest,
              onMinimumAction: onMinimumAction,
              onEditQuest: (skill, task) =>
                  closeThen(() => onEditQuest(skill, task)),
              onDeleteQuest: (task) => closeThen(() => onDeleteQuest(task)),
              onMasterNode: (skill, node) =>
                  closeThen(() => onMasterNode(skill, node)),
              onDeleteNode: (skill, node) =>
                  closeThen(() => onDeleteNode(skill, node)),
            ),
          ),
        );
      },
    );
  }
}

class _MobileRoadmapHeader extends StatelessWidget {
  final bool isDark;

  const _MobileRoadmapHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151426) : const Color(0xFFF3EFFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7562FF).withAlpha(isDark ? 65 : 75),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7562FF).withAlpha(26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.map_outlined, color: Color(0xFF7562FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Дорожная карта',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Путь навыка: этапы, связи и цели',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subtext(isDark), fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileRoadmapSkillChooser extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final ValueChanged<Skill> onSelect;

  const _MobileRoadmapSkillChooser({
    required this.state,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const ValueKey('mobile-roadmap-skill-chooser'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: state.roadmapSkills.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
            child: Text(
              'Выбери навык, чтобы открыть его маршрут. Карта не выбирает первый путь за тебя.',
              style: TextStyle(
                color: subtext(isDark),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          );
        }
        final skill = state.roadmapSkills[index - 1];
        final progress = const GoalProgressEngine().snapshotForSkill(skill);
        return PressFeedback(
          key: ValueKey('mobile-roadmap-choose-${skill.id}'),
          scale: 0.98,
          onTap: () => onSelect(skill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: surface(isDark),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: skill.color.withAlpha(55)),
            ),
            child: Row(
              children: [
                Icon(skill.icon, color: skill.color, size: 25),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    skill.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor(isDark),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  progress.isEmpty ? 'Нет пути' : progress.percentLabel,
                  style: TextStyle(
                    color: progress.isEmpty ? subtext(isDark) : skill.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: subtext(isDark)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileRoadmapStageRow extends StatelessWidget {
  final Skill skill;
  final RoadmapStageInfo info;
  final bool isDark;
  final bool alternate;
  final bool first;
  final bool last;
  final VoidCallback onTap;

  const _MobileRoadmapStageRow({
    super.key,
    required this.skill,
    required this.info,
    required this.isDark,
    required this.alternate,
    required this.first,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _stageVisual(info, skill);
    return Semantics(
      button: true,
      label:
          '${info.node.title}, ${visual.label}, ${info.completedLinkedQuests} из ${info.questTarget} квестов',
      child: SizedBox(
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: first ? 52 : 0,
              bottom: last ? 52 : 0,
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: visual.color.withAlpha(info.isCurrent ? 110 : 48),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: alternate
                      ? _StageLabelCard(
                          info: info,
                          visual: visual,
                          isDark: isDark,
                          onTap: onTap,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 10),
                _StageNode(info: info, visual: visual, onTap: onTap),
                const SizedBox(width: 10),
                Expanded(
                  child: alternate
                      ? const SizedBox.shrink()
                      : _StageLabelCard(
                          info: info,
                          visual: visual,
                          isDark: isDark,
                          onTap: onTap,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageNode extends StatelessWidget {
  final RoadmapStageInfo info;
  final _StageVisual visual;
  final VoidCallback onTap;

  const _StageNode({
    required this.info,
    required this.visual,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      scale: 0.94,
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: visual.color.withAlpha(info.isCurrent ? 35 : 13),
          border: Border.all(
            color: visual.color,
            width: info.isCurrent ? 3 : 2,
          ),
          boxShadow: info.isCurrent
              ? [BoxShadow(color: visual.color.withAlpha(80), blurRadius: 18)]
              : null,
        ),
        child: Icon(visual.icon, color: visual.color, size: 25),
      ),
    );
  }
}

class _StageLabelCard extends StatelessWidget {
  final RoadmapStageInfo info;
  final _StageVisual visual;
  final bool isDark;
  final VoidCallback onTap;

  const _StageLabelCard({
    required this.info,
    required this.visual,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: visual.color.withAlpha(info.isCurrent ? 20 : 8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: visual.color.withAlpha(55)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.node.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: info.role == RoadmapStageRole.locked
                    ? subtext(isDark)
                    : textColor(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${visual.label} · ${info.completedLinkedQuests}/${info.questTarget}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: visual.color, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileEmptyPath extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final VoidCallback onAddStage;
  final VoidCallback onTemplates;

  const _MobileEmptyPath({
    required this.skill,
    required this.isDark,
    required this.onAddStage,
    required this.onTemplates,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_outlined, color: skill.color, size: 34),
            const SizedBox(height: 10),
            Text(
              'У пути пока нет этапов',
              style: TextStyle(
                color: textColor(isDark),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Добавь первый этап вручную или выбери готовую структуру.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtext(isDark), fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAddStage,
              style: FilledButton.styleFrom(
                backgroundColor: skill.color,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Добавить этап'),
            ),
            TextButton.icon(
              onPressed: onTemplates,
              icon: const Icon(Icons.layers_outlined),
              label: const Text('Шаблоны путей'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageVisual {
  final String label;
  final IconData icon;
  final Color color;

  const _StageVisual(this.label, this.icon, this.color);
}

_StageVisual _stageVisual(RoadmapStageInfo info, Skill skill) {
  return switch (info.role) {
    RoadmapStageRole.completed => _StageVisual(
      'Завершён',
      Icons.check_rounded,
      _roadmapStageStatusColor(skill, SkillTreeNodeStatus.mastered),
    ),
    RoadmapStageRole.current => _StageVisual(
      'Активный',
      Icons.bolt_rounded,
      skill.color,
    ),
    RoadmapStageRole.next => _StageVisual(
      'Следующий',
      Icons.arrow_downward_rounded,
      skill.color.withAlpha(190),
    ),
    RoadmapStageRole.locked => const _StageVisual(
      'Закрыт',
      Icons.lock_outline_rounded,
      Color(0xFF6F707B),
    ),
  };
}

Duration _roadmapMotionDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : kMotionSlow;
