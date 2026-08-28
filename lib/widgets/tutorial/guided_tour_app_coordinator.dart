import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../models/tutorial_progress.dart';
import '../../tutorial/guided_tour_plan.dart';
import 'guided_tour_navigation_coordinator.dart';
import 'guided_tour_session_controller.dart';
import 'tutorial_anchor_registry.dart';
import 'tutorial_training_center.dart';

/// Presentation adapter between persisted tutorial history and the disposable
/// guided-tour session used by MainPage.
///
/// Domain ownership stays outside this class: every persistent action is an
/// explicit callback supplied by MainPage, while replay and navigation remain
/// session-only.
class GuidedTourAppCoordinator {
  GuidedTourAppCoordinator({
    required GuidedTourDestination Function() currentDestination,
    required GuidedTourDestinationAction openDestination,
    required GuidedTourDestinationWait waitForDestination,
    required this.isMounted,
    required this.hasMinimumAction,
    required this.hasRoadmapPractice,
    required this.onCreateSkill,
    required this.onCreateQuest,
    required this.onAcknowledgeNextAction,
    required this.onDismissFirstRun,
    required this.onCompleteModule,
    this.onTutorialChanged,
  }) {
    navigation = GuidedTourNavigationCoordinator(
      controller: controller,
      anchors: anchors,
      currentDestination: currentDestination,
      openDestination: openDestination,
      waitForDestination: waitForDestination,
      onStepFinished: _handleStepFinished,
      onSessionCompleted: _handleSessionCompleted,
    );
  }

  final GuidedTourSessionController controller = GuidedTourSessionController();
  final TutorialAnchorRegistry anchors = TutorialAnchorRegistry();
  late final GuidedTourNavigationCoordinator navigation;
  final bool Function() isMounted;
  final bool Function() hasMinimumAction;
  final bool Function() hasRoadmapPractice;
  final FutureOr<void> Function() onCreateSkill;
  final FutureOr<void> Function() onCreateQuest;
  final FutureOr<void> Function() onAcknowledgeNextAction;
  final FutureOr<void> Function() onDismissFirstRun;
  final void Function(String moduleId) onCompleteModule;
  final VoidCallback? onTutorialChanged;

  bool _enterScheduled = false;

  void syncPersistedState({
    required bool shouldShowFirstRun,
    required String? activeModuleId,
    required String? activeStepId,
    required bool coreCompleted,
  }) {
    final session = controller.session;
    if (session?.plan.mode == GuidedTourMode.firstRunCore) {
      if (activeModuleId == TutorialModuleIds.core) {
        final before = controller.snapshot;
        controller.syncFirstRunStep(activeStepId, coreCompleted: false);
        if (before?.currentIndex != controller.snapshot?.currentIndex) {
          onTutorialChanged?.call();
        }
      } else if (coreCompleted) {
        controller.syncFirstRunStep(null, coreCompleted: true);
        onTutorialChanged?.call();
      } else {
        controller.end();
      }
      return;
    }

    if (session != null && !session.isComplete) return;
    if (!shouldShowFirstRun || activeModuleId == null) return;

    if (activeModuleId == TutorialModuleIds.core) {
      controller.startFirstRun(initialStepId: activeStepId);
    } else {
      controller.startModuleReplay(
        activeModuleId,
        hasMinimumAction: hasMinimumAction(),
        hasRoadmapPractice: hasRoadmapPractice(),
      );
    }
    onTutorialChanged?.call();
    scheduleEnter();
  }

  Future<void> primary(GuidedTourStep step) async {
    if (controller.session?.plan.mode == GuidedTourMode.firstRunCore) {
      switch (step.id) {
        case TutorialStepIds.coreCreateSkill:
          await onCreateSkill();
          return;
        case TutorialStepIds.coreCreateQuest:
          await onCreateQuest();
          return;
        case TutorialStepIds.coreCompleteQuest:
          await onAcknowledgeNextAction();
          return;
      }
    }
    await navigation.advance();
  }

  Future<void> dismiss(GuidedTourStep step) async {
    if (controller.session?.plan.mode == GuidedTourMode.firstRunCore) {
      await onDismissFirstRun();
      controller.end();
      return;
    }
    controller.pause();
  }

  Future<void> previous(GuidedTourStep step) => navigation.previous();

  void showRestOfTour() {
    controller.dismissCoreCompletion();
    controller.startFullTour(
      hasMinimumAction: hasMinimumAction(),
      hasRoadmapPractice: hasRoadmapPractice(),
    );
    scheduleEnter();
  }

  void startUsingAfterCore() => controller.dismissCoreCompletion();

  void handleTrainingSelection(TutorialTrainingSelection selection) {
    switch (selection.action) {
      case TutorialTrainingAction.startFullTour:
      case TutorialTrainingAction.restartTour:
        controller.startFullTour(
          hasMinimumAction: hasMinimumAction(),
          hasRoadmapPractice: hasRoadmapPractice(),
        );
        scheduleEnter();
        return;
      case TutorialTrainingAction.continueTour:
        unawaited(navigation.resume());
        return;
      case TutorialTrainingAction.module:
        controller.startModuleReplay(
          selection.moduleId ?? TutorialModuleIds.core,
          hasMinimumAction: hasMinimumAction(),
          hasRoadmapPractice: hasRoadmapPractice(),
        );
        scheduleEnter();
        return;
    }
  }

  void scheduleEnter() {
    if (_enterScheduled) return;
    _enterScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterScheduled = false;
      if (isMounted()) unawaited(navigation.enterStartedSession());
    });
  }

  void dispose() {
    navigation.dispose();
    anchors.dispose();
    controller.dispose();
  }

  void _handleStepFinished(GuidedTourStep completed, GuidedTourStep? next) {
    if (next != null && next.chapterId != completed.chapterId) {
      onCompleteModule(completed.chapterId);
    }
  }

  void _handleSessionCompleted(GuidedTourPlan plan) {
    final last = plan.steps.lastOrNull;
    if (last != null) onCompleteModule(last.chapterId);
    controller.end();
  }
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
