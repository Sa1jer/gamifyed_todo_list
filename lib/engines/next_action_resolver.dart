import '../models/skill_models.dart';
import '../models/task_models.dart';
import 'task_ordering.dart';

/// A presentation-only answer to "what can I do now?".
///
/// This resolver intentionally never mutates Task, Skill, AppState, or storage.
/// Task completion and Minimum Action completion remain the existing AppState
/// flows with their own XP and RoadMap semantics.
enum NextActionReason {
  explicitOverride,
  selectedSkillActiveStage,
  selectedSkill,
  activeStage,
  availableTask,
}

enum NextActionEmptyState { noSkills, selectedSkillWithoutTasks, noTasks }

class NextActionCandidate {
  const NextActionCandidate({
    required this.task,
    required this.skill,
    required this.reason,
    this.stage,
  });

  final Task task;
  final Skill skill;
  final SkillTreeNode? stage;
  final NextActionReason reason;

  bool get usesMinimumAction =>
      task.hasMinimumAction && !task.isMinimumActionDone;

  String get actionText =>
      usesMinimumAction ? task.minimumAction.trim() : task.title;
}

class NextActionResolution {
  const NextActionResolution._({
    required this.candidate,
    required this.alternatives,
    this.emptyState,
    this.suggestedSkill,
  });

  const NextActionResolution.candidate({
    required NextActionCandidate candidate,
    required List<NextActionCandidate> alternatives,
  }) : this._(candidate: candidate, alternatives: alternatives);

  const NextActionResolution.empty({
    required this.emptyState,
    this.suggestedSkill,
  }) : candidate = null,
       alternatives = const <NextActionCandidate>[];

  final NextActionCandidate? candidate;
  final List<NextActionCandidate> alternatives;
  final NextActionEmptyState? emptyState;
  final Skill? suggestedSkill;
}

/// A temporary, user-editable work-entry loop around one real Task.
///
/// It is intentionally session-only. Completing this plan must not be wired to
/// task completion, Minimum Action completion, XP, history, or RoadMap state.
class BootEntryPlan {
  const BootEntryPlan({
    required this.parentTaskId,
    required this.parentSkillId,
    required this.parentTaskTitle,
    required this.openContext,
    required this.smallChange,
    required this.inspectResult,
  });

  final String parentTaskId;
  final String parentSkillId;
  final String parentTaskTitle;
  final String openContext;
  final String smallChange;
  final String inspectResult;

  bool get isReady => smallChange.trim().isNotEmpty;

  factory BootEntryPlan.suggest(Task task) {
    return BootEntryPlan(
      parentTaskId: task.id,
      parentSkillId: task.skillId,
      parentTaskTitle: task.title,
      openContext: 'Открой квест и всё, что нужно для шага',
      smallChange: task.hasMinimumAction && !task.isMinimumActionDone
          ? task.minimumAction.trim()
          : '',
      inspectResult: 'Посмотри, что изменилось после шага',
    );
  }

  BootEntryPlan copyWith({
    String? openContext,
    String? smallChange,
    String? inspectResult,
  }) {
    return BootEntryPlan(
      parentTaskId: parentTaskId,
      parentSkillId: parentSkillId,
      parentTaskTitle: parentTaskTitle,
      openContext: openContext ?? this.openContext,
      smallChange: smallChange ?? this.smallChange,
      inspectResult: inspectResult ?? this.inspectResult,
    );
  }
}

class NextActionResolver {
  const NextActionResolver();

  NextActionResolution resolve({
    required Iterable<Skill> skills,
    required Iterable<Task> tasks,
    String? selectedSkillId,
    String? explicitTaskId,
  }) {
    final orderedSkills = skills
        .where((skill) => skill.id != kInboxSkillId)
        .toList();
    final skillsById = {for (final skill in orderedSkills) skill.id: skill};
    if (orderedSkills.isEmpty) {
      return const NextActionResolution.empty(
        emptyState: NextActionEmptyState.noSkills,
      );
    }

    final selectedSkill = selectedSkillId == null
        ? null
        : skillsById[selectedSkillId];
    final candidates = <_IndexedCandidate>[];
    var index = 0;
    for (final task in tasks) {
      final taskIndex = index++;
      final skill = skillsById[task.skillId];
      if (skill == null || task.isDone || !task.isSkillTask) continue;
      if (task.title.trim().isEmpty) continue;

      final stage = _usableStageFor(skill, task);
      if (task.treeNodeId != null &&
          task.treeNodeId!.trim().isNotEmpty &&
          stage == null) {
        // A task attached to a missing or locked stage is not a safe "do now"
        // recommendation. It remains visible in its normal task surface.
        continue;
      }

      final reason = _reasonFor(
        skill: skill,
        selectedSkill: selectedSkill,
        stage: stage,
      );
      candidates.add(
        _IndexedCandidate(
          candidate: NextActionCandidate(
            task: task,
            skill: skill,
            stage: stage,
            reason: reason,
          ),
          sourceIndex: taskIndex,
        ),
      );
    }

    if (candidates.isEmpty) {
      return NextActionResolution.empty(
        emptyState: selectedSkill == null
            ? NextActionEmptyState.noTasks
            : NextActionEmptyState.selectedSkillWithoutTasks,
        suggestedSkill: selectedSkill ?? orderedSkills.first,
      );
    }

    candidates.sort(_compareCandidates);
    final alternatives = candidates.map((entry) => entry.candidate).toList();
    final override = explicitTaskId == null
        ? null
        : alternatives
              .where((candidate) => candidate.task.id == explicitTaskId)
              .firstOrNull;
    if (override != null) {
      return NextActionResolution.candidate(
        candidate: NextActionCandidate(
          task: override.task,
          skill: override.skill,
          stage: override.stage,
          reason: NextActionReason.explicitOverride,
        ),
        alternatives: alternatives,
      );
    }

    return NextActionResolution.candidate(
      candidate: alternatives.first,
      alternatives: alternatives,
    );
  }

  SkillTreeNode? _usableStageFor(Skill skill, Task task) {
    final stageId = task.treeNodeId?.trim();
    if (stageId == null || stageId.isEmpty) return null;
    final stage = skill.treeNodes
        .where((node) => node.id == stageId)
        .firstOrNull;
    if (stage == null) return null;
    return skill.treeNodeStatus(stage) == SkillTreeNodeStatus.active
        ? stage
        : null;
  }

  NextActionReason _reasonFor({
    required Skill skill,
    required Skill? selectedSkill,
    required SkillTreeNode? stage,
  }) {
    if (selectedSkill?.id == skill.id && stage != null) {
      return NextActionReason.selectedSkillActiveStage;
    }
    if (selectedSkill?.id == skill.id) return NextActionReason.selectedSkill;
    if (stage != null) return NextActionReason.activeStage;
    return NextActionReason.availableTask;
  }

  int _compareCandidates(_IndexedCandidate a, _IndexedCandidate b) {
    final byContext = _reasonRank(
      a.candidate.reason,
    ).compareTo(_reasonRank(b.candidate.reason));
    if (byContext != 0) return byContext;
    final byPriority = prioritySortRank(
      a.candidate.task.priority,
    ).compareTo(prioritySortRank(b.candidate.task.priority));
    if (byPriority != 0) return byPriority;
    final bySourceOrder = a.sourceIndex.compareTo(b.sourceIndex);
    if (bySourceOrder != 0) return bySourceOrder;
    return a.candidate.task.id.compareTo(b.candidate.task.id);
  }

  int _reasonRank(NextActionReason reason) => switch (reason) {
    NextActionReason.explicitOverride => -1,
    NextActionReason.selectedSkillActiveStage => 0,
    NextActionReason.selectedSkill => 1,
    NextActionReason.activeStage => 2,
    NextActionReason.availableTask => 3,
  };
}

class _IndexedCandidate {
  const _IndexedCandidate({required this.candidate, required this.sourceIndex});

  final NextActionCandidate candidate;
  final int sourceIndex;
}
