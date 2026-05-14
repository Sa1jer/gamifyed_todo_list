import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'utils.dart';

class StorageService {
  static const String _skillsBox = 'skills';
  static const String _tasksBox = 'tasks';
  static const String _profileBox = 'profile';
  static const String _historyBox = 'history';
  static const String _achievementsBox = 'achievements';
  static const String _statsBox = 'stats';
  static const String _bossesBox = 'bosses';
  static const String _rewardChestsBox = 'reward_chests';
  static const String _buffsBox = 'buffs';
  static const String _weeklyGoalsBox = 'weekly_goals';
  static const String _metaBox = 'meta';

  static const String _skillsSavedKey = 'skillsSaved';
  static const String _tasksSavedKey = 'tasksSaved';
  static const String _isDarkKey = 'isDark';

  late Box<String> _skills;
  late Box<String> _tasks;
  late Box<String> _profile;
  late Box<String> _history;
  late Box<String> _achievements;
  late Box<String> _stats;
  late Box<String> _bosses;
  late Box<String> _rewardChests;
  late Box<String> _buffs;
  late Box<String> _weeklyGoals;
  late Box<String> _meta;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    _skills = await Hive.openBox<String>(_skillsBox);
    _tasks = await Hive.openBox<String>(_tasksBox);
    _profile = await Hive.openBox<String>(_profileBox);
    _history = await Hive.openBox<String>(_historyBox);
    _achievements = await Hive.openBox<String>(_achievementsBox);
    _stats = await Hive.openBox<String>(_statsBox);
    _bosses = await Hive.openBox<String>(_bossesBox);
    _rewardChests = await Hive.openBox<String>(_rewardChestsBox);
    _buffs = await Hive.openBox<String>(_buffsBox);
    _weeklyGoals = await Hive.openBox<String>(_weeklyGoalsBox);
    _meta = await Hive.openBox<String>(_metaBox);

    _initialized = true;
  }

  void _ensureInit() {
    if (!_initialized) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
  }

  Future<bool> hasSavedSkills() async {
    _ensureInit();
    return _meta.get(_skillsSavedKey) == 'true';
  }

  Future<bool> hasSavedTasks() async {
    _ensureInit();
    return _meta.get(_tasksSavedKey) == 'true';
  }

  Future<bool?> loadTheme() async {
    _ensureInit();
    final raw = _meta.get(_isDarkKey);
    if (raw == null) return null;
    return raw == 'true';
  }

  Future<void> saveTheme(bool isDark) async {
    _ensureInit();
    await _meta.put(_isDarkKey, isDark ? 'true' : 'false');
  }

  Future<void> saveSkills(List<Skill> skills) async {
    _ensureInit();
    await _meta.put(_skillsSavedKey, 'true');
    await _skills.clear();
    for (final skill in skills) {
      await _skills.put(skill.id, _encodeSkill(skill));
    }
  }

  Future<List<Skill>> loadSkills() async {
    _ensureInit();
    final result = <Skill>[];
    for (final key in _skills.keys) {
      final json = _skills.get(key);
      if (json != null) {
        result.add(_decodeSkill(json));
      }
    }
    return result;
  }

  Future<void> saveTasks(List<Task> tasks) async {
    _ensureInit();
    await _meta.put(_tasksSavedKey, 'true');
    await _tasks.clear();
    for (final task in tasks) {
      await _tasks.put(task.id, _encodeTask(task));
    }
  }

  Future<List<Task>> loadTasks() async {
    _ensureInit();
    final result = <Task>[];
    for (final key in _tasks.keys) {
      final json = _tasks.get(key);
      if (json != null) {
        result.add(_decodeTask(json));
      }
    }
    return result;
  }

  Future<void> saveProfile(UserProfile profile) async {
    _ensureInit();
    final data = {
      'name': profile.name,
      'level': profile.level,
      'xp': profile.xp,
      'totalXpEarned': profile.totalXpEarned,
      'age': profile.age,
      'gender': profile.gender?.index,
      'avatarBytes': profile.avatarBytes != null
          ? base64Encode(profile.avatarBytes!)
          : null,
      'bannerBytes': profile.bannerBytes != null
          ? base64Encode(profile.bannerBytes!)
          : null,
    };
    await _profile.put('profile', jsonEncode(data));
  }

  Future<UserProfile> loadProfile() async {
    _ensureInit();
    final raw = _profile.get('profile');
    if (raw == null) {
      return UserProfile(name: 'Your Name');
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;
    return UserProfile(
      name: data['name'] as String? ?? 'Your Name',
      level: data['level'] as int? ?? 1,
      xp: data['xp'] as int? ?? 0,
      totalXpEarned: data['totalXpEarned'] as int? ?? 0,
      age: data['age'] as int?,
      gender: data['gender'] != null
          ? Gender.values[data['gender'] as int]
          : null,
      avatarBytes: data['avatarBytes'] != null
          ? base64Decode(data['avatarBytes'] as String)
          : null,
      bannerBytes: data['bannerBytes'] != null
          ? base64Decode(data['bannerBytes'] as String)
          : null,
    );
  }

  Future<void> saveHistory(List<HistoryEntry> entries) async {
    _ensureInit();
    await _history.clear();
    for (int i = 0; i < entries.length; i++) {
      await _history.put(entries[i].id, _encodeHistoryEntry(entries[i]));
    }
  }

  Future<List<HistoryEntry>> loadHistory() async {
    _ensureInit();
    final result = <HistoryEntry>[];
    for (final key in _history.keys) {
      final json = _history.get(key);
      if (json != null) {
        result.add(_decodeHistoryEntry(json));
      }
    }
    return result;
  }

  Future<void> saveStats(DailyStats stats) async {
    _ensureInit();
    await _stats.put('daily', jsonEncode(_encodeDailyStats(stats)));
  }

  Future<DailyStats?> loadStats() async {
    _ensureInit();
    final raw = _stats.get('daily');
    if (raw == null) return null;
    return _decodeDailyStats(jsonDecode(raw));
  }

  Future<void> saveAchievements(List<Achievement> achievements) async {
    _ensureInit();
    await _achievements.clear();
    for (final a in achievements) {
      await _achievements.put(a.id, _encodeAchievement(a));
    }
  }

  Future<List<Achievement>> loadAchievements() async {
    _ensureInit();
    final result = <Achievement>[];
    for (final key in _achievements.keys) {
      final json = _achievements.get(key);
      if (json != null) {
        result.add(_decodeAchievement(json));
      }
    }
    return result;
  }

  Future<void> saveBosses(List<Boss> bosses) async {
    _ensureInit();
    await _bosses.clear();
    for (final boss in bosses) {
      await _bosses.put(boss.id, _encodeBoss(boss));
    }
  }

  Future<List<Boss>> loadBosses() async {
    _ensureInit();
    final result = <Boss>[];
    for (final key in _bosses.keys) {
      final json = _bosses.get(key);
      if (json != null) {
        result.add(_decodeBoss(json));
      }
    }
    return result;
  }

  Future<void> saveRewardChests(List<RewardChest> rewardChests) async {
    _ensureInit();
    await _rewardChests.clear();
    for (final chest in rewardChests) {
      await _rewardChests.put(chest.id, _encodeRewardChest(chest));
    }
  }

  Future<List<RewardChest>> loadRewardChests() async {
    _ensureInit();
    final result = <RewardChest>[];
    for (final key in _rewardChests.keys) {
      final json = _rewardChests.get(key);
      if (json != null) {
        result.add(_decodeRewardChest(json));
      }
    }
    return result;
  }

  Future<void> saveBuffs(List<Buff> buffs) async {
    _ensureInit();
    await _buffs.clear();
    for (final buff in buffs) {
      await _buffs.put(buff.id, _encodeBuff(buff));
    }
  }

  Future<List<Buff>> loadBuffs() async {
    _ensureInit();
    final result = <Buff>[];
    for (final key in _buffs.keys) {
      final json = _buffs.get(key);
      if (json != null) {
        result.add(_decodeBuff(json));
      }
    }
    return result;
  }

  Future<void> saveWeeklyGoals(List<WeeklyGoal> goals) async {
    _ensureInit();
    await _weeklyGoals.clear();
    for (final goal in goals) {
      await _weeklyGoals.put(goal.id, _encodeWeeklyGoal(goal));
    }
  }

  Future<List<WeeklyGoal>> loadWeeklyGoals() async {
    _ensureInit();
    final result = <WeeklyGoal>[];
    for (final key in _weeklyGoals.keys) {
      final json = _weeklyGoals.get(key);
      if (json != null) {
        result.add(_decodeWeeklyGoal(json));
      }
    }
    return result;
  }

  String _encodeSkill(Skill s) => jsonEncode({
    'id': s.id,
    'name': s.name,
    'goal': s.goal,
    'checklist': s.checklist,
    'checklistDone': s.checklistDone,
    'treeNodes': s.treeNodes.map(_encodeSkillTreeNode).toList(),
    'color': s.color.toARGB32(),
    'iconName': s.icon.codePoint.toString(),
    'level': s.level,
    'xp': s.xp,
  });

  IconData _getIconFromCodePoint(String codePoint) {
    final cp = int.tryParse(codePoint);
    if (cp == null) return Icons.bolt;
    for (final icon in [...kIconsPrimary, ...kIconsExtra]) {
      if (icon.codePoint == cp) return icon;
    }
    return Icons.bolt;
  }

  Skill _decodeSkill(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final iconName = d['iconName'] as String;
    return Skill(
      id: d['id'] as String,
      name: d['name'] as String,
      goal: d['goal'] as String,
      checklist: (d['checklist'] as List).cast<String>(),
      checklistDone: (d['checklistDone'] as List).cast<bool>(),
      treeNodes:
          (d['treeNodes'] as List?)
              ?.map((raw) => _decodeSkillTreeNode(raw as Map<String, dynamic>))
              .toList() ??
          [],
      color: Color(d['color'] as int),
      icon: _getIconFromCodePoint(iconName),
      level: d['level'] as int? ?? 1,
      xp: d['xp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> _encodeSkillTreeNode(SkillTreeNode node) => {
    'id': node.id,
    'title': node.title,
    'description': node.description,
    'xpReward': node.xpReward,
    'prerequisiteIds': node.prerequisiteIds,
    'checklist': node.checklist,
    'checklistDone': node.checklistDone,
    'isMastered': node.isMastered,
    'masteredAt': node.masteredAt?.toIso8601String(),
  };

  SkillTreeNode _decodeSkillTreeNode(Map<String, dynamic> d) {
    return SkillTreeNode(
      id: d['id'] as String,
      title: d['title'] as String,
      description: d['description'] as String? ?? '',
      xpReward: d['xpReward'] as int? ?? 20,
      prerequisiteIds: (d['prerequisiteIds'] as List?)?.cast<String>() ?? [],
      checklist: (d['checklist'] as List?)?.cast<String>() ?? [],
      checklistDone: (d['checklistDone'] as List?)?.cast<bool>() ?? [],
      isMastered: d['isMastered'] as bool? ?? false,
      masteredAt: d['masteredAt'] != null
          ? DateTime.parse(d['masteredAt'] as String)
          : null,
    );
  }

  String _encodeTask(Task t) => jsonEncode({
    'id': t.id,
    'title': t.title,
    'skillId': t.skillId,
    'xpReward': t.xpReward,
    'type': t.type.index,
    'isDone': t.isDone,
    'streak': t.streak,
    'earnedXP': t.earnedXP,
    'repeatFrequency': t.repeatFrequency.index,
    'repeatCustomDays': t.repeatCustomDays,
    'nextResetAt': t.nextResetAt?.toIso8601String(),
    'lastCompletedAt': t.lastCompletedAt?.toIso8601String(),
    'priority': t.priority.index,
    'minimumAction': t.minimumAction,
    'minimumActionDoneAt': t.minimumActionDoneAt?.toIso8601String(),
    'minimumActionEarnedXP': t.minimumActionEarnedXP,
    'bonusXpEarned': t.bonusXpEarned,
    'consumedBuffIds': t.consumedBuffIds,
    'subtasks': t.subtasks,
    'subtaskDone': t.subtaskDone,
    'tags': t.tags,
    'notificationsEnabled': t.notificationsEnabled,
    'notificationHour': t.notificationHour,
    'notificationMinute': t.notificationMinute,
    'createdAt': t.createdAt.toIso8601String(),
    'updatedAt': t.updatedAt.toIso8601String(),
  });

  Task _decodeTask(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    return Task(
      id: d['id'] as String,
      title: d['title'] as String,
      skillId: d['skillId'] as String,
      xpReward: d['xpReward'] as int,
      type: TaskType.values[d['type'] as int],
      isDone: d['isDone'] as bool? ?? false,
      streak: d['streak'] as int? ?? 0,
      earnedXP: d['earnedXP'] as int? ?? 0,
      repeatFrequency:
          RepeatFrequency.values[d['repeatFrequency'] as int? ?? 0],
      repeatCustomDays: d['repeatCustomDays'] as int? ?? 1,
      nextResetAt: d['nextResetAt'] != null
          ? DateTime.parse(d['nextResetAt'] as String)
          : null,
      lastCompletedAt: d['lastCompletedAt'] != null
          ? DateTime.parse(d['lastCompletedAt'] as String)
          : null,
      priority: Priority.values[d['priority'] as int? ?? 1],
      minimumAction: d['minimumAction'] as String? ?? '',
      minimumActionDoneAt: d['minimumActionDoneAt'] != null
          ? DateTime.parse(d['minimumActionDoneAt'] as String)
          : null,
      minimumActionEarnedXP: d['minimumActionEarnedXP'] as int? ?? 0,
      bonusXpEarned: d['bonusXpEarned'] as int? ?? 0,
      consumedBuffIds: (d['consumedBuffIds'] as List?)?.cast<String>() ?? [],
      subtasks: (d['subtasks'] as List?)?.cast<String>() ?? [],
      subtaskDone: (d['subtaskDone'] as List?)?.cast<bool>() ?? [],
      tags: (d['tags'] as List?)?.cast<String>() ?? [],
      notificationsEnabled: d['notificationsEnabled'] as bool? ?? false,
      notificationHour: d['notificationHour'] as int?,
      notificationMinute: d['notificationMinute'] as int?,
      createdAt: d['createdAt'] != null
          ? DateTime.parse(d['createdAt'] as String)
          : null,
      updatedAt: d['updatedAt'] != null
          ? DateTime.parse(d['updatedAt'] as String)
          : null,
    );
  }

  String _encodeHistoryEntry(HistoryEntry e) => jsonEncode({
    'id': e.id,
    'taskTitle': e.taskTitle,
    'taskId': e.taskId,
    'skillId': e.skillId,
    'skillName': e.skillName,
    'skillColor': e.skillColor.toARGB32(),
    'skillIconCodePoint': e.skillIcon.codePoint.toString(),
    'xp': e.xp,
    'isCompletion': e.isCompletion,
    'at': e.at.toIso8601String(),
  });

  HistoryEntry _decodeHistoryEntry(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final iconName = d['skillIconCodePoint'] as String;
    return HistoryEntry(
      id: d['id'] as String,
      taskTitle: d['taskTitle'] as String,
      taskId: d['taskId'] as String?,
      skillId: d['skillId'] as String,
      skillName: d['skillName'] as String,
      skillColor: Color(d['skillColor'] as int),
      skillIcon: _getIconFromCodePoint(iconName),
      xp: d['xp'] as int,
      isCompletion: d['isCompletion'] as bool,
      at: DateTime.parse(d['at'] as String),
    );
  }

  Map<String, dynamic> _encodeDailyStats(DailyStats s) => {
    'date': s.date.toIso8601String(),
    'tasksCompleted': s.tasksCompleted,
    'xpEarned': s.xpEarned,
    'skillsImproved': s.skillsImproved,
  };

  DailyStats _decodeDailyStats(Map<String, dynamic> d) => DailyStats(
    date: DateTime.parse(d['date'] as String),
    tasksCompleted: d['tasksCompleted'] as int,
    xpEarned: d['xpEarned'] as int,
    skillsImproved: d['skillsImproved'] as int,
  );

  String _encodeAchievement(Achievement a) =>
      jsonEncode({'id': a.id, 'unlockedAt': a.unlockedAt?.toIso8601String()});

  Achievement _decodeAchievement(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final def = achievementDefinitions.firstWhere((x) => x.id == d['id']);
    return Achievement(
      id: d['id'] as String,
      unlockedAt: d['unlockedAt'] != null
          ? DateTime.parse(d['unlockedAt'] as String)
          : null,
    )..def = def;
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
    final d = jsonDecode(json) as Map<String, dynamic>;
    return Boss(
      id: d['id'] as String,
      title: d['title'] as String,
      skillId: d['skillId'] as String,
      hp: d['hp'] as int,
      maxHp: d['maxHp'] as int,
      targetStreak: d['targetStreak'] as int,
      currentStreak: d['currentStreak'] as int? ?? 0,
      isDefeated: d['isDefeated'] as bool? ?? false,
      defeatedAt: d['defeatedAt'] != null
          ? DateTime.parse(d['defeatedAt'] as String)
          : null,
    );
  }

  String _encodeRewardChest(RewardChest chest) => jsonEncode({
    'id': chest.id,
    'title': chest.title,
    'description': chest.description,
    'rarity': chest.rarity.index,
    'sourceKey': chest.sourceKey,
    'skillId': chest.skillId,
    'unlockedAt': chest.unlockedAt.toIso8601String(),
    'openedAt': chest.openedAt?.toIso8601String(),
  });

  RewardChest _decodeRewardChest(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    return RewardChest(
      id: d['id'] as String,
      title: d['title'] as String,
      description: d['description'] as String,
      rarity: RewardRarity.values[d['rarity'] as int? ?? 0],
      sourceKey: d['sourceKey'] as String,
      skillId: d['skillId'] as String?,
      unlockedAt: DateTime.parse(d['unlockedAt'] as String),
      openedAt: d['openedAt'] != null
          ? DateTime.parse(d['openedAt'] as String)
          : null,
    );
  }

  String _encodeBuff(Buff buff) => jsonEncode({
    'id': buff.id,
    'type': buff.type.index,
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
    final d = jsonDecode(json) as Map<String, dynamic>;
    return Buff(
      id: d['id'] as String,
      type: BuffType.values[d['type'] as int? ?? 0],
      title: d['title'] as String,
      description: d['description'] as String,
      bonusPercent: d['bonusPercent'] as int? ?? 0,
      charges: d['charges'] as int? ?? 0,
      skillId: d['skillId'] as String?,
      sourceChestId: d['sourceChestId'] as String?,
      sourceKey: d['sourceKey'] as String?,
      createdAt: DateTime.parse(d['createdAt'] as String),
      expiresAt: d['expiresAt'] != null
          ? DateTime.parse(d['expiresAt'] as String)
          : null,
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
    final d = jsonDecode(json) as Map<String, dynamic>;
    return WeeklyGoal(
      id: d['id'] as String,
      weekStart: DateTime.parse(d['weekStart'] as String),
      title: d['title'] as String? ?? '',
      createdAt: d['createdAt'] != null
          ? DateTime.parse(d['createdAt'] as String)
          : null,
      updatedAt: d['updatedAt'] != null
          ? DateTime.parse(d['updatedAt'] as String)
          : null,
      keyResults:
          (d['keyResults'] as List?)?.map((raw) {
            final item = raw as Map<String, dynamic>;
            return WeeklyKeyResult(
              id: item['id'] as String,
              title: item['title'] as String? ?? '',
              isDone: item['isDone'] as bool? ?? false,
              completedAt: item['completedAt'] != null
                  ? DateTime.parse(item['completedAt'] as String)
                  : null,
            );
          }).toList() ??
          [],
    );
  }
}

extension ColorValue on Color {
  int toARGB32() {
    int channel(double value) => (value * 255).round().clamp(0, 255).toInt();
    return (channel(a) << 24) |
        (channel(r) << 16) |
        (channel(g) << 8) |
        channel(b);
  }
}
