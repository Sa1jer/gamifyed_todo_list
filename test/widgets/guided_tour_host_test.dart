import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models/tutorial_progress.dart';
import 'package:todo_list_app/tutorial/guided_tour_plan.dart';
import 'package:todo_list_app/widgets/tutorial/guided_tour_host.dart';
import 'package:todo_list_app/widgets/tutorial/guided_tour_session_controller.dart';
import 'package:todo_list_app/widgets/tutorial/tutorial_anchor_registry.dart';
import 'package:todo_list_app/widgets/tutorial/tutorial_card_placement.dart';

void main() {
  test('placement evaluates all desktop sides and avoids target', () {
    const viewport = Size(900, 700);
    const card = Size(360, 220);
    const target = Rect.fromLTWH(20, 260, 120, 60);

    final result = TutorialCardPlacement.resolve(
      viewport: viewport,
      cardSize: card,
      safeInsets: EdgeInsets.zero,
      target: target,
    );

    expect(result.side, TutorialCardSide.right);
    expect((result.offset & card).overlaps(target), isFalse);
    expect((Offset.zero & viewport).contains(result.offset), isTrue);
  });

  test('placement falls back to a safe dock when side space is blocked', () {
    const viewport = Size(430, 700);
    const card = Size(390, 260);
    const target = Rect.fromLTWH(90, 250, 250, 160);

    final result = TutorialCardPlacement.resolve(
      viewport: viewport,
      cardSize: card,
      safeInsets: EdgeInsets.zero,
      target: target,
      reservedRegions: const [
        Rect.fromLTWH(0, 0, 430, 210),
        Rect.fromLTWH(0, 410, 430, 290),
      ],
    );

    expect(
      result.side,
      anyOf(TutorialCardSide.dockedBottom, TutorialCardSide.dockedTop),
    );
  });

  test('placement can choose every desktop side deterministically', () {
    const viewport = Size(1000, 760);
    const card = Size(320, 190);
    const cases = <(Rect, TutorialCardSide)>[
      (Rect.fromLTWH(40, 300, 80, 60), TutorialCardSide.right),
      (Rect.fromLTWH(880, 300, 80, 60), TutorialCardSide.left),
      (Rect.fromLTWH(450, 40, 100, 60), TutorialCardSide.bottom),
      (Rect.fromLTWH(450, 660, 100, 60), TutorialCardSide.top),
    ];

    for (final (target, side) in cases) {
      final result = TutorialCardPlacement.resolve(
        viewport: viewport,
        cardSize: card,
        safeInsets: EdgeInsets.zero,
        target: target,
      );
      expect(result.side, side);
      expect((result.offset & card).overlaps(target), isFalse);
    }
  });

  testWidgets('host shows one progress card and tracks a semantic anchor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GuidedTourSessionController();
    final anchors = TutorialAnchorRegistry();
    addTearDown(controller.dispose);
    addTearDown(anchors.dispose);
    controller.startModuleReplay(
      TutorialModuleIds.stats,
      hasMinimumAction: false,
      hasRoadmapPractice: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TutorialAnchorTarget(
                  registry: anchors,
                  id: TutorialAnchorId.navStatistics,
                  child: const SizedBox(width: 120, height: 60),
                ),
              ),
              GuidedTourHost(
                controller: controller,
                anchors: anchors,
                isDark: true,
                reducedMotion: true,
                mobile: false,
                onSkip: (_) {},
                onPrimary: (_) => controller.advance(),
                onPrevious: (_) => controller.previous(),
                onDismiss: (_) => controller.pause(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.byKey(const ValueKey('guided-tour-card')), findsOneWidget);
    expect(find.text('ОБУЧЕНИЕ · 1 ИЗ 2'), findsOneWidget);
    expect(find.text('История роста'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('host remains reachable at 200 percent text and Escape pauses', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GuidedTourSessionController();
    final anchors = TutorialAnchorRegistry();
    addTearDown(controller.dispose);
    addTearDown(anchors.dispose);
    controller.startModuleReplay(
      TutorialModuleIds.core,
      hasMinimumAction: false,
      hasRoadmapPractice: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Stack(
              children: [
                TutorialAnchorTarget(
                  registry: anchors,
                  id: TutorialAnchorId.actNextAction,
                  child: const SizedBox(width: 100, height: 50),
                ),
                GuidedTourHost(
                  controller: controller,
                  anchors: anchors,
                  isDark: false,
                  reducedMotion: true,
                  mobile: true,
                  onSkip: (_) {},
                  onPrimary: (_) => controller.advance(),
                  onPrevious: (_) => controller.previous(),
                  onDismiss: (_) => controller.pause(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.byKey(const ValueKey('guided-tour-primary')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(controller.hasResumableSession, isTrue);
    expect(find.byKey(const ValueKey('guided-tour-card')), findsNothing);
  });

  testWidgets('highlight follows event-driven target scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GuidedTourSessionController();
    final anchors = TutorialAnchorRegistry();
    final scrollController = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(anchors.dispose);
    addTearDown(scrollController.dispose);
    controller.startModuleReplay(
      TutorialModuleIds.core,
      hasMinimumAction: false,
      hasRoadmapPractice: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              anchors.notifyAnchorChanged();
              return false;
            },
            child: Stack(
              children: [
                ListView(
                  controller: scrollController,
                  children: [
                    const SizedBox(height: 220),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: KeyedSubtree(
                        key: anchors.keyFor(TutorialAnchorId.actNextAction),
                        child: const SizedBox(width: 120, height: 52),
                      ),
                    ),
                    const SizedBox(height: 700),
                  ],
                ),
                GuidedTourHost(
                  controller: controller,
                  anchors: anchors,
                  isDark: true,
                  reducedMotion: true,
                  mobile: false,
                  onSkip: (_) {},
                  onPrimary: (_) => controller.advance(),
                  onPrevious: (_) => controller.previous(),
                  onDismiss: (_) => controller.pause(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final before = tester.getRect(
      find.byKey(const ValueKey('guided-tour-highlight')),
    );

    scrollController.jumpTo(100);
    await tester.pump();
    await tester.pump();

    final after = tester.getRect(
      find.byKey(const ValueKey('guided-tour-highlight')),
    );
    expect(after.top, closeTo(before.top - 100, 1));
  });

  testWidgets('card and spotlight stay inside the viewport after resize', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GuidedTourSessionController();
    final anchors = TutorialAnchorRegistry();
    addTearDown(controller.dispose);
    addTearDown(anchors.dispose);
    controller.startModuleReplay(
      TutorialModuleIds.core,
      hasMinimumAction: false,
      hasRoadmapPractice: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 110,
                right: 24,
                child: TutorialAnchorTarget(
                  registry: anchors,
                  id: TutorialAnchorId.actNextAction,
                  child: const SizedBox(width: 120, height: 52),
                ),
              ),
              GuidedTourHost(
                controller: controller,
                anchors: anchors,
                isDark: false,
                reducedMotion: true,
                mobile: false,
                onSkip: (_) {},
                onPrimary: (_) => controller.advance(),
                onPrevious: (_) => controller.previous(),
                onDismiss: (_) => controller.pause(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    tester.view.physicalSize = const Size(520, 700);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final card = tester.getRect(find.byKey(const ValueKey('guided-tour-card')));
    final highlight = tester.getRect(
      find.byKey(const ValueKey('guided-tour-highlight')),
    );
    expect(card.left, greaterThanOrEqualTo(0));
    expect(card.right, lessThanOrEqualTo(520));
    expect(card.top, greaterThanOrEqualTo(0));
    expect(card.bottom, lessThanOrEqualTo(700));
    expect(highlight.left, greaterThanOrEqualTo(0));
    expect(highlight.right, lessThanOrEqualTo(520));
    expect(tester.takeException(), isNull);
  });
}
