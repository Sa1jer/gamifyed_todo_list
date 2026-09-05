import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../update_check.dart';
import '../../utils.dart';

/// Строка «есть новая сборка» в профиле.
///
/// Только уведомление: скачивание и установка APK изнутри требуют разрешения
/// `REQUEST_INSTALL_PACKAGES`, а оно чувствительное и закрывает дорогу в
/// магазин. Ссылка копируется в буфер — открыть браузер приложение сейчас не
/// умеет, для этого нужна отдельная зависимость.
///
/// Пока обновления нет — и пока проверка не ответила — виджет ничего не
/// занимает: молчание здесь норма, а не пустая рамка.
class UpdateNotice extends StatefulWidget {
  final UpdateChecker checker;
  final bool isDark;

  const UpdateNotice({super.key, required this.checker, required this.isDark});

  @override
  State<UpdateNotice> createState() => _UpdateNoticeState();
}

class _UpdateNoticeState extends State<UpdateNotice> {
  @override
  void initState() {
    super.initState();
    if (!widget.checker.hasChecked) {
      widget.checker.check().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = widget.checker.available;
    if (update == null) return const SizedBox.shrink();

    final isDark = widget.isDark;
    final text = textColor(isDark);
    final secondary = subtext(isDark);

    return Container(
      key: const ValueKey('profile-update-notice'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dialogFieldSurface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.system_update_alt_rounded, color: secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Доступна сборка ${update.versionName}',
                  style: TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'У вас $kAppVersionLabel. Обновление встанет поверх, '
                  'данные сохранятся.',
                  style: TextStyle(color: secondary, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: const ValueKey('profile-update-copy-link'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: update.url));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Ссылка на сборку скопирована'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: surface(isDark),
                ),
              );
            },
            child: const Text('Скопировать ссылку'),
          ),
        ],
      ),
    );
  }
}
