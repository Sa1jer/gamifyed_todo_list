import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Папка внутри каталога приложения, где лежат боксы Hive.
const storageDirectoryName = 'storage';

/// Определяет каталог хранилища и один раз переносит в него старые данные.
///
/// Раньше боксы писались прямо в `getApplicationDocumentsDirectory()`. На
/// Windows и Linux это настоящая пользовательская папка «Документы»: тринадцать
/// файлов `.hive` оказывались вперемешку с документами человека. Теперь они
/// живут в каталоге приложения, одной отдельной папкой.
///
/// Перенос односторонний и неразрушающий: старые файлы остаются на месте.
/// Пока несколько релизов не подтвердят, что новое место работает, они —
/// запасной путь, а не мусор. Их удаление отдельной задачей в TODO.
///
/// Чего этот перенос не умеет: достать данные сборки с **другим**
/// идентификатором приложения. На macOS, iOS и Android каталог адресуется
/// идентификатором и закрыт песочницей, так что читать чужой контейнер
/// приложение не вправе — там работает только экспорт и импорт профиля. На
/// Windows и Linux «Документы» общие, поэтому данные старой сборки лежат ровно
/// там, куда смотрит `legacy`, и подхватятся сами.
Future<Directory> resolveStorageDirectory({
  required Directory support,
  Directory? legacy,
}) async {
  final target = Directory(
    '${support.path}${Platform.pathSeparator}$storageDirectoryName',
  );
  await target.create(recursive: true);

  if (legacy == null || !legacy.existsSync()) return target;
  if (legacy.resolveSymbolicLinksSync() == target.resolveSymbolicLinksSync()) {
    return target;
  }
  if (_boxFiles(target).isNotEmpty) return target;

  for (final box in _boxFiles(legacy)) {
    final name = box.uri.pathSegments.last;
    box.copySync('${target.path}${Platform.pathSeparator}$name');
  }
  return target;
}

/// Каталог хранилища для настоящего приложения.
Future<Directory> defaultStorageDirectory() async {
  final support = await getApplicationSupportDirectory();
  Directory? legacy;
  try {
    legacy = await getApplicationDocumentsDirectory();
  } on Object {
    // Платформа может не давать пользовательских «Документов». Тогда и
    // переносить нечего — это не ошибка запуска.
    legacy = null;
  }
  return resolveStorageDirectory(support: support, legacy: legacy);
}

/// Только файлы боксов: `.lock` — это состояние работающего процесса, копировать
/// его в новое место значит принести туда чужую блокировку.
List<File> _boxFiles(Directory directory) => directory
    .listSync()
    .whereType<File>()
    .where((file) => file.path.endsWith('.hive'))
    .toList(growable: false);
