import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/next_action_resolver.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  const resolver = NextActionResolver();

  Skill skill({
    String id = 'skill-1',
    String name = 'Навык',
    List<SkillTreeNode>? stages,
  }) => Skill(
    id: id,
    name: name,
    goal: '',
    color: Colors.blue,
    icon: Icons.bolt_rounded,
    treeNodes: stages,
  );

  Task task({
    String id = 'task-1',
    String skillId = 'skill-1',
    String title = 'Сделать понятный шаг',
    Priority priority = Priority.medium,
    String minimumAction = '',
    String? stageId,
    bool isDone = false,
  }) => Task(
    id: id,
    title: title,
    skillId: skillId,
    xpReward: 20,
    type: TaskType.shortTerm,
    priority: priority,
    minimumAction: minimumAction,
    treeNodeId: stageId,
    isDone: isDone,
  );

  group('NextActionResolver', () {
    test('valid explicit choice wins without mutating the source task', () {
      final first = task(id: 'first', priority: Priority.high);
      final explicit = task(id: 'explicit', priority: Priority.low);

      final result = resolver.resolve(
        skills: [skill()],
        tasks: [first, explicit],
        selectedSkillId: 'skill-1',
        explicitTaskId: explicit.id,
      );

      expect(result.candidate?.task.id, explicit.id);
      expect(result.candidate?.reason, NextActionReason.explicitOverride);
      expect(explicit.isDone, isFalse);
      expect(explicit.minimumActionEarnedXP, 0);
    });

    test(
      'stale explicit choice falls back to selected skill deterministically',
      () {
        final high = task(id: 'high', priority: Priority.high);
        final low = task(id: 'low', priority: Priority.low);

        final result = resolver.resolve(
          skills: [skill()],
          tasks: [low, high],
          selectedSkillId: 'skill-1',
          explicitTaskId: 'removed-task',
        );

        expect(result.candidate?.task.id, high.id);
        expect(result.candidate?.reason, NextActionReason.selectedSkill);
      },
    );

    test(
      'selected skill active-stage task wins over another selected task',
      () {
        final stage = SkillTreeNode(id: 'stage-1', title: 'Практика');
        final current = skill(stages: [stage]);
        final stageTask = task(id: 'stage-task', stageId: stage.id);
        final looseTask = task(id: 'loose-task', priority: Priority.high);

        final result = resolver.resolve(
          skills: [current],
          tasks: [looseTask, stageTask],
          selectedSkillId: current.id,
        );

        expect(result.candidate?.task.id, stageTask.id);
        expect(result.candidate?.stage?.id, stage.id);
        expect(
          result.candidate?.reason,
          NextActionReason.selectedSkillActiveStage,
        );
      },
    );

    test(
      'completed, inbox, missing-skill, and locked-stage tasks are ignored',
      () {
        final active = skill();
        final lockedStage = SkillTreeNode(
          id: 'locked',
          title: 'Закрыто',
          prerequisiteIds: ['missing-prerequisite'],
        );
        final withLockedStage = skill(id: 'other', stages: [lockedStage]);

        final result = resolver.resolve(
          skills: [active, withLockedStage],
          tasks: [
            task(id: 'completed', isDone: true),
            task(id: 'inbox', skillId: kInboxSkillId),
            task(id: 'missing-skill', skillId: 'missing'),
            task(id: 'locked-stage', skillId: 'other', stageId: 'locked'),
            task(id: 'valid'),
          ],
          selectedSkillId: 'missing',
        );

        expect(result.candidate?.task.id, 'valid');
        expect(result.alternatives, hasLength(1));
      },
    );

    test(
      'minimum action changes copy but not candidate ownership or state',
      () {
        final source = task(
          minimumAction: 'Открыть файл и поправить один отступ',
        );

        final result = resolver.resolve(skills: [skill()], tasks: [source]);

        expect(result.candidate?.usesMinimumAction, isTrue);
        expect(result.candidate?.actionText, source.minimumAction);
        expect(source.isMinimumActionDone, isFalse);
        expect(source.minimumActionEarnedXP, 0);
      },
    );

    test('useful empty states distinguish no skills and no usable task', () {
      final noSkills = resolver.resolve(skills: const [], tasks: const []);
      final noTasks = resolver.resolve(skills: [skill()], tasks: const []);

      expect(noSkills.emptyState, NextActionEmptyState.noSkills);
      expect(noTasks.emptyState, NextActionEmptyState.noTasks);
      expect(noTasks.suggestedSkill?.id, 'skill-1');
    });
  });

  group('BootEntryPlan', () {
    test(
      'suggestion stays linked to parent and uses existing minimum action',
      () {
        final parent = task(
          id: 'parent',
          minimumAction: 'Открыть проект и заменить один слабый кадр',
        );

        final plan = BootEntryPlan.suggest(parent);

        expect(plan.parentTaskId, parent.id);
        expect(plan.parentSkillId, parent.skillId);
        expect(plan.smallChange, parent.minimumAction);
        expect(plan.isReady, isTrue);
        expect(parent.isDone, isFalse);
        expect(parent.earnedXP, 0);
        expect(parent.minimumActionEarnedXP, 0);
      },
    );

    test(
      'without a minimum action the user must provide the concrete change',
      () {
        final plan = BootEntryPlan.suggest(task(minimumAction: ''));
        final edited = plan.copyWith(smallChange: 'Исправить один отступ');

        expect(plan.isReady, isFalse);
        expect(edited.isReady, isTrue);
        expect(edited.parentTaskId, plan.parentTaskId);
      },
    );
  });
}
