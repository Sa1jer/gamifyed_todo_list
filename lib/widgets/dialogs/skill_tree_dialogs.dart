part of '../dialogs.dart';

class SkillTreeDialog extends StatefulWidget {
  final AppState state;
  final Skill skill;

  const SkillTreeDialog({super.key, required this.state, required this.skill});

  @override
  State<SkillTreeDialog> createState() => _SkillTreeDialogState();
}

class _SkillTreeDialogState extends State<SkillTreeDialog> {
  String? _selectedNodeId;

  Skill get _skill =>
      widget.state.skills
          .where((item) => item.id == widget.skill.id)
          .firstOrNull ??
      widget.skill;

  SkillTreeNode? _selectedNodeFor(Skill skill) {
    if (skill.treeNodes.isEmpty) return null;
    final selected = skill.treeNodes
        .where((node) => node.id == _selectedNodeId)
        .firstOrNull;
    if (selected != null) return selected;
    return skill.treeNodes
            .where(
              (node) =>
                  skill.treeNodeStatus(node) == SkillTreeNodeStatus.active,
            )
            .firstOrNull ??
        skill.treeNodes.first;
  }

  @override
  Widget build(BuildContext context) {
    final skill = _skill;
    final selectedNode = _selectedNodeFor(skill);
    final isDark = widget.state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 940,
        height: 680,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.account_tree, color: skill.color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Карта мастерства: ${skill.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: txt,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SmallBtn(
                    label: 'Новый этап',
                    icon: Icons.add,
                    color: skill.color,
                    tooltip: 'Создать первый этап карты',
                    onTap: () => _showAddNode(context, skill),
                  ),
                  const SizedBox(width: 10),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть карту мастерства',
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _SkillTreeIntro(isDark: isDark, color: skill.color),
            ),
            Expanded(
              child: MotionFadeSlideSwitcher(
                child: skill.treeNodes.isEmpty
                    ? SkillTreeEmptyState(
                        key: const ValueKey('skill-tree-empty'),
                        isDark: isDark,
                        color: skill.color,
                        onAdd: () => _showAddNode(context, skill),
                      )
                    : Row(
                        key: const ValueKey('skill-tree-canvas'),
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 8, 14),
                              child: _MasteryTreeCanvas(
                                state: widget.state,
                                skill: skill,
                                isDark: isDark,
                                selectedNodeId: selectedNode?.id,
                                onSelect: (node) =>
                                    setState(() => _selectedNodeId = node.id),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 300,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 14, 14),
                              child: SkillTreeNodeInspector(
                                state: widget.state,
                                skill: skill,
                                node: selectedNode,
                                isDark: isDark,
                                onAddChild: selectedNode == null
                                    ? null
                                    : () => _showAddNode(
                                        context,
                                        skill,
                                        parent: selectedNode,
                                      ),
                                onAddQuest: selectedNode == null
                                    ? null
                                    : () => _showAddTaskForNode(
                                        context,
                                        skill,
                                        selectedNode,
                                      ),
                                onMaster: selectedNode == null
                                    ? null
                                    : () => _masterNode(
                                        context,
                                        skill,
                                        selectedNode,
                                      ),
                                onDelete: selectedNode == null
                                    ? null
                                    : () {
                                        widget.state.removeSkillTreeNode(
                                          skill.id,
                                          selectedNode.id,
                                        );
                                        setState(() => _selectedNodeId = null);
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNode(
    BuildContext context,
    Skill skill, {
    SkillTreeNode? parent,
  }) {
    showDialog(
      context: context,
      builder: (_) => AddSkillTreeNodeDialog(
        isDark: widget.state.isDark,
        skill: skill,
        parentNode: parent,
        onSave: (title, description, xpReward, requiredQuestCompletions) {
          widget.state.addSkillTreeNode(
            skill.id,
            SkillTreeNode(
              id: uid(),
              title: title,
              description: description,
              xpReward: xpReward,
              requiredQuestCompletions: requiredQuestCompletions,
              prerequisiteIds: parent == null ? [] : [parent.id],
            ),
          );
          setState(() {
            _selectedNodeId = skill.treeNodes.lastOrNull?.id;
          });
        },
      ),
    );
  }

  void _showAddTaskForNode(
    BuildContext context,
    Skill skill,
    SkillTreeNode node,
  ) {
    showAdaptiveCreationForm<void>(
      context: context,
      builder: (_, fullScreen) => AddTaskDialog(
        isDark: widget.state.isDark,
        fullScreen: fullScreen,
        skillColor: skill.color,
        skill: skill,
        initialTreeNodeId: node.id,
        onSave:
            (
              title,
              description,
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
            ) => widget.state.addTask(
              Task(
                id: uid(),
                title: title,
                description: description,
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
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _masterNode(BuildContext context, Skill skill, SkillTreeNode node) {
    final message = widget.state.masterSkillTreeNode(skill.id, node.id);
    if (message != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
    setState(() {});
  }
}

class _SkillTreeIntro extends StatelessWidget {
  final bool isDark;
  final Color color;

  const _SkillTreeIntro({required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text(
        'Этап навыка = ступень мастерства. Квесты = действия, которые двигают этап. '
        'Освоение этапа = зафиксированный milestone.',
        style: TextStyle(
          color: subtext(isDark),
          fontSize: 12,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MasteryTreeCanvas extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final bool isDark;
  final String? selectedNodeId;
  final ValueChanged<SkillTreeNode> onSelect;

  const _MasteryTreeCanvas({
    required this.state,
    required this.skill,
    required this.isDark,
    required this.selectedNodeId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bdr = borderColor(isDark);
    final bg = isDark ? const Color(0xFF0D0D12) : const Color(0xFFF7F8FC);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _buildMasteryTreeLayout(
            skill,
            Size(constraints.maxWidth, constraints.maxHeight),
          );

          return InteractiveViewer(
            minScale: 0.72,
            maxScale: 1.7,
            boundaryMargin: const EdgeInsets.all(120),
            child: SizedBox(
              width: layout.size.width,
              height: layout.size.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MasteryTreePainter(
                        skill: skill,
                        layout: layout,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  ...skill.treeNodes.map((node) {
                    final position = layout.positions[node.id];
                    if (position == null) return const SizedBox.shrink();
                    return Positioned(
                      left: position.dx - 58,
                      top: position.dy - 54,
                      width: 116,
                      height: 108,
                      child: _MasteryMapNode(
                        state: state,
                        skill: skill,
                        node: node,
                        isDark: isDark,
                        selected: node.id == selectedNodeId,
                        onTap: () => onSelect(node),
                      ),
                    );
                  }),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: _TreeLegend(isDark: isDark, color: skill.color),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  _MasteryTreeLayout _buildMasteryTreeLayout(Skill skill, Size minSize) {
    const horizontalGap = 128.0;
    const verticalGap = 118.0;
    const horizontalPadding = 120.0;
    const verticalPadding = 90.0;
    final nodes = skill.treeNodes;
    final validIds = nodes.map((node) => node.id).toSet();
    final childrenByParent = {
      for (final node in nodes) node.id: <SkillTreeNode>[],
    };
    final roots = <SkillTreeNode>[];

    for (final node in nodes) {
      final parentId = node.prerequisiteIds
          .where((id) => validIds.contains(id))
          .firstOrNull;
      if (parentId == null) {
        roots.add(node);
      } else {
        childrenByParent[parentId]?.add(node);
      }
    }

    var leafIndex = 0;
    var maxDepth = 0;
    final xById = <String, double>{};
    final depthById = <String, int>{};

    double placeNode(SkillTreeNode node, int depth) {
      maxDepth = math.max(maxDepth, depth);
      depthById[node.id] = depth;
      final children = childrenByParent[node.id] ?? const <SkillTreeNode>[];
      if (children.isEmpty) {
        final x = leafIndex * horizontalGap;
        leafIndex++;
        xById[node.id] = x;
        return x;
      }

      final childXs = children.map((child) => placeNode(child, depth + 1));
      final x = childXs.reduce((a, b) => a + b) / children.length;
      xById[node.id] = x;
      return x;
    }

    for (final root in roots) {
      placeNode(root, 0);
    }

    final minX = xById.values.isEmpty ? 0.0 : xById.values.reduce(math.min);
    final maxX = xById.values.isEmpty ? 0.0 : xById.values.reduce(math.max);
    final contentWidth = math.max(
      minSize.width,
      (maxX - minX) + horizontalPadding * 2,
    );
    final contentHeight = math.max(
      minSize.height,
      (maxDepth + 1) * verticalGap + verticalPadding * 2,
    );
    final xOffset = xById.length == 1
        ? contentWidth / 2
        : (contentWidth - (maxX - minX)) / 2 - minX;

    final positions = <String, Offset>{};
    for (final node in nodes) {
      final depth = depthById[node.id] ?? 0;
      final x = (xById[node.id] ?? 0) + xOffset;
      final y = contentHeight - verticalPadding - depth * verticalGap;
      positions[node.id] = Offset(x, y);
    }

    return _MasteryTreeLayout(
      size: Size(contentWidth, contentHeight),
      positions: positions,
    );
  }
}

class _MasteryTreeLayout {
  final Size size;
  final Map<String, Offset> positions;

  const _MasteryTreeLayout({required this.size, required this.positions});
}

class _MasteryTreePainter extends CustomPainter {
  final Skill skill;
  final _MasteryTreeLayout layout;
  final bool isDark;

  const _MasteryTreePainter({
    required this.skill,
    required this.layout,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(10)
      ..style = PaintingStyle.fill;
    for (var x = 24.0; x < size.width; x += 42) {
      for (var y = 24.0; y < size.height; y += 42) {
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }

    for (final node in skill.treeNodes) {
      final childPosition = layout.positions[node.id];
      final parentId = node.prerequisiteIds
          .where((id) => layout.positions.containsKey(id))
          .firstOrNull;
      final parentPosition = parentId == null
          ? null
          : layout.positions[parentId];
      if (childPosition == null || parentPosition == null) continue;

      final status = skill.treeNodeStatus(node);
      final color = skillTreeNodeStatusColor[status]!;
      final paint = Paint()
        ..color = color.withAlpha(
          status == SkillTreeNodeStatus.locked ? 75 : 170,
        )
        ..strokeWidth = status == SkillTreeNodeStatus.locked ? 2 : 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final middleY = (parentPosition.dy + childPosition.dy) / 2;
      final path = Path()
        ..moveTo(parentPosition.dx, parentPosition.dy - 34)
        ..cubicTo(
          parentPosition.dx,
          middleY,
          childPosition.dx,
          middleY,
          childPosition.dx,
          childPosition.dy + 34,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MasteryTreePainter oldDelegate) {
    return oldDelegate.skill != skill ||
        oldDelegate.layout != layout ||
        oldDelegate.isDark != isDark;
  }
}

class _MasteryMapNode extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final SkillTreeNode node;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  const _MasteryMapNode({
    required this.state,
    required this.skill,
    required this.node,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = skill.treeNodeStatus(node);
    final statusColor = skillTreeNodeStatusColor[status]!;
    final completed = state.completedTasksForTreeNode(skill.id, node.id);
    final target = node.questTarget;
    final diameter = switch (target) {
      <= 1 => 54.0,
      <= 3 => 62.0,
      _ => 70.0,
    };
    final nodeFill = isDark ? const Color(0xFF151923) : Colors.white;
    final icon = switch (status) {
      SkillTreeNodeStatus.locked => Icons.lock,
      SkillTreeNodeStatus.active => Icons.bolt_rounded,
      SkillTreeNodeStatus.mastered => Icons.workspace_premium,
    };

    return PressFeedback(
      scale: 0.94,
      tooltip: node.title,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: kMotionStandard,
            curve: kMotionCurve,
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status == SkillTreeNodeStatus.locked
                  ? nodeFill.withAlpha(isDark ? 150 : 210)
                  : statusColor.withAlpha(isDark ? 32 : 24),
              border: Border.all(
                color: selected ? Colors.white : statusColor,
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                if (selected || status == SkillTreeNodeStatus.active)
                  BoxShadow(
                    color: statusColor.withAlpha(selected ? 90 : 45),
                    blurRadius: selected ? 24 : 16,
                    spreadRadius: selected ? 1 : 0,
                  ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, color: statusColor, size: diameter * 0.42),
                Positioned(
                  bottom: -9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D0D12)
                          : const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      '${math.min(completed, target)}/$target',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Text(
            node.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: status == SkillTreeNodeStatus.locked
                  ? subtext(isDark)
                  : textColor(isDark),
              fontSize: 11,
              height: 1.05,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TreeLegend extends StatelessWidget {
  final bool isDark;
  final Color color;

  const _TreeLegend({required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface(isDark).withAlpha(isDark ? 220 : 235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(label: 'закрыто', color: const Color(0xFF8E8E93)),
          const SizedBox(width: 10),
          _LegendDot(label: 'активно', color: color),
          const SizedBox(width: 10),
          const _LegendDot(label: 'освоено', color: Color(0xFF34C759)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
