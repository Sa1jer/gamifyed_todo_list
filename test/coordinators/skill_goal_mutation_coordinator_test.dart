import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/coordinators/skill_goal_mutation_coordinator.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  const coordinator = SkillGoalMutationCoordinator();
  final now = DateTime(2026, 7, 16, 12);

  test('add rejects reserved and duplicate ids and keeps Inbox last', () {
    final inbox = _skill(kInboxSkillId);
    final skills = <Skill>[_skill('existing'), inbox];
    final added = _skill('added')
      ..checklist = ['One']
      ..checklistDone = <bool>[];

    expect(coordinator.add(skills: skills, skill: added), isTrue);
    expect(skills.map((skill) => skill.id), [
      'existing',
      'added',
      kInboxSkillId,
    ]);
    expect(added.checklistDone, [false]);
    expect(coordinator.add(skills: skills, skill: _skill('added')), isFalse);
    expect(
      coordinator.add(skills: skills, skill: _skill(kInboxSkillId)),
      isFalse,
    );
  });

  test('reorder validates indices and never moves Inbox from the end', () {
    final skills = <Skill>[
      _skill('first'),
      _skill('second'),
      _skill(kInboxSkillId),
    ];

    expect(
      coordinator.reorder(skills: skills, oldIndex: 0, newIndex: 2),
      isTrue,
    );
    expect(skills.map((skill) => skill.id), ['second', 'first', kInboxSkillId]);
    expect(
      coordinator.reorder(skills: skills, oldIndex: 2, newIndex: 0),
      isFalse,
    );
    expect(
      coordinator.reorder(skills: skills, oldIndex: -1, newIndex: 0),
      isFalse,
    );
    expect(
      coordinator.reorder(skills: skills, oldIndex: 0, newIndex: 3),
      isFalse,
    );
  });

  test('update synchronizes checklist and rejects Inbox', () {
    final skill = _skill('skill')
      ..checklist = ['Old']
      ..checklistDone = [true];

    expect(
      coordinator.update(
        skill: skill,
        name: 'Updated',
        goal: 'Updated goal',
        checklist: const ['One', 'Two'],
      ),
      isTrue,
    );
    expect(skill.name, 'Updated');
    expect(skill.goal, 'Updated goal');
    expect(skill.checklistDone, [true, false]);
    expect(
      coordinator.update(
        skill: _skill(kInboxSkillId),
        name: 'Inbox',
        goal: '',
        checklist: const [],
      ),
      isFalse,
    );
  });

  test(
    'next Goal archives a completed Goal once and rejects invalid states',
    () {
      final completed = _skill(
        'skill',
        goal: 'First goal',
        nodes: [_node('stage', mastered: true)],
      )..triggeredGoalMilestones.addAll([25, 50, 100]);
      var nextId = 0;

      expect(
        coordinator.setNextGoal(
          skill: completed,
          nextGoal: '  Second goal  ',
          idFactory: () => 'goal-${nextId++}',
          completedAt: now,
        ),
        NextGoalUpdateResult.updated,
      );
      expect(completed.goal, 'Second goal');
      expect(completed.completedGoals, hasLength(1));
      expect(completed.completedGoals.single.goalText, 'First goal');
      expect(completed.completedGoals.single.completedAt, now);
      expect(completed.triggeredGoalMilestones, isEmpty);
      expect(
        coordinator.setNextGoal(
          skill: completed,
          nextGoal: 'Second goal',
          idFactory: () => 'unused',
          completedAt: now,
        ),
        NextGoalUpdateResult.unchanged,
      );
      expect(completed.completedGoals, hasLength(1));

      expect(
        coordinator.setNextGoal(
          skill: _skill('incomplete', nodes: [_node('stage')]),
          nextGoal: 'Next',
          idFactory: () => 'unused',
          completedAt: now,
        ),
        NextGoalUpdateResult.notCompleted,
      );
      expect(
        coordinator.setNextGoal(
          skill: completed,
          nextGoal: '  ',
          idFactory: () => 'unused',
          completedAt: now,
        ),
        NextGoalUpdateResult.invalid,
      );
    },
  );

  test('new RoadMap snapshots stages and clears only matching task links', () {
    final stage = _node('stage', mastered: true);
    final skill = _skill('skill', nodes: [stage])
      ..completedGoals.add(
        CompletedGoal(
          id: 'goal',
          skillId: 'skill',
          goalText: 'Completed goal',
          completedAt: now,
          progressAtCompletion: 1,
          completedStages: 1,
          totalStages: 1,
        ),
      );
    final linked = _task('linked', 'skill', treeNodeId: stage.id);
    final otherSkill = _task('other', 'other', treeNodeId: stage.id);

    expect(
      coordinator.startNewRoadmap(
        skill: skill,
        tasks: [linked, otherSkill],
        idFactory: () => 'roadmap',
        now: now,
      ),
      StartNewRoadmapResult.created,
    );
    expect(skill.completedRoadmaps, hasLength(1));
    expect(skill.completedRoadmaps.single.stages.single.id, stage.id);
    expect(skill.treeNodes, isEmpty);
    expect(linked.treeNodeId, isNull);
    expect(linked.updatedAt, now);
    expect(otherSkill.treeNodeId, stage.id);

    expect(
      coordinator.startNewRoadmap(
        skill: _skill('empty'),
        tasks: const [],
        idFactory: () => 'unused',
        now: now,
      ),
      StartNewRoadmapResult.noStages,
    );
    expect(
      coordinator.startNewRoadmap(
        skill: _skill('incomplete', nodes: [_node('stage')]),
        tasks: const [],
        idFactory: () => 'unused',
        now: now,
      ),
      StartNewRoadmapResult.notCompleted,
    );
  });

  test('Skill deletion cleans linked domain objects and selection', () {
    final skill = _skill('skill');
    final linkedTask = _task('task', skill.id);
    final inboxTask = _task('inbox', kInboxSkillId);
    final bosses = [
      Boss(id: 'boss', title: 'Boss', skillId: skill.id, targetStreak: 3),
    ];
    final chests = [
      RewardChest(
        id: 'chest',
        title: 'Chest',
        description: '',
        rarity: RewardRarity.common,
        sourceKey: 'source',
        skillId: skill.id,
        unlockedAt: now,
      ),
    ];
    final buffs = [
      Buff(
        id: 'buff',
        type: BuffType.skillFocusXpBoost,
        title: 'Buff',
        description: '',
        bonusPercent: 10,
        charges: 1,
        createdAt: now,
        skillId: skill.id,
      ),
    ];

    final result = coordinator.remove(
      skillId: skill.id,
      skills: [skill],
      tasks: [linkedTask, inboxTask],
      bosses: bosses,
      rewardChests: chests,
      buffs: buffs,
      selectedSkillId: skill.id,
    );

    expect(result.changed, isTrue);
    expect(result.removedTaskIds, [linkedTask.id]);
    expect(result.clearsSelection, isTrue);
    expect(bosses, isEmpty);
    expect(chests, isEmpty);
    expect(buffs, isEmpty);
    expect(
      coordinator
          .remove(
            skillId: 'missing',
            skills: const [],
            tasks: const [],
            bosses: const [],
            rewardChests: const [],
            buffs: const [],
            selectedSkillId: null,
          )
          .changed,
      isFalse,
    );
  });
}

Skill _skill(
  String id, {
  String goal = 'Goal',
  List<SkillTreeNode> nodes = const [],
}) => Skill(
  id: id,
  name: id,
  goal: goal,
  color: Colors.blue,
  icon: Icons.star,
  treeNodes: nodes,
);

SkillTreeNode _node(String id, {bool mastered = false}) => SkillTreeNode(
  id: id,
  title: id,
  isMastered: mastered,
  masteredAt: mastered ? DateTime(2026, 7, 1) : null,
);

Task _task(String id, String skillId, {String? treeNodeId}) => Task(
  id: id,
  title: id,
  skillId: skillId,
  xpReward: skillId == kInboxSkillId ? 0 : 20,
  type: TaskType.shortTerm,
  treeNodeId: treeNodeId,
);
