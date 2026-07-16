import '../engines/goal_progress_engine.dart';
import '../models/activity_models.dart';
import '../models/skill_models.dart';
import '../models/task_models.dart';
import '../utils.dart';

class AnalyticsDaySummary {
  final DateTime date;
  final int xp;
  final int completedTasks;

  const AnalyticsDaySummary({
    required this.date,
    required this.xp,
    required this.completedTasks,
  });
}

class AnalyticsHistoryRecord {
  final String id;
  final String? taskId;
  final String taskTitle;
  final String skillId;
  final String skillName;
  final int xp;
  final bool isCompletion;
  final DateTime at;

  const AnalyticsHistoryRecord({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.skillId,
    required this.skillName,
    required this.xp,
    required this.isCompletion,
    required this.at,
  });

  factory AnalyticsHistoryRecord.fromEntry(HistoryEntry entry) =>
      AnalyticsHistoryRecord(
        id: entry.id,
        taskId: entry.taskId,
        taskTitle: entry.taskTitle,
        skillId: entry.skillId,
        skillName: entry.skillName,
        xp: entry.xp,
        isCompletion: entry.isCompletion,
        at: entry.at,
      );
}

class AnalyticsSkillSummary {
  final String skillId;
  final String name;
  final int weeklyXp;
  final int completedTasks;
  final int activeTasks;
  final int totalTasks;
  final int completedStages;
  final int totalStages;
  final double goalProgress;
  final bool isExistingSkill;

  const AnalyticsSkillSummary({
    required this.skillId,
    required this.name,
    required this.weeklyXp,
    required this.completedTasks,
    required this.activeTasks,
    required this.totalTasks,
    required this.completedStages,
    required this.totalStages,
    required this.goalProgress,
    required this.isExistingSkill,
  });

  bool get hasRoadmap => totalStages > 0;

  int get xp => weeklyXp;

  int get tasksCompleted => completedTasks;
}

class AnalyticsActivityLeader {
  final String skillId;
  final String name;
  final int xp;
  final int completedTasks;

  const AnalyticsActivityLeader({
    required this.skillId,
    required this.name,
    required this.xp,
    required this.completedTasks,
  });
}

/// Immutable, recomputable statistics used by desktop and mobile surfaces.
///
/// The snapshot retains only the effective entries for one week and scalar
/// skill aggregates. It never owns or mutates AppState collections.
class AnalyticsReadModel {
  final DateTime weekStart;
  final List<AnalyticsDaySummary> days;
  final List<AnalyticsHistoryRecord> entries;
  final List<AnalyticsSkillSummary> skills;
  final Map<String, AnalyticsSkillSummary> _skillsById;
  final AnalyticsSkillSummary? _leadingSkill;
  final AnalyticsActivityLeader? activityLeader;
  final int todayXp;
  final int todayCompletedTasks;
  final int totalCompletions;

  const AnalyticsReadModel._({
    required this.weekStart,
    required this.days,
    required this.entries,
    required this.skills,
    required Map<String, AnalyticsSkillSummary> skillsById,
    required AnalyticsSkillSummary? leadingSkill,
    required this.activityLeader,
    required this.todayXp,
    required this.todayCompletedTasks,
    required this.totalCompletions,
  }) : _skillsById = skillsById,
       _leadingSkill = leadingSkill;

  int get totalXp => days.fold(0, (sum, day) => sum + day.xp);

  int get completedTasks => entries.length;

  int get activeDays => days.where((day) => day.completedTasks > 0).length;

  int get averageXpPerActiveDay =>
      activeDays == 0 ? 0 : (totalXp / activeDays).round();

  AnalyticsSkillSummary? get leadingSkill => _leadingSkill;

  AnalyticsSkillSummary? skillById(String id) => _skillsById[id];

  AnalyticsDaySummary? dayFor(DateTime date) {
    final normalized = dateOnly(date);
    return days.where((day) => day.date == normalized).firstOrNull;
  }

  factory AnalyticsReadModel.build({
    required DateTime weekStart,
    required Map<DateTime, List<HistoryEntry>> completionHistoryByDate,
    required Iterable<Skill> skills,
    required Iterable<Task> tasks,
    required DailyStats? todayStats,
    required int totalCompletions,
  }) {
    final normalizedStart = startOfWeek(weekStart);
    final daySummaries = <AnalyticsDaySummary>[];
    final weekEntries = <HistoryEntry>[];
    final weeklyXpBySkill = <String, int>{};
    final weeklyTasksBySkill = <String, int>{};
    final latestEntryBySkill = <String, HistoryEntry>{};

    for (var index = 0; index < 7; index++) {
      final day = dateOnly(normalizedStart.add(Duration(days: index)));
      final entries = completionHistoryByDate[day] ?? const <HistoryEntry>[];
      var dayXp = 0;
      for (final entry in entries) {
        dayXp += entry.xp;
        weeklyXpBySkill.update(
          entry.skillId,
          (value) => value + entry.xp,
          ifAbsent: () => entry.xp,
        );
        weeklyTasksBySkill.update(
          entry.skillId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        final latest = latestEntryBySkill[entry.skillId];
        if (latest == null || entry.at.isAfter(latest.at)) {
          latestEntryBySkill[entry.skillId] = entry;
        }
      }
      daySummaries.add(
        AnalyticsDaySummary(
          date: day,
          xp: dayXp,
          completedTasks: entries.length,
        ),
      );
      weekEntries.addAll(entries);
    }
    weekEntries.sort((a, b) => b.at.compareTo(a.at));

    final activeTasksBySkill = <String, int>{};
    final totalTasksBySkill = <String, int>{};
    for (final task in tasks) {
      if (!task.isSkillTask) continue;
      totalTasksBySkill.update(
        task.skillId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if (!task.isDone) {
        activeTasksBySkill.update(
          task.skillId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    const goalProgress = GoalProgressEngine();
    final skillSummaries = <AnalyticsSkillSummary>[];
    final currentSkillIds = <String>{};
    for (final skill in skills) {
      if (skill.id == kInboxSkillId) continue;
      currentSkillIds.add(skill.id);
      final progress = goalProgress.snapshotForSkill(skill);
      skillSummaries.add(
        AnalyticsSkillSummary(
          skillId: skill.id,
          name: skill.name,
          weeklyXp: weeklyXpBySkill[skill.id] ?? 0,
          completedTasks: weeklyTasksBySkill[skill.id] ?? 0,
          activeTasks: activeTasksBySkill[skill.id] ?? 0,
          totalTasks: totalTasksBySkill[skill.id] ?? 0,
          completedStages: progress.completedStages,
          totalStages: progress.totalStages,
          goalProgress: progress.value,
          isExistingSkill: true,
        ),
      );
    }
    AnalyticsSkillSummary? leadingSkill;
    for (final summary in skillSummaries) {
      if (summary.weeklyXp <= 0) continue;
      if (leadingSkill == null ||
          _compareSkillActivity(summary, leadingSkill) < 0) {
        leadingSkill = summary;
      }
    }

    // Weekly history remains visible after a skill is deleted. Identity comes
    // from the latest immutable history entry, matching the legacy summary.
    for (final entry in latestEntryBySkill.entries) {
      if (entry.key == kInboxSkillId || currentSkillIds.contains(entry.key)) {
        continue;
      }
      final source = entry.value;
      skillSummaries.add(
        AnalyticsSkillSummary(
          skillId: entry.key,
          name: source.skillName,
          weeklyXp: weeklyXpBySkill[entry.key] ?? 0,
          completedTasks: weeklyTasksBySkill[entry.key] ?? 0,
          activeTasks: 0,
          totalTasks: 0,
          completedStages: 0,
          totalStages: 0,
          goalProgress: 0,
          isExistingSkill: false,
        ),
      );
    }
    skillSummaries.sort((a, b) {
      final byXp = b.weeklyXp.compareTo(a.weeklyXp);
      if (byXp != 0) return byXp;
      return a.name.compareTo(b.name);
    });

    final immutableSkillSummaries = List<AnalyticsSkillSummary>.unmodifiable(
      skillSummaries,
    );
    AnalyticsActivityLeader? activityLeader;
    for (final entry in latestEntryBySkill.entries) {
      final source = entry.value;
      final candidate = AnalyticsActivityLeader(
        skillId: entry.key,
        name: source.skillName,
        xp: weeklyXpBySkill[entry.key] ?? 0,
        completedTasks: weeklyTasksBySkill[entry.key] ?? 0,
      );
      if (activityLeader == null ||
          _compareActivity(candidate, activityLeader) < 0) {
        activityLeader = candidate;
      }
    }
    return AnalyticsReadModel._(
      weekStart: normalizedStart,
      days: List.unmodifiable(daySummaries),
      entries: List.unmodifiable(
        weekEntries.map(AnalyticsHistoryRecord.fromEntry),
      ),
      skills: immutableSkillSummaries,
      skillsById: Map<String, AnalyticsSkillSummary>.unmodifiable({
        for (final summary in immutableSkillSummaries) summary.skillId: summary,
      }),
      leadingSkill: leadingSkill,
      activityLeader: activityLeader,
      todayXp: todayStats?.xpEarned ?? 0,
      todayCompletedTasks: todayStats?.tasksCompleted ?? 0,
      totalCompletions: totalCompletions,
    );
  }

  static int _compareActivity(
    AnalyticsActivityLeader left,
    AnalyticsActivityLeader right,
  ) {
    final byXp = right.xp.compareTo(left.xp);
    if (byXp != 0) return byXp;
    final byTasks = right.completedTasks.compareTo(left.completedTasks);
    if (byTasks != 0) return byTasks;
    final byName = left.name.compareTo(right.name);
    if (byName != 0) return byName;
    return left.skillId.compareTo(right.skillId);
  }

  static int _compareSkillActivity(
    AnalyticsSkillSummary left,
    AnalyticsSkillSummary right,
  ) {
    final byXp = right.weeklyXp.compareTo(left.weeklyXp);
    if (byXp != 0) return byXp;
    final byTasks = right.completedTasks.compareTo(left.completedTasks);
    if (byTasks != 0) return byTasks;
    final byName = left.name.compareTo(right.name);
    if (byName != 0) return byName;
    return left.skillId.compareTo(right.skillId);
  }
}

/// Bounded cache keyed by the AppState analytics epoch and normalized week.
///
/// AppState advances the epoch for task, skill, RoadMap, daily-stat, and
/// completion-history mutations. Unrelated theme/profile changes therefore do
/// not rebuild statistics. The small bound prevents historical week browsing
/// from retaining an unbounded set of entry lists.
class AnalyticsReadModelCache {
  static const int _maxWeeks = 8;

  int? _epoch;
  final Map<DateTime, AnalyticsReadModel> _weeks = {};

  AnalyticsReadModel resolve({
    required int epoch,
    required DateTime weekStart,
    required AnalyticsReadModel Function(DateTime normalizedWeekStart) build,
  }) {
    if (_epoch != epoch) {
      _weeks.clear();
      _epoch = epoch;
    }
    final normalized = startOfWeek(weekStart);
    final cached = _weeks.remove(normalized);
    if (cached != null) {
      _weeks[normalized] = cached;
      return cached;
    }
    final snapshot = build(normalized);
    _weeks[normalized] = snapshot;
    if (_weeks.length > _maxWeeks) {
      _weeks.remove(_weeks.keys.first);
    }
    return snapshot;
  }

  void invalidate() {
    _epoch = null;
    _weeks.clear();
  }
}
