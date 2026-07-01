import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/main.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/persistence_status.dart';
import 'package:todo_list_app/utils.dart';
import 'package:todo_list_app/widgets/persistence_recovery.dart';

import 'support/fault_injecting_storage.dart';

void main() {
  Skill skill(String id) => Skill(
    id: id,
    name: id,
    goal: '',
    color: const Color(0xff336699),
    icon: Icons.star,
  );

  Task task(String id, String skillId) => Task(
    id: id,
    skillId: skillId,
    title: id,
    xpReward: 10,
    type: TaskType.shortTerm,
  );

  group('storage reliability characterization', () {
    test('successful load reports ready state', () async {
      final storage = FaultInjectingStorageService();
      final state = AppState(storage: storage);
      addTearDown(state.dispose);

      await state.loadSavedData();

      expect(state.hasLoadedSavedData, isTrue);
      expect(state.persistenceStatus.phase, PersistencePhase.ready);
      expect(state.persistenceStatus.lastSuccessfulLoadAt, isNotNull);
      expect(state.persistenceStatus.blocksSaving, isFalse);
    });

    test(
      'load failure is propagated and does not report a completed load',
      () async {
        final storage = FaultInjectingStorageService(
          skills: <Skill>[skill('stored-skill')],
        )..failBeforeOperation = StorageOperation.loadTasks;
        final state = AppState(storage: storage);
        addTearDown(() async {
          storage.clearFailures();
          state.dispose();
          await state.flushSaves();
        });

        await expectLater(
          state.loadSavedData(),
          throwsA(isA<InjectedStorageFailure>()),
        );

        expect(state.hasLoadedSavedData, isFalse);
        expect(state.persistenceStatus.phase, PersistencePhase.loadFailed);
        expect(state.persistenceStatus.canRetry, isTrue);
        expect(state.persistenceStatus.blocksSaving, isTrue);
        expect(storage.operations, <StorageOperation>[
          StorageOperation.loadSkills,
          StorageOperation.loadTasks,
        ]);
        expect(
          storage.operations.where(
            (operation) => operation.name.startsWith('save'),
          ),
          isEmpty,
        );
      },
    );

    test(
      'clear-then-write can destroy the old snapshot before failing',
      () async {
        final storage = FaultInjectingStorageService(
          skills: <Skill>[skill('old-a'), skill('old-b')],
        )..failAfterItems[StorageOperation.saveSkills] = 1;

        await expectLater(
          storage.saveSkills(<Skill>[
            skill('new-a'),
            skill('new-b'),
            skill('new-c'),
          ]),
          throwsA(isA<InjectedStorageFailure>()),
        );

        expect(storage.persistedSkills.map((item) => item.id), <String>[
          'new-a',
        ]);
      },
    );

    test('one domain can commit while the next domain is partial', () async {
      final storage = FaultInjectingStorageService()
        ..failAfterItems[StorageOperation.saveTasks] = 1;
      final state = AppState(storage: storage);
      state.skills.add(skill('skill-a'));
      state.tasks
        ..add(task('task-a', 'skill-a'))
        ..add(task('task-b', 'skill-a'));
      addTearDown(() async {
        storage.clearFailures();
        state.dispose();
        await state.flushSaves();
      });

      await expectLater(
        state.flushSaves(),
        throwsA(isA<InjectedStorageFailure>()),
      );

      expect(
        storage.persistedSkills.map((item) => item.id),
        containsAll(<String>[kInboxSkillId, 'skill-a']),
      );
      expect(storage.persistedTasks.map((item) => item.id), <String>['task-a']);
      expect(storage.operations, contains(StorageOperation.saveSkills));
      expect(storage.operations, contains(StorageOperation.saveTasks));
      expect(storage.operations, isNot(contains(StorageOperation.saveProfile)));
    });

    test(
      'failed startup load cannot be overwritten by a later flush',
      () async {
        final storage = FaultInjectingStorageService(
          skills: <Skill>[skill('recoverable-skill')],
          tasks: <Task>[task('recoverable-task', 'recoverable-skill')],
        )..failBeforeOperation = StorageOperation.loadTasks;
        final state = AppState(storage: storage);
        addTearDown(() async {
          storage.clearFailures();
          state.dispose();
          await state.flushSaves();
        });

        await expectLater(
          state.loadSavedData(),
          throwsA(isA<InjectedStorageFailure>()),
        );
        storage.clearFailures();

        await state.flushSaves();

        expect(state.hasLoadedSavedData, isFalse);
        expect(storage.persistedSkills.map((item) => item.id), <String>[
          'recoverable-skill',
        ]);
        expect(storage.persistedTasks.map((item) => item.id), <String>[
          'recoverable-task',
        ]);
      },
    );

    test('failed startup load blocks writes until recovery succeeds', () async {
      final storage = FaultInjectingStorageService(
        skills: <Skill>[skill('recoverable-skill')],
      )..failBeforeOperation = StorageOperation.loadTasks;
      final state = AppState(storage: storage);
      addTearDown(state.dispose);

      await expectLater(
        state.loadSavedData(),
        throwsA(isA<InjectedStorageFailure>()),
      );
      storage.clearFailures();
      await state.flushSaves();

      expect(
        storage.operations.where(
          (operation) => operation.name.startsWith('save'),
        ),
        isEmpty,
      );
    });

    test('retry load recovers from a transient failure', () async {
      final storage = FaultInjectingStorageService()
        ..failBeforeOperation = StorageOperation.loadTasks;
      final state = AppState(storage: storage);
      addTearDown(state.dispose);

      expect(await state.retryLoadSavedData(), isFalse);
      storage.clearFailures();
      expect(await state.retryLoadSavedData(), isTrue);

      expect(state.persistenceStatus.phase, PersistencePhase.ready);
      expect(state.hasLoadedSavedData, isTrue);
    });

    test('save failure stays dirty and retry restores ready state', () async {
      final storage = FaultInjectingStorageService();
      final state = AppState(storage: storage);
      addTearDown(() async {
        storage.clearFailures();
        state.dispose();
      });
      await state.loadSavedData();
      storage.failBeforeOperation = StorageOperation.saveTasks;

      await expectLater(
        state.flushSaves(),
        throwsA(isA<InjectedStorageFailure>()),
      );

      expect(state.persistenceStatus.phase, PersistencePhase.saveFailed);
      expect(state.persistenceStatus.isDirty, isTrue);
      expect(state.persistenceStatus.canRetry, isTrue);

      storage.clearFailures();
      expect(await state.retrySave(), isTrue);
      expect(state.persistenceStatus.phase, PersistencePhase.ready);
      expect(state.persistenceStatus.isDirty, isFalse);
      expect(state.persistenceStatus.lastSuccessfulSaveAt, isNotNull);
    });

    test(
      'debounced save failure is observed without an uncaught error',
      () async {
        final errors = <Object>[];
        final storage = FaultInjectingStorageService();
        final state = AppState(storage: storage);
        addTearDown(() {
          storage.clearFailures();
          state.dispose();
        });
        await state.loadSavedData();
        storage.failBeforeOperation = StorageOperation.saveTheme;

        await runZonedGuarded(() async {
          state.toggleTheme();
          await Future<void>.delayed(const Duration(milliseconds: 900));
        }, (error, _) => errors.add(error));

        expect(errors, isEmpty);
        expect(state.persistenceStatus.phase, PersistencePhase.saveFailed);
        expect(state.persistenceStatus.isDirty, isTrue);
      },
    );

    testWidgets('startup recovery screen retries a failed load', (
      tester,
    ) async {
      final storage = FaultInjectingStorageService()
        ..failBeforeOperation = StorageOperation.loadTasks;

      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();

      expect(find.text('Не удалось загрузить данные'), findsOneWidget);
      expect(find.byKey(const Key('persistence-retry-load')), findsOneWidget);

      storage.clearFailures();
      await tester.tap(find.byKey(const Key('persistence-retry-load')));
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить данные'), findsNothing);
      expect(find.text('RPG To-Do List'), findsOneWidget);
    });

    testWidgets('startup recovery retries storage initialization', (
      tester,
    ) async {
      final storage = FaultInjectingStorageService()
        ..failBeforeOperation = StorageOperation.init;

      await tester.pumpWidget(RPGApp(storage: storage));
      await tester.pump();

      expect(find.text('Не удалось загрузить данные'), findsOneWidget);
      expect(storage.operations, <StorageOperation>[StorageOperation.init]);

      storage.clearFailures();
      await tester.tap(find.byKey(const Key('persistence-retry-load')));
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить данные'), findsNothing);
      expect(
        storage.operations.where((item) => item == StorageOperation.init),
        hasLength(2),
      );
    });

    testWidgets('save failure banner retries without losing dirty state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = FaultInjectingStorageService();
      final state = AppState(storage: storage);
      addTearDown(storage.clearFailures);
      await state.loadSavedData();
      storage.failBeforeOperation = StorageOperation.saveTasks;
      await expectLater(
        state.flushSaves(),
        throwsA(isA<InjectedStorageFailure>()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ListenableBuilder(
            listenable: state,
            builder: (context, _) => PersistenceGate(
              state: state,
              child: const Scaffold(body: SizedBox.expand()),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('persistence-save-failure')), findsOneWidget);
      expect(
        find.textContaining('пока не записаны на устройство'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(state.persistenceStatus.isDirty, isTrue);
      storage.clearFailures();
      await tester.tap(find.byKey(const Key('persistence-retry-save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('persistence-save-failure')), findsNothing);
      expect(state.persistenceStatus.isDirty, isFalse);
      state.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
