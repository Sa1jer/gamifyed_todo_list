import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/course_nudge_engine.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  group('CourseNudgeEngine', () {
    const engine = CourseNudgeEngine();
    final now = DateTime(2026, 2, 9, 10);

    Skill skill({
      String id = 'skill-1',
      String goal = 'Подтягиваться 20 раз',
      List<GoalReviewEntry>? reviews,
      List<SkillTreeNode>? stages,
    }) {
      return Skill(
        id: id,
        name: 'Подтягивания',
        goal: goal,
        goalSpec: GoalSpec(
          text: goal,
          reviews: reviews,
          updatedAt: now.subtract(const Duration(days: 8)),
        ),
        color: Colors.orange,
        icon: Icons.fitness_center,
        treeNodes: stages,
      );
    }

    Task task({
      String id = 'task-1',
      String skillId = 'skill-1',
      String title = 'Сделать тренировку',
      String minimumAction = '',
      String? treeNodeId,
      bool isDone = false,
    }) {
      return Task(
        id: id,
        title: title,
        skillId: skillId,
        xpReward: 20,
        type: TaskType.shortTerm,
        minimumAction: minimumAction,
        treeNodeId: treeNodeId,
        isDone: isDone,
      );
    }

    GoalReviewEntry review({
      String id = 'review-1',
      String nextFocus = '',
      String adjustment = '',
    }) {
      return GoalReviewEntry(
        id: id,
        createdAt: now,
        nextFocus: nextFocus,
        adjustment: adjustment,
        updatedPlan: nextFocus.isNotEmpty || adjustment.isNotEmpty,
      );
    }

    test('returns actionable review focus before other nudges', () {
      final nudge = engine.suggestForSkill(
        skill(
          reviews: [review(nextFocus: 'сделать 2 тренировки подтягиваний')],
        ),
        [task(title: 'Большой квест без минимума')],
      );

      expect(nudge?.kind, CourseNudgeKind.createFocusQuest);
      expect(nudge?.initialTitle, 'сделать 2 тренировки подтягиваний');
    });

    test('vague next focus asks to clarify instead of creating a quest', () {
      final nudge = engine.suggestForSkill(
        skill(reviews: [review(nextFocus: 'стать стабильнее')]),
        [task(title: 'Большой квест без минимума')],
      );

      expect(nudge?.kind, CourseNudgeKind.clarifyFocus);
      expect(nudge?.actionLabel, 'Уточнить фокус');
    });

    test('addMinimumToTask disappears after minimum action is added', () {
      final before = engine.suggestForSkill(skill(), [task()]);
      final after = engine.suggestForSkill(skill(), [
        task(minimumAction: '5 подтягиваний'),
      ]);

      expect(before?.kind, CourseNudgeKind.addMinimumToTask);
      expect(after?.kind, isNot(CourseNudgeKind.addMinimumToTask));
    });

    test('createStageQuest waits until active stage has no active quest', () {
      final stage = SkillTreeNode(id: 'stage-1', title: 'Основа');
      final currentSkill = skill(stages: [stage]);

      final before = engine.suggestForSkill(currentSkill, const []);
      final after = engine.suggestForSkill(currentSkill, [
        task(treeNodeId: stage.id, minimumAction: '5 минут практики'),
      ]);

      expect(before?.kind, CourseNudgeKind.createStageQuest);
      expect(after?.kind, isNot(CourseNudgeKind.createStageQuest));
    });

    test('suggestPrimary returns only the highest-priority nudge', () {
      final focusSkill = skill(
        id: 'focus',
        reviews: [review(nextFocus: 'прочитать 20 страниц')],
      );
      final minimumSkill = skill(id: 'minimum');

      final nudge = engine.suggestPrimary(
        [minimumSkill, focusSkill],
        [task(skillId: 'minimum')],
      );

      expect(nudge?.kind, CourseNudgeKind.createFocusQuest);
      expect(nudge?.skill.id, 'focus');
    });
  });
}
