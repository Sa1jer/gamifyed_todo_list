import 'dart:async';

import 'package:flutter/material.dart';

import '../../utils.dart';
import 'motion_controls.dart';

class DlgHeader extends StatelessWidget {
  final String title;
  final Color txtColor;

  const DlgHeader({super.key, required this.title, required this.txtColor});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: txtColor,
          fontSize: 18,
        ),
      ),
      const Spacer(),
      PressFeedback(
        scale: 0.82,
        tooltip: 'Закрыть',
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.close, color: Color(0xFF8E8E93), size: 22),
      ),
    ],
  );
}

class DlgField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController ctrl;
  final Color fBg;
  final Color txt;
  final Color sub;
  final Color bdr;
  final int min;
  final int? max;
  final bool showLabel;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;

  const DlgField({
    super.key,
    required this.label,
    required this.ctrl,
    required this.fBg,
    required this.txt,
    required this.sub,
    required this.bdr,
    this.min = 1,
    this.max,
    this.hintText,
    this.showLabel = true,
    this.fieldKey,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (showLabel) ...[SubLbl(label, sub), const SizedBox(height: 6)],
      Container(
        decoration: BoxDecoration(
          color: fBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bdr),
        ),
        child: TextField(
          key: fieldKey,
          controller: ctrl,
          onChanged: onChanged,
          style: TextStyle(color: txt, fontSize: 14),
          minLines: min,
          maxLines: max ?? (min == 1 ? 1 : 4),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: TextStyle(color: sub, fontSize: 13, height: 1.25),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ),
    ],
  );
}

class MobileFormPage extends StatelessWidget {
  final Key pageKey;
  final Key saveKey;
  final String title;
  final Color backgroundColor;
  final Color accentColor;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final Widget child;
  final Widget? bottomAction;
  final bool showTopSaveAction;
  final String saveLabel;
  final TextStyle? titleStyle;

  const MobileFormPage({
    super.key,
    required this.pageKey,
    required this.saveKey,
    required this.title,
    required this.backgroundColor,
    required this.accentColor,
    required this.onSave,
    this.onCancel,
    required this.child,
    this.bottomAction,
    this.showTopSaveAction = true,
    this.saveLabel = 'Создать',
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: pageKey,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const ValueKey('mobile-form-cancel'),
          tooltip: 'Отмена',
          onPressed: onCancel ?? () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          title,
          key: const ValueKey('mobile-form-title'),
          style: titleStyle,
        ),
        actions: showTopSaveAction
            ? [
                TextButton(
                  key: saveKey,
                  onPressed: onSave,
                  style: TextButton.styleFrom(foregroundColor: accentColor),
                  child: Text(
                    saveLabel,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 4),
              ]
            : const [
                SizedBox(
                  key: ValueKey('mobile-form-top-save-hidden'),
                  width: 8,
                ),
              ],
      ),
      body: SafeArea(
        top: false,
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: child,
        ),
      ),
      bottomNavigationBar: bottomAction == null
          ? null
          : SafeArea(top: false, child: bottomAction!),
    );
  }
}

Future<bool> showDiscardMobileFormDialog(
  BuildContext context, {
  required bool isDark,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: surface(isDark),
      title: Text(
        'Отменить изменения?',
        style: TextStyle(color: textColor(isDark)),
      ),
      content: Text(
        'Введённые данные не сохранятся. Можно продолжить редактирование или удалить черновик.',
        style: TextStyle(color: subtext(isDark), height: 1.35),
      ),
      actions: [
        TextButton(
          key: const ValueKey('mobile-form-keep-editing'),
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Продолжить редактирование'),
        ),
        TextButton(
          key: const ValueKey('mobile-form-discard'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF453A)),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Удалить черновик'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class DlgActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;
  final Color saveColor;

  const DlgActions({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = 'Сохранить',
    this.saveColor = const Color(0xFF4A9EFF),
  });

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 10,
    runSpacing: 8,
    children: [
      PressFeedback(
        onTap: onCancel,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(45),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Отмена',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      PressFeedback(
        onTap: onSave,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: saveColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            saveLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    ],
  );
}

Future<int?> showIntegerEditDialog(
  BuildContext context, {
  required String title,
  required int initialValue,
  required int min,
  required int max,
  required Color color,
  required bool isDark,
  String suffix = '',
}) async {
  final controller = TextEditingController(text: '$initialValue');
  String? errorText;
  try {
    return await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        final txt = textColor(isDark);
        final sub = subtext(isDark);
        final bdr = borderColor(isDark);
        final bg = surface(isDark);
        final fBg = isDark ? const Color(0xFF181820) : const Color(0xFFFFFFFF);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void save() {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null) {
                setDialogState(() => errorText = 'Введите число');
                return;
              }
              Navigator.pop(dialogContext, parsed.clamp(min, max).toInt());
            }

            return Dialog(
              backgroundColor: bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: SizedBox(
                width: 360,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DlgHeader(title: title, txtColor: txt),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: txt,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                        decoration: InputDecoration(
                          suffixText: suffix,
                          suffixStyle: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                          ),
                          errorText: errorText,
                          helperText: 'Диапазон: $min-$max',
                          helperStyle: TextStyle(color: sub, fontSize: 11),
                          filled: true,
                          fillColor: fBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: bdr),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: color, width: 1.4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => save(),
                      ),
                      const SizedBox(height: 16),
                      DlgActions(
                        onCancel: () => Navigator.pop(dialogContext),
                        onSave: save,
                        saveColor: color,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    unawaited(Future<void>.delayed(kMotionSlow, controller.dispose));
  }
}

class SubLbl extends StatelessWidget {
  final String text;
  final Color color;

  const SubLbl(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
  );
}
