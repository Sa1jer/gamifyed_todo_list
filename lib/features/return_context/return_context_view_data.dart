import '../../app_state.dart';
import '../../engines/next_action_resolver.dart';
import '../../engines/return_context_resolver.dart';
import '../../models/task_models.dart';

class ReturnContextNavigationTarget {
  const ReturnContextNavigationTarget({
    required this.skillId,
    this.taskId,
    this.stageId,
  });

  final String skillId;
  final String? taskId;
  final String? stageId;
}

/// Projects live AppState data into detached records and delegates selection to
/// the pure ReturnContextResolver.
class ReturnContextViewDataBuilder {
  const ReturnContextViewDataBuilder({
    this.resolver = const ReturnContextResolver(),
    this.nextActionResolver = const NextActionResolver(),
  });

  final ReturnContextResolver resolver;
  final NextActionResolver nextActionResolver;

  ReturnContextCandidate? build({
    required AppState state,
    required DateTime now,
    Duration pauseThreshold = defaultReturnContextPauseThreshold,
  }) {
    if (!state.hasLoadedSavedData || state.persistenceStatus.blocksSaving) {
      return null;
    }

    final skills = state.roadmapSkills;
    final nextAction = nextActionResolver.resolve(
      skills: skills,
      tasks: state.tasks,
      selectedSkillId: state.selectedSkillId,
    );
    final actions = <ReturnContextActionRecord>[];
    for (var index = 0; index < nextAction.alternatives.length; index++) {
      final candidate = nextAction.alternatives[index];
      actions.add(
        ReturnContextActionRecord(
          taskId: candidate.task.id,
          taskTitle: candidate.task.title,
          skillId: candidate.skill.id,
          skillName: candidate.skill.name,
          actionLabel: candidate.actionText,
          sourceOrder: index,
          usesMinimumAction: candidate.usesMinimumAction,
          stageId: candidate.stage?.id,
          stageTitle: candidate.stage?.title,
        ),
      );
    }

    return resolver.resolve(
      ReturnContextInput(
        now: now,
        pauseThreshold: pauseThreshold,
        selectedSkillId: state.selectedSkillId,
        skills: skills.map(
          (skill) => ReturnContextSkillRecord(id: skill.id, name: skill.name),
        ),
        history: state.history.map(
          (entry) => ReturnContextHistoryRecord(
            id: entry.id,
            taskId: entry.taskId,
            taskTitle: entry.taskTitle,
            skillId: entry.skillId,
            skillName: entry.skillName,
            at: entry.at,
            isCompletion: entry.isCompletion,
            isInbox: entry.skillId == kInboxSkillId,
          ),
        ),
        reviews: skills.expand(
          (skill) => skill.goalSpec.reviews.map(
            (review) => ReturnContextReviewRecord(
              id: review.id,
              skillId: skill.id,
              skillName: skill.name,
              at: review.createdAt,
              wins: review.wins,
              nextFocus: review.nextFocus,
              isMeaningful: <String>[
                review.wins,
                review.blockers,
                review.adjustment,
                review.nextFocus,
              ].any((value) => value.trim().isNotEmpty),
            ),
          ),
        ),
        actions: actions,
      ),
    );
  }

  ReturnContextNavigationTarget? revalidate({
    required AppState state,
    required ReturnContextCandidate rendered,
  }) {
    final skill = state.roadmapSkills
        .where((candidate) => candidate.id == rendered.skillId)
        .firstOrNull;
    if (skill == null) return null;

    final resolution = nextActionResolver.resolve(
      skills: state.roadmapSkills,
      tasks: state.tasks,
      selectedSkillId: skill.id,
      explicitTaskId: rendered.taskId,
    );
    final action = resolution.alternatives
        .where((candidate) => candidate.skill.id == skill.id)
        .firstOrNull;
    return ReturnContextNavigationTarget(
      skillId: skill.id,
      taskId: action?.task.id,
      stageId: action?.stage?.id,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
