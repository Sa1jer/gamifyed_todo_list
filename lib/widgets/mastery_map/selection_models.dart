part of '../mastery_map_workspace.dart';

enum _MasterySelectionType { skill, node, quest }

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
