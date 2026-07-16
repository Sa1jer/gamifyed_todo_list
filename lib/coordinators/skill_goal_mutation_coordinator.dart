import '../engines/goal_progress_engine.dart';
import '../models/reward_models.dart';
import '../models/skill_models.dart';
import '../models/task_models.dart';

enum NextGoalUpdateResult {
  updated,
  invalid,
  unchanged,
  notCompleted,
  notFound,
}

enum StartNewRoadmapResult {
  created,
  notFound,
  noCompletedGoal,
  noStages,
  notCompleted,
}

class SkillRemovalResult {
  const SkillRemovalResult({
    required this.changed,
    this.removedTaskIds = const [],
    this.clearsSelection = false,
  });

  final bool changed;
  final List<String> removedTaskIds;
  final bool clearsSelection;
}

/// Owns cohesive Skill and Goal mutations without persistence or notifications.
class SkillGoalMutationCoordinator {
  const SkillGoalMutationCoordinator();

  bool add({required List<Skill> skills, required Skill skill}) {
    if (skill.id == kInboxSkillId ||
        skills.any((item) => item.id == skill.id)) {
      return false;
    }
    skill.syncChecklistDone();
    skill.syncTreeNodes();
    final inboxIndex = skills.indexWhere((item) => item.id == kInboxSkillId);
    if (inboxIndex == -1) {
      skills.add(skill);
    } else {
      skills.insert(inboxIndex, skill);
    }
    return true;
  }

  bool reorder({
    required List<Skill> skills,
    required int oldIndex,
    required int newIndex,
  }) {
    if (oldIndex < 0 ||
        oldIndex >= skills.length ||
        newIndex < 0 ||
        newIndex >= skills.length ||
        newIndex == oldIndex ||
        skills[oldIndex].id == kInboxSkillId) {
      return false;
    }

    final skill = skills.removeAt(oldIndex);
    skills.insert(newIndex, skill);
    final inboxIndex = skills.indexWhere((item) => item.id == kInboxSkillId);
    if (inboxIndex != -1 && inboxIndex != skills.length - 1) {
      skills.add(skills.removeAt(inboxIndex));
    }
    return true;
  }

  bool update({
    required Skill skill,
    required String name,
    required String goal,
    required List<String> checklist,
  }) {
    if (skill.id == kInboxSkillId) return false;
    skill.name = name;
    skill.goal = goal;
    skill.checklist = List.of(checklist);
    skill.syncChecklistDone();
    skill.syncTreeNodes();
    return true;
  }

  NextGoalUpdateResult setNextGoal({
    required Skill? skill,
    required String nextGoal,
    required String Function() idFactory,
    required DateTime completedAt,
  }) {
    final normalizedGoal = nextGoal.trim();
    if (normalizedGoal.isEmpty) return NextGoalUpdateResult.invalid;
    if (skill == null) return NextGoalUpdateResult.notFound;

    final progress = const GoalProgressEngine().snapshotForSkill(skill);
    if (!progress.isComplete) return NextGoalUpdateResult.notCompleted;
    if (normalizedGoal == skill.goal.trim()) {
      return NextGoalUpdateResult.unchanged;
    }

    final previousGoal = skill.goal.trim();
    if (previousGoal.isNotEmpty) {
      skill.completedGoals.insert(
        0,
        CompletedGoal(
          id: idFactory(),
          skillId: skill.id,
          goalText: previousGoal,
          completedAt: completedAt,
          progressAtCompletion: progress.value,
          completedStages: progress.completedStages,
          totalStages: progress.totalStages,
        ),
      );
    }
    skill.goal = normalizedGoal;
    skill.triggeredGoalMilestones.clear();
    return NextGoalUpdateResult.updated;
  }

  StartNewRoadmapResult startNewRoadmap({
    required Skill? skill,
    required List<Task> tasks,
    required String Function() idFactory,
    required DateTime now,
  }) {
    if (skill == null) return StartNewRoadmapResult.notFound;
    if (skill.treeNodes.isEmpty) return StartNewRoadmapResult.noStages;

    final progress = const GoalProgressEngine().snapshotForSkill(skill);
    if (!progress.isComplete) return StartNewRoadmapResult.notCompleted;
    final completedGoal = skill.completedGoals.firstOrNull;
    if (completedGoal == null) return StartNewRoadmapResult.noCompletedGoal;

    final archivedNodeIds = skill.treeNodes.map((node) => node.id).toSet();
    skill.completedRoadmaps.insert(
      0,
      CompletedRoadmap(
        id: idFactory(),
        skillId: skill.id,
        completedGoalId: completedGoal.id,
        goalText: completedGoal.goalText,
        completedAt: completedGoal.completedAt,
        progressAtCompletion: progress.value,
        completedStages: progress.completedStages,
        totalStages: progress.totalStages,
        stages: skill.treeNodes.map(RoadmapStageSnapshot.fromNode),
      ),
    );

    for (final task in tasks.where(
      (task) =>
          task.isSkillTask &&
          task.skillId == skill.id &&
          task.treeNodeId != null &&
          archivedNodeIds.contains(task.treeNodeId),
    )) {
      task.treeNodeId = null;
      task.updatedAt = now;
    }
    skill.treeNodes.clear();
    skill.syncTreeNodes();
    return StartNewRoadmapResult.created;
  }

  SkillRemovalResult remove({
    required String skillId,
    required List<Skill> skills,
    required List<Task> tasks,
    required List<Boss> bosses,
    required List<RewardChest> rewardChests,
    required List<Buff> buffs,
    required String? selectedSkillId,
  }) {
    if (skillId == kInboxSkillId || !skills.any((s) => s.id == skillId)) {
      return const SkillRemovalResult(changed: false);
    }
    final removedTaskIds = tasks
        .where((task) => task.isSkillTask && task.skillId == skillId)
        .map((task) => task.id)
        .toList(growable: false);
    skills.removeWhere((skill) => skill.id == skillId);
    tasks.removeWhere((task) => task.isSkillTask && task.skillId == skillId);
    bosses.removeWhere((boss) => boss.skillId == skillId);
    rewardChests.removeWhere((chest) => chest.skillId == skillId);
    buffs.removeWhere((buff) => buff.skillId == skillId);
    return SkillRemovalResult(
      changed: true,
      removedTaskIds: removedTaskIds,
      clearsSelection: selectedSkillId == skillId,
    );
  }
}
