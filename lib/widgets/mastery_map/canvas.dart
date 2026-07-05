part of '../mastery_map_workspace.dart';

class _OrbMasteryMapCanvas extends StatefulWidget {
  final AppState state;
  final bool isDark;
  final _MasterySelection? selection;
  final _RoadmapLayoutAxis layoutAxis;
  final ValueChanged<Skill> onSelectSkill;
  final VoidCallback onCollapse;
  final void Function(Skill skill, RoadmapTemplateConfig config)
  onApplyRoadmapTemplate;
  final void Function(Skill skill, SkillTreeNode node) onExtendPath;
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
    required this.layoutAxis,
    required this.onSelectSkill,
    required this.onCollapse,
    required this.onApplyRoadmapTemplate,
    required this.onExtendPath,
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
      layout.layoutAxis.name,
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

  void _showRoadmapTemplateSheet(BuildContext context, Skill skill) {
    final isDark = widget.isDark;
    final applyTemplate = widget.onApplyRoadmapTemplate;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          key: const ValueKey('roadmap-template-bottom-sheet'),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.86,
          ),
          decoration: BoxDecoration(
            color: surface(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
            child: _RoadmapTemplatePanel(
              key: const ValueKey('roadmap-template-panel'),
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
    );
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
            layout.layoutAxis,
          );
    final scaleX = target.width / bounds.width;
    final scaleY = target.height / bounds.height;
    final scale = math
        .min(1.0, math.min(scaleX, scaleY))
        .clamp(_roadmapCameraMinScale, 1.0)
        .toDouble();
    final selectedCenter = selectedSkill == null
        ? null
        : layout.skillPositions[selectedSkill];

    final dx =
        selectedSkill != null &&
            hasStages &&
            layout.layoutAxis == _RoadmapLayoutAxis.horizontal
        ? target.right - bounds.right * scale
        : selectedCenter != null &&
              layout.layoutAxis == _RoadmapLayoutAxis.vertical
        ? target.center.dx - selectedCenter.dx * scale
        : target.center.dx - bounds.center.dx * scale;
    final horizontalYOffset =
        selectedSkill != null &&
            layout.layoutAxis == _RoadmapLayoutAxis.horizontal
        ? -60.0
        : 0.0;

    final dy =
        (selectedSkill != null &&
                hasStages &&
                layout.layoutAxis == _RoadmapLayoutAxis.vertical
            ? target.top - bounds.top * scale
            : target.center.dy - bounds.center.dy * scale) +
        horizontalYOffset;

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

  Rect _roadmapTargetViewport(
    Size viewport,
    bool templatePanelCollapsed,
    _RoadmapLayoutAxis layoutAxis,
  ) {
    final isNarrow = viewport.width < 760;
    final vertical = layoutAxis == _RoadmapLayoutAxis.vertical;
    final edgePadding = vertical ? 16.0 : 28.0;
    final left = !isNarrow && !templatePanelCollapsed ? 284.0 : edgePadding;
    final top = vertical ? 16.0 : 86.0;
    final right = math.max(left + 160, viewport.width - edgePadding);
    final bottomPadding = isNarrow && !templatePanelCollapsed
        ? 238.0
        : vertical
        ? 12.0
        : 48.0;
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
      final focusedDiameter = layout.focusedSkillOrbDiameter;
      final focusedWidth = layout.compactVisuals ? 216.0 : 264.0;
      include(
        layout.layoutAxis == _RoadmapLayoutAxis.vertical
            ? Rect.fromLTWH(
                selectedCenter.dx - focusedWidth / 2,
                selectedCenter.dy - focusedDiameter / 2,
                focusedWidth,
                focusedDiameter +
                    _roadmapSkillLabelGap +
                    _roadmapSkillLabelHeight,
              )
            : Rect.fromCenter(center: selectedCenter, width: 284, height: 264),
      );
      if (selectedSkill.goal.trim().isNotEmpty) {
        include(_roadmapGoalAnchorRect(layout, selectedCenter));
      }
    }
    for (final position in layout.nodePositions.values) {
      include(
        layout.layoutAxis == _RoadmapLayoutAxis.vertical
            ? Rect.fromLTWH(
                position.dx - _roadmapNodeItemWidth / 2,
                position.dy - _roadmapNodeItemTopOffset,
                _roadmapNodeItemWidth,
                _roadmapNodeItemHeight,
              )
            : Rect.fromCenter(center: position, width: 202, height: 182),
      );
    }
    for (final point in layout.pathInsertionPoints) {
      include(Rect.fromCircle(center: point.position, radius: 30));
    }

    return (hasBounds ? bounds : (Offset.zero & layout.size)).inflate(
      layout.layoutAxis == _RoadmapLayoutAxis.vertical ? 8 : 38,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDark = widget.isDark;
    final selection = widget.selection;
    final mobilePresentation = MediaQuery.sizeOf(context).width < 760;
    final bg = mobilePresentation
        ? isDark
              ? const Color(0xFF11100F)
              : const Color(0xFFF6EEDD)
        : isDark
        ? Color.lerp(const Color(0xFF0D0D12), Colors.black, 0.75)!
        : const Color(0xFFF3EBDD);
    return Container(
      key: ValueKey('roadmap-canvas-${widget.layoutAxis.name}'),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(mobilePresentation ? 18 : 14),
        border: Border.all(
          color: mobilePresentation
              ? borderColor(isDark).withAlpha(70)
              : borderColor(isDark),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _buildOrbLayout(
            state,
            Size(constraints.maxWidth, constraints.maxHeight),
            baseTextStyle: DefaultTextStyle.of(context).style,
            textScaler: MediaQuery.textScalerOf(context),
            textDirection: Directionality.of(context),
          );
          final calmMobile = mobilePresentation;
          final compactCanvas = layout.compactVisuals;
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
                  key: ValueKey(
                    calmMobile
                        ? 'roadmap-mobile-calm-background'
                        : 'roadmap-desktop-vector-grid',
                  ),
                  painter: _MasteryVectorGridPainter(
                    isDark: isDark,
                    calmMobile: calmMobile,
                  ),
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
                              ? layout.focusedSkillOrbDiameter
                              : selected
                              ? compactCanvas
                                    ? 86.0
                                    : 98.0
                              : compactCanvas
                              ? 78.0
                              : 89.0;
                          final focusedWidth = compactCanvas ? 216.0 : 264.0;
                          return AnimatedPositioned(
                            key: ValueKey('map-skill-orb-${skill.id}'),
                            duration: kMotionSlow,
                            curve: kMotionCurve,
                            left:
                                position.dx -
                                (roadFocus ? focusedWidth / 2 : 108),
                            top: position.dy - orbDiameter / 2,
                            width: roadFocus ? focusedWidth : 216,
                            height:
                                orbDiameter +
                                _roadmapSkillLabelGap +
                                _roadmapSkillLabelHeight,
                            child: _SkillOrbButton(
                              skill: skill,
                              isDark: isDark,
                              selected: selected,
                              roadFocus: roadFocus,
                              hiddenInFocus: hiddenInFocus,
                              dimmed: selectedSkill != null && !selected,
                              compactVisuals: compactCanvas,
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
                              left: position.dx - _roadmapNodeItemWidth / 2,
                              top: position.dy - _roadmapNodeItemTopOffset,
                              width: _roadmapNodeItemWidth,
                              height: _roadmapNodeItemHeight,
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
                            final rightNode = point.rightNodeId == null
                                ? null
                                : selectedSkill.treeNodes
                                      .where(
                                        (node) => node.id == point.rightNodeId,
                                      )
                                      .firstOrNull;
                            if (leftNode == null ||
                                (point.rightNodeId != null &&
                                    rightNode == null)) {
                              return const SizedBox.shrink();
                            }
                            final position = point.position;
                            return AnimatedPositioned(
                              key: ValueKey(
                                'roadmap-insert-${selectedSkill.id}-${leftNode.id}-${rightNode?.id ?? 'skill'}',
                              ),
                              duration: kMotionSlow,
                              curve: kMotionCurve,
                              left: position.dx - _roadmapInsertHitSize / 2,
                              top: position.dy - _roadmapInsertHitSize / 2,
                              width: _roadmapInsertHitSize,
                              height: _roadmapInsertHitSize,
                              child: _RoadmapInsertStageButton(
                                isDark: isDark,
                                color: selectedSkill.color,
                                onTap: () => rightNode == null
                                    ? widget.onExtendPath(
                                        selectedSkill,
                                        leftNode,
                                      )
                                    : widget.onInsertStageAfter(
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
                              final rect = _roadmapGoalAnchorRect(
                                layout,
                                center,
                              );
                              return Positioned(
                                key: ValueKey(
                                  'roadmap-goal-anchor-${selectedSkill.id}',
                                ),
                                left: rect.left,
                                top: rect.top,
                                width: rect.width,
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
                  top: constraints.maxWidth < 760 ? null : 14,
                  bottom: constraints.maxWidth < 760 ? 14 : null,
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
                                if (calmMobile) {
                                  if (selection?.type !=
                                      _MasterySelectionType.skill) {
                                    widget.onSelectSkill(selectedSkill);
                                  }
                                  _showRoadmapTemplateSheet(
                                    context,
                                    selectedSkill,
                                  );
                                  return;
                                }
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

  _OrbCanvasLayout _buildOrbLayout(
    AppState state,
    Size minSize, {
    required TextStyle baseTextStyle,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
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
    final compactVisuals = minSize.width < 760;
    final vertical = widget.layoutAxis == _RoadmapLayoutAxis.vertical;
    const verticalStageStep = _roadmapVerticalStageStep;
    const stageStep = 170.0;
    const terminalGap = 208.0;
    final focusLeftSafe = minSize.width < 760 ? 88.0 : 338.0;
    final visualSpan = stageCount == 0
        ? 0.0
        : vertical
        ? 210.0 + (maxStagesInPath - 1) * verticalStageStep
        : terminalGap + (maxStagesInPath - 1) * stageStep;
    final roadWidth = vertical
        ? 500.0 + (pathCount - 1) * 180.0
        : focusLeftSafe + visualSpan + 360.0;
    final roadHeight = vertical
        ? visualSpan + 380.0
        : 250.0 + pathCount * 132.0;
    final double width = math
        .max(
          minSize.width,
          selectedSkill == null
              ? 720
              : vertical
              ? math.max(900.0, roadWidth)
              : math.max(1060.0, roadWidth),
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
        : vertical
        ? _verticalRoadmapSkillCenter(Size(width, height), stageCount)
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
        : _placeRoadmapNodes(
            pathLayout,
            selectedCenter,
            widget.layoutAxis,
            verticalStageStep: verticalStageStep,
          );
    final pathInsertionPoints = selectedSkill == null || selectedCenter == null
        ? const <_RoadmapInsertionPoint>[]
        : _placeRoadmapInsertionActions(
            selectedSkill,
            pathLayout,
            nodePositions,
            selectedCenter,
            widget.layoutAxis,
            baseTextStyle: baseTextStyle,
            textScaler: textScaler,
            textDirection: textDirection,
            compactVisuals: compactVisuals,
          );

    return _OrbCanvasLayout(
      size: Size(width, height),
      center: center,
      layoutAxis: widget.layoutAxis,
      selectedSkill: selectedSkill,
      pathLayout: pathLayout,
      skillPositions: skillPositions,
      nodePositions: nodePositions,
      pathInsertionPoints: pathInsertionPoints,
      compactVisuals: compactVisuals,
    );
  }

  Offset _verticalRoadmapSkillCenter(Size size, int stageCount) => Offset(
    size.width / 2,
    stageCount <= 2 ? math.min(260.0, size.height * 0.34) : 200,
  );

  Rect _roadmapGoalAnchorRect(_OrbCanvasLayout layout, Offset skillCenter) {
    final skill = layout.selectedSkill;
    if (skill == null) return Rect.zero;
    final measuredWidth = _roadmapGoalAnchorWidth(skill.goal);
    if (layout.layoutAxis == _RoadmapLayoutAxis.vertical) {
      final width = math.min(measuredWidth, 260.0);
      return Rect.fromLTWH(
        skillCenter.dx + layout.focusedSkillOrbDiameter / 2 + 34,
        skillCenter.dy - _roadmapGoalAnchorEstimatedHeight / 2,
        width,
        _roadmapGoalAnchorEstimatedHeight,
      );
    }
    return Rect.fromLTWH(
      skillCenter.dx - measuredWidth / 2,
      skillCenter.dy - _roadmapGoalAnchorTopOffset,
      measuredWidth,
      _roadmapGoalAnchorEstimatedHeight,
    );
  }

  Offset _roadmapSkillCenter(
    Size size,
    double focusLeftSafe,
    double visualSpan,
  ) {
    final workRight = size.width - 188.0;
    final workCenter = Offset(
      (focusLeftSafe + workRight) / 2,
      size.height / 2 + 28,
    );
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
    _RoadmapLayoutAxis layoutAxis, {
    required double verticalStageStep,
  }) {
    if (pathLayout.paths.isEmpty) return {};
    final positions = <String, Offset>{};
    final pathCount = pathLayout.paths.length;
    const terminalGap = 208.0;
    const stageStep = 170.0;
    const pathStep = 132.0;
    if (layoutAxis == _RoadmapLayoutAxis.vertical) {
      const verticalTerminalGap = 210.0;
      const verticalPathStep = 180.0;
      for (
        var pathIndex = 0;
        pathIndex < pathLayout.paths.length;
        pathIndex++
      ) {
        final path = pathLayout.paths[pathIndex];
        final x =
            skillCenter.dx +
            (pathIndex - (pathCount - 1) / 2) * verticalPathStep;
        for (var stageIndex = 0; stageIndex < path.nodes.length; stageIndex++) {
          final node = path.nodes[stageIndex];
          final y =
              skillCenter.dy +
              verticalTerminalGap +
              (path.nodes.length - 1 - stageIndex) * verticalStageStep;
          positions.putIfAbsent(node.id, () => Offset(x, y));
        }
      }
      return positions;
    }

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
    Skill skill,
    RoadmapPathLayout pathLayout,
    Map<String, Offset> nodePositions,
    Offset skillCenter,
    _RoadmapLayoutAxis layoutAxis, {
    required TextStyle baseTextStyle,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required bool compactVisuals,
  }) {
    final points = <_RoadmapInsertionPoint>[];
    for (final path in pathLayout.paths) {
      for (var index = 0; index < path.nodes.length - 1; index++) {
        final leftNode = path.nodes[index];
        final rightNode = path.nodes[index + 1];
        final leftPosition = nodePositions[leftNode.id];
        final rightPosition = nodePositions[rightNode.id];
        if (leftPosition == null || rightPosition == null) continue;
        final position = layoutAxis == _RoadmapLayoutAxis.vertical
            ? _verticalRoadmapInsertionPosition(
                upperPosition: rightPosition,
                upperBottomOffset: _roadmapNodeLabelTextBottomOffset(
                  rightNode,
                  baseTextStyle,
                  textScaler,
                  textDirection,
                ),
                lowerPosition: leftPosition,
                lowerTopOffset: _roadmapNodeOrbTopOffset(leftNode),
              )
            : Offset.lerp(leftPosition, rightPosition, 0.5)!;
        points.add(
          _RoadmapInsertionPoint(
            leftNodeId: leftNode.id,
            rightNodeId: rightNode.id,
            position: position,
          ),
        );
      }
      final terminal = path.terminalStage;
      final terminalPosition = terminal == null
          ? null
          : nodePositions[terminal.id];
      if (terminal != null && terminalPosition != null) {
        final position = layoutAxis == _RoadmapLayoutAxis.vertical
            ? _verticalRoadmapInsertionPosition(
                upperPosition: skillCenter,
                upperBottomOffset: _roadmapFocusedSkillLabelTextBottomOffset(
                  skill,
                  baseTextStyle,
                  textScaler,
                  textDirection,
                  orbDiameter: compactVisuals
                      ? _roadmapMobileFocusedSkillOrbDiameter
                      : _roadmapFocusedSkillOrbDiameter,
                ),
                lowerPosition: terminalPosition,
                lowerTopOffset: _roadmapNodeOrbTopOffset(terminal),
              )
            : _horizontalTerminalInsertionPosition(
                terminalPosition: terminalPosition,
                terminalNode: terminal,
                skillCenter: skillCenter,
              );
        points.add(
          _RoadmapInsertionPoint(
            leftNodeId: terminal.id,
            rightNodeId: null,
            position: position,
          ),
        );
      }
    }
    return points;
  }

  Offset _verticalRoadmapInsertionPosition({
    required Offset upperPosition,
    required double upperBottomOffset,
    required Offset lowerPosition,
    required double lowerTopOffset,
  }) {
    final upperBottom = upperPosition.dy + upperBottomOffset;
    final lowerTop = lowerPosition.dy + lowerTopOffset;
    return Offset(
      (upperPosition.dx + lowerPosition.dx) / 2,
      (upperBottom + lowerTop) / 2,
    );
  }

  Offset _horizontalTerminalInsertionPosition({
    required Offset terminalPosition,
    required SkillTreeNode terminalNode,
    required Offset skillCenter,
  }) {
    final terminalRight =
        terminalPosition.dx +
        _roadmapNodeOrbDiameter(terminalNode.questTarget) / 2;
    const focusedSkillVisualInset = 12.0;
    final skillLeft =
        skillCenter.dx -
        _roadmapFocusedSkillOrbDiameter / 2 +
        focusedSkillVisualInset;
    return Offset(
      (terminalRight + skillLeft) / 2,
      (terminalPosition.dy + skillCenter.dy) / 2,
    );
  }
}

class _RoadmapInsertionPoint {
  final String leftNodeId;
  final String? rightNodeId;
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
  final _RoadmapLayoutAxis layoutAxis;
  final Skill? selectedSkill;
  final RoadmapPathLayout pathLayout;
  final Map<Skill, Offset> skillPositions;
  final Map<String, Offset> nodePositions;
  final List<_RoadmapInsertionPoint> pathInsertionPoints;
  final bool compactVisuals;

  double get focusedSkillOrbDiameter => compactVisuals
      ? _roadmapMobileFocusedSkillOrbDiameter
      : _roadmapFocusedSkillOrbDiameter;

  const _OrbCanvasLayout({
    required this.size,
    required this.center,
    required this.layoutAxis,
    required this.selectedSkill,
    required this.pathLayout,
    required this.skillPositions,
    required this.nodePositions,
    required this.pathInsertionPoints,
    required this.compactVisuals,
  });
}
