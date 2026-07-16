import '../engines/task_ordering.dart';
import '../models/activity_models.dart';
import '../models/task_models.dart';
import '../utils.dart';
import 'analytics_read_model.dart';

class WeeklyTaskRiskData {
  final String taskId;
  final String title;
  final String skillId;
  final String skillName;
  final int streak;
  final DateTime? nextResetAt;

  const WeeklyTaskRiskData({
    required this.taskId,
    required this.title,
    required this.skillId,
    required this.skillName,
    required this.streak,
    required this.nextResetAt,
  });
}

/// Detached task projection used as input to weekly analytics calculations.
///
/// The projection is created at the AppState/presentation boundary. The
/// builder therefore never retains live Task/Skill instances and never calls
/// back into the application facade while assembling a snapshot.
class WeeklyTaskInputData {
  final String taskId;
  final String title;
  final String skillId;
  final String skillName;
  final int xpReward;
  final TaskType type;
  final Priority priority;
  final int streak;
  final DateTime? nextResetAt;
  final DateTime updatedAt;
  final DateTime? minimumActionDoneAt;
  final String minimumAction;
  final int subtaskCount;
  final bool canCompleteMinimumAction;
  final int minimumActionXp;

  const WeeklyTaskInputData({
    required this.taskId,
    required this.title,
    required this.skillId,
    required this.skillName,
    required this.xpReward,
    required this.type,
    required this.priority,
    required this.streak,
    required this.nextResetAt,
    required this.updatedAt,
    required this.minimumActionDoneAt,
    required this.minimumAction,
    required this.subtaskCount,
    required this.canCompleteMinimumAction,
    required this.minimumActionXp,
  });

  bool get hasMinimumAction => minimumAction.trim().isNotEmpty;

  bool get isMinimumActionDone => minimumActionDoneAt != null;
}

class WeeklyKeyResultData {
  final String id;
  final String title;
  final bool isDone;
  final DateTime? completedAt;

  const WeeklyKeyResultData({
    required this.id,
    required this.title,
    required this.isDone,
    required this.completedAt,
  });
}

class WeeklyGoalData {
  final String id;
  final DateTime weekStart;
  final String title;
  final List<WeeklyKeyResultData> keyResults;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeeklyGoalData({
    required this.id,
    required this.weekStart,
    required this.title,
    required List<WeeklyKeyResultData> keyResults,
    required this.createdAt,
    required this.updatedAt,
  }) : keyResults = List.unmodifiable(keyResults);

  int get completedKeyResults =>
      keyResults.where((result) => result.isDone).length;

  double get progress => keyResults.isEmpty
      ? 0
      : (completedKeyResults / keyResults.length).clamp(0.0, 1.0);

  bool get isCompleted => keyResults.isNotEmpty && progress >= 1;

  factory WeeklyGoalData.fromGoal(WeeklyGoal goal) => WeeklyGoalData(
    id: goal.id,
    weekStart: goal.weekStart,
    title: goal.title,
    keyResults: List.unmodifiable(
      goal.keyResults.map(
        (result) => WeeklyKeyResultData(
          id: result.id,
          title: result.title,
          isDone: result.isDone,
          completedAt: result.completedAt,
        ),
      ),
    ),
    createdAt: goal.createdAt,
    updatedAt: goal.updatedAt,
  );
}

class WeeklyTaskInsightData {
  final String taskId;
  final String title;
  final String skillId;
  final String skillName;
  final String reason;
  final String? minimumAction;
  final int daysSinceActivity;
  final int xpReward;
  final Priority priority;

  const WeeklyTaskInsightData({
    required this.taskId,
    required this.title,
    required this.skillId,
    required this.skillName,
    required this.reason,
    required this.minimumAction,
    required this.daysSinceActivity,
    required this.xpReward,
    required this.priority,
  });
}

class ProcrastinationInsightsData {
  final List<WeeklyTaskInsightData> stalled;
  final List<WeeklyTaskInsightData> oversized;
  final List<WeeklyTaskInsightData> minimumStarts;

  ProcrastinationInsightsData({
    required List<WeeklyTaskInsightData> stalled,
    required List<WeeklyTaskInsightData> oversized,
    required List<WeeklyTaskInsightData> minimumStarts,
  }) : stalled = List.unmodifiable(stalled),
       oversized = List.unmodifiable(oversized),
       minimumStarts = List.unmodifiable(minimumStarts);

  String get signature {
    final ids = [
      ...stalled.map((item) => 's:${item.taskId}:${item.daysSinceActivity}'),
      ...oversized.map((item) => 'o:${item.taskId}'),
      ...minimumStarts.map((item) => 'm:${item.taskId}'),
    ];
    return ids.join('|');
  }

  int get totalCount =>
      stalled.length + oversized.length + minimumStarts.length;

  WeeklyTaskInsightData? get primaryInsight {
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
}

/// Detached immutable data consumed by the weekly analytics presentation.
///
/// The object intentionally contains no AppState or mutable model references.
/// Rebuilding it is the only way for changed application state to become
/// visible to this view.
class WeeklyAnalyticsViewData {
  final DateTime weekStart;
  final List<AnalyticsDaySummary> dayStats;
  final List<AnalyticsHistoryRecord> entries;
  final List<AnalyticsSkillSummary> skillStats;
  final List<WeeklyTaskRiskData> riskTasks;
  final WeeklyGoalData? weeklyGoal;
  final ProcrastinationInsightsData procrastination;

  WeeklyAnalyticsViewData({
    required this.weekStart,
    required List<AnalyticsDaySummary> dayStats,
    required List<AnalyticsHistoryRecord> entries,
    required List<AnalyticsSkillSummary> skillStats,
    required List<WeeklyTaskRiskData> riskTasks,
    required this.weeklyGoal,
    required this.procrastination,
  }) : dayStats = List.unmodifiable(dayStats),
       entries = List.unmodifiable(entries),
       skillStats = List.unmodifiable(skillStats),
       riskTasks = List.unmodifiable(riskTasks);

  int get totalXp => entries.fold(0, (sum, entry) => sum + entry.xp);

  int get completedTasks => entries.length;

  int get activeDays => dayStats.where((day) => day.completedTasks > 0).length;

  int get averageXpPerActiveDay =>
      activeDays == 0 ? 0 : (totalXp / activeDays).round();

  String? get topSkillName => skillStats.isEmpty ? null : skillStats.first.name;
}

class WeeklyAnalyticsBuilder {
  const WeeklyAnalyticsBuilder();

  WeeklyAnalyticsViewData build({
    required AnalyticsReadModel analytics,
    required Iterable<WeeklyTaskInputData> tasks,
    required WeeklyGoalData? weeklyGoal,
    required DateTime now,
  }) {
    final normalizedStart = analytics.weekStart;
    final activeTasks = tasks.toList(growable: false);
    final riskTasks =
        activeTasks
            .where((task) => task.type == TaskType.repeating)
            .where((task) => task.nextResetAt != null)
            .where(
              (task) =>
                  task.nextResetAt!.difference(now) <= const Duration(days: 1),
            )
            .map(
              (task) => WeeklyTaskRiskData(
                taskId: task.taskId,
                title: task.title,
                skillId: task.skillId,
                skillName: task.skillName,
                streak: task.streak,
                nextResetAt: task.nextResetAt,
              ),
            )
            .toList()
          ..sort((a, b) => a.nextResetAt!.compareTo(b.nextResetAt!));

    return WeeklyAnalyticsViewData(
      weekStart: normalizedStart,
      dayStats: analytics.days,
      entries: analytics.entries,
      skillStats: List.unmodifiable(
        analytics.skills.where((skill) => skill.weeklyXp > 0),
      ),
      riskTasks: List.unmodifiable(riskTasks),
      weeklyGoal: weeklyGoal,
      procrastination: _buildProcrastination(
        activeTasks: activeTasks,
        now: now,
      ),
    );
  }

  ProcrastinationInsightsData _buildProcrastination({
    required List<WeeklyTaskInputData> activeTasks,
    required DateTime now,
  }) {
    WeeklyTaskInsightData project(WeeklyTaskInputData task, String reason) =>
        WeeklyTaskInsightData(
          taskId: task.taskId,
          title: task.title,
          skillId: task.skillId,
          skillName: task.skillName,
          reason: reason,
          minimumAction: task.canCompleteMinimumAction
              ? task.minimumAction
              : null,
          daysSinceActivity: _daysSince(_activityDate(task), now),
          xpReward: task.xpReward,
          priority: task.priority,
        );

    final stalled =
        activeTasks
            .where((task) => _isStalled(task, now))
            .map((task) => project(task, _stalledReason(task, now)))
            .toList()
          ..sort((a, b) {
            final byDays = b.daysSinceActivity.compareTo(a.daysSinceActivity);
            if (byDays != 0) return byDays;
            return prioritySortRank(
              a.priority,
            ).compareTo(prioritySortRank(b.priority));
          });

    final oversized =
        activeTasks
            .where(_isOversized)
            .map((task) => project(task, _oversizedReason(task)))
            .toList()
          ..sort((a, b) {
            final byXp = b.xpReward.compareTo(a.xpReward);
            if (byXp != 0) return byXp;
            return prioritySortRank(
              a.priority,
            ).compareTo(prioritySortRank(b.priority));
          });

    final minimumStarts =
        activeTasks
            .where((task) => task.canCompleteMinimumAction)
            .map(
              (task) => project(
                task,
                '+${task.minimumActionXp} XP за лёгкий старт без давления полного закрытия.',
              ),
            )
            .toList()
          ..sort((a, b) {
            final byPriority = prioritySortRank(
              a.priority,
            ).compareTo(prioritySortRank(b.priority));
            if (byPriority != 0) return byPriority;
            final byStalled = b.daysSinceActivity.compareTo(
              a.daysSinceActivity,
            );
            if (byStalled != 0) return byStalled;
            return b.xpReward.compareTo(a.xpReward);
          });

    return ProcrastinationInsightsData(
      stalled: List.unmodifiable(stalled),
      oversized: List.unmodifiable(oversized),
      minimumStarts: List.unmodifiable(minimumStarts),
    );
  }

  static bool _isStalled(WeeklyTaskInputData task, DateTime now) {
    if (task.type == TaskType.repeating) return false;
    final days = _daysSince(_activityDate(task), now);
    if (task.priority == Priority.high && days >= 3) return true;
    if (task.isMinimumActionDone && days >= 2) return true;
    return days >= 7;
  }

  static bool _isOversized(WeeklyTaskInputData task) {
    if (task.type == TaskType.repeating) return false;
    final softCap = typeSoftCap[task.type] ?? 200;
    final looksLarge =
        task.type == TaskType.midTerm ||
        task.type == TaskType.longTerm ||
        task.xpReward >= (softCap * 0.6).round();
    if (!looksLarge) return false;
    return !task.hasMinimumAction || task.subtaskCount < 2;
  }

  static String _stalledReason(WeeklyTaskInputData task, DateTime now) {
    final days = _daysSince(_activityDate(task), now);
    if (task.isMinimumActionDone) {
      return 'Старт уже сделан, но квест не закрыт $days дн. Подойдёт один следующий маленький шаг.';
    }
    if (task.priority == Priority.high) {
      return 'Квест с высоким фокусом без прогресса $days дн. Лучше снять давление минимумом или разбиением.';
    }
    return 'Без движения $days дн. Квест просит более простой вход.';
  }

  static String _oversizedReason(WeeklyTaskInputData task) {
    final missing = <String>[];
    if (!task.hasMinimumAction) missing.add('минимум');
    if (task.subtaskCount < 2) missing.add('2–3 шага');
    return 'Похожа на крупный квест: ${task.xpReward} XP, ${typeLabel[task.type]}. Добавь ${missing.join(' и ')}.';
  }

  static DateTime _activityDate(WeeklyTaskInputData task) {
    if (task.isMinimumActionDone && task.minimumActionDoneAt != null) {
      return task.minimumActionDoneAt!;
    }
    return task.updatedAt;
  }

  static int _daysSince(DateTime date, DateTime now) =>
      dateOnly(now).difference(dateOnly(date)).inDays.clamp(0, 9999);
}
