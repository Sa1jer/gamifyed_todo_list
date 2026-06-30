import '../models.dart';

class GoalProgressSnapshot {
  final int completedStages;
  final int totalStages;
  final double value;

  const GoalProgressSnapshot({
    required this.completedStages,
    required this.totalStages,
    required this.value,
  });

  bool get isEmpty => totalStages == 0;

  bool get isComplete => totalStages > 0 && completedStages == totalStages;

  String get percentLabel => '${(value * 100).round()}%';
}

class GoalProgressEngine {
  const GoalProgressEngine();

  GoalProgressSnapshot snapshotForSkill(Skill skill) {
    return snapshotForStages(skill.treeNodes);
  }

  GoalProgressSnapshot snapshotForStages(Iterable<SkillTreeNode> stages) {
    final uniqueStages = <String, SkillTreeNode>{};
    for (final stage in stages) {
      uniqueStages.putIfAbsent(stage.id, () => stage);
    }

    return snapshotFromCounts(
      completedStages: uniqueStages.values
          .where((stage) => stage.isMastered)
          .length,
      totalStages: uniqueStages.length,
    );
  }

  GoalProgressSnapshot snapshotFromCounts({
    required int completedStages,
    required int totalStages,
  }) {
    final safeTotal = totalStages < 0 ? 0 : totalStages;
    final safeCompleted = completedStages.clamp(0, safeTotal).toInt();
    final value = safeTotal == 0
        ? 0.0
        : (safeCompleted / safeTotal).clamp(0.0, 1.0);

    return GoalProgressSnapshot(
      completedStages: safeCompleted,
      totalStages: safeTotal,
      value: value,
    );
  }
}
