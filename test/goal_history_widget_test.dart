import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/widgets/character_timeline_dialog.dart';

class _NoopStorageService extends StorageService {
  @override
  Future<void> saveTheme(bool isDark) async {}

  @override
  Future<void> saveSfxEnabled(bool enabled) async {}

  @override
  Future<void> saveTooltipsEnabled(bool enabled) async {}

  @override
  Future<void> saveOnboardingSeen(bool seen) async {}

  @override
  Future<void> saveTutorialProgress(TutorialProgress progress) async {}

  @override
  Future<void> saveSkills(List<Skill> skills) async {}

  @override
  Future<void> saveTasks(List<Task> tasks) async {}

  @override
  Future<void> saveProfile(UserProfile profile) async {}

  @override
  Future<void> saveHistory(List<HistoryEntry> entries) async {}

  @override
  Future<void> saveAchievements(List<Achievement> achievements) async {}

  @override
  Future<void> saveStats(DailyStats stats) async {}

  @override
  Future<void> saveBosses(List<Boss> bosses) async {}

  @override
  Future<void> saveRewardChests(List<RewardChest> rewardChests) async {}

  @override
  Future<void> saveBuffs(List<Buff> buffs) async {}

  @override
  Future<void> saveWeeklyGoals(List<WeeklyGoal> goals) async {}

  @override
  Future<void> saveBestStreak(int value) async {}
}

void main() {
  testWidgets('completed goal appears in timeline without mobile overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(storage: _NoopStorageService(), seedDefaults: false);
    state.skills.add(
      Skill(
        id: 'history-skill',
        name: 'Flutter',
        goal: 'Новая цель',
        color: Colors.blue,
        icon: Icons.code,
        completedGoals: [
          CompletedGoal(
            id: 'completed-goal-1',
            skillId: 'history-skill',
            goalText: 'Собрать первое Flutter-приложение',
            completedAt: DateTime(2026, 6, 29, 14),
            progressAtCompletion: 1.0,
            completedStages: 4,
            totalStages: 4,
          ),
        ],
        completedRoadmaps: [
          CompletedRoadmap(
            id: 'completed-roadmap-1',
            skillId: 'history-skill',
            completedGoalId: 'completed-goal-1',
            goalText: 'Собрать первое Flutter-приложение',
            completedAt: DateTime(2026, 6, 29, 14),
            progressAtCompletion: 1.0,
            completedStages: 4,
            totalStages: 4,
            stages: [
              RoadmapStageSnapshot(
                id: 'archived-stage-1',
                title: 'Основа',
                isMastered: true,
              ),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CharacterTimelineDialog(state: state)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Цель достигнута: «Собрать первое Flutter-приложение»'),
      findsOneWidget,
    );
    expect(find.text('Flutter • Этапы: 4/4 • 100%'), findsOneWidget);
    expect(
      find.text('RoadMap сохранена: «Собрать первое Flutter-приложение»'),
      findsOneWidget,
    );
    expect(find.text('Flutter • Архив этапов: 4/4'), findsOneWidget);
    expect(find.text('Цель'), findsOneWidget);
    expect(find.text('RoadMap'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.pump();
  });

  testWidgets('mobile chronicle lazily builds a long history', (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(storage: _NoopStorageService(), seedDefaults: false);
    state.skills.add(
      Skill(
        id: 'long-history-skill',
        name: 'Длинный путь',
        goal: 'Проверить ленивую летопись',
        color: Colors.purple,
        icon: Icons.auto_stories,
        completedGoals: List<CompletedGoal>.generate(
          48,
          (index) => CompletedGoal(
            id: 'goal-$index',
            skillId: 'long-history-skill',
            goalText: 'Рубеж $index',
            completedAt: DateTime(2026, 1, 1).add(Duration(days: index)),
            progressAtCompletion: 1,
            completedStages: 3,
            totalStages: 3,
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CharacterTimelineDialog(state: state, fullScreen: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-secondary-page-Летопись')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mobile-timeline-event-0')),
      220,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('mobile-timeline-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.byKey(const ValueKey('mobile-timeline-event-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-timeline-event-35')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.pump();
  });
}
