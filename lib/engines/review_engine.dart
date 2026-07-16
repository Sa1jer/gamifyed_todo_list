import '../models/activity_models.dart';
import '../models/skill_models.dart';

class ReviewSuggestion {
  final Skill skill;
  final bool isDue;
  final DateTime? lastReviewAt;
  final int recentQuestCount;
  final int recentXp;
  final List<HistoryEntry> recentWins;
  final String winsDraft;
  final String blockersDraft;
  final String adjustmentDraft;
  final String nextFocusDraft;

  const ReviewSuggestion({
    required this.skill,
    required this.isDue,
    required this.lastReviewAt,
    required this.recentQuestCount,
    required this.recentXp,
    required this.recentWins,
    required this.winsDraft,
    required this.blockersDraft,
    required this.adjustmentDraft,
    required this.nextFocusDraft,
  });
}

class ReviewEngine {
  static const Duration cadence = Duration(days: 7);

  const ReviewEngine();

  bool isReviewDue(Skill skill, {DateTime? now}) {
    if (skill.goal.trim().isEmpty) return false;
    final reference = now ?? DateTime.now();
    final lastReviewAt = _lastReviewAt(skill);
    final anchor = lastReviewAt ?? skill.goalSpec.updatedAt;
    return !anchor.add(cadence).isAfter(reference);
  }

  ReviewSuggestion suggest(
    Skill skill,
    Iterable<HistoryEntry> history, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final recentWins =
        history
            .where((entry) => entry.isCompletion)
            .where((entry) => entry.skillId == skill.id)
            .where((entry) => !entry.at.isBefore(reference.subtract(cadence)))
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));
    final recentXp = recentWins.fold<int>(0, (sum, entry) => sum + entry.xp);

    return ReviewSuggestion(
      skill: skill,
      isDue: isReviewDue(skill, now: reference),
      lastReviewAt: _lastReviewAt(skill),
      recentQuestCount: recentWins.length,
      recentXp: recentXp,
      recentWins: recentWins,
      winsDraft: _winsDraft(recentWins, recentXp),
      blockersDraft: '',
      adjustmentDraft: recentWins.isEmpty
          ? 'Упростить следующий шаг и выбрать один лёгкий квест.'
          : '',
      nextFocusDraft: _nextFocusDraft(skill),
    );
  }

  ReviewSuggestion? suggestPrimary(
    Iterable<Skill> skills,
    Iterable<HistoryEntry> history, {
    DateTime? now,
  }) {
    final suggestions = skills
        .where((skill) => skill.goal.trim().isNotEmpty)
        .map((skill) => suggest(skill, history, now: now))
        .toList();
    if (suggestions.isEmpty) return null;

    suggestions.sort((a, b) {
      final byDue = a.isDue == b.isDue ? 0 : (a.isDue ? -1 : 1);
      if (byDue != 0) return byDue;

      final byWins = b.recentQuestCount.compareTo(a.recentQuestCount);
      if (byWins != 0) return byWins;

      final aReview = a.lastReviewAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bReview = b.lastReviewAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final byOldestReview = aReview.compareTo(bReview);
      if (byOldestReview != 0) return byOldestReview;

      return a.skill.name.compareTo(b.skill.name);
    });
    return suggestions.first;
  }

  DateTime? _lastReviewAt(Skill skill) {
    if (skill.goalSpec.reviews.isEmpty) return null;
    final reviews = [...skill.goalSpec.reviews]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews.first.createdAt;
  }

  String _winsDraft(List<HistoryEntry> wins, int recentXp) {
    if (wins.isEmpty) {
      return 'Неделя была тихой — это тоже сигнал для мягкой настройки.';
    }
    final latest = wins.first.taskTitle;
    return 'Закрыто ${wins.length} квест. · +$recentXp XP. Свежая победа: $latest.';
  }

  String _nextFocusDraft(Skill skill) {
    final activeStage = skill.treeNodes
        .where(
          (node) => skill.treeNodeStatus(node) == SkillTreeNodeStatus.active,
        )
        .firstOrNull;
    if (activeStage != null) {
      return 'Продолжить этап «${activeStage.title}».';
    }
    return 'Выбрать один следующий квест для роста навыка.';
  }
}
