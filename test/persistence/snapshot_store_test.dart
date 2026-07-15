import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/persistence/snapshot_store.dart';
import 'package:todo_list_app/storage_snapshot.dart';

class _MemoryBackend implements SnapshotBackend {
  final values = <String, String>{};
  String? failWriteKey;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (key == failWriteKey) throw StateError('write failed: $key');
    values[key] = value;
  }
}

StorageSnapshot _snapshot(String id) => StorageSnapshot(
  id: id,
  createdAt: DateTime.utc(2026, 7, 15),
  skills: const <Skill>[],
  tasks: const <Task>[],
  profile: UserProfile(name: id),
  history: const <HistoryEntry>[],
  achievements: const <Achievement>[],
  stats: null,
  bosses: const <Boss>[],
  rewardChests: const <RewardChest>[],
  buffs: const <Buff>[],
  weeklyGoals: const <WeeklyGoal>[],
  bestStreak: 0,
  isDark: true,
  sfxEnabled: true,
  tooltipsEnabled: true,
  onboardingSeen: false,
  tutorialProgress: const TutorialProgress.empty(),
);

void main() {
  late _MemoryBackend backend;
  late SnapshotStore store;

  setUp(() {
    backend = _MemoryBackend();
    store = SnapshotStore(
      backend: backend,
      encode: (snapshot) => '${snapshot.id}|${snapshot.profile.name}',
      decode: (raw) {
        final parts = raw.split('|');
        if (parts.length != 2) throw const FormatException('corrupt');
        return _snapshot(parts.first);
      },
    );
  });

  test('staging failure never advances the current manifest', () async {
    await store.save(_snapshot('first'));
    backend.failWriteKey = 'payload:second';

    await expectLater(store.save(_snapshot('second')), throwsStateError);

    expect(backend.values[SnapshotStore.currentManifestKey], 'first');
    expect((await store.loadLatest())?.snapshot.id, 'first');
  });

  test('corrupt current payload falls back to previous commit', () async {
    await store.save(_snapshot('first'));
    await store.save(_snapshot('second'));
    backend.values['payload:second'] = 'corrupt';

    final loaded = await store.loadLatest();

    expect(loaded?.snapshot.id, 'first');
    expect(loaded?.source, SnapshotLoadSource.previous);
  });

  test('committed empty collections remain authoritative', () async {
    await store.save(_snapshot('empty'));

    final loaded = await store.loadLatest();

    expect(loaded, isNotNull);
    expect(loaded!.snapshot.skills, isEmpty);
    expect(loaded.snapshot.tasks, isEmpty);
    expect(loaded.snapshot.history, isEmpty);
  });
}
