import 'package:flutter/material.dart';

import '../utils.dart';

enum Priority { high, medium, low }

const priorityLabel = {
  Priority.high: 'Высокий',
  Priority.medium: 'Средний',
  Priority.low: 'Низкий',
};

const priorityColor = {
  Priority.high: Color(0xFFFF3B30),
  Priority.medium: Color(0xFFFF9500),
  Priority.low: Color(0xFF4A9EFF),
};

// ─── Task ─────────────────────────────────────────────────────────────────────

const String kInboxSkillId = '__system_inbox_skill__';

class Task {
  final String id;
  String title;
  String? _description;
  String? _skillId;
  int xpReward;
  TaskType type;
  bool isDone;
  bool isArchived;
  int streak;
  int earnedXP;
  RepeatFrequency repeatFrequency;
  int repeatCustomDays;
  DateTime? nextResetAt;
  DateTime? lastCompletedAt;
  Priority priority;
  String minimumAction;
  DateTime? minimumActionDoneAt;
  int minimumActionEarnedXP;
  int bonusXpEarned;
  List<String> consumedBuffIds;
  List<String> subtasks;
  List<bool> subtaskDone;
  List<String> tags;
  String? treeNodeId;
  bool notificationsEnabled;
  int? notificationHour;
  int? notificationMinute;
  DateTime createdAt;
  DateTime updatedAt;

  String get description => _description ?? '';
  set description(String value) => _description = value.trim();

  String get skillId {
    final normalized = _skillId?.trim();
    return normalized == null || normalized.isEmpty
        ? kInboxSkillId
        : normalized;
  }

  set skillId(String value) => _skillId = value;

  Task({
    required this.id,
    required this.title,
    String description = '',
    required String skillId,
    required this.xpReward,
    required this.type,
    this.isDone = false,
    this.isArchived = false,
    this.streak = 0,
    this.earnedXP = 0,
    this.repeatFrequency = RepeatFrequency.daily,
    this.repeatCustomDays = 1,
    this.nextResetAt,
    this.lastCompletedAt,
    this.priority = Priority.medium,
    this.minimumAction = '',
    this.minimumActionDoneAt,
    this.minimumActionEarnedXP = 0,
    this.bonusXpEarned = 0,
    List<String>? consumedBuffIds,
    List<String>? subtasks,
    List<bool>? subtaskDone,
    List<String>? tags,
    this.treeNodeId,
    this.notificationsEnabled = false,
    this.notificationHour,
    this.notificationMinute,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : _description = description.trim(),
       _skillId = skillId,
       subtasks = List.of(subtasks ?? const <String>[]),
       consumedBuffIds = List.of(consumedBuffIds ?? const <String>[]),
       subtaskDone = List.of(
         subtaskDone ?? List.filled((subtasks ?? []).length, false),
       ),
       tags = List.of(tags ?? const <String>[]),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now() {
    normalizeScope();
  }

  bool get isInbox => skillId == kInboxSkillId;

  bool get isSkillTask => skillId.trim().isNotEmpty && !isInbox;

  void normalizeScope() {
    if (!isDone) isArchived = false;
    if ((_skillId?.trim().isEmpty ?? true)) {
      skillId = kInboxSkillId;
    }
    if (isInbox) {
      treeNodeId = null;
      xpReward = 0;
      type = TaskType.shortTerm;
      repeatFrequency = RepeatFrequency.daily;
      repeatCustomDays = 1;
      minimumAction = '';
      minimumActionDoneAt = null;
      minimumActionEarnedXP = 0;
      bonusXpEarned = 0;
      consumedBuffIds = <String>[];
      notificationsEnabled = false;
      notificationHour = null;
      notificationMinute = null;
    }

    final hour = notificationHour;
    final minute = notificationMinute;
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      notificationsEnabled = false;
      notificationHour = null;
      notificationMinute = null;
    }
  }

  int get activeMultiplier {
    if (type != TaskType.repeating) return 1;
    return multiplierForStreak(streak);
  }

  bool get showStreakBadge =>
      type == TaskType.repeating && streak >= 2 && !isDone;

  bool get hasMinimumAction => minimumAction.trim().isNotEmpty;

  bool get isMinimumActionDone =>
      minimumActionDoneAt != null && minimumActionEarnedXP > 0;

  int get subtaskCompletedCount => subtaskDone.where((v) => v).length;

  void syncSubtaskDone() {
    while (subtaskDone.length < subtasks.length) {
      subtaskDone.add(false);
    }
    while (subtaskDone.length > subtasks.length) {
      subtaskDone.removeLast();
    }
  }
}
