import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/main.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/theme/app_typography.dart';
import 'package:todo_list_app/widgets/main_page.dart';

class _MemoryStorage extends StorageService {
  final bool onboardingSeen = true;
  List<Skill> skills = [];
  List<Task> tasks = [];
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
  Future<List<HistoryEntry>> loadHistory() async => [];

  @override
  Future<void> saveHistory(List<HistoryEntry> values) async {}

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
      ),
    ),
  );
}

Future<AppState> _loadedState(_MemoryStorage storage) async {
  await storage.init();
  final state = AppState(storage: storage, seedDefaults: false);
  await state.loadSavedData();
  return state;
}

void main() {
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
