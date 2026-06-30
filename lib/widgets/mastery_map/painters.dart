part of '../mastery_map_workspace.dart';

class _OrbMasteryMapPainter extends CustomPainter {
  final _OrbCanvasLayout layout;
  final bool isDark;

  const _OrbMasteryMapPainter({required this.layout, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final selectedSkill = layout.selectedSkill;
    final selectedCenter = selectedSkill == null
        ? null
        : layout.skillPositions[selectedSkill];
    if (selectedSkill == null || selectedCenter == null) return;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          selectedSkill.color.withAlpha(isDark ? 38 : 30),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: selectedCenter, radius: 300));
    canvas.drawCircle(selectedCenter, 300, glowPaint);

    for (final road in layout.pathLayout.paths) {
      for (var index = 0; index < road.nodes.length - 1; index++) {
        final fromNode = road.nodes[index];
        final toNode = road.nodes[index + 1];
        final from = layout.nodePositions[fromNode.id];
        final to = layout.nodePositions[toNode.id];
        if (from == null || to == null) continue;
        _drawRoadConnection(
          canvas,
          selectedSkill,
          from,
          to,
          fromRadius: _nodeOrbRadius(fromNode),
          toRadius: _nodeOrbRadius(toNode),
          status: selectedSkill.treeNodeStatus(toNode),
        );
      }

      final terminal = road.terminalStage;
      if (terminal == null) continue;
      final terminalPosition = layout.nodePositions[terminal.id];
      if (terminalPosition == null) continue;
      _drawRoadConnection(
        canvas,
        selectedSkill,
        terminalPosition,
        selectedCenter,
        fromRadius: _nodeOrbRadius(terminal),
        toRadius: _skillOrbRadius,
        status: selectedSkill.treeNodeStatus(terminal),
      );
    }
  }

  double get _skillOrbRadius => 70;

  double _nodeOrbRadius(SkillTreeNode node) {
    final target = node.questTarget;
    return switch (target) {
      <= 1 => 27.0,
      <= 3 => 32.0,
      _ => 37.0,
    };
  }

  Offset _edgePoint(Offset from, Offset to, double radius) {
    final delta = to - from;
    final distance = delta.distance;
    if (distance == 0) return from;
    return from + delta / distance * radius;
  }

  void _drawRoadConnection(
    Canvas canvas,
    Skill skill,
    Offset from,
    Offset to, {
    required double fromRadius,
    required double toRadius,
    required SkillTreeNodeStatus status,
  }) {
    final start = _edgePoint(from, to, fromRadius);
    final end = _edgePoint(to, from, toRadius);
    final color = _roadmapStageStatusColor(skill, status);
    final alpha = switch (status) {
      SkillTreeNodeStatus.locked => 50,
      SkillTreeNodeStatus.active => 140,
      SkillTreeNodeStatus.mastered => 118,
    };
    final width = switch (status) {
      SkillTreeNodeStatus.locked => 1.45,
      SkillTreeNodeStatus.active => 2.4,
      SkillTreeNodeStatus.mastered => 2.05,
    };
    final path = _roadConnectionPath(start, end, layout.layoutAxis);
    final glowPaint = Paint()
      ..color = color.withAlpha(status == SkillTreeNodeStatus.active ? 24 : 12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  Path _roadConnectionPath(
    Offset start,
    Offset end,
    _RoadmapLayoutAxis layoutAxis,
  ) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) {
      return Path()..moveTo(start.dx, start.dy);
    }
    final c1 = layoutAxis == _RoadmapLayoutAxis.vertical
        ? Offset(start.dx, start.dy + delta.dy * 0.38)
        : Offset(start.dx + distance * 0.38, start.dy);
    final c2 = layoutAxis == _RoadmapLayoutAxis.vertical
        ? Offset(end.dx, end.dy - delta.dy * 0.38)
        : Offset(end.dx - distance * 0.38, end.dy);
    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
  }

  @override
  bool shouldRepaint(covariant _OrbMasteryMapPainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.isDark != isDark;
  }
}

class _MasteryVectorGridPainter extends CustomPainter {
  final bool isDark;

  const _MasteryVectorGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    _drawVectorGrid(canvas, size);
  }

  void _drawVectorGrid(Canvas canvas, Size size) {
    const minorCell = 42.0;
    const majorEvery = 5;
    const majorCell = minorCell * majorEvery;
    final gridColor = isDark ? Colors.white : const Color(0xFF756A58);
    final minorPaint = Paint()
      ..color = gridColor.withAlpha(isDark ? 13 : 10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..isAntiAlias = true;
    final majorPaint = Paint()
      ..color = gridColor.withAlpha(isDark ? 39 : 26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..isAntiAlias = true;
    final crossPaint = Paint()
      ..color = gridColor.withAlpha(isDark ? 112 : 68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final dotPaint = Paint()
      ..color = gridColor.withAlpha(isDark ? 86 : 52)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (var x = 0.0; x <= size.width; x += minorCell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
    }
    for (var y = 0.0; y <= size.height; y += minorCell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
    }

    for (var x = 0.0; x <= size.width; x += majorCell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
    }
    for (var y = 0.0; y <= size.height; y += majorCell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorPaint);
    }

    for (var x = 0.0; x <= size.width; x += majorCell) {
      for (var y = 0.0; y <= size.height; y += majorCell) {
        _drawGridCross(canvas, Offset(x, y), crossPaint);
      }
    }

    for (var x = majorCell / 2; x < size.width; x += majorCell) {
      for (var y = majorCell / 2; y < size.height; y += majorCell) {
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }
  }

  void _drawGridCross(Canvas canvas, Offset center, Paint paint) {
    const half = 5.0;
    canvas.drawLine(
      Offset(center.dx - half, center.dy),
      Offset(center.dx + half, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - half),
      Offset(center.dx, center.dy + half),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MasteryVectorGridPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
