import 'models.dart';

const int kStorageSnapshotVersion = 1;

class StorageSnapshot {
  StorageSnapshot({
    required this.id,
    required this.createdAt,
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
    required this.bestStreak,
    required this.isDark,
    required this.sfxEnabled,
    required this.tooltipsEnabled,
    required this.onboardingSeen,
    required this.tutorialProgress,
    this.version = kStorageSnapshotVersion,
  });

  final String id;
  final int version;
  final DateTime createdAt;
  final List<Skill> skills;
  final List<Task> tasks;
  final UserProfile profile;
  final List<HistoryEntry> history;
  final List<Achievement> achievements;
  final DailyStats? stats;
  final List<Boss> bosses;
  final List<RewardChest> rewardChests;
  final List<Buff> buffs;
  final List<WeeklyGoal> weeklyGoals;
  final int bestStreak;
  final bool isDark;
  final bool sfxEnabled;
  final bool tooltipsEnabled;
  final bool onboardingSeen;
  final TutorialProgress tutorialProgress;
}

enum SnapshotLoadSource { current, previous }

class CommittedSnapshot {
  const CommittedSnapshot({required this.snapshot, required this.source});

  final StorageSnapshot snapshot;
  final SnapshotLoadSource source;
}
