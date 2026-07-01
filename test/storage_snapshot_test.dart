import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/persistence_status.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/storage_snapshot.dart';

import 'support/fault_injecting_storage.dart';

class _MemorySnapshotBackend implements SnapshotBackend {
  final Map<String, String> values = <String, String>{};
  String? failWriteKey;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (key == failWriteKey) {
      throw StateError('Injected write failure for $key');
    }
    values[key] = value;
  }
}

void main() {
  Skill skill(String id) => Skill(
    id: id,
    name: id,
    goal: 'Goal $id',
    color: const Color(0xff336699),
    icon: Icons.star,
  );

  StorageSnapshot snapshot(String id, {String? skillId}) => StorageSnapshot(
    id: id,
    createdAt: DateTime.utc(2026, 7, 1),
    skills: <Skill>[skill(skillId ?? 'skill-$id')],
    tasks: const <Task>[],
    profile: UserProfile(name: 'Snapshot $id'),
    history: const <HistoryEntry>[],
    achievements: const <Achievement>[],
    stats: null,
    bosses: const <Boss>[],
    rewardChests: const <RewardChest>[],
    buffs: const <Buff>[],
    weeklyGoals: const <WeeklyGoal>[],
    bestStreak: 3,
    isDark: true,
    sfxEnabled: true,
    tooltipsEnabled: true,
    onboardingSeen: false,
    tutorialProgress: const TutorialProgress.empty(),
  );

  group('snapshot manifest commit protocol', () {
    test('commits payload before making it current', () async {
      final backend = _MemorySnapshotBackend();
      final storage = StorageService(snapshotBackend: backend);

      await storage.saveSnapshot(snapshot('first'));
      final loaded = await storage.loadLatestSnapshot();

      expect(backend.values['payload:first'], isNotNull);
      expect(backend.values['manifest_current'], 'first');
      expect(loaded?.snapshot.id, 'first');
      expect(loaded?.source, SnapshotLoadSource.current);
    });

    test('interrupted staging write cannot replace current snapshot', () async {
      final backend = _MemorySnapshotBackend();
      final storage = StorageService(snapshotBackend: backend);
      await storage.saveSnapshot(snapshot('first'));
      backend.failWriteKey = 'payload:second';

      await expectLater(
        storage.saveSnapshot(snapshot('second')),
        throwsA(isA<StateError>()),
      );

      expect(backend.values['manifest_current'], 'first');
      expect((await storage.loadLatestSnapshot())?.snapshot.id, 'first');
    });

    test('manifest failure leaves the previous commit loadable', () async {
      final backend = _MemorySnapshotBackend();
      final storage = StorageService(snapshotBackend: backend);
      await storage.saveSnapshot(snapshot('first'));
      backend.failWriteKey = 'manifest_current';

      await expectLater(
        storage.saveSnapshot(snapshot('second')),
        throwsA(isA<StateError>()),
      );

      expect(backend.values['manifest_current'], 'first');
      expect((await storage.loadLatestSnapshot())?.snapshot.id, 'first');
    });

    test('corrupted current snapshot falls back to previous', () async {
      final backend = _MemorySnapshotBackend();
      final storage = StorageService(snapshotBackend: backend);
      await storage.saveSnapshot(snapshot('first'));
      await storage.saveSnapshot(snapshot('second'));
      backend.values['payload:second'] = '{corrupted';

      final loaded = await storage.loadLatestSnapshot();

      expect(loaded?.snapshot.id, 'first');
      expect(loaded?.source, SnapshotLoadSource.previous);
    });

    test(
      'no valid committed snapshot returns null for legacy fallback',
      () async {
        final backend = _MemorySnapshotBackend();
        final storage = StorageService(snapshotBackend: backend);
        await storage.saveSnapshot(snapshot('first'));
        await storage.saveSnapshot(snapshot('second'));
        backend.values['payload:first'] = '{corrupted';
        backend.values['payload:second'] = '{corrupted';

        expect(await storage.loadLatestSnapshot(), isNull);
      },
    );

    test('snapshot round-trip validates domain counts and stable ids', () {
      final storage = StorageService(snapshotBackend: _MemorySnapshotBackend());
      final encoded = storage.debugEncodeSnapshot(snapshot('round-trip'));

      final decoded = storage.debugDecodeSnapshot(encoded);

      expect(decoded.id, 'round-trip');
      expect(decoded.skills.single.id, 'skill-round-trip');
      expect(decoded.profile.name, 'Snapshot round-trip');
      expect(decoded.bestStreak, 3);
    });

    test('snapshot with a mismatched domain count is rejected', () {
      final storage = StorageService(snapshotBackend: _MemorySnapshotBackend());
      final encoded = storage.debugEncodeSnapshot(snapshot('count-mismatch'));
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      final counts = json['counts'] as Map<String, dynamic>;
      counts['skills'] = 99;

      expect(
        () => storage.debugDecodeSnapshot(jsonEncode(json)),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('AppState snapshot integration', () {
    test(
      'successful legacy load creates the first committed snapshot',
      () async {
        final storage = FaultInjectingStorageService(
          skills: <Skill>[skill('legacy-skill')],
          snapshotSupport: true,
        );
        final state = AppState(storage: storage);
        addTearDown(state.dispose);

        await state.loadSavedData();

        expect(storage.operations, contains(StorageOperation.loadSkills));
        expect(storage.operations, contains(StorageOperation.saveSnapshot));
        expect(storage.savedSnapshots, hasLength(1));
        expect(storage.persistedSkills.map((item) => item.id), <String>[
          'legacy-skill',
        ]);
        expect(state.persistenceStatus.phase, PersistencePhase.ready);
      },
    );

    test('valid committed snapshot bypasses legacy domain reads', () async {
      final storage = FaultInjectingStorageService(snapshotSupport: true)
        ..committedSnapshot = CommittedSnapshot(
          snapshot: snapshot('current', skillId: 'snapshot-skill'),
          source: SnapshotLoadSource.current,
        );
      final state = AppState(storage: storage);
      addTearDown(state.dispose);

      await state.loadSavedData();

      expect(storage.operations.first, StorageOperation.loadSnapshot);
      expect(storage.operations, isNot(contains(StorageOperation.loadSkills)));
      expect(storage.operations, isNot(contains(StorageOperation.loadTasks)));
      expect(state.skills.map((item) => item.id), contains('snapshot-skill'));
      expect(state.profile.name, 'Snapshot current');
    });

    test('snapshot commit failure remains dirty and retryable', () async {
      final storage = FaultInjectingStorageService(snapshotSupport: true)
        ..committedSnapshot = CommittedSnapshot(
          snapshot: snapshot('current'),
          source: SnapshotLoadSource.current,
        )
        ..failBeforeOperation = StorageOperation.saveSnapshot;
      final state = AppState(storage: storage);
      addTearDown(() {
        storage.clearFailures();
        state.dispose();
      });
      await state.loadSavedData();

      await expectLater(
        state.flushSaves(),
        throwsA(isA<InjectedStorageFailure>()),
      );

      expect(state.persistenceStatus.phase, PersistencePhase.saveFailed);
      expect(state.persistenceStatus.isDirty, isTrue);
      expect(storage.committedSnapshot?.snapshot.id, 'current');
      storage.clearFailures();
      expect(await state.retrySave(), isTrue);
      expect(state.persistenceStatus.phase, PersistencePhase.ready);
    });
  });
}
