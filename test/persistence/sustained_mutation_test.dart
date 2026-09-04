import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/storage_snapshot.dart';
import 'package:todo_list_app/utils.dart';

/// Настоящий Hive под сервисом, но с подсчётом фактических записей на диск.
class _CountingStorageService extends StorageService {
  _CountingStorageService({required super.hivePath});

  int snapshotWrites = 0;
  bool failNextSnapshotWrite = false;

  @override
  Future<void> saveSnapshot(StorageSnapshot snapshot) {
    snapshotWrites++;
    if (failNextSnapshotWrite) {
      failNextSnapshotWrite = false;
      return Future.error(StateError('snapshot write refused'));
    }
    return super.saveSnapshot(snapshot);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('todo-sustained-');
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  Skill skill(String id) => Skill(
    id: id,
    name: 'Skill $id',
    goal: 'Goal $id',
    color: const Color(0xFF336699),
    icon: Icons.star,
  );

  test(
    'sustained mutation collapses writes without losing the last one',
    () async {
      final storage = _CountingStorageService(hivePath: hiveDirectory.path);
      await storage.init();
      final state = AppState(storage: storage, seedDefaults: false);
      addTearDown(state.dispose);
      await state.loadSavedData();
      storage.snapshotWrites = 0;

      // Поток мутаций без паузы: именно так выглядит быстрый ввод и серия
      // нажатий, ради которой у планировщика есть догоняющий проход.
      for (var i = 0; i < 40; i++) {
        state.addSkill(skill('sustained-$i'));
      }
      await state.flushSaves();

      // Догоняющий проход один, а не по одному на мутацию.
      expect(
        storage.snapshotWrites,
        lessThan(10),
        reason: 'планировщик должен склеивать поток мутаций',
      );
      expect(storage.snapshotWrites, greaterThan(0));

      // Последняя мутация не потеряна: на диске финальное состояние.
      final committed = await storage.loadLatestSnapshot();
      final persisted = committed!.snapshot.skills.map((s) => s.id).toSet();
      for (var i = 0; i < 40; i++) {
        expect(persisted, contains('sustained-$i'));
      }
      expect(committed.source, SnapshotLoadSource.current);
    },
  );

  test('lifecycle flush leaves no pending work behind', () async {
    final storage = _CountingStorageService(hivePath: hiveDirectory.path);
    await storage.init();
    final state = AppState(storage: storage, seedDefaults: false);
    addTearDown(state.dispose);
    await state.loadSavedData();

    state.addSkill(skill('pending'));
    state.addTask(
      Task(
        id: 'pending-task',
        title: 'Persist me',
        skillId: 'pending',
        xpReward: 20,
        type: TaskType.shortTerm,
      ),
    );

    await state.flushSaves();
    final writesAfterFlush = storage.snapshotWrites;
    expect(state.persistenceStatus.isDirty, isFalse);

    // Чистый flush не пишет: снапшот на диске уже описывает это состояние.
    await state.flushSaves();
    expect(storage.snapshotWrites, writesAfterFlush);

    // Новая мутация возвращает право на запись.
    state.addSkill(skill('later'));
    expect(state.persistenceStatus.isDirty, isTrue);
    await state.flushSaves();
    expect(storage.snapshotWrites, greaterThan(writesAfterFlush));

    // Состояние доживает до перезапуска процесса.
    await Hive.close();
    final reopened = StorageService(hivePath: hiveDirectory.path);
    await reopened.init();
    final snapshot = (await reopened.loadLatestSnapshot())!.snapshot;
    expect(snapshot.skills.any((s) => s.id == 'pending'), isTrue);
    expect(snapshot.tasks.single.id, 'pending-task');
  });

  test(
    'a failed write keeps the state dirty so the next flush retries',
    () async {
      final storage = _CountingStorageService(hivePath: hiveDirectory.path);
      await storage.init();
      final state = AppState(storage: storage, seedDefaults: false);
      addTearDown(state.dispose);
      await state.loadSavedData();
      await state.flushSaves();
      storage.snapshotWrites = 0;

      state.addSkill(skill('survives-failure'));
      storage.failNextSnapshotWrite = true;
      await expectLater(state.flushSaves(), throwsA(isA<StateError>()));

      // Скипающий flush не должен проглотить работу, которую не удалось записать.
      expect(state.persistenceStatus.isDirty, isTrue);
      expect(storage.snapshotWrites, 1);

      await state.flushSaves();
      expect(storage.snapshotWrites, 2);
      expect(state.persistenceStatus.isDirty, isFalse);

      final committed = await storage.loadLatestSnapshot();
      expect(
        committed!.snapshot.skills.any((s) => s.id == 'survives-failure'),
        isTrue,
      );
    },
  );
}
