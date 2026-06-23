import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../models.dart';
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

  Future<void> setAchievementUnlocked(String id, bool unlocked) async {
    if (!kDebugMode) {
      throw StateError(
        'Debug achievement tools must not run outside debug mode.',
      );
    }
    assert(
      kDebugMode,
      'Debug achievement tools must not run outside debug mode',
    );
    _ensureAchievements();
    final achievement = _achievementById(id);
    if (achievement == null) return;
    await _applyAchievementOverrides({id: unlocked});
  }

  Future<void> setAllAchievementsUnlocked(bool unlocked) async {
    if (!kDebugMode) {
      throw StateError(
        'Debug achievement tools must not run outside debug mode.',
      );
    }
    assert(
      kDebugMode,
      'Debug achievement tools must not run outside debug mode',
    );
    _ensureAchievements();
    await _applyAchievementOverrides({
      for (final definition in achievementDefinitions) definition.id: unlocked,
    });
  }

  Future<void> _applyAchievementOverrides(Map<String, bool> overrides) async {
    if (overrides.isEmpty) return;
    _setAchievementStates(overrides);
    state.normalizeAfterBulkStateChange();
    _ensureAchievements();
    _setAchievementStates(overrides);
    // Debug achievement changes should not surface as normal reward popups.
    state.consumeAchievementNotifications();
    state.refresh();
    await state.flushSaves();

    final draft = await debugService.loadDraftState();
    await debugService.saveDraftState(
      draft.copyWith(
        achievementUnlockOverrides: {
          ...draft.achievementUnlockOverrides,
          ...overrides,
        },
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _setAchievementStates(Map<String, bool> overrides) {
    for (final entry in overrides.entries) {
      final achievement = _achievementById(entry.key);
      if (achievement == null) continue;
      achievement.unlockedAt = entry.value ? DateTime.now() : null;
    }
  }

  void _ensureAchievements() {
    for (final achievement in state.achievements) {
      achievement.def ??= _definitionById(achievement.id);
    }
    for (final definition in achievementDefinitions) {
      if (_achievementById(definition.id) == null) {
        state.achievements.add(
          Achievement(id: definition.id)..def = definition,
        );
      }
    }
  }

  Achievement? _achievementById(String id) {
    for (final achievement in state.achievements) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }

  AchievementDef? _definitionById(String id) {
    for (final definition in achievementDefinitions) {
      if (definition.id == id) return definition;
    }
    return null;
  }
}
