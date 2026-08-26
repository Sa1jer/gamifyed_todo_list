import '../models/tutorial_progress.dart';
import 'tutorial_catalog.dart';

class TutorialNormalizationResult {
  const TutorialNormalizationResult(this.progress, {required this.changed});

  final TutorialProgress progress;
  final bool changed;
}

/// Pure progression and compatibility policy for the existing
/// [TutorialProgress] persistence model.
class TutorialCoordinator {
  const TutorialCoordinator();

  TutorialNormalizationResult normalize({
    required TutorialProgress progress,
    required bool onboardingSeen,
    required bool hasSkill,
    required bool hasActiveQuest,
    DateTime? now,
  }) {
    final completedModules = Set<String>.from(progress.completedModuleIds)
      ..removeWhere((id) => TutorialCatalog.module(id) == null);
    final completedSteps = Set<String>.from(progress.completedStepIds);
    final dismissedModules = Set<String>.from(progress.dismissedModuleIds)
      ..removeWhere((id) => TutorialCatalog.module(id) == null);
    var activeModule = progress.activeModuleId;
    var activeStep = progress.activeStepId;

    if (activeModule != null && TutorialCatalog.module(activeModule) == null) {
      activeModule = null;
      activeStep = null;
    }

    final legacyCorePassed =
        onboardingSeen ||
        completedModules.contains(TutorialModuleIds.core) ||
        completedSteps.any(TutorialCatalog.legacyCoreStepIds.contains) ||
        (activeModule == TutorialModuleIds.core &&
            activeStep != null &&
            TutorialCatalog.legacyCoreStepIds.contains(activeStep));

    if (legacyCorePassed) {
      completedModules.add(TutorialModuleIds.core);
      completedSteps.addAll(
        TutorialCatalog.stepIdsForModule(TutorialModuleIds.core),
      );
      if (activeModule == TutorialModuleIds.core) {
        activeModule = null;
        activeStep = null;
      }
    } else if (activeModule == TutorialModuleIds.core) {
      activeStep = normalizedCoreStep(
        activeStep ?? TutorialStepIds.coreCreateSkill,
        hasSkill: hasSkill,
        hasActiveQuest: hasActiveQuest,
      );
    } else if (activeModule != null) {
      final moduleSteps = TutorialCatalog.stepIdsForModule(activeModule);
      if (activeStep == null || !moduleSteps.contains(activeStep)) {
        activeStep = firstIncompleteStep(activeModule, completedSteps);
        if (activeStep == null) activeModule = null;
      }
    }

    final normalized = TutorialProgress(
      completedModuleIds: completedModules,
      completedStepIds: completedSteps,
      dismissedModuleIds: dismissedModules,
      activeModuleId: activeModule,
      activeStepId: activeStep,
      updatedAt: progress.updatedAt,
    );
    final changed = _signature(normalized) != _signature(progress);
    return TutorialNormalizationResult(
      changed
          ? normalized.copyWith(updatedAt: now ?? DateTime.now())
          : normalized,
      changed: changed,
    );
  }

  String normalizedCoreStep(
    String stepId, {
    required bool hasSkill,
    required bool hasActiveQuest,
  }) {
    if (!TutorialCatalog.stepIdsForModule(
      TutorialModuleIds.core,
    ).contains(stepId)) {
      return defaultCoreStep(
        hasSkill: hasSkill,
        hasActiveQuest: hasActiveQuest,
      );
    }
    if (!hasSkill) return TutorialStepIds.coreCreateSkill;
    if (stepId == TutorialStepIds.coreCreateSkill) {
      return hasActiveQuest
          ? TutorialStepIds.coreCompleteQuest
          : TutorialStepIds.coreCreateQuest;
    }
    if (stepId == TutorialStepIds.coreCreateQuest && hasActiveQuest) {
      return TutorialStepIds.coreCompleteQuest;
    }
    if (stepId == TutorialStepIds.coreCompleteQuest && !hasActiveQuest) {
      return TutorialStepIds.coreCreateQuest;
    }
    return stepId;
  }

  String defaultCoreStep({
    required bool hasSkill,
    required bool hasActiveQuest,
  }) {
    if (!hasSkill) return TutorialStepIds.coreCreateSkill;
    if (hasActiveQuest) return TutorialStepIds.coreCompleteQuest;
    return TutorialStepIds.coreCreateQuest;
  }

  String? firstIncompleteStep(String moduleId, Set<String> completedSteps) {
    for (final step in TutorialCatalog.stepIdsForModule(moduleId)) {
      if (!completedSteps.contains(step)) return step;
    }
    return null;
  }

  String? moduleForStep(String stepId) =>
      TutorialCatalog.step(stepId)?.moduleId;

  String? nextStep(String stepId) {
    final moduleId = moduleForStep(stepId);
    if (moduleId == null) return null;
    final steps = TutorialCatalog.stepIdsForModule(moduleId);
    final index = steps.indexOf(stepId);
    if (index < 0 || index == steps.length - 1) return null;
    return steps[index + 1];
  }

  String _signature(TutorialProgress progress) => <String>[
    ...(progress.completedModuleIds.toList()..sort()),
    '|',
    ...(progress.completedStepIds.toList()..sort()),
    '|',
    ...(progress.dismissedModuleIds.toList()..sort()),
    '|${progress.activeModuleId}|${progress.activeStepId}',
  ].join();
}
