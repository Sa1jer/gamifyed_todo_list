import '../../app_state.dart';
import '../../engines/goal_progress_engine.dart';
import '../../engines/momentum_resolver.dart';
import '../../engines/next_action_resolver.dart';
import '../../engines/return_context_resolver.dart';
import '../../engines/roadmap_engine.dart';
import '../../models/task_models.dart';

MomentumSnapshot? buildMomentumViewData(
  AppState state,
  DateTime now,
  ReturnContextCandidate? returnContext,
) => const MomentumViewDataBuilder().build(
  state: state,
  now: now,
  returnContext: returnContext,
);

/// Projects live application state into detached facts for MomentumResolver.
///
/// All progress and action ordering remain owned by the existing engines. This
/// builder has no mutation, notification, or persistence responsibility.
class MomentumViewDataBuilder {
  const MomentumViewDataBuilder({
    this.resolver = const MomentumResolver(),
    this.nextActionResolver = const NextActionResolver(),
    this.goalProgressEngine = const GoalProgressEngine(),
    this.roadmapEngine = const RoadmapEngine(),
  });

  final MomentumResolver resolver;
  final NextActionResolver nextActionResolver;
  final GoalProgressEngine goalProgressEngine;
  final RoadmapEngine roadmapEngine;

  MomentumSnapshot? build({
    required AppState state,
    required DateTime now,
    ReturnContextCandidate? returnContext,
  }) {
    if (!state.hasLoadedSavedData || state.persistenceStatus.blocksSaving) {
      return null;
    }

    final skills = state.roadmapSkills;
    final resolution = nextActionResolver.resolve(
      skills: skills,
      tasks: state.tasks,
      selectedSkillId: state.selectedSkillId,
    );
    final actions = <MomentumActionRecord>[];
    for (var index = 0; index < resolution.alternatives.length; index++) {
      final candidate = resolution.alternatives[index];
      actions.add(
        MomentumActionRecord(
          taskId: candidate.task.id,
          taskTitle: candidate.task.title,
          skillId: candidate.skill.id,
          skillName: candidate.skill.name,
          actionLabel: candidate.actionText,
          sourceOrder: index,
          usesMinimumAction: candidate.usesMinimumAction,
          stageId: candidate.stage?.id,
        ),
      );
    }

    final skillRecords = <MomentumSkillRecord>[];
    final stageRecords = <MomentumStageRecord>[];
    for (final skill in skills) {
      final goal = goalProgressEngine.snapshotForSkill(skill);
      skillRecords.add(
        MomentumSkillRecord(
          skillId: skill.id,
          skillName: skill.name,
          goalProgress: goal.value,
          goalCompleted: goal.isComplete,
        ),
      );

      final completedCounts = <String, int>{
        for (final node in skill.treeNodes)
          node.id: state.completedTasksForTreeNode(skill.id, node.id),
      };
      final roadmap = roadmapEngine.buildSnapshot(
        skill,
        completedQuestCountsByNodeId: completedCounts,
      );
      stageRecords.addAll(
        roadmap.stages.map(
          (stage) => MomentumStageRecord(
            skillId: skill.id,
            stageId: stage.node.id,
            stageTitle: stage.node.title,
            role: _stageRole(stage.role),
            progress: stage.progress,
            completedQuestCount: stage.completedLinkedQuests,
            requiredQuestCount: stage.questTarget,
            completedAt: stage.node.masteredAt,
          ),
        ),
      );
    }

    return resolver.resolve(
      MomentumInput(
        now: now,
        selectedSkillId: state.selectedSkillId,
        returnContextSkillId: returnContext?.skillId,
        skills: skillRecords,
        stages: stageRecords,
        actions: actions,
        existingTaskIds: state.tasks
            .where((task) => task.isSkillTask)
            .map((task) => task.id),
        history: state.history.map(
          (entry) => MomentumHistoryRecord(
            id: entry.id,
            taskId: entry.taskId,
            skillId: entry.skillId,
            at: entry.at,
            isCompletion: entry.isCompletion,
            isInbox: entry.skillId == kInboxSkillId,
          ),
        ),
      ),
    );
  }

  MomentumStageRole _stageRole(RoadmapStageRole role) => switch (role) {
    RoadmapStageRole.completed => MomentumStageRole.completed,
    RoadmapStageRole.current => MomentumStageRole.current,
    RoadmapStageRole.next => MomentumStageRole.next,
    RoadmapStageRole.locked => MomentumStageRole.locked,
  };
}
