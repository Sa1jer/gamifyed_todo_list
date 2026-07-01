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
import 'package:todo_list_app/widgets/tasks_panel.dart';

Rect _roadmapVisibleInsertRect(WidgetTester tester, Finder finder) {
  const visibleToHitRatio = 32 / 46;
  final hitRect = tester.getRect(finder);
  return Rect.fromCenter(
    center: hitRect.center,
    width: hitRect.width * visibleToHitRatio,
    height: hitRect.height * visibleToHitRatio,
  );
}

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
    state.addInboxTask('Проверить счётчик Задачника');

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
    final inboxCount = find.byKey(
      ValueKey('skill-inbox-task-count-$kInboxSkillId'),
    );
    expect(inboxCount, findsOneWidget);
    expect(
      find.descendant(of: inboxCount, matching: find.text('1')),
      findsOneWidget,
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
    expect(
      find.byKey(ValueKey('compact-skill-reorder-$kInboxSkillId')),
      findsNothing,
    );

    final listFinder = find.byKey(const ValueKey('compact-skill-list'));
    await tester.drag(listFinder, const Offset(-320, 0));
    await tester.pumpAndSettle();

    expect(find.text('Задачник'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-inbox-task-count')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('compact-skill-reorder-$kInboxSkillId')),
      findsNothing,
    );
    await tester.tap(find.text('Задачник'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Быстрые To-do без XP'), findsOneWidget);
    await tester.drag(listFinder, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mobile-compact-inbox-task-count')),
      findsOneWidget,
    );

    await tester.tap(find.text('Задачник').first);
    await tester.pumpAndSettle();
    await tester.drag(listFinder, const Offset(320, 0));
    await tester.pumpAndSettle();

    final list = tester.widget<ReorderableListView>(listFinder);
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

  testWidgets(
    'mobile skill experience expands, reports progress, and collapses',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const skillId = 'mobile-experience';
      const skillName = 'Очень длинное название навыка для мобильного экрана';
      final storage = InMemoryStorageService()
        .._onboardingSeen = true
        ..skills = [
          Skill(
            id: skillId,
            name: skillName,
            goal: 'Дойти до уверенного результата',
            color: const Color(0xFF4A9EFF),
            icon: Icons.auto_stories_rounded,
            level: 4,
            treeNodes: [
              SkillTreeNode(
                id: 'stage-done',
                title: 'Основа',
                isMastered: true,
              ),
              SkillTreeNode(id: 'stage-next', title: 'Практика'),
            ],
          ),
        ]
        ..tasks = [
          Task(
            id: 'mobile-active-1',
            title: 'Первый квест',
            skillId: skillId,
            xpReward: 20,
            type: TaskType.shortTerm,
          ),
          Task(
            id: 'mobile-active-2',
            title: 'Второй квест',
            skillId: skillId,
            xpReward: 20,
            type: TaskType.shortTerm,
          ),
          Task(
            id: 'mobile-completed',
            title: 'Завершённый квест',
            skillId: skillId,
            xpReward: 20,
            type: TaskType.shortTerm,
            isDone: true,
          ),
        ];
      await storage.init();

      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final expandedPanel = find.byKey(
        const ValueKey('mobile-skill-panel-expanded'),
      );
      final skillCard = find.byKey(
        const ValueKey('mobile-expanded-skill-mobile-experience'),
      );
      expect(expandedPanel, findsOneWidget);
      expect(skillCard, findsOneWidget);
      expect(find.text(skillName), findsOneWidget);
      expect(find.text('Ур. 4'), findsOneWidget);
      expect(find.text('2 квеста'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(
        tester.getTopLeft(expandedPanel).dy,
        lessThan(tester.getTopLeft(find.text('Действовать сегодня')).dy),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(skillCard);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('mobile-skill-panel-compact')),
        findsOneWidget,
      );
      expect(find.text('Фокус: $skillName'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mobile-skill-list-compact')),
        findsOneWidget,
      );

      tester.view.physicalSize = const Size(700, 800);
      await tester.pumpAndSettle();

      expect(find.text('Фокус: $skillName'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('mobile skill without RoadMap stages has neutral progress', (
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
          id: 'mobile-empty-roadmap',
          name: 'Навык без этапов',
          goal: 'Добавить этапы позже',
          color: const Color(0xFFFF9500),
          icon: Icons.lightbulb_outline_rounded,
        ),
      ];
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Этапы не добавлены'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-skill-progress-mobile-empty-roadmap')),
      findsNothing,
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

  testWidgets('QHD skill quest count stays centered in its badge', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2560, 1440);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const skillId = 'qhd-count-skill';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: SkillCard(
                skill: Skill(
                  id: skillId,
                  name: 'QHD badge',
                  goal: 'Проверить центрирование',
                  color: const Color(0xFF4A9EFF),
                  icon: Icons.center_focus_strong,
                ),
                taskCount: 8,
                isSelected: false,
                isDark: true,
                onTap: () {},
                onRoadmap: null,
                onEdit: null,
                onDelete: null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final badge = tester.getRect(
      find.byKey(const ValueKey('skill-task-count-$skillId')),
    );
    final count = tester.getRect(find.text('8'));
    expect(count.center.dx, closeTo(badge.center.dx, 0.5));
    expect(count.center.dy, closeTo(badge.center.dy, 0.5));
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

    await tester.tap(
      find.byKey(const ValueKey('roadmap-delete-task-task-free')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Свободный квест навыка'), findsNothing);
    expect(find.text('Назад к навыкам'), findsOneWidget);
    expect(find.text('Python'), findsWidgets);
    expect(find.text('Выберите навык'), findsNothing);

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

  testWidgets('desktop RoadMap toggles horizontal and vertical layouts', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final root = SkillTreeNode(id: 'layout-root', title: 'Старт');
    final middle = SkillTreeNode(
      id: 'layout-middle',
      title: 'Практика',
      prerequisiteIds: [root.id],
    );
    final terminal = SkillTreeNode(
      id: 'layout-terminal',
      title: 'Результат',
      prerequisiteIds: [middle.id],
    );
    final storage = InMemoryStorageService()
      .._onboardingSeen = true
      ..skills = [
        Skill(
          id: 'layout-skill',
          name: 'Ориентация RoadMap',
          goal: 'Проверить обе раскладки',
          color: const Color(0xFF4A9EFF),
          icon: Icons.route_rounded,
          treeNodes: [root, middle, terminal],
        ),
      ];
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byIcon(Icons.account_tree).first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('roadmap-canvas-horizontal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('roadmap-layout-horizontal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('roadmap-layout-vertical')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('roadmap-layout-horizontal')),
        matching: find.byIcon(Icons.view_stream_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('roadmap-layout-vertical')),
        matching: find.byIcon(Icons.view_week_outlined),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-skill-orb-layout-skill')));
    await tester.pumpAndSettle();

    Finder node(String id) => find.byKey(ValueKey('map-node-layout-skill-$id'));
    Finder nodeSurface(String id) =>
        find.byKey(ValueKey('map-node-surface-layout-skill-$id'));
    Finder nodeLabel(String id) =>
        find.byKey(ValueKey('map-node-label-text-layout-skill-$id'));
    Finder insertion(String leftId, String rightId) =>
        find.byKey(ValueKey('roadmap-insert-layout-skill-$leftId-$rightId'));

    final horizontalRoot = tester.getCenter(node(root.id));
    final horizontalMiddle = tester.getCenter(node(middle.id));
    final horizontalTerminal = tester.getCenter(node(terminal.id));
    final horizontalInsertion = tester.getCenter(insertion(root.id, middle.id));
    final horizontalTerminalInsertion = insertion(terminal.id, 'skill');
    final horizontalSkillSurface = tester.getRect(
      find.byKey(const ValueKey('map-skill-surface-layout-skill')),
    );
    final horizontalTerminalSurface = tester.getRect(nodeSurface(terminal.id));
    expect(horizontalRoot.dx, lessThan(horizontalMiddle.dx));
    expect(horizontalMiddle.dx, lessThan(horizontalTerminal.dx));
    expect((horizontalRoot.dy - horizontalTerminal.dy).abs(), lessThan(2));
    expect(
      horizontalInsertion.dx,
      closeTo((horizontalRoot.dx + horizontalMiddle.dx) / 2, 1),
    );
    expect(
      tester.getCenter(horizontalTerminalInsertion).dx,
      closeTo(
        (horizontalTerminalSurface.right + horizontalSkillSurface.left) / 2,
        1,
      ),
    );
    final horizontalVisibleInsertion = _roadmapVisibleInsertRect(
      tester,
      horizontalTerminalInsertion,
    );
    expect(
      horizontalVisibleInsertion.overlaps(horizontalTerminalSurface),
      isFalse,
    );
    expect(
      horizontalVisibleInsertion.overlaps(horizontalSkillSurface),
      isFalse,
    );

    await tester.tap(find.byKey(const ValueKey('roadmap-layout-vertical')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('roadmap-canvas-vertical')),
      findsOneWidget,
    );
    final verticalRoot = tester.getCenter(node(root.id));
    final verticalMiddle = tester.getCenter(node(middle.id));
    final verticalTerminal = tester.getCenter(node(terminal.id));
    final verticalSkillRect = tester.getRect(
      find.byKey(const ValueKey('map-skill-surface-layout-skill')),
    );
    final verticalGoalRect = tester.getRect(
      find.byKey(const ValueKey('roadmap-goal-anchor-layout-skill')),
    );
    final verticalCanvasRect = tester.getRect(
      find.byKey(const ValueKey('roadmap-canvas-vertical')),
    );
    final skillLabelRect = tester.getRect(
      find.byKey(const ValueKey('map-skill-label-text-layout-skill')),
    );
    expect(
      tester.getRect(nodeLabel(middle.id)).bottom,
      lessThan(
        tester
            .getRect(
              find.byKey(
                const ValueKey('map-node-label-layout-skill-layout-middle'),
              ),
            )
            .bottom,
      ),
    );
    final verticalViewer = tester.widget<InteractiveViewer>(
      find.descendant(
        of: find.byKey(const ValueKey('roadmap-canvas-vertical')),
        matching: find.byType(InteractiveViewer),
      ),
    );
    expect(verticalSkillRect.center.dy, lessThan(verticalTerminal.dy));
    expect(verticalTerminal.dy, lessThan(verticalMiddle.dy));
    expect(verticalMiddle.dy, lessThan(verticalRoot.dy));
    expect((verticalRoot.dx - verticalTerminal.dx).abs(), lessThan(2));
    expect(verticalGoalRect.left, greaterThan(verticalSkillRect.center.dx));
    expect(
      verticalSkillRect.center.dy,
      lessThan(verticalCanvasRect.top + verticalCanvasRect.height * 0.35),
    );
    expect(
      verticalRoot.dy,
      greaterThan(verticalCanvasRect.top + verticalCanvasRect.height * 0.65),
    );
    expect(verticalSkillRect.top, lessThan(verticalCanvasRect.top + 48));
    expect(
      tester.getRect(node(root.id)).bottom,
      greaterThan(verticalCanvasRect.bottom - 48),
    );
    expect(
      verticalViewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(0.6),
    );

    void expectInsertionBetween({
      required Finder insertionFinder,
      required Rect upperLabel,
      required Rect lowerSurface,
    }) {
      final center = tester.getCenter(insertionFinder);
      final visibleCircleBounds = _roadmapVisibleInsertRect(
        tester,
        insertionFinder,
      );
      expect(center.dy, closeTo((upperLabel.bottom + lowerSurface.top) / 2, 1));
      expect(visibleCircleBounds.overlaps(upperLabel), isFalse);
      expect(visibleCircleBounds.overlaps(lowerSurface), isFalse);
    }

    expectInsertionBetween(
      insertionFinder: insertion(root.id, middle.id),
      upperLabel: tester.getRect(nodeLabel(middle.id)),
      lowerSurface: tester.getRect(nodeSurface(root.id)),
    );
    expectInsertionBetween(
      insertionFinder: insertion(middle.id, terminal.id),
      upperLabel: tester.getRect(nodeLabel(terminal.id)),
      lowerSurface: tester.getRect(nodeSurface(middle.id)),
    );
    expectInsertionBetween(
      insertionFinder: insertion(terminal.id, 'skill'),
      upperLabel: skillLabelRect,
      lowerSurface: tester.getRect(nodeSurface(terminal.id)),
    );
    expect(
      tester.getCenter(insertion(terminal.id, 'skill')).dy,
      greaterThan(
        (verticalSkillRect.center.dy +
                tester.getRect(nodeSurface(terminal.id)).center.dy) /
            2,
      ),
    );
    expect(
      find.byKey(
        const ValueKey('roadmap-insert-layout-skill-layout-root-layout-middle'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('roadmap-insert-layout-skill-layout-terminal-skill'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Развернуть'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('roadmap-canvas-vertical')),
      findsNWidgets(2),
    );
    expect(find.byTooltip('Закрыть полноэкранную карту'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Закрыть полноэкранную карту'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('roadmap-layout-horizontal')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('roadmap-canvas-horizontal')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('RoadMap skill orb separates goal and level progress', (
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
          id: 'progress-orb',
          name: 'Прогресс шара',
          goal: 'Освоить два этапа',
          color: const Color(0xFF4A9EFF),
          icon: Icons.track_changes,
          level: 3,
          xp: 120,
          treeNodes: [
            SkillTreeNode(
              id: 'progress-done',
              title: 'Готово',
              isMastered: true,
            ),
            SkillTreeNode(
              id: 'progress-next',
              title: 'Дальше',
              prerequisiteIds: ['progress-done'],
            ),
          ],
        ),
      ];
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byIcon(Icons.account_tree).first);
    await tester.pumpAndSettle();

    final goalProgress = tester.widget<Semantics>(
      find.byKey(const ValueKey('map-skill-goal-progress-progress-orb')),
    );
    final levelProgress = tester.widget<FractionallySizedBox>(
      find.byKey(const ValueKey('map-skill-level-progress-progress-orb')),
    );
    expect(goalProgress.properties.value, '50%');
    expect(levelProgress.widthFactor, closeTo(120 / xpForLevel(3), 0.001));
    expect(find.text('3'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('green RoadMap skill uses gray for mastered stages', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Skill masteredSkill(String id, Color color) => Skill(
      id: id,
      name: id,
      goal: 'Проверить цвет освоения',
      color: color,
      icon: Icons.palette_outlined,
      treeNodes: [
        SkillTreeNode(id: '$id-stage', title: 'Освоено', isMastered: true),
      ],
    );

    final storage = InMemoryStorageService()
      .._onboardingSeen = true
      ..skills = [
        masteredSkill('green-skill', const Color(0xFF34C759)),
        masteredSkill('blue-skill', const Color(0xFF4A9EFF)),
      ];
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byIcon(Icons.account_tree).first);
    await tester.pumpAndSettle();

    Future<Color?> masteredStageColor(String skillId) async {
      await tester.tap(find.byKey(ValueKey('map-skill-orb-$skillId')));
      await tester.pumpAndSettle();
      final node = find.byKey(ValueKey('map-node-$skillId-$skillId-stage'));
      return tester
          .widget<Icon>(
            find.descendant(
              of: node,
              matching: find.byIcon(Icons.workspace_premium),
            ),
          )
          .color;
    }

    expect(await masteredStageColor('green-skill'), const Color(0xFF8E8E93));
    await tester.tap(find.text('Назад к навыкам'));
    await tester.pumpAndSettle();
    expect(await masteredStageColor('blue-skill'), const Color(0xFF34C759));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Rewards places one Effects section above chest list', (
    WidgetTester tester,
  ) async {
    final storage = InMemoryStorageService().._onboardingSeen = true;
    await storage.init();
    final state = AppState(storage: storage, seedDefaults: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: RewardsDialog(state: state)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Пассивные эффекты'), findsNothing);
    expect(find.text('Эффекты'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('rewards-effects-section')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('Эффекты')).dy,
      lessThan(tester.getTopLeft(find.text('Новые сундуки')).dy),
    );
    expect(find.byKey(const ValueKey('empty-buffs')), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rewards-effects-section')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('empty-buffs')), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    state.dispose();
  });

  testWidgets('vertical RoadMap auto-fits a ten-stage chain', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stages = <SkillTreeNode>[];
    for (var index = 0; index < 10; index++) {
      stages.add(
        SkillTreeNode(
          id: 'long-stage-$index',
          title: 'Этап ${index + 1}',
          prerequisiteIds: index == 0 ? [] : ['long-stage-${index - 1}'],
        ),
      );
    }
    final storage = InMemoryStorageService()
      .._onboardingSeen = true
      ..skills = [
        Skill(
          id: 'long-roadmap',
          name: 'Длинная RoadMap',
          goal: 'Пройти десять этапов',
          color: const Color(0xFF34C759),
          icon: Icons.stairs_rounded,
          treeNodes: stages,
        ),
      ];
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byIcon(Icons.account_tree).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-skill-orb-long-roadmap')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('roadmap-layout-vertical')));
    await tester.pumpAndSettle();

    final canvasRect = tester.getRect(
      find.byKey(const ValueKey('roadmap-canvas-vertical')),
    );
    final firstRect = tester.getRect(
      find.byKey(const ValueKey('map-node-long-roadmap-long-stage-0')),
    );
    final terminalRect = tester.getRect(
      find.byKey(const ValueKey('map-node-long-roadmap-long-stage-9')),
    );
    final verticalViewer = tester.widget<InteractiveViewer>(
      find.descendant(
        of: find.byKey(const ValueKey('roadmap-canvas-vertical')),
        matching: find.byType(InteractiveViewer),
      ),
    );
    expect(canvasRect.overlaps(firstRect), isTrue);
    expect(canvasRect.overlaps(terminalRect), isTrue);
    expect(firstRect.center.dy, greaterThan(terminalRect.center.dy));
    expect(
      verticalViewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(0.25),
    );
    for (var index = 0; index < stages.length - 1; index++) {
      final upperLabel = tester.getRect(
        find.byKey(
          ValueKey('map-node-label-text-long-roadmap-long-stage-${index + 1}'),
        ),
      );
      final lowerSurface = tester.getRect(
        find.byKey(ValueKey('map-node-surface-long-roadmap-long-stage-$index')),
      );
      final insertionFinder = find.byKey(
        ValueKey(
          'roadmap-insert-long-roadmap-long-stage-$index-long-stage-${index + 1}',
        ),
      );
      final insertionCenter = tester.getCenter(insertionFinder);
      final visibleCircleBounds = _roadmapVisibleInsertRect(
        tester,
        insertionFinder,
      );
      expect(
        insertionCenter.dy,
        closeTo((upperLabel.bottom + lowerSurface.top) / 2, 1),
      );
      expect(visibleCircleBounds.overlaps(upperLabel), isFalse);
      expect(visibleCircleBounds.overlaps(lowerSurface), isFalse);
      expect(canvasRect.contains(visibleCircleBounds.topLeft), isTrue);
      expect(canvasRect.contains(visibleCircleBounds.bottomRight), isTrue);
    }
    final skillLabel = tester.getRect(
      find.byKey(const ValueKey('map-skill-label-text-long-roadmap')),
    );
    final terminalSurface = tester.getRect(
      find.byKey(const ValueKey('map-node-surface-long-roadmap-long-stage-9')),
    );
    final terminalInsertionFinder = find.byKey(
      const ValueKey('roadmap-insert-long-roadmap-long-stage-9-skill'),
    );
    final terminalInsertionCenter = tester.getCenter(terminalInsertionFinder);
    final terminalVisibleCircle = _roadmapVisibleInsertRect(
      tester,
      terminalInsertionFinder,
    );
    expect(
      terminalInsertionCenter.dy,
      closeTo((skillLabel.bottom + terminalSurface.top) / 2, 1),
    );
    expect(terminalVisibleCircle.overlaps(skillLabel), isFalse);
    expect(terminalVisibleCircle.overlaps(terminalSurface), isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile vertical RoadMap handles zero and one stages', (
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
          id: 'empty-roadmap',
          name: 'Без этапов',
          goal: 'Добавить путь позже',
          color: const Color(0xFFFF9500),
          icon: Icons.hourglass_empty_rounded,
        ),
        Skill(
          id: 'single-roadmap',
          name: 'Один этап',
          goal: 'Пройти первый шаг',
          color: const Color(0xFF4A9EFF),
          icon: Icons.looks_one_rounded,
          treeNodes: [SkillTreeNode(id: 'single-stage', title: 'Первый шаг')],
        ),
      ];
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Карта').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('roadmap-canvas-vertical')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('map-skill-orb-empty-roadmap')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('map-node-empty-roadmap-single-stage')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Назад к навыкам'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('map-skill-orb-single-roadmap')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('map-node-single-roadmap-single-stage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('roadmap-canvas-vertical')),
      findsOneWidget,
    );
    final mobileInsertion = find.byKey(
      const ValueKey('roadmap-insert-single-roadmap-single-stage-skill'),
    );
    expect(mobileInsertion, findsOneWidget);
    final mobileInsertionCenter = tester.getCenter(mobileInsertion);
    final mobileSkillLabel = tester.getRect(
      find.byKey(const ValueKey('map-skill-label-text-single-roadmap')),
    );
    final mobileStageSurface = tester.getRect(
      find.byKey(
        const ValueKey('map-node-surface-single-roadmap-single-stage'),
      ),
    );
    expect(
      mobileInsertionCenter.dy,
      closeTo((mobileSkillLabel.bottom + mobileStageSurface.top) / 2, 1),
    );
    expect(mobileInsertion.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

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
          treeNodes: [
            SkillTreeNode(id: 'mobile-stage', title: 'Основа'),
            SkillTreeNode(
              id: 'mobile-stage-middle',
              title: 'Практика',
              prerequisiteIds: ['mobile-stage'],
            ),
            SkillTreeNode(
              id: 'mobile-stage-terminal',
              title: 'Результат',
              prerequisiteIds: ['mobile-stage-middle'],
            ),
          ],
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
    expect(
      find.byKey(const ValueKey('mobile-skill-panel-expanded')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('mobile-expanded-skill-mobile-skill')),
    );
    await tester.pumpAndSettle();

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

    expect(
      find.byKey(const ValueKey('roadmap-canvas-vertical')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('roadmap-layout-horizontal')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('roadmap-layout-vertical')), findsNothing);
    final mobileRoot = tester.getCenter(
      find.byKey(const ValueKey('map-node-mobile-skill-mobile-stage')),
    );
    final mobileMiddle = tester.getCenter(
      find.byKey(const ValueKey('map-node-mobile-skill-mobile-stage-middle')),
    );
    final mobileTerminal = tester.getCenter(
      find.byKey(const ValueKey('map-node-mobile-skill-mobile-stage-terminal')),
    );
    final mobileSkill = tester.getCenter(
      find.byKey(const ValueKey('map-skill-surface-mobile-skill')),
    );
    final mobileGoal = tester.getRect(
      find.byKey(const ValueKey('roadmap-goal-anchor-mobile-skill')),
    );
    expect(mobileSkill.dy, lessThan(mobileTerminal.dy));
    expect(mobileTerminal.dy, lessThan(mobileMiddle.dy));
    expect(mobileMiddle.dy, lessThan(mobileRoot.dy));
    expect((mobileRoot.dx - mobileTerminal.dx).abs(), lessThan(2));
    expect(mobileGoal.left, greaterThan(mobileSkill.dx));
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

  testWidgets('mobile AddSkill opens full-screen and validates save/cancel', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService().._onboardingSeen = true;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const ValueKey('mobile-add-skill-open')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mobile-add-skill-page')), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('mobile-add-skill-save')));
    await tester.pump();
    expect(find.text('Введите название навыка'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('mobile-form-cancel')));
    await tester.pumpAndSettle();
    expect(storage.skills.where((skill) => skill.id != kInboxSkillId), isEmpty);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('mobile-add-skill-open')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('add-skill-name-field')),
      '  Мобильная разработка  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('add-skill-goal-field')),
      'Собрать приложение',
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('mobile-add-skill-save')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final userSkills = storage.skills
        .where((skill) => skill.id != kInboxSkillId)
        .toList();
    expect(userSkills, hasLength(1));
    expect(userSkills.single.name, 'Мобильная разработка');
    expect(userSkills.single.goal, 'Собрать приложение');
    expect(find.byKey(const ValueKey('mobile-add-skill-page')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile AddTask keeps original stable skill id', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService();
    await storage.init();
    final state = AppState(storage: storage, seedDefaults: false);
    final firstSkill = Skill(
      id: 'mobile-task-a',
      name: 'Flutter',
      goal: 'Создать квест',
      color: const Color(0xFF4A9EFF),
      icon: Icons.code,
      treeNodes: [SkillTreeNode(id: 'stage-a', title: 'Основа')],
    );
    final secondSkill = Skill(
      id: 'mobile-task-b',
      name: 'Фитнес',
      goal: 'Не получить чужой квест',
      color: const Color(0xFFFF9500),
      icon: Icons.fitness_center,
    );
    state.addSkill(firstSkill);
    state.addSkill(secondSkill);
    state.selectSkill(firstSkill.id);

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: state,
          builder: (context, _) => AppStateProvider(
            state: state,
            child: Scaffold(
              body: TasksPanel(
                onComplete: (_, _) {},
                onMinimumAction: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final openButton = find.byKey(
      const ValueKey('add-task-button-mobile-task-a'),
    );
    await tester.tap(openButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mobile-add-task-page')), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    await tester.tap(find.byKey(const ValueKey('mobile-add-task-save')));
    await tester.pump();
    expect(find.text('Введите название квеста'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mobile-form-cancel')));
    await tester.pumpAndSettle();
    expect(state.tasks, isEmpty);

    await tester.tap(openButton);
    await tester.pumpAndSettle();
    state.selectSkill(secondSkill.id);
    await tester.enterText(
      find.byKey(const ValueKey('add-task-title-field')),
      '  Проверить stable id  ',
    );
    await tester.tap(find.byKey(const ValueKey('mobile-add-task-save')));
    await tester.pumpAndSettle();

    expect(state.tasks, hasLength(1));
    expect(state.tasks.single.title, 'Проверить stable id');
    expect(state.tasks.single.skillId, firstSkill.id);
    expect(state.tasks.single.treeNodeId, isNull);
    expect(find.byKey(const ValueKey('mobile-add-task-page')), findsNothing);
    expect(tester.takeException(), isNull);

    state.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile AddTask preserves explicit RoadMap stage id', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stage = SkillTreeNode(id: 'mobile-stage', title: 'Основа');
    final skill = Skill(
      id: 'mobile-stage-skill',
      name: 'Flutter',
      goal: 'Проверить контекст этапа',
      color: const Color(0xFF4A9EFF),
      icon: Icons.code,
      treeNodes: [stage],
    );
    String? savedTreeNodeId;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('open-stage-task-form'),
                onPressed: () => showAdaptiveCreationForm<void>(
                  context: context,
                  builder: (_, fullScreen) => AddTaskDialog(
                    isDark: true,
                    fullScreen: fullScreen,
                    skillColor: skill.color,
                    skill: skill,
                    initialTreeNodeId: stage.id,
                    onSave:
                        (_, _, _, _, _, _, _, _, _, _, _, _, _, treeNodeId) =>
                            savedTreeNodeId = treeNodeId,
                  ),
                ),
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-stage-task-form')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-add-task-page')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('add-task-title-field')),
      'Квест этапа',
    );
    await tester.tap(find.byKey(const ValueKey('mobile-add-task-save')));
    await tester.pumpAndSettle();

    expect(savedTreeNodeId, stage.id);
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
