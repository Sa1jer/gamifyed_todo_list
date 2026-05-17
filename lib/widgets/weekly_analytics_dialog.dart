import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'shared.dart';

class WeeklyAnalyticsDialog extends StatefulWidget {
  final AppState state;

  const WeeklyAnalyticsDialog({super.key, required this.state});

  @override
  State<WeeklyAnalyticsDialog> createState() => _WeeklyAnalyticsDialogState();
}

class _WeeklyAnalyticsDialogState extends State<WeeklyAnalyticsDialog> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _startOfWeek(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDark = state.isDark;
    final bdr = borderColor(isDark);
    final bg = surface(isDark);
    final summary = _WeeklySummary.fromState(state, _weekStart);
    final canGoNext = _weekStart.isBefore(_startOfWeek(DateTime.now()));
    final size = MediaQuery.sizeOf(context);
    final availableWidth = size.width - 36;
    final availableHeight = size.height - 40;
    final dialogWidth = availableWidth < 360
        ? availableWidth
        : availableWidth.clamp(360.0, 900.0).toDouble();
    final maxHeight = availableHeight < 520
        ? availableHeight
        : availableHeight.clamp(520.0, 720.0).toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: bdr),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 90 : 30),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            _WeeklyHeader(
              isDark: isDark,
              weekStart: _weekStart,
              canGoNext: canGoNext,
              onPrevious: () => setState(
                () => _weekStart = _weekStart.subtract(const Duration(days: 7)),
              ),
              onNext: canGoNext
                  ? () => setState(
                      () =>
                          _weekStart = _weekStart.add(const Duration(days: 7)),
                    )
                  : null,
              onClose: () => Navigator.pop(context),
            ),
            Container(height: 1, color: bdr),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    MotionFadeSlideSwitcher(
                      child: _WeeklyOverview(
                        key: ValueKey(
                          'week-overview-${_weekStart.toIso8601String()}',
                        ),
                        summary: summary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    MotionFadeSlideSwitcher(
                      child: _WeeklyGoalCard(
                        key: ValueKey(
                          'week-goal-${summary.weeklyGoal?.id ?? 'empty'}-${summary.weeklyGoal?.updatedAt.millisecondsSinceEpoch ?? 0}',
                        ),
                        summary: summary,
                        isDark: isDark,
                        onEdit: () => _openGoalEditor(summary),
                        onToggleKeyResult: (keyResultId) {
                          final goal = summary.weeklyGoal;
                          if (goal == null) return;
                          widget.state.toggleWeeklyKeyResult(
                            goal.id,
                            keyResultId,
                          );
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    MotionFadeSlideSwitcher(
                      child: _ProcrastinationInsightsCard(
                        key: ValueKey(
                          'week-procrastination-${summary.procrastination.signature}',
                        ),
                        summary: summary,
                        isDark: isDark,
                        onStartMinimum: (taskId) {
                          final message = widget.state.completeMinimumAction(
                            taskId,
                          );
                          if (message != null) {
                            ScaffoldMessenger.maybeOf(
                              context,
                            )?.showSnackBar(SnackBar(content: Text(message)));
                          }
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 760;
                        final graph = _WeeklyXpChart(
                          summary: summary,
                          isDark: isDark,
                        );
                        final skills = _WeeklySkillBreakdown(
                          summary: summary,
                          isDark: isDark,
                        );

                        if (!wide) {
                          return Column(
                            children: [
                              graph,
                              const SizedBox(height: 14),
                              skills,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: graph),
                            const SizedBox(width: 14),
                            Expanded(flex: 5, child: skills),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 760;
                        final tasks = _WeeklyTaskList(
                          summary: summary,
                          isDark: isDark,
                        );
                        final risks = _WeeklyStreakRisks(
                          summary: summary,
                          isDark: isDark,
                        );

                        if (!wide) {
                          return Column(
                            children: [
                              tasks,
                              const SizedBox(height: 14),
                              risks,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: tasks),
                            const SizedBox(width: 14),
                            Expanded(flex: 5, child: risks),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoalEditor(_WeeklySummary summary) async {
    final draft = await showDialog<_WeeklyGoalDraft>(
      context: context,
      builder: (_) => _WeeklyGoalEditorDialog(
        isDark: widget.state.isDark,
        weekStart: summary.weekStart,
        goal: summary.weeklyGoal,
      ),
    );
    if (draft == null) return;

    widget.state.saveWeeklyGoal(
      weekStart: summary.weekStart,
      title: draft.title,
      keyResults: draft.keyResults,
    );
    if (mounted) setState(() {});
  }
}

class _WeeklyHeader extends StatelessWidget {
  final bool isDark;
  final DateTime weekStart;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onClose;

  const _WeeklyHeader({
    required this.isDark,
    required this.weekStart,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = const Color(0xFF34C759);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withAlpha(26),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.calendar_view_week,
              color: Color(0xFF34C759),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Неделя',
                  style: TextStyle(
                    color: txt,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDayMonth(weekStart)} — ${_formatDayMonth(weekStart.add(const Duration(days: 6)))}',
                  style: TextStyle(color: sub, fontSize: 12.5),
                ),
              ],
            ),
          ),
          _WeekNavButton(
            tooltip: 'Предыдущая неделя',
            icon: Icons.chevron_left,
            color: sub,
            onTap: onPrevious,
          ),
          const SizedBox(width: 6),
          _WeekNavButton(
            tooltip: canGoNext ? 'Следующая неделя' : 'Это текущая неделя',
            icon: Icons.chevron_right,
            color: sub,
            onTap: onNext,
          ),
          const SizedBox(width: 10),
          PressFeedback(
            scale: 0.94,
            tooltip: 'Закрыть недельную аналитику',
            onTap: onClose,
            child: Icon(Icons.close, color: sub, size: 22),
          ),
        ],
      ),
    );
  }
}

class _WeekNavButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _WeekNavButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withAlpha(onTap == null ? 10 : 18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color.withAlpha(onTap == null ? 90 : 230)),
    );

    if (onTap == null) {
      return Tooltip(message: tooltip, child: button);
    }

    return PressFeedback(
      scale: 0.94,
      tooltip: tooltip,
      onTap: onTap!,
      child: button,
    );
  }
}

class _WeeklyOverview extends StatelessWidget {
  final _WeeklySummary summary;
  final bool isDark;

  const _WeeklyOverview({
    super.key,
    required this.summary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 440
            ? 1
            : constraints.maxWidth < 760
            ? 2
            : 4;
        const spacing = 10.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _WeeklyMetricCard(
                isDark: isDark,
                title: 'XP недели',
                value: '${summary.totalXp}',
                subtitle: summary.totalXp == 0
                    ? 'Пока без XP'
                    : '${summary.averageXpPerActiveDay} XP в активный день',
                icon: Icons.bolt,
                color: const Color(0xFFFFCC00),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _WeeklyMetricCard(
                isDark: isDark,
                title: 'Квесты',
                value: '${summary.completedTasks}',
                subtitle: summary.completedTasks == 0
                    ? 'Ещё не закрывались'
                    : '${summary.activeDays} активн. дн.',
                icon: Icons.check_circle,
                color: const Color(0xFF34C759),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _WeeklyMetricCard(
                isDark: isDark,
                title: 'Навыки',
                value: '${summary.skillStats.length}',
                subtitle: summary.topSkillName == null
                    ? 'Нет вклада'
                    : 'Лидер: ${summary.topSkillName}',
                icon: Icons.auto_graph,
                color: const Color(0xFF4A9EFF),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _WeeklyMetricCard(
                isDark: isDark,
                title: 'Риски',
                value: '${summary.riskTasks.length}',
                subtitle: summary.riskTasks.isEmpty
                    ? 'Серии спокойны'
                    : 'Лучше закрыть первыми',
                icon: Icons.local_fire_department,
                color: const Color(0xFFFF9500),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WeeklyMetricCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _WeeklyMetricCard({
    required this.isDark,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121219) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sub,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: txt,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: sub, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  final _WeeklySummary summary;
  final bool isDark;
  final VoidCallback onEdit;
  final ValueChanged<String> onToggleKeyResult;

  const _WeeklyGoalCard({
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

    return _WeeklySection(
      isDark: isDark,
      icon: Icons.flag,
      color: color,
      title: 'Цель недели',
      subtitle: 'Одна цель и ключевые результаты, по которым видно фокус',
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
  final WeeklyKeyResult result;
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

class _WeeklyGoalDraft {
  final String title;
  final List<WeeklyKeyResult> keyResults;

  const _WeeklyGoalDraft({required this.title, required this.keyResults});
}

class _WeeklyGoalEditorDialog extends StatefulWidget {
  final bool isDark;
  final DateTime weekStart;
  final WeeklyGoal? goal;

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
      _WeeklyGoalDraft(title: _titleCtrl.text, keyResults: keyResults),
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

class _ProcrastinationInsightsCard extends StatelessWidget {
  final _WeeklySummary summary;
  final bool isDark;
  final ValueChanged<String> onStartMinimum;

  const _ProcrastinationInsightsCard({
    super.key,
    required this.summary,
    required this.isDark,
    required this.onStartMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final insights = summary.procrastination;
    final hasInsights =
        insights.stalled.isNotEmpty ||
        insights.oversized.isNotEmpty ||
        insights.minimumStarts.isNotEmpty;

    return _WeeklySection(
      isDark: isDark,
      icon: Icons.psychology_alt,
      color: const Color(0xFFFF9500),
      title: 'Procrastination Insights',
      subtitle: 'Где можно застрять и какой следующий шаг самый лёгкий',
      child: hasInsights
          ? LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final columns = [
                  _InsightColumn(
                    isDark: isDark,
                    title: 'Зависшие',
                    subtitle: 'Давно без движения',
                    icon: Icons.hourglass_bottom,
                    color: const Color(0xFFFF3B30),
                    items: insights.stalled,
                    emptyText: 'Нет зависших задач',
                  ),
                  _InsightColumn(
                    isDark: isDark,
                    title: 'Слишком крупные',
                    subtitle: 'Нужно разбить или добавить минимум',
                    icon: Icons.account_tree,
                    color: const Color(0xFFFF9500),
                    items: insights.oversized,
                    emptyText: 'Крупные задачи под контролем',
                  ),
                  _InsightColumn(
                    isDark: isDark,
                    title: 'Начни с минимума',
                    subtitle: 'Самый мягкий вход',
                    icon: Icons.play_circle,
                    color: const Color(0xFF34C759),
                    items: insights.minimumStarts,
                    emptyText: 'Нет доступных лёгких стартов',
                    onStartMinimum: onStartMinimum,
                  ),
                ];

                if (!wide) {
                  return Column(
                    children: columns
                        .map(
                          (column) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: column,
                          ),
                        )
                        .toList(),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: columns[0]),
                    const SizedBox(width: 10),
                    Expanded(child: columns[1]),
                    const SizedBox(width: 10),
                    Expanded(child: columns[2]),
                  ],
                );
              },
            )
          : _WeeklyEmptyState(
              icon: Icons.shield,
              title: 'Прокрастинационных рисков не видно',
              subtitle: 'Задачи выглядят достаточно понятными для старта.',
              isDark: isDark,
            ),
    );
  }
}

class _InsightColumn extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_TaskInsight> items;
  final String emptyText;
  final ValueChanged<String>? onStartMinimum;

  const _InsightColumn({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.items,
    required this.emptyText,
    this.onStartMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121219) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: txt,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: sub, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                color: sub.withAlpha(9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emptyText,
                textAlign: TextAlign.center,
                style: TextStyle(color: sub, fontSize: 11),
              ),
            )
          else
            ...items.take(3).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final insight = entry.value;
              return MotionListItem(
                key: ValueKey('$title-${insight.task.id}'),
                index: index,
                slide: 4,
                child: _InsightTaskTile(
                  insight: insight,
                  isDark: isDark,
                  color: color,
                  onStartMinimum: onStartMinimum,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _InsightTaskTile extends StatelessWidget {
  final _TaskInsight insight;
  final bool isDark;
  final Color color;
  final ValueChanged<String>? onStartMinimum;

  const _InsightTaskTile({
    required this.insight,
    required this.isDark,
    required this.color,
    required this.onStartMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final task = insight.task;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final skillColor = insight.skill?.color ?? color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: skillColor.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: skillColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                insight.skill?.icon ?? Icons.bolt,
                color: skillColor,
                size: 15,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: txt,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            insight.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: sub, fontSize: 10.5, height: 1.25),
          ),
          if (insight.minimumAction != null) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Минимум: ${insight.minimumAction}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF34C759),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onStartMinimum != null) ...[
                  const SizedBox(width: 8),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Сделать лёгкий старт',
                    onTap: () => onStartMinimum!(task.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withAlpha(24),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF34C759).withAlpha(70),
                        ),
                      ),
                      child: const Text(
                        'Старт',
                        style: TextStyle(
                          color: Color(0xFF34C759),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyXpChart extends StatelessWidget {
  final _WeeklySummary summary;
  final bool isDark;

  const _WeeklyXpChart({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final maxXp = summary.dayStats.fold<int>(
      0,
      (max, day) => day.xp > max ? day.xp : max,
    );

    return _WeeklySection(
      isDark: isDark,
      icon: Icons.bar_chart,
      color: const Color(0xFFFFCC00),
      title: 'XP по дням',
      subtitle: 'По фактическим выполнениям, отмены уже вычтены',
      child: Column(
        children: [
          if (summary.completedTasks == 0)
            _WeeklyEmptyState(
              icon: Icons.hourglass_empty,
              title: 'Неделя ещё пустая',
              subtitle: 'Закрой первый квест, и график начнёт жить.',
              isDark: isDark,
            )
          else
            ...summary.dayStats.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final ratio = maxXp == 0 ? 0.0 : day.xp / maxXp;
              return MotionListItem(
                key: ValueKey('week-day-${day.date.toIso8601String()}'),
                index: index,
                slide: 4,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 38,
                        child: Text(
                          _weekdayShort(day.date),
                          style: TextStyle(
                            color: sub,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = day.xp == 0
                                ? 4.0
                                : (constraints.maxWidth * ratio).clamp(
                                    16.0,
                                    constraints.maxWidth,
                                  );
                            return Stack(
                              children: [
                                Container(
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFCC00,
                                    ).withAlpha(22),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: kMotionProgress,
                                  curve: kMotionCurve,
                                  width: width,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: day.xp == 0
                                        ? sub.withAlpha(40)
                                        : const Color(0xFFFFCC00),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 9),
                      SizedBox(
                        width: 72,
                        child: Text(
                          '${day.xp} XP',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: day.xp == 0 ? sub : txt,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _WeeklySkillBreakdown extends StatelessWidget {
  final _WeeklySummary summary;
  final bool isDark;

  const _WeeklySkillBreakdown({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final stats = summary.skillStats;
    final maxXp = stats.fold<int>(
      0,
      (max, stat) => stat.xp > max ? stat.xp : max,
    );

    return _WeeklySection(
      isDark: isDark,
      icon: Icons.auto_graph,
      color: const Color(0xFF4A9EFF),
      title: 'Вклад навыков',
      subtitle: 'Какие направления двигали неделю',
      child: stats.isEmpty
          ? _WeeklyEmptyState(
              icon: Icons.bolt,
              title: 'Пока нет лидера',
              subtitle:
                  'Когда появятся квесты, здесь будет видно вклад навыков.',
              isDark: isDark,
            )
          : Column(
              children: stats.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                final progress = maxXp == 0 ? 0.0 : stat.xp / maxXp;
                return MotionListItem(
                  key: ValueKey('week-skill-${stat.skillId}'),
                  index: index,
                  slide: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: stat.color.withAlpha(24),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(stat.icon, color: stat.color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      stat.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textColor(isDark),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${stat.xp} XP',
                                    style: TextStyle(
                                      color: stat.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              XPBar(
                                progress: progress,
                                color: stat.color,
                                height: 5,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _questCount(stat.tasksCompleted),
                                style: TextStyle(color: sub, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _WeeklyTaskList extends StatelessWidget {
  final _WeeklySummary summary;
  final bool isDark;

  const _WeeklyTaskList({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final entries = summary.entries;
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return _WeeklySection(
      isDark: isDark,
      icon: Icons.task_alt,
      color: const Color(0xFF34C759),
      title: 'Квесты недели',
      subtitle: 'Последние фактические закрытия',
      child: entries.isEmpty
          ? _WeeklyEmptyState(
              icon: Icons.task_alt,
              title: 'Нет закрытых квестов',
              subtitle: 'Эта неделя пока ждёт первый выполненный шаг.',
              isDark: isDark,
            )
          : Column(
              children: entries.take(7).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return MotionListItem(
                  key: ValueKey(
                    'week-task-${item.id}-${item.at.millisecondsSinceEpoch}',
                  ),
                  index: index,
                  slide: 4,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF121219)
                          : const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: borderColor(isDark)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: item.skillColor.withAlpha(24),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            item.skillIcon,
                            color: item.skillColor,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.taskTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: txt,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.skillName} • ${formatShortDate(item.at)} ${formatTime(item.at)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: sub, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${item.xp}',
                          style: const TextStyle(
                            color: Color(0xFF34C759),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _WeeklyStreakRisks extends StatelessWidget {
  final _WeeklySummary summary;
  final bool isDark;

  const _WeeklyStreakRisks({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final risks = summary.riskTasks;
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return _WeeklySection(
      isDark: isDark,
      icon: Icons.local_fire_department,
      color: const Color(0xFFFF9500),
      title: 'Риск серии',
      subtitle: 'Повторяющиеся квесты, которые лучше не откладывать',
      child: risks.isEmpty
          ? _WeeklyEmptyState(
              icon: Icons.shield,
              title: 'Риски не горят',
              subtitle: 'Сейчас нет повторяющихся квестов на грани сброса.',
              isDark: isDark,
            )
          : Column(
              children: risks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                final skill = summary.state.skills
                    .where((skill) => skill.id == task.skillId)
                    .firstOrNull;
                final color = skill?.color ?? const Color(0xFFFF9500);
                return MotionListItem(
                  key: ValueKey('week-risk-${task.id}'),
                  index: index,
                  slide: 4,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(14),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: color.withAlpha(48)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.repeat, color: color, size: 17),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: txt,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${skill?.name ?? 'Навык'} • серия ${task.streak} д. • ${formatResetLabel(task.nextResetAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: sub, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _WeeklySection extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _WeeklySection({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101016) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: txt,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: sub, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _WeeklyEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _WeeklyEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
      decoration: BoxDecoration(
        color: sub.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Column(
        children: [
          Icon(icon, color: sub, size: 26),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sub,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: sub.withAlpha(180), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _WeeklySummary {
  final AppState state;
  final DateTime weekStart;
  final List<_DayWeekStat> dayStats;
  final List<HistoryEntry> entries;
  final List<_SkillWeekStat> skillStats;
  final List<Task> riskTasks;
  final WeeklyGoal? weeklyGoal;
  final _ProcrastinationInsights procrastination;

  const _WeeklySummary({
    required this.state,
    required this.weekStart,
    required this.dayStats,
    required this.entries,
    required this.skillStats,
    required this.riskTasks,
    required this.weeklyGoal,
    required this.procrastination,
  });

  int get totalXp => entries.fold(0, (sum, entry) => sum + entry.xp);

  int get completedTasks => entries.length;

  int get activeDays => dayStats.where((day) => day.completedTasks > 0).length;

  int get averageXpPerActiveDay =>
      activeDays == 0 ? 0 : (totalXp / activeDays).round();

  String? get topSkillName => skillStats.isEmpty ? null : skillStats.first.name;

  static _WeeklySummary fromState(AppState state, DateTime weekStart) {
    final normalizedStart = dateOnly(weekStart);
    final completionHistoryByDate = state.completionHistoryByDate;
    final days = List.generate(
      7,
      (index) => dateOnly(normalizedStart.add(Duration(days: index))),
    );

    final dayStats = <_DayWeekStat>[];
    final entries = <HistoryEntry>[];

    for (final day in days) {
      final dayEntries = completionHistoryByDate[day] ?? const <HistoryEntry>[];
      dayStats.add(
        _DayWeekStat(
          date: day,
          xp: dayEntries.fold(0, (sum, entry) => sum + entry.xp),
          completedTasks: dayEntries.length,
        ),
      );
      entries.addAll(dayEntries);
    }

    entries.sort((a, b) => b.at.compareTo(a.at));

    final skillsById = {for (final skill in state.skills) skill.id: skill};
    final skillStatsById = <String, _SkillWeekStat>{};

    for (final entry in entries) {
      final skill = skillsById[entry.skillId];
      final stat = skillStatsById.putIfAbsent(
        entry.skillId,
        () => _SkillWeekStat(
          skillId: entry.skillId,
          name: skill?.name ?? entry.skillName,
          icon: skill?.icon ?? entry.skillIcon,
          color: skill?.color ?? entry.skillColor,
        ),
      );
      stat.xp += entry.xp;
      stat.tasksCompleted++;
    }

    final skillStats = skillStatsById.values.toList()
      ..sort((a, b) {
        final byXp = b.xp.compareTo(a.xp);
        if (byXp != 0) return byXp;
        return a.name.compareTo(b.name);
      });

    final now = DateTime.now();
    final riskTasks =
        state.tasks
            .where((task) => task.type == TaskType.repeating)
            .where((task) => !task.isDone)
            .where((task) => task.nextResetAt != null)
            .where(
              (task) =>
                  task.nextResetAt!.difference(now) <= const Duration(days: 1),
            )
            .toList()
          ..sort((a, b) => a.nextResetAt!.compareTo(b.nextResetAt!));

    return _WeeklySummary(
      state: state,
      weekStart: normalizedStart,
      dayStats: dayStats,
      entries: entries,
      skillStats: skillStats,
      riskTasks: riskTasks,
      weeklyGoal: state.weeklyGoalForWeek(normalizedStart),
      procrastination: _ProcrastinationInsights.fromState(state),
    );
  }
}

class _ProcrastinationInsights {
  final List<_TaskInsight> stalled;
  final List<_TaskInsight> oversized;
  final List<_TaskInsight> minimumStarts;

  const _ProcrastinationInsights({
    required this.stalled,
    required this.oversized,
    required this.minimumStarts,
  });

  String get signature {
    final ids = [
      ...stalled.map((item) => 's:${item.task.id}:${item.daysSinceActivity}'),
      ...oversized.map((item) => 'o:${item.task.id}'),
      ...minimumStarts.map((item) => 'm:${item.task.id}'),
    ];
    return ids.join('|');
  }

  static _ProcrastinationInsights fromState(AppState state) {
    final now = DateTime.now();
    final activeTasks = state.tasks.where((task) => !task.isDone).toList();
    final skillsById = {for (final skill in state.skills) skill.id: skill};

    final stalled =
        activeTasks
            .where(_isStalled)
            .map(
              (task) => _TaskInsight(
                task: task,
                skill: skillsById[task.skillId],
                reason: _stalledReason(task, now),
                minimumAction: state.canCompleteMinimumAction(task)
                    ? task.minimumAction
                    : null,
                daysSinceActivity: _daysSince(_activityDate(task), now),
              ),
            )
            .toList()
          ..sort((a, b) {
            final byDays = b.daysSinceActivity.compareTo(a.daysSinceActivity);
            if (byDays != 0) return byDays;
            return _priorityScore(
              a.task.priority,
            ).compareTo(_priorityScore(b.task.priority));
          });

    final oversized =
        activeTasks
            .where(_isOversized)
            .map(
              (task) => _TaskInsight(
                task: task,
                skill: skillsById[task.skillId],
                reason: _oversizedReason(task),
                minimumAction: state.canCompleteMinimumAction(task)
                    ? task.minimumAction
                    : null,
                daysSinceActivity: _daysSince(_activityDate(task), now),
              ),
            )
            .toList()
          ..sort((a, b) {
            final byXp = b.task.xpReward.compareTo(a.task.xpReward);
            if (byXp != 0) return byXp;
            return _priorityScore(
              a.task.priority,
            ).compareTo(_priorityScore(b.task.priority));
          });

    final minimumStarts =
        activeTasks
            .where(state.canCompleteMinimumAction)
            .map(
              (task) => _TaskInsight(
                task: task,
                skill: skillsById[task.skillId],
                reason:
                    '+${state.previewMinimumActionXP(task)} XP за лёгкий старт без давления полного закрытия.',
                minimumAction: task.minimumAction,
                daysSinceActivity: _daysSince(_activityDate(task), now),
              ),
            )
            .toList()
          ..sort((a, b) {
            final byPriority = _priorityScore(
              a.task.priority,
            ).compareTo(_priorityScore(b.task.priority));
            if (byPriority != 0) return byPriority;
            final byStalled = b.daysSinceActivity.compareTo(
              a.daysSinceActivity,
            );
            if (byStalled != 0) return byStalled;
            return b.task.xpReward.compareTo(a.task.xpReward);
          });

    return _ProcrastinationInsights(
      stalled: stalled,
      oversized: oversized,
      minimumStarts: minimumStarts,
    );
  }

  static bool _isStalled(Task task) {
    if (task.type == TaskType.repeating) return false;
    final days = _daysSince(_activityDate(task), DateTime.now());
    if (task.priority == Priority.high && days >= 3) return true;
    if (task.isMinimumActionDone && days >= 2) return true;
    return days >= 7;
  }

  static bool _isOversized(Task task) {
    if (task.type == TaskType.repeating) return false;
    final softCap = typeSoftCap[task.type] ?? 200;
    final looksLarge =
        task.type == TaskType.midTerm ||
        task.type == TaskType.longTerm ||
        task.xpReward >= (softCap * 0.6).round();
    if (!looksLarge) return false;
    return !task.hasMinimumAction || task.subtasks.length < 2;
  }

  static String _stalledReason(Task task, DateTime now) {
    final days = _daysSince(_activityDate(task), now);
    if (task.isMinimumActionDone) {
      return 'Старт уже сделан, но задача не закрыта $days дн. Подойдёт один следующий маленький шаг.';
    }
    if (task.priority == Priority.high) {
      return 'High-priority задача без прогресса $days дн. Лучше снять давление минимумом или разбиением.';
    }
    return 'Без движения $days дн. Задача просит более простой вход.';
  }

  static String _oversizedReason(Task task) {
    final missing = <String>[];
    if (!task.hasMinimumAction) missing.add('минимум');
    if (task.subtasks.length < 2) missing.add('2–3 шага');
    return 'Похожа на крупный квест: ${task.xpReward} XP, ${typeLabel[task.type]}. Добавь ${missing.join(' и ')}.';
  }

  static DateTime _activityDate(Task task) {
    if (task.isMinimumActionDone && task.minimumActionDoneAt != null) {
      return task.minimumActionDoneAt!;
    }
    return task.updatedAt;
  }

  static int _daysSince(DateTime date, DateTime now) {
    return dateOnly(now).difference(dateOnly(date)).inDays.clamp(0, 9999);
  }

  static int _priorityScore(Priority priority) => switch (priority) {
    Priority.high => 0,
    Priority.medium => 1,
    Priority.low => 2,
  };
}

class _TaskInsight {
  final Task task;
  final Skill? skill;
  final String reason;
  final String? minimumAction;
  final int daysSinceActivity;

  const _TaskInsight({
    required this.task,
    required this.skill,
    required this.reason,
    required this.minimumAction,
    required this.daysSinceActivity,
  });
}

class _DayWeekStat {
  final DateTime date;
  final int xp;
  final int completedTasks;

  const _DayWeekStat({
    required this.date,
    required this.xp,
    required this.completedTasks,
  });
}

class _SkillWeekStat {
  final String skillId;
  final String name;
  final IconData icon;
  final Color color;
  int xp = 0;
  int tasksCompleted = 0;

  _SkillWeekStat({
    required this.skillId,
    required this.name,
    required this.icon,
    required this.color,
  });
}

DateTime _startOfWeek(DateTime date) {
  final day = dateOnly(date);
  return day.subtract(Duration(days: day.weekday - 1));
}

String _weekdayShort(DateTime date) {
  const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  return weekdays[date.weekday - 1];
}

String _formatDayMonth(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month';
}

String _questCount(int count) => '$count ${_questWord(count)}';

String _questWord(int count) {
  final lastTwo = count % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'квестов';
  return switch (count % 10) {
    1 => 'квест',
    2 || 3 || 4 => 'квеста',
    _ => 'квестов',
  };
}
