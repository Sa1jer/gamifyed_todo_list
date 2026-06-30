import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/goal_progress_engine.dart';
import 'package:todo_list_app/models.dart';

void main() {
  const engine = GoalProgressEngine();

  SkillTreeNode stage(String id, {bool mastered = false}) {
    return SkillTreeNode(id: id, title: id, isMastered: mastered);
  }

  Skill skillWithStages(List<SkillTreeNode> stages) {
    return Skill(
      id: 'skill-1',
      name: 'Навык',
      goal: 'Достичь цели',
      color: Colors.orange,
      icon: Icons.flag,
      treeNodes: stages,
    );
  }

  test('zero stages returns neutral zero progress', () {
    final progress = engine.snapshotForSkill(skillWithStages([]));

    expect(progress.value, 0.0);
    expect(progress.isEmpty, isTrue);
    expect(progress.isComplete, isFalse);
  });

  for (final testCase in [
    (completed: 0, total: 3, expected: 0.0),
    (completed: 1, total: 4, expected: 0.25),
    (completed: 2, total: 4, expected: 0.5),
    (completed: 4, total: 4, expected: 1.0),
  ]) {
    test('${testCase.completed} of ${testCase.total} stages', () {
      final stages = List.generate(
        testCase.total,
        (index) => stage('stage-$index', mastered: index < testCase.completed),
      );

      final progress = engine.snapshotForSkill(skillWithStages(stages));

      expect(progress.value, testCase.expected);
    });
  }

  test('count inputs are clamped to a safe range', () {
    expect(
      engine.snapshotFromCounts(completedStages: 8, totalStages: 4).value,
      1.0,
    );
    expect(
      engine.snapshotFromCounts(completedStages: -2, totalStages: 4).value,
      0.0,
    );
    expect(
      engine.snapshotFromCounts(completedStages: 2, totalStages: -1).value,
      0.0,
    );
  });

  test('stages shared by multiple roads are counted once by id', () {
    final progress = engine.snapshotForStages([
      stage('shared', mastered: true),
      stage('left'),
      stage('shared', mastered: true),
      stage('right'),
    ]);

    expect(progress.completedStages, 1);
    expect(progress.totalStages, 3);
    expect(progress.value, closeTo(1 / 3, 0.0001));
  });
}
