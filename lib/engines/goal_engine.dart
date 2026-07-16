import '../models/skill_models.dart';

enum SmarterCriterion {
  specific,
  measurable,
  achievable,
  relevant,
  timeBound,
  evaluated,
  readjustable,
}

class SmarterCheck {
  final SmarterCriterion criterion;
  final String label;
  final bool passed;
  final String hint;

  const SmarterCheck({
    required this.criterion,
    required this.label,
    required this.passed,
    required this.hint,
  });
}

class SmarterReadiness {
  final List<SmarterCheck> checks;

  const SmarterReadiness({required this.checks});

  int get score => checks.where((check) => check.passed).length;

  int get total => checks.length;

  bool get isStrong => score >= 5;

  List<SmarterCheck> get missing =>
      checks.where((check) => !check.passed).toList();

  List<String> get topHints =>
      missing.take(2).map((check) => check.hint).toList();
}

class GoalEngine {
  const GoalEngine();

  SmarterReadiness analyze(
    GoalSpec goal, {
    bool hasSkill = true,
    DateTime? now,
  }) {
    final text = goal.text.trim();
    final hasDeadline = goal.deadline != null;
    final hasMetric =
        (goal.metric?.trim().isNotEmpty ?? false) ||
        goal.targetValue != null ||
        _containsNumber(text);
    final hasReviews = goal.reviews.isNotEmpty;
    final hasReadjustment = goal.reviews.any((review) => review.updatedPlan);

    return SmarterReadiness(
      checks: [
        SmarterCheck(
          criterion: SmarterCriterion.specific,
          label: 'Конкретно',
          passed: _isSpecific(text),
          hint: 'Сделай цель конкретнее: что именно должно измениться?',
        ),
        SmarterCheck(
          criterion: SmarterCriterion.measurable,
          label: 'Измеримо',
          passed: hasMetric,
          hint: 'Добавь число или понятный критерий результата.',
        ),
        SmarterCheck(
          criterion: SmarterCriterion.achievable,
          label: 'Посильно',
          passed: _isAchievable(goal, now ?? DateTime.now()),
          hint: 'Добавь промежуточный этап, если цель выглядит резкой.',
        ),
        SmarterCheck(
          criterion: SmarterCriterion.relevant,
          label: 'Связано',
          passed: hasSkill,
          hint: 'Свяжи цель с навыком, чтобы квесты двигали её вперёд.',
        ),
        SmarterCheck(
          criterion: SmarterCriterion.timeBound,
          label: 'Есть срок',
          passed: hasDeadline,
          hint: 'Если срок важен, добавь дату достижения.',
        ),
        SmarterCheck(
          criterion: SmarterCriterion.evaluated,
          label: 'Проверяется',
          passed: hasReviews,
          hint: 'После первой недели сделай короткий review цели.',
        ),
        SmarterCheck(
          criterion: SmarterCriterion.readjustable,
          label: 'Корректируется',
          passed: hasReadjustment,
          hint:
              'Когда план изменится, отметь корректировку без чувства провала.',
        ),
      ],
    );
  }

  List<String> hints(GoalSpec goal, {bool hasSkill = true, DateTime? now}) =>
      analyze(goal, hasSkill: hasSkill, now: now).topHints;

  int readinessScore(GoalSpec goal, {bool hasSkill = true, DateTime? now}) =>
      analyze(goal, hasSkill: hasSkill, now: now).score;

  bool _isSpecific(String text) {
    if (text.length < 8) return false;
    final lower = text.toLowerCase();
    const vagueMarkers = [
      'лучше',
      'больше',
      'много',
      'сильнее',
      'нормально',
      'как-нибудь',
      'развиваться',
    ];
    return !vagueMarkers.any(lower.contains);
  }

  bool _containsNumber(String text) => RegExp(r'\d').hasMatch(text);

  bool _isAchievable(GoalSpec goal, DateTime now) {
    if (goal.deadline == null ||
        goal.targetValue == null ||
        goal.currentValue == null) {
      return true;
    }

    final remainingDays = goal.deadline!.difference(now).inDays;
    if (remainingDays <= 0) return false;

    final remaining = goal.targetValue! - goal.currentValue!;
    if (remaining <= 0) return true;

    final weeklyGrowth = remaining / (remainingDays / 7).clamp(1.0, 999.0);
    final base = goal.currentValue == 0
        ? goal.targetValue!
        : goal.currentValue!;
    return weeklyGrowth <= base.abs() * 0.2;
  }
}
