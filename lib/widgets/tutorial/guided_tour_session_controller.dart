import 'package:flutter/foundation.dart';

import '../../tutorial/guided_tour_plan.dart';
import '../../tutorial/guided_tour_session.dart';

/// Presentation-only owner for the current guided session.
///
/// Persisted tutorial history remains in AppState/TutorialProgress. This
/// controller never reads or mutates domain data and can be discarded safely
/// when MainPage is disposed.
class GuidedTourSessionController extends ChangeNotifier {
  GuidedTourSession? _session;
  bool _showCoreCompletion = false;

  /// Шаг, действие которого пользователь начал и бросил.
  ///
  /// Отмена диалога возвращала на побайтово ту же карточку: ни отклика, ни
  /// подсказки, что делать дальше. Флаг позволяет шагу сказать об этом и
  /// предложить пропуск.
  String? _abandonedStepId;
  final ValueNotifier<TutorialAnchorId?> activeAnchor = ValueNotifier(null);

  GuidedTourSession? get session => _session;
  GuidedTourSessionSnapshot? get snapshot => _session?.snapshot;
  GuidedTourStep? get currentStep => _session?.currentStep;
  bool get hasActiveSession =>
      _session != null && !_session!.isComplete && !_session!.isPaused;
  bool get hasResumableSession =>
      _session != null &&
      _session!.isPaused &&
      _session!.plan.mode != GuidedTourMode.firstRunCore;
  bool get showCoreCompletion => _showCoreCompletion;

  /// Пользователь открыл действие текущего шага и закрыл его, ничего не создав.
  bool get currentStepAbandoned =>
      _abandonedStepId != null && _abandonedStepId == currentStep?.id;

  void markStepAbandoned(String stepId) {
    if (_abandonedStepId == stepId) return;
    _abandonedStepId = stepId;
    notifyListeners();
  }

  void startFirstRun({String? initialStepId}) {
    _showCoreCompletion = false;
    _session = GuidedTourSession(
      GuidedTourPlan.firstRunCore(),
      initialStepId: initialStepId,
    );
    _notifyChanged();
  }

  void startFullTour({
    required bool hasMinimumAction,
    required bool hasRoadmapPractice,
  }) {
    _showCoreCompletion = false;
    _session = GuidedTourSession(
      GuidedTourPlan.fullProductTour(
        hasMinimumAction: hasMinimumAction,
        hasRoadmapPractice: hasRoadmapPractice,
      ),
    );
    _notifyChanged();
  }

  void startModuleReplay(
    String moduleId, {
    required bool hasMinimumAction,
    required bool hasRoadmapPractice,
  }) {
    _showCoreCompletion = false;
    _session = GuidedTourSession(
      GuidedTourPlan.moduleReplay(
        moduleId,
        hasMinimumAction: hasMinimumAction,
        hasRoadmapPractice: hasRoadmapPractice,
      ),
    );
    _notifyChanged();
  }

  void syncFirstRunStep(String? stepId, {required bool coreCompleted}) {
    final active = _session;
    if (active?.plan.mode != GuidedTourMode.firstRunCore) return;
    if (coreCompleted || stepId == null) {
      active!.complete();
      _showCoreCompletion = true;
      _notifyChanged();
      return;
    }
    if (active!.moveToStep(stepId)) _notifyChanged();
  }

  void present() => _mutate((session) => session.present());
  void beginLeaving() => _mutate((session) => session.beginLeaving());
  void beginNavigation() => _mutate((session) => session.beginNavigation());
  void waitForAnchor() => _mutate((session) => session.waitForAnchor());
  void beginEntering() => _mutate((session) => session.beginEntering());

  bool advance() {
    final active = _session;
    if (active == null) return false;
    final changed = active.advance();
    if (changed) _notifyChanged();
    return changed;
  }

  bool previous() {
    final active = _session;
    if (active == null) return false;
    final changed = active.previous();
    if (changed) _notifyChanged();
    return changed;
  }

  void pause() => _mutate((session) => session.pause());
  void resume() => _mutate((session) => session.resume());
  void restart() => _mutate((session) => session.restart());

  void dismissCoreCompletion() {
    if (!_showCoreCompletion) return;
    _showCoreCompletion = false;
    _session = null;
    _notifyChanged();
  }

  void end() {
    if (_session == null && !_showCoreCompletion) return;
    _session = null;
    _showCoreCompletion = false;
    _notifyChanged();
  }

  void _mutate(void Function(GuidedTourSession session) action) {
    final active = _session;
    if (active == null) return;
    final before = active.snapshot;
    action(active);
    final after = active.snapshot;
    if (before.phase != after.phase ||
        before.currentIndex != after.currentIndex) {
      _notifyChanged();
    }
  }

  void _notifyChanged() {
    // Любое движение сессии снимает отметку: она относится к конкретному шагу.
    if (_abandonedStepId != null && _abandonedStepId != currentStep?.id) {
      _abandonedStepId = null;
    }
    final nextAnchor = currentStep?.anchorId;
    if (activeAnchor.value != nextAnchor) activeAnchor.value = nextAnchor;
    notifyListeners();
  }

  @override
  void dispose() {
    activeAnchor.dispose();
    super.dispose();
  }
}
