import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/coordinators/roadmap_mutation_coordinator.dart';
import 'package:todo_list_app/engines/roadmap_engine.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  const coordinator = RoadmapMutationCoordinator();

  test('reorders a unique linear path and rewrites prerequisites', () {
    final skill = _skill(
      nodes: [
        _node('a'),
        _node('b', parent: 'a'),
      ],
    );

    expect(coordinator.reorderPath(skill, ['b', 'a']), isTrue);

    expect(skill.treeNodes.map((node) => node.id), ['b', 'a']);
    expect(skill.treeNodes[0].prerequisiteIds, isEmpty);
    expect(skill.treeNodes[1].prerequisiteIds, ['b']);
  });

  test('template mutation preserves a linked extra stage', () {
    final linked = _node('linked', description: 'Keep this stage');
    final skill = _skill(nodes: [_node('root'), linked]);
    final task = Task(
      id: 'task',
      title: 'Linked quest',
      skillId: skill.id,
      xpReward: 20,
      type: TaskType.shortTerm,
      treeNodeId: linked.id,
    );

    expect(
      coordinator.applyTemplate(
        skill,
        [task],
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.simple,
          stagesPerPath: 1,
        ),
      ),
      isTrue,
    );

    expect(skill.treeNodes.any((node) => node.id == linked.id), isTrue);
  });

  test('removing a middle stage reconnects a linear road', () {
    final root = _node('root');
    final removed = _node('removed', parent: root.id);
    final child = _node('child', parent: removed.id);
    final skill = _skill(nodes: [root, removed, child]);
    final original = DateTime(2026, 1, 1);
    final now = DateTime(2026, 2, 2);
    final task = Task(
      id: 'task',
      title: 'Linked quest',
      skillId: skill.id,
      xpReward: 20,
      type: TaskType.shortTerm,
      treeNodeId: removed.id,
      updatedAt: original,
    );

    expect(
      coordinator.removeStage(skill, [task], removed.id, now: now),
      isTrue,
    );

    expect(skill.treeNodes.map((node) => node.id), ['root', 'child']);
    expect(child.prerequisiteIds, ['root']);
    expect(task.treeNodeId, isNull);
    expect(task.updatedAt, now);
    expect(coordinator.validateGraph(skill).isValid, isTrue);
  });

  test('removing first, last, and only stages remains valid', () {
    final first = _node('first');
    final middle = _node('middle', parent: first.id);
    final last = _node('last', parent: middle.id);
    final skill = _skill(nodes: [first, middle, last]);

    expect(
      coordinator.removeStage(skill, const [], first.id, now: DateTime(2026)),
      isTrue,
    );
    expect(middle.prerequisiteIds, isEmpty);
    expect(
      coordinator.removeStage(skill, const [], last.id, now: DateTime(2026)),
      isTrue,
    );
    expect(skill.treeNodes.map((node) => node.id), ['middle']);
    expect(
      coordinator.removeStage(skill, const [], middle.id, now: DateTime(2026)),
      isTrue,
    );
    expect(skill.treeNodes, isEmpty);
    expect(coordinator.validateGraph(skill).isValid, isTrue);
  });

  test('removing a branch parent preserves both branches', () {
    final root = _node('root');
    final branch = _node('branch', parent: root.id);
    final left = _node('left', parent: branch.id);
    final right = _node('right', parent: branch.id);
    final skill = _skill(nodes: [root, branch, left, right]);

    expect(
      coordinator.removeStage(skill, const [], branch.id, now: DateTime(2026)),
      isTrue,
    );

    expect(left.prerequisiteIds, ['root']);
    expect(right.prerequisiteIds, ['root']);
    expect(coordinator.validateGraph(skill).isValid, isTrue);
  });

  test('removing a shared stage keeps all valid prerequisites', () {
    final root = _node('root');
    final side = _node('side');
    final shared = _node('shared')
      ..prerequisiteIds = [root.id, side.id, 'stale'];
    final child = _node('child', parent: shared.id);
    final unrelated = _node('unrelated');
    final skill = _skill(nodes: [root, side, shared, child, unrelated]);

    expect(
      coordinator.removeStage(skill, const [], shared.id, now: DateTime(2026)),
      isTrue,
    );

    expect(child.prerequisiteIds, ['root', 'side']);
    expect(unrelated.prerequisiteIds, isEmpty);
    expect(coordinator.validateGraph(skill).isValid, isTrue);
  });

  test('removing a stage cleans already-stale linked task references', () {
    final root = _node('root');
    final removed = _node('removed', parent: root.id);
    final skill = _skill(nodes: [root, removed]);
    final removedTask = _task('removed-task', skill.id, removed.id);
    final staleTask = _task('stale-task', skill.id, 'missing-stage');
    final otherSkillTask = _task('other-task', 'other-skill', removed.id);
    final now = DateTime(2026, 3, 1);

    expect(
      coordinator.removeStage(
        skill,
        [removedTask, staleTask, otherSkillTask],
        removed.id,
        now: now,
      ),
      isTrue,
    );

    expect(removedTask.treeNodeId, isNull);
    expect(staleTask.treeNodeId, isNull);
    expect(otherSkillTask.treeNodeId, removed.id);
    expect(coordinator.validateGraph(skill).isValid, isTrue);
    expect(
      coordinator.removeStage(skill, const [], removed.id, now: now),
      isFalse,
    );
  });

  test('graph validator rejects dangling references and cycles', () {
    final first = _node('first', parent: 'missing');
    final second = _node('second', parent: first.id);
    first.prerequisiteIds.add(second.id);
    final validation = coordinator.validateGraph(
      _skill(nodes: [first, second]),
    );

    expect(validation.isValid, isFalse);
    expect(validation.errors, contains('dangling-prerequisite:first:missing'));
    expect(validation.errors, contains('cycle'));
  });

  test('unified stage update trims fields and reports no-op saves', () {
    final node = _node('stage');
    final skill = _skill(nodes: [node]);

    expect(
      coordinator.updateStage(
        skill,
        node.id,
        title: '  Основа  ',
        description: '  Начать спокойно  ',
        requiredQuestCompletions: 0,
        xpReward: -1,
      ),
      isTrue,
    );
    expect(node.title, 'Основа');
    expect(node.description, 'Начать спокойно');
    expect(node.requiredQuestCompletions, 1);
    expect(node.xpReward, 0);
    expect(
      coordinator.updateStage(
        skill,
        node.id,
        title: node.title,
        description: node.description,
        requiredQuestCompletions: 1,
        xpReward: 0,
      ),
      isFalse,
    );
  });

  test('invalid checklist mutations are no-ops', () {
    final node = _node('node')
      ..checklist = ['One']
      ..checklistDone = [false]
      ..isMastered = true;
    final skill = _skill(nodes: [node]);

    expect(coordinator.toggleChecklist(skill, node.id, 0), isFalse);
    expect(node.checklistDone, [false]);
    expect(
      coordinator.removeStage(skill, const [], 'missing', now: DateTime(2026)),
      isFalse,
    );
  });
}

Skill _skill({required List<SkillTreeNode> nodes}) => Skill(
  id: 'skill',
  name: 'Skill',
  goal: 'Goal',
  color: Colors.blue,
  icon: Icons.star,
  treeNodes: nodes,
);

SkillTreeNode _node(String id, {String? parent, String description = ''}) =>
    SkillTreeNode(
      id: id,
      title: id,
      description: description,
      prerequisiteIds: parent == null ? const [] : [parent],
    );

Task _task(String id, String skillId, String treeNodeId) => Task(
  id: id,
  title: id,
  skillId: skillId,
  xpReward: 20,
  type: TaskType.shortTerm,
  treeNodeId: treeNodeId,
);
