import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/persistence/snapshot_store.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/storage_snapshot.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'todo-storage-reopen-',
    );
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

  StorageSnapshot snapshot(String id, {List<Skill>? skills}) => StorageSnapshot(
    id: id,
    createdAt: DateTime.utc(2026, 7, 16),
    skills: skills ?? <Skill>[skill('skill-$id')],
    tasks: const <Task>[],
    profile: UserProfile(name: 'Snapshot $id'),
    history: const <HistoryEntry>[],
    achievements: const <Achievement>[],
    stats: null,
    bosses: const <Boss>[],
    rewardChests: const <RewardChest>[],
    buffs: const <Buff>[],
    weeklyGoals: const <WeeklyGoal>[],
    bestStreak: 4,
    isDark: true,
    sfxEnabled: true,
    tooltipsEnabled: false,
    onboardingSeen: true,
    tutorialProgress: const TutorialProgress.empty(),
  );

  test(
    'corrupt real box bytes never masquerade as a clean empty start',
    () async {
      // Инъекция сбоя в настоящий Hive, а не в подменённый StorageService:
      // в файл бокса пишем мусор, который не разбирается как его формат.
      final first = StorageService(hivePath: hiveDirectory.path);
      await first.init();
      await first.saveSkills(<Skill>[skill('doomed')]);
      await Hive.close();

      final boxFile = File('${hiveDirectory.path}/skills.hive');
      expect(boxFile.existsSync(), isTrue);
      boxFile.writeAsBytesSync(List<int>.filled(4096, 0x7f));

      Object? caught;
      List<Skill> loaded = const <Skill>[];
      final storage = StorageService(hivePath: hiveDirectory.path);
      try {
        await storage.init();
        loaded = await storage.loadSkills();
      } catch (error) {
        caught = error;
      }

      // Важен не тип исключения, а то, что порча не выглядит как чистый
      // пустой старт с целыми данными: либо падение, либо пустота.
      if (caught == null) {
        expect(loaded, isEmpty);
      }
    },
  );

  test(
    'write into a closed real box leaves the committed snapshot intact',
    () async {
      final storage = StorageService(hivePath: hiveDirectory.path);
      await storage.init();
      await storage.saveSnapshot(snapshot('committed'));

      // Прерванная запись: боксы закрыты под работающим сервисом.
      await Hive.close();
      await expectLater(
        storage.saveSnapshot(snapshot('never-committed')),
        throwsA(anything),
      );

      final reopened = StorageService(hivePath: hiveDirectory.path);
      await reopened.init();
      final loaded = await reopened.loadLatestSnapshot();
      expect(loaded?.snapshot.id, 'committed');
      expect(loaded?.source, SnapshotLoadSource.current);
    },
  );

  test(
    'saving the same snapshot twice stays idempotent on real Hive',
    () async {
      final storage = StorageService(hivePath: hiveDirectory.path);
      await storage.init();
      await storage.saveSnapshot(snapshot('once'));
      await storage.saveSnapshot(snapshot('once'));
      await Hive.close();

      final reopened = StorageService(hivePath: hiveDirectory.path);
      await reopened.init();
      expect((await reopened.loadLatestSnapshot())?.snapshot.id, 'once');
      final box = Hive.box<String>('storage_snapshots');
      final payloads = box.keys
          .whereType<String>()
          .where((key) => key.startsWith(SnapshotStore.payloadPrefix))
          .toList();
      expect(payloads.length, lessThanOrEqualTo(2));
    },
  );

  test(
    'legacy boxes and committed snapshot survive a real Hive reopen',
    () async {
      final first = StorageService(hivePath: hiveDirectory.path);
      await first.init();
      await first.saveSkills(<Skill>[skill('legacy-skill')]);
      await first.saveTasks(<Task>[
        Task(
          id: 'legacy-task',
          title: 'Persist me',
          skillId: 'legacy-skill',
          xpReward: 30,
          type: TaskType.shortTerm,
        ),
      ]);
      await first.saveProfile(UserProfile(name: 'Persisted profile'));
      await first.saveTheme(false);
      await first.saveBestStreak(7);
      await first.saveSnapshot(snapshot('committed'));

      await Hive.close();

      final reopened = StorageService(hivePath: hiveDirectory.path);
      await reopened.init();

      expect((await reopened.loadSkills()).single.id, 'legacy-skill');
      expect((await reopened.loadTasks()).single.id, 'legacy-task');
      expect((await reopened.loadProfile()).name, 'Persisted profile');
      expect(await reopened.loadTheme(), isFalse);
      expect(await reopened.loadBestStreak(), 7);
      expect((await reopened.loadLatestSnapshot())?.snapshot.id, 'committed');
    },
  );

  test(
    'corrupt current payload falls back after process-like reopen',
    () async {
      final first = StorageService(hivePath: hiveDirectory.path);
      await first.init();
      await first.saveSnapshot(snapshot('previous'));
      await first.saveSnapshot(snapshot('current'));
      await Hive.close();

      final reopened = StorageService(hivePath: hiveDirectory.path);
      await reopened.init();
      final snapshotBox = Hive.box<String>('storage_snapshots');
      await snapshotBox.put('${SnapshotStore.payloadPrefix}current', '{broken');

      final loaded = await reopened.loadLatestSnapshot();
      expect(loaded?.snapshot.id, 'previous');
      expect(loaded?.source, SnapshotLoadSource.previous);
    },
  );

  test(
    'committed empty collections remain authoritative after reopen',
    () async {
      final first = StorageService(hivePath: hiveDirectory.path);
      await first.init();
      await first.saveSkills(<Skill>[skill('stale-legacy-skill')]);
      await first.saveSnapshot(snapshot('empty', skills: const <Skill>[]));
      await Hive.close();

      final reopened = StorageService(hivePath: hiveDirectory.path);
      await reopened.init();
      final loaded = await reopened.loadLatestSnapshot();

      expect(loaded, isNotNull);
      expect(loaded!.snapshot.skills, isEmpty);
      expect((await reopened.loadSkills()).single.id, 'stale-legacy-skill');
    },
  );
}
