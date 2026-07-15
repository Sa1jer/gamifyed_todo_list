import '../models.dart';
import '../utils.dart';

class SkillSelectionResult {
  const SkillSelectionResult({required this.changed, required this.skillId});

  final bool changed;
  final String? skillId;
}

/// Owns ephemeral review/session decisions and weekly review mutations.
class ReviewSessionCoordinator {
  const ReviewSessionCoordinator();

  SkillSelectionResult select({
    required String? currentSkillId,
    required String? requestedSkillId,
    required Iterable<Skill> skills,
    bool toggle = false,
  }) {
    final valid =
        requestedSkillId == null ||
        skills.any((skill) => skill.id == requestedSkillId);
    if (!valid) {
      return SkillSelectionResult(changed: false, skillId: currentSkillId);
    }
    final next = toggle && requestedSkillId == currentSkillId
        ? null
        : requestedSkillId;
    return SkillSelectionResult(changed: next != currentSkillId, skillId: next);
  }

  bool dismissNudge(Set<String> dismissedKeys, String key) {
    final normalized = key.trim();
    return normalized.isNotEmpty && dismissedKeys.add(normalized);
  }

  bool addGoalReview({
    required Skill? skill,
    required GoalReviewEntry review,
    required DateTime now,
  }) {
    if (skill == null) return false;
    skill.goalSpec.reviews.insert(0, review);
    skill.goalSpec.updatedAt = now;
    return true;
  }

  bool saveWeeklyGoal({
    required List<WeeklyGoal> goals,
    required DateTime weekStart,
    required String title,
    required List<WeeklyKeyResult> keyResults,
    required String Function() idFactory,
    required DateTime now,
  }) {
    final normalizedStart = startOfWeek(weekStart);
    final normalizedTitle = title.trim();
    final normalizedResults = keyResults
        .map(
          (result) => WeeklyKeyResult(
            id: result.id.isEmpty ? idFactory() : result.id,
            title: result.title.trim(),
            isDone: result.isDone,
            completedAt: result.completedAt,
          ),
        )
        .where((result) => result.title.isNotEmpty)
        .take(5)
        .toList(growable: false);
    final existing = goals
        .where((goal) => isSameDate(goal.weekStart, normalizedStart))
        .firstOrNull;

    if (normalizedTitle.isEmpty && normalizedResults.isEmpty) {
      if (existing == null) return false;
      goals.remove(existing);
      return true;
    }

    if (existing == null) {
      goals.add(
        WeeklyGoal(
          id: idFactory(),
          weekStart: normalizedStart,
          title: normalizedTitle.isEmpty ? 'Цель недели' : normalizedTitle,
          keyResults: normalizedResults,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      existing.title = normalizedTitle.isEmpty
          ? 'Цель недели'
          : normalizedTitle;
      existing.keyResults = normalizedResults;
      existing.updatedAt = now;
    }
    goals.sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return true;
  }

  bool toggleWeeklyKeyResult({
    required List<WeeklyGoal> goals,
    required String goalId,
    required String keyResultId,
    required DateTime now,
  }) {
    final goal = goals.where((item) => item.id == goalId).firstOrNull;
    final keyResult = goal?.keyResults
        .where((item) => item.id == keyResultId)
        .firstOrNull;
    if (goal == null || keyResult == null) return false;
    keyResult.isDone = !keyResult.isDone;
    keyResult.completedAt = keyResult.isDone ? now : null;
    goal.updatedAt = now;
    return true;
  }
}
