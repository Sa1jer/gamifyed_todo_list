import 'package:flutter/material.dart';
import '../analytics/weekly_analytics_read_model.dart';
import '../app_state.dart';
import '../feedback_service.dart';
import '../utils.dart';
import 'shared.dart';
import 'weekly_analytics/weekly_goal_section.dart';
import 'weekly_analytics/weekly_section.dart';

class WeeklyAnalyticsDialog extends StatefulWidget {
  final AppState state;
  final bool fullScreen;

  const WeeklyAnalyticsDialog({
    super.key,
    required this.state,
    this.fullScreen = false,
  });

  @override
  State<WeeklyAnalyticsDialog> createState() => _WeeklyAnalyticsDialogState();
}

class _WeeklyAnalyticsDialogState extends State<WeeklyAnalyticsDialog> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = startOfWeek(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDark = state.isDark;
    final bdr = borderColor(isDark);
    final bg = surface(isDark);
    final analytics = state.analyticsForWeek(_weekStart);
    final skillNames = {for (final skill in state.skills) skill.id: skill.name};
    final taskInputs = state.tasks
        .where((task) => task.isSkillTask && !task.isDone)
        .map(
          (task) => WeeklyTaskInputData(
            taskId: task.id,
            title: task.title,
            skillId: task.skillId,
            skillName: skillNames[task.skillId] ?? 'Навык',
            xpReward: task.xpReward,
            type: task.type,
            priority: task.priority,
            streak: task.streak,
            nextResetAt: task.nextResetAt,
            updatedAt: task.updatedAt,
            minimumActionDoneAt: task.minimumActionDoneAt,
            minimumAction: task.minimumAction,
            subtaskCount: task.subtasks.length,
            canCompleteMinimumAction: state.canCompleteMinimumAction(task),
            minimumActionXp: state.previewMinimumActionXP(task),
          ),
        )
        .toList(growable: false);
    final weeklyGoal = state.weeklyGoalForWeek(analytics.weekStart);
    final summary = const WeeklyAnalyticsBuilder().build(
      analytics: analytics,
      tasks: taskInputs,
      weeklyGoal: weeklyGoal == null
          ? null
          : WeeklyGoalData.fromGoal(weeklyGoal),
      now: DateTime.now(),
    );
    final skillVisuals = <String, _WeeklySkillVisual>{
      for (final skill in state.skills)
        skill.id: _WeeklySkillVisual(color: skill.color, icon: skill.icon),
    };
    for (final entry in state.history) {
      skillVisuals.putIfAbsent(
        entry.skillId,
        () =>
            _WeeklySkillVisual(color: entry.skillColor, icon: entry.skillIcon),
      );
    }
    final canGoNext = _weekStart.isBefore(startOfWeek(DateTime.now()));
    final size = MediaQuery.sizeOf(context);
    final availableWidth = size.width - 36;
    final availableHeight = size.height - 40;
    final dialogWidth = widget.fullScreen
        ? size.width
        : availableWidth < 360
        ? availableWidth
        : availableWidth.clamp(360.0, 900.0).toDouble();
    final maxHeight = widget.fullScreen
        ? size.height
        : availableHeight < 520
        ? availableHeight
        : availableHeight.clamp(520.0, 720.0).toDouble();

    final content = Container(
      width: dialogWidth,
      constraints: widget.fullScreen
          ? const BoxConstraints()
          : BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.fullScreen ? 0 : 22),
        border: widget.fullScreen ? null : Border.all(color: bdr),
        boxShadow: widget.fullScreen
            ? null
            : [
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
                    () => _weekStart = _weekStart.add(const Duration(days: 7)),
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
                    child: _ProcrastinationInsightsCard(
                      key: ValueKey(
                        'week-procrastination-${summary.procrastination.signature}',
                      ),
                      summary: summary,
                      skillVisuals: skillVisuals,
                      isDark: isDark,
                      onStartMinimum: (taskId) {
                        final message = widget.state.completeMinimumAction(
                          taskId,
                        );
                        if (message != null) {
                          AppFeedback.questResult(message, isMinimum: true);
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
                      final skills = _WeeklySkillBreakdown(
                        summary: summary,
                        isDark: isDark,
                        skillVisuals: skillVisuals,
                      );
                      final graph = _WeeklyXpChart(
                        summary: summary,
                        isDark: isDark,
                      );

                      if (!wide) {
                        return Column(
                          children: [skills, const SizedBox(height: 14), graph],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: skills),
                          const SizedBox(width: 14),
                          Expanded(flex: 6, child: graph),
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
                        skillVisuals: skillVisuals,
                      );
                      final risks = _WeeklyStreakRisks(
                        summary: summary,
                        isDark: isDark,
                        skillVisuals: skillVisuals,
                      );

                      if (!wide) {
                        return Column(
                          children: [tasks, const SizedBox(height: 14), risks],
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
                  const SizedBox(height: 14),
                  MotionFadeSlideSwitcher(
                    child: WeeklyGoalCard(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.fullScreen) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(child: SizedBox.expand(child: content)),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: content,
    );
  }

  Future<void> _openGoalEditor(_WeeklySummary summary) async {
    final draft = await showWeeklyGoalEditor(
      context: context,
      isDark: widget.state.isDark,
      weekStart: summary.weekStart,
      goal: summary.weeklyGoal,
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
                  'Обзор недели',
                  style: TextStyle(
                    color: txt,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDayMonth(weekStart)} — ${_formatDayMonth(weekStart.add(const Duration(days: 6)))} · что получилось, какой навык рос и что мягко продолжить',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: sub, fontSize: 12.5, height: 1.25),
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
            tooltip: 'Закрыть обзор недели',
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
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final storyTitle = summary.completedTasks == 0
        ? 'Неделя пока ждёт первый квест'
        : summary.topSkillName == null
        ? 'На этой неделе закрыто ${_questCount(summary.completedTasks)}'
        : 'Главный навык недели — ${summary.topSkillName}';
    final storySubtitle = summary.completedTasks == 0
        ? 'Закрой один маленький квест или минимальный шаг, и здесь появится история роста.'
        : '${summary.completedTasks} ${_questWord(summary.completedTasks)} · ${summary.totalXp} XP · ${summary.activeDays} активн. дн.';

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.auto_stories,
      color: const Color(0xFF34C759),
      title: 'Итог недели',
      subtitle: 'Сначала рост, потом детали.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withAlpha(14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF34C759).withAlpha(42)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withAlpha(24),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Color(0xFF34C759),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storyTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: txt,
                          fontSize: 14.5,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storySubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: sub,
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
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
                      title: 'Серии',
                      value: summary.riskTasks.isEmpty
                          ? 'ок'
                          : '${summary.riskTasks.length}',
                      subtitle: summary.riskTasks.isEmpty
                          ? 'Спокойны'
                          : 'Есть риск сброса',
                      icon: Icons.local_fire_department,
                      color: const Color(0xFFFF9500),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
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

class _ProcrastinationInsightsCard extends StatelessWidget {
  final _WeeklySummary summary;
  final bool isDark;
  final Map<String, _WeeklySkillVisual> skillVisuals;
  final ValueChanged<String> onStartMinimum;

  const _ProcrastinationInsightsCard({
    super.key,
    required this.summary,
    required this.isDark,
    required this.skillVisuals,
    required this.onStartMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final insights = summary.procrastination;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final hasInsights =
        insights.stalled.isNotEmpty ||
        insights.oversized.isNotEmpty ||
        insights.minimumStarts.isNotEmpty;
    final primary = insights.primaryInsight;
    final primaryCanStart =
        primary != null &&
        insights.minimumStarts.any((item) => item.taskId == primary.taskId);

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.next_plan,
      color: const Color(0xFF4A9EFF),
      title: 'Что поможет продолжить',
      subtitle: 'Один мягкий следующий шаг вместо панели тревог.',
      child: hasInsights
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (primary != null)
                  _PrimaryInsightCard(
                    insight: primary,
                    isDark: isDark,
                    skillVisuals: skillVisuals,
                    label: insights.primaryLabel,
                    onStartMinimum: primaryCanStart ? onStartMinimum : null,
                  ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF121219)
                        : const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: borderColor(isDark)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
                      collapsedIconColor: sub,
                      iconColor: const Color(0xFF4A9EFF),
                      title: Text(
                        'Детали: ${insights.totalCount} пунктов для разбора',
                        style: TextStyle(
                          color: txt,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        'Детали доступны, но не требуют внимания сразу.',
                        style: TextStyle(color: sub, fontSize: 10.5),
                      ),
                      children: [
                        LayoutBuilder(
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
                                skillVisuals: skillVisuals,
                                emptyText: 'Нет зависших квестов',
                              ),
                              _InsightColumn(
                                isDark: isDark,
                                title: 'Крупные',
                                subtitle: 'Нужен мягкий вход',
                                icon: Icons.account_tree,
                                color: const Color(0xFFFF9500),
                                items: insights.oversized,
                                skillVisuals: skillVisuals,
                                emptyText: 'Крупные квесты под контролем',
                              ),
                              _InsightColumn(
                                isDark: isDark,
                                title: 'Лёгкий старт',
                                subtitle: 'Можно начать сейчас',
                                icon: Icons.play_circle,
                                color: const Color(0xFF34C759),
                                items: insights.minimumStarts,
                                skillVisuals: skillVisuals,
                                emptyText: 'Нет доступных лёгких стартов',
                                onStartMinimum: onStartMinimum,
                              ),
                            ];

                            if (!wide) {
                              return Column(
                                children: columns
                                    .map(
                                      (column) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
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
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : WeeklyAnalyticsEmptyState(
              icon: Icons.shield,
              title: 'Неделя выглядит устойчиво',
              subtitle: 'Квесты достаточно понятны для продолжения без аудита.',
              isDark: isDark,
            ),
    );
  }
}

class _PrimaryInsightCard extends StatelessWidget {
  final _TaskInsight insight;
  final bool isDark;
  final Map<String, _WeeklySkillVisual> skillVisuals;
  final String label;
  final ValueChanged<String>? onStartMinimum;

  const _PrimaryInsightCard({
    required this.insight,
    required this.isDark,
    required this.skillVisuals,
    required this.label,
    required this.onStartMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final color = insight.minimumAction != null
        ? const Color(0xFF34C759)
        : const Color(0xFF4A9EFF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withAlpha(46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: color, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: txt,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Это не тревога, а самый полезный следующий штрих недели.',
            style: TextStyle(color: sub, fontSize: 10.8, height: 1.25),
          ),
          const SizedBox(height: 10),
          _InsightTaskTile(
            insight: insight,
            isDark: isDark,
            skillVisuals: skillVisuals,
            color: color,
            onStartMinimum: onStartMinimum,
          ),
        ],
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
  final Map<String, _WeeklySkillVisual> skillVisuals;
  final String emptyText;
  final ValueChanged<String>? onStartMinimum;

  const _InsightColumn({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.items,
    required this.skillVisuals,
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
                key: ValueKey('$title-${insight.taskId}'),
                index: index,
                slide: 4,
                child: _InsightTaskTile(
                  insight: insight,
                  isDark: isDark,
                  skillVisuals: skillVisuals,
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
  final Map<String, _WeeklySkillVisual> skillVisuals;
  final Color color;
  final ValueChanged<String>? onStartMinimum;

  const _InsightTaskTile({
    required this.insight,
    required this.isDark,
    required this.skillVisuals,
    required this.color,
    required this.onStartMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final skillVisual = skillVisuals[insight.skillId];
    final skillColor = skillVisual?.color ?? color;

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
                skillVisual?.icon ?? Icons.bolt,
                color: skillColor,
                size: 15,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  insight.title,
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
                    onTap: () => onStartMinimum!(insight.taskId),
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

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.bar_chart,
      color: const Color(0xFFFFCC00),
      title: 'График XP',
      subtitle: 'Как распределялся рост по дням.',
      child: Column(
        children: [
          if (summary.completedTasks == 0)
            WeeklyAnalyticsEmptyState(
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
  final Map<String, _WeeklySkillVisual> skillVisuals;

  const _WeeklySkillBreakdown({
    required this.summary,
    required this.isDark,
    required this.skillVisuals,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final stats = summary.skillStats;
    final maxXp = stats.fold<int>(
      0,
      (max, stat) => stat.xp > max ? stat.xp : max,
    );

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.auto_graph,
      color: const Color(0xFF4A9EFF),
      title: 'Навыки недели',
      subtitle: 'Какие направления двигали неделю',
      child: stats.isEmpty
          ? WeeklyAnalyticsEmptyState(
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
                final visual = skillVisuals[stat.skillId];
                final color = visual?.color ?? const Color(0xFF4A9EFF);
                final icon = visual?.icon ?? Icons.bolt;
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
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              XPBar(
                                progress: progress,
                                color: color,
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
  final Map<String, _WeeklySkillVisual> skillVisuals;

  const _WeeklyTaskList({
    required this.summary,
    required this.isDark,
    required this.skillVisuals,
  });

  @override
  Widget build(BuildContext context) {
    final entries = summary.entries;
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.task_alt,
      color: const Color(0xFF34C759),
      title: 'Квесты недели',
      subtitle: 'Последние фактические закрытия',
      child: entries.isEmpty
          ? WeeklyAnalyticsEmptyState(
              icon: Icons.task_alt,
              title: 'Нет закрытых квестов',
              subtitle: 'Эта неделя пока ждёт первый выполненный шаг.',
              isDark: isDark,
            )
          : Column(
              children: entries.take(7).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final visual = skillVisuals[item.skillId];
                final color = visual?.color ?? const Color(0xFF4A9EFF);
                final icon = visual?.icon ?? Icons.bolt;
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
                            color: color.withAlpha(24),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(icon, color: color, size: 15),
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
  final Map<String, _WeeklySkillVisual> skillVisuals;

  const _WeeklyStreakRisks({
    required this.summary,
    required this.isDark,
    required this.skillVisuals,
  });

  @override
  Widget build(BuildContext context) {
    final risks = summary.riskTasks;
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.local_fire_department,
      color: const Color(0xFFFF9500),
      title: 'Риски серии',
      subtitle: 'Повторяющиеся квесты, которые лучше мягко поддержать.',
      child: risks.isEmpty
          ? WeeklyAnalyticsEmptyState(
              icon: Icons.shield,
              title: 'Риски не горят',
              subtitle: 'Сейчас нет повторяющихся квестов на грани сброса.',
              isDark: isDark,
            )
          : Column(
              children: risks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                final visual = skillVisuals[task.skillId];
                final color = visual?.color ?? const Color(0xFFFF9500);
                return MotionListItem(
                  key: ValueKey('week-risk-${task.taskId}'),
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
                                '${task.skillName} • серия ${task.streak} д. • ${formatResetLabel(task.nextResetAt)}',
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

typedef _WeeklySummary = WeeklyAnalyticsViewData;
typedef _TaskInsight = WeeklyTaskInsightData;

class _WeeklySkillVisual {
  final Color color;
  final IconData icon;

  const _WeeklySkillVisual({required this.color, required this.icon});
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
