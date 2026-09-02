import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';
import 'package:todo_list_app/storage_snapshot.dart';
import 'package:todo_list_app/user_data_transfer.dart';

import 'support/fault_injecting_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('имя файла берёт дату экспорта', () {
    expect(
      UserDataTransfer.suggestedFileName(DateTime(2026, 8, 31)),
      'rpg-todo-2026-08-31.json',
    );
    expect(
      UserDataTransfer.suggestedFileName(DateTime(2026, 1, 5)),
      'rpg-todo-2026-01-05.json',
    );
  });

  Future<AppState> freshState() async {
    final storage = FaultInjectingStorageService(snapshotSupport: true);
    final state = AppState(storage: storage, seedDefaults: false);
    await state.loadSavedData();
    return state;
  }

  group('перенос данных между устройствами', () {
    test('экспорт и импорт переносят навыки, квесты и профиль', () async {
      final source = await freshState();
      addTearDown(source.dispose);
      expect(source.supportsDataTransfer, isTrue);

      source.skills.add(
        Skill(
          id: 'axe',
          name: 'секира',
          goal: 'дойти до конца',
          color: const Color(0xFF4A9EFF),
          icon: Icons.fitness_center,
        ),
      );
      source.tasks.add(
        Task(
          id: 'quest-1',
          title: 'Первый квест',
          skillId: 'axe',
          xpReward: 60,
          type: TaskType.shortTerm,
        ),
      );
      source.profile.name = 'Странник';
      await source.flushSaves();

      final exported = source.exportUserData();
      expect(exported, contains('секира'));
      expect(exported, contains('Первый квест'));

      // Другое устройство: пустое хранилище, тот же файл.
      final target = await freshState();
      addTearDown(target.dispose);
      expect(target.tasks, isEmpty);

      expect(await target.importUserData(exported), isTrue);
      expect(target.skills.any((skill) => skill.id == 'axe'), isTrue);
      expect(target.tasks.single.title, 'Первый квест');
      expect(target.tasks.single.xpReward, 60);
      expect(target.profile.name, 'Странник');
    });

    test('чужой файл отклоняется и ничего не перезаписывает', () async {
      final state = await freshState();
      addTearDown(state.dispose);
      state.skills.add(
        Skill(
          id: 'keep',
          name: 'останется',
          goal: 'цель',
          color: const Color(0xFF34C759),
          icon: Icons.favorite,
        ),
      );
      await state.flushSaves();

      // Разбор идёт до записи: битый файл не должен стирать данные.
      for (final payload in ['{"это":"не наш файл"}', 'не json вовсе']) {
        await expectLater(
          state.importUserData(payload),
          throwsA(
            isA<UserDataImportException>().having(
              (error) => error.reason,
              'reason',
              UserDataImportFailure.unreadable,
            ),
          ),
        );
        expect(state.skills.any((skill) => skill.id == 'keep'), isTrue);
        expect(state.tasks, isEmpty);
      }
    });

    test('файл другой версии схемы отличается от битого', () async {
      final state = await freshState();
      addTearDown(state.dispose);
      final exported = state.exportUserData();
      final foreign = exported.replaceFirst(
        '"version":$kStorageSnapshotVersion',
        '"version":${kStorageSnapshotVersion + 7}',
      );
      expect(foreign, isNot(exported));

      await expectLater(
        state.importUserData(foreign),
        throwsA(
          isA<UserDataImportException>().having(
            (error) => error.reason,
            'reason',
            UserDataImportFailure.versionMismatch,
          ),
        ),
      );
    });
  });
}
