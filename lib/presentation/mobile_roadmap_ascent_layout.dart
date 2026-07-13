import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engines/roadmap_engine.dart';

/// Mobile-only projection of the existing RoadMap graph.
///
/// The domain keeps its prerequisite direction. This calculator only maps that
/// direction onto a readable mobile path: the skill root stays at the top,
/// while the foundation sits at the bottom and later stages rise toward the
/// skill. This is presentation geometry only; the stored RoadMap graph is
/// unchanged.
class MobileRoadMapAscentLayout {
  const MobileRoadMapAscentLayout();

  MobileRoadMapLayoutResult calculate({
    required Size viewport,
    required List<RoadmapStageInfo> stages,
    double textScale = 1,
  }) {
    final safeWidth = math.max(280.0, viewport.width);
    if (stages.isEmpty) {
      return MobileRoadMapLayoutResult.empty(width: safeWidth);
    }

    final sourceIndex = <String, int>{
      for (var index = 0; index < stages.length; index++)
        stages[index].node.id: index,
    };
    final stageById = {for (final stage in stages) stage.node.id: stage};
    final parentsById = <String, List<String>>{
      for (final stage in stages)
        stage.node.id: stage.node.prerequisiteIds
            .where(stageById.containsKey)
            .toList(growable: false),
    };
    final depths = <String, int>{};
    final visiting = <String>{};
    var hasCycle = false;

    int resolveDepth(String id) {
      final cached = depths[id];
      if (cached != null) return cached;
      if (!visiting.add(id)) {
        hasCycle = true;
        return 1;
      }
      final parents = parentsById[id] ?? const <String>[];
      final depth =
          (parents.isEmpty
                  ? 1
                  : parents.map(resolveDepth).fold<int>(1, (
                      maximum,
                      parentDepth,
                    ) {
                      return math.max(maximum, parentDepth + 1);
                    }))
              .clamp(1, 48)
              .toInt();
      visiting.remove(id);
      return depths[id] = depth;
    }

    for (final stage in stages) {
      resolveDepth(stage.node.id);
    }

    final byDepth = <int, List<RoadmapStageInfo>>{};
    for (final stage in stages) {
      byDepth.putIfAbsent(depths[stage.node.id] ?? 1, () => []).add(stage);
    }
    for (final group in byDepth.values) {
      group.sort(
        (left, right) => (sourceIndex[left.node.id] ?? 0).compareTo(
          sourceIndex[right.node.id] ?? 0,
        ),
      );
    }

    final maxDepth = byDepth.keys.fold<int>(1, math.max);
    final cardWidth = (safeWidth * 0.37).clamp(108.0, 166.0);
    final cardHeight = (72 * textScale.clamp(1, 1.65))
        .clamp(72.0, 122.0)
        .toDouble();
    const stageRadius = 31.0;
    const rootRadius = 46.0;
    const topPadding = 24.0;
    final laneSpacing = cardHeight + 10;
    final levelHeightByDepth = <int, double>{
      for (final entry in byDepth.entries)
        entry.key: math.max(150.0, entry.value.length * laneSpacing + 26),
    };
    const bottomPadding = 18.0;
    const rootLabelHeight = 34.0;
    final rootCenter = Offset(safeWidth / 2, topPadding + rootRadius);
    final nodes = <String, MobileRoadMapNodeGeometry>{};
    var levelTop = topPadding + rootRadius * 2 + rootLabelHeight + 28;

    // The visual journey ascends from its foundation to the skill. Domain
    // depth still describes prerequisites, so invert it only for coordinates.
    for (var visualDepth = 1; visualDepth <= maxDepth; visualDepth++) {
      final depth = maxDepth - visualDepth + 1;
      final group = byDepth[depth] ?? const <RoadmapStageInfo>[];
      final levelHeight = levelHeightByDepth[depth] ?? 150;
      final levelCenter = levelTop + levelHeight / 2;
      levelTop += levelHeight;
      for (var lane = 0; lane < group.length; lane++) {
        final stage = group[lane];
        final count = group.length;
        final centeredLane = lane - (count - 1) / 2;
        final laneFraction = count == 1
            ? 0.5
            : (0.22 + lane * (0.56 / math.max(1, count - 1)));
        final center = Offset(
          safeWidth * laneFraction,
          levelCenter + centeredLane * laneSpacing,
        );
        final alternateForLinearPath = depth.isEven;
        final cardOnLeft = count == 1
            ? alternateForLinearPath
            : center.dx > safeWidth / 2;
        final cardLeft = cardOnLeft ? 8.0 : safeWidth - cardWidth - 8;
        nodes[stage.node.id] = MobileRoadMapNodeGeometry(
          stage: stage,
          depth: depth,
          center: center,
          radius: stageRadius,
          cardRect: Rect.fromLTWH(
            cardLeft,
            center.dy - cardHeight / 2,
            cardWidth,
            cardHeight,
          ),
          cardOnLeft: cardOnLeft,
        );
      }
    }

    final edges = <MobileRoadMapEdgeGeometry>[];
    for (final stage in stages) {
      final child = nodes[stage.node.id]!;
      final parentIds = parentsById[stage.node.id] ?? const <String>[];
      var hasUpwardParent = false;
      for (final parentId in parentIds) {
        final parent = nodes[parentId];
        if (parent == null || parent.depth >= child.depth) continue;
        hasUpwardParent = true;
        edges.add(
          MobileRoadMapEdgeGeometry(
            fromId: parentId,
            toId: stage.node.id,
            from: parent.center,
            to: child.center,
          ),
        );
      }
      if (!hasUpwardParent) {
        edges.add(
          MobileRoadMapEdgeGeometry(
            fromId: stage.node.id,
            toId: MobileRoadMapLayoutResult.rootId,
            from: child.center,
            to: rootCenter,
          ),
        );
      }
    }

    final totalHeight = levelTop + bottomPadding;
    final traversal = stages.toList(growable: false)
      ..sort((left, right) {
        final depthOrder = (depths[left.node.id] ?? 1).compareTo(
          depths[right.node.id] ?? 1,
        );
        if (depthOrder != 0) return depthOrder;
        return (sourceIndex[left.node.id] ?? 0).compareTo(
          sourceIndex[right.node.id] ?? 0,
        );
      });

    return MobileRoadMapLayoutResult(
      size: Size(safeWidth, totalHeight),
      rootCenter: rootCenter,
      rootRadius: rootRadius,
      nodes: nodes,
      edges: edges,
      semanticTraversal: traversal,
      hasCycle: hasCycle,
      paintSignature: _paintSignature(
        size: Size(safeWidth, totalHeight),
        rootCenter: rootCenter,
        nodes: nodes,
        edges: edges,
      ),
    );
  }

  String _paintSignature({
    required Size size,
    required Offset rootCenter,
    required Map<String, MobileRoadMapNodeGeometry> nodes,
    required List<MobileRoadMapEdgeGeometry> edges,
  }) {
    final signature = StringBuffer(
      '${size.width}:${size.height}:${rootCenter.dx}:${rootCenter.dy}',
    );
    final orderedNodes = nodes.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in orderedNodes) {
      final node = entry.value;
      signature.write(
        ':${entry.key}:${node.center.dx},${node.center.dy}:${node.stage.status.name}',
      );
    }
    for (final edge in edges) {
      signature.write(
        ':${edge.fromId}>${edge.toId}:${edge.from.dx},${edge.from.dy}:${edge.to.dx},${edge.to.dy}',
      );
    }
    return signature.toString();
  }
}

class MobileRoadMapLayoutResult {
  static const rootId = '__mobile_roadmap_skill_root__';

  final Size size;
  final Offset rootCenter;
  final double rootRadius;
  final Map<String, MobileRoadMapNodeGeometry> nodes;
  final List<MobileRoadMapEdgeGeometry> edges;
  final List<RoadmapStageInfo> semanticTraversal;
  final bool hasCycle;
  final String paintSignature;

  const MobileRoadMapLayoutResult({
    required this.size,
    required this.rootCenter,
    required this.rootRadius,
    required this.nodes,
    required this.edges,
    required this.semanticTraversal,
    required this.hasCycle,
    required this.paintSignature,
  });

  factory MobileRoadMapLayoutResult.empty({required double width}) {
    return MobileRoadMapLayoutResult(
      size: Size(width, 0),
      rootCenter: Offset(width / 2, 0),
      rootRadius: 0,
      nodes: const {},
      edges: const [],
      semanticTraversal: const [],
      hasCycle: false,
      paintSignature: 'empty:$width',
    );
  }
}

class MobileRoadMapNodeGeometry {
  final RoadmapStageInfo stage;
  final int depth;
  final Offset center;
  final double radius;
  final Rect cardRect;
  final bool cardOnLeft;

  const MobileRoadMapNodeGeometry({
    required this.stage,
    required this.depth,
    required this.center,
    required this.radius,
    required this.cardRect,
    required this.cardOnLeft,
  });
}

class MobileRoadMapEdgeGeometry {
  final String fromId;
  final String toId;
  final Offset from;
  final Offset to;

  const MobileRoadMapEdgeGeometry({
    required this.fromId,
    required this.toId,
    required this.from,
    required this.to,
  });

  bool get pointsUpward => to.dy < from.dy;
}
