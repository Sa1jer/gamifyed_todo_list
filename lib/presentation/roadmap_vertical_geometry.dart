import 'package:flutter/widgets.dart';

enum VerticalRoadmapLabelSide { left, right }

@immutable
class VerticalRoadmapNodeGeometry {
  const VerticalRoadmapNodeGeometry({
    required this.nodeId,
    required this.orbCenter,
    required this.orbRect,
    required this.labelRect,
    required this.labelSide,
  });

  factory VerticalRoadmapNodeGeometry.fromCenter({
    required String nodeId,
    required Offset orbCenter,
    required double orbDiameter,
    required Size labelSize,
    required VerticalRoadmapLabelSide labelSide,
    required double labelGap,
  }) {
    final orbRect = Rect.fromCircle(center: orbCenter, radius: orbDiameter / 2);
    final labelLeft = labelSide == VerticalRoadmapLabelSide.left
        ? orbRect.left - labelGap - labelSize.width
        : orbRect.right + labelGap;
    final labelRect = Rect.fromLTWH(
      labelLeft,
      orbCenter.dy - labelSize.height / 2,
      labelSize.width,
      labelSize.height,
    );
    return VerticalRoadmapNodeGeometry(
      nodeId: nodeId,
      orbCenter: orbCenter,
      orbRect: orbRect,
      labelRect: labelRect,
      labelSide: labelSide,
    );
  }

  final String nodeId;
  final Offset orbCenter;
  final Rect orbRect;
  final Rect labelRect;
  final VerticalRoadmapLabelSide labelSide;

  Rect get contentRect => orbRect.expandToInclude(labelRect);

  VerticalRoadmapNodeGeometry translatedTo(Offset nextOrbCenter) {
    final delta = nextOrbCenter - orbCenter;
    return VerticalRoadmapNodeGeometry(
      nodeId: nodeId,
      orbCenter: nextOrbCenter,
      orbRect: orbRect.shift(delta),
      labelRect: labelRect.shift(delta),
      labelSide: labelSide,
    );
  }
}
