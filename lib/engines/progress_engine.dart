import '../models.dart';
import 'roadmap_engine.dart';

enum ProgressBasis { metric, roadmap, skillLevel }

class SkillProgressSnapshot {
  final Skill skill;
  final double percent;
  final ProgressBasis basis;
  final SkillTreeNode? currentStage;
  final int weeklyDelta;
  final int weeklyQuestCount;
  final List<HistoryEntry> recentWins;
  final bool needsAdjust;
  final DateTime? lastProgressAt;

  const SkillProgressSnapshot({
    required this.skill,
    required this.percent,
    required this.basis,
    required this.currentStage,
    required this.weeklyDelta,
    required this.weeklyQuestCount,
    required this.recentWins,
    required this.needsAdjust,
    required this.lastProgressAt,
  });

  String get percentLabel => '${(percent * 100).round()}%';

  String get basisLabel => switch (basis) {
    ProgressBasis.metric => 'по цели',
    ProgressBasis.roadmap => 'по этапам',
    ProgressBasis.skillLevel => 'по уровню',
  };
}

class ProgressSnapshot {
  final List<SkillProgressSnapshot> skills;

  const ProgressSnapshot({required this.skills});

  bool get isEmpty => skills.isEmpty;

  List<SkillProgressSnapshot> get visibleGoals => skills.take(3).toList();

  List<SkillProgressSnapshot> get needsReview =>
      skills.where((snapshot) => snapshot.needsAdjust).toList();
}

class ProgressEngine {
  static const Duration recentWindow = Duration(days: 7);
  static const Duration stalledWindow = Duration(days: 14);

  final RoadmapEngine roadmapEngine;

  const ProgressEngine({this.roadmapEngine = const RoadmapEngine()});

  ProgressSnapshot buildSnapshot(
    Iterable<Skill> skills,
    Iterable<HistoryEntry> history, {
    DateTime? now,
  }) {
    final snapshots =
        skills
            .map((skill) => snapshotForSkill(skill, history, now: now))
            .toList()
          ..sort(_compareSnapshots);
    return ProgressSnapshot(skills: snapshots);
  }

  SkillProgressSnapshot snapshotForSkill(
    Skill skill,
    Iterable<HistoryEntry> history, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final entries =
        history
            .where((entry) => entry.isCompletion)
            .where((entry) => entry.skillId == skill.id)
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));
    final recentWins = entries
        .where((entry) => !entry.at.isBefore(reference.subtract(recentWindow)))
        .toList();
    final roadmap = roadmapEngine.buildSnapshot(skill);
    final progress = _progressFor(skill, roadmap);
    final lastProgressAt = entries.firstOrNull?.at;

    return SkillProgressSnapshot(
      skill: skill,
      percent: progress.percent,
      basis: progress.basis,
      currentStage: roadmap.currentStage?.node,
      weeklyDelta: recentWins.fold<int>(0, (sum, entry) => sum + entry.xp),
      weeklyQuestCount: recentWins.length,
      recentWins: recentWins.take(3).toList(),
      needsAdjust: _needsAdjust(skill, lastProgressAt, reference),
      lastProgressAt: lastProgressAt,
    );
  }

  ({double percent, ProgressBasis basis}) _progressFor(
    Skill skill,
    RoadmapSnapshot roadmap,
  ) {
    final target = skill.goalSpec.targetValue;
    final current = skill.goalSpec.currentValue;
    if (target != null && target > 0 && current != null) {
      return (
        percent: (current / target).clamp(0.0, 1.0),
        basis: ProgressBasis.metric,
      );
    }
    if (!roadmap.isEmpty) {
      return (
        percent: roadmap.overallProgress.clamp(0.0, 1.0),
        basis: ProgressBasis.roadmap,
      );
    }
    return (
      percent: skill.progress.clamp(0.0, 1.0),
      basis: ProgressBasis.skillLevel,
    );
  }

  bool _needsAdjust(Skill skill, DateTime? lastProgressAt, DateTime now) {
    if (skill.goal.trim().isEmpty) return false;
    final anchor = lastProgressAt ?? skill.goalSpec.updatedAt;
    final hasFreshReview = skill.goalSpec.reviews.any(
      (review) => !review.createdAt.isBefore(now.subtract(stalledWindow)),
    );
    return anchor.isBefore(now.subtract(stalledWindow)) && !hasFreshReview;
  }

  int _compareSnapshots(SkillProgressSnapshot a, SkillProgressSnapshot b) {
    final byAdjust = a.needsAdjust == b.needsAdjust
        ? 0
        : (a.needsAdjust ? -1 : 1);
    if (byAdjust != 0) return byAdjust;

    final byWeek = b.weeklyDelta.compareTo(a.weeklyDelta);
    if (byWeek != 0) return byWeek;

    final byPercent = a.percent.compareTo(b.percent);
    if (byPercent != 0) return byPercent;

    return a.skill.name.compareTo(b.skill.name);
  }
}
