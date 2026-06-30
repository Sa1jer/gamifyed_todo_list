part of '../mastery_map_workspace.dart';

class _OrbMasteryMapCanvas extends StatefulWidget {
  final AppState state;
  final bool isDark;
  final _MasterySelection? selection;
  final ValueChanged<Skill> onSelectSkill;
  final VoidCallback onCollapse;
  final void Function(Skill skill, RoadmapTemplateConfig config)
  onApplyRoadmapTemplate;
  final void Function(
    Skill skill,
    SkillTreeNode leftNode,
    SkillTreeNode rightNode,
  )
  onInsertStageAfter;
  final void Function(Skill skill, SkillTreeNode node) onSelectNode;

  const _OrbMasteryMapCanvas({
    super.key,
    required this.state,
    required this.isDark,
    required this.selection,
    required this.onSelectSkill,
    required this.onCollapse,
    required this.onApplyRoadmapTemplate,
    required this.onInsertStageAfter,
    required this.onSelectNode,
  });

  @override
  State<_OrbMasteryMapCanvas> createState() => _OrbMasteryMapCanvasState();
}

class _OrbMasteryMapCanvasState extends State<_OrbMasteryMapCanvas>
    with SingleTickerProviderStateMixin {
  static const _roadmapCameraMinScale = 0.04;

  bool _templatePanelHidden = true;
  final TransformationController _roadmapCameraController =
      TransformationController();
  late final AnimationController _roadmapCameraAnimationController =
      AnimationController(vsync: this, duration: kMotionSlow)
        ..addListener(_handleRoadmapCameraTick);
  Matrix4Tween? _roadmapCameraTween;
  String? _lastRoadmapCameraSignature;

  @override
  void dispose() {
    _roadmapCameraAnimationController
      ..removeListener(_handleRoadmapCameraTick)
      ..dispose();
    _roadmapCameraController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _OrbMasteryMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selection?.skillId != oldWidget.selection?.skillId) {
      _templatePanelHidden = true;
    }
  }

  void _handleRoadmapCameraTick() {
    final tween = _roadmapCameraTween;
    if (tween == null) return;
    final value = kMotionCurve.transform(
      _roadmapCameraAnimationController.value,
    );
    _roadmapCameraController.value = tween.transform(value);
  }

  void _scheduleRoadmapCameraFit(
    _OrbCanvasLayout layout,
    Size viewport,
    bool templatePanelCollapsed,
  ) {
    final signature = _roadmapCameraSignature(
      layout,
      viewport,
      templatePanelCollapsed,
    );
    if (signature == _lastRoadmapCameraSignature) return;
    _lastRoadmapCameraSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _roadmapFitMatrix(
        layout,
        viewport,
        templatePanelCollapsed,
      );
      _animateRoadmapCameraTo(target);
    });
  }

  String _roadmapCameraSignature(
    _OrbCanvasLayout layout,
    Size viewport,
    bool templatePanelCollapsed,
  ) {
    final selectedSkill = layout.selectedSkill;
    if (selectedSkill == null) {
      final skillShape = layout.skillPositions.keys
          .map((skill) => skill.id)
          .join(',');
      return [
        'overview',
        viewport.width.round(),
        viewport.height.round(),
        layout.size.width.round(),
        layout.size.height.round(),
        skillShape,
      ].join(':');
    }
    final pathShape = layout.pathLayout.paths
        .map((path) => path.nodes.map((node) => node.id).join(','))
        .join('|');
    return [
      selectedSkill.id,
      viewport.width.round(),
      viewport.height.round(),
      layout.size.width.round(),
      layout.size.height.round(),
      templatePanelCollapsed ? 'panel-collapsed' : 'panel-open',
      selectedSkill.goal.trim().isEmpty ? 'no-goal' : 'goal',
      pathShape,
      layout.pathInsertionPoints.length,
    ].join(':');
  }

  void _animateRoadmapCameraTo(Matrix4 target) {
    final current = _roadmapCameraController.value;
    if (_matrixCloseTo(current, target)) {
      _roadmapCameraAnimationController.stop();
      _roadmapCameraController.value = target;
      return;
    }
    _roadmapCameraTween = Matrix4Tween(
      begin: Matrix4.copy(current),
      end: target,
    );
    _roadmapCameraAnimationController
      ..stop()
      ..reset()
      ..forward();
  }

  void _centerRoadmapOverviewCamera(_OrbCanvasLayout layout, Size viewport) {
    _animateRoadmapCameraTo(_roadmapFitMatrix(layout, viewport, true));
  }

  bool _matrixCloseTo(Matrix4 a, Matrix4 b) {
    for (var index = 0; index < 16; index++) {
      if ((a.storage[index] - b.storage[index]).abs() > 0.35) {
        return false;
      }
    }
    return true;
  }

  Matrix4 _roadmapFitMatrix(
    _OrbCanvasLayout layout,
    Size viewport,
    bool templatePanelCollapsed,
  ) {
    final bounds = _roadmapContentBounds(layout);
    final selectedSkill = layout.selectedSkill;
    final hasStages = layout.selectedSkill?.treeNodes.isNotEmpty ?? false;
    final target = selectedSkill == null
        ? _roadmapOverviewTargetViewport(viewport)
        : _roadmapTargetViewport(
            viewport,
            hasStages ? templatePanelCollapsed : true,
          );
    final scaleX = target.width / bounds.width;
    final scaleY = target.height / bounds.height;
    final scale = math
        .min(1.0, math.min(scaleX, scaleY))
        .clamp(_roadmapCameraMinScale, 1.0)
        .toDouble();
    final dx = selectedSkill != null && hasStages
        ? target.right - bounds.right * scale
        : target.center.dx - bounds.center.dx * scale;
    final dy = target.center.dy - bounds.center.dy * scale;
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  Rect _roadmapOverviewTargetViewport(Size viewport) {
    const padding = 28.0;
    return Rect.fromLTRB(
      padding,
      padding,
      math.max(padding, viewport.width - padding),
      math.max(padding, viewport.height - padding),
    );
  }

  Rect _roadmapTargetViewport(Size viewport, bool templatePanelCollapsed) {
    final isNarrow = viewport.width < 760;
    final left = !isNarrow && !templatePanelCollapsed ? 284.0 : 28.0;
    final top = 86.0;
    final right = math.max(left + 160, viewport.width - 44);
    final bottomPadding = isNarrow && !templatePanelCollapsed ? 238.0 : 48.0;
    final bottom = math.max(top + 160, viewport.height - bottomPadding);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect _roadmapContentBounds(_OrbCanvasLayout layout) {
    final selectedSkill = layout.selectedSkill;
    if (selectedSkill == null) {
      var overviewBounds = Rect.zero;
      var hasOverviewBounds = false;
      for (final position in layout.skillPositions.values) {
        final orbBounds = Rect.fromCenter(
          center: position,
          width: 216,
          height: 170,
        );
        overviewBounds = hasOverviewBounds
            ? overviewBounds.expandToInclude(orbBounds)
            : orbBounds;
        hasOverviewBounds = true;
      }
      return (hasOverviewBounds ? overviewBounds : (Offset.zero & layout.size))
          .inflate(28);
    }
    final selectedCenter = layout.skillPositions[selectedSkill];
    var bounds = Rect.zero;
    var hasBounds = false;

    void include(Rect rect) {
      bounds = hasBounds ? bounds.expandToInclude(rect) : rect;
      hasBounds = true;
    }

    if (selectedCenter != null) {
      include(Rect.fromCenter(center: selectedCenter, width: 284, height: 264));
      if (selectedSkill.goal.trim().isNotEmpty) {
        final goalWidth = _roadmapGoalAnchorWidth(selectedSkill.goal);
        include(
          Rect.fromCenter(
            center:
                selectedCenter +
                const Offset(
                  0,
                  -_roadmapGoalAnchorTopOffset +
                      _roadmapGoalAnchorEstimatedHeight / 2,
                ),
            width: goalWidth,
            height: _roadmapGoalAnchorEstimatedHeight,
          ),
        );
      }
    }
    for (final position in layout.nodePositions.values) {
      include(Rect.fromCenter(center: position, width: 202, height: 182));
    }
    for (final point in layout.pathInsertionPoints) {
      include(Rect.fromCircle(center: point.position, radius: 30));
    }

    return (hasBounds ? bounds : (Offset.zero & layout.size)).inflate(38);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDark = widget.isDark;
    final selection = widget.selection;
    final baseBg = isDark ? const Color(0xFF0D0D12) : const Color(0xFFF7F8FC);
    final bg = Color.lerp(baseBg, Colors.black, 0.75)!;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor(isDark)),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _buildOrbLayout(
            state,
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          final selectedSkill = layout.selectedSkill;
          final templatePanelCollapsed =
              _templatePanelHidden ||
              selection?.type != _MasterySelectionType.skill;
          _scheduleRoadmapCameraFit(
            layout,
            Size(constraints.maxWidth, constraints.maxHeight),
            templatePanelCollapsed,
          );

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MasteryVectorGridPainter(isDark: isDark),
                ),
              ),
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _roadmapCameraController,
                  minScale: _roadmapCameraMinScale,
                  maxScale: 1.85,
                  boundaryMargin: const EdgeInsets.all(3000),
                  constrained: false,
                  child: SizedBox(
                    width: layout.size.width,
                    height: layout.size.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _OrbMasteryMapPainter(
                              layout: layout,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        ...layout.skillPositions.entries.map((entry) {
                          final skill = entry.key;
                          final position = entry.value;
                          final selected = selection?.skillId == skill.id;
                          final roadFocus =
                              selectedSkill != null &&
                              selectedSkill.id == skill.id;
                          final hiddenInFocus =
                              selectedSkill != null && !roadFocus;
                          final orbDiameter = roadFocus
                              ? 149.0
                              : selected
                              ? 98.0
                              : 89.0;
                          return AnimatedPositioned(
                            key: ValueKey('map-skill-orb-${skill.id}'),
                            duration: kMotionSlow,
                            curve: kMotionCurve,
                            left: position.dx - (roadFocus ? 132 : 108),
                            top: position.dy - orbDiameter / 2,
                            width: roadFocus ? 264 : 216,
                            height: orbDiameter + 55,
                            child: _SkillOrbButton(
                              skill: skill,
                              isDark: isDark,
                              selected: selected,
                              roadFocus: roadFocus,
                              hiddenInFocus: hiddenInFocus,
                              dimmed: selectedSkill != null && !selected,
                              onTap: () => widget.onSelectSkill(skill),
                            ),
                          );
                        }),
                        if (selectedSkill != null)
                          ...selectedSkill.treeNodes.map((node) {
                            final position = layout.nodePositions[node.id];
                            if (position == null) {
                              return const SizedBox.shrink();
                            }
                            return AnimatedPositioned(
                              key: ValueKey(
                                'map-node-${selectedSkill.id}-${node.id}',
                              ),
                              duration: kMotionSlow,
                              curve: kMotionCurve,
                              left: position.dx - 77,
                              top: position.dy - 50,
                              width: 154,
                              height: 151,
                              child: AnimatedSwitcher(
                                duration: kMotionSlow,
                                switchInCurve: kMotionCurve,
                                switchOutCurve: kMotionExitCurve,
                                child: _MapNodeButton(
                                  key: ValueKey(
                                    'node-button-${selectedSkill.id}-${node.id}',
                                  ),
                                  state: state,
                                  skill: selectedSkill,
                                  node: node,
                                  isDark: isDark,
                                  selected:
                                      selection?.nodeId == node.id &&
                                      selection?.type !=
                                          _MasterySelectionType.skill,
                                  onTap: () =>
                                      widget.onSelectNode(selectedSkill, node),
                                ),
                              ),
                            );
                          }),
                        if (selectedSkill != null)
                          ...layout.pathInsertionPoints.map((point) {
                            final leftNode = selectedSkill.treeNodes
                                .where((node) => node.id == point.leftNodeId)
                                .firstOrNull;
                            final rightNode = selectedSkill.treeNodes
                                .where((node) => node.id == point.rightNodeId)
                                .firstOrNull;
                            if (leftNode == null || rightNode == null) {
                              return const SizedBox.shrink();
                            }
                            final position = point.position;
                            return AnimatedPositioned(
                              key: ValueKey(
                                'roadmap-insert-${selectedSkill.id}-${leftNode.id}-${rightNode.id}',
                              ),
                              duration: kMotionSlow,
                              curve: kMotionCurve,
                              left: position.dx - 23,
                              top: position.dy - 23,
                              width: 46,
                              height: 46,
                              child: _RoadmapInsertStageButton(
                                isDark: isDark,
                                color: selectedSkill.color,
                                onTap: () => widget.onInsertStageAfter(
                                  selectedSkill,
                                  leftNode,
                                  rightNode,
                                ),
                              ),
                            );
                          }),
                        if (selectedSkill != null &&
                            selectedSkill.goal.trim().isNotEmpty)
                          Builder(
                            builder: (_) {
                              final center =
                                  layout.skillPositions[selectedSkill] ??
                                  Offset.zero;
                              final width = _roadmapGoalAnchorWidth(
                                selectedSkill.goal,
                              );
                              return Positioned(
                                left: center.dx - width / 2,
                                top: center.dy - _roadmapGoalAnchorTopOffset,
                                width: width,
                                child: _RoadmapGoalAnchor(
                                  skill: selectedSkill,
                                  isDark: isDark,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (selectedSkill == null)
                Positioned(
                  left: 14,
                  top: 14,
                  width: 214,
                  child: _SelectSkillHint(isDark: isDark),
                ),
              if (selectedSkill == null)
                Positioned(
                  right: 14,
                  top: 14,
                  child: _MapCanvasAction(
                    isDark: isDark,
                    label: 'Отцентровать',
                    icon: Icons.center_focus_strong,
                    onTap: () => _centerRoadmapOverviewCamera(
                      layout,
                      Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  ),
                ),
              if (selectedSkill != null)
                Positioned(
                  right: 14,
                  top: 14,
                  child: _MapCanvasAction(
                    isDark: isDark,
                    label: 'Назад к навыкам',
                    icon: Icons.keyboard_return,
                    onTap: widget.onCollapse,
                  ),
                ),
              if (selectedSkill != null)
                Positioned(
                  left: 14,
                  top: constraints.maxWidth < 760 ? null : 14,
                  bottom: constraints.maxWidth < 760 ? 14 : null,
                  width: constraints.maxWidth < 760
                      ? math.min(constraints.maxWidth - 28, 276)
                      : 235,
                  child: AnimatedSwitcher(
                    duration: kMotionSlow,
                    switchInCurve: kMotionCurve,
                    switchOutCurve: kMotionExitCurve,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topLeft,
                        clipBehavior: Clip.none,
                        children: [...previousChildren, ?currentChild],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      final scale = Tween<double>(
                        begin: 0.96,
                        end: 1,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: scale,
                          alignment: Alignment.topLeft,
                          child: child,
                        ),
                      );
                    },
                    child: templatePanelCollapsed
                        ? Align(
                            key: const ValueKey('roadmap-template-show'),
                            alignment: Alignment.centerLeft,
                            child: _MapCanvasAction(
                              isDark: isDark,
                              label: 'Шаблоны',
                              icon: Icons.route,
                              color: selectedSkill.color,
                              onTap: () {
                                setState(() => _templatePanelHidden = false);
                                if (selection?.type !=
                                    _MasterySelectionType.skill) {
                                  widget.onSelectSkill(selectedSkill);
                                }
                              },
                            ),
                          )
                        : _RoadmapTemplatePanel(
                            key: const ValueKey('roadmap-template-panel'),
                            skill: selectedSkill,
                            isDark: isDark,
                            onHide: () =>
                                setState(() => _templatePanelHidden = true),
                            onApply: (config) => widget.onApplyRoadmapTemplate(
                              selectedSkill,
                              config,
                            ),
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  _OrbCanvasLayout _buildOrbLayout(AppState state, Size minSize) {
    final selectedSkill = widget.selection == null
        ? null
        : state.roadmapSkills
              .where((skill) => skill.id == widget.selection!.skillId)
              .firstOrNull;
    final pathLayout = selectedSkill == null
        ? const RoadmapPathLayout(paths: [])
        : _roadmapEngine.buildPathLayout(selectedSkill);
    final pathCount = math.max(1, pathLayout.paths.length);
    final maxStagesInPath = math.max(1, pathLayout.maxStagesInPath);
    final stageCount = selectedSkill?.treeNodes.length ?? 0;
    const stageStep = 170.0;
    const terminalGap = 208.0;
    final focusLeftSafe = minSize.width < 760 ? 88.0 : 338.0;
    final visualSpan = stageCount == 0
        ? 0.0
        : terminalGap + (maxStagesInPath - 1) * stageStep;
    final roadWidth = focusLeftSafe + visualSpan + 360.0;
    final roadHeight = 250.0 + pathCount * 132.0;
    final double width = math
        .max(
          minSize.width,
          selectedSkill == null ? 720 : math.max(1060.0, roadWidth),
        )
        .toDouble();
    final double height = math
        .max(
          minSize.height,
          selectedSkill == null ? 620 : math.max(680.0, roadHeight),
        )
        .toDouble();
    final center = Offset(width / 2, height / 2);
    final selectedCenter = selectedSkill == null
        ? null
        : _roadmapSkillCenter(Size(width, height), focusLeftSafe, visualSpan);
    final skillPositions = <Skill, Offset>{};

    final skills = state.roadmapSkills;
    for (var index = 0; index < skills.length; index++) {
      final skill = skills[index];
      skillPositions[skill] =
          selectedSkill != null &&
              selectedCenter != null &&
              skill.id == selectedSkill.id
          ? selectedCenter
          : _clusterSkillOrbPosition(center, index, skills.length);
    }

    final nodePositions = selectedSkill == null || selectedCenter == null
        ? <String, Offset>{}
        : _placeRoadmapNodes(pathLayout, selectedCenter);
    final pathInsertionPoints = selectedSkill == null || selectedCenter == null
        ? const <_RoadmapInsertionPoint>[]
        : _placeRoadmapInsertionActions(pathLayout, nodePositions);

    return _OrbCanvasLayout(
      size: Size(width, height),
      center: center,
      selectedSkill: selectedSkill,
      pathLayout: pathLayout,
      skillPositions: skillPositions,
      nodePositions: nodePositions,
      pathInsertionPoints: pathInsertionPoints,
    );
  }

  Offset _roadmapSkillCenter(
    Size size,
    double focusLeftSafe,
    double visualSpan,
  ) {
    final workRight = size.width - 188.0;
    final workCenter = Offset((focusLeftSafe + workRight) / 2, size.height / 2);
    if (visualSpan <= 0) return workCenter;
    final skillX = (workCenter.dx + visualSpan / 2).clamp(
      focusLeftSafe + visualSpan + 112.0,
      workRight,
    );
    return Offset(skillX.toDouble(), workCenter.dy);
  }

  Offset _clusterSkillOrbPosition(Offset center, int index, int count) {
    if (index == 0) return center;
    var remaining = index - 1;
    var ring = 0;
    var capacity = 6;
    while (remaining >= capacity) {
      remaining -= capacity;
      ring++;
      capacity += 6;
    }
    final radius = 150.0 + ring * 128.0;
    final angle =
        (remaining / capacity) * math.pi * 2 +
        (count.isEven ? math.pi / capacity : 0) -
        math.pi / 2;
    return center + Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  Map<String, Offset> _placeRoadmapNodes(
    RoadmapPathLayout pathLayout,
    Offset skillCenter,
  ) {
    if (pathLayout.paths.isEmpty) return {};
    final positions = <String, Offset>{};
    final pathCount = pathLayout.paths.length;
    const terminalGap = 208.0;
    const stageStep = 170.0;
    const pathStep = 132.0;
    for (var pathIndex = 0; pathIndex < pathLayout.paths.length; pathIndex++) {
      final path = pathLayout.paths[pathIndex];
      final y = skillCenter.dy + (pathIndex - (pathCount - 1) / 2) * pathStep;
      for (var stageIndex = 0; stageIndex < path.nodes.length; stageIndex++) {
        final node = path.nodes[stageIndex];
        final x =
            skillCenter.dx -
            terminalGap -
            (path.nodes.length - 1 - stageIndex) * stageStep;
        positions.putIfAbsent(node.id, () => Offset(x, y));
      }
    }
    return positions;
  }

  List<_RoadmapInsertionPoint> _placeRoadmapInsertionActions(
    RoadmapPathLayout pathLayout,
    Map<String, Offset> nodePositions,
  ) {
    final points = <_RoadmapInsertionPoint>[];
    for (final path in pathLayout.paths) {
      for (var index = 0; index < path.nodes.length - 1; index++) {
        final leftNode = path.nodes[index];
        final rightNode = path.nodes[index + 1];
        final leftPosition = nodePositions[leftNode.id];
        final rightPosition = nodePositions[rightNode.id];
        if (leftPosition == null || rightPosition == null) continue;
        points.add(
          _RoadmapInsertionPoint(
            leftNodeId: leftNode.id,
            rightNodeId: rightNode.id,
            position: Offset.lerp(leftPosition, rightPosition, 0.5)!,
          ),
        );
      }
    }
    return points;
  }
}

class _RoadmapInsertionPoint {
  final String leftNodeId;
  final String rightNodeId;
  final Offset position;

  const _RoadmapInsertionPoint({
    required this.leftNodeId,
    required this.rightNodeId,
    required this.position,
  });
}

class _OrbCanvasLayout {
  final Size size;
  final Offset center;
  final Skill? selectedSkill;
  final RoadmapPathLayout pathLayout;
  final Map<Skill, Offset> skillPositions;
  final Map<String, Offset> nodePositions;
  final List<_RoadmapInsertionPoint> pathInsertionPoints;

  const _OrbCanvasLayout({
    required this.size,
    required this.center,
    required this.selectedSkill,
    required this.pathLayout,
    required this.skillPositions,
    required this.nodePositions,
    required this.pathInsertionPoints,
  });
}
