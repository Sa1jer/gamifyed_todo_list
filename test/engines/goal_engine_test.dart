import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/goal_engine.dart';
import 'package:todo_list_app/models.dart';

void main() {
  group('GoalEngine SMARTER readiness', () {
    const engine = GoalEngine();

    test('specific numeric goal gets core readiness without review', () {
      final readiness = engine.analyze(
        GoalSpec(
          text: 'Подтягиваться 20 раз',
          deadline: DateTime.now().add(const Duration(days: 120)),
          targetValue: 20,
          currentValue: 10,
        ),
      );

      expect(readiness.score, greaterThanOrEqualTo(5));
      expect(readiness.total, 7);
      expect(
        readiness.missing.map((check) => check.criterion),
        containsAll([
          SmarterCriterion.evaluated,
          SmarterCriterion.readjustable,
        ]),
      );
    });

    test('vague goal receives specific and measurable hints', () {
      final readiness = engine.analyze(GoalSpec(text: 'Стать сильнее'));

      expect(readiness.score, lessThan(5));
      expect(
        readiness.missing.map((check) => check.criterion),
        containsAll([SmarterCriterion.specific, SmarterCriterion.measurable]),
      );
      expect(readiness.topHints, hasLength(2));
    });

    test('review with updated plan satisfies evaluated and readjustable', () {
      final readiness = engine.analyze(
        GoalSpec(
          text: 'Собрать 5 этапов roadmap',
          metric: 'этапы',
          deadline: DateTime.now().add(const Duration(days: 90)),
          reviews: [
            GoalReviewEntry(
              id: 'review-1',
              wins: 'Первый этап готов',
              adjustment: 'Снизить объём недели',
              updatedPlan: true,
            ),
          ],
        ),
      );

      expect(
        readiness.checks
            .firstWhere(
              (check) => check.criterion == SmarterCriterion.evaluated,
            )
            .passed,
        isTrue,
      );
      expect(
        readiness.checks
            .firstWhere(
              (check) => check.criterion == SmarterCriterion.readjustable,
            )
            .passed,
        isTrue,
      );
    });

    test('aggressive deadline is marked as not achievable', () {
      final readiness = engine.analyze(
        GoalSpec(
          text: 'Подтягиваться 100 раз',
          deadline: DateTime.now().add(const Duration(days: 7)),
          targetValue: 100,
          currentValue: 5,
        ),
      );

      expect(
        readiness.checks
            .firstWhere(
              (check) => check.criterion == SmarterCriterion.achievable,
            )
            .passed,
        isFalse,
      );
    });
  });
}
