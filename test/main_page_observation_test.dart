import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/main.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/theme/app_typography.dart';
import 'package:todo_list_app/utils.dart';
import 'package:todo_list_app/widgets/main_page.dart';

class _MemoryStorage extends StorageService {
  final bool onboardingSeen = true;
  List<Skill> skills = [];
  List<Task> tasks = [];
  List<HistoryEntry> history = [];
  UserProfile profile = UserProfile(name: 'Your Name');

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasSavedSkills() async => skills.isNotEmpty;

  @override
  Future<bool> hasSavedTasks() async => tasks.isNotEmpty;

  @override
  Future<bool?> loadTheme() async => true;

  @override
  Future<void> saveTheme(bool value) async {}

  @override
  Future<bool?> loadSfxEnabled() async => true;

  @override
  Future<void> saveSfxEnabled(bool value) async {}

  @override
  Future<bool?> loadTooltipsEnabled() async => true;

  @override
  Future<void> saveTooltipsEnabled(bool value) async {}

  @override
  Future<bool?> loadOnboardingSeen() async => onboardingSeen;

  @override
  Future<void> saveOnboardingSeen(bool value) async {}

  @override
  Future<TutorialProgress?> loadTutorialProgress() async => onboardingSeen
      ? const TutorialProgress(completedModuleIds: {TutorialModuleIds.core})
      : null;

  @override
  Future<void> saveTutorialProgress(TutorialProgress progress) async {}

  @override
  Future<List<Skill>> loadSkills() async => List.of(skills);

  @override
  Future<void> saveSkills(List<Skill> values) async {
    skills = List.of(values);
  }

  @override
  Future<List<Task>> loadTasks() async => List.of(tasks);

  @override
  Future<void> saveTasks(List<Task> values) async {
    tasks = List.of(values);
  }

  @override
  Future<UserProfile> loadProfile() async => profile;

  @override
  Future<void> saveProfile(UserProfile value) async {
    profile = value;
  }

  @override
  Future<List<HistoryEntry>> loadHistory() async => List.of(history);

  @override
  Future<void> saveHistory(List<HistoryEntry> values) async {
    history = List.of(values);
  }

  @override
  Future<List<Achievement>> loadAchievements() async => [];

  @override
  Future<void> saveAchievements(List<Achievement> values) async {}

  @override
  Future<DailyStats?> loadStats() async => null;

  @override
  Future<void> saveStats(DailyStats value) async {}

  @override
  Future<List<Boss>> loadBosses() async => [];

  @override
  Future<void> saveBosses(List<Boss> values) async {}

  @override
  Future<List<RewardChest>> loadRewardChests() async => [];

  @override
  Future<void> saveRewardChests(List<RewardChest> values) async {}

  @override
  Future<List<Buff>> loadBuffs() async => [];

  @override
  Future<void> saveBuffs(List<Buff> values) async {}

  @override
  Future<List<WeeklyGoal>> loadWeeklyGoals() async => [];

  @override
  Future<void> saveWeeklyGoals(List<WeeklyGoal> values) async {}

  @override
  Future<int?> loadBestStreak() async => 0;

  @override
  Future<void> saveBestStreak(int value) async {}
}

ThemeData _testTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4A9EFF),
    brightness: Brightness.dark,
  );
  final textTheme = AppTypography.textTheme(scheme);
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    textTheme: textTheme,
    extensions: [
      AppTextRoles.fromTheme(textTheme, brightness: Brightness.dark),
    ],
  );
}

Widget _mainPageHarness({
  required AppState state,
  VoidCallback? onWorkspaceBuild,
  VoidCallback? onProfileBuild,
  VoidCallback? onTutorialBuild,
  VoidCallback? onEventNotification,
  DateTime Function()? nowForTesting,
}) {
  return MaterialApp(
    theme: _testTheme(),
    home: AppStateProvider(
      state: state,
      child: MainPage(
        key: const ValueKey('main-page-under-test'),
        state: state,
        onToggleTheme: state.toggleTheme,
        onWorkspaceBuildForTesting: onWorkspaceBuild,
        onProfileBuildForTesting: onProfileBuild,
        onTutorialBuildForTesting: onTutorialBuild,
        onEventNotificationForTesting: onEventNotification,
        nowForTesting: nowForTesting,
      ),
    ),
  );
}

_MemoryStorage _returnContextStorage(DateTime now) {
  const skillId = 'return-skill';
  const taskId = 'return-task';
  final skill = Skill(
    id: skillId,
    name: 'Разработка приложения',
    goal: 'Вернуть рабочий контекст без нового доменного состояния',
    color: const Color(0xFF4A9EFF),
    icon: Icons.code_rounded,
  );
  return _MemoryStorage()
    ..skills = [skill]
    ..tasks = [
      Task(
        id: taskId,
        title: 'Проверить редактирование задачи',
        description: 'Проверить существующий сценарий после паузы',
        skillId: skillId,
        xpReward: 20,
        type: TaskType.shortTerm,
        minimumAction: 'Открыть существующую задачу',
      ),
    ]
    ..history = [
      HistoryEntry(
        id: 'return-history',
        taskTitle: 'Исправлена валидация',
        taskId: taskId,
        skillId: skillId,
        skillName: skill.name,
        skillColor: skill.color,
        skillIcon: skill.icon,
        xp: 20,
        isCompletion: true,
        at: now.subtract(const Duration(days: 3)),
      ),
    ];
}

Future<AppState> _loadedState(_MemoryStorage storage) async {
  await storage.init();
  final state = AppState(storage: storage, seedDefaults: false);
  await state.loadSavedData();
  return state;
}

Future<void> _disposeTestState(WidgetTester tester, AppState state) async {
  await tester.pumpWidget(const SizedBox.shrink());
  state.dispose();
  await tester.pump();
}

void main() {
  group('Return Context integration', () {
    final now = DateTime.utc(2026, 7, 18, 12);

    testWidgets(
      'mobile card is primary, dismiss is session-only across resize',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final state = await _loadedState(_returnContextStorage(now));
        await tester.pumpWidget(
          _mainPageHarness(state: state, nowForTesting: () => now),
        );
        await tester.pump();

        expect(
          find.byKey(const ValueKey('return-context-card')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('next-action-lens')), findsNothing);
        expect(state.selectedSkillId, isNull);

        await tester.tap(find.byKey(const ValueKey('return-context-another')));
        await tester.pump();
        expect(find.byKey(const ValueKey('return-context-card')), findsNothing);
        expect(find.byKey(const ValueKey('next-action-lens')), findsOneWidget);
        expect(state.selectedSkillId, isNull);

        tester.view.physicalSize = const Size(1280, 800);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('return-context-card')),
          findsNothing,
          reason: 'dismissal belongs to MainPage session, not one layout',
        );
        await _disposeTestState(tester, state);
      },
    );

    testWidgets('mobile continue revalidates and opens existing Skill focus', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = await _loadedState(_returnContextStorage(now));
      await tester.pumpWidget(
        _mainPageHarness(state: state, nowForTesting: () => now),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('return-context-continue')));
      await tester.pumpAndSettle();

      expect(state.selectedSkillId, 'return-skill');
      expect(
        find.byKey(const ValueKey('mobile-skill-focus-return-skill')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('return-context-card')), findsNothing);
      await _disposeTestState(tester, state);
    });

    testWidgets(
      'continue handles a Task deleted after render without crashing',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final state = await _loadedState(_returnContextStorage(now));
        await tester.pumpWidget(
          _mainPageHarness(state: state, nowForTesting: () => now),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('return-context-card')),
          findsOneWidget,
        );

        // Simulates the candidate becoming stale between paint and the action.
        // No notification is emitted so the rendered candidate stays on screen.
        state.tasks.removeWhere((task) => task.id == 'return-task');
        await tester.tap(find.byKey(const ValueKey('return-context-continue')));
        await tester.pump(const Duration(milliseconds: 600));

        expect(tester.takeException(), isNull);
        expect(state.selectedSkillId, 'return-skill');
        expect(
          find.byKey(const ValueKey('mobile-skill-focus-return-skill')),
          findsOneWidget,
        );
        await _disposeTestState(tester, state);
      },
    );

    testWidgets(
      'desktop card is compact, detached from profile notifications, and routes',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final state = await _loadedState(_returnContextStorage(now));
        var workspaceBuilds = 0;
        await tester.pumpWidget(
          _mainPageHarness(
            state: state,
            nowForTesting: () => now,
            onWorkspaceBuild: () => workspaceBuilds++,
          ),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('return-context-card')),
          findsOneWidget,
        );
        workspaceBuilds = 0;

        state.updateProfileName('Профиль не меняет контекст');
        await tester.pump();
        expect(workspaceBuilds, 0);
        expect(
          find.byKey(const ValueKey('return-context-card')),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 1));

        await tester.tap(find.byKey(const ValueKey('return-context-continue')));
        await tester.pump();
        expect(state.selectedSkillId, 'return-skill');
        expect(find.byKey(const ValueKey('return-context-card')), findsNothing);
        await _disposeTestState(tester, state);
      },
    );

    testWidgets('loading state never exposes Return Context', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AppState(
        storage: _returnContextStorage(now),
        seedDefaults: false,
      );
      await tester.pumpWidget(
        _mainPageHarness(state: state, nowForTesting: () => now),
      );
      await tester.pump();

      expect(state.hasLoadedSavedData, isFalse);
      expect(find.byKey(const ValueKey('return-context-card')), findsNothing);
      await _disposeTestState(tester, state);
    });
  });

  testWidgets(
    'profile and persistence notifications do not rebuild MainPage workspace',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = await _loadedState(_MemoryStorage());
      var workspaceBuilds = 0;
      var profileBuilds = 0;

      await tester.pumpWidget(
        _mainPageHarness(
          state: state,
          onWorkspaceBuild: () => workspaceBuilds++,
          onProfileBuild: () => profileBuilds++,
        ),
      );
      await tester.pump();
      workspaceBuilds = 0;
      profileBuilds = 0;

      state.updateProfileName('Новый профиль');
      await tester.pump();

      expect(workspaceBuilds, 0);
      expect(profileBuilds, 1);
      expect(find.text('Новый профиль'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(
        workspaceBuilds,
        0,
        reason: 'dirty/saving/saved transitions are shell-independent',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'domain, selection, theme, and tutorial changes reach only their boundary',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = await _loadedState(_MemoryStorage());
      var workspaceBuilds = 0;
      var tutorialBuilds = 0;

      await tester.pumpWidget(
        _mainPageHarness(
          state: state,
          onWorkspaceBuild: () => workspaceBuilds++,
          onTutorialBuild: () => tutorialBuilds++,
        ),
      );
      await tester.pump();
      workspaceBuilds = 0;
      tutorialBuilds = 0;

      state.addInboxTask('Проверить ревизию');
      await tester.pump();
      expect(workspaceBuilds, 1);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(workspaceBuilds, 1);

      state.addSkill(
        Skill(
          id: 'observation-skill',
          name: 'Фокус',
          goal: 'Проверить selection projection',
          color: const Color(0xFF4A9EFF),
          icon: Icons.center_focus_strong,
        ),
      );
      await tester.pump();
      workspaceBuilds = 0;

      state.selectSkill('observation-skill');
      await tester.pump();
      expect(workspaceBuilds, 1);

      workspaceBuilds = 0;
      state.toggleTheme();
      await tester.pump();
      expect(workspaceBuilds, 1);

      workspaceBuilds = 0;
      tutorialBuilds = 0;
      state.startTutorialModule(TutorialModuleIds.roadmap);
      await tester.pump();
      expect(workspaceBuilds, 0);
      expect(tutorialBuilds, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      await tester.pump();
    },
  );

  testWidgets('MainPage detaches the old AppState listener on replacement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final first = await _loadedState(_MemoryStorage());
    final second = await _loadedState(_MemoryStorage());
    var notifications = 0;

    await tester.pumpWidget(
      _mainPageHarness(
        state: first,
        onEventNotification: () => notifications++,
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      _mainPageHarness(
        state: second,
        onEventNotification: () => notifications++,
      ),
    );
    await tester.pump();
    notifications = 0;

    first.updateProfileName('Старый state');
    await tester.pump();
    expect(notifications, 0);

    second.updateProfileName('Новый state');
    await tester.pump();
    expect(notifications, greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
    notifications = 0;
    second.updateProfileName('После dispose');
    await tester.pump();
    expect(notifications, 0);

    first.dispose();
    second.dispose();
    await tester.pump();
  });

  testWidgets('captured theme frame is disposed when RPGApp unmounts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final capture = Completer<ui.Image?>();
    var captureRequested = false;
    final storage = _MemoryStorage();
    await tester.pumpWidget(
      RPGApp(
        storage: storage,
        captureFrameForTesting: () {
          captureRequested = true;
          return capture.future;
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const ValueKey('mobile-header-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mobile-menu-theme')));
    await tester.pump();
    await tester.pump();
    expect(captureRequested, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.black, BlendMode.src);
    final image = await recorder.endRecording().toImage(1, 1);
    capture.complete(image);
    await tester.pump();

    expect(image.debugDisposed, isTrue);
  });
}
