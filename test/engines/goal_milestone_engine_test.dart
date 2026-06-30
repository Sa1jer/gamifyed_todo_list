import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/goal_milestone_engine.dart';
import 'package:todo_list_app/models.dart';

void main() {
  const engine = GoalMilestoneEngine();

  List<int> crossed({
    required double oldProgress,
    required double newProgress,
    Iterable<int> alreadyTriggered = const [],
  }) {
    return engine
        .crossedMilestones(
          oldProgress: oldProgress,
          newProgress: newProgress,
          alreadyTriggered: alreadyTriggered,
        )
        .map((milestone) => milestone.percent)
        .toList();
  }

  test('old 0.0 to new 0.24 triggers nothing', () {
    expect(crossed(oldProgress: 0.0, newProgress: 0.24), isEmpty);
  });

  test('old 0.0 to new 0.25 triggers 25', () {
    expect(crossed(oldProgress: 0.0, newProgress: 0.25), [25]);
  });

  test('old 0.2 to new 0.34 triggers 25', () {
    expect(crossed(oldProgress: 0.2, newProgress: 0.34), [25]);
  });

  test('old 0.34 to new 0.67 triggers 50', () {
    expect(crossed(oldProgress: 0.34, newProgress: 0.67), [50]);
  });

  test('old 0.67 to new 1.0 triggers 100', () {
    expect(crossed(oldProgress: 0.67, newProgress: 1.0), [100]);
  });

  test('old 0.0 to new 1.0 triggers all crossed milestones', () {
    expect(crossed(oldProgress: 0.0, newProgress: 1.0), [25, 50, 100]);
  });

  test('old 0.6 to new 0.7 does not retrigger 50', () {
    expect(crossed(oldProgress: 0.6, newProgress: 0.7), isEmpty);
  });

  test('already triggered milestones are not emitted again', () {
    expect(
      crossed(oldProgress: 0.0, newProgress: 1.0, alreadyTriggered: [25, 50]),
      [100],
    );
  });

  test('progress decrease does not replay old milestones immediately', () {
    expect(crossed(oldProgress: 0.8, newProgress: 0.4), isEmpty);
  });

  test('clamps unsafe inputs before crossing calculation', () {
    expect(
      engine.crossedMilestones(oldProgress: -1, newProgress: 2),
      GoalMilestone.values,
    );
  });
}
