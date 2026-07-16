import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/achievement_models.dart';
import '../models/activity_models.dart';
import '../models/reward_models.dart';
import '../models/skill_models.dart';
import '../models/task_models.dart';
import '../models/user_profile.dart';
import 'legacy_storage_codec.dart';

/// Owns legacy per-domain Hive reads and writes.
///
/// This boundary intentionally preserves the existing box/key layout while
/// snapshots remain the authoritative all-or-nothing persistence path.
class LegacyHiveDomainStore {
  const LegacyHiveDomainStore({
    required this.skills,
    required this.tasks,
    required this.profile,
    required this.history,
    required this.achievements,
    required this.stats,
    required this.bosses,
    required this.rewardChests,
    required this.buffs,
    required this.weeklyGoals,
    required this.meta,
    required this.codec,
    required this.skillsSavedKey,
    required this.tasksSavedKey,
  });

  final Box<String> skills;
  final Box<String> tasks;
  final Box<String> profile;
  final Box<String> history;
  final Box<String> achievements;
  final Box<String> stats;
  final Box<String> bosses;
  final Box<String> rewardChests;
  final Box<String> buffs;
  final Box<String> weeklyGoals;
  final Box<String> meta;
  final LegacyStorageCodec codec;
  final String skillsSavedKey;
  final String tasksSavedKey;

  Future<bool> hasSavedSkills() async => meta.get(skillsSavedKey) == 'true';
  Future<bool> hasSavedTasks() async => meta.get(tasksSavedKey) == 'true';

  Future<void> saveSkills(List<Skill> values) async {
    await meta.put(skillsSavedKey, 'true');
    await _replaceAll(skills, values, (value) => value.id, codec.encodeSkill);
  }

  Future<List<Skill>> loadSkills() => _loadAll(skills, codec.decodeSkill);

  Future<void> saveTasks(List<Task> values) async {
    await meta.put(tasksSavedKey, 'true');
    await _replaceAll(tasks, values, (value) => value.id, codec.encodeTask);
  }

  Future<List<Task>> loadTasks() => _loadAll(tasks, codec.decodeTask);

  Future<void> saveProfile(UserProfile value) =>
      profile.put('profile', codec.encodeProfile(value));

  Future<UserProfile> loadProfile() async {
    final raw = profile.get('profile');
    return raw == null
        ? UserProfile(name: 'Your Name')
        : codec.decodeProfile(raw);
  }

  Future<void> saveHistory(List<HistoryEntry> values) => _replaceAll(
    history,
    values,
    (value) => value.id,
    codec.encodeHistoryEntry,
  );

  Future<List<HistoryEntry>> loadHistory() =>
      _loadAll(history, codec.decodeHistoryEntry);

  Future<void> saveStats(DailyStats value) =>
      stats.put('daily', jsonEncode(codec.encodeDailyStats(value)));

  Future<DailyStats?> loadStats() async {
    final raw = stats.get('daily');
    if (raw == null) return null;
    return codec.decodeOrNull(
      raw,
      (value) => codec.decodeDailyStats(codec.decodeMap(value)),
    );
  }

  Future<void> saveAchievements(List<Achievement> values) => _replaceAll(
    achievements,
    values,
    (value) => value.id,
    codec.encodeAchievement,
  );

  Future<List<Achievement>> loadAchievements() =>
      _loadAll(achievements, codec.decodeAchievement);

  Future<void> saveBosses(List<Boss> values) =>
      _replaceAll(bosses, values, (value) => value.id, codec.encodeBoss);

  Future<List<Boss>> loadBosses() => _loadAll(bosses, codec.decodeBoss);

  Future<void> saveRewardChests(List<RewardChest> values) => _replaceAll(
    rewardChests,
    values,
    (value) => value.id,
    codec.encodeRewardChest,
  );

  Future<List<RewardChest>> loadRewardChests() =>
      _loadAll(rewardChests, codec.decodeRewardChest);

  Future<void> saveBuffs(List<Buff> values) =>
      _replaceAll(buffs, values, (value) => value.id, codec.encodeBuff);

  Future<List<Buff>> loadBuffs() => _loadAll(buffs, codec.decodeBuff);

  Future<void> saveWeeklyGoals(List<WeeklyGoal> values) => _replaceAll(
    weeklyGoals,
    values,
    (value) => value.id,
    codec.encodeWeeklyGoal,
  );

  Future<List<WeeklyGoal>> loadWeeklyGoals() =>
      _loadAll(weeklyGoals, codec.decodeWeeklyGoal);

  Future<void> _replaceAll<T>(
    Box<String> box,
    Iterable<T> values,
    String Function(T value) keyOf,
    String Function(T value) encode,
  ) async {
    await box.clear();
    for (final value in values) {
      await box.put(keyOf(value), encode(value));
    }
  }

  Future<List<T>> _loadAll<T>(
    Box<String> box,
    T Function(String raw) decode,
  ) async {
    final result = <T>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      final decoded = codec.decodeOrNull(raw, decode);
      if (decoded != null) result.add(decoded);
    }
    return result;
  }
}
