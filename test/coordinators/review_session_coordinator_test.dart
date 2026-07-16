import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/coordinators/review_session_coordinator.dart';
import 'package:todo_list_app/models.dart';

void main() {
  const coordinator = ReviewSessionCoordinator();
  final now = DateTime(2026, 7, 16, 12);
  final skills = [_skill('one'), _skill('two')];

  test(
    'selection accepts valid ids, toggles, clears, and rejects stale ids',
    () {
      expect(
        coordinator
            .select(
              currentSkillId: null,
              requestedSkillId: 'one',
              skills: skills,
            )
            .skillId,
        'one',
      );
      final toggled = coordinator.select(
        currentSkillId: 'one',
        requestedSkillId: 'one',
        skills: skills,
        toggle: true,
      );
      expect(toggled.changed, isTrue);
      expect(toggled.skillId, isNull);
      expect(
        coordinator
            .select(
              currentSkillId: 'one',
              requestedSkillId: null,
              skills: skills,
            )
            .skillId,
        isNull,
      );
      final stale = coordinator.select(
        currentSkillId: 'one',
        requestedSkillId: 'missing',
        skills: skills,
      );
      expect(stale.changed, isFalse);
      expect(stale.skillId, 'one');
    },
  );

  test('nudge dismissal trims keys and is idempotent', () {
    final dismissed = <String>{};

    expect(coordinator.dismissNudge(dismissed, '  nudge  '), isTrue);
    expect(dismissed, {'nudge'});
    expect(coordinator.dismissNudge(dismissed, 'nudge'), isFalse);
    expect(coordinator.dismissNudge(dismissed, '   '), isFalse);
  });

  test('weekly Goal creation normalizes values and caps Key Results', () {
    final goals = <WeeklyGoal>[];
    var nextId = 0;
    final keyResults = List.generate(
      7,
      (index) => WeeklyKeyResult(
        id: index == 0 ? '' : 'result-$index',
        title: index == 6 ? '   ' : '  Result $index  ',
      ),
    );

    expect(
      coordinator.saveWeeklyGoal(
        goals: goals,
        weekStart: DateTime(2026, 7, 15),
        title: '   ',
        keyResults: keyResults,
        idFactory: () => 'generated-${nextId++}',
        now: now,
      ),
      isTrue,
    );
    expect(goals, hasLength(1));
    expect(goals.single.weekStart, DateTime(2026, 7, 13));
    expect(goals.single.title, 'Цель недели');
    expect(goals.single.keyResults, hasLength(5));
    expect(goals.single.keyResults.first.id, 'generated-0');
    expect(goals.single.keyResults.first.title, 'Result 0');
    expect(goals.single.createdAt, now);
    expect(goals.single.updatedAt, now);
  });

  test('weekly Goal update, toggle, and deletion preserve timestamps', () {
    final createdAt = DateTime(2026, 7, 1);
    final goal = WeeklyGoal(
      id: 'goal',
      weekStart: DateTime(2026, 7, 13),
      title: 'Old',
      keyResults: [WeeklyKeyResult(id: 'result', title: 'Old result')],
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final goals = [goal];

    expect(
      coordinator.saveWeeklyGoal(
        goals: goals,
        weekStart: DateTime(2026, 7, 16),
        title: '  Updated  ',
        keyResults: [
          WeeklyKeyResult(id: 'result', title: '  Updated result  '),
        ],
        idFactory: () => 'unused',
        now: now,
      ),
      isTrue,
    );
    expect(goal.title, 'Updated');
    expect(goal.keyResults.single.title, 'Updated result');
    expect(goal.createdAt, createdAt);
    expect(goal.updatedAt, now);

    final toggledAt = now.add(const Duration(minutes: 1));
    expect(
      coordinator.toggleWeeklyKeyResult(
        goals: goals,
        goalId: goal.id,
        keyResultId: 'result',
        now: toggledAt,
      ),
      isTrue,
    );
    expect(goal.keyResults.single.isDone, isTrue);
    expect(goal.keyResults.single.completedAt, toggledAt);
    expect(goal.updatedAt, toggledAt);
    expect(
      coordinator.toggleWeeklyKeyResult(
        goals: goals,
        goalId: 'missing',
        keyResultId: 'result',
        now: now,
      ),
      isFalse,
    );

    expect(
      coordinator.saveWeeklyGoal(
        goals: goals,
        weekStart: goal.weekStart,
        title: ' ',
        keyResults: const [],
        idFactory: () => 'unused',
        now: now,
      ),
      isTrue,
    );
    expect(goals, isEmpty);
    expect(
      coordinator.saveWeeklyGoal(
        goals: goals,
        weekStart: DateTime(2026, 7, 13),
        title: '',
        keyResults: const [],
        idFactory: () => 'unused',
        now: now,
      ),
      isFalse,
    );
  });

  test('Goal review inserts newest entry and missing Skill is a no-op', () {
    final skill = _skill('skill');
    final review = GoalReviewEntry(id: 'review', wins: 'Win');

    expect(
      coordinator.addGoalReview(skill: skill, review: review, now: now),
      isTrue,
    );
    expect(skill.goalSpec.reviews.first, same(review));
    expect(skill.goalSpec.updatedAt, now);
    expect(
      coordinator.addGoalReview(skill: null, review: review, now: now),
      isFalse,
    );
  });
}

Skill _skill(String id) =>
    Skill(id: id, name: id, goal: 'Goal', color: Colors.blue, icon: Icons.star);
