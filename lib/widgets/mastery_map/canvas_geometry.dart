part of '../mastery_map_workspace.dart';

extension _OrbMasteryMapCanvasGeometry on _OrbMasteryMapCanvasState {
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
      if (layout.goalAnchorRect case final goalAnchorRect?) {
        include(goalAnchorRect);
      }
    }
    if (layout.layoutAxis == _RoadmapLayoutAxis.vertical) {
      for (final geometry in layout.verticalNodeGeometry.values) {
        include(geometry.orbRect);
        include(geometry.labelRect);
      }
    } else {
      for (final position in layout.nodePositions.values) {
        include(Rect.fromCenter(center: position, width: 202, height: 182));
      }
    }
    for (final point in layout.pathInsertionPoints) {
      include(Rect.fromCircle(center: point.position, radius: 30));
    }

    return (hasBounds ? bounds : (Offset.zero & layout.size)).inflate(
      layout.layoutAxis == _RoadmapLayoutAxis.vertical ? 8 : 38,
    );
  }

  Rect _roadmapGoalAnchorRectFor({
    required Skill skill,
    required Offset skillCenter,
    required _RoadmapLayoutAxis layoutAxis,
    required double focusedSkillOrbDiameter,
    required TextStyle baseTextStyle,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    final anchorSize = _roadmapGoalAnchorSize(
      text: skill.goal,
      vertical: layoutAxis == _RoadmapLayoutAxis.vertical,
      baseTextStyle: baseTextStyle,
      textScaler: textScaler,
      textDirection: textDirection,
    );
    if (layoutAxis == _RoadmapLayoutAxis.vertical) {
      return Rect.fromCenter(
        center: Offset(
          skillCenter.dx +
              focusedSkillOrbDiameter / 2 +
              34 +
              anchorSize.width / 2,
          skillCenter.dy,
        ),
        width: anchorSize.width,
        height: anchorSize.height,
      );
    }
    return Rect.fromLTWH(
      skillCenter.dx - anchorSize.width / 2,
      skillCenter.dy - _roadmapGoalAnchorTopOffset,
      anchorSize.width,
      anchorSize.height,
    );
  }

  Map<String, VerticalRoadmapNodeGeometry> _buildVerticalNodeGeometry({
    required AppState state,
    required Skill skill,
    required Map<String, Offset> nodePositions,
    required Offset skillCenter,
    required _RoadmapLayoutAxis layoutAxis,
    required TextStyle baseTextStyle,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    if (layoutAxis != _RoadmapLayoutAxis.vertical) return const {};
    final result = <String, VerticalRoadmapNodeGeometry>{};
    for (final node in skill.treeNodes) {
      final orbCenter = nodePositions[node.id];
      if (orbCenter == null) continue;
      final status = skill.treeNodeStatus(node);
      final target = node.questTarget;
      final completed = state.completedTasksForTreeNode(skill.id, node.id);
      final metadata =
          '${_roadmapStageStatusLabel(status)} · ${math.min(completed, target)}/$target';
      final side = _verticalNodeLabelSide(
        orbCenter: orbCenter,
        skillCenter: skillCenter,
      );
      result[node.id] = VerticalRoadmapNodeGeometry.fromCenter(
        nodeId: node.id,
        orbCenter: orbCenter,
        orbDiameter: _roadmapNodeOrbDiameter(target),
        labelSize: Size(
          _roadmapVerticalNodeLabelWidth,
          _roadmapVerticalNodeLabelHeight(
            node: node,
            metadata: metadata,
            baseTextStyle: baseTextStyle,
            textScaler: textScaler,
            textDirection: textDirection,
          ),
        ),
        labelSide: side,
        labelGap: _roadmapVerticalNodeLabelGap,
      );
    }
    return result;
  }

  /// Branch stages label outward, away from the axis: a
  /// [_roadmapVerticalNodeLabelWidth] label pointed inward would run over the
  /// neighbouring path, which sits only 180px away. Stages on the axis itself
  /// have no outward side, so they all label right and read as one column.
  VerticalRoadmapLabelSide _verticalNodeLabelSide({
    required Offset orbCenter,
    required Offset skillCenter,
  }) {
    final branchDelta = orbCenter.dx - skillCenter.dx;
    if (branchDelta < -1) return VerticalRoadmapLabelSide.left;
    return VerticalRoadmapLabelSide.right;
  }
}
