import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models/tutorial_progress.dart';
import 'package:todo_list_app/tutorial/guided_tour_plan.dart';
import 'package:todo_list_app/widgets/tutorial/guided_tour_app_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('final chapter completion is reported exactly once', () async {
    final completedModules = <String>[];
    final coordinator = GuidedTourAppCoordinator(
      currentDestination: () => GuidedTourDestination.act,
      openDestination: (_) async {},
      waitForDestination: (_) async {},
      isMounted: () => true,
      hasMinimumAction: () => false,
      hasRoadmapPractice: () => false,
      onCreateSkill: () {},
      onCreateQuest: () {},
      onAcknowledgeNextAction: () {},
      onDismissFirstRun: () {},
      onCompleteModule: completedModules.add,
    );
    addTearDown(coordinator.dispose);
    coordinator.controller.startModuleReplay(
      'removed-topic',
      hasMinimumAction: false,
      hasRoadmapPractice: false,
    );

    await coordinator.navigation.advance();

    expect(completedModules, [TutorialModuleIds.core]);
    expect(coordinator.controller.hasActiveSession, isFalse);
  });
}
