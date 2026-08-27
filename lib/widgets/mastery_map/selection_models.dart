part of '../mastery_map_workspace.dart';

enum _MasterySelectionType { skill, node, quest }

enum _RoadmapLayoutAxis { horizontal, vertical }

const _roadmapFocusedSkillOrbDiameter = 149.0;
const _roadmapMobileFocusedSkillOrbDiameter = 120.0;
const _roadmapSkillLabelGap = 9.0;
const _roadmapSkillLabelHeight = 46.0;
const _roadmapNodeItemWidth = 176.0;
const _roadmapNodeItemHeight = 164.0;
const _roadmapVerticalNodeLabelWidth = 196.0;
const _roadmapVerticalNodeLabelMinHeight = 58.0;
const _roadmapVerticalNodeLabelGap = 18.0;
// Centers the orb itself on the layout/painter endpoint. The remaining item
// height is reserved for the label below the orb.
const _roadmapNodeItemTopOffset = 53.5;
const _roadmapNodeLabelGap = 13.0;
const _roadmapNodeLabelWidth = 156.0;
const _roadmapNodeLabelHeight = 44.0;
const _roadmapInsertHitSize = 46.0;
const _roadmapInsertVisibleDiameter = 32.0;
const _roadmapVerticalStageStep = 170.0;

double _roadmapNodeOrbDiameter(int questTarget) => switch (questTarget) {
  <= 1 => 62.0,
  <= 3 => 74.0,
  _ => 86.0,
};

double _roadmapNodeContentHeight(SkillTreeNode node) =>
    _roadmapNodeOrbDiameter(node.questTarget) +
    _roadmapNodeLabelGap +
    _roadmapNodeLabelHeight;

double _roadmapNodeContentTopOffset(SkillTreeNode node) =>
    -_roadmapNodeItemTopOffset +
    (_roadmapNodeItemHeight - _roadmapNodeContentHeight(node)) / 2;

double _roadmapNodeOrbTopOffset(SkillTreeNode node) =>
    _roadmapNodeContentTopOffset(node);

double _roadmapNodeLabelTextBottomOffset(
  SkillTreeNode node,
  TextStyle baseTextStyle,
  TextScaler textScaler,
  TextDirection textDirection,
  _RoadmapLayoutAxis layoutAxis,
) {
  if (layoutAxis == _RoadmapLayoutAxis.vertical) {
    return _roadmapNodeOrbDiameter(node.questTarget) / 2;
  }
  final labelTop =
      _roadmapNodeContentTopOffset(node) +
      _roadmapNodeOrbDiameter(node.questTarget) +
      _roadmapNodeLabelGap;
  return labelTop +
      _roadmapLabelTextHeight(
        text: node.title,
        maxWidth: _roadmapNodeLabelWidth,
        maxLines: 2,
        fontSize: _adaptiveNodeLabelFontSize(
          node.title,
          availableWidth: _roadmapNodeLabelWidth,
          textScale: textScaler.scale(1),
        ),
        fontWeight: FontWeight.w600,
        baseTextStyle: baseTextStyle,
        textScaler: textScaler,
        textDirection: textDirection,
      );
}

double _roadmapVerticalNodeLabelHeight({
  required SkillTreeNode node,
  required String metadata,
  required TextStyle baseTextStyle,
  required TextScaler textScaler,
  required TextDirection textDirection,
}) {
  final titleHeight = _roadmapLabelTextHeight(
    text: node.title,
    maxWidth: _roadmapVerticalNodeLabelWidth,
    maxLines: 2,
    fontSize: _adaptiveNodeLabelFontSize(
      node.title,
      availableWidth: _roadmapVerticalNodeLabelWidth,
      textScale: textScaler.scale(1),
      vertical: true,
    ),
    fontWeight: FontWeight.w900,
    baseTextStyle: baseTextStyle,
    textScaler: textScaler,
    textDirection: textDirection,
    lineHeight: 1.12,
  );
  final metadataHeight = _roadmapLabelTextHeight(
    text: metadata,
    maxWidth: _roadmapVerticalNodeLabelWidth,
    maxLines: 1,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    baseTextStyle: baseTextStyle,
    textScaler: textScaler,
    textDirection: textDirection,
    lineHeight: 1.1,
  );
  return math.max(
    _roadmapVerticalNodeLabelMinHeight,
    titleHeight + 5 + metadataHeight,
  );
}

double _roadmapFocusedSkillLabelTextBottomOffset(
  Skill skill,
  TextStyle baseTextStyle,
  TextScaler textScaler,
  TextDirection textDirection, {
  double orbDiameter = _roadmapFocusedSkillOrbDiameter,
}) {
  final textHeight = _roadmapLabelTextHeight(
    text: skill.name,
    maxWidth: 190,
    maxLines: 2,
    fontSize: _adaptiveSkillLabelFontSize(
      skill.name,
      true,
      availableWidth: 190,
      textScale: textScaler.scale(1),
    ),
    fontWeight: FontWeight.w900,
    baseTextStyle: baseTextStyle,
    textScaler: textScaler,
    textDirection: textDirection,
  );
  return orbDiameter / 2 +
      _roadmapSkillLabelGap +
      (_roadmapSkillLabelHeight + textHeight) / 2;
}

double _roadmapLabelTextHeight({
  required String text,
  required double maxWidth,
  required int maxLines,
  required double fontSize,
  required FontWeight fontWeight,
  required TextStyle baseTextStyle,
  required TextScaler textScaler,
  required TextDirection textDirection,
  double lineHeight = 1.05,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: baseTextStyle.merge(
        TextStyle(
          fontSize: fontSize,
          height: lineHeight,
          fontWeight: fontWeight,
        ),
      ),
    ),
    maxLines: maxLines,
    ellipsis: '…',
    textScaler: textScaler,
    textDirection: textDirection,
  )..layout(maxWidth: maxWidth);
  final measuredHeight = painter.height;
  painter.dispose();
  return measuredHeight;
}

Color _roadmapStageStatusColor(Skill skill, SkillTreeNodeStatus status) {
  return switch (status) {
    SkillTreeNodeStatus.active => skill.color,
    SkillTreeNodeStatus.mastered =>
      skill.color == const Color(0xFF34C759)
          ? const Color(0xFF8E8E93)
          : skillTreeNodeStatusColor[SkillTreeNodeStatus.mastered]!,
    SkillTreeNodeStatus.locked =>
      skillTreeNodeStatusColor[SkillTreeNodeStatus.locked]!,
  };
}

class _MasterySelection {
  final _MasterySelectionType type;
  final String skillId;
  final String? nodeId;
  final String? taskId;

  const _MasterySelection.skill(this.skillId)
    : type = _MasterySelectionType.skill,
      nodeId = null,
      taskId = null;

  const _MasterySelection.node(this.skillId, this.nodeId)
    : type = _MasterySelectionType.node,
      taskId = null;

  const _MasterySelection.quest(this.skillId, this.nodeId, this.taskId)
    : type = _MasterySelectionType.quest;
}

enum _QuestEditOrigin { standard, stageInspector }

class _QuestEditNavigation {
  final _QuestEditOrigin origin;
  final String? stageId;

  const _QuestEditNavigation.standard()
    : origin = _QuestEditOrigin.standard,
      stageId = null;

  const _QuestEditNavigation.stageInspector(this.stageId)
    : origin = _QuestEditOrigin.stageInspector;

  factory _QuestEditNavigation.fromSelection(
    _MasterySelection? selection,
    Skill skill,
  ) {
    if (selection?.type == _MasterySelectionType.node &&
        selection?.skillId == skill.id &&
        selection?.nodeId != null) {
      return _QuestEditNavigation.stageInspector(selection!.nodeId);
    }
    return const _QuestEditNavigation.standard();
  }

  _MasterySelection savedSelection({
    required Skill skill,
    required Task task,
    required String? savedStageId,
  }) {
    final originalStageId = stageId;
    if (origin == _QuestEditOrigin.stageInspector &&
        originalStageId != null &&
        skill.treeNodes.any((node) => node.id == originalStageId)) {
      return _MasterySelection.node(skill.id, originalStageId);
    }
    return savedStageId == null
        ? _MasterySelection.skill(skill.id)
        : _MasterySelection.quest(skill.id, savedStageId, task.id);
  }
}

List<Task> _sortedActiveQuests(Iterable<Task> tasks) {
  final list = tasks.toList();
  list.sort((a, b) {
    final priority = a.priority.index.compareTo(b.priority.index);
    if (priority != 0) return priority;
    return b.updatedAt.compareTo(a.updatedAt);
  });
  return list;
}

List<Task> _sortedCompletedQuests(Iterable<Task> tasks) {
  final list = tasks.toList();
  list.sort((a, b) => _questSortDate(b).compareTo(_questSortDate(a)));
  return list;
}

DateTime _questSortDate(Task task) => task.lastCompletedAt ?? task.updatedAt;

double _adaptiveSkillLabelFontSize(
  String text,
  bool selected, {
  double availableWidth = 190,
  double textScale = 1,
}) {
  final length = text.trim().length;
  final base = selected ? 20.0 : 17.0;
  final widthFactor = availableWidth < 150 ? 0.92 : 1.0;
  final scaleFactor = textScale >= 1.8
      ? 0.84
      : textScale >= 1.4
      ? 0.92
      : 1.0;
  final lengthFactor = length <= 16
      ? 1.0
      : length <= 26
      ? 0.92
      : 0.84;
  return (base * widthFactor * scaleFactor * lengthFactor).clamp(14.0, base);
}

double _adaptiveNodeLabelFontSize(
  String text, {
  double availableWidth = _roadmapNodeLabelWidth,
  double textScale = 1,
  bool vertical = false,
}) {
  final length = text.trim().length;
  final base = vertical ? 17.0 : 16.0;
  final widthFactor = availableWidth < 140 ? 0.9 : 1.0;
  final scaleFactor = textScale >= 1.8
      ? 0.84
      : textScale >= 1.4
      ? 0.92
      : 1.0;
  final lengthFactor = length <= 18
      ? 1.0
      : length <= 30
      ? 0.92
      : 0.84;
  return (base * widthFactor * scaleFactor * lengthFactor).clamp(13.5, base);
}
