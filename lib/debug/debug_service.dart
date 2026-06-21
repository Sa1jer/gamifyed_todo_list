import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models.dart';

class DebugAdminDraftState {
  final String? selectedScenarioId;
  final Map<String, bool> achievementUnlockOverrides;
  final int? profileLevelOverride;
  final int? profileXpOverride;
  final RewardRarity? pendingChestRarity;
  final BuffType? pendingBuffType;
  final DateTime? updatedAt;

  const DebugAdminDraftState({
    this.selectedScenarioId,
    this.achievementUnlockOverrides = const {},
    this.profileLevelOverride,
    this.profileXpOverride,
    this.pendingChestRarity,
    this.pendingBuffType,
    this.updatedAt,
  });

  const DebugAdminDraftState.empty()
    : selectedScenarioId = null,
      achievementUnlockOverrides = const {},
      profileLevelOverride = null,
      profileXpOverride = null,
      pendingChestRarity = null,
      pendingBuffType = null,
      updatedAt = null;

  bool get isEmpty =>
      selectedScenarioId == null &&
      achievementUnlockOverrides.isEmpty &&
      profileLevelOverride == null &&
      profileXpOverride == null &&
      pendingChestRarity == null &&
      pendingBuffType == null;

  int get overrideCount =>
      achievementUnlockOverrides.length +
      (profileLevelOverride == null ? 0 : 1) +
      (profileXpOverride == null ? 0 : 1) +
      (pendingChestRarity == null ? 0 : 1) +
      (pendingBuffType == null ? 0 : 1) +
      (selectedScenarioId == null ? 0 : 1);

  DebugAdminDraftState copyWith({
    String? selectedScenarioId,
    Map<String, bool>? achievementUnlockOverrides,
    int? profileLevelOverride,
    int? profileXpOverride,
    RewardRarity? pendingChestRarity,
    BuffType? pendingBuffType,
    DateTime? updatedAt,
  }) {
    return DebugAdminDraftState(
      selectedScenarioId: selectedScenarioId ?? this.selectedScenarioId,
      achievementUnlockOverrides:
          achievementUnlockOverrides ?? this.achievementUnlockOverrides,
      profileLevelOverride: profileLevelOverride ?? this.profileLevelOverride,
      profileXpOverride: profileXpOverride ?? this.profileXpOverride,
      pendingChestRarity: pendingChestRarity ?? this.pendingChestRarity,
      pendingBuffType: pendingBuffType ?? this.pendingBuffType,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedScenarioId': selectedScenarioId,
      'achievementUnlockOverrides': achievementUnlockOverrides,
      'profileLevelOverride': profileLevelOverride,
      'profileXpOverride': profileXpOverride,
      'pendingChestRarity': pendingChestRarity?.name,
      'pendingBuffType': pendingBuffType?.name,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String encode() => jsonEncode(toJson());

  static DebugAdminDraftState decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Debug draft state must be a JSON object.');
    }
    final data = Map<String, dynamic>.from(decoded);
    final overridesRaw = data['achievementUnlockOverrides'];
    final overrides = <String, bool>{};
    if (overridesRaw is Map) {
      for (final entry in overridesRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is bool) {
          overrides[key] = value;
        }
      }
    }

    return DebugAdminDraftState(
      selectedScenarioId: _readString(data['selectedScenarioId']),
      achievementUnlockOverrides: overrides,
      profileLevelOverride: _readInt(data['profileLevelOverride']),
      profileXpOverride: _readInt(data['profileXpOverride']),
      pendingChestRarity: _enumByName(
        RewardRarity.values,
        _readString(data['pendingChestRarity']),
      ),
      pendingBuffType: _enumByName(
        BuffType.values,
        _readString(data['pendingBuffType']),
      ),
      updatedAt: DateTime.tryParse(_readString(data['updatedAt']) ?? ''),
    );
  }

  static DebugAdminDraftState tryDecode(String raw) {
    try {
      return decode(raw);
    } catch (_) {
      return const DebugAdminDraftState.empty();
    }
  }

  static String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

class DebugService {
  static const boxName = '__debug__';
  static const _draftStateKey = 'draftState';

  Box<String>? _box;

  bool get isInitialized => _box != null;

  Future<void> init() async {
    assert(kDebugMode, 'DebugService must not be used outside debug mode');
    if (_box != null) return;
    _box = await Hive.openBox<String>(boxName);
  }

  Future<DebugAdminDraftState> loadDraftState() async {
    await init();
    final raw = _box!.get(_draftStateKey);
    if (raw == null) return const DebugAdminDraftState.empty();
    return DebugAdminDraftState.tryDecode(raw);
  }

  Future<void> saveDraftState(DebugAdminDraftState state) async {
    await init();
    final stateToSave = state.updatedAt == null
        ? state.copyWith(updatedAt: DateTime.now())
        : state;
    await _box!.put(_draftStateKey, stateToSave.encode());
  }

  Future<void> clear() async {
    await init();
    await _box!.clear();
  }

  @visibleForTesting
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
