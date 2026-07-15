import 'package:flutter/material.dart';

import '../../analytics/weekly_analytics_read_model.dart';
import '../../models.dart';
import '../../utils.dart';
import '../shared.dart';
import 'weekly_section.dart';

Future<WeeklyGoalDraft?> showWeeklyGoalEditor({
  required BuildContext context,
  required bool isDark,
  required DateTime weekStart,
  required WeeklyGoalData? goal,
}) {
  return showDialog<WeeklyGoalDraft>(
    context: context,
    builder: (_) => _WeeklyGoalEditorDialog(
      isDark: isDark,
      weekStart: weekStart,
      goal: goal,
    ),
  );
}

class WeeklyGoalCard extends StatelessWidget {
  final WeeklyAnalyticsViewData summary;
  final bool isDark;
  final VoidCallback onEdit;
  final ValueChanged<String> onToggleKeyResult;

  const WeeklyGoalCard({
    super.key,
    required this.summary,
    required this.isDark,
    required this.onEdit,
    required this.onToggleKeyResult,
  });

  @override
  Widget build(BuildContext context) {
    final goal = summary.weeklyGoal;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    const color = Color(0xFF34C759);

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.flag,
      color: color,
      title: 'Цель недели',
      subtitle: 'Фокус недели остаётся ниже истории роста.',
      trailing: PressFeedback(
        scale: 0.94,
        tooltip: goal == null ? 'Задать цель недели' : 'Редактировать цель',
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color.withAlpha(22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withAlpha(64)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                goal == null ? Icons.add : Icons.edit,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                goal == null ? 'Задать' : 'Изменить',
                style: const TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
      child: goal == null
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withAlpha(12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withAlpha(38)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.track_changes, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Цель недели ещё не задана',
                          style: TextStyle(
                            color: txt,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Сформулируй один главный результат и 2–3 измеримых шага.',
                          style: TextStyle(color: sub, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: TextStyle(
                          color: txt,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${(goal.progress * 100).round()}%',
                        style: const TextStyle(
                          color: color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                XPBar(progress: goal.progress, color: color, height: 6),
                const SizedBox(height: 10),
                if (goal.keyResults.isEmpty)
                  Text(
                    'Key results не заданы. Добавь 2–3 результата, чтобы цель стала измеримой.',
                    style: TextStyle(color: sub, fontSize: 12),
                  )
                else
                  ...goal.keyResults.asMap().entries.map((entry) {
                    final index = entry.key;
                    final result = entry.value;
                    return MotionListItem(
                      key: ValueKey('weekly-kr-${result.id}-${result.isDone}'),
                      index: index,
                      slide: 4,
                      child: _WeeklyKeyResultRow(
                        result: result,
                        isDark: isDark,
                        onTap: () => onToggleKeyResult(result.id),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _WeeklyKeyResultRow extends StatelessWidget {
  final WeeklyKeyResultData result;
  final bool isDark;
  final VoidCallback onTap;

  const _WeeklyKeyResultRow({
    required this.result,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    const color = Color(0xFF34C759);

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: PressFeedback(
        scale: 0.98,
        tooltip: result.isDone ? 'Вернуть key result' : 'Отметить key result',
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: result.isDone ? color.withAlpha(16) : sub.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: result.isDone ? color.withAlpha(70) : borderColor(isDark),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: kMotionStandard,
                curve: kMotionCurve,
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: result.isDone ? color : Colors.transparent,
                  border: Border.all(
                    color: result.isDone ? color : sub.withAlpha(150),
                    width: 1.6,
                  ),
                ),
                child: result.isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.title,
                  style: TextStyle(
                    color: result.isDone ? sub : txt,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    decoration: result.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: sub,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeeklyGoalDraft {
  final String title;
  final List<WeeklyKeyResult> keyResults;

  const WeeklyGoalDraft({required this.title, required this.keyResults});
}

class _WeeklyGoalEditorDialog extends StatefulWidget {
  final bool isDark;
  final DateTime weekStart;
  final WeeklyGoalData? goal;

  const _WeeklyGoalEditorDialog({
    required this.isDark,
    required this.weekStart,
    required this.goal,
  });

  @override
  State<_WeeklyGoalEditorDialog> createState() =>
      _WeeklyGoalEditorDialogState();
}

class _WeeklyGoalEditorDialogState extends State<_WeeklyGoalEditorDialog> {
  late final TextEditingController _titleCtrl;
  late final List<_KeyResultEditorItem> _items;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.goal?.title ?? '');
    _items = [
      ...?widget.goal?.keyResults.map(
        (result) => _KeyResultEditorItem(
          id: result.id,
          controller: TextEditingController(text: result.title),
          isDone: result.isDone,
          completedAt: result.completedAt,
        ),
      ),
    ];
    while (_items.length < 3) {
      _items.add(_KeyResultEditorItem.empty());
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final item in _items) {
      item.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    const color = Color(0xFF34C759);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 90 : 25),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: color, size: 22),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Цель недели',
                    style: TextStyle(
                      color: txt,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                PressFeedback(
                  scale: 0.94,
                  tooltip: 'Закрыть без сохранения',
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: sub, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDayMonth(widget.weekStart)} — ${_formatDayMonth(widget.weekStart.add(const Duration(days: 6)))}',
              style: TextStyle(color: sub, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: txt),
              decoration: _fieldDecoration(
                isDark,
                label: 'Главная цель недели',
                hint: 'Например: закрыть MVP недельной аналитики',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Key results',
              style: TextStyle(
                color: txt,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${index + 1}.',
                        style: TextStyle(
                          color: sub,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: item.controller,
                        style: TextStyle(color: txt),
                        decoration: _fieldDecoration(
                          isDark,
                          label: 'Измеримый результат',
                          hint: 'Например: 3 закрытых квеста по Python',
                        ),
                      ),
                    ),
                    if (_items.length > 3) ...[
                      const SizedBox(width: 8),
                      PressFeedback(
                        scale: 0.94,
                        tooltip: 'Удалить key result',
                        onTap: () => setState(() {
                          final removed = _items.removeAt(index);
                          removed.controller.dispose();
                        }),
                        child: Icon(
                          Icons.close,
                          color: sub.withAlpha(180),
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            PressFeedback(
              scale: 0.98,
              tooltip: 'Добавить ещё один ключевой результат',
              onTap: _items.length >= 5
                  ? () {}
                  : () => setState(
                      () => _items.add(_KeyResultEditorItem.empty()),
                    ),
              child: Text(
                _items.length >= 5
                    ? 'Максимум 5 результатов'
                    : '+ Добавить результат',
                style: TextStyle(
                  color: _items.length >= 5 ? sub : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Совет: цель отвечает “зачем”, результаты — “как пойму, что неделя удалась”.',
                    style: TextStyle(color: sub, fontSize: 11.5, height: 1.3),
                  ),
                ),
                const SizedBox(width: 12),
                SmallBtn(
                  label: 'Сохранить',
                  icon: Icons.check,
                  color: color,
                  onTap: _save,
                  tooltip: 'Сохранить цель недели',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    bool isDark, {
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: subtext(isDark).withAlpha(150)),
      labelStyle: TextStyle(color: subtext(isDark)),
      filled: true,
      fillColor: isDark ? const Color(0xFF121219) : const Color(0xFFF7F8FC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor(isDark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF34C759), width: 1.4),
      ),
    );
  }

  void _save() {
    final keyResults = _items
        .map(
          (item) => WeeklyKeyResult(
            id: item.id,
            title: item.controller.text,
            isDone: item.isDone,
            completedAt: item.completedAt,
          ),
        )
        .toList();

    Navigator.pop(
      context,
      WeeklyGoalDraft(title: _titleCtrl.text, keyResults: keyResults),
    );
  }
}

class _KeyResultEditorItem {
  final String id;
  final TextEditingController controller;
  final bool isDone;
  final DateTime? completedAt;

  _KeyResultEditorItem({
    required this.id,
    required this.controller,
    required this.isDone,
    required this.completedAt,
  });

  factory _KeyResultEditorItem.empty() {
    return _KeyResultEditorItem(
      id: '',
      controller: TextEditingController(),
      isDone: false,
      completedAt: null,
    );
  }
}

String _formatDayMonth(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
}
