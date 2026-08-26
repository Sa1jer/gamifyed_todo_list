import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models/tutorial_progress.dart';
import 'package:todo_list_app/tutorial/tutorial_coordinator.dart';

void main() {
  const coordinator = TutorialCoordinator();

  test('fresh Core follows skill, quest, useful action', () {
    expect(
      coordinator.defaultCoreStep(hasSkill: false, hasActiveQuest: false),
      TutorialStepIds.coreCreateSkill,
    );
    expect(
      coordinator.defaultCoreStep(hasSkill: true, hasActiveQuest: false),
      TutorialStepIds.coreCreateQuest,
    );
    expect(
      coordinator.defaultCoreStep(hasSkill: true, hasActiveQuest: true),
      TutorialStepIds.coreCompleteQuest,
    );
  });

  test('Core returns to quest creation when its first quest is removed', () {
    expect(
      coordinator.normalizedCoreStep(
        TutorialStepIds.coreCompleteQuest,
        hasSkill: true,
        hasActiveQuest: false,
      ),
      TutorialStepIds.coreCreateQuest,
    );
  });

  test('legacy Core step becomes completed without optional auto-chain', () {
    final result = coordinator.normalize(
      progress: const TutorialProgress(
        activeModuleId: TutorialModuleIds.core,
        activeStepId: TutorialStepIds.coreOpenStats,
      ),
      onboardingSeen: false,
      hasSkill: true,
      hasActiveQuest: true,
      now: DateTime(2026, 1, 2),
    );

    expect(result.changed, isTrue);
    expect(result.progress.activeModuleId, isNull);
    expect(result.progress.activeStepId, isNull);
    expect(result.progress.isModuleCompleted(TutorialModuleIds.core), isTrue);
    expect(
      result.progress.isModuleCompleted(TutorialModuleIds.roadmap),
      isFalse,
    );
    expect(result.progress.isModuleCompleted(TutorialModuleIds.stats), isFalse);
  });

  test('dismissed optional modules survive normalization', () {
    final result = coordinator.normalize(
      progress: const TutorialProgress(
        completedModuleIds: {TutorialModuleIds.core},
        dismissedModuleIds: {TutorialModuleIds.roadmap},
      ),
      onboardingSeen: true,
      hasSkill: true,
      hasActiveQuest: false,
    );

    expect(
      result.progress.dismissedModuleIds.contains(TutorialModuleIds.roadmap),
      isTrue,
    );
    expect(result.progress.activeModuleId, isNull);
  });

  test('unknown active module is removed safely', () {
    final result = coordinator.normalize(
      progress: const TutorialProgress(
        activeModuleId: 'removed-module',
        activeStepId: 'removed-step',
      ),
      onboardingSeen: false,
      hasSkill: false,
      hasActiveQuest: false,
    );

    expect(result.progress.activeModuleId, isNull);
    expect(result.progress.activeStepId, isNull);
  });
}
