import 'dart:convert';
import 'dart:typed_data';

import '../models/achievement_models.dart';
import '../models/activity_models.dart';
import '../models/reward_models.dart';
import '../models/skill_models.dart';
import '../models/task_models.dart';
import '../models/user_profile.dart';
import '../utils.dart';

/// Legacy-compatible JSON codec for persisted Hive payloads.
///
/// Payload keys and fallback semantics intentionally remain unchanged.
class LegacyStorageCodec {
  const LegacyStorageCodec();

  static const int _maxJsonDecodeDepth = 64;

  T? decodeOrNull<T>(String raw, T Function(String raw) decode) =>
      _decodeOrNull(raw, decode);
  Map<String, dynamic> decodeMap(String raw) => _decodeMap(raw);
  String encodeSkill(Skill value) => _encodeSkill(value);
  Skill decodeSkill(String raw) => _decodeSkill(raw);
  String encodeTask(Task value) => _encodeTask(value);
  Task decodeTask(String raw) => _decodeTask(raw);
  String encodeProfile(UserProfile value) => _encodeProfile(value);
  UserProfile decodeProfile(String raw) => _decodeProfile(raw);
  String encodeHistoryEntry(HistoryEntry value) => _encodeHistoryEntry(value);
  HistoryEntry decodeHistoryEntry(String raw) => _decodeHistoryEntry(raw);
  Map<String, dynamic> encodeDailyStats(DailyStats value) =>
      _encodeDailyStats(value);
  DailyStats decodeDailyStats(Map<String, dynamic> value) =>
      _decodeDailyStats(value);
  String encodeAchievement(Achievement value) => _encodeAchievement(value);
  Achievement decodeAchievement(String raw) => _decodeAchievement(raw);
  String encodeBoss(Boss value) => _encodeBoss(value);
  Boss decodeBoss(String raw) => _decodeBoss(raw);
  String encodeRewardChest(RewardChest value) => _encodeRewardChest(value);
  RewardChest decodeRewardChest(String raw) => _decodeRewardChest(raw);
  String encodeBuff(Buff value) => _encodeBuff(value);
  Buff decodeBuff(String raw) => _decodeBuff(raw);
  String encodeWeeklyGoal(WeeklyGoal value) => _encodeWeeklyGoal(value);
  WeeklyGoal decodeWeeklyGoal(String raw) => _decodeWeeklyGoal(raw);

  T? _decodeOrNull<T>(String raw, T Function(String raw) decode) {
    try {
      return decode(raw);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decodeMap(String raw) {
    final decoded = jsonDecode(raw);
    if (!_jsonDepthWithinLimit(decoded)) {
      throw const FormatException('Storage JSON payload is too deeply nested.');
    }
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const FormatException('Storage JSON payload must be an object.');
  }

  bool _jsonDepthWithinLimit(Object? root) {
    final stack = <({Object? value, int depth})>[(value: root, depth: 1)];
    while (stack.isNotEmpty) {
      final item = stack.removeLast();
      if (item.depth > _maxJsonDecodeDepth) return false;
      switch (item.value) {
        case final Map map:
          for (final value in map.values) {
            stack.add((value: value, depth: item.depth + 1));
          }
        case final List list:
          for (final value in list) {
            stack.add((value: value, depth: item.depth + 1));
          }
      }
    }
    return true;
  }

  String _readString(
    Map<String, dynamic> data,
    String key, [
    String fallback = '',
  ]) {
    final value = data[key];
    if (value is String) return value;
    return fallback;
  }

  String? _readNullableString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  int _readInt(Map<String, dynamic> data, String key, [int fallback = 0]) {
    final value = data[key];
    return _readNullableIntValue(value) ?? fallback;
  }

  int? _readNullableInt(Map<String, dynamic> data, String key) {
    return _readNullableIntValue(data[key]);
  }

  int? _readNullableIntValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _readNullableDouble(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int _readPositiveInt(
    Map<String, dynamic> data,
    String key, [
    int fallback = 1,
  ]) {
    final value = _readInt(data, key, fallback);
    return value < 1 ? fallback : value;
  }

  bool _readBool(
    Map<String, dynamic> data,
    String key, [
    bool fallback = false,
  ]) {
    final value = data[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  List<String> _readStringList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! List) return [];
    return value.whereType<String>().toList();
  }

  List<bool> _readBoolList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! List) return [];
    return value.map((item) {
      if (item is bool) return item;
      if (item is String) return item.toLowerCase() == 'true';
      return false;
    }).toList();
  }

  List<int> _readIntList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! List) return [];
    return value
        .map(_readNullableIntValue)
        .whereType<int>()
        .toList(growable: false);
  }

  DateTime? _readDate(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Uint8List? _readBytes(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) return null;
    try {
      final bytes = base64Decode(value);
      return hasSupportedImageMagicBytes(bytes) ? bytes : null;
    } catch (_) {
      return null;
    }
  }

  T _readEnum<T extends Enum>(List<T> values, Object? raw, T fallback) {
    if (raw is String) {
      final byName = values.where((value) => value.name == raw).firstOrNull;
      if (byName != null) return byName;
    }

    final index = raw is int
        ? raw
        : raw is num
        ? raw.toInt()
        : raw is String
        ? int.tryParse(raw)
        : null;
    if (index == null || index < 0 || index >= values.length) return fallback;
    return values[index];
  }

  String _encodeProfile(UserProfile profile) {
    final data = {
      'name': profile.name,
      'level': profile.level,
      'xp': profile.xp,
      'totalXpEarned': profile.totalXpEarned,
      'age': profile.age,
      'gender': profile.gender?.name,
      'avatarBytes': profile.avatarBytes != null
          ? base64Encode(profile.avatarBytes!)
          : null,
      'bannerBytes': profile.bannerBytes != null
          ? base64Encode(profile.bannerBytes!)
          : null,
      'streakProtectionCharges': profile.streakProtectionCharges,
      'streakProtectionRefilledAt': profile.streakProtectionRefilledAt
          ?.toIso8601String(),
      'lastStreakProtectionUsedAt': profile.lastStreakProtectionUsedAt
          ?.toIso8601String(),
      'lastStreakProtectionTaskTitle': profile.lastStreakProtectionTaskTitle,
    };
    return jsonEncode(data);
  }

  UserProfile _decodeProfile(String raw) {
    final data = _decodeOrNull(raw, _decodeMap);
    if (data == null) {
      return UserProfile(name: 'Your Name');
    }
    return UserProfile(
      name: _readString(data, 'name', 'Your Name'),
      level: _readInt(data, 'level', 1),
      xp: _readInt(data, 'xp'),
      totalXpEarned: _readInt(data, 'totalXpEarned'),
      age: data['age'] == null ? null : _readInt(data, 'age'),
      gender: data['gender'] == null
          ? null
          : _readEnum(Gender.values, data['gender'], Gender.nonBinary),
      avatarBytes: _readBytes(data, 'avatarBytes'),
      bannerBytes: _readBytes(data, 'bannerBytes'),
      streakProtectionCharges: _readInt(data, 'streakProtectionCharges', 1),
      streakProtectionRefilledAt: _readDate(data, 'streakProtectionRefilledAt'),
      lastStreakProtectionUsedAt: _readDate(data, 'lastStreakProtectionUsedAt'),
      lastStreakProtectionTaskTitle: _readNullableString(
        data,
        'lastStreakProtectionTaskTitle',
      ),
    );
  }

  String _encodeSkill(Skill s) => jsonEncode({
    'id': s.id,
    'name': s.name,
    'goal': s.goal,
    'goalSpec': _encodeGoalSpec(s.goalSpec),
    'checklist': s.checklist,
    'checklistDone': s.checklistDone,
    'treeNodes': s.treeNodes.map(_encodeSkillTreeNode).toList(),
    'completedGoals': s.completedGoals.map(_encodeCompletedGoal).toList(),
    'completedRoadmaps': s.completedRoadmaps
        .map(_encodeCompletedRoadmap)
        .toList(),
    'triggeredGoalMilestones': s.triggeredGoalMilestones,
    'color': storageArgbFromColor(s.color),
    'iconName': s.icon.codePoint.toString(),
    'level': s.level,
    'xp': s.xp,
  });

  Skill _decodeSkill(String json) {
    final d = _decodeMap(json);
    final iconName = _readString(d, 'iconName', _readString(d, 'icon', ''));
    final legacyGoal = _readString(d, 'goal');
    final goalSpec = _decodeGoalSpec(d['goalSpec'], legacyGoal);
    return Skill(
      id: _readString(d, 'id', uid()),
      name: _readString(d, 'name', 'Навык'),
      goal: legacyGoal,
      goalSpec: goalSpec,
      checklist: _readStringList(d, 'checklist'),
      checklistDone: _readBoolList(d, 'checklistDone'),
      treeNodes:
          (d['treeNodes'] as List?)
              ?.whereType<Map>()
              .map(
                (raw) => _decodeSkillTreeNode(Map<String, dynamic>.from(raw)),
              )
              .toList() ??
          [],
      completedGoals:
          (d['completedGoals'] as List?)
              ?.whereType<Map>()
              .map(_decodeCompletedGoal)
              .whereType<CompletedGoal>()
              .toList() ??
          [],
      completedRoadmaps:
          ((d['completedRoadmaps'] ?? d['completedRoadMaps']) as List?)
              ?.whereType<Map>()
              .map(_decodeCompletedRoadmap)
              .whereType<CompletedRoadmap>()
              .toList() ??
          [],
      triggeredGoalMilestones: _readIntList(
        d,
        'triggeredGoalMilestones',
      ).where(_isKnownGoalMilestonePercent).toSet().toList(),
      color: storageColorFromArgb(_readInt(d, 'color', 0xFF4A9EFF)),
      icon: storageIconFromCodePoint(iconName),
      level: _readInt(d, 'level', 1),
      xp: _readInt(d, 'xp'),
    );
  }

  bool _isKnownGoalMilestonePercent(int percent) {
    return GoalMilestone.values.any(
      (milestone) => milestone.percent == percent,
    );
  }

  Map<String, dynamic> _encodeGoalSpec(GoalSpec goal) => {
    'text': goal.text,
    'deadline': goal.deadline?.toIso8601String(),
    'metric': goal.metric,
    'targetValue': goal.targetValue,
    'currentValue': goal.currentValue,
    'reviews': goal.reviews.map(_encodeGoalReviewEntry).toList(),
    'updatedAt': goal.updatedAt.toIso8601String(),
  };

  GoalSpec _decodeGoalSpec(Object? raw, String legacyGoal) {
    final data = switch (raw) {
      final Map map => Map<String, dynamic>.from(map),
      final String value when value.isNotEmpty => _decodeOrNull(
        value,
        _decodeMap,
      ),
      _ => null,
    };

    if (data == null) {
      return GoalSpec(text: legacyGoal);
    }

    final rawText = data['text'];
    final text = rawText is String && rawText.isNotEmpty ? rawText : legacyGoal;
    final rawReviews = data['reviews'];

    return GoalSpec(
      text: text,
      deadline: _readDate(data, 'deadline'),
      metric: _readNullableString(data, 'metric'),
      targetValue: _readNullableDouble(data, 'targetValue'),
      currentValue: _readNullableDouble(data, 'currentValue'),
      reviews: rawReviews is List
          ? rawReviews.whereType<Map>().map(_decodeGoalReviewEntry).toList()
          : [],
      updatedAt: _readDate(data, 'updatedAt') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _encodeGoalReviewEntry(GoalReviewEntry review) => {
    'id': review.id,
    'createdAt': review.createdAt.toIso8601String(),
    'wins': review.wins,
    'blockers': review.blockers,
    'adjustment': review.adjustment,
    'nextFocus': review.nextFocus,
    'updatedPlan': review.updatedPlan,
  };

  GoalReviewEntry _decodeGoalReviewEntry(Map<dynamic, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw);
    return GoalReviewEntry(
      id: _readString(data, 'id', uid()),
      createdAt: _readDate(data, 'createdAt') ?? DateTime.now(),
      wins: _readString(data, 'wins'),
      blockers: _readString(data, 'blockers'),
      adjustment: _readString(data, 'adjustment'),
      nextFocus: _readString(data, 'nextFocus'),
      updatedPlan: _readBool(data, 'updatedPlan'),
    );
  }

  Map<String, dynamic> _encodeCompletedGoal(CompletedGoal goal) => {
    'id': goal.id,
    'skillId': goal.skillId,
    'goalText': goal.goalText,
    'completedAt': goal.completedAt.toIso8601String(),
    'progressAtCompletion': goal.progressAtCompletion,
    'completedStages': goal.completedStages,
    'totalStages': goal.totalStages,
  };

  CompletedGoal? _decodeCompletedGoal(Map<dynamic, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw);
    final id = _readString(data, 'id').trim();
    final skillId = _readString(data, 'skillId').trim();
    final goalText = _readString(data, 'goalText').trim();
    final completedAt = _readDate(data, 'completedAt');
    if (id.isEmpty ||
        skillId.isEmpty ||
        goalText.isEmpty ||
        completedAt == null) {
      return null;
    }

    final totalStages = _readInt(data, 'totalStages').clamp(0, 1 << 30);
    final completedStages = _readInt(
      data,
      'completedStages',
    ).clamp(0, totalStages);
    final progress = (_readNullableDouble(data, 'progressAtCompletion') ?? 0.0)
        .clamp(0.0, 1.0);
    return CompletedGoal(
      id: id,
      skillId: skillId,
      goalText: goalText,
      completedAt: completedAt,
      progressAtCompletion: progress,
      completedStages: completedStages,
      totalStages: totalStages,
    );
  }

  Map<String, dynamic> _encodeCompletedRoadmap(CompletedRoadmap roadmap) => {
    'id': roadmap.id,
    'skillId': roadmap.skillId,
    'completedGoalId': roadmap.completedGoalId,
    'goalText': roadmap.goalText,
    'completedAt': roadmap.completedAt.toIso8601String(),
    'progressAtCompletion': roadmap.progressAtCompletion,
    'completedStages': roadmap.completedStages,
    'totalStages': roadmap.totalStages,
    'stages': roadmap.stages.map(_encodeRoadmapStageSnapshot).toList(),
  };

  CompletedRoadmap? _decodeCompletedRoadmap(Map<dynamic, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw);
    final id = _readString(data, 'id').trim();
    final skillId = _readString(data, 'skillId').trim();
    final goalText = _readString(data, 'goalText').trim();
    final completedAt = _readDate(data, 'completedAt');
    if (id.isEmpty ||
        skillId.isEmpty ||
        goalText.isEmpty ||
        completedAt == null) {
      return null;
    }

    final stages =
        (data['stages'] as List?)
            ?.whereType<Map>()
            .map(_decodeRoadmapStageSnapshot)
            .whereType<RoadmapStageSnapshot>()
            .toList() ??
        <RoadmapStageSnapshot>[];
    final totalStages = _readInt(
      data,
      'totalStages',
      stages.length,
    ).clamp(0, 1 << 30);
    final completedStages = _readInt(
      data,
      'completedStages',
      stages.where((stage) => stage.isMastered).length,
    ).clamp(0, totalStages);
    final progress = (_readNullableDouble(data, 'progressAtCompletion') ?? 0.0)
        .clamp(0.0, 1.0);

    return CompletedRoadmap(
      id: id,
      skillId: skillId,
      completedGoalId: _readNullableString(data, 'completedGoalId'),
      goalText: goalText,
      completedAt: completedAt,
      progressAtCompletion: progress,
      completedStages: completedStages,
      totalStages: totalStages,
      stages: stages,
    );
  }

  Map<String, dynamic> _encodeRoadmapStageSnapshot(
    RoadmapStageSnapshot stage,
  ) => {
    'id': stage.id,
    'title': stage.title,
    'description': stage.description,
    'xpReward': stage.xpReward,
    'requiredQuestCompletions': stage.requiredQuestCompletions,
    'prerequisiteIds': stage.prerequisiteIds,
    'checklist': stage.checklist,
    'checklistDone': stage.checklistDone,
    'isMastered': stage.isMastered,
    'masteredAt': stage.masteredAt?.toIso8601String(),
  };

  RoadmapStageSnapshot? _decodeRoadmapStageSnapshot(Map<dynamic, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw);
    final id = _readString(data, 'id').trim();
    if (id.isEmpty) return null;

    return RoadmapStageSnapshot(
      id: id,
      title: _readString(data, 'title', 'Этап RoadMap'),
      description: _readString(data, 'description'),
      xpReward: _readInt(data, 'xpReward', 20),
      requiredQuestCompletions: _readInt(data, 'requiredQuestCompletions', 3),
      prerequisiteIds: _readStringList(data, 'prerequisiteIds'),
      checklist: _readStringList(data, 'checklist'),
      checklistDone: _readBoolList(data, 'checklistDone'),
      isMastered: _readBool(data, 'isMastered'),
      masteredAt: _readDate(data, 'masteredAt'),
    );
  }

  Map<String, dynamic> _encodeSkillTreeNode(SkillTreeNode node) => {
    'id': node.id,
    'title': node.title,
    'description': node.description,
    'xpReward': node.xpReward,
    'requiredQuestCompletions': node.requiredQuestCompletions,
    'prerequisiteIds': node.prerequisiteIds,
    'checklist': node.checklist,
    'checklistDone': node.checklistDone,
    'isMastered': node.isMastered,
    'masteredAt': node.masteredAt?.toIso8601String(),
  };

  SkillTreeNode _decodeSkillTreeNode(Map<String, dynamic> d) {
    return SkillTreeNode(
      id: _readString(d, 'id', uid()),
      title: _readString(d, 'title', 'Этап навыка'),
      description: _readString(d, 'description'),
      xpReward: _readInt(d, 'xpReward', 20),
      requiredQuestCompletions: _readInt(d, 'requiredQuestCompletions', 3),
      prerequisiteIds: _readStringList(d, 'prerequisiteIds'),
      checklist: _readStringList(d, 'checklist'),
      checklistDone: _readBoolList(d, 'checklistDone'),
      isMastered: _readBool(d, 'isMastered'),
      masteredAt: _readDate(d, 'masteredAt'),
    );
  }

  String _encodeTask(Task t) => jsonEncode({
    'id': t.id,
    'title': t.title,
    'description': t.description,
    'skillId': t.skillId,
    'xpReward': t.xpReward,
    'type': t.type.name,
    'isDone': t.isDone,
    'isArchived': t.isArchived,
    'streak': t.streak,
    'earnedXP': t.earnedXP,
    'repeatFrequency': t.repeatFrequency.name,
    'repeatCustomDays': t.repeatCustomDays,
    'nextResetAt': t.nextResetAt?.toIso8601String(),
    'lastCompletedAt': t.lastCompletedAt?.toIso8601String(),
    'priority': t.priority.name,
    'minimumAction': t.minimumAction,
    'minimumActionDoneAt': t.minimumActionDoneAt?.toIso8601String(),
    'minimumActionEarnedXP': t.minimumActionEarnedXP,
    'bonusXpEarned': t.bonusXpEarned,
    'consumedBuffIds': t.consumedBuffIds,
    'subtasks': t.subtasks,
    'subtaskDone': t.subtaskDone,
    'tags': t.tags,
    'treeNodeId': t.treeNodeId,
    'notificationsEnabled': t.notificationsEnabled,
    'notificationHour': t.notificationHour,
    'notificationMinute': t.notificationMinute,
    'createdAt': t.createdAt.toIso8601String(),
    'updatedAt': t.updatedAt.toIso8601String(),
  });

  Task _decodeTask(String json) {
    final d = _decodeMap(json);
    final skillId = _readTaskSkillId(d);
    return Task(
      id: _readString(d, 'id', uid()),
      title: _readString(d, 'title', 'Квест'),
      description: _readString(d, 'description'),
      skillId: skillId,
      xpReward: _readInt(d, 'xpReward', 20),
      type: _readEnum(TaskType.values, d['type'], TaskType.shortTerm),
      isDone: _readBool(d, 'isDone'),
      isArchived: _readBool(d, 'isArchived'),
      streak: _readInt(d, 'streak'),
      earnedXP: _readInt(d, 'earnedXP'),
      repeatFrequency: _readEnum(
        RepeatFrequency.values,
        d['repeatFrequency'],
        RepeatFrequency.daily,
      ),
      repeatCustomDays: _readPositiveInt(d, 'repeatCustomDays'),
      nextResetAt: _readDate(d, 'nextResetAt'),
      lastCompletedAt: _readDate(d, 'lastCompletedAt'),
      priority: _readEnum(Priority.values, d['priority'], Priority.medium),
      minimumAction: _readString(d, 'minimumAction'),
      minimumActionDoneAt: _readDate(d, 'minimumActionDoneAt'),
      minimumActionEarnedXP: _readInt(d, 'minimumActionEarnedXP'),
      bonusXpEarned: _readInt(d, 'bonusXpEarned'),
      consumedBuffIds: _readStringList(d, 'consumedBuffIds'),
      subtasks: _readStringList(d, 'subtasks'),
      subtaskDone: _readBoolList(d, 'subtaskDone'),
      tags: _readStringList(d, 'tags'),
      treeNodeId: _readNullableString(d, 'treeNodeId'),
      notificationsEnabled: _readBool(d, 'notificationsEnabled'),
      notificationHour: _readNullableInt(d, 'notificationHour'),
      notificationMinute: _readNullableInt(d, 'notificationMinute'),
      createdAt: _readDate(d, 'createdAt'),
      updatedAt: _readDate(d, 'updatedAt'),
    );
  }

  String _readTaskSkillId(Map<String, dynamic> data) {
    final rawSkillId = _readNullableString(data, 'skillId');
    final rawScope = data['scope'];
    if (rawScope == 'inbox' || rawSkillId == null || rawSkillId.isEmpty) {
      return kInboxSkillId;
    }
    return rawSkillId;
  }

  String _encodeHistoryEntry(HistoryEntry e) => jsonEncode({
    'id': e.id,
    'taskTitle': e.taskTitle,
    'taskId': e.taskId,
    'skillId': e.skillId,
    'skillName': e.skillName,
    'skillColor': storageArgbFromColor(e.skillColor),
    'skillIconCodePoint': e.skillIcon.codePoint.toString(),
    'xp': e.xp,
    'isCompletion': e.isCompletion,
    'at': e.at.toIso8601String(),
  });

  HistoryEntry _decodeHistoryEntry(String json) {
    final d = _decodeMap(json);
    final iconName = _readString(d, 'skillIconCodePoint');
    return HistoryEntry(
      id: _readString(d, 'id', uid()),
      taskTitle: _readString(d, 'taskTitle', 'Квест'),
      taskId: _readNullableString(d, 'taskId'),
      skillId: _readString(d, 'skillId'),
      skillName: _readString(d, 'skillName', 'Навык'),
      skillColor: storageColorFromArgb(_readInt(d, 'skillColor', 0xFF4A9EFF)),
      skillIcon: storageIconFromCodePoint(iconName),
      xp: _readInt(d, 'xp'),
      isCompletion: _readBool(d, 'isCompletion', true),
      at: _readDate(d, 'at') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _encodeDailyStats(DailyStats s) => {
    'date': s.date.toIso8601String(),
    'tasksCompleted': s.tasksCompleted,
    'xpEarned': s.xpEarned,
    'skillsImproved': s.skillsImproved,
  };

  DailyStats _decodeDailyStats(Map<String, dynamic> d) => DailyStats(
    date: _readDate(d, 'date') ?? DateTime.now(),
    tasksCompleted: _readInt(d, 'tasksCompleted'),
    xpEarned: _readInt(d, 'xpEarned'),
    skillsImproved: _readInt(d, 'skillsImproved'),
  );

  String _encodeAchievement(Achievement a) =>
      jsonEncode({'id': a.id, 'unlockedAt': a.unlockedAt?.toIso8601String()});

  Achievement _decodeAchievement(String json) {
    final d = _decodeMap(json);
    final id = _readString(d, 'id', uid());
    final def = achievementDefinitions.where((x) => x.id == id).firstOrNull;
    return Achievement(id: id, unlockedAt: _readDate(d, 'unlockedAt'))
      ..def = def;
  }

  String _encodeBoss(Boss b) => jsonEncode({
    'id': b.id,
    'title': b.title,
    'skillId': b.skillId,
    'hp': b.hp,
    'maxHp': b.maxHp,
    'targetStreak': b.targetStreak,
    'currentStreak': b.currentStreak,
    'isDefeated': b.isDefeated,
    'defeatedAt': b.defeatedAt?.toIso8601String(),
  });

  Boss _decodeBoss(String json) {
    final d = _decodeMap(json);
    return Boss(
      id: _readString(d, 'id', uid()),
      title: _readString(d, 'title', 'Сопротивление'),
      skillId: _readString(d, 'skillId'),
      hp: _readInt(d, 'hp', 100),
      maxHp: _readPositiveInt(d, 'maxHp', 100),
      targetStreak: _readPositiveInt(d, 'targetStreak', 7),
      currentStreak: _readInt(d, 'currentStreak'),
      isDefeated: _readBool(d, 'isDefeated'),
      defeatedAt: _readDate(d, 'defeatedAt'),
    );
  }

  String _encodeRewardChest(RewardChest chest) => jsonEncode({
    'id': chest.id,
    'title': chest.title,
    'description': chest.description,
    'rarity': chest.rarity.name,
    'sourceKey': chest.sourceKey,
    'skillId': chest.skillId,
    'unlockedAt': chest.unlockedAt.toIso8601String(),
    'openedAt': chest.openedAt?.toIso8601String(),
  });

  RewardChest _decodeRewardChest(String json) {
    final d = _decodeMap(json);
    return RewardChest(
      id: _readString(d, 'id', uid()),
      title: _readString(d, 'title', 'Сундук'),
      description: _readString(d, 'description'),
      rarity: _readEnum(RewardRarity.values, d['rarity'], RewardRarity.common),
      sourceKey: _readString(d, 'sourceKey', _readString(d, 'id', uid())),
      skillId: _readNullableString(d, 'skillId'),
      unlockedAt: _readDate(d, 'unlockedAt') ?? DateTime.now(),
      openedAt: _readDate(d, 'openedAt'),
    );
  }

  String _encodeBuff(Buff buff) => jsonEncode({
    'id': buff.id,
    'type': buff.type.name,
    'title': buff.title,
    'description': buff.description,
    'bonusPercent': buff.bonusPercent,
    'charges': buff.charges,
    'skillId': buff.skillId,
    'sourceChestId': buff.sourceChestId,
    'sourceKey': buff.sourceKey,
    'createdAt': buff.createdAt.toIso8601String(),
    'expiresAt': buff.expiresAt?.toIso8601String(),
  });

  Buff _decodeBuff(String json) {
    final d = _decodeMap(json);
    return Buff(
      id: _readString(d, 'id', uid()),
      type: _readEnum(BuffType.values, d['type'], BuffType.nextQuestXpBoost),
      title: _readString(d, 'title', 'Пассивный эффект'),
      description: _readString(d, 'description'),
      bonusPercent: _readInt(d, 'bonusPercent'),
      charges: _readInt(d, 'charges'),
      skillId: _readNullableString(d, 'skillId'),
      sourceChestId: _readNullableString(d, 'sourceChestId'),
      sourceKey: _readNullableString(d, 'sourceKey'),
      createdAt: _readDate(d, 'createdAt') ?? DateTime.now(),
      expiresAt: _readDate(d, 'expiresAt'),
    );
  }

  String _encodeWeeklyGoal(WeeklyGoal goal) => jsonEncode({
    'id': goal.id,
    'weekStart': goal.weekStart.toIso8601String(),
    'title': goal.title,
    'createdAt': goal.createdAt.toIso8601String(),
    'updatedAt': goal.updatedAt.toIso8601String(),
    'keyResults': goal.keyResults
        .map(
          (result) => {
            'id': result.id,
            'title': result.title,
            'isDone': result.isDone,
            'completedAt': result.completedAt?.toIso8601String(),
          },
        )
        .toList(),
  });

  WeeklyGoal _decodeWeeklyGoal(String json) {
    final d = _decodeMap(json);
    return WeeklyGoal(
      id: _readString(d, 'id', uid()),
      weekStart: _readDate(d, 'weekStart') ?? DateTime.now(),
      title: _readString(d, 'title', 'Цель недели'),
      createdAt: _readDate(d, 'createdAt'),
      updatedAt: _readDate(d, 'updatedAt'),
      keyResults:
          (d['keyResults'] as List?)?.whereType<Map>().map((raw) {
            final item = Map<String, dynamic>.from(raw);
            return WeeklyKeyResult(
              id: _readString(item, 'id', uid()),
              title: _readString(item, 'title', 'Результат'),
              isDone: _readBool(item, 'isDone'),
              completedAt: _readDate(item, 'completedAt'),
            );
          }).toList() ??
          [],
    );
  }
}
