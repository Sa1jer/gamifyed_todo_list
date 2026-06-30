import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/debug/debug_admin_panel.dart';
import 'package:todo_list_app/debug/debug_service.dart';
import 'package:todo_list_app/main.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/utils.dart';
import 'package:todo_list_app/widgets/dialogs.dart';
import 'package:todo_list_app/widgets/skills_panel.dart';

class InMemoryStorageService extends StorageService {
  List<Skill> skills = [];
  List<Task> tasks = [];
  bool? _theme;
  bool? _tooltipsEnabled;
  bool? _onboardingSeen;
  TutorialProgress? _tutorialProgress;
  int? _bestStreak;

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasSavedSkills() async => skills.isNotEmpty;

  @override
  Future<bool> hasSavedTasks() async => tasks.isNotEmpty;

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
  Future<List<Skill>> loadSkills() async => List.of(skills);

  @override
  Future<void> saveSkills(List<Skill> skills) async {
    this.skills = List.of(skills);
  }

  @override
  Future<List<Task>> loadTasks() async => List.of(tasks);

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    this.tasks = List.of(tasks);
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

  @override
  Future<int?> loadBestStreak() async => _bestStreak;

  @override
  Future<void> saveBestStreak(int value) async {
    _bestStreak = value;
  }
}

class _FakeDebugService extends DebugService {
  DebugAdminDraftState draft;
  bool cleared = false;
  bool _initialized = false;

  _FakeDebugService({required this.draft});

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  Future<DebugAdminDraftState> loadDraftState() async => draft;

  @override
  Future<void> saveDraftState(DebugAdminDraftState state) async {
    draft = state;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    draft = const DebugAdminDraftState.empty();
  }
}

bool _hasContainerWithColor(WidgetTester tester, Color color) {
  return tester.widgetList<Container>(find.byType(Container)).any((container) {
    final decoration = container.decoration;
    return decoration is BoxDecoration && decoration.color == color;
  });
}

void main() {
  test('skill color palette is rainbow ordered', () {
    expect(kColors, hasLength(12));
    expect(kColors.first, const Color(0xFFFF3B30));
    expect(kColors.last, const Color(0xFF8E8E93));
    expect(kColors, isNot(contains(const Color(0xFFFF2D55))));
    expect(kColors.take(4).toList(), const [
      Color(0xFFFF3B30),
      Color(0xFFFF6B2C),
      Color(0xFFFF9500),
      Color(0xFFFFCC00),
    ]);
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService();
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('RPG To-Do List'), findsOneWidget);
    expect(find.text('Действовать сегодня'), findsOneWidget);
    expect(find.text('Первый запуск'), findsOneWidget);
    expect(find.textContaining('В форме достаточно названия'), findsOneWidget);
    expect(find.textContaining('1. Навык'), findsNothing);
    await tester.tap(find.text('Пропустить обучение'));
    await tester.pumpAndSettle();

    expect(find.text('Создать первый навык'), findsWidgets);
    expect(find.text('Карта'), findsWidgets);
    expect(find.text('План'), findsNothing);
    expect(find.byIcon(Icons.edit_note), findsNothing);

    await tester.tap(find.byIcon(Icons.query_stats).first);
    await tester.pump();

    expect(find.text('История роста'), findsWidgets);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.account_tree).first);
    await tester.pump();

    expect(find.text('RoadMap пока пустой'), findsWidgets);
    expect(find.textContaining('Сначала создай первый навык'), findsWidgets);

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pump();

    expect(find.text('Гид по RPG To-Do List'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('First-run tutorial dismisses once and persists', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService();
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Первый запуск'), findsOneWidget);
    expect(storage._onboardingSeen, isFalse);

    await tester.tap(find.text('Пропустить обучение'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('first-run-tutorial-opacity')),
      findsNothing,
    );
    expect(storage._onboardingSeen, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('skill card RoadMap action opens focused RoadMap', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      .._onboardingSeen = true
      ..skills = [
        Skill(
          id: 'skill-roadmap',
          name: 'Подтягивания',
          goal: 'Подтягиваться 20 раз',
          color: const Color(0xFFFF9500),
          icon: Icons.fitness_center,
          treeNodes: [SkillTreeNode(id: 'stage-1', title: 'Основа')],
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final skillName = find.text('Подтягивания').first;
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(skillName));
    await tester.pumpAndSettle();
    addTearDown(() async => gesture.removePointer());

    expect(find.byTooltip('Открыть карту мастерства'), findsNothing);
    await tester.tap(find.byTooltip('Открыть путь навыка в RoadMap'));
    await tester.pumpAndSettle();

    expect(find.text('Дорожная карта'), findsWidgets);
    expect(find.text('Шаблон RoadMap'), findsNothing);
    expect(find.text('Шаблоны'), findsOneWidget);
    expect(find.textContaining('Подтягивания'), findsWidgets);

    await tester.tap(find.text('Развернуть'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Закрыть полноэкранную карту'), findsOneWidget);
  });

  testWidgets('First-run tutorial continues from skill to first quest', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService();
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Создать навык').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Новый навык'), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('first-run-tutorial-opacity')),
          )
          .opacity,
      lessThan(0.05),
    );
    expect(find.textContaining('Достаточно названия и цели'), findsOneWidget);
    expect(find.text('Первый квест'), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), 'Подтягивания');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Подтягиваться 20 раз',
    );
    await tester.ensureVisible(find.text('Создать'));
    await tester.pump();
    await tester.tap(find.text('Создать'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('first-run-tutorial-opacity')),
          )
          .opacity,
      lessThan(0.05),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    final savedUserSkills = storage.skills
        .where((skill) => skill.id != kInboxSkillId)
        .toList();
    expect(savedUserSkills, hasLength(1));
    expect(savedUserSkills.single.treeNodes, isEmpty);
    expect(storage.tasks, isEmpty);
    expect(storage._onboardingSeen, isFalse);
    expect(find.text('Первый квест'), findsWidgets);
    expect(
      find.textContaining('Теперь добавь один маленький квест'),
      findsOneWidget,
    );

    await tester.tap(find.text('Создать квест').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Новый квест'), findsWidgets);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('first-run-tutorial-opacity')),
          )
          .opacity,
      lessThan(0.05),
    );
    expect(
      find.textContaining('Квест — одно конкретное действие'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField).first,
      'Сделать 3 подтягивания',
    );
    await tester.ensureVisible(find.text('Создать'));
    await tester.pump();
    await tester.tap(find.text('Создать'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('first-run-tutorial-opacity')),
          )
          .opacity,
      lessThan(0.05),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    expect(storage.tasks, hasLength(1));
    expect(storage._onboardingSeen, isFalse);
    expect(find.text('Действовать сегодня!'), findsOneWidget);
    expect(
      find.textContaining('Здесь выполняется следующий квест'),
      findsOneWidget,
    );
    expect(find.text('Сделать сейчас'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('core tutorial replay skips skill creation when skill exists', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      .._onboardingSeen = true
      .._tutorialProgress = const TutorialProgress(
        activeModuleId: TutorialModuleIds.core,
      )
      ..skills = [
        Skill(
          id: 'skill-1',
          name: 'Подтягивания',
          goal: 'Подтягиваться 20 раз',
          color: const Color(0xFFFF9500),
          icon: Icons.fitness_center,
        ),
      ];

    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Первый запуск'), findsNothing);
    expect(find.text('Создать навык'), findsNothing);
    expect(find.text('Первый квест'), findsOneWidget);
    expect(find.text('Создать квест'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('first action tutorial continues without completing quest', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final task = Task(
      id: 'task-1',
      title: 'Сделать 3 подтягивания',
      skillId: 'skill-1',
      xpReward: 20,
      type: TaskType.shortTerm,
    );
    final storage = InMemoryStorageService()
      .._onboardingSeen = true
      .._tutorialProgress = const TutorialProgress(
        activeModuleId: TutorialModuleIds.core,
      )
      ..skills = [
        Skill(
          id: 'skill-1',
          name: 'Подтягивания',
          goal: 'Подтягиваться 20 раз',
          color: const Color(0xFFFF9500),
          icon: Icons.fitness_center,
        ),
      ]
      ..tasks = [task];

    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Действовать сегодня!'), findsOneWidget);
    expect(find.text('Понял!'), findsOneWidget);
    expect(find.text('Сделать сейчас'), findsNothing);

    await tester.tap(find.text('Понял!'));
    await tester.pump();

    expect(task.isDone, isFalse);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('first-run-tutorial-opacity')),
          )
          .opacity,
      lessThan(0.05),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('first-run-tutorial-opacity')),
          )
          .opacity,
      lessThan(0.05),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Дорожная карта'), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('first-run-tutorial-opacity')),
          )
          .opacity,
      greaterThan(0.9),
    );
    expect(find.text('Открыть Карту'), findsOneWidget);
    expect(task.isDone, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('XP tutorial opens RoadMap and continues inside the map', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      .._onboardingSeen = true
      .._tutorialProgress = const TutorialProgress(
        activeModuleId: TutorialModuleIds.core,
        activeStepId: TutorialStepIds.coreXpFeedback,
      )
      ..skills = [
        Skill(
          id: 'skill-1',
          name: 'Подтягивания',
          goal: 'Подтягиваться 20 раз',
          color: const Color(0xFFFF9500),
          icon: Icons.fitness_center,
          treeNodes: [SkillTreeNode(id: 'stage-1', title: 'Основа')],
        ),
      ];

    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Дорожная карта'), findsOneWidget);

    await tester.tap(find.text('Открыть Карту'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Дорожная карта'), findsWidgets);
    expect(find.text('Карта'), findsWidgets);
    expect(find.textContaining('Большой пузырь'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Statistics tutorial opens spotlight and completes core module', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      .._onboardingSeen = true
      .._tutorialProgress = const TutorialProgress(
        activeModuleId: TutorialModuleIds.core,
        activeStepId: TutorialStepIds.coreOpenStats,
      )
      ..skills = [
        Skill(
          id: 'skill-1',
          name: 'Подтягивания',
          goal: 'Подтягиваться 20 раз',
          color: const Color(0xFFFF9500),
          icon: Icons.fitness_center,
        ),
      ];

    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Открыть статистику'));
    await tester.pumpAndSettle();

    expect(find.text('Статистика'), findsWidgets);
    expect(find.textContaining('история роста'), findsWidgets);
    expect(find.text('Завершить обучение'), findsOneWidget);

    await tester.tap(find.text('Завершить обучение'));
    await tester.pumpAndSettle();

    expect(storage._onboardingSeen, isTrue);
    expect(
      storage._tutorialProgress!.isModuleCompleted(TutorialModuleIds.core),
      isTrue,
    );

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Трофеи и эффекты'), findsOneWidget);

    await tester.tap(find.text('Открыть трофеи'));
    await tester.pumpAndSettle();

    expect(find.text('Дальше: профиль'), findsOneWidget);

    await tester.tap(find.text('Дальше: профиль'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Профиль и подсказки'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('AddSkillDialog keeps first stage optional and preview first', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<SkillTreeNode>? savedNodes;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddSkillDialog(
            isDark: true,
            showFirstRunHints: true,
            onSave:
                (
                  name,
                  goal,
                  checklist,
                  color,
                  icon,
                  initialTreeNodes,
                  initialQuest,
                ) {
                  savedNodes = initialTreeNodes;
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Достаточно названия и цели'), findsOneWidget);
    expect(find.byKey(const ValueKey('skill-preview-icon')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('skill-preview-icon'))).dy,
      lessThan(tester.getTopLeft(find.text('Название навыка')).dy),
    );
    for (var i = 0; i < kColors.length; i++) {
      expect(find.byKey(ValueKey('skill-color-$i')), findsOneWidget);
    }

    await tester.enterText(find.byType(TextField).at(0), 'Плавание');
    await tester.enterText(find.byType(TextField).at(1), 'Проплыть километр');
    await tester.ensureVisible(find.text('Создать'));
    await tester.pump();
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();

    expect(savedNodes, isEmpty);
  });

  testWidgets('Tooltip visibility follows saved setting', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService().._tooltipsEnabled = false;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final visibility = tester.widget<TooltipVisibility>(
      find.byType(TooltipVisibility).first,
    );
    expect(visibility.visible, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'Profile opens tutorial module picker and starts RoadMap replay',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = InMemoryStorageService().._onboardingSeen = true;
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Your Name').first);
      await tester.pumpAndSettle();

      expect(find.text('Пройти обучение заново'), findsOneWidget);

      await tester.ensureVisible(find.text('Пройти обучение заново'));
      await tester.pump();
      await tester.tap(find.text('Пройти обучение заново'));
      await tester.pumpAndSettle();

      expect(find.text('Первый путь'), findsOneWidget);
      expect(find.text('RoadMap'), findsOneWidget);

      await tester.tap(find.text('RoadMap').last);
      await tester.pumpAndSettle();

      expect(find.text('Дорожная карта навыка'), findsOneWidget);
      expect(
        storage._tutorialProgress!.activeModuleId,
        TutorialModuleIds.roadmap,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('Debug admin opens after hidden top-bar gesture', (
    WidgetTester tester,
  ) async {
    final fakeDebugService = _FakeDebugService(
      draft: const DebugAdminDraftState(
        selectedScenarioId: 'epic_chest_pending',
        pendingChestRarity: RewardRarity.epic,
      ),
    );
    addTearDown(() async {
      debugServiceOverride = null;
    });
    debugServiceOverride = fakeDebugService;

    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService().._onboardingSeen = true;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final appMark = find.byKey(const ValueKey('top-bar-app-mark'));
    expect(appMark, findsOneWidget);
    expect(find.text('DEBUG ADMIN'), findsNothing);

    for (var i = 0; i < 4; i++) {
      await tester.tap(appMark);
      await tester.pump(const Duration(milliseconds: 80));
    }

    expect(find.text('DEBUG ADMIN'), findsNothing);

    await tester.tap(appMark);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('DEBUG ADMIN'), findsOneWidget);
    expect(find.text('Debug storage'), findsOneWidget);
    expect(find.textContaining(DebugService.boxName), findsOneWidget);
    expect(find.text('Сценарии'), findsOneWidget);
    expect(find.text('Новый пользователь'), findsOneWidget);
    expect(find.text('Стрик 7 дней'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Достижения'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Достижения'), findsOneWidget);

    final firstAchievementToggle = find.byKey(
      const ValueKey('debug-achievement-toggle-first_task'),
    );
    await tester.ensureVisible(firstAchievementToggle);
    await tester.pumpAndSettle();

    expect(find.text('first_task · locked'), findsOneWidget);
    await tester.tap(firstAchievementToggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('first_task · unlocked'), findsOneWidget);
    expect(
      fakeDebugService.draft.achievementUnlockOverrides['first_task'],
      isTrue,
    );

    final unlockAll = find.byKey(
      const ValueKey('debug-achievements-unlock-all'),
    );
    await tester.ensureVisible(unlockAll);
    await tester.pumpAndSettle();
    await tester.tap(unlockAll);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Unlock all achievements?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Unlock all achievements?'), findsNothing);
    expect(fakeDebugService.draft.achievementUnlockOverrides, hasLength(1));

    await tester.tap(unlockAll);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.widgetWithText(TextButton, 'Unlock all').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      fakeDebugService.draft.achievementUnlockOverrides,
      hasLength(achievementDefinitions.length),
    );
    expect(
      fakeDebugService.draft.achievementUnlockOverrides.values.every(
        (value) => value,
      ),
      isTrue,
    );

    await tester.scrollUntilVisible(
      find.text('Стрик 7 дней'),
      -180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Стрик 7 дней'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Применить сценарий?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Применить сценарий?'), findsNothing);
    expect(storage.skills.where((skill) => skill.id != kInboxSkillId), isEmpty);
    expect(fakeDebugService.draft.selectedScenarioId, 'epic_chest_pending');

    await tester.tap(find.text('Стрик 7 дней'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Применить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(fakeDebugService.draft.selectedScenarioId, 'streak_7');
    expect(
      storage.skills.where((skill) => skill.id != kInboxSkillId),
      hasLength(1),
    );
    expect(storage.tasks, hasLength(1));

    await tester.tap(find.text('Очистить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Очистить debug state?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Очистить debug state?'), findsNothing);
    expect(fakeDebugService.cleared, isFalse);
    expect(
      storage.skills.where((skill) => skill.id != kInboxSkillId),
      hasLength(1),
    );

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('DEBUG ADMIN'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Locked achievement details open without provider crash', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final achievement = Achievement(id: achievementDefinitions.first.id)
      ..def = achievementDefinitions.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AchievementsDialog(achievements: [achievement], isDark: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(achievement.def!.name));
    await tester.pumpAndSettle();

    expect(find.text('Заблокировано'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unlocked achievement details open without provider crash', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final achievement = Achievement(
      id: achievementDefinitions.first.id,
      unlockedAt: DateTime(2026, 6, 20),
    )..def = achievementDefinitions.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AchievementsDialog(achievements: [achievement], isDark: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(achievement.def!.name));
    await tester.pumpAndSettle();

    expect(find.text('Разблокировано!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SkillsPanel add skill dialog opens without provider crash', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService();
    await storage.init();
    final state = AppState(storage: storage);

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateProvider(
          state: state,
          child: const Scaffold(body: SizedBox.expand(child: SkillsPanel())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Навык').first);
    await tester.pumpAndSettle();

    expect(find.text('Новый навык'), findsOneWidget);
    expect(tester.takeException(), isNull);

    state.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('SkillsPanel edit skill dialog opens without provider crash', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService();
    await storage.init();
    final state = AppState(storage: storage);
    state.skills.add(
      Skill(
        id: 'skill-1',
        name: 'Python',
        goal: 'Собрать первый проект',
        color: const Color(0xFF4A9EFF),
        icon: Icons.code,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateProvider(
          state: state,
          child: const Scaffold(body: SizedBox.expand(child: SkillsPanel())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Python')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Редактировать навык'));
    await tester.pumpAndSettle();

    expect(find.text('Редактировать навык'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await mouse.removePointer();
    state.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('SkillsPanel reorder keeps selected skill and stable handles', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(520, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService();
    await storage.init();
    final state = AppState(storage: storage);
    state.addSkill(
      Skill(
        id: 'skill-long',
        name: 'Очень длинное название навыка для проверки перестановки',
        goal: 'Проверить читаемость',
        color: const Color(0xFF4A9EFF),
        icon: Icons.code,
        treeNodes: [SkillTreeNode(id: 'stage-1', title: 'Первый этап')],
      ),
    );
    state.addSkill(
      Skill(
        id: 'skill-short',
        name: 'Короткий',
        goal: 'Проверить порядок',
        color: const Color(0xFF34C759),
        icon: Icons.check,
      ),
    );
    state.selectSkill('skill-long');

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateProvider(
          state: state,
          child: const Scaffold(body: SizedBox.expand(child: SkillsPanel())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('skill-reorder-handle-skill-long')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('skill-reorder-handle-skill-short')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('skill-reorder-handle-$kInboxSkillId')),
      findsNothing,
    );
    final handleVisibility = find.byKey(
      const ValueKey('skill-reorder-handle-visibility-skill-long'),
    );
    expect(tester.widget<AnimatedOpacity>(handleVisibility).opacity, 0);
    expect(
      find.byKey(const ValueKey('skill-goal-percent-skill-long')),
      findsNothing,
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('Короткий')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(
              const ValueKey('skill-reorder-handle-visibility-skill-short'),
            ),
          )
          .opacity,
      1,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('skill-reorder-handle-skill-short')),
          )
          .dx,
      closeTo(
        tester.getTopLeft(find.byKey(const ValueKey('skills-list'))).dx,
        1,
      ),
    );

    final list = tester.widget<ReorderableListView>(
      find.byKey(const ValueKey('skills-list')),
    );
    list.onReorderItem!.call(0, 1);
    await tester.pumpAndSettle();

    expect(state.roadmapSkills.map((skill) => skill.id), [
      'skill-short',
      'skill-long',
    ]);
    expect(state.selectedSkillId, 'skill-long');
    expect(tester.takeException(), isNull);

    state.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile skill rail supports long-press reorder', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      .._onboardingSeen = true
      ..skills = [
        Skill(
          id: 'mobile-long',
          name: 'Очень длинное название мобильного навыка',
          goal: 'Проверить мобильную сортировку',
          color: const Color(0xFF4A9EFF),
          icon: Icons.phone_android,
        ),
        Skill(
          id: 'mobile-short',
          name: 'Второй',
          goal: 'Проверить порядок',
          color: const Color(0xFFFF9500),
          icon: Icons.looks_two,
        ),
      ]
      ..tasks = [
        Task(
          id: 'mobile-reorder-task',
          title: 'Проверить сортировку навыков',
          skillId: 'mobile-long',
          xpReward: 20,
          type: TaskType.shortTerm,
        ),
      ];
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byKey(const ValueKey('compact-skill-reorder-mobile-long')),
      findsOneWidget,
    );

    final list = tester.widget<ReorderableListView>(
      find.byKey(const ValueKey('compact-skill-list')),
    );
    list.onReorderItem!.call(0, 1);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      storage.skills
          .where((skill) => skill.id != kInboxSkillId)
          .map((skill) => skill.id),
      ['mobile-short', 'mobile-long'],
    );
    expect(
      find.text('Очень длинное название мобильного навыка'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('desktop skill hover matches its visible card without click', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(500, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const skillId = 'hover-skill';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 330,
              child: SkillCard(
                skill: Skill(
                  id: skillId,
                  name: 'Наведение без клика',
                  goal: 'Проверить pointer geometry',
                  color: const Color(0xFF4A9EFF),
                  icon: Icons.mouse,
                ),
                taskCount: 1,
                isSelected: false,
                isDark: true,
                onTap: () {},
                onRoadmap: () {},
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hitRegion = find.byKey(const ValueKey('skill-card-hit-$skillId'));
    final surface = find.byKey(const ValueKey('skill-card-surface-$skillId'));
    expect(tester.getRect(hitRegion), tester.getRect(surface));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(surface));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.route_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Selected skill does not expose Planning settings in Act', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stage = SkillTreeNode(id: 'stage-1', title: 'Основа');
    final storage = InMemoryStorageService()
      ..skills = [
        Skill(
          id: 'skill-1',
          name: 'Python',
          goal: 'Собрать первый проект',
          color: const Color(0xFF4A9EFF),
          icon: Icons.code,
          treeNodes: [stage],
        ),
      ]
      ..tasks = [
        Task(
          id: 'task-1',
          title: 'Написать функцию',
          skillId: 'skill-1',
          xpReward: 20,
          type: TaskType.shortTerm,
          treeNodeId: stage.id,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Python').first);
    await tester.pumpAndSettle();

    expect(find.text('Настроить'), findsNothing);
    expect(find.text('Настройка навыка: Python'), findsNothing);
    expect(find.text('Новый квест'), findsOneWidget);
    expect(find.text('Написать функцию'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Course nudge stays out of Act and appears in Statistics', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..skills = [
        Skill(
          id: 'skill-1',
          name: 'Python',
          goal: 'Собрать первый проект',
          color: const Color(0xFF4A9EFF),
          icon: Icons.code,
        ),
      ]
      ..tasks = [
        Task(
          id: 'task-1',
          title: 'Написать функцию',
          skillId: 'skill-1',
          xpReward: 20,
          type: TaskType.shortTerm,
        ),
      ];

    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Следующая корректировка'), findsNothing);

    await tester.tap(find.byIcon(Icons.query_stats).first);
    await tester.pumpAndSettle();

    expect(find.text('Следующая корректировка'), findsOneWidget);
    expect(find.text('Добавь лёгкий старт'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('RoadMap keeps skill focus and starts minimum practice', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stage = SkillTreeNode(id: 'stage-1', title: 'Основа');
    final storage = InMemoryStorageService()
      .._onboardingSeen = true
      ..skills = [
        Skill(
          id: 'skill-1',
          name: 'Python',
          goal: 'Собрать первый проект',
          color: const Color(0xFF4A9EFF),
          icon: Icons.code,
          treeNodes: [stage],
        ),
      ]
      ..tasks = [
        Task(
          id: 'task-min',
          title: 'Открыть редактор',
          skillId: 'skill-1',
          xpReward: 20,
          type: TaskType.shortTerm,
          treeNodeId: stage.id,
          minimumAction: 'Открыть файл на 5 минут',
        ),
        Task(
          id: 'task-no-min',
          title: 'Написать модуль',
          skillId: 'skill-1',
          xpReward: 20,
          type: TaskType.shortTerm,
          treeNodeId: stage.id,
        ),
        Task(
          id: 'task-free',
          title: 'Свободный квест навыка',
          skillId: 'skill-1',
          xpReward: 20,
          type: TaskType.shortTerm,
        ),
      ];

    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.account_tree).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Python').first);
    await tester.pumpAndSettle();

    expect(find.text('Шаблон RoadMap'), findsNothing);
    expect(find.text('Шаблоны'), findsOneWidget);
    await tester.tap(find.text('Шаблоны'));
    await tester.pumpAndSettle();
    expect(find.text('Шаблон RoadMap'), findsOneWidget);
    expect(find.text('Назад к навыкам'), findsOneWidget);
    expect(find.text('Квесты без этапа'), findsOneWidget);
    expect(find.text('Свободный квест навыка'), findsOneWidget);

    await tester.tap(find.text('Основа').first);
    await tester.pumpAndSettle();

    expect(find.text('Основа'), findsWidgets);
    expect(find.text('Открыть редактор'), findsOneWidget);
    expect(find.text('Написать модуль'), findsOneWidget);
    expect(find.text('Минимум'), findsOneWidget);
    expect(find.text('Минимальный шаг: Открыть файл на 5 минут'), findsNothing);

    expect(find.text('Переименовать'), findsNothing);
    await tester.tap(find.byTooltip('Переименовать этап'));
    await tester.pumpAndSettle();
    expect(find.text('Переименовать этап'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'База');
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('База'), findsWidgets);

    await tester.tap(find.text('Открыть редактор'));
    await tester.pumpAndSettle();

    expect(find.text('База'), findsWidgets);
    expect(find.text('Минимальный шаг: Открыть файл на 5 минут'), findsNothing);

    await tester.tap(find.text('Минимум'));
    await tester.pumpAndSettle();

    final minimumTask = storage.tasks.firstWhere(
      (task) => task.id == 'task-min',
    );
    final noMinimumTask = storage.tasks.firstWhere(
      (task) => task.id == 'task-no-min',
    );
    expect(minimumTask.minimumActionDoneAt, isNotNull);
    expect(minimumTask.minimumActionEarnedXP, greaterThan(0));
    expect(noMinimumTask.minimumActionDoneAt, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile Act and RoadMap stay readable at 360dp', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const skillName = 'Разработка мобильных приложений';
    const taskTitle =
        'Подготовить длинный сценарий проверки мобильного интерфейса';
    final storage = InMemoryStorageService()
      .._onboardingSeen = true
      ..skills = [
        Skill(
          id: 'mobile-skill',
          name: skillName,
          goal: 'Выпустить устойчивую мобильную версию',
          color: const Color(0xFF4A9EFF),
          icon: Icons.phone_android,
          treeNodes: [SkillTreeNode(id: 'mobile-stage', title: 'Основа')],
        ),
      ]
      ..tasks = [
        Task(
          id: 'mobile-task',
          title: taskTitle,
          description: 'Проверить читаемость и отсутствие переполнений.',
          skillId: 'mobile-skill',
          xpReward: 20,
          type: TaskType.shortTerm,
          minimumAction: 'Открыть экран и проверить один блок',
        ),
      ];

    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Действовать сегодня'), findsOneWidget);
    expect(find.text('Быстрая задача'), findsNothing);
    expect(find.textContaining('Быстрые To-do'), findsNothing);
    expect(find.textContaining(taskTitle), findsWidgets);
    expect(find.textContaining('Минимум:'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Карта').last);
    await tester.pumpAndSettle();

    expect(find.text('Развернуть'), findsNothing);
    final viewerFinder = find.byType(InteractiveViewer).first;
    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    final viewport = tester.getSize(viewerFinder);
    const overviewSkillCenter = Offset(360, 310);
    final initiallyCentered = MatrixUtils.transformPoint(
      viewer.transformationController!.value,
      overviewSkillCenter,
    );
    expect(initiallyCentered.dx, closeTo(viewport.width / 2, 2));
    expect(initiallyCentered.dy, closeTo(viewport.height / 2, 2));

    viewer.transformationController!.value = Matrix4.translationValues(
      72,
      48,
      0,
    );
    await tester.tap(find.text('Отцентровать'));
    await tester.pumpAndSettle();
    final recentered = MatrixUtils.transformPoint(
      viewer.transformationController!.value,
      overviewSkillCenter,
    );
    expect(recentered.dx, closeTo(viewport.width / 2, 2));
    expect(recentered.dy, closeTo(viewport.height / 2, 2));

    final mobileSkillChip = find.text(skillName).last;
    await tester.ensureVisible(mobileSkillChip);
    await tester.tap(mobileSkillChip);
    await tester.pumpAndSettle();

    expect(find.text('Шаблон RoadMap'), findsNothing);
    expect(find.text('Шаблоны'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile AddSkill uses a seven-column icon grid', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddSkillDialog(isDark: true, onSave: (_, _, _, _, _, _, _) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('skill-icon-grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 7);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AddTaskDialog keeps minimum off unless prefilled', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTaskDialog(
            key: const ValueKey('plain-task-dialog'),
            isDark: true,
            skillColor: const Color(0xFF4A9EFF),
            onSave:
                (
                  title,
                  description,
                  xp,
                  type,
                  freq,
                  customDays,
                  priority,
                  minimumAction,
                  subtasks,
                  tags,
                  notificationsEnabled,
                  notificationHour,
                  notificationMinute,
                  treeNodeId,
                ) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    expect(
      find.text('Например: открыть проект и сделать первый шаг'),
      findsNothing,
    );

    final stage = SkillTreeNode(id: 'stage-1', title: 'Основа');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTaskDialog(
            key: const ValueKey('stage-task-dialog'),
            isDark: true,
            skillColor: const Color(0xFF4A9EFF),
            skill: Skill(
              id: 'skill-1',
              name: 'RoadMap',
              goal: 'Проверить этапы',
              color: const Color(0xFF4A9EFF),
              icon: Icons.route,
              treeNodes: [stage],
            ),
            initialTreeNodeId: stage.id,
            onSave:
                (
                  title,
                  description,
                  xp,
                  type,
                  freq,
                  customDays,
                  priority,
                  minimumAction,
                  subtasks,
                  tags,
                  notificationsEnabled,
                  notificationHour,
                  notificationMinute,
                  treeNodeId,
                ) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    expect(find.text('Этап дорожной карты: Основа'), findsOneWidget);
    expect(
      find.text('Например: открыть проект и сделать первый шаг'),
      findsNothing,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTaskDialog(
            key: const ValueKey('prefilled-task-dialog'),
            isDark: true,
            skillColor: const Color(0xFF4A9EFF),
            initialMinimumAction: 'Открыть файл на 5 минут',
            onSave:
                (
                  title,
                  description,
                  xp,
                  type,
                  freq,
                  customDays,
                  priority,
                  minimumAction,
                  subtasks,
                  tags,
                  notificationsEnabled,
                  notificationHour,
                  notificationMinute,
                  treeNodeId,
                ) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    expect(find.text('Открыть файл на 5 минут'), findsOneWidget);
  });

  testWidgets(
    'AddTaskDialog advanced settings restore behavior without noise',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stage = SkillTreeNode(id: 'stage-1', title: 'Основа');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskDialog(
              isDark: true,
              skillColor: const Color(0xFF4A9EFF),
              skill: Skill(
                id: 'skill-1',
                name: 'RoadMap',
                goal: 'Проверить настройки',
                color: const Color(0xFF4A9EFF),
                icon: Icons.route,
                treeNodes: [stage],
              ),
              showFirstRunHints: true,
              onSave:
                  (
                    title,
                    description,
                    xp,
                    type,
                    freq,
                    customDays,
                    priority,
                    minimumAction,
                    subtasks,
                    tags,
                    notificationsEnabled,
                    notificationHour,
                    notificationMinute,
                    treeNodeId,
                  ) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Квест — одно конкретное действие'),
        findsOneWidget,
      );

      expect(find.text('Разово'), findsNothing);

      await tester.tap(find.text('Настройки квеста'));
      await tester.pumpAndSettle();

      expect(find.text('Поведение квеста'), findsOneWidget);
      expect(find.text('Тип квеста'), findsOneWidget);
      expect(find.text('Привычка'), findsOneWidget);
      expect(find.text('Разово'), findsWidgets);
      expect(find.text('Проект'), findsOneWidget);
      expect(find.text('Большая цель'), findsOneWidget);
      expect(find.text('Напоминание'), findsOneWidget);
      expect(find.text('Этап в дорожной карте'), findsOneWidget);
      expect(find.text('SMARTER квеста'), findsOneWidget);
      expect(find.textContaining('S · Конкретно'), findsNothing);
      expect(find.text('Контексты'), findsNothing);
      expect(find.text('Баланс и фокус'), findsNothing);
      expect(find.text('Ручной фокус'), findsNothing);
      expect(find.text('Повторяемость'), findsNothing);

      await tester.ensureVisible(find.text('SMARTER квеста'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SMARTER квеста'));
      await tester.pumpAndSettle();

      expect(find.textContaining('S · Конкретно'), findsOneWidget);
      expect(find.textContaining('M · Измеримо'), findsOneWidget);
      expect(find.textContaining('A · Лёгкий старт'), findsOneWidget);
      expect(find.textContaining('R · Связано'), findsOneWidget);
      expect(find.textContaining('T · Ритм'), findsOneWidget);
      expect(find.textContaining('Review'), findsNothing);

      await tester.tap(find.text('Привычка'));
      await tester.pumpAndSettle();

      expect(find.text('Повторяемость'), findsOneWidget);
      expect(find.text('1 раз за 1 день'), findsOneWidget);
    },
  );

  testWidgets('AddTaskDialog saves optional quest description', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? savedDescription;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTaskDialog(
            isDark: true,
            skillColor: const Color(0xFF4A9EFF),
            onSave:
                (
                  title,
                  description,
                  xp,
                  type,
                  freq,
                  customDays,
                  priority,
                  minimumAction,
                  subtasks,
                  tags,
                  notificationsEnabled,
                  notificationHour,
                  notificationMinute,
                  treeNodeId,
                ) {
                  savedDescription = description;
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Описание'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Закрыть черновик');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Оставить короткую заметку к квесту',
    );
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();

    expect(savedDescription, 'Оставить короткую заметку к квесту');
  });

  testWidgets('AddTaskDialog allows editing XP by typing the number', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const skillColor = Color(0xFFFF6B2C);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTaskDialog(
            isDark: true,
            skillColor: skillColor,
            onSave:
                (
                  title,
                  description,
                  xp,
                  type,
                  freq,
                  customDays,
                  priority,
                  minimumAction,
                  subtasks,
                  tags,
                  notificationsEnabled,
                  notificationHour,
                  notificationMinute,
                  treeNodeId,
                ) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_hasContainerWithColor(tester, skillColor), isTrue);

    await tester.tap(find.text('Настройки квеста'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('20 XP').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('20 XP').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '75');
    expect(_hasContainerWithColor(tester, skillColor), isTrue);
    await tester.tap(find.text('Сохранить').last);
    await tester.pumpAndSettle();

    expect(find.text('75 XP'), findsOneWidget);
  });

  testWidgets('AddTaskDialog supports course nudge prefilled quest', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? savedTitle;
    String? savedMinimum;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTaskDialog(
            isDark: true,
            skillColor: const Color(0xFF4A9EFF),
            initialTitle: 'прочитать 20 страниц',
            initialMinimumAction: 'Открыть книгу на 5 минут',
            focusMinimumAction: true,
            onSave:
                (
                  title,
                  description,
                  xp,
                  type,
                  freq,
                  customDays,
                  priority,
                  minimumAction,
                  subtasks,
                  tags,
                  notificationsEnabled,
                  notificationHour,
                  notificationMinute,
                  treeNodeId,
                ) {
                  savedTitle = title;
                  savedMinimum = minimumAction;
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('прочитать 20 страниц'), findsOneWidget);
    expect(find.text('Открыть книгу на 5 минут'), findsOneWidget);

    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();

    expect(savedTitle, 'прочитать 20 страниц');
    expect(savedMinimum, 'Открыть книгу на 5 минут');
  });
}
