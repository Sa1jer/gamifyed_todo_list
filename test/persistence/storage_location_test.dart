import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/persistence/storage_location.dart';

void main() {
  late Directory root;
  late Directory support;
  late Directory legacy;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('todo-location-');
    support = await Directory('${root.path}/support').create(recursive: true);
    legacy = await Directory('${root.path}/documents').create(recursive: true);
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  File box(Directory directory, String name, String content) =>
      File('${directory.path}/$name.hive')..writeAsStringSync(content);

  List<String> boxNames(Directory directory) =>
      directory
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.endsWith('.hive'))
          .toList()
        ..sort();

  test(
    'storage moves out of the documents folder into its own directory',
    () async {
      box(legacy, 'skills', 'навыки');
      box(legacy, 'tasks', 'квесты');

      final target = await resolveStorageDirectory(
        support: support,
        legacy: legacy,
      );

      expect(
        target.path,
        '${support.path}${Platform.pathSeparator}$storageDirectoryName',
      );
      expect(boxNames(target), ['skills.hive', 'tasks.hive']);
      expect(File('${target.path}/skills.hive').readAsStringSync(), 'навыки');
    },
  );

  test('the old files stay put, so the move has a way back', () async {
    box(legacy, 'skills', 'навыки');

    await resolveStorageDirectory(support: support, legacy: legacy);

    expect(boxNames(legacy), ['skills.hive']);
    expect(File('${legacy.path}/skills.hive').readAsStringSync(), 'навыки');
  });

  test('a second run does not overwrite data written since the move', () async {
    box(legacy, 'skills', 'старое');
    final target = await resolveStorageDirectory(
      support: support,
      legacy: legacy,
    );
    File('${target.path}/skills.hive').writeAsStringSync('новое');

    await resolveStorageDirectory(support: support, legacy: legacy);

    // Перенос обязан быть однократным: иначе каждый запуск откатывал бы
    // работу пользователя к состоянию на момент обновления.
    expect(File('${target.path}/skills.hive').readAsStringSync(), 'новое');
  });

  test('lock files are left behind rather than carried over', () async {
    box(legacy, 'skills', 'навыки');
    File('${legacy.path}/skills.lock').writeAsStringSync('');

    final target = await resolveStorageDirectory(
      support: support,
      legacy: legacy,
    );

    // `.lock` описывает работающий процесс, а не данные. Перенесённая
    // блокировка означала бы чужой замок в новом каталоге.
    expect(File('${target.path}/skills.lock').existsSync(), isFalse);
    expect(boxNames(target), ['skills.hive']);
  });

  test(
    'a first install with nothing to migrate still gets its directory',
    () async {
      final target = await resolveStorageDirectory(
        support: support,
        legacy: legacy,
      );

      expect(target.existsSync(), isTrue);
      expect(boxNames(target), isEmpty);
    },
  );

  test('a missing legacy folder is not a startup failure', () async {
    await legacy.delete();

    final target = await resolveStorageDirectory(
      support: support,
      legacy: legacy,
    );

    expect(target.existsSync(), isTrue);
  });

  test('no legacy folder at all is not a startup failure', () async {
    final target = await resolveStorageDirectory(support: support);

    expect(target.existsSync(), isTrue);
  });

  test(
    'a legacy folder that is the target itself copies nothing onto itself',
    () async {
      final target = await resolveStorageDirectory(
        support: support,
        legacy: legacy,
      );
      box(target, 'skills', 'навыки');

      // Платформа вправе вернуть один и тот же каталог обоими путями.
      final again = await resolveStorageDirectory(
        support: support,
        legacy: target,
      );

      expect(again.path, target.path);
      expect(File('${target.path}/skills.hive').readAsStringSync(), 'навыки');
    },
  );
}
