import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../storage_snapshot.dart';
import '../../user_data_transfer.dart';
import '../../utils.dart';

/// Кнопки экспорта и импорта всех данных пользователя.
///
/// Живут в двух местах — в профиле и в настройках, — потому что переносом
/// пользуются в двух разных ситуациях: «переезжаю на другое устройство» это
/// профиль, «что-то с хранилищем» это настройки. Дублируется точка входа, но
/// не логика: файловые диалоги, подтверждение замены и разбор ошибок здесь
/// одни на всех.
class UserDataTransferControls extends StatefulWidget {
  final AppState state;

  /// Закрывать ли экран после успешного импорта.
  ///
  /// В профиле это уместно: данные под ним уже другие. В настройках закрывать
  /// нечего — раздел остаётся на месте.
  final bool popOnImport;

  const UserDataTransferControls({
    super.key,
    required this.state,
    this.popOnImport = false,
  });

  @override
  State<UserDataTransferControls> createState() =>
      _UserDataTransferControlsState();
}

class _UserDataTransferControlsState extends State<UserDataTransferControls> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDark = state.isDark;
    final text = textColor(isDark);
    final border = borderColor(isDark);

    if (!state.supportsDataTransfer) {
      return Text(
        'Перенос недоступен: хранилище этого устройства работает в устаревшем '
        'режиме без единого документа состояния.',
        style: TextStyle(color: subtext(isDark), fontSize: 12, height: 1.35),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey('profile-export-data'),
            onPressed: _busy ? null : () => _export(context, state),
            style: OutlinedButton.styleFrom(
              foregroundColor: text,
              side: BorderSide(color: border),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('Экспорт'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey('profile-import-data'),
            onPressed: _busy ? null : () => _import(context, state),
            style: OutlinedButton.styleFrom(
              foregroundColor: text,
              side: BorderSide(color: border),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Импорт'),
          ),
        ),
      ],
    );
  }

  void _notify(
    ScaffoldMessengerState messenger,
    bool isDark,
    String message, {
    bool error = false,
  }) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFD83651) : surface(isDark),
        showCloseIcon: true,
      ),
    );
  }

  Future<void> _export(BuildContext context, AppState state) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final isDark = state.isDark;
    setState(() => _busy = true);
    try {
      // Незаписанные изменения не должны потеряться в экспорте.
      await state.flushSaves();
      final path = await UserDataTransfer.exportToFile(
        json: state.exportUserData(),
        fileName: UserDataTransfer.suggestedFileName(DateTime.now()),
      );
      if (path == null) return;
      _notify(messenger, isDark, 'Данные сохранены в $path');
    } catch (error) {
      _notify(
        messenger,
        isDark,
        'Не удалось сохранить файл: $error',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(BuildContext context, AppState state) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final isDark = state.isDark;
    final confirmed = await _confirmImport(context, isDark);
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final raw = await UserDataTransfer.pickImportFile();
      if (raw == null) return;
      final loaded = await state.importUserData(raw);
      if (!loaded) {
        _notify(
          messenger,
          isDark,
          'Файл прочитан, но данные не загрузились',
          error: true,
        );
        return;
      }
      _notify(messenger, state.isDark, 'Данные восстановлены из файла');
      if (widget.popOnImport) await navigator.maybePop();
    } on UserDataImportException catch (error) {
      _notify(messenger, isDark, switch (error.reason) {
        UserDataImportFailure.versionMismatch =>
          'Файл сделан другой версией приложения. Обновите RPG To-Do на '
              'обоих устройствах и экспортируйте заново.',
        UserDataImportFailure.unreadable =>
          'Это не файл с данными RPG To-Do или он повреждён',
      }, error: true);
    } catch (error) {
      _notify(
        messenger,
        isDark,
        'Не удалось прочитать файл: $error',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmImport(BuildContext context, bool isDark) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Заменить все данные?',
          style: TextStyle(color: textColor(isDark)),
        ),
        content: Text(
          'Навыки, квесты, история и прогресс на этом устройстве будут '
          'заменены содержимым файла. Отменить это будет нечем — сначала '
          'сохраните текущие данные экспортом.',
          style: TextStyle(color: subtext(isDark), height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            key: const ValueKey('profile-import-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD83651),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Заменить'),
          ),
        ],
      ),
    );
  }
}
