import '../../tutorial/guided_tour_plan.dart';
import 'guided_tour_session_controller.dart';
import 'tutorial_anchor_registry.dart';

typedef GuidedTourDestinationAction =
    Future<void> Function(GuidedTourDestination destination);
typedef GuidedTourDestinationWait =
    Future<void> Function(GuidedTourDestination destination);
typedef GuidedTourStepFinished =
    void Function(GuidedTourStep completed, GuidedTourStep? next);

/// Sequences presentation navigation without owning product state or routes.
///
/// MainPage supplies real destination bindings. This coordinator only enforces
/// the one-card transition order and bounded anchor readiness contract.
class GuidedTourNavigationCoordinator {
  GuidedTourNavigationCoordinator({
    required this.controller,
    required this.anchors,
    required this.currentDestination,
    required this.openDestination,
    required this.waitForDestination,
    required this.onStepFinished,
    required this.onSessionCompleted,
    this.anchorTimeout = const Duration(milliseconds: 1200),
  });

  final GuidedTourSessionController controller;
  final TutorialAnchorRegistry anchors;
  final GuidedTourDestination Function() currentDestination;
  final GuidedTourDestinationAction openDestination;
  final GuidedTourDestinationWait waitForDestination;
  final GuidedTourStepFinished onStepFinished;
  final void Function(GuidedTourPlan plan) onSessionCompleted;
  final Duration anchorTimeout;

  bool _busy = false;
  bool _disposed = false;

  bool get isBusy => _busy;

  Future<void> enterStartedSession() async {
    final session = controller.session;
    final step = session?.currentStep;
    if (session == null || step == null || _busy || _disposed) return;
    await _run(
      () => _prepareStep(
        step,
        preferredDestination: session.plan.initialDestination,
      ),
    );
  }

  Future<void> advance() async {
    final session = controller.session;
    final completed = session?.currentStep;
    if (session == null || completed == null || _busy || _disposed) return;
    await _run(() async {
      final navigationDestination = completed.navigateTo;
      if (!controller.advance()) return;
      final next = controller.currentStep;
      onStepFinished(completed, next);
      if (next == null) {
        onSessionCompleted(session.plan);
        return;
      }
      await _prepareStep(
        next,
        preferredDestination:
            navigationDestination ?? _preferredDestination(next),
      );
    });
  }

  Future<void> previous() async {
    final session = controller.session;
    if (session == null || !session.canGoPrevious || _busy || _disposed) {
      return;
    }
    await _run(() async {
      if (!controller.previous()) return;
      final step = controller.currentStep;
      if (step == null) return;
      await _prepareStep(
        step,
        preferredDestination: _preferredDestination(step),
      );
    });
  }

  Future<void> resume() async {
    final step = controller.currentStep;
    if (step == null || _busy || _disposed) return;
    controller.resume();
    await _run(
      () =>
          _prepareStep(step, preferredDestination: _preferredDestination(step)),
    );
  }

  Future<void> restart() async {
    final session = controller.session;
    if (session == null || _busy || _disposed) return;
    controller.restart();
    final step = controller.currentStep;
    if (step == null) return;
    await _run(
      () => _prepareStep(
        step,
        preferredDestination: session.plan.initialDestination,
      ),
    );
  }

  Future<void> _prepareStep(
    GuidedTourStep step, {
    required GuidedTourDestination preferredDestination,
  }) async {
    if (_disposed) return;
    if (currentDestination() != preferredDestination) {
      controller.beginNavigation();
      await openDestination(preferredDestination);
      if (_disposed) return;
    }
    controller.waitForAnchor();
    await waitForDestination(preferredDestination);
    if (_disposed) return;
    final anchor = step.anchorId;
    if (anchor != null &&
        step.presentation != GuidedTourPresentation.coachCard) {
      await anchors.waitUntilReady(anchor, timeout: anchorTimeout);
      if (_disposed) return;
    }
    controller.beginEntering();
  }

  void dispose() {
    _disposed = true;
  }

  GuidedTourDestination _preferredDestination(GuidedTourStep step) {
    switch (step.anchorId) {
      case TutorialAnchorId.navRoadmap:
      case TutorialAnchorId.navStatistics:
      case TutorialAnchorId.navTrophies:
      case TutorialAnchorId.profileEntry:
        return GuidedTourDestination.act;
      case null:
      case TutorialAnchorId.skillCreate:
      case TutorialAnchorId.questCreate:
      case TutorialAnchorId.actNextAction:
      case TutorialAnchorId.actMinimumAction:
      case TutorialAnchorId.actInbox:
      case TutorialAnchorId.roadmapCanvas:
      case TutorialAnchorId.roadmapPractice:
      case TutorialAnchorId.statisticsSummary:
      case TutorialAnchorId.trophiesSummary:
      case TutorialAnchorId.profileTraining:
        return step.destination ?? currentDestination();
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || _disposed) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }
}
