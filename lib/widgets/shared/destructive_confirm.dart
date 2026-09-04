import 'package:flutter/material.dart';

import '../../utils.dart';

/// One confirmation for actions that destroy content the user cannot rebuild.
///
/// The confirming action carries an icon as well as danger colour: colour on
/// its own is not a signal for a red-green colour blind reader, and it is the
/// first thing a high-contrast or forced-colours mode flattens.
///
/// Reserve this for losses that undo cannot cover — a skill and its quests, a
/// RoadMap stage. A single quest is cheap to restore, so it gets an undo
/// instead of a question.
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required bool isDark,
  required String title,
  required String message,
  required String confirmLabel,
  Key? confirmKey,
  IconData confirmIcon = Icons.delete_outline_rounded,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: surface(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: TextStyle(color: textColor(isDark))),
      content: Text(
        message,
        style: TextStyle(color: subtext(isDark), height: 1.35),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          key: confirmKey,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD83651),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: Icon(confirmIcon, size: 18),
          label: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
