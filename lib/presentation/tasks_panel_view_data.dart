import '../models.dart';

/// Stable presentation partition for a selected skill's task collection.
///
/// The builder owns filtering and completion ordering so responsive task
/// widgets consume the same deterministic groups without repeating work in
/// their build methods.
class TasksPanelViewData {
  final List<Task> active;
  final List<Task> completed;
  final List<Task> archived;

  const TasksPanelViewData._({
    required this.active,
    required this.completed,
    required this.archived,
  });

  bool get isEmpty => active.isEmpty && completed.isEmpty && archived.isEmpty;

  factory TasksPanelViewData.fromTasks(Iterable<Task> tasks) {
    final active = <Task>[];
    final completed = <Task>[];
    final archived = <Task>[];

    for (final task in tasks) {
      if (!task.isDone) {
        active.add(task);
      } else if (task.isArchived) {
        archived.add(task);
      } else {
        completed.add(task);
      }
    }
    completed.sort(_compareCompletedTasksNewestFirst);
    archived.sort(_compareCompletedTasksNewestFirst);

    return TasksPanelViewData._(
      active: List.unmodifiable(active),
      completed: List.unmodifiable(completed),
      archived: List.unmodifiable(archived),
    );
  }
}

int _compareCompletedTasksNewestFirst(Task a, Task b) {
  final aDate = a.lastCompletedAt ?? a.updatedAt;
  final bDate = b.lastCompletedAt ?? b.updatedAt;
  final byCompletion = bDate.compareTo(aDate);
  if (byCompletion != 0) return byCompletion;
  final byCreated = b.createdAt.compareTo(a.createdAt);
  if (byCreated != 0) return byCreated;
  return a.id.compareTo(b.id);
}
