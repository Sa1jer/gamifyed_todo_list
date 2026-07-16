import 'package:flutter/material.dart';
import '../analytics/weekly_analytics_read_model.dart';
import '../app_state.dart';
import '../feedback_service.dart';
import '../utils.dart';
import 'shared.dart';
import 'weekly_analytics/weekly_goal_section.dart';
import 'weekly_analytics/weekly_charts.dart';
import 'weekly_analytics/weekly_header.dart';
import 'weekly_analytics/weekly_insights.dart';
import 'weekly_analytics/weekly_overview.dart';
import 'weekly_analytics/weekly_presentation_data.dart';

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
    final skillVisuals = <String, WeeklySkillVisual>{
      for (final skill in state.skills)
        skill.id: WeeklySkillVisual(color: skill.color, icon: skill.icon),
    };
    for (final entry in state.history) {
      skillVisuals.putIfAbsent(
        entry.skillId,
        () => WeeklySkillVisual(color: entry.skillColor, icon: entry.skillIcon),
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
          WeeklyHeader(
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
                    child: WeeklyOverview(
                      key: ValueKey(
                        'week-overview-${_weekStart.toIso8601String()}',
                      ),
                      summary: summary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  MotionFadeSlideSwitcher(
                    child: WeeklyProcrastinationInsightsCard(
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
                      final skills = WeeklySkillBreakdown(
                        summary: summary,
                        isDark: isDark,
                        skillVisuals: skillVisuals,
                      );
                      final graph = WeeklyXpChart(
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
                      final tasks = WeeklyTaskList(
                        summary: summary,
                        isDark: isDark,
                        skillVisuals: skillVisuals,
                      );
                      final risks = WeeklyStreakRisks(
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

  Future<void> _openGoalEditor(WeeklySummary summary) async {
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
