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

    test('simple template creates one road with editable stage count', () {
      final paths = engine.buildTemplatePaths(
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.simple,
          stagesPerPath: 4,
        ),
      );

      expect(paths, hasLength(1));
      expect(paths.single.nodes, hasLength(4));
      expect(paths.single.nodes.first.prerequisiteIds, isEmpty);
      expect(paths.single.nodes[1].prerequisiteIds, [
        paths.single.nodes.first.id,
      ]);
      expect(paths.single.terminalStage, paths.single.nodes.last);
    });

    test('normal template creates two equal roads', () {
      final paths = engine.buildTemplatePaths(
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.normal,
          stagesPerPath: 3,
        ),
      );

      expect(paths, hasLength(2));
      for (final path in paths) {
        expect(path.nodes, hasLength(3));
        expect(path.nodes.first.prerequisiteIds, isEmpty);
        expect(path.nodes[1].prerequisiteIds, [path.nodes.first.id]);
        expect(path.nodes.last.prerequisiteIds, [path.nodes[1].id]);
      }
    });

    test('hard template creates three equal roads', () {
      final nodes = engine.buildTemplate(
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.hard,
          stagesPerPath: 3,
        ),
      );

      expect(nodes, hasLength(9));
      expect(nodes.where((node) => node.prerequisiteIds.isEmpty), hasLength(3));
    });

    test('custom template supports path count and stages per path', () {
      final config = const RoadmapTemplateConfig(
        template: RoadmapTemplate.custom,
        customPathCount: 4,
        stagesPerPath: 2,
      );
      final paths = engine.buildTemplatePaths(config);

      expect(config.pathCount, 4);
      expect(config.safeStagesPerPath, 2);
      expect(paths, hasLength(4));
      expect(paths.expand((path) => path.nodes), hasLength(8));
    });

    test('path layout turns existing chains into roads', () {
      final root = stage('root', 'Основа');
      final next = stage('next', 'Практика', prerequisites: ['root']);
      final secondRoot = stage('other', 'Дыхание');
      final skill = skillWithNodes([next, secondRoot, root]);

      final layout = engine.buildPathLayout(skill);
      final pathIds = layout.paths
          .map((path) => path.nodes.map((node) => node.id).join('>'))
          .toList();

      expect(layout.paths, hasLength(2));
      expect(layout.maxStagesInPath, 2);
      expect(pathIds, contains('root>next'));
      expect(pathIds, contains('other'));
    });

    test('ordered unique stages does not duplicate shared roots', () {
      final root = stage('root', 'Основа');
      final left = stage('left', 'Левая практика', prerequisites: ['root']);
      final right = stage('right', 'Правая практика', prerequisites: ['root']);
      final skill = skillWithNodes([left, right, root]);

      final orderedIds = engine
          .orderedUniqueStages(skill)
          .map((node) => node.id)
          .toList();

      expect(orderedIds, ['root', 'left', 'right']);
    });

    test('path layout resolves terminal stage for any stage on the road', () {
      final root = stage('root', 'Основа');
      final middle = stage('middle', 'Практика', prerequisites: ['root']);
      final terminal = stage(
        'terminal',
        'Результат',
        prerequisites: ['middle'],
      );
      final skill = skillWithNodes([middle, terminal, root]);

      final layout = engine.buildPathLayout(skill);

      expect(layout.terminalStageFor('root')?.id, 'terminal');
      expect(layout.terminalStageFor('middle')?.id, 'terminal');
      expect(layout.terminalStageFor('terminal')?.id, 'terminal');
      expect(engine.terminalStageForNode(skill, 'root')?.id, 'terminal');
      expect(engine.terminalStageForNode(skill, 'missing'), isNull);
    });
  });
}
