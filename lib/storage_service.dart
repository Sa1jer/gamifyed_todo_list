import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  static const String _sfxEnabledKey = 'sfxEnabled';
  static const String _tooltipsEnabledKey = 'tooltipsEnabled';
  static const String _onboardingSeenKey = 'onboardingSeen';
  static const String _tutorialProgressKey = 'tutorialProgress';
  static const String _bestStreakKey = 'bestStreak';
  static const String _schemaVersionKey = 'schemaVersion';
  static const int _legacySchemaVersion = 1;
  static const int _currentSchemaVersion = 2;
  static const int _maxJsonDecodeDepth = 64;

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

    _skills = await _openBox<String>(_skillsBox);
    _tasks = await _openBox<String>(_tasksBox);
    _profile = await _openBox<String>(_profileBox);
    _history = await _openBox<String>(_historyBox);
    _achievements = await _openBox<String>(_achievementsBox);
    _stats = await _openBox<String>(_statsBox);
    _bosses = await _openBox<String>(_bossesBox);
    _rewardChests = await _openBox<String>(_rewardChestsBox);
    _buffs = await _openBox<String>(_buffsBox);
    _weeklyGoals = await _openBox<String>(_weeklyGoalsBox);
    _meta = await _openBox<String>(_metaBox);

    await _migrateIfNeeded();

    _initialized = true;
  }

  Future<void> _migrateIfNeeded() async {
    final storedVersion = _storedSchemaVersion();
    if (storedVersion < _currentSchemaVersion) {
      if (storedVersion < 2) {
        await _migrateV1ToV2();
      }
      await _meta.put(_schemaVersionKey, _currentSchemaVersion.toString());
    }
  }

  Future<void> _migrateV1ToV2() async {
    for (final key in _skills.keys.toList(growable: false)) {
      final raw = _skills.get(key);
      if (raw == null) continue;
      final migrated = _migrateSkillPayloadV1ToV2(raw);
      if (migrated == null) continue;
      await _skills.put(key, migrated);
    }
  }

  String? _migrateSkillPayloadV1ToV2(String raw) {
    final data = _decodeOrNull(raw, _decodeMap);
    if (data == null || data.isEmpty) return null;
    final skill = _decodeOrNull(raw, _decodeSkill);
    if (skill == null) return null;
    return _encodeSkill(skill);
  }

  int _storedSchemaVersion() {
    return _readNullableIntValue(_meta.get(_schemaVersionKey)) ??
        _legacySchemaVersion;
  }

  int _versionAfterMigration(Object? raw) {
    final version = _readNullableIntValue(raw) ?? _legacySchemaVersion;
    return version < _currentSchemaVersion ? _currentSchemaVersion : version;
  }

  Future<Box<T>> _openBox<T>(String name) async {
    const maxAttempts = 8;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await Hive.openBox<T>(name);
      } on FileSystemException catch (error) {
        final isLocked = error.osError?.errorCode == 35;
        if (!isLocked || attempt == maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 120 * attempt));
      }
    }

    return Hive.openBox<T>(name);
  }

  void _ensureInit() {
    if (!_initialized) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
  }

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

  Future<bool?> loadSfxEnabled() async {
    _ensureInit();
    final raw = _meta.get(_sfxEnabledKey);
    if (raw == null) return null;
    return raw == 'true';
  }

  Future<void> saveSfxEnabled(bool enabled) async {
    _ensureInit();
    await _meta.put(_sfxEnabledKey, enabled ? 'true' : 'false');
  }

  Future<bool?> loadTooltipsEnabled() async {
    _ensureInit();
    final raw = _meta.get(_tooltipsEnabledKey);
    if (raw == null) return null;
    return raw == 'true';
  }

  Future<void> saveTooltipsEnabled(bool enabled) async {
    _ensureInit();
    await _meta.put(_tooltipsEnabledKey, enabled ? 'true' : 'false');
  }

  Future<bool?> loadOnboardingSeen() async {
    _ensureInit();
    final raw = _meta.get(_onboardingSeenKey);
    if (raw == null) return null;
    return raw == 'true';
  }

  Future<void> saveOnboardingSeen(bool seen) async {
    _ensureInit();
    await _meta.put(_onboardingSeenKey, seen ? 'true' : 'false');
  }

  Future<TutorialProgress?> loadTutorialProgress() async {
    _ensureInit();
    final raw = _meta.get(_tutorialProgressKey);
    if (raw == null) return null;
    final data = _decodeOrNull(raw, _decodeMap);
    if (data == null) return const TutorialProgress.empty();
    return TutorialProgress.fromJson(data);
  }

  Future<void> saveTutorialProgress(TutorialProgress progress) async {
    _ensureInit();
    await _meta.put(_tutorialProgressKey, jsonEncode(progress.toJson()));
  }

  @visibleForTesting
  String debugEncodeTask(Task task) => _encodeTask(task);

  @visibleForTesting
  Task debugDecodeTask(String json) => _decodeTask(json);

  @visibleForTesting
  String debugEncodeSkill(Skill skill) => _encodeSkill(skill);

  @visibleForTesting
  Skill debugDecodeSkill(String json) => _decodeSkill(json);

  @visibleForTesting
  Achievement debugDecodeAchievement(String json) => _decodeAchievement(json);

  @visibleForTesting
  String debugEncodeProfile(UserProfile profile) => _encodeProfile(profile);

  @visibleForTesting
  UserProfile debugDecodeProfile(String json) => _decodeProfile(json);

  @visibleForTesting
  Map<String, dynamic>? debugDecodeMapOrNull(String json) =>
      _decodeOrNull(json, _decodeMap);

  @visibleForTesting
  int get debugCurrentSchemaVersion => _currentSchemaVersion;

  @visibleForTesting
  int debugVersionAfterMigration(Object? raw) => _versionAfterMigration(raw);

  @visibleForTesting
  String? debugMigrateSkillPayloadV1ToV2(String raw) =>
      _migrateSkillPayloadV1ToV2(raw);

  Future<int?> loadBestStreak() async {
    _ensureInit();
    return _readNullableIntValue(_meta.get(_bestStreakKey));
  }

  Future<void> saveBestStreak(int value) async {
    _ensureInit();
    await _meta.put(_bestStreakKey, value.toString());
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
        final decoded = _decodeOrNull(json, _decodeSkill);
        if (decoded != null) result.add(decoded);
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
        final decoded = _decodeOrNull(json, _decodeTask);
        if (decoded != null) result.add(decoded);
      }
    }
    return result;
  }

  Future<void> saveProfile(UserProfile profile) async {
    _ensureInit();
    await _profile.put('profile', _encodeProfile(profile));
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

  Future<UserProfile> loadProfile() async {
    _ensureInit();
    final raw = _profile.get('profile');
    if (raw == null) {
      return UserProfile(name: 'Your Name');
    }

    return _decodeProfile(raw);
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
        final decoded = _decodeOrNull(json, _decodeHistoryEntry);
        if (decoded != null) result.add(decoded);
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
    final decoded = _decodeOrNull(
      raw,
      (json) => _decodeDailyStats(_decodeMap(json)),
    );
    return decoded;
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
        final decoded = _decodeOrNull(json, _decodeAchievement);
        if (decoded != null) result.add(decoded);
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
        final decoded = _decodeOrNull(json, _decodeBoss);
        if (decoded != null) result.add(decoded);
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
        final decoded = _decodeOrNull(json, _decodeRewardChest);
        if (decoded != null) result.add(decoded);
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
        final decoded = _decodeOrNull(json, _decodeBuff);
        if (decoded != null) result.add(decoded);
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
        final decoded = _decodeOrNull(json, _decodeWeeklyGoal);
        if (decoded != null) result.add(decoded);
      }
    }
    return result;
  }

  String _encodeSkill(Skill s) => jsonEncode({
    'id': s.id,
    'name': s.name,
    'goal': s.goal,
    'goalSpec': _encodeGoalSpec(s.goalSpec),
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
      color: Color(_readInt(d, 'color', const Color(0xFF4A9EFF).toARGB32())),
      icon: _getIconFromCodePoint(iconName),
      level: _readInt(d, 'level', 1),
      xp: _readInt(d, 'xp'),
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
    'skillId': t.skillId,
    'xpReward': t.xpReward,
    'type': t.type.name,
    'isDone': t.isDone,
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
    return Task(
      id: _readString(d, 'id', uid()),
      title: _readString(d, 'title', 'Квест'),
      skillId: _readString(d, 'skillId'),
      xpReward: _readInt(d, 'xpReward', 20),
      type: _readEnum(TaskType.values, d['type'], TaskType.shortTerm),
      isDone: _readBool(d, 'isDone'),
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
    final d = _decodeMap(json);
    final iconName = _readString(d, 'skillIconCodePoint');
    return HistoryEntry(
      id: _readString(d, 'id', uid()),
      taskTitle: _readString(d, 'taskTitle', 'Квест'),
      taskId: _readNullableString(d, 'taskId'),
      skillId: _readString(d, 'skillId'),
      skillName: _readString(d, 'skillName', 'Навык'),
      skillColor: Color(
        _readInt(d, 'skillColor', const Color(0xFF4A9EFF).toARGB32()),
      ),
      skillIcon: _getIconFromCodePoint(iconName),
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

extension ColorValue on Color {
  int toARGB32() {
    int channel(double value) => (value * 255).round().clamp(0, 255).toInt();
    return (channel(a) << 24) |
        (channel(r) << 16) |
        (channel(g) << 8) |
        channel(b);
  }
}
