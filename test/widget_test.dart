import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/main.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';

class InMemoryStorageService extends StorageService {
  bool? _theme;

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasSavedSkills() async => false;

  @override
  Future<bool> hasSavedTasks() async => false;

  @override
  Future<bool?> loadTheme() async => _theme;

  @override
  Future<void> saveTheme(bool isDark) async {
    _theme = isDark;
  }

  @override
  Future<List<Skill>> loadSkills() async => [];

  @override
  Future<void> saveSkills(List<Skill> skills) async {}

  @override
  Future<List<Task>> loadTasks() async => [];

  @override
  Future<void> saveTasks(List<Task> tasks) async {}

  @override
  Future<UserProfile> loadProfile() async => UserProfile(name: 'Your Name');

  @override
  Future<void> saveProfile(UserProfile profile) async {}

  @override
  Future<List<HistoryEntry>> loadHistory() async => [];

  @override
  Future<void> saveHistory(List<HistoryEntry> entries) async {}

  @override
  Future<List<Achievement>> loadAchievements() async => [];

  @override
  Future<void> saveAchievements(List<Achievement> achievements) async {}

  @override
  Future<DailyStats?> loadStats() async => null;

  @override
  Future<void> saveStats(DailyStats stats) async {}

  @override
  Future<List<Boss>> loadBosses() async => [];

  @override
  Future<void> saveBosses(List<Boss> bosses) async {}

  @override
  Future<List<RewardChest>> loadRewardChests() async => [];

  @override
  Future<void> saveRewardChests(List<RewardChest> rewardChests) async {}

  @override
  Future<List<Buff>> loadBuffs() async => [];

  @override
  Future<void> saveBuffs(List<Buff> buffs) async {}

  @override
  Future<List<WeeklyGoal>> loadWeeklyGoals() async => [];

  @override
  Future<void> saveWeeklyGoals(List<WeeklyGoal> goals) async {}
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final storage = InMemoryStorageService();
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('RPG To-Do List'), findsOneWidget);
    expect(find.text('Действовать сегодня'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dashboard_customize).first);
    await tester.pump();

    expect(find.text('Центр прогресса'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_note).first);
    await tester.pump();

    expect(find.text('Планировать систему'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pump();

    expect(find.text('Гид по RPG To-Do List'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
