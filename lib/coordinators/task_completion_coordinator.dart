import 'dart:math' as math;

import '../models.dart';
import '../utils.dart';

class TaskCompletionMutationResult {
  final int earnedXp;
  final int bonusXp;
  final int profileLevelsGained;
  final int skillLevelsGained;
  final int bestStreak;
  final bool recordsCompletion;

  const TaskCompletionMutationResult({
    required this.earnedXp,
    required this.bonusXp,
    required this.profileLevelsGained,
    required this.skillLevelsGained,
    required this.bestStreak,
    required this.recordsCompletion,
  });
}

class TaskUndoMutationResult {
  final int earnedXp;
  final int skillLevelsLost;
  final DateTime? completedAt;
  final int previousStreak;
  final List<String> consumedBuffIds;
  final bool completedToday;

  const TaskUndoMutationResult({
    required this.earnedXp,
    required this.skillLevelsLost,
    required this.completedAt,
    required this.previousStreak,
    required this.consumedBuffIds,
    required this.completedToday,
  });
}

/// Owns the atomic Task/Profile/Skill changes for completion and undo.
///
/// AppState remains the transaction boundary for rewards, history, bosses,
/// notifications, persistence, and the final listener notification.
class TaskCompletionCoordinator {
  const TaskCompletionCoordinator();

  int totalRewardFor(Task task) {
    final nextStreak = task.type == TaskType.repeating
        ? task.streak + 1
        : task.streak;
    final multiplier = task.type == TaskType.repeating
        ? multiplierForStreak(nextStreak)
        : 1;
    return task.xpReward * multiplier;
  }

  int baseEarnedFor(Task task) {
    if (task.isInbox) return 0;
    final totalReward = totalRewardFor(task);
    if (task.type == TaskType.repeating) return totalReward;
    final alreadyEarned = task.minimumActionEarnedXP.clamp(0, totalReward);
    return math.max(0, totalReward - alreadyEarned);
  }

  int previewMinimumActionXp(Task task, {required double ratio}) {
    if (!canCompleteMinimumAction(task)) return 0;
    return math.max(1, (totalRewardFor(task) * ratio).round());
  }

  bool canCompleteMinimumAction(Task task) {
    if (task.isInbox) return false;
    return task.hasMinimumAction && !task.isDone && !task.isMinimumActionDone;
  }

  TaskCompletionMutationResult completeTask({
    required Task task,
    required Skill? skill,
    required UserProfile profile,
    required int bonusXp,
    required List<String> consumedBuffIds,
    required int currentBestStreak,
    required DateTime now,
  }) {
    final totalReward = totalRewardFor(task);
    final alreadyEarned = task.type == TaskType.repeating
        ? 0
        : task.minimumActionEarnedXP.clamp(0, totalReward);
    final earned = math.max(0, totalReward - alreadyEarned) + bonusXp;

    task.isDone = true;
    task.isArchived = false;
    task.earnedXP = alreadyEarned + earned;
    task.bonusXpEarned = bonusXp;
    task.consumedBuffIds = List.of(consumedBuffIds);
    task.lastCompletedAt = now;
    task.updatedAt = now;

    if (task.type == TaskType.repeating) {
      task.streak += 1;
      task.nextResetAt = nextResetFrom(
        now,
        task.repeatFrequency,
        task.repeatCustomDays,
      );
    }

    profile.totalXpEarned += earned;
    final profileLevelsGained = profile.addXP(earned);
    final skillLevelsGained = skill?.addXP(earned) ?? 0;

    return TaskCompletionMutationResult(
      earnedXp: earned,
      bonusXp: bonusXp,
      profileLevelsGained: profileLevelsGained,
      skillLevelsGained: skillLevelsGained,
      bestStreak: math.max(currentBestStreak, task.streak),
      recordsCompletion: true,
    );
  }

  TaskCompletionMutationResult completeMinimumAction({
    required Task task,
    required Skill? skill,
    required UserProfile profile,
    required int earnedXp,
    required int currentBestStreak,
    required DateTime now,
  }) {
    task.minimumActionDoneAt = now;
    task.minimumActionEarnedXP = earnedXp;
    task.bonusXpEarned = 0;
    task.consumedBuffIds = <String>[];
    task.updatedAt = now;

    final recordsCompletion = task.type == TaskType.repeating;
    if (recordsCompletion) {
      task.isDone = true;
      task.isArchived = false;
      task.earnedXP = earnedXp;
      task.lastCompletedAt = now;
      task.streak += 1;
      task.nextResetAt = nextResetFrom(
        now,
        task.repeatFrequency,
        task.repeatCustomDays,
      );
    }

    profile.totalXpEarned += earnedXp;
    final profileLevelsGained = profile.addXP(earnedXp);
    final skillLevelsGained = skill?.addXP(earnedXp) ?? 0;

    return TaskCompletionMutationResult(
      earnedXp: earnedXp,
      bonusXp: 0,
      profileLevelsGained: profileLevelsGained,
      skillLevelsGained: skillLevelsGained,
      bestStreak: math.max(currentBestStreak, task.streak),
      recordsCompletion: recordsCompletion,
    );
  }

  TaskCompletionMutationResult completeInboxTask({
    required Task task,
    required UserProfile profile,
    required int earnedXp,
    required int currentBestStreak,
    required DateTime now,
  }) {
    task.isDone = true;
    task.isArchived = false;
    task.earnedXP = earnedXp;
    task.bonusXpEarned = 0;
    task.consumedBuffIds = <String>[];
    task.lastCompletedAt = now;
    task.updatedAt = now;
    profile.totalXpEarned += earnedXp;
    final profileLevelsGained = profile.addXP(earnedXp);

    return TaskCompletionMutationResult(
      earnedXp: earnedXp,
      bonusXp: 0,
      profileLevelsGained: profileLevelsGained,
      skillLevelsGained: 0,
      bestStreak: currentBestStreak,
      recordsCompletion: true,
    );
  }

  TaskUndoMutationResult undo({
    required Task task,
    required Skill? skill,
    required UserProfile profile,
    required DateTime now,
  }) {
    final completedAt = task.lastCompletedAt;
    final previousStreak = task.streak;
    final consumedBuffIds = List<String>.of(task.consumedBuffIds);
    final restoresMinimumProgress =
        !task.isInbox &&
        task.type != TaskType.repeating &&
        task.minimumActionDoneAt != null &&
        task.minimumActionEarnedXP > 0;
    final earned = restoresMinimumProgress
        ? math.max(0, task.earnedXP - task.minimumActionEarnedXP)
        : task.earnedXP;
    final skillLevelBefore = skill?.level ?? 1;

    task.isDone = false;
    task.isArchived = false;
    if (!task.isInbox && task.type == TaskType.repeating) {
      task.streak = math.max(0, task.streak - 1);
    }
    task.earnedXP = 0;
    task.bonusXpEarned = 0;
    task.lastCompletedAt = null;
    task.updatedAt = now;
    if (!restoresMinimumProgress) {
      task.minimumActionDoneAt = null;
      task.minimumActionEarnedXP = 0;
    }
    task.consumedBuffIds = <String>[];

    if (earned > 0) {
      profile.totalXpEarned = math.max(0, profile.totalXpEarned - earned);
      profile.removeXP(earned);
      if (!task.isInbox) skill?.removeXP(earned);
    }

    return TaskUndoMutationResult(
      earnedXp: earned,
      skillLevelsLost: task.isInbox
          ? 0
          : math.max(0, skillLevelBefore - (skill?.level ?? 1)),
      completedAt: completedAt,
      previousStreak: previousStreak,
      consumedBuffIds: consumedBuffIds,
      completedToday: completedAt != null && isSameDate(completedAt, now),
    );
  }
}
