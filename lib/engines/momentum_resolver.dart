const defaultMomentumRecentWindow = Duration(days: 7);
const momentumAdvancedGoalThreshold = 0.75;
const momentumNearStageThreshold = 0.67;

enum MomentumReason {
  stageOneQuestRemaining,
  completedStageContinuation,
  stageNearlyComplete,
  goalMeaningfullyAdvanced,
  recentRealProgress,
  minimumActionAvailable,
}

enum MomentumStageRole { completed, current, next, locked }

class MomentumSkillRecord {
  const MomentumSkillRecord({
    required this.skillId,
    required this.skillName,
    required this.goalProgress,
    required this.goalCompleted,
  });

  final String skillId;
  final String skillName;
  final double goalProgress;
  final bool goalCompleted;
}

class MomentumStageRecord {
  const MomentumStageRecord({
    required this.skillId,
    required this.stageId,
    required this.stageTitle,
    required this.role,
    required this.progress,
    required this.completedQuestCount,
    required this.requiredQuestCount,
    this.completedAt,
  });

  final String skillId;
  final String stageId;
  final String stageTitle;
  final MomentumStageRole role;
  final double progress;
  final int completedQuestCount;
  final int requiredQuestCount;
  final DateTime? completedAt;
}

class MomentumActionRecord {
  const MomentumActionRecord({
    required this.taskId,
    required this.taskTitle,
    required this.skillId,
    required this.skillName,
    required this.actionLabel,
    required this.sourceOrder,
    required this.usesMinimumAction,
    this.stageId,
  });

  final String taskId;
  final String taskTitle;
  final String skillId;
  final String skillName;
  final String actionLabel;
  final int sourceOrder;
  final bool usesMinimumAction;
  final String? stageId;
}

class MomentumHistoryRecord {
  const MomentumHistoryRecord({
    required this.id,
    required this.skillId,
    required this.at,
    required this.isCompletion,
    required this.isInbox,
    this.taskId,
  });

  final String id;
  final String skillId;
  final DateTime at;
  final bool isCompletion;
  final bool isInbox;
  final String? taskId;
}

class MomentumInput {
  MomentumInput({
    required this.now,
    required Iterable<MomentumSkillRecord> skills,
    required Iterable<MomentumStageRecord> stages,
    required Iterable<MomentumActionRecord> actions,
    required Iterable<MomentumHistoryRecord> history,
    required Iterable<String> existingTaskIds,
    this.selectedSkillId,
    this.returnContextSkillId,
    this.recentWindow = defaultMomentumRecentWindow,
  }) : skills = List<MomentumSkillRecord>.unmodifiable(skills),
       stages = List<MomentumStageRecord>.unmodifiable(stages),
       actions = List<MomentumActionRecord>.unmodifiable(actions),
       history = List<MomentumHistoryRecord>.unmodifiable(history),
       existingTaskIds = Set<String>.unmodifiable(existingTaskIds);

  final DateTime now;
  final List<MomentumSkillRecord> skills;
  final List<MomentumStageRecord> stages;
  final List<MomentumActionRecord> actions;
  final List<MomentumHistoryRecord> history;
  final Set<String> existingTaskIds;
  final String? selectedSkillId;
  final String? returnContextSkillId;
  final Duration recentWindow;
}

class MomentumSnapshot {
  const MomentumSnapshot({
    required this.key,
    required this.reason,
    required this.headline,
    required this.supportingText,
    required this.skillId,
    required this.skillName,
    required this.taskId,
    required this.actionLabel,
    this.stageId,
    this.evidenceAt,
    this.progressFraction,
    this.remainingCount,
  });

  final String key;
  final MomentumReason reason;
  final String headline;
  final String supportingText;
  final String skillId;
  final String skillName;
  final String taskId;
  final String actionLabel;
  final String? stageId;
  final DateTime? evidenceAt;
  final double? progressFraction;
  final int? remainingCount;

  @override
  bool operator ==(Object other) {
    return other is MomentumSnapshot &&
        other.key == key &&
        other.reason == reason &&
        other.headline == headline &&
        other.supportingText == supportingText &&
        other.skillId == skillId &&
        other.skillName == skillName &&
        other.taskId == taskId &&
        other.actionLabel == actionLabel &&
        other.stageId == stageId &&
        other.evidenceAt == evidenceAt &&
        other.progressFraction == progressFraction &&
        other.remainingCount == remainingCount;
  }

  @override
  int get hashCode => Object.hash(
    key,
    reason,
    headline,
    supportingText,
    skillId,
    skillName,
    taskId,
    actionLabel,
    stageId,
    evidenceAt,
    progressFraction,
    remainingCount,
  );
}

class MomentumResolver {
  const MomentumResolver();

  MomentumSnapshot? resolve(MomentumInput input) {
    if (input.recentWindow.isNegative || input.actions.isEmpty) return null;

    final skills = <String, MomentumSkillRecord>{
      for (final skill in input.skills)
        if (skill.skillId.trim().isNotEmpty) skill.skillId: skill,
    };
    if (skills.isEmpty) return null;
    final returnContextSkillId = skills.containsKey(input.returnContextSkillId)
        ? input.returnContextSkillId
        : null;

    final stagesBySkill = <String, List<MomentumStageRecord>>{};
    for (final stage in input.stages) {
      if (!skills.containsKey(stage.skillId) ||
          stage.stageId.trim().isEmpty ||
          stage.role == MomentumStageRole.locked) {
        continue;
      }
      stagesBySkill.putIfAbsent(stage.skillId, () => []).add(stage);
    }

    final recentBySkill = <String, MomentumHistoryRecord>{};
    for (final entry in input.history) {
      if (!entry.isCompletion ||
          entry.isInbox ||
          !skills.containsKey(entry.skillId) ||
          (entry.taskId != null &&
              !input.existingTaskIds.contains(entry.taskId))) {
        continue;
      }
      final elapsed = input.now.difference(entry.at);
      if (elapsed.isNegative || elapsed > input.recentWindow) continue;
      final current = recentBySkill[entry.skillId];
      if (current == null || entry.at.isAfter(current.at)) {
        recentBySkill[entry.skillId] = entry;
      }
    }

    final candidates = <_MomentumCandidate>[];
    for (final action in input.actions) {
      final skill = skills[action.skillId];
      if (skill == null ||
          (returnContextSkillId != null &&
              action.skillId != returnContextSkillId) ||
          action.taskId.trim().isEmpty ||
          !input.existingTaskIds.contains(action.taskId) ||
          action.actionLabel.trim().isEmpty) {
        continue;
      }
      final stages = stagesBySkill[action.skillId] ?? const [];
      final stage = action.stageId == null
          ? null
          : stages.where((item) => item.stageId == action.stageId).firstOrNull;
      final evidence = _strongestEvidence(
        input: input,
        skill: skill,
        action: action,
        stage: stage,
        stages: stages,
        recent: recentBySkill[action.skillId],
      );
      if (evidence != null) candidates.add(evidence);
    }
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => _compareCandidates(a, b, input));
    return candidates.first.snapshot;
  }

  _MomentumCandidate? _strongestEvidence({
    required MomentumInput input,
    required MomentumSkillRecord skill,
    required MomentumActionRecord action,
    required MomentumStageRecord? stage,
    required List<MomentumStageRecord> stages,
    required MomentumHistoryRecord? recent,
  }) {
    if (stage != null && stage.role == MomentumStageRole.current) {
      final required = stage.requiredQuestCount;
      final completed = required > 0
          ? stage.completedQuestCount.clamp(0, required)
          : 0;
      final remaining = required - completed;
      if (required > 0 && remaining == 1) {
        return _candidate(
          action,
          reason: MomentumReason.stageOneQuestRemaining,
          priority: 0,
          text: 'До завершения этапа «${stage.stageTitle}» остался один квест.',
          stageId: stage.stageId,
          progress: stage.progress,
          remaining: 1,
        );
      }
      if (required > 0 &&
          remaining > 1 &&
          stage.progress >= momentumNearStageThreshold) {
        return _candidate(
          action,
          reason: MomentumReason.stageNearlyComplete,
          priority: 2,
          text:
              'Этап «${stage.stageTitle}»: выполнено $completed из $required квестов.',
          stageId: stage.stageId,
          progress: stage.progress,
          remaining: remaining,
        );
      }
    }

    final completedStage = stages.where((item) {
      if (item.role != MomentumStageRole.completed ||
          item.completedAt == null) {
        return false;
      }
      final elapsed = input.now.difference(item.completedAt!);
      return !elapsed.isNegative && elapsed <= input.recentWindow;
    }).toList()..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    if (completedStage.isNotEmpty &&
        stages.any(
          (item) =>
              item.role == MomentumStageRole.current ||
              item.role == MomentumStageRole.next,
        )) {
      final mastered = completedStage.first;
      return _candidate(
        action,
        reason: MomentumReason.completedStageContinuation,
        priority: 1,
        text:
            'Этап «${mastered.stageTitle}» завершён — путь продолжается отсюда.',
        stageId: action.stageId,
      );
    }

    if (!skill.goalCompleted &&
        skill.goalProgress >= momentumAdvancedGoalThreshold &&
        skill.goalProgress < 1) {
      return _candidate(
        action,
        reason: MomentumReason.goalMeaningfullyAdvanced,
        priority: 3,
        text: 'Большая часть пути к этой цели уже пройдена.',
        stageId: action.stageId,
        progress: skill.goalProgress,
      );
    }

    if (recent != null) {
      return _candidate(
        action,
        reason: MomentumReason.recentRealProgress,
        priority: 4,
        text: 'Здесь уже есть недавний завершённый квест.',
        stageId: action.stageId,
        evidenceAt: recent.at,
      );
    }

    if (action.usesMinimumAction) {
      return _candidate(
        action,
        reason: MomentumReason.minimumActionAvailable,
        priority: 5,
        text: 'Для квеста «${action.taskTitle}» уже есть минимальный шаг.',
        stageId: action.stageId,
      );
    }
    return null;
  }

  _MomentumCandidate _candidate(
    MomentumActionRecord action, {
    required MomentumReason reason,
    required int priority,
    required String text,
    String? stageId,
    DateTime? evidenceAt,
    double? progress,
    int? remaining,
  }) {
    return _MomentumCandidate(
      priority: priority,
      sourceOrder: action.sourceOrder,
      snapshot: MomentumSnapshot(
        key:
            '${reason.name}:${action.skillId}:${action.taskId}:${stageId ?? ''}',
        reason: reason,
        headline: 'Движение уже есть',
        supportingText: text,
        skillId: action.skillId,
        skillName: action.skillName,
        taskId: action.taskId,
        actionLabel: action.actionLabel,
        stageId: stageId,
        evidenceAt: evidenceAt,
        progressFraction: progress,
        remainingCount: remaining,
      ),
    );
  }

  int _compareCandidates(
    _MomentumCandidate a,
    _MomentumCandidate b,
    MomentumInput input,
  ) {
    final byPriority = a.priority.compareTo(b.priority);
    if (byPriority != 0) return byPriority;
    final bySelection = _preferredRank(
      a.snapshot.skillId,
      input.selectedSkillId,
    ).compareTo(_preferredRank(b.snapshot.skillId, input.selectedSkillId));
    if (bySelection != 0) return bySelection;
    final aAt = a.snapshot.evidenceAt;
    final bAt = b.snapshot.evidenceAt;
    if (aAt != null || bAt != null) {
      if (aAt == null) return 1;
      if (bAt == null) return -1;
      final byEvidence = bAt.compareTo(aAt);
      if (byEvidence != 0) return byEvidence;
    }
    final bySource = a.sourceOrder.compareTo(b.sourceOrder);
    if (bySource != 0) return bySource;
    final bySkill = a.snapshot.skillId.compareTo(b.snapshot.skillId);
    if (bySkill != 0) return bySkill;
    return a.snapshot.taskId.compareTo(b.snapshot.taskId);
  }

  int _preferredRank(String skillId, String? preferredId) =>
      preferredId != null && skillId == preferredId ? 0 : 1;
}

class _MomentumCandidate {
  const _MomentumCandidate({
    required this.priority,
    required this.sourceOrder,
    required this.snapshot,
  });

  final int priority;
  final int sourceOrder;
  final MomentumSnapshot snapshot;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
