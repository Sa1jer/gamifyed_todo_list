import '../engines/task_ordering.dart';
import '../models.dart';
import '../utils.dart';

class TodayDashboardViewData {
  TodayDashboardViewData({
    required Iterable<String> activeTaskIds,
    required Iterable<String> dailyTaskIds,
    required Iterable<String> riskyTaskIds,
    required Iterable<String> focusTaskIds,
    required this.nextTaskId,
    required this.completedToday,
    required this.xpToday,
  }) : activeTaskIds = List.unmodifiable(activeTaskIds),
       dailyTaskIds = List.unmodifiable(dailyTaskIds),
       riskyTaskIds = List.unmodifiable(riskyTaskIds),
       focusTaskIds = List.unmodifiable(focusTaskIds);

  final List<String> activeTaskIds;
  final List<String> dailyTaskIds;
  final List<String> riskyTaskIds;
  final List<String> focusTaskIds;
  final String? nextTaskId;
  final int completedToday;
  final int xpToday;
}

class TodayDashboardViewDataBuilder {
  const TodayDashboardViewDataBuilder();

  TodayDashboardViewData build({
    required Iterable<Task> tasks,
    required DateTime now,
    required int completedToday,
    required int xpToday,
    required int Function(Task task) previewEarnedXp,
    required bool Function(Task task) isActiveStageTask,
  }) {
    final active = tasks
        .where((task) => task.isSkillTask && !task.isDone)
        .toList(growable: false);
    final sorted = [...active]
      ..sort(
        (a, b) => _compareTasks(
          a,
          b,
          now: now,
          previewEarnedXp: previewEarnedXp,
          isActiveStageTask: isActiveStageTask,
        ),
      );
    final daily = active
        .where((task) => task.type == TaskType.repeating)
        .toList(growable: false);
    final risky =
        daily
            .where((task) => task.nextResetAt != null)
            .where(
              (task) =>
                  task.nextResetAt!.difference(now) <= const Duration(days: 1),
            )
            .toList()
          ..sort((a, b) => a.nextResetAt!.compareTo(b.nextResetAt!));

    return TodayDashboardViewData(
      activeTaskIds: active.map((task) => task.id),
      dailyTaskIds: daily.map((task) => task.id),
      riskyTaskIds: risky.map((task) => task.id),
      focusTaskIds: sorted.take(3).map((task) => task.id),
      nextTaskId: sorted.firstOrNull?.id,
      completedToday: completedToday,
      xpToday: xpToday,
    );
  }

  int _compareTasks(
    Task a,
    Task b, {
    required DateTime now,
    required int Function(Task task) previewEarnedXp,
    required bool Function(Task task) isActiveStageTask,
  }) {
    final byRisk = _riskScore(a, now).compareTo(_riskScore(b, now));
    if (byRisk != 0) return byRisk;

    final byMinimum = _minimumScore(a).compareTo(_minimumScore(b));
    if (byMinimum != 0) return byMinimum;

    final byStage = _stageScore(
      a,
      isActiveStageTask,
    ).compareTo(_stageScore(b, isActiveStageTask));
    if (byStage != 0) return byStage;

    final byRepeating = _repeatingScore(a).compareTo(_repeatingScore(b));
    if (byRepeating != 0) return byRepeating;

    final byPriority = prioritySortRank(
      a.priority,
    ).compareTo(prioritySortRank(b.priority));
    if (byPriority != 0) return byPriority;

    final byXp = previewEarnedXp(b).compareTo(previewEarnedXp(a));
    if (byXp != 0) return byXp;

    final byUpdated = b.updatedAt.compareTo(a.updatedAt);
    if (byUpdated != 0) return byUpdated;

    final byCreated = b.createdAt.compareTo(a.createdAt);
    if (byCreated != 0) return byCreated;

    final byTitle = a.title.compareTo(b.title);
    if (byTitle != 0) return byTitle;
    return a.id.compareTo(b.id);
  }

  int _riskScore(Task task, DateTime now) {
    final resetAt = task.nextResetAt;
    if (task.type != TaskType.repeating || resetAt == null) return 1;
    final untilReset = resetAt.difference(now);
    return !untilReset.isNegative && untilReset <= const Duration(hours: 24)
        ? 0
        : 1;
  }

  int _minimumScore(Task task) =>
      task.hasMinimumAction && !task.isDone && !task.isMinimumActionDone
      ? 0
      : 1;

  int _stageScore(Task task, bool Function(Task task) isActiveStageTask) =>
      isActiveStageTask(task) ? 0 : 1;

  int _repeatingScore(Task task) => task.type == TaskType.repeating ? 0 : 1;
}
