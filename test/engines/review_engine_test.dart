import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/review_engine.dart';
import 'package:todo_list_app/models.dart';

void main() {
  group('ReviewEngine', () {
    const engine = ReviewEngine();
    final now = DateTime(2026, 2, 9, 10);

    Skill skill({
      String id = 'skill-1',
      DateTime? goalUpdatedAt,
      List<GoalReviewEntry>? reviews,
    }) {
      return Skill(
        id: id,
        name: 'Подтягивания',
        goal: 'Подтягиваться 20 раз',
        goalSpec: GoalSpec(
          text: 'Подтягиваться 20 раз',
          updatedAt: goalUpdatedAt ?? now.subtract(const Duration(days: 8)),
          reviews: reviews,
        ),
        color: Colors.orange,
        icon: Icons.fitness_center,
      );
    }

    HistoryEntry win({
      String skillId = 'skill-1',
      String title = 'Закрыть практику',
      int xp = 20,
      DateTime? at,
    }) {
      return HistoryEntry(
        id: title,
        taskTitle: title,
        taskId: title,
        skillId: skillId,
        skillName: 'Подтягивания',
        skillColor: Colors.orange,
        skillIcon: Icons.fitness_center,
        xp: xp,
        isCompletion: true,
        at: at ?? now.subtract(const Duration(days: 1)),
      );
    }

    test('goal becomes due after cadence without reviews', () {
      expect(engine.isReviewDue(skill(), now: now), isTrue);
    });

    test('fresh review keeps goal quiet', () {
      final reviewed = skill(
        reviews: [
          GoalReviewEntry(
            id: 'review-1',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
        ],
      );

      expect(engine.isReviewDue(reviewed, now: now), isFalse);
    });

    test('suggestion pulls recent wins for selected skill only', () {
      final suggestion = engine.suggest(skill(), [
        win(title: 'Свежий квест', xp: 30),
        win(skillId: 'other', title: 'Чужой квест', xp: 50),
        win(title: 'Старый квест', at: now.subtract(const Duration(days: 12))),
      ], now: now);

      expect(suggestion.recentQuestCount, 1);
      expect(suggestion.recentXp, 30);
      expect(suggestion.winsDraft, contains('Свежий квест'));
      expect(suggestion.winsDraft, isNot(contains('Чужой квест')));
    });

    test('primary suggestion prefers due skill with recent wins', () {
      final quiet = skill(id: 'quiet');
      final active = skill(id: 'active');

      final suggestion = engine.suggestPrimary(
        [quiet, active],
        [win(skillId: 'active', title: 'Активная победа')],
        now: now,
      );

      expect(suggestion?.skill.id, 'active');
    });
  });
}
