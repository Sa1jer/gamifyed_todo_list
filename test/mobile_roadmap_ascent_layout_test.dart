import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/roadmap_engine.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/presentation/mobile_roadmap_ascent_layout.dart';

RoadmapStageInfo _stage(
  String id,
  String title, {
  List<String> prerequisites = const [],
  RoadmapStageRole role = RoadmapStageRole.locked,
}) {
  return RoadmapStageInfo(
    node: SkillTreeNode(id: id, title: title, prerequisiteIds: prerequisites),
    status: role == RoadmapStageRole.completed
        ? SkillTreeNodeStatus.mastered
        : SkillTreeNodeStatus.locked,
    role: role,
    progress: role == RoadmapStageRole.completed ? 1 : 0,
    depth: 0,
    completedLinkedQuests: 0,
    questTarget: 3,
  );
}

void main() {
  const calculator = MobileRoadMapAscentLayout();

  test('places root and future stages in a bottom-up ascent', () {
    final layout = calculator.calculate(
      viewport: const Size(360, 600),
      stages: [
        _stage('foundation', 'Основа', role: RoadmapStageRole.current),
        _stage('practice', 'Практика', prerequisites: ['foundation']),
        _stage('mastery', 'Мастерство', prerequisites: ['practice']),
      ],
    );

    final foundation = layout.nodes['foundation']!;
    final practice = layout.nodes['practice']!;
    final mastery = layout.nodes['mastery']!;

    expect(layout.rootRadius, greaterThan(foundation.radius));
    expect(layout.rootCenter.dy, greaterThan(foundation.center.dy));
    expect(foundation.center.dy, greaterThan(practice.center.dy));
    expect(practice.center.dy, greaterThan(mastery.center.dy));
    expect(layout.edges, isNotEmpty);
    expect(layout.edges.every((edge) => edge.pointsUpward), isTrue);
    expect(foundation.cardOnLeft, isNot(practice.cardOnLeft));
    expect(practice.cardOnLeft, isNot(mastery.cardOnLeft));
  });

  test('keeps a branched topology without overlapping description cards', () {
    final layout = calculator.calculate(
      viewport: const Size(393, 700),
      stages: [
        _stage('root-stage', 'Общая основа'),
        _stage('left', 'Левая ветка', prerequisites: ['root-stage']),
        _stage('middle', 'Средняя ветка', prerequisites: ['root-stage']),
        _stage('right', 'Правая ветка', prerequisites: ['root-stage']),
      ],
    );

    final root = layout.nodes['root-stage']!;
    final branches = [
      layout.nodes['left']!,
      layout.nodes['middle']!,
      layout.nodes['right']!,
    ];

    expect(layout.rootCenter.dy, greaterThan(root.center.dy));
    expect(
      branches.every((branch) => root.center.dy > branch.center.dy),
      isTrue,
    );
    expect(
      layout.edges.where((edge) => edge.fromId == 'root-stage'),
      hasLength(3),
    );
    for (var index = 0; index < branches.length; index++) {
      for (var other = index + 1; other < branches.length; other++) {
        expect(
          branches[index].cardRect.overlaps(branches[other].cardRect),
          isFalse,
        );
      }
    }
  });

  test(
    'contains cyclic input without unbounded depth or non-finite geometry',
    () {
      final layout = calculator.calculate(
        viewport: const Size(320, 568),
        stages: [
          _stage('a', 'А', prerequisites: ['b']),
          _stage('b', 'Б', prerequisites: ['a']),
        ],
      );

      expect(layout.hasCycle, isTrue);
      expect(layout.size.height.isFinite, isTrue);
      expect(
        layout.nodes.values.every(
          (node) => node.center.dx.isFinite && node.center.dy.isFinite,
        ),
        isTrue,
      );
      expect(layout.edges.every((edge) => edge.pointsUpward), isTrue);
    },
  );

  test('keeps cards inside narrow and large-text mobile graph bounds', () {
    final stages = [
      _stage('base', 'Очень длинное название начального этапа'),
      _stage(
        'future',
        'Очень длинное название следующего будущего этапа',
        prerequisites: ['base'],
      ),
    ];

    for (final width in [320.0, 360.0, 393.0, 430.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        final layout = calculator.calculate(
          viewport: Size(width, 800),
          stages: stages,
          textScale: scale,
        );
        for (final node in layout.nodes.values) {
          expect(node.cardRect.left, greaterThanOrEqualTo(0));
          expect(node.cardRect.right, lessThanOrEqualTo(layout.size.width));
          expect(node.cardRect.top, greaterThanOrEqualTo(0));
          expect(node.cardRect.bottom, lessThanOrEqualTo(layout.size.height));
        }
      }
    }
  });
}
