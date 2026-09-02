import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Перенос всех данных пользователя между устройствами через файл.
///
/// Формат — JSON того же снапшота, которым приложение хранит состояние
/// локально. Это не отдельная схема: файл проходит через тот же кодек и ту же
/// проверку версии, что и содержимое Hive, поэтому экспорт не может разойтись
/// с тем, что приложение действительно умеет читать. Табличные форматы
/// отпадают сами — навыки, дорожные карты и подзадачи вложенные.
abstract final class UserDataTransfer {
  static const fileExtension = 'json';

  static String suggestedFileName(DateTime now) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'rpg-todo-${now.year}-${two(now.month)}-${two(now.day)}'
        '.$fileExtension';
  }

  /// Плагин выбора файлов ведёт себя по-разному на разных платформах:
  ///
  /// * Android и iOS **требуют** `bytes` и записывают файл сами;
  /// * macOS на переданных `bytes` бросает `UnsupportedError`;
  /// * Windows и Linux их игнорируют и только возвращают выбранный путь.
  ///
  /// Поэтому байты уходят в плагин лишь там, где он их ждёт, а на десктопе
  /// файл пишется здесь.
  static bool get _pluginWritesFile => Platform.isAndroid || Platform.isIOS;

  static String _withExtension(String path) =>
      path.toLowerCase().endsWith('.$fileExtension')
      ? path
      : '$path.$fileExtension';

  /// Просит пользователя выбрать место и записывает туда [json].
  ///
  /// Возвращает путь к файлу либо `null`, если диалог отменили.
  static Future<String?> exportToFile({
    required String json,
    required String fileName,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(json));
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Куда сохранить данные',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const [fileExtension],
      bytes: _pluginWritesFile ? bytes : null,
    );
    if (path == null) return null;
    if (_pluginWritesFile) return path;
    final target = _withExtension(path);
    await File(target).writeAsBytes(bytes, flush: true);
    return target;
  }

  /// Просит выбрать файл и возвращает его содержимое, либо `null` при отмене.
  static Future<String?> pickImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Выберите файл с данными',
      // Без фильтра по типу. MIME на Android и UTI на iOS для `.json`
      // выводятся из расширения по-разному, и файл, принесённый с другой
      // системы, может просто не показаться в списке. Подходит ли он —
      // решает разбор, а не диалог.
      type: FileType.any,
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null) return null;
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) return null;
    final text = utf8.decode(bytes, allowMalformed: false);
    // Редакторы на Windows любят дописывать BOM в начало файла.
    return text.startsWith('\uFEFF') ? text.substring(1) : text;
  }
}
