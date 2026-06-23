import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/achievement_engine.dart';

void main() {
  group('AchievementEngine', () {
    const engine = AchievementEngine();

    AchievementEngineSnapshot snapshot({
      int totalTasksCompleted = 0,
      int bestStreak = 0,
      int profileLevel = 1,
      int skillsCount = 0,
      bool hasFullyCompletedChecklist = false,
    }) {
      return AchievementEngineSnapshot(
        totalTasksCompleted: totalTasksCompleted,
        bestStreak: bestStreak,
        profileLevel: profileLevel,
        skillsCount: skillsCount,
        hasFullyCompletedChecklist: hasFullyCompletedChecklist,
      );
    }

    test('empty snapshot returns no achievements', () {
      expect(engine.achievementIdsFor(snapshot()), isEmpty);
    });

    test('task thresholds unlock task achievements in legacy order', () {
      expect(engine.achievementIdsFor(snapshot(totalTasksCompleted: 1)), [
        'first_task',
      ]);
      expect(engine.achievementIdsFor(snapshot(totalTasksCompleted: 100)), [
        'first_task',
        'tasks_100',
      ]);
      expect(engine.achievementIdsFor(snapshot(totalTasksCompleted: 500)), [
        'first_task',
        'tasks_100',
        'tasks_500',
      ]);
    });

    test('streak thresholds unlock streak achievements', () {
      expect(engine.achievementIdsFor(snapshot(bestStreak: 7)), ['streak_7']);
      expect(engine.achievementIdsFor(snapshot(bestStreak: 30)), [
        'streak_7',
        'streak_30',
      ]);
    });

    test(
      'profile skill and checklist thresholds unlock growth achievements',
      () {
        final ids = engine.achievementIdsFor(
          snapshot(
            profileLevel: 10,
            skillsCount: 3,
            hasFullyCompletedChecklist: true,
          ),
        );

        expect(ids, ['level_5', 'level_10', 'skills_3', 'all_checklist']);
      },
    );

    test('full snapshot returns ids in previous AppState check order', () {
      final ids = engine.achievementIdsFor(
        snapshot(
          totalTasksCompleted: 500,
          bestStreak: 30,
          profileLevel: 10,
          skillsCount: 3,
          hasFullyCompletedChecklist: true,
        ),
      );

      expect(ids, [
        'first_task',
        'tasks_100',
        'tasks_500',
        'streak_7',
        'streak_30',
        'level_5',
        'level_10',
        'skills_3',
        'all_checklist',
      ]);
    });

    test('boss achievement remains outside pure evaluation engine', () {
      final ids = engine.achievementIdsFor(
        snapshot(
          totalTasksCompleted: 500,
          bestStreak: 30,
          profileLevel: 10,
          skillsCount: 3,
          hasFullyCompletedChecklist: true,
        ),
      );

      expect(ids, isNot(contains('first_boss')));
    });
  });
}
