import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/utils.dart';
import 'package:todo_list_app/widgets/shared/undo_delete.dart';

import 'helpers/in_memory_storage_service.dart';

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

  group('the undo notice', () {
    /// Хранилище в памяти, а не Hive: настоящий ввод-вывод внутри
    /// `testWidgets` не завершается под фейковым временем и вешает тест.
    Future<AppState> buildWidgetState() async {
      final storage = InMemoryStorageService();
      await storage.init();
      final state = AppState(storage: storage, seedDefaults: false);
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

    Widget harness(AppState state, String taskId) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => deleteTaskWithUndo(context, state, taskId),
            child: const Text('удалить'),
          ),
        ),
      ),
    );

    /// Снекбар держит таймер автозакрытия, планировщик сохранения — дебаунс.
    /// Оба обязаны истечь до проверки инвариантов.
    Future<void> settle(WidgetTester tester, AppState state) async {
      state.dispose();
      await tester.pump(const Duration(seconds: 8));
    }

    testWidgets('offers an undo that puts the quest back', (tester) async {
      final state = await buildWidgetState();

      await tester.pumpWidget(harness(state, 'second'));
      await tester.tap(find.text('удалить'));
      await tester.pumpAndSettle();

      expect(questIds(state), ['first', 'third']);
      expect(find.byKey(const ValueKey('undo-delete-task')), findsOneWidget);

      await tester.tap(find.text('Отменить'));
      await tester.pumpAndSettle();

      expect(questIds(state), ['first', 'second', 'third']);
      await settle(tester, state);
    });

    testWidgets('trims a long title so the notice stays readable', (
      tester,
    ) async {
      final state = await buildWidgetState();
      state.addTask(
        Task(
          id: 'verbose',
          title:
              'Очень длинное название квеста, которое не влезает в подсказку',
          skillId: 'skill',
          xpReward: 20,
          type: TaskType.shortTerm,
        ),
      );

      await tester.pumpWidget(harness(state, 'verbose'));
      await tester.tap(find.text('удалить'));
      await tester.pumpAndSettle();

      expect(find.textContaining('…'), findsOneWidget);
      expect(find.textContaining('не влезает в подсказку'), findsNothing);
      await settle(tester, state);
    });
  });
}
