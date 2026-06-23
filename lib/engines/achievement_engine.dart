class AchievementEngineSnapshot {
  final int totalTasksCompleted;
  final int bestStreak;
  final int profileLevel;
  final int skillsCount;
  final bool hasFullyCompletedChecklist;

  const AchievementEngineSnapshot({
    required this.totalTasksCompleted,
    required this.bestStreak,
    required this.profileLevel,
    required this.skillsCount,
    required this.hasFullyCompletedChecklist,
  });
}

class AchievementEngine {
  const AchievementEngine();

  List<String> achievementIdsFor(AchievementEngineSnapshot snapshot) {
    final ids = <String>[];

    void addIf(String id, bool condition) {
      if (condition) ids.add(id);
    }

    addIf('first_task', snapshot.totalTasksCompleted >= 1);
    addIf('tasks_100', snapshot.totalTasksCompleted >= 100);
    addIf('tasks_500', snapshot.totalTasksCompleted >= 500);
    addIf('streak_7', snapshot.bestStreak >= 7);
    addIf('streak_30', snapshot.bestStreak >= 30);
    addIf('level_5', snapshot.profileLevel >= 5);
    addIf('level_10', snapshot.profileLevel >= 10);
    addIf('skills_3', snapshot.skillsCount >= 3);
    addIf('all_checklist', snapshot.hasFullyCompletedChecklist);

    return ids;
  }
}
