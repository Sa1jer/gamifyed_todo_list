import '../app_state.dart';
import '../engines/task_ordering.dart';
import '../models.dart';
import '../utils.dart';
import 'analytics_read_model.dart';

class WeeklyAnalyticsReadModel {
  final AppState state;
  final DateTime weekStart;
  final List<AnalyticsDaySummary> dayStats;
  final List<AnalyticsHistoryRecord> entries;
  final List<AnalyticsSkillSummary> skillStats;
  final List<Task> riskTasks;
  final WeeklyGoal? weeklyGoal;
  final ProcrastinationInsights procrastination;

  const WeeklyAnalyticsReadModel({
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

  static WeeklyAnalyticsReadModel fromState(
    AppState state,
    DateTime weekStart, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final analytics = state.analyticsForWeek(weekStart);
    final normalizedStart = analytics.weekStart;
    final riskTasks =
        state.tasks
            .where((task) => task.type == TaskType.repeating)
            .where((task) => !task.isDone)
            .where((task) => task.nextResetAt != null)
            .where(
              (task) =>
                  task.nextResetAt!.difference(effectiveNow) <=
                  const Duration(days: 1),
            )
            .toList()
          ..sort((a, b) => a.nextResetAt!.compareTo(b.nextResetAt!));

    return WeeklyAnalyticsReadModel(
      state: state,
      weekStart: normalizedStart,
      dayStats: analytics.days,
      entries: analytics.entries,
      skillStats: analytics.skills
          .where((skill) => skill.weeklyXp > 0)
          .toList(growable: false),
      riskTasks: List.unmodifiable(riskTasks),
      weeklyGoal: state.weeklyGoalForWeek(normalizedStart),
      procrastination: ProcrastinationInsights.fromState(
        state,
        now: effectiveNow,
      ),
    );
  }
}

class ProcrastinationInsights {
  final List<TaskInsight> stalled;
  final List<TaskInsight> oversized;
  final List<TaskInsight> minimumStarts;

  const ProcrastinationInsights({
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

  int get totalCount =>
      stalled.length + oversized.length + minimumStarts.length;

  TaskInsight? get primaryInsight {
    if (minimumStarts.isNotEmpty) return minimumStarts.first;
    if (stalled.isNotEmpty) return stalled.first;
    if (oversized.isNotEmpty) return oversized.first;
    return null;
  }

  String get primaryLabel {
    if (minimumStarts.isNotEmpty) return 'Начни с минимального шага';
    if (stalled.isNotEmpty) return 'Верни в движение один квест';
    if (oversized.isNotEmpty) return 'Сделай крупный квест легче';
    return 'Продолжай спокойный темп';
  }

  static ProcrastinationInsights fromState(
    AppState state, {
    required DateTime now,
  }) {
    final activeTasks = state.tasks
        .where((task) => task.isSkillTask && !task.isDone)
        .toList();
    final skillsById = {for (final skill in state.skills) skill.id: skill};

    final stalled =
        activeTasks
            .where((task) => _isStalled(task, now))
            .map(
              (task) => TaskInsight(
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
            return prioritySortRank(
              a.task.priority,
            ).compareTo(prioritySortRank(b.task.priority));
          });

    final oversized =
        activeTasks
            .where(_isOversized)
            .map(
              (task) => TaskInsight(
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
            return prioritySortRank(
              a.task.priority,
            ).compareTo(prioritySortRank(b.task.priority));
          });

    final minimumStarts =
        activeTasks
            .where(state.canCompleteMinimumAction)
            .map(
              (task) => TaskInsight(
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
            final byPriority = prioritySortRank(
              a.task.priority,
            ).compareTo(prioritySortRank(b.task.priority));
            if (byPriority != 0) return byPriority;
            final byStalled = b.daysSinceActivity.compareTo(
              a.daysSinceActivity,
            );
            if (byStalled != 0) return byStalled;
            return b.task.xpReward.compareTo(a.task.xpReward);
          });

    return ProcrastinationInsights(
      stalled: List.unmodifiable(stalled),
      oversized: List.unmodifiable(oversized),
      minimumStarts: List.unmodifiable(minimumStarts),
    );
  }

  static bool _isStalled(Task task, DateTime now) {
    if (task.type == TaskType.repeating) return false;
    final days = _daysSince(_activityDate(task), now);
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
      return 'Старт уже сделан, но квест не закрыт $days дн. Подойдёт один следующий маленький шаг.';
    }
    if (task.priority == Priority.high) {
      return 'Квест с высоким фокусом без прогресса $days дн. Лучше снять давление минимумом или разбиением.';
    }
    return 'Без движения $days дн. Квест просит более простой вход.';
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
}

class TaskInsight {
  final Task task;
  final Skill? skill;
  final String reason;
  final String? minimumAction;
  final int daysSinceActivity;

  const TaskInsight({
    required this.task,
    required this.skill,
    required this.reason,
    required this.minimumAction,
    required this.daysSinceActivity,
  });
}
