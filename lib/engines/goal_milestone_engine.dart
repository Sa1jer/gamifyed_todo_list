import '../models.dart';

class GoalMilestoneEngine {
  const GoalMilestoneEngine();

  List<GoalMilestone> crossedMilestones({
    required double oldProgress,
    required double newProgress,
    Iterable<int> alreadyTriggered = const [],
  }) {
    final oldValue = oldProgress.clamp(0.0, 1.0).toDouble();
    final newValue = newProgress.clamp(0.0, 1.0).toDouble();
    final triggered = alreadyTriggered.toSet();

    return GoalMilestone.values
        .where(
          (milestone) =>
              !triggered.contains(milestone.percent) &&
              oldValue < milestone.threshold &&
              newValue >= milestone.threshold,
        )
        .toList(growable: false);
  }
}
