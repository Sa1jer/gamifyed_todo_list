import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/roadmap_engine.dart';
import 'package:todo_list_app/models.dart';

void main() {
  group('RoadmapEngine', () {
    const engine = RoadmapEngine();

    Skill skillWithNodes(List<SkillTreeNode> nodes) {
      return Skill(
        id: 'skill-1',
        name: 'Подтягивания',
        goal: 'Подтягиваться 20 раз',
        color: Colors.orange,
        icon: Icons.fitness_center,
        treeNodes: nodes,
      );
    }

    SkillTreeNode stage(
      String id,
      String title, {
      List<String> prerequisites = const [],
      bool mastered = false,
      int target = 3,
    }) {
      return SkillTreeNode(
        id: id,
        title: title,
        prerequisiteIds: prerequisites,
        isMastered: mastered,
        requiredQuestCompletions: target,
      );
    }

    test('empty skill has no roadmap focus', () {
      final snapshot = engine.buildSnapshot(skillWithNodes([]));

      expect(snapshot.isEmpty, isTrue);
      expect(snapshot.currentStage, isNull);
      expect(snapshot.nextStage, isNull);
      expect(snapshot.overallProgress, 0);
    });

    test('linear stages expose current and next stage', () {
      final root = stage('root', 'Основа');
      final next = stage('next', 'Первый результат', prerequisites: ['root']);
      final skill = skillWithNodes([next, root]);

      final snapshot = engine.buildSnapshot(skill);

      expect(snapshot.currentStage?.node.id, 'root');
      expect(snapshot.nextStage?.node.id, 'next');
      expect(snapshot.path.map((item) => item.node.id), ['root', 'next']);
      expect(snapshot.currentStage?.role, RoadmapStageRole.current);
      expect(snapshot.nextStage?.role, RoadmapStageRole.next);
    });

    test('mastered root moves focus to unlocked child', () {
      final root = stage('root', 'Основа', mastered: true);
      final next = stage('next', 'Первый результат', prerequisites: ['root']);
      final skill = skillWithNodes([root, next]);

      final snapshot = engine.buildSnapshot(skill);

      expect(snapshot.currentStage?.node.id, 'next');
      expect(snapshot.nextStage, isNull);
      expect(snapshot.overallProgress, 0.5);
      expect(snapshot.stages.first.role, RoadmapStageRole.completed);
    });

    test('linked quest counts feed stage progress', () {
      final root = stage('root', 'Основа', target: 5);
      final skill = skillWithNodes([root]);

      final snapshot = engine.buildSnapshot(
        skill,
        completedQuestCountsByNodeId: {'root': 2},
      );

      expect(snapshot.currentStage?.completedLinkedQuests, 2);
      expect(snapshot.currentStage?.questTarget, 5);
      expect(snapshot.currentStage?.progress, 0.4);
    });

    test('templates create deterministic roadmap structures', () {
      final linear = engine.buildTemplate(RoadmapTemplate.linear);
      final branching = engine.buildTemplate(RoadmapTemplate.branching);

      expect(linear, hasLength(5));
      expect(linear.first.prerequisiteIds, isEmpty);
      expect(linear[1].prerequisiteIds, [linear.first.id]);

      expect(branching, hasLength(4));
      expect(branching[1].prerequisiteIds, [branching.first.id]);
      expect(branching[2].prerequisiteIds, [branching.first.id]);
      expect(branching.last.prerequisiteIds, [
        branching[1].id,
        branching[2].id,
      ]);
    });
  });
}
