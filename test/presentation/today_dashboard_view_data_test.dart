import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/presentation/today_dashboard_view_data.dart';
import 'package:todo_list_app/utils.dart';

Task _task(
  String id, {
  TaskType type = TaskType.shortTerm,
  Priority priority = Priority.medium,
  DateTime? resetAt,
  String minimumAction = '',
}) => Task(
  id: id,
  title: id,
  skillId: 'skill',
  xpReward: 20,
  type: type,
  priority: priority,
  nextResetAt: resetAt,
  minimumAction: minimumAction,
  createdAt: DateTime.utc(2026, 7, 1),
  updatedAt: DateTime.utc(2026, 7, 1),
);

void main() {
  const builder = TodayDashboardViewDataBuilder();
  final now = DateTime.utc(2026, 7, 15, 12);

  test('uses one explicit clock for risk and next-action ordering', () {
    final normal = _task('normal', priority: Priority.high);
    final risky = _task(
      'risky',
      type: TaskType.repeating,
      resetAt: now.add(const Duration(hours: 4)),
    );

    final data = builder.build(
      tasks: <Task>[normal, risky],
      now: now,
      completedToday: 2,
      xpToday: 40,
      previewEarnedXp: (task) => task.xpReward,
      isActiveStageTask: (_) => false,
    );

    expect(data.nextTaskId, 'risky');
    expect(data.riskyTaskIds, <String>['risky']);
    expect(data.focusTaskIds.first, 'risky');
    expect(data.completedToday, 2);
    expect(data.xpToday, 40);
  });

  test('produces stable unmodifiable ids with an explicit id tie-break', () {
    final first = _task('a');
    final second = _task('b');

    final data = builder.build(
      tasks: <Task>[second, first],
      now: now,
      completedToday: 0,
      xpToday: 0,
      previewEarnedXp: (_) => 20,
      isActiveStageTask: (_) => false,
    );

    expect(data.focusTaskIds, <String>['a', 'b']);
    expect(() => data.focusTaskIds.add('c'), throwsUnsupportedError);
  });
}
