import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/persistence/save_scheduler.dart';

void main() {
  test('debounce collapses several requests into one write', () async {
    var writes = 0;
    final scheduler = SaveScheduler(
      debounce: const Duration(milliseconds: 10),
      writer: () async => writes++,
      isBlocked: () => false,
      onSaving: () {},
      onSaved: (_) {},
      onFailure: (_, _) {},
    );

    await scheduler.request();
    await scheduler.request();
    await scheduler.request();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(writes, 1);
    scheduler.dispose();
  });

  test(
    'request during an in-flight write schedules one trailing write',
    () async {
      final firstWrite = Completer<void>();
      final secondWrite = Completer<void>();
      var writes = 0;
      final scheduler = SaveScheduler(
        writer: () {
          writes++;
          return writes == 1 ? firstWrite.future : secondWrite.future;
        },
        isBlocked: () => false,
        onSaving: () {},
        onSaved: (_) {},
        onFailure: (_, _) {},
      );

      final flush = scheduler.request(immediate: true);
      await scheduler.request();
      await scheduler.request();
      expect(writes, 1);

      firstWrite.complete();
      await Future<void>.delayed(Duration.zero);
      expect(writes, 2);

      secondWrite.complete();
      await flush;
      expect(writes, 2);
      scheduler.dispose();
    },
  );

  test('failure is reported and remains observable to the caller', () async {
    Object? reportedError;
    final scheduler = SaveScheduler(
      writer: () => Future<void>.error(StateError('disk full')),
      isBlocked: () => false,
      onSaving: () {},
      onSaved: (_) => fail('failed write must not report success'),
      onFailure: (error, _) => reportedError = error,
    );

    await expectLater(
      scheduler.request(immediate: true),
      throwsA(isA<StateError>()),
    );
    expect(reportedError, isA<StateError>());
    scheduler.dispose();
  });

  test('blocked scheduler never starts a write', () async {
    var writes = 0;
    final scheduler = SaveScheduler(
      writer: () async => writes++,
      isBlocked: () => true,
      onSaving: () {},
      onSaved: (_) {},
      onFailure: (_, _) {},
    );

    await scheduler.request(immediate: true);
    await scheduler.flush();

    expect(writes, 0);
    scheduler.dispose();
  });
}
