import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:todo_list_app/debug/debug_service.dart';
import 'package:todo_list_app/models.dart';

void main() {
  group('DebugAdminDraftState', () {
    test('roundtrip keeps typed draft fields', () {
      final updatedAt = DateTime.utc(2026, 6, 21, 12, 30);
      final state = DebugAdminDraftState(
        selectedScenarioId: 'streak_7',
        achievementUnlockOverrides: {'first_task': true, 'level_5': false},
        profileLevelOverride: 12,
        profileXpOverride: 345,
        pendingChestRarity: RewardRarity.epic,
        pendingBuffType: BuffType.skillFocusXpBoost,
        updatedAt: updatedAt,
      );

      final decoded = DebugAdminDraftState.decode(state.encode());

      expect(decoded.selectedScenarioId, 'streak_7');
      expect(decoded.achievementUnlockOverrides, {
        'first_task': true,
        'level_5': false,
      });
      expect(decoded.profileLevelOverride, 12);
      expect(decoded.profileXpOverride, 345);
      expect(decoded.pendingChestRarity, RewardRarity.epic);
      expect(decoded.pendingBuffType, BuffType.skillFocusXpBoost);
      expect(decoded.updatedAt, updatedAt);
      expect(decoded.overrideCount, 7);
    });

    test('invalid JSON returns empty draft state safely', () {
      final decoded = DebugAdminDraftState.tryDecode('not-json');

      expect(decoded.isEmpty, isTrue);
      expect(decoded.overrideCount, 0);
    });
  });

  group('DebugService', () {
    late Directory hiveDir;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp('todo-debug-service-');
      Hive.init(hiveDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (await hiveDir.exists()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test('clear only clears the debug box', () async {
      final productionMeta = await Hive.openBox<String>('meta');
      await productionMeta.put('schemaVersion', '2');
      final service = DebugService();

      await service.saveDraftState(
        const DebugAdminDraftState(
          selectedScenarioId: 'epic_chest_pending',
          pendingChestRarity: RewardRarity.epic,
        ),
      );

      expect((await service.loadDraftState()).isEmpty, isFalse);

      await service.clear();

      expect((await service.loadDraftState()).isEmpty, isTrue);
      expect(productionMeta.get('schemaVersion'), '2');
      expect(service.isInitialized, isTrue);
    });

    test('corrupted box payload loads as empty draft state', () async {
      final debugBox = await Hive.openBox<String>(DebugService.boxName);
      await debugBox.put('draftState', 'not-json');
      final service = DebugService();

      final loaded = await service.loadDraftState();

      expect(loaded.isEmpty, isTrue);
      expect(loaded.overrideCount, 0);
    });
  });
}
