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
  final VoidCallback? onInitialViewReady;

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
    this.onInitialViewReady,
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
  String? _lastRoadmapCameraSkillId;
  _RoadmapLayoutAxis? _lastRoadmapCameraAxis;
  bool _hasInitialRoadmapCameraFit = false;
  bool _initialViewReadyReported = false;
  bool _reducedMotion = false;
  Timer? _roadmapCameraFitTimer;
  _OrbCanvasLayout? _lastLayout;
  Size? _lastViewport;

  void centerContent() {
    final layout = _lastLayout;
    final viewport = _lastViewport;
    if (layout == null || viewport == null) return;
    _roadmapCameraFitTimer?.cancel();
    _centerRoadmapOverviewCamera(layout, viewport);
  }

  void showTemplates() {
    if (widget.selection == null) return;
    setState(() => _templatePanelHidden = false);
  }

  void _applyDesktopTemplate(Skill skill, RoadmapTemplateConfig config) {
    setState(() => _templatePanelHidden = true);
    widget.onApplyRoadmapTemplate(skill, config);
  }

  @override
  void dispose() {
    _roadmapCameraAnimationController
      ..removeListener(_handleRoadmapCameraTick)
      ..dispose();
    _roadmapCameraFitTimer?.cancel();
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

  void _reportInitialViewReady() {
    if (_initialViewReadyReported) return;
    _initialViewReadyReported = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onInitialViewReady?.call();
    });
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
    final selectionChanged =
        _lastRoadmapCameraSkillId != layout.selectedSkill?.id;
    final axisChanged = _lastRoadmapCameraAxis != layout.layoutAxis;
    _lastRoadmapCameraSignature = signature;
    _lastRoadmapCameraSkillId = layout.selectedSkill?.id;
    _lastRoadmapCameraAxis = layout.layoutAxis;

    final target = _roadmapFitMatrix(layout, viewport, templatePanelCollapsed);
    if (!_hasInitialRoadmapCameraFit) {
      // The first visible graph must already use its final camera transform.
      // Delaying this fit painted nodes at identity and caused a visible jump.
      _hasInitialRoadmapCameraFit = true;
      _roadmapCameraAnimationController.stop();
      _roadmapCameraController.value = target;
      _reportInitialViewReady();
      return;
    }

    if (selectionChanged || axisChanged) {
      _roadmapCameraFitTimer?.cancel();
      _animateRoadmapCameraTo(target);
      return;
    }

    // Native desktop resizing can issue many LayoutBuilder passes per second.
    // Fit after the constraints settle instead of restarting the camera for
    // every intermediate frame.
    _roadmapCameraFitTimer?.cancel();
    _roadmapCameraFitTimer = Timer(const Duration(milliseconds: 90), () {
      if (!mounted || signature != _lastRoadmapCameraSignature) return;
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
      layout.geometrySignature,
    ].join(':');
  }

  void _animateRoadmapCameraTo(Matrix4 target) {
    final current = _roadmapCameraController.value;
    if (_reducedMotion || _matrixCloseTo(current, target)) {
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
    final dx = target.center.dx - bounds.center.dx * scale;
    final dy = target.center.dy - bounds.center.dy * scale;

    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDark = widget.isDark;
    final selection = widget.selection;
    final mobilePresentation = MediaQuery.sizeOf(context).width < 760;
    _reducedMotion =
        state.reducedMotion || MediaQuery.disableAnimationsOf(context);
    final bg = RoadmapVisualTokens.canvas(
      isDark: isDark,
      mobile: mobilePresentation,
    );
    return Container(
      key: ValueKey('roadmap-canvas-${widget.layoutAxis.name}'),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
          mobilePresentation ? 18 : DesktopScale.radiusL,
        ),
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
          _lastLayout = layout;
          _lastViewport = Size(constraints.maxWidth, constraints.maxHeight);
          final calmMobile = mobilePresentation;
          final selectedSkill = layout.selectedSkill;
          final layoutMotionDuration = _reducedMotion
              ? Duration.zero
              : kMotionSlow;
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
                child: RepaintBoundary(
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
              ),
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _roadmapCameraController,
                  minScale: _roadmapCameraMinScale,
                  maxScale: 1.85,
                  boundaryMargin: const EdgeInsets.all(3000),
                  constrained: false,
                  child: _RoadmapGeometryTransition(
                    layout: layout,
                    duration: layoutMotionDuration,
                    curve: kMotionCurve,
                    builder: (context, geometry) => SizedBox(
                      width: geometry.size.width,
                      height: geometry.size.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                key: const ValueKey(
                                  'roadmap-connector-painter',
                                ),
                                painter: _OrbMasteryMapPainter(
                                  layout: geometry,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                          ...geometry.skillPositions.entries.map((entry) {
                            final skill = entry.key;
                            final position = entry.value;
                            final selected = selection?.skillId == skill.id;
                            final roadFocus =
                                selectedSkill != null &&
                                selectedSkill.id == skill.id;
                            final hiddenInFocus =
                                selectedSkill != null && !roadFocus;
                            final orbDiameter = roadFocus
                                ? geometry.focusedSkillOrbDiameter
                                : selected
                                ? geometry.compactVisuals
                                      ? 86.0
                                      : 98.0
                                : geometry.compactVisuals
                                ? 78.0
                                : 89.0;
                            final focusedWidth = geometry.compactVisuals
                                ? 216.0
                                : 264.0;
                            return Positioned(
                              key: ValueKey('map-skill-orb-${skill.id}'),
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
                                compactVisuals: geometry.compactVisuals,
                                geometryOrbDiameter: orbDiameter,
                                onTap: () => widget.onSelectSkill(skill),
                              ),
                            );
                          }),
                          if (selectedSkill != null)
                            ...selectedSkill.treeNodes.expand((node) {
                              final position = geometry.nodePositions[node.id];
                              if (position == null) {
                                return const <Widget>[];
                              }
                              final vertical =
                                  geometry.layoutAxis ==
                                  _RoadmapLayoutAxis.vertical;
                              final selected =
                                  selection?.nodeId == node.id &&
                                  selection?.type !=
                                      _MasterySelectionType.skill;
                              void onTap() =>
                                  widget.onSelectNode(selectedSkill, node);
                              if (vertical) {
                                final nodeGeometry =
                                    geometry.verticalNodeGeometry[node.id];
                                if (nodeGeometry == null) {
                                  return const <Widget>[];
                                }
                                return <Widget>[
                                  Positioned.fromRect(
                                    rect: nodeGeometry.labelRect,
                                    child: _VerticalRoadmapStageLabel(
                                      key: ValueKey(
                                        'map-node-label-${selectedSkill.id}-${node.id}',
                                      ),
                                      state: state,
                                      skill: selectedSkill,
                                      node: node,
                                      isDark: isDark,
                                      side: nodeGeometry.labelSide,
                                      onTap: onTap,
                                    ),
                                  ),
                                  Positioned.fromRect(
                                    key: ValueKey(
                                      'map-node-${selectedSkill.id}-${node.id}',
                                    ),
                                    rect: nodeGeometry.orbRect,
                                    child: AnimatedSwitcher(
                                      duration: layoutMotionDuration,
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
                                        selected: selected,
                                        layoutAxis: geometry.layoutAxis,
                                        onTap: onTap,
                                      ),
                                    ),
                                  ),
                                ];
                              }
                              return <Widget>[
                                Positioned(
                                  key: ValueKey(
                                    'map-node-${selectedSkill.id}-${node.id}',
                                  ),
                                  left: position.dx - _roadmapNodeItemWidth / 2,
                                  top: position.dy - _roadmapNodeItemTopOffset,
                                  width: _roadmapNodeItemWidth,
                                  height: _roadmapNodeItemHeight,
                                  child: AnimatedSwitcher(
                                    duration: layoutMotionDuration,
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
                                      selected: selected,
                                      layoutAxis: geometry.layoutAxis,
                                      onTap: onTap,
                                    ),
                                  ),
                                ),
                              ];
                            }),
                          if (selectedSkill != null)
                            ...geometry.pathInsertionPoints.map((point) {
                              final leftNode = selectedSkill.treeNodes
                                  .where((node) => node.id == point.leftNodeId)
                                  .firstOrNull;
                              final rightNode = point.rightNodeId == null
                                  ? null
                                  : selectedSkill.treeNodes
                                        .where(
                                          (node) =>
                                              node.id == point.rightNodeId,
                                        )
                                        .firstOrNull;
                              if (leftNode == null ||
                                  (point.rightNodeId != null &&
                                      rightNode == null)) {
                                return const SizedBox.shrink();
                              }
                              final position = point.position;
                              return Positioned(
                                key: ValueKey(
                                  'roadmap-insert-${selectedSkill.id}-${leftNode.id}-${rightNode?.id ?? 'skill'}',
                                ),
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
                                final rect = geometry.goalAnchorRect;
                                if (rect == null) {
                                  return const SizedBox.shrink();
                                }
                                return Positioned.fromRect(
                                  key: ValueKey(
                                    'roadmap-goal-anchor-${selectedSkill.id}',
                                  ),
                                  rect: rect,
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
              ),
              if (selectedSkill == null)
                Positioned(
                  left: 14,
                  top: 14,
                  width: 214,
                  child: _SelectSkillHint(isDark: isDark),
                ),
              if (selectedSkill != null && constraints.maxWidth < 760)
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
                  bottom: 14,
                  width: constraints.maxWidth < 760
                      ? math.min(constraints.maxWidth - 28, 276)
                      : 235,
                  child: AnimatedSwitcher(
                    duration: layoutMotionDuration,
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
                        ? calmMobile
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
                                      setState(
                                        () => _templatePanelHidden = false,
                                      );
                                      if (selection?.type !=
                                          _MasterySelectionType.skill) {
                                        widget.onSelectSkill(selectedSkill);
                                      }
                                    },
                                  ),
                                )
                              : const SizedBox.shrink()
                        : _RoadmapTemplatePanel(
                            key: const ValueKey('roadmap-template-panel'),
                            skill: selectedSkill,
                            isDark: isDark,
                            onHide: () =>
                                setState(() => _templatePanelHidden = true),
                            onApply: (config) =>
                                _applyDesktopTemplate(selectedSkill, config),
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
    final verticalNodeGeometry = selectedSkill == null || selectedCenter == null
        ? const <String, VerticalRoadmapNodeGeometry>{}
        : _buildVerticalNodeGeometry(
            state: state,
            skill: selectedSkill,
            nodePositions: nodePositions,
            skillCenter: selectedCenter,
            layoutAxis: widget.layoutAxis,
            baseTextStyle: baseTextStyle,
            textScaler: textScaler,
            textDirection: textDirection,
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

    final goalAnchorRect = selectedSkill == null || selectedCenter == null
        ? null
        : _roadmapGoalAnchorRectFor(
            skill: selectedSkill,
            skillCenter: selectedCenter,
            layoutAxis: widget.layoutAxis,
            focusedSkillOrbDiameter: compactVisuals
                ? _roadmapMobileFocusedSkillOrbDiameter
                : _roadmapFocusedSkillOrbDiameter,
            baseTextStyle: baseTextStyle,
            textScaler: textScaler,
            textDirection: textDirection,
          );
    return _OrbCanvasLayout(
      size: Size(width, height),
      center: center,
      layoutAxis: widget.layoutAxis,
      selectedSkill: selectedSkill,
      pathLayout: pathLayout,
      skillPositions: skillPositions,
      nodePositions: nodePositions,
      verticalNodeGeometry: verticalNodeGeometry,
      pathInsertionPoints: pathInsertionPoints,
      goalAnchorRect: goalAnchorRect,
      compactVisuals: compactVisuals,
      focusedSkillOrbDiameter: compactVisuals
          ? _roadmapMobileFocusedSkillOrbDiameter
          : _roadmapFocusedSkillOrbDiameter,
      verticalAxisProgress: vertical ? 1 : 0,
      geometrySignature: _orbGeometrySignature(
        size: Size(width, height),
        layoutAxis: widget.layoutAxis,
        selectedSkill: selectedSkill,
        skillPositions: skillPositions,
        nodePositions: nodePositions,
        verticalNodeGeometry: verticalNodeGeometry,
        pathInsertionPoints: pathInsertionPoints,
        goalAnchorRect: goalAnchorRect,
        compactVisuals: compactVisuals,
      ),
      paintSignature: _orbPaintSignature(
        size: Size(width, height),
        layoutAxis: widget.layoutAxis,
        selectedSkill: selectedSkill,
        pathLayout: pathLayout,
        skillPositions: skillPositions,
        nodePositions: nodePositions,
        compactVisuals: compactVisuals,
      ),
    );
  }

  String _orbGeometrySignature({
    required Size size,
    required _RoadmapLayoutAxis layoutAxis,
    required Skill? selectedSkill,
    required Map<Skill, Offset> skillPositions,
    required Map<String, Offset> nodePositions,
    required Map<String, VerticalRoadmapNodeGeometry> verticalNodeGeometry,
    required List<_RoadmapInsertionPoint> pathInsertionPoints,
    required Rect? goalAnchorRect,
    required bool compactVisuals,
  }) {
    final signature = StringBuffer()
      ..write('${size.width}:${size.height}:${layoutAxis.name}:$compactVisuals')
      ..write(':${selectedSkill?.id ?? 'none'}');
    final skills = skillPositions.entries.toList()
      ..sort((left, right) => left.key.id.compareTo(right.key.id));
    for (final entry in skills) {
      signature.write(':${entry.key.id}@${entry.value.dx},${entry.value.dy}');
    }
    final nodes = nodePositions.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in nodes) {
      signature.write(':${entry.key}@${entry.value.dx},${entry.value.dy}');
    }
    final verticalNodes = verticalNodeGeometry.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in verticalNodes) {
      signature.write(
        ':vertical:${entry.key}:${entry.value.orbRect}:${entry.value.labelRect}:${entry.value.labelSide.name}',
      );
    }
    for (final point in pathInsertionPoints) {
      signature.write(
        ':insert:${point.leftNodeId}:${point.rightNodeId}@${point.position.dx},${point.position.dy}',
      );
    }
    if (goalAnchorRect != null) {
      signature.write(':goal:$goalAnchorRect');
    }
    return signature.toString();
  }

  String _orbPaintSignature({
    required Size size,
    required _RoadmapLayoutAxis layoutAxis,
    required Skill? selectedSkill,
    required RoadmapPathLayout pathLayout,
    required Map<Skill, Offset> skillPositions,
    required Map<String, Offset> nodePositions,
    required bool compactVisuals,
  }) {
    final signature = StringBuffer()
      ..write('${size.width}:${size.height}:${layoutAxis.name}:$compactVisuals')
      ..write(':${selectedSkill?.id ?? 'none'}')
      ..write(':${selectedSkill?.color.toARGB32() ?? 0}');
    final skills = skillPositions.entries.toList()
      ..sort((left, right) => left.key.id.compareTo(right.key.id));
    for (final entry in skills) {
      signature.write(':${entry.key.id}@${entry.value.dx},${entry.value.dy}');
    }
    final positions = nodePositions.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in positions) {
      signature.write(':${entry.key}@${entry.value.dx},${entry.value.dy}');
    }
    if (selectedSkill != null) {
      for (final node in selectedSkill.treeNodes) {
        signature.write(
          ':${node.id}:${selectedSkill.treeNodeStatus(node).name}:${node.questTarget}',
        );
      }
    }
    for (final path in pathLayout.paths) {
      signature.write(
        ':path${path.index}:${path.nodes.map((node) => node.id).join(',')}',
      );
    }
    return signature.toString();
  }

  Offset _verticalRoadmapSkillCenter(Size size, int stageCount) =>
      Offset(size.width / 2, 200);

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
                  layoutAxis,
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
  final Map<String, VerticalRoadmapNodeGeometry> verticalNodeGeometry;
  final List<_RoadmapInsertionPoint> pathInsertionPoints;
  final Rect? goalAnchorRect;
  final bool compactVisuals;
  final double focusedSkillOrbDiameter;
  final double verticalAxisProgress;
  final String geometrySignature;
  final String paintSignature;

  const _OrbCanvasLayout({
    required this.size,
    required this.center,
    required this.layoutAxis,
    required this.selectedSkill,
    required this.pathLayout,
    required this.skillPositions,
    required this.nodePositions,
    required this.verticalNodeGeometry,
    required this.pathInsertionPoints,
    required this.goalAnchorRect,
    required this.compactVisuals,
    required this.focusedSkillOrbDiameter,
    required this.verticalAxisProgress,
    required this.geometrySignature,
    required this.paintSignature,
  });
}

typedef _RoadmapGeometryBuilder =
    Widget Function(BuildContext context, _OrbCanvasLayout layout);

class _RoadmapGeometryTransition extends StatefulWidget {
  final _OrbCanvasLayout layout;
  final Duration duration;
  final Curve curve;
  final _RoadmapGeometryBuilder builder;

  const _RoadmapGeometryTransition({
    required this.layout,
    required this.duration,
    required this.curve,
    required this.builder,
  });

  @override
  State<_RoadmapGeometryTransition> createState() =>
      _RoadmapGeometryTransitionState();
}

class _RoadmapGeometryTransitionState extends State<_RoadmapGeometryTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late _OrbCanvasLayout _from = widget.layout;
  late _OrbCanvasLayout _target = widget.layout;

  @override
  void didUpdateWidget(covariant _RoadmapGeometryTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.layout.geometrySignature == _target.geometrySignature) {
      _target = widget.layout;
      if (_controller.isCompleted) _from = widget.layout;
      return;
    }

    final current = _currentLayout;
    if (widget.duration == Duration.zero ||
        !_canInterpolateRoadmapGeometry(current, widget.layout)) {
      _controller.stop();
      _from = widget.layout;
      _target = widget.layout;
      _controller.value = 1;
      return;
    }

    _from = current;
    _target = widget.layout;
    _controller.forward(from: 0);
  }

  _OrbCanvasLayout get _currentLayout => _interpolateOrbCanvasLayout(
    _from,
    _target,
    widget.curve.transform(_controller.value),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => widget.builder(context, _currentLayout),
  );
}

bool _canInterpolateRoadmapGeometry(
  _OrbCanvasLayout from,
  _OrbCanvasLayout to,
) {
  if (from.selectedSkill?.id != to.selectedSkill?.id) return false;
  final fromNodeIds = from.nodePositions.keys.toSet();
  final toNodeIds = to.nodePositions.keys.toSet();
  if (fromNodeIds.length != toNodeIds.length ||
      !fromNodeIds.every(toNodeIds.contains)) {
    return false;
  }
  return true;
}

_OrbCanvasLayout _interpolateOrbCanvasLayout(
  _OrbCanvasLayout from,
  _OrbCanvasLayout to,
  double progress,
) {
  if (progress >= 1) return to;
  final t = progress.clamp(0.0, 1.0);
  final fromSkillsById = {
    for (final entry in from.skillPositions.entries) entry.key.id: entry.value,
  };
  final skillPositions = <Skill, Offset>{
    for (final entry in to.skillPositions.entries)
      entry.key: Offset.lerp(
        fromSkillsById[entry.key.id] ?? entry.value,
        entry.value,
        t,
      )!,
  };
  final nodePositions = <String, Offset>{
    for (final entry in to.nodePositions.entries)
      entry.key: Offset.lerp(
        from.nodePositions[entry.key] ?? entry.value,
        entry.value,
        t,
      )!,
  };
  final verticalNodeGeometry = <String, VerticalRoadmapNodeGeometry>{
    for (final entry in to.verticalNodeGeometry.entries)
      entry.key: entry.value.translatedTo(
        nodePositions[entry.key] ?? entry.value.orbCenter,
      ),
  };
  final fromInsertionPoints = {
    for (final point in from.pathInsertionPoints)
      '${point.leftNodeId}:${point.rightNodeId ?? 'skill'}': point.position,
  };
  final insertionPoints = [
    for (final point in to.pathInsertionPoints)
      _RoadmapInsertionPoint(
        leftNodeId: point.leftNodeId,
        rightNodeId: point.rightNodeId,
        position: Offset.lerp(
          fromInsertionPoints['${point.leftNodeId}:${point.rightNodeId ?? 'skill'}'] ??
              point.position,
          point.position,
          t,
        )!,
      ),
  ];
  final goalAnchorRect = switch ((from.goalAnchorRect, to.goalAnchorRect)) {
    (final Rect fromRect, final Rect toRect) => Rect.fromCenter(
      center: Offset.lerp(fromRect.center, toRect.center, t)!,
      width: toRect.width,
      height: toRect.height,
    ),
    (_, final Rect toRect) => toRect,
    _ => null,
  };
  return _OrbCanvasLayout(
    size: Size.lerp(from.size, to.size, t)!,
    center: Offset.lerp(from.center, to.center, t)!,
    layoutAxis: to.layoutAxis,
    selectedSkill: to.selectedSkill,
    pathLayout: to.pathLayout,
    skillPositions: skillPositions,
    nodePositions: nodePositions,
    verticalNodeGeometry: verticalNodeGeometry,
    pathInsertionPoints: insertionPoints,
    goalAnchorRect: goalAnchorRect,
    compactVisuals: to.compactVisuals,
    focusedSkillOrbDiameter:
        from.focusedSkillOrbDiameter +
        (to.focusedSkillOrbDiameter - from.focusedSkillOrbDiameter) * t,
    verticalAxisProgress:
        from.verticalAxisProgress +
        (to.verticalAxisProgress - from.verticalAxisProgress) * t,
    geometrySignature: to.geometrySignature,
    paintSignature: '${to.paintSignature}:geometry:${t.toStringAsFixed(4)}',
  );
}
