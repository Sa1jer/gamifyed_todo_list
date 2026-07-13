part of '../mastery_map_workspace.dart';

class _MobileRoadmapJournal extends StatefulWidget {
  final AppState state;
  final bool isDark;
  final _MasterySelection? selection;
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
        _MobileRoadmapHeader(
          isDark: widget.isDark,
          onTemplates: skill == null ? null : () => _showTemplates(skill),
        ),
        const SizedBox(height: 6),
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
          const SizedBox(height: 5),
          Expanded(
            child: AnimatedSwitcher(
              duration: _roadmapMotionDuration(context),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.035),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _buildUnifiedGraph(skill),
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
            backgroundColor: MobileJournalTokens.surface(widget.isDark),
            side: BorderSide(
              color: selected
                  ? skill.color.withAlpha(110)
                  : MobileJournalTokens.outline(widget.isDark),
            ),
            labelStyle: TextStyle(
              color: selected
                  ? MobileJournalTokens.readableAccent(
                      skill.color,
                      widget.isDark,
                    )
                  : MobileJournalTokens.text(widget.isDark),
              fontWeight: FontWeight.w800,
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnifiedGraph(Skill skill) {
    final completedCounts = {
      for (final node in skill.treeNodes)
        node.id: widget.state.completedTasksForTreeNode(skill.id, node.id),
    };
    final snapshot = const RoadmapEngine().buildSnapshot(
      skill,
      completedQuestCountsByNodeId: completedCounts,
    );
    if (snapshot.isEmpty) {
      return _MobileEmptyPath(
        key: ValueKey('mobile-roadmap-unified-${skill.id}'),
        skill: skill,
        isDark: widget.isDark,
        onAddStage: () => widget.onAddRoot(skill),
        onTemplates: () => _showTemplates(skill),
      );
    }

    return _MobileRoadmapAscentGraph(
      key: ValueKey('mobile-roadmap-unified-${skill.id}'),
      skill: skill,
      snapshot: snapshot,
      isDark: widget.isDark,
      onTapRoot: () => _showSkillDetails(skill),
      onTapStage: (node) => _showStageDetails(skill, node),
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
              color: MobileJournalTokens.surface(isDark),
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

class _MobileRoadmapAscentGraph extends StatelessWidget {
  final Skill skill;
  final RoadmapSnapshot snapshot;
  final bool isDark;
  final VoidCallback onTapRoot;
  final ValueChanged<SkillTreeNode> onTapStage;

  const _MobileRoadmapAscentGraph({
    super.key,
    required this.skill,
    required this.snapshot,
    required this.isDark,
    required this.onTapRoot,
    required this.onTapStage,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = const MobileRoadMapAscentLayout().calculate(
          viewport: Size(constraints.maxWidth, constraints.maxHeight),
          stages: snapshot.stages,
          textScale: textScale,
        );
        final progress = const GoalProgressEngine().snapshotForSkill(skill);
        return RepaintBoundary(
          child: SingleChildScrollView(
            key: ValueKey('mobile-roadmap-graph-scroll-${skill.id}'),
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(bottom: 18),
            child: SizedBox(
              width: layout.size.width,
              height: layout.size.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MobileRoadmapConnectionsPainter(
                        layout: layout,
                        skill: skill,
                      ),
                    ),
                  ),
                  for (final geometry in layout.nodes.values) ...[
                    Positioned.fromRect(
                      rect: geometry.cardRect,
                      child: _MobileRoadmapStageCard(
                        geometry: geometry,
                        skill: skill,
                        isDark: isDark,
                        onTap: () => onTapStage(geometry.stage.node),
                      ),
                    ),
                    Positioned(
                      left: geometry.center.dx - geometry.radius,
                      top: geometry.center.dy - geometry.radius,
                      width: geometry.radius * 2,
                      height: geometry.radius * 2,
                      child: _MobileRoadmapStageNode(
                        geometry: geometry,
                        skill: skill,
                        onTap: () => onTapStage(geometry.stage.node),
                      ),
                    ),
                  ],
                  Positioned(
                    left: layout.rootCenter.dx - layout.rootRadius,
                    top: layout.rootCenter.dy - layout.rootRadius,
                    width: layout.rootRadius * 2,
                    height: layout.rootRadius * 2,
                    child: _MobileRoadmapRootNode(
                      skill: skill,
                      progressLabel: progress.isEmpty
                          ? 'Нет пути'
                          : progress.percentLabel,
                      progressValue: progress.value,
                      onTap: onTapRoot,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: layout.rootCenter.dy + layout.rootRadius + 4,
                    child: Semantics(
                      label:
                          'Навык ${skill.name}, уровень ${skill.level}, прогресс пути ${progress.percentLabel}. Открыть детали.',
                      button: true,
                      child: GestureDetector(
                        onTap: onTapRoot,
                        child: Column(
                          children: [
                            Text(
                              skill.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: MobileJournalTokens.text(isDark),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Ур. ${skill.level} · ${progress.isEmpty ? "Нет пути" : progress.percentLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: MobileJournalTokens.muted(isDark),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileRoadmapRootNode extends StatelessWidget {
  final Skill skill;
  final String progressLabel;
  final double progressValue;
  final VoidCallback onTap;

  const _MobileRoadmapRootNode({
    required this.skill,
    required this.progressLabel,
    required this.progressValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Навык ${skill.name}, уровень ${skill.level}, прогресс пути $progressLabel. Открыть детали.',
      child: PressFeedback(
        key: ValueKey('mobile-roadmap-root-${skill.id}'),
        scale: 0.95,
        onTap: onTap,
        child: CustomPaint(
          painter: _MobileRoadmapRootRingPainter(
            color: skill.color,
            value: progressValue,
          ),
          child: Center(child: Icon(skill.icon, color: skill.color, size: 34)),
        ),
      ),
    );
  }
}

class _MobileRoadmapStageNode extends StatelessWidget {
  final MobileRoadMapNodeGeometry geometry;
  final Skill skill;
  final VoidCallback onTap;

  const _MobileRoadmapStageNode({
    required this.geometry,
    required this.skill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _stageVisual(geometry.stage, skill);
    return Semantics(
      button: true,
      label:
          '${geometry.stage.node.title}, ${visual.label}, ${geometry.stage.completedLinkedQuests} из ${geometry.stage.questTarget} квестов. Открыть этап.',
      child: PressFeedback(
        key: ValueKey('mobile-ascent-stage-${geometry.stage.node.id}'),
        scale: 0.93,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: visual.color.withAlpha(geometry.stage.isCurrent ? 36 : 12),
            border: Border.all(
              color: visual.color,
              width: geometry.stage.isCurrent ? 3 : 2,
            ),
            boxShadow: geometry.stage.isCurrent
                ? [BoxShadow(color: visual.color.withAlpha(76), blurRadius: 18)]
                : null,
          ),
          child: Icon(visual.icon, color: visual.color, size: 24),
        ),
      ),
    );
  }
}

class _MobileRoadmapStageCard extends StatelessWidget {
  final MobileRoadMapNodeGeometry geometry;
  final Skill skill;
  final bool isDark;
  final VoidCallback onTap;

  const _MobileRoadmapStageCard({
    required this.geometry,
    required this.skill,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _stageVisual(geometry.stage, skill);
    return Semantics(
      button: true,
      label:
          '${geometry.stage.node.title}, ${visual.label}, ${geometry.stage.completedLinkedQuests} из ${geometry.stage.questTarget} квестов. Открыть этап.',
      child: InkWell(
        key: ValueKey('mobile-ascent-card-${geometry.stage.node.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: visual.color.withAlpha(geometry.stage.isCurrent ? 22 : 9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: visual.color.withAlpha(60)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  geometry.stage.node.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: geometry.stage.role == RoadmapStageRole.locked
                        ? MobileJournalTokens.muted(isDark)
                        : MobileJournalTokens.text(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${visual.label} · ${geometry.stage.completedLinkedQuests}/${geometry.stage.questTarget}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: visual.color, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileRoadmapConnectionsPainter extends CustomPainter {
  final MobileRoadMapLayoutResult layout;
  final Skill skill;

  const _MobileRoadmapConnectionsPainter({
    required this.layout,
    required this.skill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in layout.edges) {
      final source = layout.nodes[edge.fromId];
      final destination = layout.nodes[edge.toId];
      final startsAtRoot = edge.fromId == MobileRoadMapLayoutResult.rootId;
      final endsAtRoot = edge.toId == MobileRoadMapLayoutResult.rootId;
      if ((source == null && !startsAtRoot) ||
          (destination == null && !endsAtRoot) ||
          !edge.pointsUpward) {
        continue;
      }
      final sourceRadius = startsAtRoot ? layout.rootRadius : source!.radius;
      final destinationRadius = endsAtRoot
          ? layout.rootRadius
          : destination!.radius;
      final delta = edge.to - edge.from;
      final length = delta.distance;
      if (length < 1) continue;
      final direction = delta / length;
      final start = edge.from + direction * sourceRadius;
      final end = edge.to - direction * destinationRadius;
      final visual = _stageVisual(destination?.stage ?? source!.stage, skill);
      final isCurrentConnection =
          destination?.stage.isCurrent ?? source?.stage.isCurrent ?? false;
      final paint = Paint()
        ..color = visual.color.withAlpha(isCurrentConnection ? 140 : 72)
        ..strokeWidth = isCurrentConnection ? 3 : 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
      final normal = Offset(-direction.dy, direction.dx);
      final wing = 7.0;
      final arrow = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - direction.dx * wing + normal.dx * wing * .58,
          end.dy - direction.dy * wing + normal.dy * wing * .58,
        )
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - direction.dx * wing - normal.dx * wing * .58,
          end.dy - direction.dy * wing - normal.dy * wing * .58,
        );
      canvas.drawPath(arrow, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MobileRoadmapConnectionsPainter oldDelegate) {
    return oldDelegate.layout.paintSignature != layout.paintSignature ||
        oldDelegate.skill.id != skill.id ||
        oldDelegate.skill.color != skill.color;
  }
}

class _MobileRoadmapRootRingPainter extends CustomPainter {
  final Color color;
  final double value;

  const _MobileRoadmapRootRingPainter({
    required this.color,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = color.withAlpha(38);
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _MobileRoadmapRootRingPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.value != value;
  }
}

class _MobileRoadmapHeader extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTemplates;

  const _MobileRoadmapHeader({required this.isDark, this.onTemplates});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151426) : const Color(0xFFF3EFFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF7562FF).withAlpha(isDark ? 65 : 75),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7562FF).withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.map_outlined, color: Color(0xFF7562FF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Дорожная карта',
                  style: TextStyle(
                    color: MobileJournalTokens.text(isDark),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Этапы, связи и путь развития навыка',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MobileJournalTokens.muted(isDark),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (onTemplates != null) ...[
            const SizedBox(width: 8),
            IconButton.outlined(
              key: const ValueKey('mobile-roadmap-templates'),
              tooltip: 'Шаблоны путей',
              onPressed: onTemplates,
              style: IconButton.styleFrom(minimumSize: const Size.square(44)),
              icon: const Icon(Icons.layers_outlined, size: 19),
            ),
          ],
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
                color: MobileJournalTokens.muted(isDark),
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
              color: MobileJournalTokens.surface(isDark),
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
                      color: MobileJournalTokens.text(isDark),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  progress.isEmpty ? 'Нет пути' : progress.percentLabel,
                  style: TextStyle(
                    color: progress.isEmpty
                        ? MobileJournalTokens.muted(isDark)
                        : MobileJournalTokens.readableAccent(
                            skill.color,
                            isDark,
                          ),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: MobileJournalTokens.muted(isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileEmptyPath extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final VoidCallback onAddStage;
  final VoidCallback onTemplates;

  const _MobileEmptyPath({
    super.key,
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
                color: MobileJournalTokens.text(isDark),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Добавь первый этап вручную или выбери готовую структуру.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MobileJournalTokens.muted(isDark),
                fontSize: 12,
              ),
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
      Icons.radio_button_unchecked_rounded,
      skill.color.withAlpha(190),
    ),
    RoadmapStageRole.locked => const _StageVisual(
      'Закрыт',
      Icons.lock_outline_rounded,
      Color(0xFF6F707B),
    ),
  };
}

Duration _roadmapMotionDuration(BuildContext context) => MobileMotion.duration(
  context,
  appReducedMotion: AppStateProvider.maybeOf(context)?.reducedMotion ?? false,
  normal: kMotionSlow,
);
