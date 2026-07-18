/// The default amount of time since the latest reliable work evidence before
/// Return Context may be shown.
const defaultReturnContextPauseThreshold = Duration(days: 1);

enum ReturnContextSource {
  completionHistory,
  goalReview,
  selectedSkillFallback,
}

class ReturnContextSkillRecord {
  const ReturnContextSkillRecord({
    required this.id,
    required this.name,
    this.isInbox = false,
  });

  final String id;
  final String name;
  final bool isInbox;
}

class ReturnContextHistoryRecord {
  const ReturnContextHistoryRecord({
    required this.id,
    required this.taskTitle,
    required this.skillId,
    required this.skillName,
    required this.at,
    required this.isCompletion,
    this.taskId,
    this.isInbox = false,
  });

  final String id;
  final String? taskId;
  final String taskTitle;
  final String skillId;
  final String skillName;
  final DateTime at;
  final bool isCompletion;
  final bool isInbox;
}

class ReturnContextReviewRecord {
  const ReturnContextReviewRecord({
    required this.id,
    required this.skillId,
    required this.skillName,
    required this.at,
    required this.nextFocus,
    required this.isMeaningful,
    this.wins = '',
  });

  final String id;
  final String skillId;
  final String skillName;
  final DateTime at;
  final String wins;
  final String nextFocus;
  final bool isMeaningful;
}

/// A scalar projection of one candidate already ordered by NextActionResolver.
class ReturnContextActionRecord {
  const ReturnContextActionRecord({
    required this.taskId,
    required this.taskTitle,
    required this.skillId,
    required this.skillName,
    required this.actionLabel,
    required this.sourceOrder,
    required this.usesMinimumAction,
    this.stageId,
    this.stageTitle,
  });

  final String taskId;
  final String taskTitle;
  final String skillId;
  final String skillName;
  final String actionLabel;
  final int sourceOrder;
  final bool usesMinimumAction;
  final String? stageId;
  final String? stageTitle;
}

class ReturnContextInput {
  ReturnContextInput({
    required this.now,
    this.pauseThreshold = defaultReturnContextPauseThreshold,
    required Iterable<ReturnContextSkillRecord> skills,
    required Iterable<ReturnContextHistoryRecord> history,
    required Iterable<ReturnContextReviewRecord> reviews,
    required Iterable<ReturnContextActionRecord> actions,
    this.selectedSkillId,
  }) : skills = List<ReturnContextSkillRecord>.unmodifiable(skills),
       history = List<ReturnContextHistoryRecord>.unmodifiable(history),
       reviews = List<ReturnContextReviewRecord>.unmodifiable(reviews),
       actions = List<ReturnContextActionRecord>.unmodifiable(actions);

  final DateTime now;
  final Duration pauseThreshold;
  final List<ReturnContextSkillRecord> skills;
  final List<ReturnContextHistoryRecord> history;
  final List<ReturnContextReviewRecord> reviews;
  final List<ReturnContextActionRecord> actions;
  final String? selectedSkillId;
}

class ReturnContextCandidate {
  const ReturnContextCandidate({
    required this.key,
    required this.source,
    required this.sourceAt,
    required this.skillId,
    required this.skillName,
    required this.reentryAction,
    required this.usesMinimumAction,
    this.taskId,
    this.taskTitle,
    this.stageId,
    this.stageTitle,
    this.lastResult,
  });

  final String key;
  final ReturnContextSource source;
  final DateTime sourceAt;
  final String skillId;
  final String skillName;
  final String? taskId;
  final String? taskTitle;
  final String? stageId;
  final String? stageTitle;
  final String? lastResult;
  final String reentryAction;
  final bool usesMinimumAction;
}

class ReturnContextResolver {
  const ReturnContextResolver();

  ReturnContextCandidate? resolve(ReturnContextInput input) {
    if (input.pauseThreshold.isNegative) return null;

    final skillsById = <String, ReturnContextSkillRecord>{
      for (final skill in input.skills)
        if (!skill.isInbox && skill.id.trim().isNotEmpty) skill.id: skill,
    };
    if (skillsById.isEmpty) return null;

    final meaningfulTimes = <DateTime>[
      for (final entry in input.history)
        if (entry.isCompletion &&
            !entry.isInbox &&
            skillsById.containsKey(entry.skillId))
          entry.at,
      for (final review in input.reviews)
        if (review.isMeaningful && skillsById.containsKey(review.skillId))
          review.at,
    ];
    if (meaningfulTimes.isEmpty) return null;
    meaningfulTimes.sort((a, b) => b.compareTo(a));
    final latestMeaningfulAt = meaningfulTimes.first;
    final elapsed = input.now.difference(latestMeaningfulAt);
    if (elapsed.isNegative || elapsed < input.pauseThreshold) return null;

    final orderedActions =
        input.actions
            .where((action) => skillsById.containsKey(action.skillId))
            .toList()
          ..sort(_compareActions);

    final history =
        input.history
            .where(
              (entry) =>
                  entry.isCompletion &&
                  !entry.isInbox &&
                  skillsById.containsKey(entry.skillId),
            )
            .toList()
          ..sort(_compareHistory);
    if (history.isNotEmpty) {
      return _fromHistory(
        history.first,
        skillsById[history.first.skillId]!,
        orderedActions,
      );
    }

    final reviews =
        input.reviews
            .where(
              (review) =>
                  review.isMeaningful &&
                  review.nextFocus.trim().isNotEmpty &&
                  skillsById.containsKey(review.skillId),
            )
            .toList()
          ..sort(_compareReviews);
    if (reviews.isNotEmpty) {
      return _fromReview(
        reviews.first,
        skillsById[reviews.first.skillId]!,
        orderedActions,
      );
    }

    final selectedSkill = input.selectedSkillId == null
        ? null
        : skillsById[input.selectedSkillId];
    if (selectedSkill == null) return null;
    final action = _firstActionForSkill(orderedActions, selectedSkill.id);
    if (action == null) return null;
    return _candidate(
      source: ReturnContextSource.selectedSkillFallback,
      sourceId: 'selected',
      sourceAt: latestMeaningfulAt,
      skill: selectedSkill,
      action: action,
    );
  }

  ReturnContextCandidate _fromHistory(
    ReturnContextHistoryRecord history,
    ReturnContextSkillRecord skill,
    List<ReturnContextActionRecord> actions,
  ) {
    final matchingTask = history.taskId == null
        ? null
        : actions
              .where((action) => action.taskId == history.taskId)
              .firstOrNull;
    final action = matchingTask ?? _firstActionForSkill(actions, skill.id);
    return _candidate(
      source: ReturnContextSource.completionHistory,
      sourceId: history.id,
      sourceAt: history.at,
      skill: skill,
      action: action,
      lastResult: _nonEmpty(history.taskTitle),
    );
  }

  ReturnContextCandidate _fromReview(
    ReturnContextReviewRecord review,
    ReturnContextSkillRecord skill,
    List<ReturnContextActionRecord> actions,
  ) {
    final action = _firstActionForSkill(actions, skill.id);
    return _candidate(
      source: ReturnContextSource.goalReview,
      sourceId: review.id,
      sourceAt: review.at,
      skill: skill,
      action: action,
      lastResult: _nonEmpty(review.wins),
      fallbackAction: review.nextFocus.trim(),
    );
  }

  ReturnContextCandidate _candidate({
    required ReturnContextSource source,
    required String sourceId,
    required DateTime sourceAt,
    required ReturnContextSkillRecord skill,
    ReturnContextActionRecord? action,
    String? lastResult,
    String? fallbackAction,
  }) {
    final actionLabel =
        _nonEmpty(action?.actionLabel) ??
        _nonEmpty(fallbackAction) ??
        'Открыть навык';
    final taskId = action?.taskId;
    final stageId = action?.stageId;
    final key = <String>[
      source.name,
      sourceId,
      '${sourceAt.microsecondsSinceEpoch}',
      skill.id,
      taskId ?? '',
      stageId ?? '',
    ].join('|');
    return ReturnContextCandidate(
      key: key,
      source: source,
      sourceAt: sourceAt,
      skillId: skill.id,
      skillName: skill.name,
      taskId: taskId,
      taskTitle: action?.taskTitle,
      stageId: stageId,
      stageTitle: _nonEmpty(action?.stageTitle),
      lastResult: lastResult,
      reentryAction: actionLabel,
      usesMinimumAction: action?.usesMinimumAction ?? false,
    );
  }

  ReturnContextActionRecord? _firstActionForSkill(
    Iterable<ReturnContextActionRecord> actions,
    String skillId,
  ) {
    return actions.where((action) => action.skillId == skillId).firstOrNull;
  }

  int _compareHistory(
    ReturnContextHistoryRecord a,
    ReturnContextHistoryRecord b,
  ) {
    final byTime = b.at.compareTo(a.at);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  int _compareReviews(
    ReturnContextReviewRecord a,
    ReturnContextReviewRecord b,
  ) {
    final byTime = b.at.compareTo(a.at);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  int _compareActions(
    ReturnContextActionRecord a,
    ReturnContextActionRecord b,
  ) {
    final byOrder = a.sourceOrder.compareTo(b.sourceOrder);
    return byOrder != 0 ? byOrder : a.taskId.compareTo(b.taskId);
  }

  String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
