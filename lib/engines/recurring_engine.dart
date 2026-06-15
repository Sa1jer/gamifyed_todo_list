import '../models.dart';
import '../utils.dart';

enum RecurringDueBucket { today, thisWeek, thisMonth, later }

class RecurringQuestInfo {
  final Task task;
  final Skill? skill;
  final SkillTreeNode? stage;
  final DateTime resetAt;
  final RecurringDueBucket dueBucket;
  final bool linkedToActiveStage;

  const RecurringQuestInfo({
    required this.task,
    required this.skill,
    required this.stage,
    required this.resetAt,
    required this.dueBucket,
    required this.linkedToActiveStage,
  });

  bool get isDone => task.isDone;

  bool get isDueToday => dueBucket == RecurringDueBucket.today;
}

class RecurringSnapshot {
  final List<RecurringQuestInfo> quests;
  final List<RecurringQuestInfo> dueToday;
  final List<RecurringQuestInfo> dueThisWeek;
  final List<RecurringQuestInfo> dueThisMonth;
  final Map<RepeatFrequency, List<RecurringQuestInfo>> grouped;

  const RecurringSnapshot({
    required this.quests,
    required this.dueToday,
    required this.dueThisWeek,
    required this.dueThisMonth,
    required this.grouped,
  });

  bool get isEmpty => quests.isEmpty;
}

class RecurringEngine {
  const RecurringEngine();

  RecurringSnapshot buildSnapshot(
    Iterable<Task> tasks, {
    Iterable<Skill> skills = const [],
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final infos =
        tasks
            .where((task) => task.type == TaskType.repeating)
            .map((task) => _infoFor(task, skills, reference))
            .toList()
          ..sort(_compareInfo);

    final activeInfos = infos.where((info) => !info.isDone).toList();
    final grouped = <RepeatFrequency, List<RecurringQuestInfo>>{};
    for (final info in infos) {
      grouped.putIfAbsent(info.task.repeatFrequency, () => []).add(info);
    }

    return RecurringSnapshot(
      quests: infos,
      dueToday: activeInfos
          .where((info) => info.dueBucket == RecurringDueBucket.today)
          .toList(),
      dueThisWeek: activeInfos
          .where(
            (info) =>
                info.dueBucket == RecurringDueBucket.today ||
                info.dueBucket == RecurringDueBucket.thisWeek,
          )
          .toList(),
      dueThisMonth: activeInfos
          .where((info) => info.dueBucket != RecurringDueBucket.later)
          .toList(),
      grouped: grouped,
    );
  }

  bool isDueToday(Task task, {DateTime? now}) {
    if (task.type != TaskType.repeating || task.isDone) return false;
    final reference = now ?? DateTime.now();
    return _dueBucketFor(_effectiveResetAt(task, reference), reference) ==
        RecurringDueBucket.today;
  }

  RecurringQuestInfo _infoFor(Task task, Iterable<Skill> skills, DateTime now) {
    final skill = skills
        .where((candidate) => candidate.id == task.skillId)
        .firstOrNull;
    final stage = skill == null || task.treeNodeId == null
        ? null
        : skill.treeNodes
              .where((candidate) => candidate.id == task.treeNodeId)
              .firstOrNull;
    final resetAt = _effectiveResetAt(task, now);
    final linkedToActiveStage =
        skill != null &&
        stage != null &&
        skill.treeNodeStatus(stage) == SkillTreeNodeStatus.active;

    return RecurringQuestInfo(
      task: task,
      skill: skill,
      stage: stage,
      resetAt: resetAt,
      dueBucket: _dueBucketFor(resetAt, now),
      linkedToActiveStage: linkedToActiveStage,
    );
  }

  DateTime _effectiveResetAt(Task task, DateTime now) {
    return task.nextResetAt ??
        nextResetFrom(now, task.repeatFrequency, task.repeatCustomDays);
  }

  RecurringDueBucket _dueBucketFor(DateTime resetAt, DateTime now) {
    if (!resetAt.isAfter(now.add(const Duration(hours: 24)))) {
      return RecurringDueBucket.today;
    }
    if (!resetAt.isAfter(now.add(const Duration(days: 7)))) {
      return RecurringDueBucket.thisWeek;
    }
    final nextMonthStart = DateTime(now.year, now.month + 1);
    if (resetAt.isBefore(nextMonthStart)) {
      return RecurringDueBucket.thisMonth;
    }
    return RecurringDueBucket.later;
  }

  int _compareInfo(RecurringQuestInfo a, RecurringQuestInfo b) {
    final byDone = a.isDone == b.isDone ? 0 : (a.isDone ? 1 : -1);
    if (byDone != 0) return byDone;

    final byBucket = a.dueBucket.index.compareTo(b.dueBucket.index);
    if (byBucket != 0) return byBucket;

    final byReset = a.resetAt.compareTo(b.resetAt);
    if (byReset != 0) return byReset;

    final byStage = a.linkedToActiveStage == b.linkedToActiveStage
        ? 0
        : (a.linkedToActiveStage ? -1 : 1);
    if (byStage != 0) return byStage;

    return a.task.title.compareTo(b.task.title);
  }
}
