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

  test('removing a stage clears graph and linked task references', () {
    final removed = _node('removed');
    final child = _node('child', parent: removed.id);
    final skill = _skill(nodes: [removed, child]);
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

    expect(skill.treeNodes.map((node) => node.id), ['child']);
    expect(child.prerequisiteIds, isEmpty);
    expect(task.treeNodeId, isNull);
    expect(task.updatedAt, now);
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
