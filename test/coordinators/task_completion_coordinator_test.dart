import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/coordinators/task_completion_coordinator.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  const coordinator = TaskCompletionCoordinator();
  final now = DateTime(2026, 7, 15, 12);

  test('completion credits only the remainder after a minimum action', () {
    final profile = UserProfile(name: 'Tester');
    final skill = _skill();
    final task = _task()
      ..minimumAction = 'Open the document'
      ..minimumActionDoneAt = now.subtract(const Duration(minutes: 5))
      ..minimumActionEarnedXP = 6;

    final result = coordinator.completeTask(
      task: task,
      skill: skill,
      profile: profile,
      bonusXp: 4,
      consumedBuffIds: const ['buff'],
      currentBestStreak: 0,
      now: now,
    );

    expect(result.earnedXp, 18);
    expect(task.earnedXP, 24);
    expect(task.bonusXpEarned, 4);
    expect(task.consumedBuffIds, ['buff']);
    expect(profile.totalXpEarned, 18);
    expect(profile.xp, 18);
    expect(skill.xp, 18);
  });

  test('undo preserves credited minimum-action progress for a normal task', () {
    final profile = UserProfile(name: 'Tester');
    final skill = _skill();
    final task = _task()
      ..minimumAction = 'Open the document'
      ..minimumActionDoneAt = now.subtract(const Duration(minutes: 5))
      ..minimumActionEarnedXP = 6;
    coordinator.completeTask(
      task: task,
      skill: skill,
      profile: profile,
      bonusXp: 4,
      consumedBuffIds: const ['buff'],
      currentBestStreak: 0,
      now: now,
    );

    final result = coordinator.undo(
      task: task,
      skill: skill,
      profile: profile,
      now: now.add(const Duration(minutes: 1)),
    );

    expect(result.earnedXp, 18);
    expect(result.consumedBuffIds, ['buff']);
    expect(task.isDone, isFalse);
    expect(task.minimumActionEarnedXP, 6);
    expect(task.minimumActionDoneAt, isNotNull);
    expect(profile.totalXpEarned, 0);
    expect(profile.xp, 0);
    expect(skill.xp, 0);
  });

  test('inbox completion credits profile only and undo is symmetric', () {
    final profile = UserProfile(name: 'Tester');
    final task = Task(
      id: 'inbox',
      title: 'Quick action',
      skillId: kInboxSkillId,
      xpReward: 0,
      type: TaskType.shortTerm,
    );

    final completion = coordinator.completeInboxTask(
      task: task,
      profile: profile,
      earnedXp: 10,
      currentBestStreak: 3,
      now: now,
    );

    expect(completion.earnedXp, 10);
    expect(completion.skillLevelsGained, 0);
    expect(task.earnedXP, 10);
    expect(profile.totalXpEarned, 10);

    final undo = coordinator.undo(
      task: task,
      skill: null,
      profile: profile,
      now: now,
    );
    expect(undo.earnedXp, 10);
    expect(task.isDone, isFalse);
    expect(profile.totalXpEarned, 0);
    expect(profile.xp, 0);
  });

  test('repeating reward uses the next streak multiplier', () {
    final task = _task(type: TaskType.repeating)..streak = 4;

    expect(coordinator.totalRewardFor(task), task.xpReward * 2);
  });
}

Skill _skill() => Skill(
  id: 'skill',
  name: 'Skill',
  goal: 'Goal',
  color: Colors.blue,
  icon: Icons.star,
);

Task _task({TaskType type = TaskType.shortTerm}) =>
    Task(id: 'task', title: 'Task', skillId: 'skill', xpReward: 20, type: type);
