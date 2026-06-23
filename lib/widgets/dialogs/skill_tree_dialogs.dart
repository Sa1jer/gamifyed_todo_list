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
                    ? _SkillTreeEmptyState(
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
                              child: _MasteryNodeInspector(
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
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        isDark: widget.state.isDark,
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
    ).then((_) => setState(() {}));
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

class _MasteryNodeInspector extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final SkillTreeNode? node;
  final bool isDark;
  final VoidCallback? onAddChild;
  final VoidCallback? onAddQuest;
  final VoidCallback? onMaster;
  final VoidCallback? onDelete;

  const _MasteryNodeInspector({
    required this.state,
    required this.skill,
    required this.node,
    required this.isDark,
    required this.onAddChild,
    required this.onAddQuest,
    required this.onMaster,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final selectedNode = node;
    final bdr = borderColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111118) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      padding: const EdgeInsets.all(14),
      child: selectedNode == null
          ? _EmptyNodeInspector(
              isDark: isDark,
              color: skill.color,
              onAddRoot: onAddChild,
            )
          : _SelectedNodeInspector(
              state: state,
              skill: skill,
              node: selectedNode,
              isDark: isDark,
              onAddChild: onAddChild,
              onAddQuest: onAddQuest,
              onMaster: onMaster,
              onDelete: onDelete,
            ),
    );
  }
}

class _EmptyNodeInspector extends StatelessWidget {
  final bool isDark;
  final Color color;
  final VoidCallback? onAddRoot;

  const _EmptyNodeInspector({
    required this.isDark,
    required this.color,
    required this.onAddRoot,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.account_tree_outlined, color: color, size: 30),
        const SizedBox(height: 12),
        Text(
          'Выберите этап',
          style: TextStyle(
            color: textColor(isDark),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Этап — это ступень навыка. Создавайте квесты для этапа, выполняйте их и фиксируйте освоение.',
          style: TextStyle(
            color: subtext(isDark),
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
        const Spacer(),
        SmallBtn(
          label: 'Первый этап',
          icon: Icons.add,
          color: color,
          onTap: onAddRoot ?? () {},
        ),
      ],
    );
  }
}

class _SelectedNodeInspector extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final SkillTreeNode node;
  final bool isDark;
  final VoidCallback? onAddChild;
  final VoidCallback? onAddQuest;
  final VoidCallback? onMaster;
  final VoidCallback? onDelete;

  const _SelectedNodeInspector({
    required this.state,
    required this.skill,
    required this.node,
    required this.isDark,
    required this.onAddChild,
    required this.onAddQuest,
    required this.onMaster,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final status = skill.treeNodeStatus(node);
    final statusColor = skillTreeNodeStatusColor[status]!;
    final linkedTasks = state.tasksForTreeNode(skill.id, node.id);
    final completed = state.completedTasksForTreeNode(skill.id, node.id);
    final target = node.questTarget;
    final ready = state.canMasterSkillTreeNode(skill.id, node.id);
    final parent = node.prerequisiteIds
        .map(
          (id) => skill.treeNodes
              .where((candidate) => candidate.id == id)
              .firstOrNull,
        )
        .whereType<SkillTreeNode>()
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(28),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor.withAlpha(120)),
              ),
              child: Icon(_statusIcon(status), color: statusColor, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: txt,
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TaskBadge(
                    label: skillTreeNodeStatusLabel[status]!,
                    color: statusColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (node.description.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            node.description,
            style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
          ),
        ],
        const SizedBox(height: 14),
        _NodeProgressPanel(
          isDark: isDark,
          color: statusColor,
          completed: completed,
          target: target,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            TaskBadge(
              icon: Icons.auto_awesome,
              label: '+${node.xpReward} XP',
              color: const Color(0xFFFFCC00),
            ),
            if (parent != null)
              TaskBadge(
                icon: Icons.lock_open,
                label: 'после: ${parent.title}',
                color: const Color(0xFF8E8E93),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Квесты этапа',
          style: TextStyle(
            color: txt,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: linkedTasks.isEmpty
              ? Center(
                  child: Text(
                    'Пока нет квестов.\nСоздайте квест, чтобы двинуть этап.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: linkedTasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (_, index) => _InspectorQuestRow(
                    task: linkedTasks[index],
                    isDark: isDark,
                    color: skill.color,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SmallBtn(
              label: 'Квест',
              icon: Icons.add_task,
              color: const Color(0xFF4A9EFF),
              onTap: onAddQuest ?? () {},
            ),
            SmallBtn(
              label: 'Следующий этап',
              icon: Icons.account_tree,
              color: skill.color,
              onTap: onAddChild ?? () {},
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MasterNodeButton(
                enabled: ready,
                mastered: node.isMastered,
                color: skill.color,
                onTap: onMaster ?? () {},
              ),
            ),
            const SizedBox(width: 10),
            PressFeedback(
              scale: 0.94,
              tooltip: 'Удалить этап',
              onTap: onDelete ?? () {},
              child: Icon(Icons.delete_outline, color: sub, size: 21),
            ),
          ],
        ),
      ],
    );
  }

  IconData _statusIcon(SkillTreeNodeStatus status) {
    return switch (status) {
      SkillTreeNodeStatus.locked => Icons.lock,
      SkillTreeNodeStatus.active => Icons.bolt_rounded,
      SkillTreeNodeStatus.mastered => Icons.workspace_premium,
    };
  }
}

class _NodeProgressPanel extends StatelessWidget {
  final bool isDark;
  final Color color;
  final int completed;
  final int target;

  const _NodeProgressPanel({
    required this.isDark,
    required this.color,
    required this.completed,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = math.min(completed, target);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Прогресс освоения',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$clamped/$target',
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
            progress: target == 0 ? 0 : (clamped / target).clamp(0.0, 1.0),
            color: color,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _InspectorQuestRow extends StatelessWidget {
  final Task task;
  final bool isDark;
  final Color color;

  const _InspectorQuestRow({
    required this.task,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        children: [
          Icon(
            task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isDone ? const Color(0xFF34C759) : color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: task.isDone ? sub : textColor(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                decoration: task.isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterNodeButton extends StatelessWidget {
  final bool enabled;
  final bool mastered;
  final Color color;
  final VoidCallback onTap;

  const _MasterNodeButton({
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
        label: 'Готово',
        color: const Color(0xFF34C759),
      );
    }

    final button = AnimatedOpacity(
      duration: kMotionStandard,
      curve: kMotionCurve,
      opacity: enabled ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Освоить',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    if (!enabled) return button;

    return PressFeedback(
      scale: 0.96,
      tooltip: 'Освоить этап карты мастерства',
      onTap: onTap,
      child: button,
    );
  }
}

class _SkillTreeEmptyState extends StatelessWidget {
  final bool isDark;
  final Color color;
  final VoidCallback onAdd;

  const _SkillTreeEmptyState({
    super.key,
    required this.isDark,
    required this.color,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined, color: sub, size: 42),
          const SizedBox(height: 12),
          Text(
            'Карта мастерства пока пустая',
            style: TextStyle(color: sub, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Начните с этапов: “Основы”, “Практика”, “Первый проект”.',
            style: TextStyle(color: sub.withAlpha(170), fontSize: 12),
          ),
          const SizedBox(height: 14),
          SmallBtn(
            label: 'Добавить этап',
            icon: Icons.add,
            color: color,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class AddSkillTreeNodeDialog extends StatefulWidget {
  final bool isDark;
  final Skill skill;
  final SkillTreeNode? parentNode;
  final Function(
    String title,
    String description,
    int xpReward,
    int requiredQuestCompletions,
  )
  onSave;

  const AddSkillTreeNodeDialog({
    super.key,
    required this.isDark,
    required this.skill,
    this.parentNode,
    required this.onSave,
  });

  @override
  State<AddSkillTreeNodeDialog> createState() => _AddSkillTreeNodeDialogState();
}

class _AddSkillTreeNodeDialogState extends State<AddSkillTreeNodeDialog> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  int _xpReward = 30;
  int _requiredQuestCompletions = 3;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = surface(isDark);
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final color = widget.skill.color;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DlgHeader(title: 'Новый этап карты', txtColor: txt),
              const SizedBox(height: 16),
              if (widget.parentNode != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withAlpha(45)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_tree, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Откроется после: ${widget.parentNode!.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: txt,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              DlgField(
                label: 'Название этапа',
                ctrl: _titleCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
              ),
              const SizedBox(height: 12),
              DlgField(
                label: 'Описание',
                ctrl: _descriptionCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
                min: 2,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SubLbl('XP за освоение', sub),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.96,
                    tooltip: 'Ввести XP числом',
                    onTap: () async {
                      final value = await showIntegerEditDialog(
                        context,
                        title: 'XP за освоение',
                        initialValue: _xpReward,
                        min: 10,
                        max: 200,
                        color: color,
                        isDark: isDark,
                        suffix: 'XP',
                      );
                      if (value != null && mounted) {
                        setState(() => _xpReward = value);
                      }
                    },
                    child: TaskBadge(
                      icon: Icons.auto_awesome,
                      label: '$_xpReward XP',
                      color: color,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _xpReward.toDouble(),
                min: 10,
                max: 200,
                divisions: 19,
                activeColor: color,
                inactiveColor: color.withAlpha(40),
                onChanged: (value) => setState(() => _xpReward = value.round()),
              ),
              Row(
                children: [
                  SubLbl('Размер этапа', sub),
                  const Spacer(),
                  TaskBadge(
                    icon: Icons.flag,
                    label: '$_requiredQuestCompletions квест.',
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _nodeSizeChip(
                    label: 'Малый',
                    value: 1,
                    color: color,
                    isDark: isDark,
                    sub: sub,
                    bdr: bdr,
                  ),
                  _nodeSizeChip(
                    label: 'Обычный',
                    value: 3,
                    color: color,
                    isDark: isDark,
                    sub: sub,
                    bdr: bdr,
                  ),
                  _nodeSizeChip(
                    label: 'Большой',
                    value: 5,
                    color: color,
                    isDark: isDark,
                    sub: sub,
                    bdr: bdr,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Размер определяет, сколько связанных квестов нужно завершить перед освоением этапа.',
                style: TextStyle(
                  color: sub,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              DlgActions(onCancel: () => Navigator.pop(context), onSave: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nodeSizeChip({
    required String label,
    required int value,
    required Color color,
    required bool isDark,
    required Color sub,
    required Color bdr,
  }) {
    return _DialogChoiceChip(
      label: '$label · $value',
      color: color,
      selected: _requiredQuestCompletions == value,
      backgroundColor: isDark
          ? const Color(0xFF23232D)
          : const Color(0xFFF0F0F5),
      borderColor: bdr,
      inactiveTextColor: sub,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      radius: 999,
      selectedWeight: FontWeight.w800,
      onTap: () => setState(() => _requiredQuestCompletions = value),
    );
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onSave(
      title,
      _descriptionCtrl.text.trim(),
      _xpReward,
      _requiredQuestCompletions,
    );
    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADD TASK DIALOG  (unchanged from uploaded version)
// ═══════════════════════════════════════════════════════════════════════════════
