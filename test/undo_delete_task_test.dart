import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/utils.dart';

/// Покрывает примитивы отмены в `AppState`. Обвязка `deleteTaskWithUndo` —
/// снекбар с кнопкой «Отменить» — тестом не закрыта: она требует настоящего
/// `AppState`, а настоящий `StorageService` внутри `testWidgets` не завершает
/// ввод-вывод под фейковым временем. Правильное решение — вынести фейковое
/// хранилище из `widget_test.dart` и `app_state_test.dart` в общий хелпер и
/// писать виджет-тест на нём; третью копию фейка заводить не стоит.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('todo-undo-');
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  Task quest(String id) => Task(
    id: id,
    title: 'Квест $id',
    skillId: 'skill',
    xpReward: 20,
    type: TaskType.shortTerm,
  );

  /// Настоящий Hive, а не очередная копия фейкового хранилища: их в тестах уже
  /// две. Взамен всё, что делает реальный ввод-вывод, обязано выполняться в
  /// настоящей асинхронной зоне — внутри `testWidgets` время фейковое, и такой
  /// `await` не завершится никогда.
  Future<AppState> buildState() async {
    final storage = StorageService(hivePath: hiveDirectory.path);
    await storage.init();
    final state = AppState(storage: storage, seedDefaults: false);
    addTearDown(state.dispose);
    await state.loadSavedData();
    state.addSkill(
      Skill(
        id: 'skill',
        name: 'Навык',
        goal: 'Цель',
        color: const Color(0xFF4A9EFF),
        icon: Icons.star,
      ),
    );
    for (final id in ['first', 'second', 'third']) {
      state.addTask(quest(id));
    }
    return state;
  }

  List<String> questIds(AppState state) => state.tasks
      .where((task) => task.skillId == 'skill')
      .map((task) => task.id)
      .toList();

  test(
    'a restored quest returns to the position it was deleted from',
    () async {
      final state = await buildState();

      final removed = state.removeTaskForUndo('second')!;
      expect(removed.task.id, 'second');
      expect(questIds(state), ['first', 'third']);

      state.restoreTask(removed);

      // Порядок квестов пользователь задаёт руками, поэтому возврат в конец
      // списка отменял бы удаление лишь наполовину.
      expect(questIds(state), ['first', 'second', 'third']);
    },
  );

  test('restoring twice does not duplicate the quest', () async {
    final state = await buildState();

    final removed = state.removeTaskForUndo('first')!;
    state.restoreTask(removed);
    state.restoreTask(removed);

    expect(state.tasks.where((task) => task.id == 'first'), hasLength(1));
  });

  test(
    'removing an unknown id reports that there is nothing to undo',
    () async {
      final state = await buildState();

      expect(state.removeTaskForUndo('missing'), isNull);
      expect(questIds(state), ['first', 'second', 'third']);
    },
  );
}
