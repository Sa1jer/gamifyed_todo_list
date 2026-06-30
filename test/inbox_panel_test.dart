import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/widgets/inbox_panel.dart';

class _InMemoryStorageService extends StorageService {
  List<Skill> _skills = [];
  List<Task> _tasks = [];
  bool? _theme;
  bool? _tooltipsEnabled;
  bool? _onboardingSeen;
  TutorialProgress? _tutorialProgress;
  int? _bestStreak;

  @override
  Future<void> init() async {}

  @override
  Future<bool?> loadTheme() async => _theme;

  @override
  Future<void> saveTheme(bool isDark) async {
    _theme = isDark;
  }

  @override
  Future<bool?> loadSfxEnabled() async => true;

  @override
  Future<void> saveSfxEnabled(bool enabled) async {}

  @override
  Future<bool?> loadTooltipsEnabled() async => _tooltipsEnabled;

  @override
  Future<void> saveTooltipsEnabled(bool enabled) async {
    _tooltipsEnabled = enabled;
  }

  @override
  Future<bool?> loadOnboardingSeen() async => _onboardingSeen;

  @override
  Future<void> saveOnboardingSeen(bool seen) async {
    _onboardingSeen = seen;
  }

  @override
  Future<TutorialProgress?> loadTutorialProgress() async => _tutorialProgress;

  @override
  Future<void> saveTutorialProgress(TutorialProgress progress) async {
    _tutorialProgress = progress;
  }

  @override
  Future<int?> loadBestStreak() async => _bestStreak;

  @override
  Future<void> saveBestStreak(int value) async {
    _bestStreak = value;
  }

  @override
  Future<List<Skill>> loadSkills() async => List.of(_skills);

  @override
  Future<void> saveSkills(List<Skill> skills) async {
    _skills = List.of(skills);
  }

  @override
  Future<List<Task>> loadTasks() async => List.of(_tasks);

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    _tasks = List.of(tasks);
  }

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
  Future<AppState> pumpInboxPanel(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(
      storage: _InMemoryStorageService(),
      seedDefaults: false,
    );

    await tester.pumpWidget(
      AppStateProvider(
        state: state,
        child: AnimatedBuilder(
          animation: state,
          builder: (context, _) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 210,
                child: InboxPanel(
                  onComplete: (taskId, _) => state.completeTask(taskId),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return state;
  }

  testWidgets('inbox panel creates and completes quick task at 360dp', (
    tester,
  ) async {
    final state = await pumpInboxPanel(tester);

    expect(find.text('Задачник'), findsOneWidget);
    expect(find.textContaining('без XP'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), 'Позвонить врачу');
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(state.inboxTasks, hasLength(1));
    expect(state.inboxTasks.single.skillId, kInboxSkillId);
    expect(find.text('Позвонить врачу'), findsOneWidget);
    expect(find.text('без XP'), findsOneWidget);

    await tester.tap(find.byTooltip('Закрыть задачу'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(state.inboxTasks.single.isDone, isTrue);
    expect(state.profile.xp, 0);
    expect(state.history, isEmpty);
    expect(find.byTooltip('Вернуть в Задачник'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await state.flushSaves();
    state.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('inbox panel shows every completed quick task', (tester) async {
    final state = await pumpInboxPanel(tester);

    for (var i = 0; i < 5; i++) {
      state.addInboxTask('Готовая задача $i');
      state.completeTask(state.inboxTasks.last.id);
    }
    await tester.pumpAndSettle();

    expect(find.text('Готово (5)'), findsOneWidget);
    final inboxScroll = find.descendant(
      of: find.byKey(const ValueKey('inbox-list')),
      matching: find.byType(Scrollable),
    );
    for (var i = 4; i >= 0; i--) {
      await tester.scrollUntilVisible(
        find.text('Готовая задача $i'),
        60,
        scrollable: inboxScroll,
      );
      expect(find.text('Готовая задача $i'), findsOneWidget);
    }

    state.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
