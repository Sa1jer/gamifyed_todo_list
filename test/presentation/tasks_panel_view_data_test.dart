import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/presentation/tasks_panel_view_data.dart';
import 'package:todo_list_app/utils.dart';

Task _task(
  String id, {
  bool done = false,
  bool archived = false,
  DateTime? completedAt,
}) => Task(
  id: id,
  title: id,
  skillId: 'skill',
  xpReward: 20,
  type: TaskType.shortTerm,
  isDone: done,
  isArchived: archived,
  lastCompletedAt: completedAt,
  createdAt: DateTime.utc(2026, 7, 1),
  updatedAt: DateTime.utc(2026, 7, 1),
);

void main() {
  test('partitions tasks and orders completed groups newest first', () {
    final data = TasksPanelViewData.fromTasks(<Task>[
      _task('active'),
      _task('old', done: true, completedAt: DateTime.utc(2026, 7, 2)),
      _task(
        'archived',
        done: true,
        archived: true,
        completedAt: DateTime.utc(2026, 7, 4),
      ),
      _task('new', done: true, completedAt: DateTime.utc(2026, 7, 3)),
    ]);

    expect(data.active.map((task) => task.id), <String>['active']);
    expect(data.completed.map((task) => task.id), <String>['new', 'old']);
    expect(data.archived.map((task) => task.id), <String>['archived']);
    expect(data.isEmpty, isFalse);
    expect(() => data.completed.add(_task('late')), throwsUnsupportedError);
  });

  test('uses task id as the final deterministic completion tie-break', () {
    final sameTime = DateTime.utc(2026, 7, 2);
    final data = TasksPanelViewData.fromTasks(<Task>[
      _task('b', done: true, completedAt: sameTime),
      _task('a', done: true, completedAt: sameTime),
    ]);

    expect(data.completed.map((task) => task.id), <String>['a', 'b']);
  });
}
