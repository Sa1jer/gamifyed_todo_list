import 'guided_tour_plan.dart';

enum GuidedTourPhase {
  presenting,
  leaving,
  navigating,
  waitingForAnchor,
  entering,
  paused,
  completed,
}

class GuidedTourSessionSnapshot {
  const GuidedTourSessionSnapshot({
    required this.planId,
    required this.mode,
    required this.phase,
    required this.currentIndex,
    required this.totalSteps,
    required this.currentStep,
  });

  final String planId;
  final GuidedTourMode mode;
  final GuidedTourPhase phase;
  final int currentIndex;
  final int totalSteps;
  final GuidedTourStep? currentStep;

  int get displayIndex => currentStep == null ? totalSteps : currentIndex + 1;
  bool get isComplete => phase == GuidedTourPhase.completed;
  bool get isPaused => phase == GuidedTourPhase.paused;
}

/// Session-only guided-tour state. It owns no persistence, navigation,
/// BuildContext, timers, or domain models.
class GuidedTourSession {
  GuidedTourSession(this.plan, {String? initialStepId})
    : _currentIndex = _resolveInitialIndex(plan, initialStepId);

  final GuidedTourPlan plan;
  int _currentIndex;
  GuidedTourPhase _phase = GuidedTourPhase.entering;
  GuidedTourPhase _phaseBeforePause = GuidedTourPhase.presenting;

  GuidedTourStep? get currentStep =>
      _currentIndex < plan.steps.length ? plan.steps[_currentIndex] : null;
  int get currentIndex => _currentIndex;
  int get totalSteps => plan.steps.length;
  GuidedTourPhase get phase => _phase;
  bool get canGoPrevious => _currentIndex > 0;
  bool get isComplete => _phase == GuidedTourPhase.completed;
  bool get isPaused => _phase == GuidedTourPhase.paused;

  GuidedTourSessionSnapshot get snapshot => GuidedTourSessionSnapshot(
    planId: plan.id,
    mode: plan.mode,
    phase: _phase,
    currentIndex: _currentIndex.clamp(0, plan.steps.length),
    totalSteps: plan.steps.length,
    currentStep: currentStep,
  );

  void present() {
    if (!isComplete && !isPaused) _phase = GuidedTourPhase.presenting;
  }

  void beginLeaving() {
    if (!isComplete && !isPaused) _phase = GuidedTourPhase.leaving;
  }

  void beginNavigation() {
    if (!isComplete && !isPaused) _phase = GuidedTourPhase.navigating;
  }

  void waitForAnchor() {
    if (!isComplete && !isPaused) _phase = GuidedTourPhase.waitingForAnchor;
  }

  void beginEntering() {
    if (!isComplete && !isPaused) _phase = GuidedTourPhase.entering;
  }

  bool advance() {
    if (isComplete || isPaused) return false;
    if (_currentIndex >= plan.steps.length - 1) {
      _currentIndex = plan.steps.length;
      _phase = GuidedTourPhase.completed;
      return true;
    }
    _currentIndex++;
    _phase = GuidedTourPhase.entering;
    return true;
  }

  bool previous() {
    if (!canGoPrevious || isPaused) return false;
    _currentIndex--;
    _phase = GuidedTourPhase.entering;
    return true;
  }

  void pause() {
    if (isComplete || isPaused) return;
    _phaseBeforePause = _phase;
    _phase = GuidedTourPhase.paused;
  }

  void resume() {
    if (!isPaused) return;
    _phase = switch (_phaseBeforePause) {
      GuidedTourPhase.leaving ||
      GuidedTourPhase.navigating ||
      GuidedTourPhase.waitingForAnchor => GuidedTourPhase.waitingForAnchor,
      _ => GuidedTourPhase.entering,
    };
  }

  void restart() {
    _currentIndex = 0;
    _phase = GuidedTourPhase.entering;
  }

  bool moveToStep(String stepId) {
    final index = plan.steps.indexWhere((step) => step.id == stepId);
    if (index < 0 || index == _currentIndex) return false;
    _currentIndex = index;
    _phase = GuidedTourPhase.entering;
    return true;
  }

  void complete() {
    _currentIndex = plan.steps.length;
    _phase = GuidedTourPhase.completed;
  }

  static int _resolveInitialIndex(GuidedTourPlan plan, String? stepId) {
    if (stepId == null) return 0;
    final index = plan.steps.indexWhere((step) => step.id == stepId);
    return index < 0 ? 0 : index;
  }
}
