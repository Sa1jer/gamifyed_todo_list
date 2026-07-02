part of '../mastery_map_workspace.dart';

enum _MasterySelectionType { skill, node, quest }

enum _RoadmapLayoutAxis { horizontal, vertical }

const _roadmapFocusedSkillOrbDiameter = 149.0;
const _roadmapMobileFocusedSkillOrbDiameter = 120.0;
const _roadmapSkillLabelGap = 9.0;
const _roadmapSkillLabelHeight = 46.0;
const _roadmapNodeItemWidth = 154.0;
const _roadmapNodeItemHeight = 151.0;
const _roadmapNodeItemTopOffset = 50.0;
const _roadmapNodeLabelGap = 13.0;
const _roadmapNodeLabelWidth = 108.0;
const _roadmapNodeLabelHeight = 30.0;
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
) {
  final labelTop =
      _roadmapNodeContentTopOffset(node) +
      _roadmapNodeOrbDiameter(node.questTarget) +
      _roadmapNodeLabelGap;
  return labelTop +
      _roadmapLabelTextHeight(
        text: node.title,
        maxWidth: _roadmapNodeLabelWidth,
        maxLines: 2,
        fontSize: _adaptiveNodeLabelFontSize(node.title),
        fontWeight: FontWeight.w600,
        baseTextStyle: baseTextStyle,
        textScaler: textScaler,
        textDirection: textDirection,
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
    fontSize: _adaptiveSkillLabelFontSize(skill.name, true),
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
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: baseTextStyle.merge(
        TextStyle(fontSize: fontSize, height: 1.05, fontWeight: fontWeight),
      ),
    ),
    maxLines: maxLines,
    ellipsis: '…',
    textScaler: textScaler,
    textDirection: textDirection,
  )..layout(maxWidth: maxWidth);
  final height = painter.height;
  painter.dispose();
  return height;
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

double _adaptiveSkillLabelFontSize(String text, bool selected) {
  final length = text.trim().length;
  final base = selected ? 14.5 : 13.5;
  if (length <= 10) return base;
  if (length <= 16) return base - 1.0;
  if (length <= 24) return base - 2.1;
  return base - 3.0;
}

double _adaptiveQuestTitleFontSize(String text) {
  final length = text.trim().length;
  if (length <= 24) return 13.2;
  if (length <= 42) return 12.6;
  return 12.0;
}

double _adaptiveInspectorTitleFontSize(String text) {
  final length = text.trim().length;
  if (length <= 18) return 17.0;
  if (length <= 32) return 15.8;
  return 14.8;
}

double _adaptiveNodeLabelFontSize(String text) {
  final length = text.trim().length;
  if (length <= 10) return 12.0;
  if (length <= 18) return 11.2;
  if (length <= 26) return 10.5;
  return 10.0;
}
