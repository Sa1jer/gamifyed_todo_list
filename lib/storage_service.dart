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

  late Box<String> _skills;
  late Box<String> _tasks;
  late Box<String> _profile;
  late Box<String> _history;
  late Box<String> _achievements;
  late Box<String> _stats;
  late Box<String> _bosses;

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

    _initialized = true;
  }

  void _ensureInit() {
    if (!_initialized) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
  }

  Future<void> saveSkills(List<Skill> skills) async {
    _ensureInit();
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
      'avatarBytes': profile.avatarBytes != null ? base64Encode(profile.avatarBytes!) : null,
      'bannerBytes': profile.bannerBytes != null ? base64Encode(profile.bannerBytes!) : null,
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
      gender: data['gender'] != null ? Gender.values[data['gender'] as int] : null,
      avatarBytes: data['avatarBytes'] != null ? base64Decode(data['avatarBytes'] as String) : null,
      bannerBytes: data['bannerBytes'] != null ? base64Decode(data['bannerBytes'] as String) : null,
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

  String _encodeSkill(Skill s) => jsonEncode({
    'id': s.id,
    'name': s.name,
    'goal': s.goal,
    'checklist': s.checklist,
    'checklistDone': s.checklistDone,
    'color': s.color.toARGB32(),
    'iconCodePoint': s.icon.codePoint,
    'level': s.level,
    'xp': s.xp,
  });

  Skill _decodeSkill(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    return Skill(
      id: d['id'] as String,
      name: d['name'] as String,
      goal: d['goal'] as String,
      checklist: (d['checklist'] as List).cast<String>(),
      checklistDone: (d['checklistDone'] as List).cast<bool>(),
      color: Color(d['color'] as int),
      icon: IconData(d['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      level: d['level'] as int? ?? 1,
      xp: d['xp'] as int? ?? 0,
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
    'priority': t.priority.index,
    'subtasks': t.subtasks,
    'subtaskDone': t.subtaskDone,
    'tags': t.tags,
    'notificationsEnabled': t.notificationsEnabled,
    'notificationHour': t.notificationHour,
    'notificationMinute': t.notificationMinute,
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
      repeatFrequency: RepeatFrequency.values[d['repeatFrequency'] as int? ?? 0],
      repeatCustomDays: d['repeatCustomDays'] as int? ?? 1,
      nextResetAt: d['nextResetAt'] != null ? DateTime.parse(d['nextResetAt'] as String) : null,
      priority: Priority.values[d['priority'] as int? ?? 1],
      subtasks: (d['subtasks'] as List?)?.cast<String>() ?? [],
      subtaskDone: (d['subtaskDone'] as List?)?.cast<bool>() ?? [],
      tags: (d['tags'] as List?)?.cast<String>() ?? [],
      notificationsEnabled: d['notificationsEnabled'] as bool? ?? false,
      notificationHour: d['notificationHour'] as int?,
      notificationMinute: d['notificationMinute'] as int?,
    );
  }

  String _encodeHistoryEntry(HistoryEntry e) => jsonEncode({
    'id': e.id,
    'taskTitle': e.taskTitle,
    'skillId': e.skillId,
    'skillName': e.skillName,
    'skillColor': e.skillColor.toARGB32(),
    'skillIconCodePoint': e.skillIcon.codePoint,
    'xp': e.xp,
    'isCompletion': e.isCompletion,
    'at': e.at.toIso8601String(),
  });

  HistoryEntry _decodeHistoryEntry(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    return HistoryEntry(
      id: d['id'] as String,
      taskTitle: d['taskTitle'] as String,
      skillId: d['skillId'] as String,
      skillName: d['skillName'] as String,
      skillColor: Color(d['skillColor'] as int),
      skillIcon: IconData(d['skillIconCodePoint'] as int, fontFamily: 'MaterialIcons'),
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

  String _encodeAchievement(Achievement a) => jsonEncode({
    'id': a.id,
    'unlockedAt': a.unlockedAt?.toIso8601String(),
  });

  Achievement _decodeAchievement(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final def = achievementDefinitions.firstWhere((x) => x.id == d['id']);
    return Achievement(
      id: d['id'] as String,
      unlockedAt: d['unlockedAt'] != null ? DateTime.parse(d['unlockedAt'] as String) : null,
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
      defeatedAt: d['defeatedAt'] != null ? DateTime.parse(d['defeatedAt'] as String) : null,
    );
  }
}

extension ColorValue on Color {
  int toARGB32() {
    return (a.round() << 24) | (r.round() << 16) | (g.round() << 8) | b.round();
  }
}