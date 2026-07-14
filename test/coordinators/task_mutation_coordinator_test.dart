import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/coordinators/task_mutation_coordinator.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  const coordinator = TaskMutationCoordinator();
  final now = DateTime(2026, 4, 12, 10);

  test('add normalizes custom days and rejects a stale stage id', () {
    final skill = _skill();
    final tasks = <Task>[];
    final task = _task(treeNodeId: 'stale')..repeatCustomDays = 0;

    coordinator.add(tasks: tasks, skills: [skill], task: task, now: now);

    expect(tasks, [same(task)]);
    expect(task.treeNodeId, isNull);
    expect(task.repeatCustomDays, 1);
    expect(task.createdAt, now);
    expect(task.updatedAt, now);
  });

  test('update keeps completed minimum action when blank is submitted', () {
    final task = _task()
      ..minimumAction = 'Open the document'
      ..minimumActionDoneAt = DateTime(2026, 4, 10)
      ..minimumActionEarnedXP = 3;

    final result = coordinator.update(
      task: task,
      skills: [_skill()],
      data: _updateData(minimumAction: ''),
      now: now,
    );

    expect(task.minimumAction, 'Open the document');
    expect(result.skillIdToSync, task.skillId);
  });

  test('switching a completed repeating task resets recurrence state', () {
    final task = _task(type: TaskType.repeating)
      ..isDone = true
      ..streak = 7
      ..nextResetAt = DateTime(2026, 4, 20);

    coordinator.update(
      task: task,
      skills: [_skill()],
      data: _updateData(type: TaskType.shortTerm),
      now: now,
    );

    expect(task.streak, 0);
    expect(task.nextResetAt, isNull);
  });

  test('inbox update preserves quick-task isolation', () {
    final task = Task(
      id: 'inbox',
      title: 'Quick',
      skillId: kInboxSkillId,
      xpReward: 0,
      type: TaskType.shortTerm,
    )..notificationsEnabled = true;

    final result = coordinator.update(
      task: task,
      skills: [_skill()],
      data: _updateData(
        xpReward: 500,
        type: TaskType.repeating,
        notificationsEnabled: true,
      ),
      now: now,
    );

    expect(task.xpReward, 0);
    expect(task.type, TaskType.shortTerm);
    expect(task.notificationsEnabled, isFalse);
    expect(task.treeNodeId, isNull);
    expect(result.notificationWasDisabled, isTrue);
    expect(result.skillIdToSync, isNull);
  });

  test('remove and subtask toggle mutate only valid targets', () {
    final task = _task()..subtasks = ['One'];
    task.syncSubtaskDone();
    final tasks = [task];

    expect(coordinator.toggleSubtask(task, 0, now: now), isTrue);
    expect(task.subtaskDone, [true]);
    expect(coordinator.toggleSubtask(task, 1, now: now), isFalse);
    expect(coordinator.remove(tasks, task.id), same(task));
    expect(tasks, isEmpty);
    expect(coordinator.remove(tasks, task.id), isNull);
  });
}

Skill _skill() => Skill(
  id: 'skill',
  name: 'Skill',
  goal: 'Goal',
  color: Colors.blue,
  icon: Icons.star,
  treeNodes: [SkillTreeNode(id: 'stage', title: 'Stage')],
);

Task _task({TaskType type = TaskType.shortTerm, String? treeNodeId}) => Task(
  id: 'task',
  title: 'Task',
  skillId: 'skill',
  xpReward: 20,
  type: type,
  treeNodeId: treeNodeId,
);

TaskUpdateData _updateData({
  String minimumAction = 'Small step',
  int xpReward = 30,
  TaskType type = TaskType.shortTerm,
  bool notificationsEnabled = false,
}) => TaskUpdateData(
  title: 'Updated',
  description: 'Description',
  xpReward: xpReward,
  type: type,
  repeatFrequency: RepeatFrequency.daily,
  repeatCustomDays: 1,
  priority: Priority.medium,
  minimumAction: minimumAction,
  subtasks: const [],
  tags: const [],
  notificationsEnabled: notificationsEnabled,
  notificationHour: notificationsEnabled ? 9 : null,
  notificationMinute: notificationsEnabled ? 30 : null,
  treeNodeId: 'stage',
);
