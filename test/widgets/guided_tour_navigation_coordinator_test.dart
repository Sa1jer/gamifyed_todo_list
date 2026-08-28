import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models/tutorial_progress.dart';
import 'package:todo_list_app/tutorial/guided_tour_plan.dart';
import 'package:todo_list_app/tutorial/guided_tour_session.dart';
import 'package:todo_list_app/widgets/tutorial/guided_tour_navigation_coordinator.dart';
import 'package:todo_list_app/widgets/tutorial/guided_tour_session_controller.dart';
import 'package:todo_list_app/widgets/tutorial/tutorial_anchor_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('navigation coordinator hides, navigates, waits, then enters', () async {
    final controller = GuidedTourSessionController();
    final anchors = TutorialAnchorRegistry();
    addTearDown(controller.dispose);
    addTearDown(anchors.dispose);
    controller.startModuleReplay(
      TutorialModuleIds.roadmap,
      hasMinimumAction: false,
      hasRoadmapPractice: false,
    );
    var destination = GuidedTourDestination.act;
    final events = <String>[];
    final coordinator = GuidedTourNavigationCoordinator(
      controller: controller,
      anchors: anchors,
      currentDestination: () => destination,
      openDestination: (next) async {
        events.add('navigate:${next.name}');
        destination = next;
      },
      waitForDestination: (next) async {
        events.add('ready:${next.name}');
      },
      onStepFinished: (completed, next) {
        events.add('finished:${completed.id}');
      },
      onSessionCompleted: (_) => events.add('complete'),
      anchorTimeout: const Duration(milliseconds: 1),
    );

    controller.present();
    controller.beginLeaving();
    await coordinator.advance();

    expect(events, [
      'finished:tour.nav.roadmap',
      'navigate:roadmap',
      'ready:roadmap',
    ]);
    expect(controller.currentStep?.id, 'tour.roadmap.canvas');
    expect(controller.session?.phase, GuidedTourPhase.entering);
  });

  test(
    'previous follows the plan destination instead of route history',
    () async {
      final controller = GuidedTourSessionController();
      final anchors = TutorialAnchorRegistry();
      addTearDown(controller.dispose);
      addTearDown(anchors.dispose);
      controller.startModuleReplay(
        TutorialModuleIds.stats,
        hasMinimumAction: false,
        hasRoadmapPractice: false,
      );
      controller.advance();
      var destination = GuidedTourDestination.statistics;
      final visited = <GuidedTourDestination>[];
      final coordinator = GuidedTourNavigationCoordinator(
        controller: controller,
        anchors: anchors,
        currentDestination: () => destination,
        openDestination: (next) async {
          destination = next;
          visited.add(next);
        },
        waitForDestination: (_) async {},
        onStepFinished: (_, _) {},
        onSessionCompleted: (_) {},
        anchorTimeout: const Duration(milliseconds: 1),
      );

      await coordinator.previous();

      expect(controller.currentStep?.id, 'tour.nav.statistics');
      expect(visited, [GuidedTourDestination.act]);
    },
  );

  test('active anchor changes only when the semantic step changes', () {
    final controller = GuidedTourSessionController();
    addTearDown(controller.dispose);
    controller.startFullTour(hasMinimumAction: true, hasRoadmapPractice: false);
    var anchorChanges = 0;
    controller.activeAnchor.addListener(() => anchorChanges++);

    controller.present();
    controller.beginLeaving();
    expect(anchorChanges, 0);

    controller.advance();
    expect(controller.activeAnchor.value, TutorialAnchorId.actInbox);
    expect(anchorChanges, 1);
  });

  test('dispose cancels an in-flight destination wait safely', () async {
    final controller = GuidedTourSessionController();
    final anchors = TutorialAnchorRegistry();
    final destinationReady = Completer<void>();
    controller.startModuleReplay(
      TutorialModuleIds.stats,
      hasMinimumAction: false,
      hasRoadmapPractice: false,
    );
    final coordinator = GuidedTourNavigationCoordinator(
      controller: controller,
      anchors: anchors,
      currentDestination: () => GuidedTourDestination.act,
      openDestination: (_) async {},
      waitForDestination: (_) => destinationReady.future,
      onStepFinished: (_, _) {},
      onSessionCompleted: (_) {},
    );

    final entering = coordinator.enterStartedSession();
    await Future<void>.delayed(Duration.zero);
    coordinator.dispose();
    anchors.dispose();
    controller.dispose();
    destinationReady.complete();

    await entering;
  });

  test('late anchor notifications are ignored after disposal', () {
    final anchors = TutorialAnchorRegistry();

    anchors.dispose();

    expect(anchors.notifyAnchorChanged, returnsNormally);
  });
}
