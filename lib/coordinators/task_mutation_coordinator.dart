import '../models.dart';
import '../utils.dart';

class TaskUpdateData {
  const TaskUpdateData({
    required this.title,
    required this.description,
    required this.xpReward,
    required this.type,
    required this.repeatFrequency,
    required this.repeatCustomDays,
    required this.priority,
    required this.minimumAction,
    required this.subtasks,
    required this.tags,
    required this.notificationsEnabled,
    required this.notificationHour,
    required this.notificationMinute,
    required this.treeNodeId,
  });

  final String title;
  final String description;
  final int xpReward;
  final TaskType type;
  final RepeatFrequency repeatFrequency;
  final int repeatCustomDays;
  final Priority priority;
  final String minimumAction;
  final List<String> subtasks;
  final List<String> tags;
  final bool notificationsEnabled;
  final int? notificationHour;
  final int? notificationMinute;
  final String? treeNodeId;
}

class TaskMutationResult {
  const TaskMutationResult({
    required this.task,
    this.notificationWasDisabled = false,
    this.skillIdToSync,
  });

  final Task task;
  final bool notificationWasDisabled;
  final String? skillIdToSync;
}

/// Owns task normalization and collection mutation policy.
///
/// AppState remains responsible for notifications, boss synchronization,
/// persistence scheduling, and notifying listeners.
class TaskMutationCoordinator {
  const TaskMutationCoordinator();

  TaskMutationResult add({
    required List<Task> tasks,
    required Iterable<Skill> skills,
    required Task task,
    required DateTime now,
  }) {
    task.syncSubtaskDone();
    task.normalizeScope();
    task.treeNodeId = task.isSkillTask
        ? normalizedTreeNodeId(skills, task.skillId, task.treeNodeId)
        : null;
    if (task.repeatCustomDays < 1) task.repeatCustomDays = 1;
    task.createdAt = now;
    task.updatedAt = now;
    tasks.add(task);
    return TaskMutationResult(
      task: task,
      skillIdToSync: task.isSkillTask ? task.skillId : null,
    );
  }

  TaskMutationResult update({
    required Task task,
    required Iterable<Skill> skills,
    required TaskUpdateData data,
    required DateTime now,
  }) {
    final oldType = task.type;
    final hadNotification = task.notificationsEnabled;
    final oldMinimumAction = task.minimumAction;

    if (task.isInbox) {
      task.title = data.title;
      task.description = data.description.trim();
      task.priority = data.priority;
      task.subtasks = List.of(data.subtasks);
      task.syncSubtaskDone();
      task.tags = List.of(data.tags);
      task.updatedAt = now;
      task.normalizeScope();
      return TaskMutationResult(
        task: task,
        notificationWasDisabled: hadNotification && !task.notificationsEnabled,
      );
    }

    task.title = data.title;
    task.description = data.description.trim();
    task.xpReward = data.xpReward;
    task.type = data.type;
    task.repeatFrequency = data.repeatFrequency;
    task.repeatCustomDays = data.repeatCustomDays < 1
        ? 1
        : data.repeatCustomDays;
    task.priority = data.priority;
    final nextMinimumAction = data.minimumAction.trim();
    task.minimumAction = nextMinimumAction.isEmpty && task.isMinimumActionDone
        ? oldMinimumAction
        : nextMinimumAction;
    task.subtasks = List.of(data.subtasks);
    task.syncSubtaskDone();
    task.tags = List.of(data.tags);
    task.treeNodeId = normalizedTreeNodeId(
      skills,
      task.skillId,
      data.treeNodeId,
    );
    task.notificationsEnabled = data.notificationsEnabled;
    task.notificationHour = data.notificationHour;
    task.notificationMinute = data.notificationMinute;
    task.normalizeScope();
    task.updatedAt = now;

    if (oldType == TaskType.repeating && data.type != TaskType.repeating) {
      task.streak = 0;
      task.nextResetAt = null;
    } else if (data.type == TaskType.repeating && task.isDone) {
      task.nextResetAt = nextResetFrom(
        task.lastCompletedAt ?? now,
        task.repeatFrequency,
        task.repeatCustomDays,
      );
    }

    return TaskMutationResult(
      task: task,
      notificationWasDisabled: hadNotification && !task.notificationsEnabled,
      skillIdToSync: task.skillId,
    );
  }

  Task? remove(List<Task> tasks, String id) {
    final index = tasks.indexWhere((task) => task.id == id);
    if (index == -1) return null;
    return tasks.removeAt(index);
  }

  bool toggleSubtask(Task task, int index, {required DateTime now}) {
    if (index < 0 || index >= task.subtaskDone.length) return false;
    task.subtaskDone[index] = !task.subtaskDone[index];
    task.updatedAt = now;
    return true;
  }

  String? normalizedTreeNodeId(
    Iterable<Skill> skills,
    String skillId,
    String? nodeId,
  ) {
    final trimmed = nodeId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final skill = skills.where((skill) => skill.id == skillId).firstOrNull;
    if (skill == null) return null;
    return skill.treeNodes.any((node) => node.id == trimmed) ? trimmed : null;
  }
}
