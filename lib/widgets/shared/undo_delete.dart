import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';

/// Удаляет квест и даёт его вернуть.
///
/// Потеря одного квеста дешёвая и обратимая, поэтому вопроса перед удалением
/// нет: диалог на каждый квест — это налог на частое безобидное действие.
/// Вместо него отмена, которая стоит одного нажатия и не требует внимания,
/// если она не нужна. Для потерь, которые вернуть нечем — навык со всеми
/// квестами, этап карты, — есть `confirmDestructiveAction`.
void deleteTaskWithUndo(
  BuildContext context,
  AppState state,
  String taskId, {
  VoidCallback? onUndo,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final removed = state.removeTaskForUndo(taskId);
  if (removed == null) return;

  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const ValueKey('undo-delete-task'),
        content: Text('Квест «${_shortTitle(removed.task)}» удалён'),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            state.restoreTask(removed);
            onUndo?.call();
          },
        ),
      ),
    );
}

/// Длинное название превращает подсказку в стену текста, а SnackBar — в
/// перекрытие половины экрана.
String _shortTitle(Task task) {
  final title = task.title.trim();
  if (title.length <= 32) return title;
  return '${title.substring(0, 31).trimRight()}…';
}
