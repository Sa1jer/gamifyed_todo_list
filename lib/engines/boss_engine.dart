import 'dart:math' as math;

import '../models.dart';
import '../utils.dart' show TaskType;

/// Pure, side-effect-free engine that derives [BossSnapshot]s and applies
/// snapshot-driven HP/defeat updates onto [Boss] instances.
///
/// The engine is intentionally decoupled from [AppState]: it accepts
/// plain collections plus a small set of injectable hooks for the few
/// side effects that must happen when a boss transitions to "defeated"
/// (achievement unlock + reward chest grant). This keeps the geometry of
/// the calculation testable in isolation, while leaving cross-cutting
/// concerns (notifications, persistence, history) in [AppState].
class BossEngine {
  const BossEngine();

  /// A repeatable predicate equivalent to the legacy
  /// `AppState.canCompleteMinimumAction`. Extracted as a pure helper so the
  /// engine has no back-reference to [AppState].
  static bool canStartMinimumAction(Task task) =>
      task.hasMinimumAction && !task.isDone && !task.isMinimumActionDone;

  /// Build a [BossSnapshot] for [boss] given the full [tasks] list and
  /// the (optional) owning [skill]. The snapshot is deterministic and
  /// depends only on its inputs and the current wall clock for the
  /// "urgent repeating" window.
  BossSnapshot buildSnapshot({
    required Boss boss,
    required List<Task> tasks,
    required Skill? skill,
    DateTime? now,
  }) {
    final ts = now ?? DateTime.now();
    final targetStreak = boss.targetStreak < 1 ? 1 : boss.targetStreak;

    final skillTasks = tasks
        .where((task) => task.isSkillTask && task.skillId == boss.skillId)
        .toList();
    final repeatingTasks = skillTasks
        .where((task) => task.type == TaskType.repeating)
        .toList();
    final highPriorityTasks = skillTasks
        .where((task) => task.priority == Priority.high)
        .toList();
    final minimumTasks = skillTasks
        .where((task) => task.hasMinimumAction)
        .toList();

    final currentStreak = repeatingTasks.fold<int>(
      0,
      (max, task) => math.max(max, task.streak),
    );
    final completedTasks = skillTasks.where((task) => task.isDone).length;
    final startedTasks = minimumTasks
        .where((task) => task.isMinimumActionDone || task.isDone)
        .length;
    final relievedHighPriorityTasks = highPriorityTasks
        .where((task) => task.isDone || task.isMinimumActionDone)
        .length;
    final checklistTotal = skill?.checklist.length ?? 0;
    final checklistCompleted = skill?.checklistCompletedCount ?? 0;
    final totalTreeNodes = skill?.treeNodes.length ?? 0;
    final masteredTreeNodes = skill?.masteredTreeNodeCount ?? 0;
    final urgentRepeatingTasks = repeatingTasks
        .where((task) => !task.isDone)
        .where((task) {
          final nextResetAt = task.nextResetAt;
          if (nextResetAt == null) return false;
          return nextResetAt.difference(ts) <= const Duration(hours: 24);
        })
        .length;
    final stalledHighPriorityTasks = highPriorityTasks
        .where((task) => !task.isDone && !task.isMinimumActionDone)
        .length;

    final contributions = <({double value, double weight})>[
      if (repeatingTasks.isNotEmpty)
        (value: (currentStreak / targetStreak).clamp(0.0, 1.0), weight: 0.32),
      if (highPriorityTasks.isNotEmpty)
        (
          value: (relievedHighPriorityTasks / highPriorityTasks.length).clamp(
            0.0,
            1.0,
          ),
          weight: 0.26,
        ),
      if (minimumTasks.isNotEmpty)
        (
          value: (startedTasks / minimumTasks.length).clamp(0.0, 1.0),
          weight: 0.18,
        ),
      if (skillTasks.isNotEmpty)
        (
          value: (completedTasks / skillTasks.length).clamp(0.0, 1.0),
          weight: 0.12,
        ),
      if (checklistTotal > 0)
        (
          value: (checklistCompleted / checklistTotal).clamp(0.0, 1.0),
          weight: 0.10,
        ),
      if (totalTreeNodes > 0)
        (
          value: (masteredTreeNodes / totalTreeNodes).clamp(0.0, 1.0),
          weight: 0.14,
        ),
    ];

    final totalWeight = contributions.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    final weightedScore = contributions.fold<double>(
      0,
      (sum, item) => sum + item.value * item.weight,
    );
    final impactProgress = totalWeight == 0
        ? 0.0
        : (weightedScore / totalWeight).clamp(0.0, 1.0);

    final streakProgress = repeatingTasks.isEmpty
        ? 0.0
        : (currentStreak / targetStreak).clamp(0.0, 1.0);
    final priorityProgress = highPriorityTasks.isEmpty
        ? 0.0
        : (relievedHighPriorityTasks / highPriorityTasks.length).clamp(
            0.0,
            1.0,
          );
    final startProgress = minimumTasks.isEmpty
        ? 0.0
        : (startedTasks / minimumTasks.length).clamp(0.0, 1.0);
    final completionProgress = skillTasks.isEmpty
        ? 0.0
        : (completedTasks / skillTasks.length).clamp(0.0, 1.0);
    final checklistProgress = checklistTotal == 0
        ? 0.0
        : (checklistCompleted / checklistTotal).clamp(0.0, 1.0);
    final treeProgress = totalTreeNodes == 0
        ? 0.0
        : (masteredTreeNodes / totalTreeNodes).clamp(0.0, 1.0);

    final isUnderAttack =
        urgentRepeatingTasks > 0 || stalledHighPriorityTasks > 0;

    final phaseLabel = boss.isDefeated
        ? 'Побеждён'
        : impactProgress >= 0.85
        ? 'При смерти'
        : impactProgress >= 0.6
        ? 'Ослабевает'
        : isUnderAttack
        ? 'Атакует'
        : impactProgress >= 0.3
        ? 'Выжидает'
        : 'Силен';

    final recommendation = urgentRepeatingTasks > 0
        ? 'Удержи повторяющиеся квесты: сопротивление восстановится, если пропустить день.'
        : stalledHighPriorityTasks > 0
        ? 'Закрой важный квест по навыку, чтобы сбить давление.'
        : minimumTasks.any(canStartMinimumAction)
        ? 'Сделай лёгкий старт по крупному квесту — это тоже снижает давление.'
        : totalTreeNodes > 0 && masteredTreeNodes < totalTreeNodes
        ? 'Освой следующий этап карты мастерства — это сильно ослабит сопротивление.'
        : checklistTotal > 0 && checklistCompleted < checklistTotal
        ? 'Продвигай критерии навыка — они тоже ослабляют сопротивление.'
        : 'Поддерживай темп по навыку: любой прогресс снижает сопротивление.';

    return BossSnapshot(
      currentStreak: currentStreak,
      targetStreak: targetStreak,
      completedTasks: completedTasks,
      totalTasks: skillTasks.length,
      startedTasks: startedTasks,
      startableTasks: minimumTasks.length,
      checklistCompleted: checklistCompleted,
      checklistTotal: checklistTotal,
      masteredTreeNodes: masteredTreeNodes,
      totalTreeNodes: totalTreeNodes,
      urgentRepeatingTasks: urgentRepeatingTasks,
      stalledHighPriorityTasks: stalledHighPriorityTasks,
      impactProgress: impactProgress,
      streakProgress: streakProgress,
      priorityProgress: priorityProgress,
      startProgress: startProgress,
      completionProgress: completionProgress,
      checklistProgress: checklistProgress,
      treeProgress: treeProgress,
      isUnderAttack: isUnderAttack,
      phaseLabel: phaseLabel,
      recommendation: recommendation,
    );
  }

  /// Update every boss bound to [skillId] using snapshot-driven HP and
  /// defeat status. When a boss transitions from alive to defeated, the
  /// engine invokes [onBossDefeated] exactly once so the caller can
  /// trigger achievements, reward chests, persistence, etc.
  ///
  /// All mutations happen in-place on the [bosses] list. Returns the set
  /// of boss ids that were newly defeated by this sync.
  Set<String> syncForSkill({
    required String skillId,
    required List<Boss> bosses,
    required List<Task> tasks,
    required Skill? skill,
    void Function(Boss boss, BossSnapshot snapshot)? onBossDefeated,
    DateTime? now,
  }) {
    final newlyDefeated = <String>{};
    final ts = now ?? DateTime.now();

    for (final boss in bosses) {
      if (boss.skillId != skillId) continue;

      final snapshot = buildSnapshot(
        boss: boss,
        tasks: tasks,
        skill: skill,
        now: ts,
      );
      boss.currentStreak = snapshot.currentStreak;
      final nextHp = ((1 - snapshot.impactProgress) * boss.maxHp).round().clamp(
        0,
        boss.maxHp,
      );
      final shouldBeDefeated = nextHp <= 0 || snapshot.impactProgress >= 0.999;

      if (!shouldBeDefeated) {
        boss.isDefeated = false;
        boss.defeatedAt = null;
        boss.hp = nextHp;
        continue;
      }

      boss.hp = 0;
      if (!boss.isDefeated) {
        boss.isDefeated = true;
        boss.defeatedAt = ts;
        newlyDefeated.add(boss.id);
        if (onBossDefeated != null) onBossDefeated(boss, snapshot);
      }
    }

    return newlyDefeated;
  }
}
