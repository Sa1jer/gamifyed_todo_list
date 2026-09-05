import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/debug/debug_admin_panel.dart';
import 'package:todo_list_app/debug/debug_service.dart';
import 'package:todo_list_app/main.dart';
import 'package:todo_list_app/models.dart';

import 'package:todo_list_app/tutorial/tutorial_catalog.dart';
import 'package:todo_list_app/utils.dart';

import 'helpers/in_memory_storage_service.dart';
import 'package:todo_list_app/widgets/dialogs.dart';
import 'package:todo_list_app/widgets/daily_victories_dialog.dart';
import 'package:todo_list_app/widgets/character_timeline_dialog.dart';
import 'package:todo_list_app/widgets/skills_panel.dart';
import 'package:todo_list_app/widgets/mobile_journal_tokens.dart';
import 'package:todo_list_app/widgets/desktop_journal_tokens.dart';
import 'package:todo_list_app/widgets/main_page/reward_notice.dart';
import 'package:todo_list_app/widgets/mastery_map_workspace.dart';
import 'package:todo_list_app/widgets/mobile_statistics_page.dart';
import 'package:todo_list_app/widgets/profile_dialog.dart';
import 'package:todo_list_app/widgets/shared.dart';
import 'package:todo_list_app/widgets/tasks_panel.dart';
import 'package:todo_list_app/widgets/weekly_analytics_dialog.dart';

Rect _roadmapVisibleInsertRect(WidgetTester tester, Finder finder) {
  const visibleToHitRatio = 32 / 46;
  final hitRect = tester.getRect(finder);
  return Rect.fromCenter(
    center: hitRect.center,
    width: hitRect.width * visibleToHitRatio,
    height: hitRect.height * visibleToHitRatio,
  );
}

Offset _roadmapScenePointToGlobal(WidgetTester tester, Offset scenePoint) {
  final viewerFinder = find.byType(InteractiveViewer).last;
  final viewer = tester.widget<InteractiveViewer>(viewerFinder);
  final transform = viewer.transformationController!.value;
  return tester.getTopLeft(viewerFinder) +
      MatrixUtils.transformPoint(transform, scenePoint);
}

void _expectRoadmapConnectorsAttached(
  WidgetTester tester, {
  required String skillId,
  required Iterable<String> nodeIds,
  double tolerance = 1.5,
}) {
  final customPaint = tester.widget<CustomPaint>(
    find.byKey(const ValueKey('roadmap-connector-painter')),
  );
  final nodePositions = debugRoadmapConnectorNodePositions(customPaint.painter);
  for (final nodeId in nodeIds) {
    expect(nodePositions, contains(nodeId));
    final paintedCenter = _roadmapScenePointToGlobal(
      tester,
      nodePositions[nodeId]!,
    );
    final renderedCenter = tester.getCenter(
      find.byKey(ValueKey('map-node-surface-$skillId-$nodeId')),
    );
    expect(renderedCenter.dx, closeTo(paintedCenter.dx, tolerance));
    expect(renderedCenter.dy, closeTo(paintedCenter.dy, tolerance));
  }

  final paintedSkillCenter = debugRoadmapConnectorSkillPosition(
    customPaint.painter,
  );
  expect(paintedSkillCenter, isNotNull);
  final renderedSkillCenter = tester.getCenter(
    find.byKey(ValueKey('map-skill-surface-$skillId')),
  );
  final paintedSkillGlobal = _roadmapScenePointToGlobal(
    tester,
    paintedSkillCenter!,
  );
  expect(renderedSkillCenter.dx, closeTo(paintedSkillGlobal.dx, tolerance));
  expect(renderedSkillCenter.dy, closeTo(paintedSkillGlobal.dy, tolerance));
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
  testWidgets('stage progress badge sits below the orb, clear of the label', (
    WidgetTester tester,
  ) async {
    // Бейдж висел `Positioned(bottom: -10)` внутри стека орба: наползал на
    // обводку, а двухстрочная подпись упиралась в него.
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final skill = Skill(
      id: 'badge-skill',
      name: 'Навык',
      goal: 'Цель',
      color: const Color(0xFF4A9EFF),
      icon: Icons.route_rounded,
      treeNodes: [
        SkillTreeNode(
          id: 'badge-stage',
          title: 'Этап с длинным названием в две строки',
          requiredQuestCompletions: 3,
        ),
      ],
    );
    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..welcomeSeen = true
      ..skills = [skill];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.account_tree).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-skill-orb-badge-skill')));
    await tester.pumpAndSettle();

    final orb = find.byKey(
      const ValueKey('map-node-surface-badge-skill-badge-stage'),
    );
    final badge = find.byKey(
      const ValueKey('map-node-progress-badge-skill-badge-stage'),
    );
    final label = find.byKey(
      const ValueKey('map-node-label-badge-skill-badge-stage'),
    );
    expect(orb, findsOneWidget);
    expect(badge, findsOneWidget);

    final orbRect = tester.getRect(orb);
    final badgeRect = tester.getRect(badge);
    final labelRect = tester.getRect(label);

    // Бейдж целиком ниже круга и не касается его.
    expect(badgeRect.top, greaterThanOrEqualTo(orbRect.bottom));
    // Между бейджем и подписью есть зазор.
    expect(labelRect.top, greaterThanOrEqualTo(badgeRect.bottom));
    expect(tester.takeException(), isNull);
  });
  testWidgets('mobile next action panel is compact and can be hidden', (
    WidgetTester tester,
  ) async {
    // Панель занимала 351 px из 852 — больше трети экрана телефона под одну
    // подсказку. Заголовок, чип причины и три полноразмерные кнопки.
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..welcomeSeen = true
      ..skills = [
        Skill(
          id: 'yt',
          name: 'YouTube',
          goal: 'Видео про сборки',
          color: const Color(0xFFFF3B30),
          icon: Icons.tv_rounded,
        ),
      ]
      ..tasks = [
        Task(
          id: 'q1',
          title: 'Записать аудио по сценарию.',
          skillId: 'yt',
          xpReward: 100,
          type: TaskType.shortTerm,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final lens = find.byKey(const ValueKey('next-action-lens'));
    expect(lens, findsOneWidget);
    expect(
      tester.getSize(lens).height,
      lessThan(200),
      reason: 'панель должна оставаться компактной',
    );

    // Зоны нажатия не приносятся в жертву высоте.
    for (final key in [
      'next-action-open-task',
      'next-action-choose-another',
      'next-action-boot-entry',
    ]) {
      expect(
        tester.getSize(find.byKey(ValueKey(key))).height,
        greaterThanOrEqualTo(48),
        reason: key,
      );
    }

    await tester.tap(find.byKey(const ValueKey('next-action-hide')));
    await tester.pumpAndSettle();
    expect(lens, findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('wide profile splits identity and settings into two columns', (
    WidgetTester tester,
  ) async {
    // Раньше окно было 460×680 при доступных 1320×820: шапка занимала
    // половину, а из 1198 px содержимого 857 лежали под сгибом.
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..welcomeSeen = true
      ..skills = [
        Skill(
          id: 'axe',
          name: 'секира',
          goal: 'цель',
          color: const Color(0xFF4A9EFF),
          icon: Icons.fitness_center,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Your Name'));
    await tester.pumpAndSettle();

    const identity = ValueKey('desktop-profile-body-scroll');
    const settings = ValueKey('desktop-profile-settings-scroll');
    expect(find.byKey(identity), findsOneWidget);
    expect(find.byKey(settings), findsOneWidget);

    // Колонки стоят рядом, а не одна под другой.
    final left = tester.getRect(find.byKey(identity));
    final right = tester.getRect(find.byKey(settings));
    expect(left.right, lessThanOrEqualTo(right.left));
    expect(left.top, right.top);

    // Настройки — в правой колонке, путь пользователя — в левой.
    expect(
      find.descendant(
        of: find.byKey(settings),
        matching: find.text('Интерфейс'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(identity),
        matching: find.text('Личные данные'),
      ),
      findsOneWidget,
    );
    // Левая колонка шире правой.
    expect(left.width, greaterThan(right.width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow profile keeps a single column', (
    WidgetTester tester,
  ) async {
    // На узком десктопе две колонки сжались бы в кашу.
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..welcomeSeen = true;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Your Name'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('desktop-profile-body-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-profile-settings-scroll')),
      findsNothing,
    );
    // Настройки не пропали — они ниже по той же колонке.
    await tester.scrollUntilVisible(
      find.text('Данные'),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('desktop-profile-body-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Данные'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('cancelling a tour action offers a way out', (
    WidgetTester tester,
  ) async {
    // Отмена диалога возвращала на побайтово ту же карточку: ни отклика,
    // ни подсказки. Единственными выходами были «создать» и «закрыть тур».
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService();
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(FilledButton).first, warnIfMissed: false);
    await tester.pumpAndSettle();

    String body() => tester
        .widget<Text>(find.byKey(const ValueKey('guided-tour-body')))
        .data!;

    expect(find.text('Первый навык'), findsOneWidget);
    final original = body();
    expect(find.byKey(const ValueKey('guided-tour-skip')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('guided-tour-primary')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsWidgets);

    await tester.tap(find.text('Отмена').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(body(), isNot(original));
    expect(body(), contains('в любой момент'));
    final skip = find.byKey(const ValueKey('guided-tour-skip'));
    expect(skip, findsOneWidget);

    await tester.tap(skip);
    await tester.pumpAndSettle();
    expect(find.text('Первый навык'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('quest reward keeps its gold pill', (WidgetTester tester) async {
    // Подложка под наградой — решение владельца. Значение XP и пилюля идут
    // одним блестящим жёлтым #FFCF40; читаемости это стоит контраста, но
    // выбор сделан осознанно (см. desktop_journal_palette_test.dart).
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..theme = false
      ..skills = [
        Skill(
          id: 'axe',
          name: 'секира',
          goal: 'цель',
          color: const Color(0xFF4A9EFF),
          icon: Icons.fitness_center,
        ),
      ]
      ..tasks = [
        Task(
          id: 'quest-1',
          title: 'Квест',
          skillId: 'axe',
          xpReward: 60,
          type: TaskType.shortTerm,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final pill = find.byKey(const ValueKey('desktop-reward-pill'));
    expect(pill, findsOneWidget);
    expect(find.text('+60 XP'), findsWidgets);
    final decoration =
        tester.widget<Container>(pill).decoration! as BoxDecoration;
    expect(decoration.color, isNotNull);
    expect(decoration.border, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MaterialApp theme follows the saved theme after load', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..theme = false
      ..skills = [
        Skill(
          id: 'axe',
          name: 'секира',
          goal: 'цель',
          color: const Color(0xFF4A9EFF),
          icon: Icons.fitness_center,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // AppState стартует в тёмной теме и переключается на сохранённую уже после
    // загрузки. Раньше MaterialApp не перестраивался и оставался тёмным: тост
    // о росте навыка, слайдеры и переключатели рисовались тёмными в светлом
    // приложении.
    final ctx = tester.element(find.byType(Navigator).first);
    expect(Theme.of(ctx).brightness, Brightness.light);
    expect(tester.takeException(), isNull);
  });

  testWidgets('animated desktop surfaces never rest on transparent black', (
    WidgetTester tester,
  ) async {
    // Colors.transparent — прозрачный ЧЁРНЫЙ. AnimatedContainer лерпит каналы,
    // поэтому переход к светлой поверхности проходил через серый: на белой
    // теме каждое наведение давало вспышку #BBBBBB. Прозрачная стадия обязана
    // нести оттенок своей цели.
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..theme = false
      ..skills = [
        Skill(
          id: 'axe',
          name: 'секира',
          goal: 'цель',
          color: const Color(0xFF4A9EFF),
          icon: Icons.fitness_center,
        ),
        // Второй навык нужен, чтобы в списке была невыбранная карточка:
        // именно её покоящееся состояние раньше было прозрачно-чёрным.
        Skill(
          id: 'lard',
          name: 'курдюк',
          goal: 'цель',
          color: const Color(0xFF34C759),
          icon: Icons.favorite,
        ),
      ]
      ..tasks = [
        Task(
          id: 'quest-1',
          title: 'Квест',
          skillId: 'axe',
          xpReward: 20,
          type: TaskType.shortTerm,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    var checked = 0;
    for (final element in find.byType(AnimatedContainer).evaluate()) {
      final decoration =
          (element.widget as AnimatedContainer).decoration as BoxDecoration?;
      if (decoration == null) continue;
      final colors = <Color?>[decoration.color, decoration.border?.top.color];
      for (final color in colors) {
        if (color == null) continue;
        checked++;
        final isTransparentBlack =
            color.a == 0 && color.r == 0 && color.g == 0 && color.b == 0;
        expect(
          isTransparentBlack,
          isFalse,
          reason:
              'прозрачная стадия анимации должна нести оттенок цели, '
              'иначе переход проходит через серый',
        );
      }
    }
    expect(checked, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('secondary workspaces return to Act on skill and inbox taps', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        Skill(
          id: 'axe',
          name: 'секира',
          goal: 'цель',
          color: const Color(0xFF4A9EFF),
          icon: Icons.fitness_center,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    Future<void> openTrophies() async {
      await tester.tap(find.byKey(const ValueKey('desktop-nav-trophies')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('desktop-trophies-in-progress')),
        findsOneWidget,
      );
    }

    // Клик по навыку из «Трофеев» раньше только менял выбор, экран не менялся.
    await openTrophies();
    await tester.tap(find.byKey(const ValueKey('desktop-skill-surface-axe')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-trophies-in-progress')),
      findsNothing,
    );

    // То же для «Задачника».
    await openTrophies();
    await tester.tap(find.byKey(const ValueKey('desktop-inbox-shortcut')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-trophies-in-progress')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('right rail hides in the Inbox and returns when leaving it', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        Skill(
          id: 'axe',
          name: 'секира',
          goal: 'цель',
          color: const Color(0xFF4A9EFF),
          icon: Icons.fitness_center,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    const rail = ValueKey('desktop-right-rail-region');
    expect(find.byKey(rail), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('desktop-inbox-shortcut')));
    await tester.pumpAndSettle();
    expect(find.byKey(rail), findsNothing);

    await tester.tap(find.byKey(const ValueKey('desktop-skill-surface-axe')));
    await tester.pumpAndSettle();
    expect(find.byKey(rail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('welcome-page')), findsOneWidget);
    expect(find.text('Добро пожаловать'), findsOneWidget);
    expect(find.text('RPG To-Do'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('welcome-begin-action')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();

    expect(find.text('RPG To-Do'), findsOneWidget);
    expect(find.text('Действовать сегодня'), findsOneWidget);
    expect(find.text('Первый навык'), findsOneWidget);
    expect(storage.welcomeSeen, isTrue);
    await tester.tap(find.byKey(const ValueKey('guided-tour-close')));
    await tester.pumpAndSettle();

    expect(find.text('Создай первый навык'), findsWidgets);
    expect(find.text('Карта'), findsWidgets);
    expect(find.text('План'), findsNothing);
    expect(find.byIcon(Icons.edit_note), findsNothing);

    await tester.tap(find.byKey(const ValueKey('desktop-nav-statistics')));
    await tester.pumpAndSettle();

    expect(find.text('История роста'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('desktop-nav-trophies')));
    await tester.pumpAndSettle();
    expect(find.text('Трофеи после действий'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('desktop-nav-map')));
    await tester.pump();

    expect(find.text('RoadMap пока пустой'), findsWidgets);
    expect(find.textContaining('Сначала создай первый навык'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('desktop-settings')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('desktop-settings-workspace')),
      findsOneWidget,
    );
    expect(find.byType(ProfileDialog), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('desktop width renders the three-panel journal shell', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateTime.now();
    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..dailyStats = DailyStats(date: today, tasksCompleted: 2, xpEarned: 40)
      ..skills = [
        Skill(
          id: 'desktop-one',
          name: 'Боевые навыки',
          goal: 'Стать сильнее',
          color: const Color(0xFFFF315B),
          icon: Icons.fitness_center_rounded,
          xp: 340,
        ),
        Skill(
          id: 'desktop-two',
          name: 'Развитие разума',
          goal: 'Читать регулярно',
          color: const Color(0xFFB84DFF),
          icon: Icons.auto_stories_rounded,
          xp: 120,
        ),
      ]
      ..tasks = [
        Task(
          id: 'desktop-active-one',
          title: '100 отжиманий',
          skillId: 'desktop-one',
          xpReward: 80,
          type: TaskType.shortTerm,
        ),
        Task(
          id: 'desktop-active-two',
          title: 'Прочитать 20 страниц',
          skillId: 'desktop-two',
          xpReward: 30,
          type: TaskType.repeating,
          streak: 4,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('desktop-three-panel-shell')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-sidebar-region')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('desktop-main-region')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('desktop-right-rail-region')),
      findsOneWidget,
    );
    expect(find.text('+40'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('2 дн.'), findsNothing);
    expect(find.text('4 дн.'), findsOneWidget);
    expect(find.text('340 / 1000 XP'), findsOneWidget);
    expect(find.text('+80 XP'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('desktop-weekly-xp-divider')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('desktop-weekly-chart'))).height,
      66,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('desktop-skill-xp-section-title')),
          )
          .dy,
      greaterThan(
        tester
            .getBottomLeft(
              find.byKey(const ValueKey('desktop-weekly-xp-divider')),
            )
            .dy,
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('desktop-skill-desktop-two')));
    await tester.pumpAndSettle();
    expect(find.text('120 / 1000 XP'), findsOneWidget);
    expect(find.text('Прочитать 20 страниц'), findsWidgets);
    final activeTask = find.byKey(
      const ValueKey('desktop-active-task-desktop-active-two'),
    );
    await tester.tap(
      find.descendant(
        of: activeTask,
        matching: find.bySemanticsLabel('Выполнить квест'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-completed-task-desktop-active-two')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(
          const ValueKey('desktop-completed-task-desktop-active-two'),
        ),
        matching: find.bySemanticsLabel('Вернуть квест'),
      ),
    );
    await tester.pumpAndSettle();
    expect(activeTask, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop shell stays stable across target widths and light mode',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final width in [
        900.0,
        960.0,
        1024.0,
        1100.0,
        1180.0,
        1280.0,
        1366.0,
        1440.0,
        1920.0,
      ]) {
        tester.view.physicalSize = Size(width, 800);
        final storage = InMemoryStorageService()
          ..onboardingSeen = true
          ..theme = width != 1280
          ..skills = [
            Skill(
              id: 'desktop-responsive-${width.toInt()}',
              name: 'Очень длинное название desktop-навыка $width',
              goal: 'Проверить плотность трёх панелей',
              color: const Color(0xFF2D8CFF),
              icon: Icons.route_rounded,
            ),
          ];
        await storage.init();
        await tester.pumpWidget(RPGApp(storage: storage));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.byKey(const ValueKey('desktop-three-panel-shell')),
          findsOneWidget,
        );
        if (width >= 1024) {
          expect(
            tester
                .widgetList<Semantics>(find.byType(Semantics))
                .any(
                  (semantics) =>
                      semantics.properties.label ==
                      'Фокус на сегодня, выполнено 0 из 0 квестов, 0 процентов',
                ),
            isTrue,
          );
        } else {
          expect(
            find.byKey(const ValueKey('desktop-right-rail-region')),
            findsNothing,
          );
        }
        expect(tester.takeException(), isNull, reason: 'desktop width $width');

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );

  testWidgets('desktop focus hover keeps stable row geometry', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        Skill(
          id: 'hover-skill',
          name: 'Спокойный hover',
          goal: 'Не мигать',
          color: const Color(0xFFFF6B2C),
          icon: Icons.mouse_rounded,
        ),
      ]
      ..tasks = [
        Task(
          id: 'hover-task',
          title: 'Проверить строку',
          skillId: 'hover-skill',
          xpReward: 20,
          type: TaskType.shortTerm,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    final surface = find.byKey(
      const ValueKey('desktop-focus-surface-hover-task'),
    );
    final initialRect = tester.getRect(surface);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(initialRect.center);
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.getRect(surface), initialRect);

    await mouse.moveTo(initialRect.center + const Offset(6, 2));
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getRect(surface), initialRect);

    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.getRect(surface), initialRect);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop focus preserves long titles and reflows large text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    const longTitle =
        'Сделать пятнадцать чистых повторений и записать подробный результат тренировки';
    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        Skill(
          id: 'focus-readable-skill',
          name: 'Очень длинное название речевого навыка',
          goal: 'Читать важное без случайного уменьшения шрифта',
          color: const Color(0xFFFF6B2C),
          icon: Icons.record_voice_over_rounded,
        ),
      ]
      ..tasks = [
        Task(
          id: 'focus-readable-task',
          title: longTitle,
          skillId: 'focus-readable-skill',
          xpReward: 500,
          type: TaskType.shortTerm,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    final titleFinder = find.byKey(
      const ValueKey('desktop-focus-title-focus-readable-task'),
    );
    final surfaceFinder = find.byKey(
      const ValueKey('desktop-focus-surface-focus-readable-task'),
    );
    expect(tester.widget<Text>(titleFinder).maxLines, 2);
    expect(find.text('+500'), findsOneWidget);
    final normalHeight = tester.getSize(surfaceFinder).height;

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(titleFinder).maxLines, 3);
    expect(tester.getSize(surfaceFinder).height, greaterThan(normalHeight));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop Inbox is content-led and submits with Enter', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        Skill(
          id: 'inbox-host-skill',
          name: 'Навык',
          goal: '',
          color: const Color(0xFF2D8CFF),
          icon: Icons.bolt_rounded,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('desktop-inbox-shortcut')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-inbox-workspace')),
      findsOneWidget,
    );
    expect(find.text('Задачник'), findsWidgets);
    expect(find.textContaining('+10 XP'), findsOneWidget);

    final composer = find.byKey(const ValueKey('desktop-inbox-composer'));
    final field = find.descendant(
      of: composer,
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'Ответить на письмо');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Ответить на письмо'), findsOneWidget);
    expect(find.text('АКТИВНЫЕ · 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop RoadMap uses recovered shell and synchronized context', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    Skill skill(String id, String name, Color color) => Skill(
      id: id,
      name: name,
      goal: 'Освоить путь $name',
      color: color,
      icon: Icons.route_rounded,
      treeNodes: [SkillTreeNode(id: '$id-stage', title: 'Основа $name')],
    );
    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        skill('road-shell-a', 'Альфа', const Color(0xFFFF6B2C)),
        skill('road-shell-b', 'Бета', const Color(0xFFB84DFF)),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('desktop-nav-map')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-roadmap-toolbar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-roadmap-context-rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-roadmap-empty-context')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('roadmap-canvas-horizontal')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-skill-orb-road-shell-b')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-roadmap-context-road-shell-b')),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('desktop-skill-semantics-road-shell-b')),
          )
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('desktop-skill-road-shell-b')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('desktop-skill-road-shell-a')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-roadmap-context-road-shell-a')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-roadmap-skill-summary')),
      findsOneWidget,
    );

    final toolbar = find.byKey(const ValueKey('desktop-roadmap-toolbar'));
    await tester.tap(
      find.descendant(of: toolbar, matching: find.text('Шаблоны')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-roadmap-template-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-roadmap-template-grid')),
      findsOneWidget,
    );
    final desktopTemplateGrid = tester.widget<GridView>(
      find.byKey(const ValueKey('desktop-roadmap-template-grid')),
    );
    expect(
      (desktopTemplateGrid.gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      1,
    );
    for (final title in ['Простой', 'Нормальный', 'Сложный', 'Свой путь']) {
      expect(find.text(title), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(ValueKey('roadmap-template-title-$title')))
            .maxLines,
        2,
      );
    }

    final counterLabel = find.byKey(
      const ValueKey('roadmap-counter-label-Этапов в дороге'),
    );
    final counterControls = find.byKey(
      const ValueKey('roadmap-counter-controls-Этапов в дороге'),
    );
    expect(
      tester.getRect(counterControls).left - tester.getRect(counterLabel).right,
      greaterThanOrEqualTo(10),
    );

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    expect(
      tester.getRect(counterLabel).bottom,
      lessThan(tester.getRect(counterControls).top),
    );
    expect(tester.takeException(), isNull);

    tester.platformDispatcher.textScaleFactorTestValue = 1;
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('roadmap-template-choice-custom')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('roadmap-counter-increase-Этапов в дороге')),
    );
    await tester.tap(find.byKey(const ValueKey('roadmap-template-apply')));
    await tester.pumpAndSettle();
    expect(
      storage.skills
          .firstWhere((skill) => skill.id == 'road-shell-a')
          .treeNodes,
      hasLength(4),
    );
    expect(
      find.byKey(const ValueKey('desktop-roadmap-template-surface')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('desktop-skill-road-shell-b')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-roadmap-context-road-shell-b')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-roadmap-template-surface')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop secondary workspaces expose complete page ecosystems', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final skill = Skill(
      id: 'ecosystem-skill',
      name: 'Экосистема',
      goal: 'Проверить все страницы',
      color: const Color(0xFF34C759),
      icon: Icons.eco_rounded,
      treeNodes: [SkillTreeNode(id: 'ecosystem-stage', title: 'Основа')],
    );
    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [skill]
      ..dailyStats = DailyStats(date: now, tasksCompleted: 1, xpEarned: 20)
      ..history = [
        HistoryEntry(
          id: 'ecosystem-history',
          taskTitle: 'Проверить детали',
          taskId: 'ecosystem-task',
          skillId: skill.id,
          skillName: skill.name,
          skillColor: skill.color,
          skillIcon: skill.icon,
          xp: 20,
          isCompletion: true,
          at: now,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const ValueKey('desktop-nav-trophies')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-trophies-in-progress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-rewards-effects')),
      findsOneWidget,
    );
    expect(find.text('Новые сундуки'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('desktop-rewards-chests')),
      findsOneWidget,
    );
    final effects = find.byKey(const ValueKey('desktop-rewards-effects'));
    final chests = find.byKey(const ValueKey('desktop-rewards-chests'));
    expect(tester.getSize(effects).width, tester.getSize(chests).width);
    expect(tester.getSize(effects).height, lessThan(240));
    expect(tester.getSize(chests).height, lessThan(240));
    // Блок «Как получить трофеи» убран: две из трёх его карточек повторяли
    // достижения из «В процессе», только без прогресса.
    expect(
      find.byKey(const ValueKey('desktop-trophies-how-to')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('desktop-trophies-collection')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('desktop-nav-statistics')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-statistics-summary-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-statistics-growth-history')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-statistics-right-rail')),
      findsOneWidget,
    );
    expect(find.text('Цели и путь'), findsOneWidget);
    expect(find.text('Что продолжить'), findsOneWidget);

    final detailEntries = <(String, String)>[
      ('Победы дня', 'daily'),
      ('Неделя', 'weekly'),
      ('Летопись опыта', 'timeline'),
      ('Срез роста', 'growth'),
      ('Календарь квестов', 'calendar'),
      // «Журнал XP» показывал тот же список закрытых квестов, что и
      // «Летопись», отличаясь только заголовком и цветом иконки. Коллекция
      // достижений уехала в «Трофеи», к активным эффектам и сундукам.
      ('Сопротивление', 'resistance'),
    ];
    for (final entry in detailEntries) {
      final opener = switch (entry.$2) {
        'daily' || 'weekly' || 'timeline' => find.descendant(
          of: find.byKey(const ValueKey('desktop-statistics-growth-history')),
          matching: find.text(entry.$1),
        ),
        _ => find.text(entry.$1),
      };
      await tester.ensureVisible(opener.first);
      await tester.pump();
      await tester.tap(opener.first);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('desktop-statistics-detail-${entry.$2}')),
        findsOneWidget,
        reason: entry.$1,
      );
      expect(find.byType(Dialog), findsNothing, reason: entry.$1);
      await tester.tap(
        find.byKey(const ValueKey('desktop-statistics-detail-back')),
      );
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const ValueKey('desktop-settings')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-settings-workspace')),
      findsOneWidget,
    );
    expect(find.text('ПРОФИЛЬ'), findsOneWidget);
    expect(find.text('ВНЕШНИЙ ВИД И ДВИЖЕНИЕ'), findsOneWidget);
    expect(find.text('ЗВУК И ПОМОЩЬ'), findsOneWidget);
    expect(find.text('ДАННЫЕ НА УСТРОЙСТВЕ'), findsOneWidget);
    expect(find.text('О ПРИЛОЖЕНИИ'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('desktop-settings-theme')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-settings-motion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-settings-sound')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-settings-tooltips')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop skill actions keep geometry and history-aware empty state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final used = Skill(
        id: 'used-empty-skill',
        name: 'Использованный навык',
        goal: 'Сохранить историю',
        color: const Color(0xFFFF6B2C),
        icon: Icons.history_rounded,
      );
      final fresh = Skill(
        id: 'fresh-empty-skill',
        name: 'Новый навык',
        goal: 'Начать с нуля',
        color: const Color(0xFF4A9EFF),
        icon: Icons.auto_awesome_rounded,
      );
      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..skills = [used, fresh]
        ..history = [
          HistoryEntry(
            id: 'used-history',
            taskTitle: 'Старый квест',
            skillId: used.id,
            skillName: used.name,
            skillColor: used.color,
            skillIcon: used.icon,
            xp: 20,
            isCompletion: true,
            at: DateTime.now(),
          ),
        ];
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.byKey(const ValueKey('desktop-first-quest-empty')),
        findsNothing,
      );
      expect(find.text('АКТИВНЫЕ · 0'), findsOneWidget);
      expect(find.text('ВЫПОЛНЕНО · 0'), findsOneWidget);

      final row = find.byKey(const ValueKey('desktop-skill-used-empty-skill'));
      final overflow = find.byKey(
        const ValueKey('desktop-skill-overflow-used-empty-skill'),
      );
      final roadmap = find.byKey(
        const ValueKey('desktop-skill-roadmap-used-empty-skill'),
      );
      final content = find.byKey(
        const ValueKey('desktop-skill-content-used-empty-skill'),
      );
      final initialRect = tester.getRect(row);
      expect(tester.widget<AnimatedOpacity>(overflow).opacity, 0);
      expect(tester.widget<AnimatedOpacity>(roadmap).opacity, 0);
      // Место под лоток действий раскрывается только на время наведения:
      // иначе название и полоса уровня всегда стоят сдвинутыми влево.
      expect(
        (tester.widget<AnimatedPadding>(content).padding as EdgeInsets).right,
        0,
      );
      final initialContentRect = tester.getRect(content);
      final title = find.descendant(
        of: content,
        matching: find.text('Использованный навык'),
      );
      final initialTitleWidth = tester.getRect(title).width;
      expect(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.drag_indicator_rounded),
        ),
        findsNothing,
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(initialRect.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(tester.getRect(row), initialRect);
      expect(tester.widget<AnimatedOpacity>(overflow).opacity, 1);
      expect(tester.widget<AnimatedOpacity>(roadmap).opacity, 1);
      expect(
        (tester.widget<AnimatedPadding>(content).padding as EdgeInsets).right,
        76,
      );
      // Сам бокс отступа занимает ту же ширину — сдвигается его содержимое.
      expect(tester.getRect(content), initialContentRect);
      expect(tester.getRect(title).width, lessThan(initialTitleWidth));
      expect(tester.getRect(overflow).width, 38);
      expect(tester.getRect(roadmap).width, 38);
      final roadmapTrigger = find.descendant(
        of: row,
        matching: find.byTooltip('Открыть путь навыка в RoadMap'),
      );
      expect(tester.getRect(roadmapTrigger).width, 38);
      expect(tester.getRect(roadmapTrigger).height, greaterThanOrEqualTo(44));
      expect(
        tester.getRect(overflow).right,
        lessThanOrEqualTo(tester.getRect(row).right),
      );

      await tester.pumpAndSettle();
      await tester.tap(overflow);
      await tester.pumpAndSettle();
      await mouse.moveTo(const Offset(1000, 700));
      await tester.pump(const Duration(milliseconds: 220));
      expect(tester.widget<AnimatedOpacity>(overflow).opacity, 1);
      expect(find.text('Редактировать навык'), findsOneWidget);
      final editMenuItem = find.byKey(
        const ValueKey('desktop-skill-menu-edit-used-empty-skill'),
      );
      final deleteMenuItem = find.byKey(
        const ValueKey('desktop-skill-menu-delete-used-empty-skill'),
      );
      expect(tester.getRect(editMenuItem).width, greaterThanOrEqualTo(220));
      expect(tester.getRect(deleteMenuItem).width, greaterThanOrEqualTo(220));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Редактировать навык'), findsNothing);

      await mouse.moveTo(initialRect.center);
      await tester.pumpAndSettle();
      await tester.tap(overflow);
      await tester.pumpAndSettle();
      await tester.tap(editMenuItem);
      await tester.pumpAndSettle();
      expect(find.text('Редактировать навык'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('desktop-add-skill-dialog')),
        findsOneWidget,
      );
      await tester.tap(find.text('Отмена').last);
      await tester.pumpAndSettle();

      await mouse.moveTo(initialRect.center);
      await tester.pumpAndSettle();
      await tester.tap(overflow);
      await tester.pumpAndSettle();
      await tester.tap(deleteMenuItem);
      await tester.pumpAndSettle();
      expect(find.text('Удалить навык?'), findsOneWidget);
      await tester.tap(find.text('Отмена').last);
      await tester.pumpAndSettle();

      final skillList = tester.widget<ReorderableListView>(
        find.byKey(const ValueKey('desktop-skill-list')),
      );
      skillList.onReorderItem!.call(0, 1);
      await tester.pumpAndSettle();
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('desktop-skill-fresh-empty-skill')),
            )
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('desktop-skill-used-empty-skill')),
              )
              .dy,
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('desktop-skill-fresh-empty-skill')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('desktop-first-quest-empty')),
        findsOneWidget,
      );
      final firstQuest = find.byKey(
        const ValueKey('desktop-first-quest-empty'),
      );
      final firstQuestSize = tester.getSize(firstQuest);
      expect(firstQuestSize.width, greaterThan(firstQuestSize.height));
      expect(firstQuestSize.width, lessThanOrEqualTo(720));
      expect(firstQuestSize.height, lessThanOrEqualTo(260));
      expect(
        find.text(
          'Начни с небольшого действия, которое поможет двигаться к цели.',
        ),
        findsOneWidget,
      );
      expect(find.text('0 активных'), findsNothing);
      expect(find.text('АКТИВНЫЕ · 0'), findsNothing);
      expect(find.text('ВЫПОЛНЕНО · 0'), findsNothing);

      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pumpAndSettle();
      final freshRow = find.byKey(
        const ValueKey('desktop-skill-fresh-empty-skill'),
      );
      await mouse.moveTo(tester.getRect(freshRow).center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey('desktop-skill-surface-fresh-empty-skill'),
              ),
            )
            .height,
        greaterThanOrEqualTo(62),
      );
      expect(
        tester
            .getRect(
              find.byKey(
                const ValueKey('desktop-skill-overflow-fresh-empty-skill'),
              ),
            )
            .right,
        lessThanOrEqualTo(tester.getRect(freshRow).right),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('desktop navigation hover keeps stable geometry in both themes', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final isDark in [false, true]) {
      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..theme = isDark;
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final nav = find.byKey(const ValueKey('desktop-nav-map'));
      final surface = find.byKey(const ValueKey('desktop-nav-surface-Карта'));
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: const Offset(1, 1));
      await pointer.moveTo(tester.getCenter(nav));
      await tester.pump();
      final stableRect = tester.getRect(surface);
      expect(
        find.descendant(of: nav, matching: find.byType(AnimatedContainer)),
        findsNothing,
      );
      final stableDecoration =
          tester.widget<DecoratedBox>(surface).decoration as BoxDecoration;

      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
        expect(tester.getRect(surface), stableRect);
        expect(
          (tester.widget<DecoratedBox>(surface).decoration as BoxDecoration)
              .color,
          stableDecoration.color,
        );
      }
      await pointer.moveTo(stableRect.center + const Offset(10, 4));
      await tester.pump();
      expect(
        (tester.widget<DecoratedBox>(surface).decoration as BoxDecoration)
            .color,
        stableDecoration.color,
      );
      tester
          .widget<AppStateProvider>(find.byType(AppStateProvider).first)
          .state
          .refresh();
      await tester.pump();
      expect(tester.getRect(surface), stableRect);
      expect(
        (tester.widget<DecoratedBox>(surface).decoration as BoxDecoration)
            .color,
        stableDecoration.color,
      );
      await pointer.moveTo(const Offset(1, 1));
      await tester.pump();
      expect(
        (tester.widget<DecoratedBox>(surface).decoration as BoxDecoration)
            .color,
        Colors.transparent,
      );
      await pointer.moveTo(stableRect.center);
      await tester.pump();
      await pointer.down(stableRect.center);
      await pointer.up();
      await tester.pumpAndSettle();
      final activeColor =
          (tester.widget<DecoratedBox>(surface).decoration as BoxDecoration)
              .color;
      expect(activeColor, isNot(Colors.transparent));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
        expect(tester.getRect(surface), stableRect);
        expect(
          (tester.widget<DecoratedBox>(surface).decoration as BoxDecoration)
              .color,
          activeColor,
        );
      }
      await pointer.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop quest actions preserve reward geometry and name archive semantics',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final skill = Skill(
        id: 'quest-actions-skill',
        name: 'Квесты',
        goal: '',
        color: const Color(0xFFFF4A4A),
        icon: Icons.task_alt_rounded,
      );
      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..skills = [skill]
        ..tasks = [
          Task(
            id: 'quest-active',
            title: 'Активный квест',
            skillId: skill.id,
            xpReward: 80,
            type: TaskType.shortTerm,
          ),
          Task(
            id: 'quest-completed',
            title: 'Завершённый квест',
            skillId: skill.id,
            xpReward: 100,
            earnedXP: 100,
            isDone: true,
            type: TaskType.shortTerm,
          ),
        ];
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final activeRow = find.byKey(
        const ValueKey('desktop-active-task-quest-active'),
      );
      final activeOverflow = find.byKey(
        const ValueKey('desktop-task-overflow-quest-active'),
      );
      final reward = find.descendant(
        of: activeRow,
        matching: find.text('+80 XP'),
      );
      final rowRect = tester.getRect(activeRow);
      final rewardRect = tester.getRect(reward);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(rowRect.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));

      expect(tester.getRect(activeRow), rowRect);
      expect(tester.getRect(reward), rewardRect);
      expect(tester.widget<AnimatedOpacity>(activeOverflow).opacity, 1);

      final completedRow = find.byKey(
        const ValueKey('desktop-completed-task-quest-completed'),
      );
      await mouse.moveTo(tester.getRect(completedRow).center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      final completedOverflow = find.byKey(
        const ValueKey('desktop-task-overflow-quest-completed'),
      );
      await tester.tap(completedOverflow);
      await tester.pumpAndSettle();
      expect(find.text('Архивировать'), findsOneWidget);
      expect(find.text('Убрать в выполнено'), findsNothing);
      expect(find.text('Вернуть из выполненных'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reward notice close works while hovered and advances queued notices',
    (WidgetTester tester) async {
      const metrics = DesktopResponsiveMetrics(
        sidebarWidth: 248,
        railWidth: 260,
        mainPadding: DesktopScale.space24,
        sectionGap: DesktopScale.space16,
        sectionGapLarge: DesktopScale.space24,
        showRightRail: true,
      );
      final notices = <RewardNoticeData>[
        const RewardNoticeData(
          id: 10,
          chestTitles: [],
          buffTitles: ['Фокус'],
          achievementTitles: [],
        ),
        const RewardNoticeData(
          id: 11,
          chestTitles: ['Сундук дисциплины'],
          buffTitles: [],
          achievementTitles: [],
        ),
      ];

      Widget buildHarness(StateSetter setState) => MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              if (notices.isNotEmpty)
                RewardNoticePopover(
                  notice: notices.first,
                  isDark: true,
                  desktop: true,
                  desktopMetrics: metrics,
                  reducedMotion: false,
                  queuedCount: notices.length,
                  autoHideDuration: const Duration(seconds: 30),
                  onShow: () {},
                  onHide: () => setState(() => notices.removeAt(0)),
                ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        StatefulBuilder(builder: (context, setState) => buildHarness(setState)),
      );
      await tester.pump(const Duration(milliseconds: 220));

      final firstNotice = find.byKey(const ValueKey('reward-notice-10'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getRect(firstNotice).center);
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('reward-notice-close')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      await tester.pump();
      expect(firstNotice, findsNothing);
      expect(find.byKey(const ValueKey('reward-notice-11')), findsOneWidget);
      expect(find.text('Получен сундук'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reward notice auto-hide is safe with reduced motion', (
    WidgetTester tester,
  ) async {
    const notice = RewardNoticeData(
      id: 20,
      chestTitles: [],
      buffTitles: [],
      achievementTitles: ['Первый шаг'],
    );
    var hidden = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              RewardNoticePopover(
                notice: notice,
                isDark: true,
                desktop: false,
                desktopMetrics: DesktopResponsiveMetrics.forWidth(390),
                reducedMotion: true,
                queuedCount: 1,
                autoHideDuration: const Duration(milliseconds: 50),
                onShow: () {},
                onHide: () => hidden = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));
    expect(hidden, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reward notice disposes safely during its closing animation', (
    WidgetTester tester,
  ) async {
    const notice = RewardNoticeData(
      id: 21,
      chestTitles: [],
      buffTitles: ['Поток'],
      achievementTitles: [],
    );
    var hidden = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              RewardNoticePopover(
                notice: notice,
                isDark: true,
                desktop: false,
                desktopMetrics: DesktopResponsiveMetrics.forWidth(390),
                reducedMotion: false,
                queuedCount: 1,
                onShow: () {},
                onHide: () => hidden = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(find.byKey(const ValueKey('reward-notice-close')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 220));
    expect(hidden, isFalse);
    expect(tester.takeException(), isNull);
  });

  test('reward notice signature deduplicates recovered batches', () {
    const first = RewardNoticeData(
      id: 1,
      chestTitles: ['Сундук'],
      buffTitles: ['Фокус'],
      achievementTitles: [],
    );
    const recovered = RewardNoticeData(
      id: 2,
      chestTitles: ['Сундук'],
      buffTitles: ['Фокус'],
      achievementTitles: [],
    );
    expect(first.signature, recovered.signature);
  });

  testWidgets(
    'desktop selected-skill header shows real goal and excludes Inbox quests',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final skill = Skill(
        id: 'header-skill',
        name: 'Заголовок навыка',
        goal: 'Собрать портфолио проектов',
        color: const Color(0xFF4A9EFF),
        icon: Icons.code_rounded,
      );
      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..skills = [skill]
        ..tasks = [
          Task(
            id: 'header-active',
            title: 'Сделать первый проект',
            skillId: skill.id,
            xpReward: 20,
            type: TaskType.shortTerm,
          ),
          Task(
            id: 'header-completed',
            title: 'Описать проект',
            skillId: skill.id,
            xpReward: 20,
            type: TaskType.shortTerm,
            isDone: true,
          ),
          Task(
            id: 'header-inbox',
            title: 'Не относится к навыку',
            skillId: kInboxSkillId,
            xpReward: 10,
            type: TaskType.shortTerm,
          ),
        ];
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Заголовок навыка'), findsWidgets);
      expect(find.text('Собрать портфолио проектов'), findsOneWidget);
      expect(find.text('Всего квестов: 2'), findsOneWidget);
      expect(find.text('Всего квестов: 3'), findsNothing);
      expect(find.text('Новый квест'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Всего квестов: 2')).dy,
        greaterThan(tester.getTopLeft(find.text('0 / 1000 XP')).dy),
      );
      final xpRow = tester.getCenter(
        find.byKey(const ValueKey('desktop-skill-xp-row-header-skill')),
      );
      final addQuest = tester.getCenter(
        find.byKey(const ValueKey('desktop-add-task-header-skill')),
      );
      final emblem = tester.getRect(
        find.byKey(const ValueKey('desktop-skill-emblem-header-skill')),
      );
      final contentBlock = tester.getRect(
        find.byKey(const ValueKey('desktop-skill-content-block-header-skill')),
      );
      final title = tester.getRect(
        find.byKey(const ValueKey('desktop-skill-title-header-skill')),
      );
      final progressTrack = tester.getRect(
        find.byKey(const ValueKey('desktop-skill-progress-track-header-skill')),
      );
      final questCount = tester.getRect(
        find.byKey(const ValueKey('desktop-skill-quest-count-header-skill')),
      );

      // The leading emblem and trailing CTA are aligned to the whole three-row
      // content block, not to the middle XP row as the legacy layout was.
      expect(addQuest.dy, closeTo(contentBlock.center.dy, 2));
      expect(emblem.center.dy, closeTo(contentBlock.center.dy, 2));
      expect(emblem.width, 76);
      expect(title.left, closeTo(progressTrack.left, 1));
      expect(title.left, closeTo(questCount.left, 1));
      expect(questCount.top, greaterThan(xpRow.dy));
      expect(progressTrack.right, lessThan(addQuest.dx));
      expect(
        find.ancestor(
          of: find.byKey(
            const ValueKey('desktop-skill-quest-count-header-skill'),
          ),
          matching: find.byType(Chip),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'desktop selected-skill header keeps zero quest count plain when no goal exists',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final skill = Skill(
        id: 'header-zero-skill',
        name: 'Навык без цели',
        goal: '',
        color: const Color(0xFF2ED36F),
        icon: Icons.forest_rounded,
      );
      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..skills = [skill];
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Всего квестов: 0'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('desktop-skill-goal-header-zero-skill')),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.byKey(
            const ValueKey('desktop-skill-quest-count-header-zero-skill'),
          ),
          matching: find.byType(Chip),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'desktop selected-skill header reflows one quest and a long goal safely',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 1280);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final skill = Skill(
        id: 'header-one-skill',
        name: 'Очень длинное название навыка для проверки адаптации',
        goal:
            'Длинная реальная цель должна переноситься без обрезки основной кнопки',
        color: const Color(0xFFFF8A1F),
        icon: Icons.rocket_launch_rounded,
      );
      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..skills = [skill]
        ..tasks = [
          Task(
            id: 'header-one-task',
            title: 'Единственный квест',
            skillId: skill.id,
            xpReward: 20,
            type: TaskType.shortTerm,
          ),
        ];
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Всего квестов: 1'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('desktop-skill-goal-header-one-skill')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('desktop-add-task-header-one-skill')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'desktop selected-skill header keeps its geometry across desktop widths',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final width in [1024.0, 1180.0, 1280.0, 1366.0, 1440.0, 1920.0]) {
        tester.view.physicalSize = Size(width, 1280);
        final skill = Skill(
          id: 'header-matrix-$width',
          name: 'Навык $width',
          goal: 'Реальная цель для проверки desktop-компоновки',
          color: const Color(0xFF4A9EFF),
          icon: Icons.code_rounded,
        );
        final storage = InMemoryStorageService()
          ..onboardingSeen = true
          ..skills = [skill]
          ..tasks = [
            Task(
              id: 'header-matrix-task-$width',
              title: 'Квест',
              skillId: skill.id,
              xpReward: 20,
              type: TaskType.shortTerm,
            ),
          ];
        await storage.init();
        await tester.pumpWidget(
          RPGApp(
            key: ValueKey('desktop-header-matrix-$width'),
            storage: storage,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.byKey(ValueKey('desktop-raised-skill-header-${skill.id}')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('desktop-add-task-${skill.id}')),
          findsOneWidget,
        );
        expect(find.text('Всего квестов: 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'compact width uses the modern mobile shell, not legacy desktop',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = InMemoryStorageService()..onboardingSeen = true;
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.byKey(const ValueKey('desktop-three-panel-shell')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mobile-skill-overview')),
        findsOneWidget,
      );
      expect(find.text('RPG To-Do List'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('secondary desktop navigation returns to the last normal panel', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('desktop-nav-trophies')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-trophies-in-progress')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('desktop-nav-trophies')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('desktop-main-scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty RoadMap uses a constraint-aware desktop presentation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('desktop-nav-map')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('roadmap-empty-large')), findsOneWidget);

    tester.view.physicalSize = const Size(900, 480);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('roadmap-empty-compact')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile header keeps secondary actions in an overflow sheet', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..rewardChests = [
        RewardChest(
          id: 'mobile-header-chest',
          title: 'Новый трофей',
          description: 'Проверка badge',
          rarity: RewardRarity.common,
          sourceKey: 'test',
          unlockedAt: DateTime(2026),
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final menuButton = find.byKey(const ValueKey('mobile-header-menu'));
    expect(menuButton, findsOneWidget);
    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any(
            (semantics) =>
                semantics.properties.label == 'Раздел Сейчас' &&
                semantics.properties.selected == true,
          ),
      isTrue,
    );
    expect(find.byIcon(Icons.volume_up), findsNothing);
    expect(find.byIcon(Icons.help_outline), findsNothing);
    final badge = tester.widget<Badge>(
      find.descendant(of: menuButton, matching: find.byType(Badge)),
    );
    expect(badge.isLabelVisible, isTrue);

    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-header-menu-sheet')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mobile-menu-rewards')), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-menu-stats')), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-menu-sound')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-menu-reduced-motion')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mobile-menu-theme')), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-menu-help')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('mobile-menu-reduced-motion')));
    await tester.pumpAndSettle();
    expect(await storage.loadReducedMotion(), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile statistics workspace has an explicit close action', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const ValueKey('mobile-header-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mobile-menu-stats')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stats-workspace')), findsOneWidget);
    final close = find.byTooltip('Закрыть историю роста');
    expect(close, findsOneWidget);
    await tester.tap(close);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('act-workspace')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-workspace')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile secondary workspaces use full-page routes', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    Future<void> openMenu() async {
      await tester.tap(find.byKey(const ValueKey('mobile-header-menu')));
      await tester.pumpAndSettle();
    }

    await openMenu();
    await tester.tap(find.byKey(const ValueKey('mobile-menu-profile')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-secondary-page-Профиль')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
    final profileHero = find.byKey(const ValueKey('mobile-profile-hero'));
    final profileScroll = find.byKey(const ValueKey('mobile-profile-scroll'));
    final heroTopBeforeScroll = tester.getTopLeft(profileHero).dy;
    await tester.drag(profileScroll, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(profileHero).dy,
      closeTo(heroTopBeforeScroll, 0.1),
    );
    expect(
      tester
          .state<ScrollableState>(
            find.descendant(
              of: profileScroll,
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels,
      greaterThan(0),
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileDialog), findsNothing);

    await openMenu();
    await tester.tap(find.byKey(const ValueKey('mobile-menu-rewards')));
    await tester.pumpAndSettle();
    expect(find.byType(RewardsDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-secondary-page-Трофеи')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(RewardsDialog), findsNothing);

    await openMenu();
    await tester.tap(find.byKey(const ValueKey('mobile-menu-stats')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-workspace')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-secondary-page-Статистика')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final statsScroll = find.descendant(
      of: find.byKey(const ValueKey('stats-workspace')),
      matching: find.byType(Scrollable),
    );
    Future<void> tapStoryCard(int index) async {
      final card = find.byKey(ValueKey('История роста-card-$index'));
      await tester.scrollUntilVisible(card, 160, scrollable: statsScroll);
      await tester.tap(
        find.descendant(of: card, matching: find.byType(GestureDetector)).first,
      );
    }

    await tapStoryCard(0);
    await tester.pumpAndSettle();
    expect(find.byType(DailyVictoriesDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-secondary-page-Победы дня')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tapStoryCard(1);
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyAnalyticsDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-secondary-page-Неделя')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tapStoryCard(2);
    await tester.pumpAndSettle();
    expect(find.byType(CharacterTimelineDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-secondary-page-Летопись')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-workspace')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-workspace')), findsNothing);
    expect(find.byKey(const ValueKey('act-workspace')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in <double>[360, 393, 430]) {
    testWidgets('mobile profile is responsive at ${width.toInt()}dp', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(width, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = InMemoryStorageService()..onboardingSeen = true;
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byKey(const ValueKey('mobile-header-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mobile-menu-profile')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('mobile-secondary-page-Профиль')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mobile-secondary-back-Профиль')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('mobile-profile-hero')), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('mobile-secondary-back-Профиль')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProfileDialog), findsNothing);
    });
  }

  testWidgets('mobile journal stays readable across target widths', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final width in [360.0, 393.0, 430.0, 700.0, 760.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.platformDispatcher.textScaleFactorTestValue = width == 360
          ? 2
          : 1.3;
      final skillId = 'responsive-${width.toInt()}';
      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..theme = width != 393
        ..skills = [
          Skill(
            id: skillId,
            name: 'Длинное название навыка для $width dp',
            goal:
                'Уверенно пройти длинный путь без потери контекста на мобильном экране',
            color: const Color(0xFFFF1635),
            icon: Icons.auto_stories_rounded,
          ),
        ]
        ..tasks = [
          Task(
            id: 'responsive-task-${width.toInt()}',
            title: 'Сделать один понятный следующий шаг',
            skillId: skillId,
            xpReward: 20,
            type: TaskType.shortTerm,
          ),
        ];
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const ValueKey('mobile-header-menu')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mobile-skill-panel-compact')),
        findsOneWidget,
      );
      if (width == 360) {
        expect(find.byKey(const ValueKey('next-action-lens')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('mobile-focus-placeholder')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('focus-placeholder-compact')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('focus-placeholder-hidden')),
          findsNothing,
        );
        expect(find.text('Следующее действие'), findsOneWidget);
      }
      expect(tester.takeException(), isNull, reason: 'overview width: $width');
      final skillChip = find.byKey(ValueKey('mobile-skill-chip-$skillId'));
      await tester.scrollUntilVisible(
        skillChip,
        180,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('mobile-skill-panel-compact')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      if (width <= 430) {
        await tester.drag(
          find
              .descendant(
                of: find.byKey(const ValueKey('mobile-skill-panel-compact')),
                matching: find.byType(Scrollable),
              )
              .first,
          const Offset(0, -160),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(skillChip);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('mobile-selected-skill-focus-$skillId')),
        findsOneWidget,
      );
      final focusError = tester.takeException();
      expect(
        focusError,
        isNull,
        reason:
            'width: $width\n${focusError is FlutterError ? focusError.toStringDeep() : focusError}',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('mobile empty overview replaces the focus placeholder', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Создай первый навык'), findsOneWidget);
    expect(
      find.text('После этого здесь появятся квесты и фокус.'),
      findsOneWidget,
    );
    expect(find.text('Выбери навык для фокуса'), findsNothing);
    expect(
      find.byKey(const ValueKey('mobile-focus-placeholder')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'single skill uses the Next Action empty state at short heights',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..skills = [
          Skill(
            id: 'adaptive-placeholder',
            name: 'Один навык',
            goal: '',
            color: const Color(0xFF4A9EFF),
            icon: Icons.explore_rounded,
          ),
        ];
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('next-action-lens')), findsOneWidget);
      expect(find.byKey(const ValueKey('next-action-empty')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mobile-focus-placeholder')),
        findsNothing,
      );

      tester.view.physicalSize = const Size(360, 760);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('next-action-empty')), findsOneWidget);

      tester.view.physicalSize = const Size(360, 580);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('next-action-empty')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mobile skill focus transition moves surrounding cards', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Skill skill(String id, String name, Color color) => Skill(
      id: id,
      name: name,
      goal: '',
      color: color,
      icon: Icons.explore_rounded,
    );

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        skill('transition-top', 'Верхний', const Color(0xFF4A9EFF)),
        skill('transition-middle', 'Средний', const Color(0xFFFF9500)),
        skill('transition-bottom', 'Нижний', const Color(0xFF34C759)),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('mobile-skill-chip-transition-middle')),
    );
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('mobile-skill-card-exiting-above-transition-top'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-skill-card-opening-transition-middle')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('mobile-skill-card-exiting-below-transition-bottom'),
      ),
      findsOneWidget,
    );

    // Уходящая анимация обзора длится столько же, сколько сама анимация
    // (220 мс), а не магические 180. После неё — ещё кадр на построение
    // фокуса: смена навыка перестраивает экран целиком, и раньше этот
    // тяжёлый кадр попадал в середину перехода.
    await tester.pump(const Duration(milliseconds: 221));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('mobile-skill-focus-transition-middle')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mobile-overview-action')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('mobile-skill-focus-transition-middle')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-skill-overview')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-skill-card-transition-middle')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Welcome starts Core and dismissal persists independently', (
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

    expect(find.byKey(const ValueKey('welcome-page')), findsOneWidget);
    expect(storage.welcomeSeen, isFalse);
    expect(storage.onboardingSeen, isFalse);

    await tester.tap(find.byKey(const ValueKey('welcome-begin-action')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();

    expect(find.text('Первый навык'), findsOneWidget);
    expect(storage.welcomeSeen, isTrue);
    await tester.tap(find.byKey(const ValueKey('guided-tour-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('guided-tour-card')), findsNothing);
    expect(storage.onboardingSeen, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('desktop Profile keeps hero fixed across scroll boundaries', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(960, 620);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();
    final state = AppState(storage: storage, seedDefaults: false);
    state.addSkill(
      Skill(
        id: 'profile-scroll-skill',
        name: 'Длинный навык для профиля',
        goal: 'Проверить нижнюю границу',
        color: const Color(0xFF4A9EFF),
        icon: Icons.route_rounded,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateProvider(
          state: state,
          child: const Scaffold(body: ProfileDialog()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hero = find.byKey(const ValueKey('desktop-profile-fixed-hero'));
    final body = find.byKey(const ValueKey('desktop-profile-body-scroll'));
    expect(hero, findsOneWidget);
    expect(body, findsOneWidget);
    // Именно одна прокручиваемая область тела: у каждого TextField есть
    // собственный внутренний Scrollable, считать их здесь нечего.
    expect(
      find.descendant(
        of: find.byType(ProfileDialog),
        matching: find.byType(ListView),
      ),
      findsOneWidget,
    );
    final heroRect = tester.getRect(hero);

    await tester.drag(body, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(tester.getRect(hero), heroRect);

    await tester.drag(body, const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(tester.getRect(hero), heroRect);

    await tester.drag(body, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.getRect(hero), heroRect);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    state.dispose();
  });

  testWidgets('Core acknowledgement shows one session-only completion card', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = false
      ..tutorialProgress = const TutorialProgress(
        activeModuleId: TutorialModuleIds.core,
        activeStepId: TutorialStepIds.coreCompleteQuest,
        completedStepIds: {
          TutorialStepIds.coreCreateSkill,
          TutorialStepIds.coreCreateQuest,
        },
      )
      ..skills = [
        Skill(
          id: 'skill-core',
          name: 'Плавание',
          goal: 'Проплыть километр',
          color: const Color(0xFF4A9EFF),
          icon: Icons.pool,
        ),
      ]
      ..tasks = [
        Task(
          id: 'task-core',
          title: 'Проплыть 100 метров',
          skillId: 'skill-core',
          xpReward: 20,
          type: TaskType.shortTerm,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();

    expect(find.text('Следующее действие'), findsOneWidget);
    await tester.tap(find.text('Понятно'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tutorial-core-completion')),
      findsOneWidget,
    );
    expect(find.text('Основу ты знаешь.'), findsOneWidget);
    expect(storage.tasks.single.isDone, isFalse);

    await tester.tap(find.byKey(const ValueKey('tutorial-core-start-using')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-core-completion')),
      findsNothing,
    );
    expect(storage.onboardingSeen, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('completed legacy Core does not reopen completion card', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = true
      ..tutorialProgress = const TutorialProgress(
        completedModuleIds: {TutorialModuleIds.core},
        completedStepIds: {
          TutorialStepIds.coreCreateSkill,
          TutorialStepIds.coreCreateQuest,
          TutorialStepIds.coreCompleteQuest,
        },
      );
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tutorial-core-completion')),
      findsNothing,
    );

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
      ..onboardingSeen = true
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

  testWidgets('Core resumes at quest when a skill already exists', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = false
      ..tutorialProgress = const TutorialProgress(
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
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('welcome-page')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();
    expect(find.text('Создать навык'), findsNothing);
    expect(find.text('Первый квест'), findsOneWidget);
    expect(find.text('Создать квест'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('cancelling the real Skill creator keeps Core on Skill', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = false
      ..tutorialProgress = const TutorialProgress(
        activeModuleId: TutorialModuleIds.core,
        activeStepId: TutorialStepIds.coreCreateSkill,
      );
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('guided-tour-primary')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-add-skill-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(storage.skills.where((skill) => skill.id != kInboxSkillId), isEmpty);
    expect(
      storage.tutorialProgress!.activeStepId,
      TutorialStepIds.coreCreateSkill,
    );
    expect(find.text('Первый навык'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('cancelling the real Quest creator keeps Core on Quest', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = false
      ..tutorialProgress = const TutorialProgress(
        activeModuleId: TutorialModuleIds.core,
        activeStepId: TutorialStepIds.coreCreateQuest,
        completedStepIds: {TutorialStepIds.coreCreateSkill},
      )
      ..skills = [
        Skill(
          id: 'cancel-quest-skill',
          name: 'Плавание',
          goal: 'Проплыть километр',
          color: const Color(0xFF4A9EFF),
          icon: Icons.pool_rounded,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('guided-tour-primary')));
    await tester.pumpAndSettle();
    expect(find.byType(AddTaskDialog), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(storage.tasks, isEmpty);
    expect(
      storage.tutorialProgress!.activeStepId,
      TutorialStepIds.coreCreateQuest,
    );
    expect(find.text('Первый квест'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('first useful action acknowledgement does not complete quest', (
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
      ..welcomeSeen = true
      ..onboardingSeen = false
      ..tutorialProgress = const TutorialProgress(
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
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();

    expect(find.text('Следующее действие'), findsOneWidget);
    expect(find.text('Понятно'), findsOneWidget);
    expect(find.text('Сделать сейчас'), findsNothing);

    await tester.tap(find.text('Понятно'));
    await tester.pumpAndSettle();

    expect(task.isDone, isFalse);
    expect(storage.onboardingSeen, isTrue);
    expect(
      storage.tutorialProgress!.isModuleCompleted(TutorialModuleIds.core),
      isTrue,
    );
    expect(
      storage.tutorialProgress!.isModuleCompleted(TutorialModuleIds.roadmap),
      isFalse,
    );
    expect(find.text('Следующее действие'), findsNothing);
    expect(
      find.byKey(const ValueKey('tutorial-core-completion')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('optional RoadMap tutorial starts without another module', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = true
      ..tutorialProgress = const TutorialProgress(
        completedModuleIds: {TutorialModuleIds.core},
        activeModuleId: TutorialModuleIds.roadmap,
        activeStepId: TutorialStepIds.roadmapPath,
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
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();

    expect(find.text('Дорожная карта'), findsWidgets);
    expect(find.text('Открыть карту'), findsOneWidget);

    await tester.tap(find.text('Открыть карту'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('Дорожная карта'), findsWidgets);
    expect(find.text('Карта'), findsWidgets);
    expect(
      storage.tutorialProgress!.activeModuleId,
      TutorialModuleIds.roadmap,
    );
    expect(find.byKey(const ValueKey('guided-tour-card')), findsOneWidget);
    expect(find.text('Путь навыка'), findsOneWidget);
    expect(
      storage.tutorialProgress!.isModuleCompleted(TutorialModuleIds.stats),
      isFalse,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Minimum tutorial spotlights only a real minimum control', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = true
      ..tutorialProgress = const TutorialProgress(
        completedModuleIds: {TutorialModuleIds.core},
        activeModuleId: TutorialModuleIds.act,
        activeStepId: TutorialStepIds.actMinimum,
        completedStepIds: {TutorialStepIds.actNextQuest},
      )
      ..skills = [
        Skill(
          id: 'minimum-skill',
          name: 'Сценарий',
          goal: 'Подготовить выпуск',
          color: const Color(0xFFFF453A),
          icon: Icons.movie_creation_outlined,
        ),
      ]
      ..tasks = [
        Task(
          id: 'minimum-task',
          title: 'Дополнить сценарий',
          skillId: 'minimum-skill',
          xpReward: 100,
          type: TaskType.longTerm,
          minimumAction: 'Открыть документ на пять минут',
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Минимальный шаг'), findsWidgets);
    expect(find.byKey(const ValueKey('guided-tour-card')), findsOneWidget);
    expect(storage.tasks.single.isMinimumActionDone, isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Minimum tutorial omits a missing minimum control', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = true
      ..tutorialProgress = const TutorialProgress(
        completedModuleIds: {TutorialModuleIds.core},
        activeModuleId: TutorialModuleIds.act,
        activeStepId: TutorialStepIds.actMinimum,
        completedStepIds: {TutorialStepIds.actNextQuest},
      );
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();

    expect(find.text('Минимальный шаг'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('guided-tour-card')),
        matching: find.text('Задачник'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('guided-tour-card')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('guided-tour-card')), findsNothing);
    expect(
      storage.tutorialProgress!.dismissedModuleIds,
      isNot(contains(TutorialModuleIds.act)),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'AddSkillDialog keeps first stage optional in desktop identity layout',
    (WidgetTester tester) async {
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
        tester.getCenter(find.byKey(const ValueKey('skill-preview-icon'))).dx,
        lessThan(tester.getCenter(find.text('Название навыка')).dx),
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
    },
  );

  testWidgets('Tooltip visibility follows saved setting', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = true
      ..tooltipsEnabled = false;
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

      final storage = InMemoryStorageService()..onboardingSeen = true;
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Your Name').first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('profile-training-center-entry')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('profile-training-center-entry')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('profile-training-center-entry')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Первый путь'), findsOneWidget);
      expect(find.text('Дорожная карта'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('tutorial-topic-roadmap')),
      );
      await tester.tap(find.byKey(const ValueKey('tutorial-topic-roadmap')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1250));
      await tester.pumpAndSettle();

      expect(find.text('Дорожная карта'), findsWidgets);
      expect(find.byKey(const ValueKey('guided-tour-card')), findsOneWidget);
      expect(storage.tutorialProgress!.activeModuleId, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('Profile keeps tutorial replay connected after a theme change', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();
    await tester.pumpWidget(
      RPGApp(storage: storage, captureFrameForTesting: () async => null),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Your Name').first);
    await tester.pumpAndSettle();

    final profile = find.byType(ProfileDialog);
    await tester.ensureVisible(find.text('Тёмная тема'));
    await tester.pump();
    await tester.tap(
      find.descendant(of: profile, matching: find.byType(Switch)).first,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-training-center-entry')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('profile-training-center-entry')),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('tutorial-topic-roadmap')),
    );
    await tester.tap(find.byKey(const ValueKey('tutorial-topic-roadmap')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('guided-tour-card')), findsOneWidget);
    expect(storage.tutorialProgress!.activeModuleId, isNull);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Profile tutorial opens the real surface and completes inline', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = true
      ..tutorialProgress = const TutorialProgress(
        completedModuleIds: {TutorialModuleIds.core},
        activeModuleId: TutorialModuleIds.profile,
        activeStepId: TutorialStepIds.profileReplay,
      );
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Профиль'), findsOneWidget);
    expect(find.byKey(const ValueKey('guided-tour-card')), findsOneWidget);
    await tester.tap(find.text('Открыть профиль'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileDialog), findsOneWidget);
    expect(find.text('Готово'), findsOneWidget);
    expect(find.byKey(const ValueKey('guided-tour-card')), findsOneWidget);
    expect(
      storage.tutorialProgress!.isModuleCompleted(TutorialModuleIds.profile),
      isFalse,
    );
    await tester.tap(find.text('Завершить'));
    await tester.pumpAndSettle();

    expect(
      storage.tutorialProgress!.isModuleCompleted(TutorialModuleIds.profile),
      isTrue,
    );
    expect(find.byKey(const ValueKey('guided-tour-card')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile system Back pauses a tutorial-opened real surface', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = true
      ..tutorialProgress = const TutorialProgress(
        completedModuleIds: {TutorialModuleIds.core},
      );
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Your Name').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-training-center-entry')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('profile-training-center-entry')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('tutorial-topic-stats')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tutorial-topic-stats')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1250));
    await tester.pumpAndSettle();

    expect(find.text('История роста'), findsOneWidget);
    await tester.tap(find.text('Открыть рост'));
    await tester.pumpAndSettle();
    expect(find.byType(MobileStatisticsPage), findsOneWidget);
    expect(find.text('Что показывает Рост'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(MobileStatisticsPage), findsNothing);
    expect(find.byKey(const ValueKey('guided-tour-card')), findsNothing);
    await tester.tap(find.text('Your Name').first);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileDialog), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('full replay traverses real surfaces without domain mutation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final skill = Skill(
      id: 'replay-skill',
      name: 'Плавание',
      goal: 'Проплыть километр',
      color: const Color(0xFF4A9EFF),
      icon: Icons.pool_rounded,
      xp: 240,
      treeNodes: [SkillTreeNode(id: 'replay-stage', title: 'Основа')],
    );
    final task = Task(
      id: 'replay-task',
      title: 'Проплыть 100 метров',
      skillId: skill.id,
      treeNodeId: 'replay-stage',
      xpReward: 80,
      type: TaskType.shortTerm,
    );
    final completedModules = TutorialCatalog.modules
        .map((module) => module.id)
        .toSet();
    final completedSteps = TutorialCatalog.modules
        .expand((module) => TutorialCatalog.stepIdsForModule(module.id))
        .toSet();
    final storage = InMemoryStorageService()
      ..welcomeSeen = true
      ..onboardingSeen = true
      ..tutorialProgress = TutorialProgress(
        completedModuleIds: completedModules,
        completedStepIds: completedSteps,
      )
      ..skills = [skill]
      ..tasks = [task];
    final beforeModules = Set<String>.of(completedModules);
    final beforeSteps = Set<String>.of(completedSteps);
    final beforeNodeIds = skill.treeNodes.map((node) => node.id).toList();
    final beforeHistory = List<HistoryEntry>.of(storage.history);
    final beforeRewards = List<RewardChest>.of(storage.rewardChests);
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Your Name').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-training-center-entry')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('profile-training-center-entry')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tutorial-start-full-tour')));
    await tester.pumpAndSettle();

    Future<void> advance(String title, String action) async {
      final card = find.byKey(const ValueKey('guided-tour-card'));
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text(title)),
        findsOneWidget,
      );
      await tester.tap(find.descendant(of: card, matching: find.text(action)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
    }

    await advance('Задачник', 'Дальше');
    await advance('После паузы', 'К карте');
    await advance('Дорожная карта', 'Открыть карту');
    expect(find.byKey(const ValueKey('mastery-workspace')), findsOneWidget);
    await advance('Путь навыка', 'Дальше');
    await advance('Практика этапа', 'К росту');
    await advance('История роста', 'Открыть рост');
    expect(
      find.byKey(const ValueKey('desktop-statistics-workspace')),
      findsOneWidget,
    );
    await advance('Что показывает Рост', 'К трофеям');
    await advance('Трофеи', 'Открыть трофеи');
    expect(
      find.byKey(const ValueKey('desktop-rewards-workspace')),
      findsOneWidget,
    );
    await advance('Откуда берутся трофеи', 'К профилю');
    await advance('Профиль', 'Открыть профиль');
    expect(find.byType(ProfileDialog), findsOneWidget);
    await advance('Готово', 'Завершить');

    expect(find.byKey(const ValueKey('guided-tour-card')), findsNothing);
    expect(
      storage.skills.where((candidate) => candidate.id != kInboxSkillId),
      hasLength(1),
    );
    expect(storage.tasks, hasLength(1));
    expect(skill.xp, 240);
    expect(task.isDone, isFalse);
    expect(skill.treeNodes.map((node) => node.id), beforeNodeIds);
    expect(storage.history, beforeHistory);
    expect(storage.rewardChests, beforeRewards);
    expect(storage.tutorialProgress!.completedModuleIds, beforeModules);
    expect(storage.tutorialProgress!.completedStepIds, beforeSteps);
    expect(storage.welcomeSeen, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

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

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final appMark = find.byKey(const ValueKey('top-bar-app-mark'));
    expect(appMark, findsOneWidget);
    expect(find.text('DEBUG ADMIN'), findsNothing);

    await tester.tap(appMark);
    await tester.pump(const Duration(milliseconds: 4100));
    await tester.tap(appMark);
    await tester.pump();
    expect(find.text('DEBUG ADMIN'), findsNothing);
    await tester.pump(const Duration(milliseconds: 4100));

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
          body: AchievementsCollection(
            achievements: [achievement],
            isDark: true,
          ),
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
          body: AchievementsCollection(
            achievements: [achievement],
            isDark: false,
          ),
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

    expect(
      find.byKey(const ValueKey('desktop-add-skill-dialog')),
      findsOneWidget,
    );
    expect(find.text('Новый навык'), findsWidgets);
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

  testWidgets('mobile skill overview supports reorder and Inbox accordion', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
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
        Task(
          id: 'mobile-inbox-task',
          title: 'Быстрая проверка',
          skillId: kInboxSkillId,
          xpReward: 0,
          type: TaskType.shortTerm,
        ),
      ];
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compact-skill-reorder-mobile-long')),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('mobile-skill-panel-compact')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.byKey(const ValueKey('compact-skill-reorder-mobile-long')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('compact-skill-reorder-$kInboxSkillId')),
      findsNothing,
    );

    final listFinder = find.byKey(const ValueKey('mobile-skill-overview-list'));
    expect(find.byKey(const ValueKey('mobile-inbox-shortcut')), findsNothing);
    final inboxToggle = find.byKey(
      const ValueKey('mobile-inbox-accordion-toggle'),
    );
    for (
      var attempt = 0;
      attempt < 6 && inboxToggle.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(
        find.byKey(const ValueKey('mobile-skill-panel-compact')),
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Задачник'), findsOneWidget);
    expect(
      tester.getRect(inboxToggle).bottom,
      lessThanOrEqualTo(
        tester.getRect(find.byKey(const ValueKey('mobile-workspace-nav'))).top,
      ),
    );
    expect(
      find.byKey(const ValueKey('mobile-inbox-accordion-content')),
      findsNothing,
    );
    await tester.longPress(
      find.byKey(const ValueKey('mobile-skill-chip-mobile-long')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Редактировать навык'), findsOneWidget);
    expect(find.text('Удалить навык'), findsOneWidget);
    await tester.tap(find.text('Редактировать навык'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-add-skill-page')), findsOneWidget);
    expect(find.text('Сохранить изменения'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mobile-form-cancel')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('mobile-skill-chip-mobile-long')),
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Править'), findsOneWidget);
    expect(find.text('Удалить'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('mobile-skill-chip-mobile-long')),
      const Offset(220, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: inboxToggle, matching: find.byType(InkWell)),
      findsNothing,
    );
    final inboxGesture = await tester.startGesture(
      tester.getCenter(inboxToggle),
    );
    await tester.pump(const Duration(milliseconds: 110));
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const ValueKey('mobile-inbox-accordion-press-scale')),
          )
          .scale,
      0.985,
    );
    await inboxGesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mobile-inbox-focus')), findsOneWidget);
    expect(find.text('Задачник'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-inbox-icon-badge')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('inbox-active-count')), findsNothing);
    expect(find.textContaining('+10 XP'), findsOneWidget);
    final inboxSurface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('mobile-inbox-accordion-surface')),
    );
    final inboxGradient =
        (inboxSurface.decoration as BoxDecoration).gradient! as LinearGradient;
    expect(inboxGradient.begin, Alignment.centerLeft);
    expect(inboxGradient.end, Alignment.centerRight);
    expect(inboxGradient.colors, hasLength(3));
    expect(inboxGradient.colors.first, inboxGradient.colors.last);
    expect(inboxGradient.colors[1], isNot(inboxGradient.colors.first));
    final inboxContent = tester.widget<Container>(
      find.byKey(const ValueKey('mobile-inbox-focus')),
    );
    final contentGradient =
        (inboxContent.decoration! as BoxDecoration).gradient! as LinearGradient;
    expect(contentGradient.begin, Alignment.centerLeft);
    expect(contentGradient.end, Alignment.centerRight);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mobile-inbox-accordion-content')),
      findsNothing,
    );
    expect(listFinder, findsOneWidget);

    // Список стал сливерным и ленивым: строит только видимые карточки.
    final list = tester.widget<SliverReorderableList>(listFinder);
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
      find.descendant(
        of: find.byKey(const ValueKey('mobile-skill-chip-mobile-long')),
        matching: find.text('Очень длинное название мобильного навыка'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile skill experience separates Overview and one selected focus', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const skillId = 'mobile-experience';
    const skillName = 'Очень длинное название навыка для мобильного экрана';
    const longDescription =
        'Подробное описание квеста должно полностью переноситься на несколько '
        'строк и увеличивать высоту карточки без обрезки последней части текста.';
    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        Skill(
          id: skillId,
          name: skillName,
          goal: 'Дойти до уверенного результата',
          color: const Color(0xFFFF1635),
          icon: Icons.auto_stories_rounded,
          level: 4,
          xp: 1000,
          treeNodes: [
            SkillTreeNode(id: 'stage-done', title: 'Основа', isMastered: true),
            SkillTreeNode(id: 'stage-next', title: 'Практика'),
          ],
        ),
      ]
      ..tasks = [
        Task(
          id: 'mobile-active-1',
          title:
              'Очень длинный первый квест, который должен аккуратно переноситься на узком экране',
          description: longDescription,
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
          id: 'mobile-active-3',
          title: 'Третий квест',
          skillId: skillId,
          xpReward: 30,
          type: TaskType.shortTerm,
        ),
        Task(
          id: 'mobile-active-4',
          title: 'Четвёртый квест',
          skillId: skillId,
          xpReward: 40,
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

    final compactPanel = find.byKey(
      const ValueKey('mobile-skill-panel-compact'),
    );
    final skillChip = find.byKey(
      const ValueKey('mobile-skill-chip-mobile-experience'),
    );
    expect(compactPanel, findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-act-overview')), findsOneWidget);
    expect(find.byKey(const ValueKey('next-action-lens')), findsOneWidget);
    expect(find.text('Следующее действие'), findsOneWidget);
    await tester.scrollUntilVisible(
      skillChip,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('mobile-skill-panel-compact')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(skillChip, findsOneWidget);
    expect(
      find.descendant(of: skillChip, matching: find.textContaining('Ур. 4')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('mobile-selected-skill-focus-mobile-experience'),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('mobile-momentum-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-momentum-xp')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-momentum-completed')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mobile-momentum-streak')), findsNothing);
    expect(find.text('0 дней'), findsNothing);
    expect(
      find.byKey(const ValueKey('mobile-next-action-summary')),
      findsNothing,
    );
    final goalSemantics = tester
        .widgetList<Semantics>(
          find.descendant(of: skillChip, matching: find.byType(Semantics)),
        )
        .any(
          (semantics) =>
              semantics.properties.value == 'Прогресс уровня: 50%' ||
              semantics.properties.label == 'Прогресс уровня: 50%',
        );
    expect(goalSemantics, isTrue);
    expect(tester.takeException(), isNull);

    await tester.tap(skillChip);
    await tester.pump();
    expect(find.byKey(const ValueKey('mobile-act-overview')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-act-focus-mobile-experience')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('mobile-skill-card-opening-mobile-experience')),
      findsOneWidget,
    );
    // Уходящая анимация обзора длится столько же, сколько сама анимация
    // (220 мс), а не магические 180. После неё — ещё кадр на построение
    // фокуса: смена навыка перестраивает экран целиком, и раньше этот
    // тяжёлый кадр попадал в середину перехода.
    await tester.pump(const Duration(milliseconds: 221));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('mobile-act-focus-mobile-experience')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-skill-panel-compact')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('mobile-focus-switcher')), findsNothing);
    expect(
      find.byKey(const ValueKey('mobile-overview-action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-act-focus-mobile-experience')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mobile-momentum-row')), findsNothing);
    // Задачник остаётся пристыкованным и в фокусе навыка: это surface
    // быстрого захвата, и бытовое дело чаще всего вспоминается как раз
    // посреди работы над навыком.
    expect(find.text('Задачник'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-inbox-dock-divider')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('next-action-lens')), findsNothing);
    expect(
      find.byKey(
        const ValueKey('mobile-selected-skill-focus-mobile-experience'),
      ),
      findsOneWidget,
    );
    expect(find.text('Дойти до уверенного результата'), findsOneWidget);
    expect(find.text('Прогресс цели'), findsNothing);
    expect(find.text('50%'), findsNothing);
    expect(
      find.byKey(const ValueKey('mobile-focus-quest-row-mobile-active-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quest-xp-mobile-active-1')),
      findsOneWidget,
    );
    final descriptionText = tester.widget<Text>(find.text(longDescription));
    expect(descriptionText.maxLines, isNull);
    expect(descriptionText.overflow, isNull);
    expect(find.byType(XpRewardPill), findsNWidgets(5));
    expect(
      find.byKey(const ValueKey('task-done-mobile-completed')),
      findsOneWidget,
    );
    expect(find.textContaining('Выполнено ('), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('mobile-focus-quest-row-mobile-completed')),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('mobile-focus-quest-row-mobile-completed')),
      const Offset(220, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('В Выполнено'), findsOneWidget);
    await tester.tap(find.text('В Выполнено'));
    await tester.pumpAndSettle();
    expect(find.text('Выполнено (1)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-focus-quest-row-mobile-completed')),
      findsNothing,
    );
    await tester.ensureVisible(find.text('Выполнено (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выполнено (1)'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('task-archived-mobile-completed')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('mobile-focus-quest-row-mobile-active-1'),
            ),
          )
          .height,
      greaterThan(
        tester
            .getSize(
              find.byKey(
                const ValueKey('mobile-focus-quest-row-mobile-active-2'),
              ),
            )
            .height,
      ),
    );
    expect(find.byType(MobileSkillFocusSurface), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-delete-skill-mobile-experience')),
      findsOneWidget,
    );
    expect(find.byType(DashedBorderContainer), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-dashed-add-quest')),
      findsOneWidget,
    );
    final focusSurface = tester.widget<MobileSkillFocusSurface>(
      find.byType(MobileSkillFocusSurface),
    );
    expect(focusSurface.skillColor, const Color(0xFFFF1635));
    final questRow = tester.widget<Container>(
      find.byKey(const ValueKey('mobile-focus-quest-row-mobile-active-1')),
    );
    final questDecoration = questRow.decoration! as BoxDecoration;
    expect(questDecoration.color, MobileJournalTokens.questRow(true));
    final completedRow = tester.widget<Container>(
      find.byKey(const ValueKey('mobile-focus-quest-row-mobile-completed')),
    );
    final completedDecoration = completedRow.decoration! as BoxDecoration;
    expect(
      completedDecoration.color,
      isNot(MobileJournalTokens.questRow(true)),
    );
    expect(MobileJournalTokens.rewardGold, const Color(0xFFFFB020));
    expect(find.text('Новый квест'), findsOneWidget);
    expect(find.textContaining('Фокус:'), findsNothing);

    await tester.ensureVisible(
      find.byKey(
        const ValueKey('mobile-focus-quest-long-press-mobile-active-1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(
      find.byKey(
        const ValueKey('mobile-focus-quest-long-press-mobile-active-1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-add-task-page')), findsOneWidget);
    expect(find.text('Сохранить изменения'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mobile-form-cancel')));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(700, 800);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('mobile-selected-skill-focus-mobile-experience'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const ValueKey('mobile-overview-action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mobile-overview-action')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('mobile-act-focus-mobile-experience')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mobile-act-overview')), findsNothing);
    await tester.pump(const Duration(milliseconds: 221));
    expect(find.byKey(const ValueKey('mobile-act-overview')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mobile-skill-panel-compact')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('desktop task row uses the shared amber XP reward pill', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final task = Task(
      id: 'desktop-reward',
      title: 'Проверить награду на desktop',
      skillId: 'desktop-skill',
      xpReward: 35,
      type: TaskType.shortTerm,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 720,
              child: TaskTile(
                task: task,
                isDark: true,
                skillColor: const Color(0xFF7562FF),
                previewEarnedXP: 35,
                previewBuffBonus: 0,
                onToggle: (_) {},
                onMinimumAction: (_) {},
                onUncomplete: () {},
                onArchive: () {},
                onRestoreArchive: () {},
                onDelete: () {},
                onEdit: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('quest-xp-desktop-reward')),
      findsOneWidget,
    );
    expect(find.byType(XpRewardPill), findsOneWidget);
    expect(MobileJournalTokens.rewardGold, const Color(0xFFFFB020));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile skill ring uses level XP without RoadMap stages', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        Skill(
          id: 'mobile-empty-roadmap',
          name: 'Навык без этапов',
          goal: 'Добавить этапы позже',
          color: const Color(0xFFFF9500),
          icon: Icons.lightbulb_outline_rounded,
          xp: 250,
        ),
      ];
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('25%'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('mobile-skill-chip-mobile-empty-roadmap')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Прогресс цели'), findsNothing);
    expect(find.text('Добавьте этапы'), findsNothing);
    expect(
      find.byKey(const ValueKey('skill-goal-bar-mobile-empty-roadmap')),
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

    await tester.tap(find.byKey(const ValueKey('desktop-skill-skill-1')));
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
      ..onboardingSeen = true
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

    await tester.tap(find.byKey(const ValueKey('map-skill-orb-skill-1')));
    await tester.pumpAndSettle();

    expect(find.text('Шаблон RoadMap'), findsNothing);
    expect(find.text('Шаблоны'), findsOneWidget);
    await tester.tap(find.text('Шаблоны'));
    await tester.pumpAndSettle();
    expect(find.text('Шаблоны путей'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('roadmap-template-bottom-sheet')),
      findsNothing,
    );
    await tester.tap(find.text('Скрыть'));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byTooltip('Редактировать').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-add-task-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.text('Сохранить изменения'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('desktop-add-task-dialog')), findsNothing);
    expect(find.text('Открыть редактор'), findsOneWidget);
    expect(find.text('Написать модуль'), findsOneWidget);
    expect(find.text('Практика для освоения'), findsOneWidget);
    expect(find.text('практика этапа: Основа'), findsNothing);

    expect(find.text('Переименовать'), findsNothing);
    await tester.tap(find.byTooltip('Переименовать этап'));
    await tester.pumpAndSettle();
    expect(find.text('Редактировать этап'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('roadmap-stage-description-field')),
      findsOneWidget,
    );
    expect(find.text('Продлить путь'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('roadmap-stage-title-field')),
      'База',
    );
    await tester.enterText(
      find.byKey(const ValueKey('roadmap-stage-description-field')),
      'Фундамент навыка',
    );
    await tester.tap(
      find.byKey(const ValueKey('roadmap-stage-target-increment')),
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('База'), findsWidgets);
    expect(find.text('Фундамент навыка'), findsOneWidget);
    final savedStage = storage.skills
        .firstWhere((skill) => skill.id == 'skill-1')
        .treeNodes
        .firstWhere((node) => node.id == 'stage-1');
    expect(savedStage.description, 'Фундамент навыка');
    expect(savedStage.questTarget, 4);

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

  testWidgets('the mobile hub has one growth log, and it reaches the XP journal', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(
      storage: InMemoryStorageService()..onboardingSeen = true,
      seedDefaults: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterTimelineDialog(
            state: state,
            fullScreen: true,
            onOpenXpJournal: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Страница обещает журнал XP текстом, поэтому переход в него обязан быть:
    // своей карточки в хабе у журнала больше нет.
    expect(
      find.byKey(const ValueKey('timeline-open-xp-journal')),
      findsOneWidget,
    );
    expect(find.text('Журнал XP'), findsOneWidget);

    // AppState заводит таймер суточного сброса прямо в конструкторе, поэтому
    // состояние закрывается до проверки инвариантов, а не в tearDown.
    state.dispose();
    await tester.pump();
  });

  testWidgets('Trophies holds the whole achievement collection', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(
      storage: InMemoryStorageService()..onboardingSeen = true,
      seedDefaults: false,
    );
    state.normalizeAfterBulkStateChange();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RewardsDialog(state: state))),
    );
    await tester.pumpAndSettle();

    // Раздел держит и последствия действий, и коллекцию: своей карточки у
    // достижений больше нет ни в мобильном хабе, ни в десктопной статистике.
    expect(find.text('Достижения'), findsOneWidget);
    expect(find.byType(AchievementsCollection), findsOneWidget);
    // Мобильный маршрут — не единственный: `RewardsDialog` рисует телефон, а
    // десктопные «Трофеи» это отдельный виджет. Проверка ниже держит оба,
    // потому что первый заход добавил коллекцию только в один из них и на
    // десктопе она стала недостижимой.
    expect(
      state.achievements,
      isNotEmpty,
      reason: 'каталог достижений должен быть заполнен по умолчанию',
    );

    state.dispose();
    await tester.pump();
  });

  testWidgets('desktop Trophies also holds the achievement collection', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.emoji_events_outlined).first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('desktop-rewards-workspace')),
      findsOneWidget,
    );
    // Десктопные «Трофеи» — отдельный виджет от мобильного маршрута. Когда
    // экран достижений убрали из статистики, коллекция должна была появиться
    // здесь; без этой проверки она осталась достижимой только с телефона.
    expect(
      find.byKey(const ValueKey('desktop-trophies-collection')),
      findsOneWidget,
    );
  });

  testWidgets('the profile keeps data transfer in both layouts', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    final storage = InMemoryStorageService(snapshotsSupported: true)
      ..onboardingSeen = true;
    await storage.init();
    final state = AppState(storage: storage, seedDefaults: false);
    await state.loadSavedData();

    // Двухколоночная раскладка кладёт перенос в правую колонку, одна колонка
    // — в самый низ. Раздел терялся в обеих, поэтому проверяются обе.
    for (final width in [1400.0, 700.0]) {
      tester.view.physicalSize = Size(width, 1000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppStateProvider(state: state, child: const ProfileDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // В одну колонку перенос стоит последним и не построен, пока до него не
      // доскроллили: ListView ленивый. Ровно поэтому владелец и не нашёл
      // кнопки глазами.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('profile-export-data')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('desktop-profile-body-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('profile-export-data')),
        findsOneWidget,
        reason: 'ширина $width',
      );
      expect(
        find.byKey(const ValueKey('profile-import-data')),
        findsOneWidget,
        reason: 'ширина $width',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    state.dispose();
  });

  testWidgets('desktop Statistics says it once instead of printing zeros', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const ValueKey('desktop-nav-statistics')));
    await tester.pumpAndSettle();

    // Три карточки печатали «0 XP · 0 квестов» подряд. Одно предложение
    // говорит то же самое и объясняет, что с этим делать.
    expect(
      find.byKey(const ValueKey('desktop-statistics-growth-empty')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desktop-statistics-growth-history')),
      findsNothing,
    );
  });

  testWidgets('desktop Settings offers data transfer next to storage status', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService(snapshotsSupported: true)
      ..onboardingSeen = true;
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const ValueKey('desktop-settings')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('desktop-settings-workspace')),
      findsOneWidget,
    );
    // Перенос данных продублирован в настройки сознательно, рядом с состоянием
    // хранилища: «переезжаю на другое устройство» и «что-то с данными» — это
    // два разных повода, и второй ведёт сюда, а не в профиль.
    expect(
      find.byKey(const ValueKey('desktop-settings-data-transfer')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('profile-export-data')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-import-data')), findsOneWidget);
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
      ..onboardingSeen = true
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
    final horizontalSkillLabel = tester.widget<Text>(
      find.byKey(const ValueKey('map-skill-label-text-layout-skill')),
    );
    final horizontalStageLabel = tester.widget<Text>(nodeLabel(middle.id));
    expect(horizontalSkillLabel.style?.fontSize, greaterThanOrEqualTo(18));
    expect(horizontalStageLabel.style?.fontSize, greaterThanOrEqualTo(15));
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
    expect(verticalSkillRect.top, lessThan(verticalCanvasRect.top + 64));
    expect(
      tester.getRect(node(root.id)).bottom,
      greaterThan(verticalCanvasRect.bottom - 64),
    );
    expect(
      verticalViewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(0.6),
    );

    final verticalRootSurface = tester.getRect(nodeSurface(root.id));
    final verticalMiddleSurface = tester.getRect(nodeSurface(middle.id));
    final verticalTerminalSurface = tester.getRect(nodeSurface(terminal.id));
    final rootLabelDelta =
        tester.getCenter(nodeLabel(root.id)).dx - verticalRootSurface.center.dx;
    final middleLabelDelta =
        tester.getCenter(nodeLabel(middle.id)).dx -
        verticalMiddleSurface.center.dx;
    final terminalLabelDelta =
        tester.getCenter(nodeLabel(terminal.id)).dx -
        verticalTerminalSurface.center.dx;
    // Stages on the axis label to one side so the names read as a column.
    expect(rootLabelDelta, greaterThan(60));
    expect(middleLabelDelta, greaterThan(60));
    expect(terminalLabelDelta, greaterThan(60));
    final verticalRootLabel = tester.widget<Text>(nodeLabel(root.id));
    expect(verticalRootLabel.textAlign, isNot(TextAlign.center));
    expect(verticalRootLabel.style?.fontSize, greaterThanOrEqualTo(16));
    for (final stage in [root, middle, terminal]) {
      final labelFinder = find.byKey(
        ValueKey('map-node-label-layout-skill-${stage.id}'),
      );
      final labelRect = tester.getRect(labelFinder);
      final orbRect = tester.getRect(nodeSurface(stage.id));
      expect(labelRect.size.isEmpty, isFalse);
      expect(verticalCanvasRect.contains(labelRect.topLeft), isTrue);
      expect(verticalCanvasRect.contains(labelRect.bottomRight), isTrue);
      expect(labelRect.overlaps(orbRect), isFalse);
      expect(
        find.ancestor(of: labelFinder, matching: node(stage.id)),
        findsNothing,
      );
    }
    expect(verticalGoalRect.width, greaterThanOrEqualTo(240));
    expect(verticalGoalRect.center.dy, closeTo(verticalSkillRect.center.dy, 1));
    expect(verticalCanvasRect.contains(verticalGoalRect.topLeft), isTrue);
    expect(verticalCanvasRect.contains(verticalGoalRect.bottomRight), isTrue);

    void expectInsertionBetween({
      required Finder insertionFinder,
      required Rect upperBoundary,
      required Rect lowerSurface,
    }) {
      final center = tester.getCenter(insertionFinder);
      final visibleCircleBounds = _roadmapVisibleInsertRect(
        tester,
        insertionFinder,
      );
      expect(
        center.dy,
        closeTo((upperBoundary.bottom + lowerSurface.top) / 2, 3),
      );
      expect(visibleCircleBounds.overlaps(upperBoundary), isFalse);
      expect(visibleCircleBounds.overlaps(lowerSurface), isFalse);
    }

    expectInsertionBetween(
      insertionFinder: insertion(root.id, middle.id),
      upperBoundary: verticalMiddleSurface,
      lowerSurface: verticalRootSurface,
    );
    expectInsertionBetween(
      insertionFinder: insertion(middle.id, terminal.id),
      upperBoundary: verticalTerminalSurface,
      lowerSurface: verticalMiddleSurface,
    );
    expectInsertionBetween(
      insertionFinder: insertion(terminal.id, 'skill'),
      upperBoundary: skillLabelRect,
      lowerSurface: verticalTerminalSurface,
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

  testWidgets(
    'desktop RoadMap keeps connector endpoints attached during orientation transitions',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final root = SkillTreeNode(id: 'sync-root', title: 'Старт');
      final middle = SkillTreeNode(
        id: 'sync-middle',
        title: 'Практика',
        prerequisiteIds: [root.id],
      );
      final terminal = SkillTreeNode(
        id: 'sync-terminal',
        title: 'Результат',
        prerequisiteIds: [middle.id],
      );
      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..skills = [
          Skill(
            id: 'sync-skill',
            name: 'Синхронный путь',
            goal: 'Линии следуют за этапами',
            color: const Color(0xFF4A9EFF),
            icon: Icons.route_rounded,
            treeNodes: [root, middle, terminal],
          ),
        ];
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('desktop-nav-map')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('map-skill-orb-sync-skill')));
      await tester.pumpAndSettle();

      final nodeIds = [root.id, middle.id, terminal.id];
      void expectAttached() => _expectRoadmapConnectorsAttached(
        tester,
        skillId: 'sync-skill',
        nodeIds: nodeIds,
      );

      expectAttached();
      await tester.tap(find.byKey(const ValueKey('roadmap-layout-vertical')));
      await tester.pump();
      expectAttached();
      for (var sample = 0; sample < 4; sample++) {
        await tester.pump(const Duration(milliseconds: 60));
        expectAttached();
      }

      await tester.tap(find.byKey(const ValueKey('roadmap-layout-horizontal')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expectAttached();
      await tester.tap(find.byKey(const ValueKey('roadmap-layout-vertical')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expectAttached();

      tester.view.physicalSize = const Size(1180, 780);
      await tester.pump(const Duration(milliseconds: 60));
      expectAttached();
      await tester.pumpAndSettle();
      expectAttached();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'desktop RoadMap establishes the selected path camera before its first visible frame',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..skills = [
          Skill(
            id: 'initial-camera-skill',
            name: 'Стабильный путь',
            goal: 'Не прыгать после открытия',
            color: const Color(0xFF4A9EFF),
            icon: Icons.route_rounded,
            treeNodes: [
              SkillTreeNode(id: 'initial-root', title: 'Основа'),
              SkillTreeNode(
                id: 'initial-next',
                title: 'Практика',
                prerequisiteIds: const ['initial-root'],
              ),
            ],
          ),
        ];
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(
        find.byKey(const ValueKey('desktop-skill-initial-camera-skill')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('desktop-nav-map')));
      await tester.pump();

      final viewer = tester.widget<InteractiveViewer>(
        find.descendant(
          of: find.byKey(const ValueKey('roadmap-canvas-horizontal')),
          matching: find.byType(InteractiveViewer),
        ),
      );
      final firstPaintMatrix = List<double>.from(
        viewer.transformationController!.value.storage,
      );
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        isNot(1),
      );

      await tester.pump();
      final nextFrameMatrix = tester
          .widget<InteractiveViewer>(
            find.descendant(
              of: find.byKey(const ValueKey('roadmap-canvas-horizontal')),
              matching: find.byType(InteractiveViewer),
            ),
          )
          .transformationController!
          .value
          .storage;
      for (var index = 0; index < firstPaintMatrix.length; index++) {
        expect(nextFrameMatrix[index], closeTo(firstPaintMatrix[index], 0.001));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('desktop RoadMap orientation uses the selected skill accent', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final skills = [
      Skill(
        id: 'accent-red',
        name: 'Красный',
        goal: '',
        color: const Color(0xFFFF3B30),
        icon: Icons.local_fire_department_rounded,
      ),
      Skill(
        id: 'accent-blue',
        name: 'Синий',
        goal: '',
        color: const Color(0xFF4A9EFF),
        icon: Icons.water_drop_rounded,
      ),
      Skill(
        id: 'accent-green',
        name: 'Зелёный',
        goal: '',
        color: const Color(0xFF34C759),
        icon: Icons.eco_rounded,
      ),
    ];
    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = skills;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    Color? orientationColor() => tester
        .widget<Icon>(
          find.descendant(
            of: find.byKey(const ValueKey('roadmap-layout-horizontal')),
            matching: find.byIcon(Icons.view_stream_outlined),
          ),
        )
        .color;

    Future<void> openForSkill(Skill skill) async {
      await tester.tap(find.byKey(const ValueKey('desktop-nav-act')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('desktop-skill-${skill.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('desktop-nav-map')));
      await tester.pumpAndSettle();
      expect(orientationColor(), skill.color);
    }

    for (final skill in skills) {
      await openForSkill(skill);
    }

    await tester.tap(find.byKey(const ValueKey('map-skill-orb-accent-green')));
    await tester.pumpAndSettle();
    expect(orientationColor(), const Color(0xFF765BFF));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop RoadMap reduced motion swaps orientation without positional animation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final root = SkillTreeNode(id: 'reduced-root', title: 'Старт');
      final child = SkillTreeNode(
        id: 'reduced-child',
        title: 'Практика',
        prerequisiteIds: [root.id],
      );
      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..skills = [
          Skill(
            id: 'reduced-roadmap',
            name: 'Без движения',
            goal: '',
            color: const Color(0xFF34C759),
            icon: Icons.motion_photos_off_rounded,
            treeNodes: [root, child],
          ),
        ];
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final appState = tester
          .widget<AppStateProvider>(find.byType(AppStateProvider).first)
          .state;
      appState.toggleReducedMotion();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('desktop-nav-map')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('map-skill-orb-reduced-roadmap')),
      );
      await tester.pumpAndSettle();

      final horizontalRoot = tester.getCenter(
        find.byKey(
          const ValueKey('map-node-surface-reduced-roadmap-reduced-root'),
        ),
      );
      _expectRoadmapConnectorsAttached(
        tester,
        skillId: 'reduced-roadmap',
        nodeIds: [root.id, child.id],
      );

      await tester.tap(find.byKey(const ValueKey('roadmap-layout-vertical')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('roadmap-canvas-vertical')),
        findsOneWidget,
      );
      final verticalRoot = tester.getCenter(
        find.byKey(
          const ValueKey('map-node-surface-reduced-roadmap-reduced-root'),
        ),
      );
      expect(verticalRoot, isNot(horizontalRoot));
      _expectRoadmapConnectorsAttached(
        tester,
        skillId: 'reduced-roadmap',
        nodeIds: [root.id, child.id],
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('RoadMap camera keeps one and two stage paths in the viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Skill skill(String id, int count) {
      final stages = <SkillTreeNode>[];
      for (var index = 0; index < count; index++) {
        stages.add(
          SkillTreeNode(
            id: '$id-stage-$index',
            title: 'Этап ${index + 1}',
            prerequisiteIds: index == 0 ? [] : ['$id-stage-${index - 1}'],
          ),
        );
      }
      return Skill(
        id: id,
        name: '$count этапа',
        goal: 'Проверить короткий путь',
        color: const Color(0xFF4A9EFF),
        icon: Icons.route_rounded,
        treeNodes: stages,
      );
    }

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [skill('short-one', 1), skill('short-two', 2)];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('desktop-nav-map')));
    await tester.pumpAndSettle();

    Rect contentBounds(String skillId, int count) {
      var bounds = tester.getRect(
        find.byKey(ValueKey('map-skill-surface-$skillId')),
      );
      for (var index = 0; index < count; index++) {
        bounds = bounds.expandToInclude(
          tester.getRect(
            find.byKey(
              ValueKey('map-node-surface-$skillId-$skillId-stage-$index'),
            ),
          ),
        );
      }
      return bounds;
    }

    void expectVisibleAndCentered(String skillId, int count, String axis) {
      final canvas = tester.getRect(
        find.byKey(ValueKey('roadmap-canvas-$axis')),
      );
      final content = contentBounds(skillId, count);
      expect(canvas.overlaps(content), isTrue);
      expect(
        (content.center.dx - canvas.center.dx).abs(),
        lessThan(canvas.width * 0.28),
      );
      expect(
        (content.center.dy - canvas.center.dy).abs(),
        lessThan(canvas.height * 0.28),
      );
    }

    for (final entry in [('short-one', 1), ('short-two', 2)]) {
      await tester.tap(find.byKey(ValueKey('desktop-skill-${entry.$1}')));
      await tester.pumpAndSettle();
      expectVisibleAndCentered(entry.$1, entry.$2, 'horizontal');
      await tester.tap(find.byKey(const ValueKey('roadmap-layout-vertical')));
      await tester.pumpAndSettle();
      expectVisibleAndCentered(entry.$1, entry.$2, 'vertical');
      await tester.tap(find.byKey(const ValueKey('roadmap-layout-horizontal')));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('RoadMap skill orb separates goal and level progress', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
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
      ..onboardingSeen = true
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

  testWidgets('desktop shows the reward when a chest is opened', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    storage.rewardChests = [
      RewardChest(
        id: 'desktop-chest',
        title: 'Сундук дисциплины',
        description: 'За сильный день',
        rarity: RewardRarity.common,
        sourceKey: 'strong-day',
        unlockedAt: DateTime(2026, 9, 5),
      ),
    ];
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.emoji_events_outlined).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Открыть').first);
    // Карточка награды анимируется постоянно, поэтому фиксированные кадры.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Раньше десктоп звал openRewardChest и выбрасывал сообщение: сундук
    // исчезал, а награду выдавали молча.
    expect(find.text('Сундук открыт'), findsOneWidget);
    // И пустое состояние не спорит с только что выданной наградой.
    expect(find.text('Пока нет сундуков'), findsNothing);
  });

  testWidgets('opening the last chest does not deny the reward just given', (
    WidgetTester tester,
  ) async {
    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();
    final state = AppState(storage: storage, seedDefaults: false);
    state.rewardChests.add(
      RewardChest(
        id: 'last-chest',
        title: 'Сундук дисциплины',
        description: 'За сильный день',
        rarity: RewardRarity.common,
        sourceKey: 'strong-day',
        unlockedAt: DateTime(2026, 9, 5),
      ),
    );
    state.refresh();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: RewardsDialog(state: state)))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('empty-chests')), findsNothing);

    await tester.tap(find.text('Открыть').first);
    // Не pumpAndSettle: карточка награды держит собственную анимацию, и
    // ожидание покоя здесь не заканчивается.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Последний сундук уходит из списка ровно в тот момент, когда его
    // открыли, и «Пока нет сундуков» под сообщением о награде читалось как
    // отрицание того, что только что произошло.
    expect(find.text('Сундук открыт'), findsOneWidget);
    expect(find.byKey(const ValueKey('empty-chests')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    state.dispose();
  });

  testWidgets('Rewards places one Effects section above chest list', (
    WidgetTester tester,
  ) async {
    final storage = InMemoryStorageService()..onboardingSeen = true;
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
    expect(find.byIcon(Icons.expand_less), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsNothing);

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
      ..onboardingSeen = true
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
      final upperSurface = tester.getRect(
        find.byKey(
          ValueKey('map-node-surface-long-roadmap-long-stage-${index + 1}'),
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
        closeTo((upperSurface.bottom + lowerSurface.top) / 2, 3),
      );
      expect(visibleCircleBounds.overlaps(upperSurface), isFalse);
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
      closeTo((skillLabel.bottom + terminalSurface.top) / 2, 3),
    );
    expect(terminalVisibleCircle.overlaps(skillLabel), isFalse);
    expect(terminalVisibleCircle.overlaps(terminalSurface), isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'vertical RoadMap keeps branched labels and goal visible at increased text scales',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final root = SkillTreeNode(
        id: 'branch-root',
        title: 'Сформировать подробную основу сценария',
      );
      final left = SkillTreeNode(
        id: 'branch-left',
        title: 'Подготовить визуальные материалы',
        prerequisiteIds: [root.id],
      );
      final right = SkillTreeNode(
        id: 'branch-right',
        title: 'Записать чистовой звук выпуска',
        prerequisiteIds: [root.id],
      );
      final leftEnd = SkillTreeNode(
        id: 'branch-left-end',
        title: 'Собрать черновой монтаж ролика',
        prerequisiteIds: [left.id],
      );
      final rightEnd = SkillTreeNode(
        id: 'branch-right-end',
        title: 'Проверить музыку и звуковые эффекты',
        prerequisiteIds: [right.id],
      );
      final finish = SkillTreeNode(
        id: 'branch-finish',
        title: 'Опубликовать готовый выпуск',
        prerequisiteIds: [leftEnd.id, rightEnd.id],
      );
      final stages = [root, left, right, leftEnd, rightEnd, finish];
      final storage = InMemoryStorageService()
        ..onboardingSeen = true
        ..skills = [
          Skill(
            id: 'branch-desktop',
            name: 'Видео производство',
            goal:
                'Выпустить самостоятельное видео со сценарием, звуком и монтажом',
            color: const Color(0xFFFF453A),
            icon: Icons.ondemand_video_rounded,
            treeNodes: stages,
          ),
        ];
      await storage.init();
      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('desktop-nav-map')));
      await tester.pumpAndSettle();
      tester.platformDispatcher.textScaleFactorTestValue = 1.25;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byKey(const ValueKey('map-skill-orb-branch-desktop')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('roadmap-layout-vertical')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final configuration in [
        (textScale: 1.25, viewport: const Size(1440, 900)),
        (textScale: 1.5, viewport: const Size(1200, 720)),
        (textScale: 2.0, viewport: const Size(1440, 900)),
      ]) {
        tester.view.physicalSize = configuration.viewport;
        tester.platformDispatcher.textScaleFactorTestValue =
            configuration.textScale;
        await tester.pumpAndSettle();
        final canvas = tester.getRect(
          find.byKey(const ValueKey('roadmap-canvas-vertical')),
        );
        var labelsOnLeft = 0;
        var labelsOnRight = 0;
        for (final stage in stages) {
          final label = tester.getRect(
            find.byKey(ValueKey('map-node-label-branch-desktop-${stage.id}')),
          );
          final orb = tester.getRect(
            find.byKey(ValueKey('map-node-surface-branch-desktop-${stage.id}')),
          );
          expect(label.size.isEmpty, isFalse);
          expect(canvas.contains(label.topLeft), isTrue);
          expect(canvas.contains(label.bottomRight), isTrue);
          expect(label.overlaps(orb), isFalse);
          if (label.center.dx < orb.center.dx) {
            labelsOnLeft++;
          } else {
            labelsOnRight++;
          }
        }
        expect(labelsOnLeft, greaterThan(0));
        expect(labelsOnRight, greaterThan(0));
        final goal = tester.getRect(
          find.byKey(const ValueKey('roadmap-goal-anchor-branch-desktop')),
        );
        final goalSize = tester.getSize(
          find.byKey(const ValueKey('roadmap-goal-anchor-branch-desktop')),
        );
        final skillOrb = tester.getRect(
          find.byKey(const ValueKey('map-skill-surface-branch-desktop')),
        );
        expect(goalSize.width, greaterThanOrEqualTo(240));
        expect(goal.center.dy, closeTo(skillOrb.center.dy, 1));
        expect(goal.left, greaterThan(skillOrb.right + 4));
        expect(canvas.contains(goal.topLeft), isTrue);
        expect(canvas.contains(goal.bottomRight), isTrue);
        expect(
          tester.takeException(),
          isNull,
          reason:
              'RoadMap must remain overflow-free at ${configuration.textScale}x text in ${configuration.viewport}',
        );
      }
    },
  );

  testWidgets('mobile vertical RoadMap handles zero and one stages', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
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
      find.byKey(const ValueKey('mobile-roadmap-skill-chooser')),
      findsOneWidget,
    );
    expect(find.byType(InteractiveViewer), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('mobile-roadmap-choose-single-roadmap')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mobile-roadmap-unified-single-roadmap')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-roadmap-root-single-roadmap')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('mobile-roadmap-skill-empty-roadmap')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mobile-roadmap-unified-empty-roadmap')),
      findsOneWidget,
    );
    expect(find.text('У пути пока нет этапов'), findsOneWidget);
    expect(find.text('Добавить этап'), findsOneWidget);
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
      ..onboardingSeen = true
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

    expect(find.byKey(const ValueKey('next-action-lens')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-skill-panel-compact')),
      findsOneWidget,
    );

    final mobileSkillChip = find.byKey(
      const ValueKey('mobile-skill-chip-mobile-skill'),
    );
    await tester.scrollUntilVisible(
      mobileSkillChip,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('mobile-skill-panel-compact')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(mobileSkillChip);
    await tester.pumpAndSettle();
    expect(mobileSkillChip.hitTestable(), findsOneWidget);
    await tester.tap(mobileSkillChip.hitTestable());
    await tester.pumpAndSettle();

    expect(find.textContaining(taskTitle), findsWidgets);
    expect(find.textContaining('Минимум:'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Карта').last);
    await tester.pumpAndSettle();

    expect(find.text('Развернуть'), findsNothing);
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(
      find.byKey(const ValueKey('mobile-roadmap-unified-mobile-skill')),
      findsOneWidget,
    );
    final graphViewport = tester.widget<ClipRect>(
      find.byKey(const ValueKey('mobile-roadmap-graph-viewport')),
    );
    expect(graphViewport.clipBehavior, Clip.hardEdge);
    final graphScroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('mobile-roadmap-graph-scroll-mobile-skill')),
    );
    expect(graphScroll.clipBehavior, Clip.hardEdge);
    final stageCard = find.byKey(
      const ValueKey('mobile-ascent-card-mobile-stage-middle'),
    );
    final stageCardColumn = tester.widget<Column>(
      find.descendant(of: stageCard, matching: find.byType(Column)).first,
    );
    expect(stageCardColumn.crossAxisAlignment, CrossAxisAlignment.center);
    final stageCardTitle = tester.widget<Text>(
      find.descendant(of: stageCard, matching: find.text('Практика')),
    );
    expect(stageCardTitle.textAlign, TextAlign.center);
    expect(stageCardTitle.style?.fontSize, greaterThanOrEqualTo(13));
    expect(
      find.byKey(const ValueKey('mobile-ascent-stage-mobile-stage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-ascent-stage-mobile-stage-middle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-ascent-stage-mobile-stage-terminal')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('mobile-roadmap-root-mobile-skill')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('mobile-ascent-stage-mobile-stage')),
            )
            .dy,
      ),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(
              const ValueKey('mobile-ascent-stage-mobile-stage-terminal'),
            ),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey('mobile-ascent-stage-mobile-stage-middle'),
              ),
            )
            .dy,
      ),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(
              const ValueKey('mobile-ascent-stage-mobile-stage-middle'),
            ),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('mobile-ascent-stage-mobile-stage')),
            )
            .dy,
      ),
    );
    expect(find.text('Шаблон RoadMap'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('mobile-roadmap-templates')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mobile-roadmap-template-sheet')),
      findsOneWidget,
    );
    expect(find.text('Шаблоны путей'), findsOneWidget);
    final mobileTemplateGrid = tester.widget<GridView>(
      find.byKey(const ValueKey('desktop-roadmap-template-grid')),
    );
    expect(
      (mobileTemplateGrid.gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      1,
    );
    expect(find.text('Простой'), findsOneWidget);
    expect(find.text('Нормальный'), findsOneWidget);
    expect(find.text('Сложный'), findsOneWidget);
    expect(find.text('Свой путь'), findsOneWidget);
    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-roadmap-mode-switcher')),
      findsNothing,
    );
    expect(find.text('Свободная карта'), findsNothing);
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile RoadMap renders runtime branches without graph changes', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        Skill(
          id: 'branching-mobile',
          name: 'Ветвящийся путь',
          goal: 'Проверить две дороги',
          color: const Color(0xFFFF3B70),
          icon: Icons.call_split_rounded,
          treeNodes: [
            SkillTreeNode(id: 'shared-root', title: 'Общая основа'),
            SkillTreeNode(
              id: 'left-branch',
              title: 'Левая ветка',
              prerequisiteIds: ['shared-root'],
            ),
            SkillTreeNode(
              id: 'right-branch',
              title: 'Правая ветка',
              prerequisiteIds: ['shared-root'],
            ),
          ],
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Карта').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('mobile-roadmap-choose-branching-mobile')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-ascent-stage-shared-root')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-ascent-stage-left-branch')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-ascent-stage-right-branch')),
      findsOneWidget,
    );
    expect(
      storage.skills
          .where((skill) => skill.id == 'branching-mobile')
          .single
          .treeNodes,
      hasLength(3),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile Act keeps next action inside selected skill focus', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        Skill(
          id: 'mobile-focus-skill',
          name: 'Flutter',
          goal: 'Выпустить приложение',
          color: const Color(0xFF4A9EFF),
          icon: Icons.code_rounded,
        ),
      ]
      ..tasks = [
        Task(
          id: 'mobile-focus-task',
          title: 'Подготовить экран релиза',
          skillId: 'mobile-focus-skill',
          xpReward: 80,
          type: TaskType.midTerm,
          minimumAction: 'Открыть макет и проверить один блок',
        ),
      ];
    await storage.init();

    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final lens = find.byKey(const ValueKey('next-action-lens'));
    expect(lens, findsOneWidget);
    expect(find.text('Следующее действие'), findsOneWidget);

    final focusSkillChip = find.byKey(
      const ValueKey('mobile-skill-chip-mobile-focus-skill'),
    );
    await tester.scrollUntilVisible(
      focusSkillChip,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('mobile-skill-panel-compact')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(focusSkillChip);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mobile-focus-quest-row-mobile-focus-task')),
      findsOneWidget,
    );
    expect(find.textContaining('Минимум:'), findsOneWidget);
    expect(
      find.textContaining('Открыть макет и проверить один блок'),
      findsOneWidget,
    );
    expect(lens, findsNothing);
    expect(find.byKey(const ValueKey('mobile-momentum-row')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile empty skill explains the next action and opens AddTask', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        Skill(
          id: 'empty-mobile-skill',
          name: 'Рисование',
          goal: 'Рисовать увереннее',
          color: const Color(0xFFFF9500),
          icon: Icons.brush_rounded,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(
      find.byKey(const ValueKey('mobile-skill-chip-empty-mobile-skill')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Добавь первый квест'), findsOneWidget);
    expect(find.textContaining('вернуться завтра'), findsOneWidget);
    await tester.tap(find.text('Создать квест').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-add-task-page')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile AddSkill protects a dirty draft on close', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const ValueKey('mobile-add-skill-open')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('add-skill-name-field')),
      'Новый навык',
    );
    await tester.tap(find.byKey(const ValueKey('mobile-form-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('Отменить изменения?'), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-add-skill-page')), findsOneWidget);
    await tester.tap(find.text('Продолжить редактирование'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-add-skill-page')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mobile-form-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить черновик'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-add-skill-page')), findsNothing);
    expect(storage.skills.where((skill) => skill.id != kInboxSkillId), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile AddTask protects a dirty draft from system back', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()
      ..onboardingSeen = true
      ..skills = [
        Skill(
          id: 'draft-skill',
          name: 'Flutter',
          goal: 'Проверить Back',
          color: const Color(0xFF4A9EFF),
          icon: Icons.code_rounded,
        ),
      ];
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(
      find.byKey(const ValueKey('mobile-skill-chip-draft-skill')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать квест').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('add-task-title-field')),
      'Не потерять черновик',
    );
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Отменить изменения?'), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-add-task-page')), findsOneWidget);

    await tester.tap(find.text('Удалить черновик'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-add-task-page')), findsNothing);
    expect(storage.tasks, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop AddSkill prioritizes live identity and optional stage', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? savedName;
    String? savedGoal;
    Color? savedColor;
    IconData? savedIcon;
    List<SkillTreeNode>? savedNodes;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddSkillDialog(
            isDark: true,
            onSave: (name, goal, _, color, icon, nodes, _) {
              savedName = name;
              savedGoal = goal;
              savedColor = color;
              savedIcon = icon;
              savedNodes = nodes;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.byKey(const ValueKey('desktop-skill-live-preview')))
          .height,
      lessThanOrEqualTo(112),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('desktop-add-skill-content')))
          .height,
      lessThan(700),
    );
    expect(
      find.byKey(const ValueKey('skill-curated-icon-strip')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('skill-icon-grid')), findsNothing);
    expect(find.text('Все иконки'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('add-skill-first-stage-field')).hitTestable(),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('add-skill-name-field')),
      'Сценарий',
    );
    await tester.enterText(
      find.byKey(const ValueKey('add-skill-goal-field')),
      'Подготовить первый выпуск',
    );
    await tester.pump();
    expect(find.text('Сценарий'), findsWidgets);
    expect(find.text('Подготовить первый выпуск'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('skill-icon-picker-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-skill-icon-picker')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('skill-icon-category-creativity')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('skill-icon-category-creativity')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Видео').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-skill-icon-picker')),
      findsNothing,
    );
    expect(
      tester
          .widget<Icon>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('skill-preview-icon')),
                  matching: find.byType(Icon),
                )
                .first,
          )
          .icon,
      Icons.tv,
    );
    await tester.tap(find.byKey(const ValueKey('skill-color-0')));
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('skill-first-stage-disclosure')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('add-skill-first-stage-field')),
      'Черновик',
    );
    await tester.tap(find.text('Создать').last);
    await tester.pumpAndSettle();

    expect(savedName, 'Сценарий');
    expect(savedGoal, 'Подготовить первый выпуск');
    expect(savedColor, kColors.first);
    expect(savedIcon, Icons.tv);
    expect(savedNodes, hasLength(1));
    expect(savedNodes!.single.title, 'Черновик');
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop AddSkill remains scrollable at 200 percent text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 650);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddSkillDialog(isDark: true, onSave: (_, _, _, _, _, _, _) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(
      find.byKey(const ValueKey('desktop-add-skill-content')),
    );
    expect(dialogRect.top, greaterThanOrEqualTo(0));
    expect(dialogRect.bottom, lessThanOrEqualTo(650));
    expect(find.text('Создать').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    final disclosure = find.byKey(
      const ValueKey('skill-first-stage-disclosure'),
    );
    await tester.ensureVisible(disclosure);
    await tester.pumpAndSettle();
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('add-skill-first-stage-field')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final pickerToggle = find.byKey(const ValueKey('skill-icon-picker-toggle'));
    await tester.ensureVisible(pickerToggle);
    await tester.pumpAndSettle();
    await tester.tap(pickerToggle);
    await tester.pumpAndSettle();
    final pickerRect = tester.getRect(
      find.byKey(const ValueKey('desktop-skill-icon-picker')),
    );
    expect(pickerRect.top, greaterThanOrEqualTo(0));
    expect(pickerRect.bottom, lessThanOrEqualTo(650));
    expect(find.byKey(const ValueKey('skill-full-icon-grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skill Creator edit preserves legacy and appearance values', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final existing = Skill(
      id: 'creator-existing',
      name: 'Монтаж',
      goal: 'Собрать первый ролик',
      checklist: ['Освоить склейки', 'Настроить звук'],
      color: const Color(0xFFFF453A),
      icon: Icons.movie_creation_outlined,
      treeNodes: [SkillTreeNode(id: 'existing-stage', title: 'Основа')],
    );
    String? savedName;
    String? savedGoal;
    List<String>? savedChecklist;
    Color? savedColor;
    IconData? savedIcon;
    List<SkillTreeNode>? submittedInitialNodes;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddSkillDialog(
            isDark: true,
            existing: existing,
            onSave: (name, goal, checklist, color, icon, nodes, _) {
              savedName = name;
              savedGoal = goal;
              savedChecklist = checklist;
              savedColor = color;
              savedIcon = icon;
              submittedInitialNodes = nodes;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Монтаж'), findsWidgets);
    expect(find.text('Собрать первый ролик'), findsWidgets);
    expect(
      find.byKey(const ValueKey('skill-first-stage-section')),
      findsNothing,
    );

    await tester.tap(find.text('Сохранить изменения').last);
    await tester.pumpAndSettle();

    expect(savedName, existing.name);
    expect(savedGoal, existing.goal);
    expect(savedChecklist, existing.checklist);
    expect(savedColor, existing.color);
    expect(savedIcon, existing.icon);
    expect(submittedInitialNodes, isEmpty);
    expect(existing.treeNodes.single.id, 'existing-stage');
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile AddSkill uses touch-friendly icon grid', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddSkillDialog(
            isDark: true,
            fullScreen: true,
            onSave: (_, _, _, _, _, _, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('skill-icon-grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 6);
    expect(grid.childrenDelegate.estimatedChildCount, 12);
    expect(find.text('Бой'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('skill-icon-grid')),
        matching: find.text('Разум'),
      ),
      findsOneWidget,
    );
    expect(find.text('Фокус'), findsOneWidget);
    final firstIcon = find.byTooltip('Бой').first;
    expect(tester.getSize(firstIcon).shortestSide, greaterThanOrEqualTo(44));
    final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
    expect(semantics.any((node) => node.properties.label == 'Бой'), isTrue);
    expect(
      semantics.any(
        (node) =>
            node.properties.label == 'Синий' &&
            node.properties.selected == true,
      ),
      isTrue,
    );
    final colorGrid = tester.widget<GridView>(
      find.byKey(const ValueKey('skill-color-grid')),
    );
    final colorDelegate =
        colorGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(colorDelegate.crossAxisCount, 6);
    expect(colorGrid.childrenDelegate.estimatedChildCount, 12);
    final firstRowY = tester
        .getCenter(find.byKey(const ValueKey('skill-color-0')))
        .dy;
    expect(
      tester.getCenter(find.byKey(const ValueKey('skill-color-5'))).dy,
      closeTo(firstRowY, 0.1),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('skill-color-6'))).dy,
      greaterThan(firstRowY),
    );
    final unselectedSwatch = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('skill-color-0')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final selectedSwatch = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('skill-color-8')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final unselectedDecoration = unselectedSwatch.decoration! as BoxDecoration;
    final selectedDecoration = selectedSwatch.decoration! as BoxDecoration;
    expect(unselectedDecoration.boxShadow, isNotEmpty);
    expect(
      selectedDecoration.boxShadow!.first.blurRadius,
      greaterThan(unselectedDecoration.boxShadow!.first.blurRadius),
    );
    expect(find.text('Все иконки'), findsOneWidget);
    expect(find.byKey(const ValueKey('skill-icon-category-all')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('skill-icon-picker-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('skill-icon-category-all')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<GridView>(find.byKey(const ValueKey('skill-icon-grid')))
          .childrenDelegate
          .estimatedChildCount,
      60,
    );
    expect(
      find.byKey(const ValueKey('mobile-form-top-save-hidden')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mobile-add-skill-save')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile AddSkill opens full-screen and validates save/cancel', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryStorageService()..onboardingSeen = true;
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const ValueKey('mobile-add-skill-open')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mobile-add-skill-page')), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(
      find.byKey(const ValueKey('mobile-add-skill-bottom-save')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mobile-add-skill-save')), findsNothing);
    expect(find.text('Твой новый навык'), findsOneWidget);
    expect(find.text('Название навыка'), findsOneWidget);
    final pageTitle = tester.widget<Text>(
      find.byKey(const ValueKey('mobile-form-title')),
    );
    expect(pageTitle.style?.fontWeight, FontWeight.w700);
    expect(pageTitle.style?.fontSize, 20);
    expect(
      tester.widget(
        find.byKey(const ValueKey('mobile-skill-section-Название навыка')),
      ),
      isA<Column>(),
    );
    expect(
      tester.widget(find.byKey(const ValueKey('mobile-skill-section-Цель'))),
      isA<Column>(),
    );
    final nameField = tester.widget<TextField>(
      find.byKey(const ValueKey('add-skill-name-field')),
    );
    final goalField = tester.widget<TextField>(
      find.byKey(const ValueKey('add-skill-goal-field')),
    );
    expect(
      nameField.decoration?.hintText,
      'Коротко назови направление, в котором хочешь расти.',
    );
    expect(
      goalField.decoration?.hintText,
      'Цель поможет понять, к чему ведёт путь.',
    );
    expect(find.text('Внешний вид'), findsOneWidget);
    expect(find.text('Первый этап (необязательно)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('add-skill-first-stage-field')).hitTestable(),
      findsNothing,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('skill-first-stage-disclosure')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('skill-first-stage-disclosure')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('add-skill-first-stage-field')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('add-skill-first-stage-field')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('mobile-add-skill-bottom-save')),
    );
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
    await tester.pumpAndSettle();
    expect(find.text('Мобильная разработка'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('add-skill-goal-field')),
      'Собрать приложение',
    );
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(const ValueKey('mobile-add-skill-bottom-save')),
    );
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

    await tester.tap(find.text('Настройки квеста'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('minimum-action-toggle')))
          .value,
      isFalse,
    );
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

    await tester.tap(find.text('Настройки квеста'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('minimum-action-toggle')))
          .value,
      isFalse,
    );
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

    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('minimum-action-toggle')))
          .value,
      isTrue,
    );
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
      expect(find.text('SMARTER квеста'), findsNothing);
      expect(find.text('Минимальный шаг'), findsOneWidget);
      expect(find.text('Контексты'), findsNothing);
      expect(find.text('Баланс и фокус'), findsNothing);
      expect(find.text('Ручной фокус'), findsNothing);
      expect(find.text('Повторяемость'), findsNothing);

      await tester.tap(find.text('Привычка'));
      await tester.pumpAndSettle();

      expect(find.text('Повторяемость'), findsOneWidget);
      expect(find.text('1 раз за 1 день'), findsOneWidget);
      expect(find.text('раз в 3 дня'), findsNothing);
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

    expect(find.text('Описание · необязательно'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Закрыть черновик');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Оставить короткую заметку к квесту',
    );
    await tester.ensureVisible(find.text('Создать'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();

    expect(savedDescription, 'Оставить короткую заметку к квесту');
  });

  testWidgets('quest form uses shared field order and XP grid', (
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
            isDark: true,
            skillColor: const Color(0xFFFF6B2C),
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

    final title = find.text('Название квеста');
    final description = find.text('Описание · необязательно');
    final xp = find.text('XP за квест');
    final settings = find.text('Настройки квеста');
    expect(title, findsOneWidget);
    expect(description, findsOneWidget);
    expect(xp, findsOneWidget);
    expect(settings, findsOneWidget);
    expect(find.text('Что сделать?'), findsNothing);
    expect(
      find.text('Создай задачу, которую хочешь реализовать.'),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(title).dy,
      lessThan(tester.getTopLeft(description).dy),
    );
    expect(
      tester.getTopLeft(description).dy,
      lessThan(tester.getTopLeft(xp).dy),
    );
    expect(tester.getTopLeft(xp).dy, lessThan(tester.getTopLeft(settings).dy));

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 10);
    expect(slider.max, 500);
    expect(slider.divisions, 49);
    expect(find.text('SMARTER квеста'), findsNothing);
  });

  testWidgets('legacy non-grid XP opens without mutating the task', (
    WidgetTester tester,
  ) async {
    final task = Task(
      id: 'legacy-xp',
      title: 'Старый квест',
      skillId: 'skill',
      xpReward: 305,
      type: TaskType.shortTerm,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTaskDialog(
            isDark: true,
            skillColor: const Color(0xFFFF6B2C),
            existing: task,
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

    expect(find.text('305 XP'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 310);
    expect(task.xpReward, 305);
    expect(tester.takeException(), isNull);
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

    // Дефолт нового квеста — 100 XP (см. `556a2a5`). Проверяется не он, а
    // то, что введённое вручную число прижимается к сетке: 75 -> 80.
    await tester.ensureVisible(find.text('100 XP').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('100 XP').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '75');
    expect(_hasContainerWithColor(tester, skillColor), isTrue);
    await tester.tap(find.text('Сохранить').last);
    await tester.pumpAndSettle();

    expect(find.text('80 XP'), findsOneWidget);
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

    await tester.ensureVisible(find.text('Создать'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();

    expect(savedTitle, 'прочитать 20 страниц');
    expect(savedMinimum, 'Открыть книгу на 5 минут');
  });
}
