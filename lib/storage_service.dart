import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';
import 'persistence/hive_preference_store.dart';
import 'persistence/legacy_hive_domain_store.dart';
import 'persistence/legacy_storage_codec.dart';
import 'persistence/snapshot_store.dart';
import 'persistence/storage_migration_policy.dart';
import 'persistence/storage_snapshot_codec.dart';
import 'storage_snapshot.dart';

export 'persistence/snapshot_store.dart' show SnapshotBackend;

class _HiveSnapshotBackend implements SnapshotBackend {
  const _HiveSnapshotBackend(this.box);

  final Box<String> box;

  @override
  Future<String?> read(String key) async => box.get(key);

  @override
  Future<void> write(String key, String value) => box.put(key, value);
}

/// Stable compatibility facade for local persistence.
///
/// Snapshot recovery, legacy box IO, preferences, migration, and payload
/// codecs have separate owners. This facade preserves the historical public
/// API used by AppState and test doubles.
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
  static const String _snapshotsBox = 'storage_snapshots';

  static const String _skillsSavedKey = 'skillsSaved';
  static const String _tasksSavedKey = 'tasksSaved';
  static const String _isDarkKey = 'isDark';
  static const String _sfxEnabledKey = 'sfxEnabled';
  static const String _tooltipsEnabledKey = 'tooltipsEnabled';
  static const String _reducedMotionKey = 'reducedMotion';
  static const String _onboardingSeenKey = 'onboardingSeen';
  static const String _tutorialProgressKey = 'tutorialProgress';
  static const String _bestStreakKey = 'bestStreak';
  static const String _schemaVersionKey = 'schemaVersion';

  final String? _hivePath;
  final LegacyStorageCodec _codec = const LegacyStorageCodec();
  final StorageMigrationPolicy _migrationPolicy =
      const StorageMigrationPolicy();

  late Box<String> _skills;
  late Box<String> _meta;
  late LegacyHiveDomainStore _domains;
  late HivePreferenceStore _preferences;
  SnapshotBackend? _snapshotBackend;

  bool _initialized = false;
  bool? _runtimeReducedMotion;

  StorageService({SnapshotBackend? snapshotBackend, String? hivePath})
    : _snapshotBackend = snapshotBackend,
      _hivePath = hivePath;

  bool get supportsSnapshots => _snapshotBackend != null;

  Future<void> init() async {
    if (_initialized) return;

    final hivePath = _hivePath;
    if (hivePath == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(hivePath);
    }

    _skills = await _openBox<String>(_skillsBox);
    final tasks = await _openBox<String>(_tasksBox);
    final profile = await _openBox<String>(_profileBox);
    final history = await _openBox<String>(_historyBox);
    final achievements = await _openBox<String>(_achievementsBox);
    final stats = await _openBox<String>(_statsBox);
    final bosses = await _openBox<String>(_bossesBox);
    final rewardChests = await _openBox<String>(_rewardChestsBox);
    final buffs = await _openBox<String>(_buffsBox);
    final weeklyGoals = await _openBox<String>(_weeklyGoalsBox);
    _meta = await _openBox<String>(_metaBox);
    final snapshots = await _openBox<String>(_snapshotsBox);

    _domains = LegacyHiveDomainStore(
      skills: _skills,
      tasks: tasks,
      profile: profile,
      history: history,
      achievements: achievements,
      stats: stats,
      bosses: bosses,
      rewardChests: rewardChests,
      buffs: buffs,
      weeklyGoals: weeklyGoals,
      meta: _meta,
      codec: _codec,
      skillsSavedKey: _skillsSavedKey,
      tasksSavedKey: _tasksSavedKey,
    );
    _preferences = HivePreferenceStore(meta: _meta, codec: _codec);
    _snapshotBackend = _HiveSnapshotBackend(snapshots);

    await _migrateIfNeeded();
    _initialized = true;
  }

  Future<CommittedSnapshot?> loadLatestSnapshot() =>
      _snapshotStore().loadLatest();

  Future<void> saveSnapshot(StorageSnapshot snapshot) =>
      _snapshotStore().save(snapshot);

  SnapshotStore _snapshotStore() {
    final backend = _snapshotBackend;
    if (backend == null) {
      throw StateError('Snapshot storage is not initialized.');
    }
    return SnapshotStore(
      backend: backend,
      encode: _snapshotCodec().encode,
      decode: _snapshotCodec().decode,
    );
  }

  StorageSnapshotCodec _snapshotCodec() => StorageSnapshotCodec(
    encodeSkill: _codec.encodeSkill,
    decodeSkill: _codec.decodeSkill,
    encodeTask: _codec.encodeTask,
    decodeTask: _codec.decodeTask,
    encodeProfile: _codec.encodeProfile,
    decodeProfile: _codec.decodeProfile,
    encodeHistoryEntry: _codec.encodeHistoryEntry,
    decodeHistoryEntry: _codec.decodeHistoryEntry,
    encodeAchievement: _codec.encodeAchievement,
    decodeAchievement: _codec.decodeAchievement,
    encodeDailyStats: _codec.encodeDailyStats,
    decodeDailyStats: _codec.decodeDailyStats,
    encodeBoss: _codec.encodeBoss,
    decodeBoss: _codec.decodeBoss,
    encodeRewardChest: _codec.encodeRewardChest,
    decodeRewardChest: _codec.decodeRewardChest,
    encodeBuff: _codec.encodeBuff,
    decodeBuff: _codec.decodeBuff,
    encodeWeeklyGoal: _codec.encodeWeeklyGoal,
    decodeWeeklyGoal: _codec.decodeWeeklyGoal,
    decodeMap: _codec.decodeMap,
  );

  Future<void> _migrateIfNeeded() => _migrationPolicy.migrate(
    storedVersionValue: _meta.get(_schemaVersionKey),
    skillKeys: _skills.keys,
    readSkill: _skills.get,
    writeSkill: _skills.put,
    writeVersion: (version) => _meta.put(_schemaVersionKey, version.toString()),
    migrateSkillPayload: _migrateSkillPayloadV1ToV2,
  );

  String? _migrateSkillPayloadV1ToV2(String raw) =>
      _migrationPolicy.migrateSkillPayloadV1ToV2<Skill>(
        raw: raw,
        decodeMapOrNull: (value) =>
            _codec.decodeOrNull(value, _codec.decodeMap),
        decodeSkillOrNull: (value) =>
            _codec.decodeOrNull(value, _codec.decodeSkill),
        encodeSkill: _codec.encodeSkill,
      );

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

  Future<bool> hasSavedSkills() {
    _ensureInit();
    return _domains.hasSavedSkills();
  }

  Future<bool> hasSavedTasks() {
    _ensureInit();
    return _domains.hasSavedTasks();
  }

  Future<bool?> loadTheme() => _loadBool(_isDarkKey);
  Future<void> saveTheme(bool value) => _saveBool(_isDarkKey, value);
  Future<bool?> loadSfxEnabled() => _loadBool(_sfxEnabledKey);
  Future<void> saveSfxEnabled(bool value) => _saveBool(_sfxEnabledKey, value);
  Future<bool?> loadTooltipsEnabled() => _loadBool(_tooltipsEnabledKey);
  Future<void> saveTooltipsEnabled(bool value) =>
      _saveBool(_tooltipsEnabledKey, value);
  Future<bool?> loadOnboardingSeen() => _loadBool(_onboardingSeenKey);
  Future<void> saveOnboardingSeen(bool value) =>
      _saveBool(_onboardingSeenKey, value);

  Future<bool?> _loadBool(String key) {
    _ensureInit();
    return _preferences.loadBool(key);
  }

  Future<void> _saveBool(String key, bool value) {
    _ensureInit();
    return _preferences.saveBool(key, value);
  }

  /// Device-local UI preference kept outside domain snapshots intentionally.
  Future<bool?> loadReducedMotion() {
    if (!_initialized) return Future<bool?>.value(_runtimeReducedMotion);
    return _preferences.loadBool(_reducedMotionKey);
  }

  Future<void> saveReducedMotion(bool enabled) async {
    _runtimeReducedMotion = enabled;
    if (!_initialized) return;
    await _preferences.saveBool(_reducedMotionKey, enabled);
  }

  Future<TutorialProgress?> loadTutorialProgress() {
    _ensureInit();
    return _preferences.loadTutorialProgress(_tutorialProgressKey);
  }

  Future<void> saveTutorialProgress(TutorialProgress progress) {
    _ensureInit();
    return _preferences.saveTutorialProgress(_tutorialProgressKey, progress);
  }

  Future<int?> loadBestStreak() {
    _ensureInit();
    return _preferences.loadInt(_bestStreakKey);
  }

  Future<void> saveBestStreak(int value) {
    _ensureInit();
    return _preferences.saveInt(_bestStreakKey, value);
  }

  Future<void> saveSkills(List<Skill> values) {
    _ensureInit();
    return _domains.saveSkills(values);
  }

  Future<List<Skill>> loadSkills() {
    _ensureInit();
    return _domains.loadSkills();
  }

  Future<void> saveTasks(List<Task> values) {
    _ensureInit();
    return _domains.saveTasks(values);
  }

  Future<List<Task>> loadTasks() {
    _ensureInit();
    return _domains.loadTasks();
  }

  Future<void> saveProfile(UserProfile value) {
    _ensureInit();
    return _domains.saveProfile(value);
  }

  Future<UserProfile> loadProfile() {
    _ensureInit();
    return _domains.loadProfile();
  }

  Future<void> saveHistory(List<HistoryEntry> values) {
    _ensureInit();
    return _domains.saveHistory(values);
  }

  Future<List<HistoryEntry>> loadHistory() {
    _ensureInit();
    return _domains.loadHistory();
  }

  Future<void> saveStats(DailyStats value) {
    _ensureInit();
    return _domains.saveStats(value);
  }

  Future<DailyStats?> loadStats() {
    _ensureInit();
    return _domains.loadStats();
  }

  Future<void> saveAchievements(List<Achievement> values) {
    _ensureInit();
    return _domains.saveAchievements(values);
  }

  Future<List<Achievement>> loadAchievements() {
    _ensureInit();
    return _domains.loadAchievements();
  }

  Future<void> saveBosses(List<Boss> values) {
    _ensureInit();
    return _domains.saveBosses(values);
  }

  Future<List<Boss>> loadBosses() {
    _ensureInit();
    return _domains.loadBosses();
  }

  Future<void> saveRewardChests(List<RewardChest> values) {
    _ensureInit();
    return _domains.saveRewardChests(values);
  }

  Future<List<RewardChest>> loadRewardChests() {
    _ensureInit();
    return _domains.loadRewardChests();
  }

  Future<void> saveBuffs(List<Buff> values) {
    _ensureInit();
    return _domains.saveBuffs(values);
  }

  Future<List<Buff>> loadBuffs() {
    _ensureInit();
    return _domains.loadBuffs();
  }

  Future<void> saveWeeklyGoals(List<WeeklyGoal> values) {
    _ensureInit();
    return _domains.saveWeeklyGoals(values);
  }

  Future<List<WeeklyGoal>> loadWeeklyGoals() {
    _ensureInit();
    return _domains.loadWeeklyGoals();
  }

  @visibleForTesting
  String debugEncodeTask(Task value) => _codec.encodeTask(value);
  @visibleForTesting
  Task debugDecodeTask(String raw) => _codec.decodeTask(raw);
  @visibleForTesting
  String debugEncodeSkill(Skill value) => _codec.encodeSkill(value);
  @visibleForTesting
  Skill debugDecodeSkill(String raw) => _codec.decodeSkill(raw);
  @visibleForTesting
  Achievement debugDecodeAchievement(String raw) =>
      _codec.decodeAchievement(raw);
  @visibleForTesting
  String debugEncodeProfile(UserProfile value) => _codec.encodeProfile(value);
  @visibleForTesting
  UserProfile debugDecodeProfile(String raw) => _codec.decodeProfile(raw);
  @visibleForTesting
  Map<String, dynamic>? debugDecodeMapOrNull(String raw) =>
      _codec.decodeOrNull(raw, _codec.decodeMap);
  @visibleForTesting
  int get debugCurrentSchemaVersion => _migrationPolicy.currentVersion;
  @visibleForTesting
  int debugVersionAfterMigration(Object? raw) =>
      _migrationPolicy.versionAfterMigration(raw);
  @visibleForTesting
  String? debugMigrateSkillPayloadV1ToV2(String raw) =>
      _migrateSkillPayloadV1ToV2(raw);
  @visibleForTesting
  String debugEncodeSnapshot(StorageSnapshot value) =>
      _snapshotCodec().encode(value);
  @visibleForTesting
  StorageSnapshot debugDecodeSnapshot(String raw) =>
      _snapshotCodec().decode(raw);
}
