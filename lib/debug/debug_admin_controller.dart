import 'package:flutter/foundation.dart';

import '../app_state.dart';
import 'debug_scenarios.dart';
import 'debug_service.dart';

class DebugAdminController {
  final AppState state;
  final DebugService debugService;

  const DebugAdminController({required this.state, required this.debugService});

  Future<void> applyScenario(DebugScenarioDef scenario) async {
    if (!kDebugMode) {
      throw StateError('Debug scenarios must not run outside debug mode.');
    }
    assert(kDebugMode, 'Debug scenarios must not run outside debug mode');
    scenario.apply(state);
    state.normalizeAfterBulkStateChange(
      resetBestStreak: scenario.resetBestStreak,
    );
    await state.flushSaves();

    final draft = await debugService.loadDraftState();
    await debugService.saveDraftState(
      draft.copyWith(
        selectedScenarioId: scenario.id,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> clearDebugDraftState() {
    if (!kDebugMode) {
      throw StateError('Debug tools must not run outside debug mode.');
    }
    assert(kDebugMode, 'Debug tools must not run outside debug mode');
    return debugService.clear();
  }
}
