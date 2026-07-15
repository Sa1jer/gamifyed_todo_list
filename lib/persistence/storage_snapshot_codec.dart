import 'dart:convert';

import '../models.dart';
import '../storage_snapshot.dart';

typedef DomainEncoder<T> = String Function(T value);
typedef DomainDecoder<T> = T Function(String raw);

/// Encodes and validates the committed snapshot envelope.
///
/// Individual domain codecs remain injectable so legacy Hive payloads and
/// committed snapshots use exactly the same serialization rules.
class StorageSnapshotCodec {
  const StorageSnapshotCodec({
    required this.encodeSkill,
    required this.decodeSkill,
    required this.encodeTask,
    required this.decodeTask,
    required this.encodeProfile,
    required this.decodeProfile,
    required this.encodeHistoryEntry,
    required this.decodeHistoryEntry,
    required this.encodeAchievement,
    required this.decodeAchievement,
    required this.encodeDailyStats,
    required this.decodeDailyStats,
    required this.encodeBoss,
    required this.decodeBoss,
    required this.encodeRewardChest,
    required this.decodeRewardChest,
    required this.encodeBuff,
    required this.decodeBuff,
    required this.encodeWeeklyGoal,
    required this.decodeWeeklyGoal,
    required this.decodeMap,
  });

  final DomainEncoder<Skill> encodeSkill;
  final DomainDecoder<Skill> decodeSkill;
  final DomainEncoder<Task> encodeTask;
  final DomainDecoder<Task> decodeTask;
  final DomainEncoder<UserProfile> encodeProfile;
  final DomainDecoder<UserProfile> decodeProfile;
  final DomainEncoder<HistoryEntry> encodeHistoryEntry;
  final DomainDecoder<HistoryEntry> decodeHistoryEntry;
  final DomainEncoder<Achievement> encodeAchievement;
  final DomainDecoder<Achievement> decodeAchievement;
  final Map<String, dynamic> Function(DailyStats value) encodeDailyStats;
  final DailyStats Function(Map<String, dynamic> value) decodeDailyStats;
  final DomainEncoder<Boss> encodeBoss;
  final DomainDecoder<Boss> decodeBoss;
  final DomainEncoder<RewardChest> encodeRewardChest;
  final DomainDecoder<RewardChest> decodeRewardChest;
  final DomainEncoder<Buff> encodeBuff;
  final DomainDecoder<Buff> decodeBuff;
  final DomainEncoder<WeeklyGoal> encodeWeeklyGoal;
  final DomainDecoder<WeeklyGoal> decodeWeeklyGoal;
  final Map<String, dynamic> Function(String raw) decodeMap;

  String encode(StorageSnapshot snapshot) {
    final domains = <String, dynamic>{
      'skills': snapshot.skills.map(encodeSkill).toList(growable: false),
      'tasks': snapshot.tasks.map(encodeTask).toList(growable: false),
      'profile': encodeProfile(snapshot.profile),
      'history': snapshot.history
          .map(encodeHistoryEntry)
          .toList(growable: false),
      'achievements': snapshot.achievements
          .map(encodeAchievement)
          .toList(growable: false),
      'stats': snapshot.stats == null
          ? null
          : jsonEncode(encodeDailyStats(snapshot.stats!)),
      'bosses': snapshot.bosses.map(encodeBoss).toList(growable: false),
      'rewardChests': snapshot.rewardChests
          .map(encodeRewardChest)
          .toList(growable: false),
      'buffs': snapshot.buffs.map(encodeBuff).toList(growable: false),
      'weeklyGoals': snapshot.weeklyGoals
          .map(encodeWeeklyGoal)
          .toList(growable: false),
      'bestStreak': snapshot.bestStreak,
      'isDark': snapshot.isDark,
      'sfxEnabled': snapshot.sfxEnabled,
      'tooltipsEnabled': snapshot.tooltipsEnabled,
      'onboardingSeen': snapshot.onboardingSeen,
      'tutorialProgress': jsonEncode(snapshot.tutorialProgress.toJson()),
    };
    return jsonEncode({
      'id': snapshot.id,
      'version': snapshot.version,
      'createdAt': snapshot.createdAt.toUtc().toIso8601String(),
      'counts': {
        'skills': snapshot.skills.length,
        'tasks': snapshot.tasks.length,
        'history': snapshot.history.length,
        'achievements': snapshot.achievements.length,
        'bosses': snapshot.bosses.length,
        'rewardChests': snapshot.rewardChests.length,
        'buffs': snapshot.buffs.length,
        'weeklyGoals': snapshot.weeklyGoals.length,
      },
      'domains': domains,
    });
  }

  StorageSnapshot decode(String raw) {
    final root = decodeMap(raw);
    final id = root['id'];
    final version = root['version'];
    final createdAtRaw = root['createdAt'];
    final domainsRaw = root['domains'];
    final countsRaw = root['counts'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Snapshot id is missing.');
    }
    if (version != kStorageSnapshotVersion) {
      throw FormatException('Unsupported snapshot version: $version');
    }
    if (createdAtRaw is! String || domainsRaw is! Map || countsRaw is! Map) {
      throw const FormatException('Snapshot metadata is incomplete.');
    }
    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) {
      throw const FormatException('Snapshot timestamp is invalid.');
    }
    final domains = Map<String, dynamic>.from(domainsRaw);
    final counts = Map<String, dynamic>.from(countsRaw);

    List<T> decodeList<T>(String key, DomainDecoder<T> decoder) {
      final encoded = domains[key];
      if (encoded is! List) {
        throw FormatException('Snapshot domain $key is missing.');
      }
      final result = <T>[];
      for (final item in encoded) {
        if (item is! String) {
          throw FormatException('Snapshot domain $key is invalid.');
        }
        result.add(decoder(item));
      }
      if (counts[key] != result.length) {
        throw FormatException('Snapshot domain $key count does not match.');
      }
      return result;
    }

    String requiredString(String key) {
      final value = domains[key];
      if (value is! String) {
        throw FormatException('Snapshot domain $key is missing.');
      }
      return value;
    }

    bool requiredBool(String key) {
      final value = domains[key];
      if (value is! bool) {
        throw FormatException('Snapshot domain $key is missing.');
      }
      return value;
    }

    int requiredInt(String key) {
      final value = domains[key];
      if (value is! int) {
        throw FormatException('Snapshot domain $key is missing.');
      }
      return value;
    }

    final skills = decodeList('skills', decodeSkill);
    final tasks = decodeList('tasks', decodeTask);
    _validateIds(skills.map((item) => item.id), 'skills');
    _validateIds(tasks.map((item) => item.id), 'tasks');
    final statsRaw = domains['stats'];

    return StorageSnapshot(
      id: id,
      version: version,
      createdAt: createdAt,
      skills: skills,
      tasks: tasks,
      profile: decodeProfile(requiredString('profile')),
      history: decodeList('history', decodeHistoryEntry),
      achievements: decodeList('achievements', decodeAchievement),
      stats: statsRaw == null
          ? null
          : decodeDailyStats(decodeMap(requiredString('stats'))),
      bosses: decodeList('bosses', decodeBoss),
      rewardChests: decodeList('rewardChests', decodeRewardChest),
      buffs: decodeList('buffs', decodeBuff),
      weeklyGoals: decodeList('weeklyGoals', decodeWeeklyGoal),
      bestStreak: requiredInt('bestStreak'),
      isDark: requiredBool('isDark'),
      sfxEnabled: requiredBool('sfxEnabled'),
      tooltipsEnabled: requiredBool('tooltipsEnabled'),
      onboardingSeen: requiredBool('onboardingSeen'),
      tutorialProgress: TutorialProgress.fromJson(
        decodeMap(requiredString('tutorialProgress')),
      ),
    );
  }

  void _validateIds(Iterable<String> ids, String domain) {
    final unique = <String>{};
    for (final id in ids) {
      if (id.isEmpty || !unique.add(id)) {
        throw FormatException('Snapshot $domain ids are invalid.');
      }
    }
  }
}
