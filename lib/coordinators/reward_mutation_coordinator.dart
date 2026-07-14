import 'dart:math' as math;

import '../models.dart';
import '../utils.dart';

typedef BuffPreview = ({int bonusXp, int bonusPercent});
typedef ConsumedBuffOutcome = ({
  int bonusXp,
  int bonusPercent,
  List<String> buffIds,
});

/// Owns reward-chest and buff list mutations.
///
/// The coordinator deliberately has no persistence or listener dependency.
/// AppState remains responsible for deciding when a mutation is part of a
/// complete transaction and for scheduling one save and one notification.
class RewardMutationCoordinator {
  static const int maxBuffBonusPercent = 50;
  static const Duration buffLifetime = Duration(hours: 24);

  const RewardMutationCoordinator();

  BuffPreview previewBuffOutcome({
    required List<Buff> buffs,
    required Task task,
    required int baseEarned,
  }) {
    if (baseEarned <= 0) return (bonusXp: 0, bonusPercent: 0);

    final totalBonusPercent = buffs
        .where((buff) => buff.isActive && buffAppliesToTask(buff, task))
        .fold<int>(0, (sum, buff) => sum + buff.bonusPercent);
    final bonusPercent = math.min(maxBuffBonusPercent, totalBonusPercent);
    final bonusXp = bonusPercent <= 0
        ? 0
        : math.max(1, (baseEarned * bonusPercent / 100).round());
    return (bonusXp: bonusXp, bonusPercent: bonusPercent);
  }

  ConsumedBuffOutcome consumeBuffsForTask({
    required List<Buff> buffs,
    required Task task,
    required int baseEarned,
  }) {
    final outcome = previewBuffOutcome(
      buffs: buffs,
      task: task,
      baseEarned: baseEarned,
    );
    if (outcome.bonusXp == 0) {
      return (bonusXp: 0, bonusPercent: 0, buffIds: const <String>[]);
    }

    final consumedBuffIds = <String>[];
    var consumedBonusPercent = 0;
    for (final buff in buffs.where((buff) => buff.isActive).toList()) {
      if (!buffAppliesToTask(buff, task)) continue;
      if (consumedBonusPercent >= maxBuffBonusPercent) continue;
      buff.charges = math.max(0, buff.charges - 1);
      consumedBuffIds.add(buff.id);
      consumedBonusPercent = math.min(
        maxBuffBonusPercent,
        consumedBonusPercent + buff.bonusPercent,
      );
    }
    return (
      bonusXp: outcome.bonusXp,
      bonusPercent: outcome.bonusPercent,
      buffIds: consumedBuffIds,
    );
  }

  bool buffAppliesToTask(Buff buff, Task task) {
    if (task.isInbox) return false;
    return switch (buff.type) {
      BuffType.nextQuestXpBoost => true,
      BuffType.questRushXpBoost => true,
      BuffType.skillFocusXpBoost =>
        buff.skillId == null || buff.skillId == task.skillId,
    };
  }

  Buff? openChest({
    required String chestId,
    required List<RewardChest> rewardChests,
    required List<Buff> buffs,
    required math.Random random,
    required Skill? Function(String id) skillById,
    DateTime? now,
  }) {
    RewardChest? chest;
    for (final candidate in rewardChests) {
      if (candidate.id == chestId) {
        chest = candidate;
        break;
      }
    }
    if (chest == null || chest.isOpened) return null;

    final openedAt = now ?? DateTime.now();
    chest.openedAt = openedAt;
    final buff = _createBuffFromChest(
      chest: chest,
      random: random,
      skill: chest.skillId == null ? null : skillById(chest.skillId!),
      now: openedAt,
    );
    buffs.add(buff);
    return buff;
  }

  void unlockDailyRewardChests({
    required DailyStats? stats,
    required List<RewardChest> rewardChests,
    required List<RewardChest> pendingNotifications,
    bool notify = true,
    DateTime? now,
  }) {
    if (stats == null || stats.tasksCompleted < 5) return;

    final key = dayKey(stats.date);
    unlockRewardChest(
      rewardChests: rewardChests,
      pendingNotifications: pendingNotifications,
      sourceKey: 'daily5:$key',
      title: 'Сундук дисциплины',
      description:
          'Пять закрытых квестов за день. Внутри эффект, который усилит следующий рывок.',
      rarity: RewardRarity.common,
      notify: notify,
      now: now,
    );

    if (stats.tasksCompleted < 10) return;
    unlockRewardChest(
      rewardChests: rewardChests,
      pendingNotifications: pendingNotifications,
      sourceKey: 'daily10:$key',
      title: 'Редкий сундук продуктивности',
      description:
          'Десять закрытых квестов за день. Внутри более сильный эффект на серию квестов.',
      rarity: RewardRarity.rare,
      notify: notify,
      now: now,
    );
  }

  void unlockStreakRewardChest({
    required Task task,
    required List<RewardChest> rewardChests,
    required List<RewardChest> pendingNotifications,
    bool notify = true,
    DateTime? now,
  }) {
    if (!task.isSkillTask || task.type != TaskType.repeating) return;

    final milestone = switch (task.streak) {
      7 => (rarity: RewardRarity.rare, title: 'Сундук серии'),
      30 => (rarity: RewardRarity.epic, title: 'Эпический сундук серии'),
      _ => null,
    };
    if (milestone == null) return;

    unlockRewardChest(
      rewardChests: rewardChests,
      pendingNotifications: pendingNotifications,
      sourceKey: 'streak:${task.id}:${task.streak}',
      title: milestone.title,
      description:
          'Трофей за серию ${task.streak} дней по квесту «${task.title}».',
      rarity: milestone.rarity,
      skillId: task.skillId,
      notify: notify,
      now: now,
    );
  }

  void grantBehaviorBuffs({
    required Task task,
    required DailyStats? stats,
    required List<HistoryEntry> completions,
    required List<Buff> buffs,
    required List<Buff> pendingNotifications,
    DateTime? now,
  }) {
    if (!task.isSkillTask || stats == null) return;

    final createdAt = now ?? DateTime.now();
    final key = dayKey(stats.date);
    final expiresAt = createdAt.add(buffLifetime);

    if (stats.tasksCompleted >= 3) {
      grantBehaviorBuff(
        buffs: buffs,
        pendingNotifications: pendingNotifications,
        sourceKey: 'flow3:$key',
        type: BuffType.questRushXpBoost,
        title: 'Поток',
        description:
            'Три квеста за день запустили поток: следующие 2 квеста дадут +10% XP.',
        bonusPercent: 10,
        charges: 2,
        expiresAt: expiresAt,
        now: createdAt,
      );
    }

    if (completions.length < 2) return;
    final last = completions.last;
    final previous = completions[completions.length - 2];
    if (last.skillId != task.skillId || previous.skillId != task.skillId) {
      return;
    }

    grantBehaviorBuff(
      buffs: buffs,
      pendingNotifications: pendingNotifications,
      sourceKey: 'focus:$key:${task.skillId}',
      type: BuffType.skillFocusXpBoost,
      title: 'Фокус',
      description:
          'Два квеста одного навыка подряд: следующий квест этого навыка даст +12% XP.',
      bonusPercent: 12,
      charges: 1,
      skillId: task.skillId,
      expiresAt: expiresAt,
      now: createdAt,
    );
  }

  Buff? grantBehaviorBuff({
    required List<Buff> buffs,
    required List<Buff> pendingNotifications,
    required String sourceKey,
    required BuffType type,
    required String title,
    required String description,
    required int bonusPercent,
    required int charges,
    required DateTime expiresAt,
    required DateTime now,
    String? skillId,
  }) {
    if (buffs.any((buff) => buff.sourceKey == sourceKey)) return null;

    final buff = Buff(
      id: uid(),
      type: type,
      title: title,
      description: description,
      bonusPercent: bonusPercent,
      charges: charges,
      skillId: skillId,
      sourceKey: sourceKey,
      createdAt: now,
      expiresAt: expiresAt,
    );
    buffs.add(buff);
    pendingNotifications.add(buff);
    return buff;
  }

  RewardChest? unlockRewardChest({
    required List<RewardChest> rewardChests,
    required List<RewardChest> pendingNotifications,
    required String sourceKey,
    required String title,
    required String description,
    required RewardRarity rarity,
    String? skillId,
    bool notify = true,
    DateTime? now,
  }) {
    if (rewardChests.any((chest) => chest.sourceKey == sourceKey)) return null;

    final chest = RewardChest(
      id: uid(),
      title: title,
      description: description,
      rarity: rarity,
      sourceKey: sourceKey,
      skillId: skillId,
      unlockedAt: now ?? DateTime.now(),
    );
    rewardChests.add(chest);
    if (notify) pendingNotifications.add(chest);
    return chest;
  }

  void restoreConsumedBuffs({
    required List<Buff> buffs,
    required List<String> buffIds,
  }) {
    if (buffIds.isEmpty) return;
    for (final buffId in buffIds) {
      for (final buff in buffs) {
        if (buff.id == buffId) {
          buff.charges += 1;
          break;
        }
      }
    }
  }

  void removeSources({
    required Set<String> sourceKeys,
    required List<RewardChest> rewardChests,
    required List<Buff> buffs,
    required List<Task> tasks,
    required List<RewardChest> pendingRewardNotifications,
    required List<Buff> pendingBuffNotifications,
  }) {
    for (final sourceKey in sourceKeys) {
      _removeRewardChestBySourceKey(
        sourceKey: sourceKey,
        rewardChests: rewardChests,
        buffs: buffs,
        tasks: tasks,
        pendingRewardNotifications: pendingRewardNotifications,
        pendingBuffNotifications: pendingBuffNotifications,
      );
      _removeBuffsWhere(
        buffs: buffs,
        tasks: tasks,
        pendingNotifications: pendingBuffNotifications,
        shouldRemove: (buff) => buff.sourceKey == sourceKey,
      );
    }
  }

  String dayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Buff _createBuffFromChest({
    required RewardChest chest,
    required math.Random random,
    required Skill? skill,
    required DateTime now,
  }) {
    final expiresAt = now.add(buffLifetime);
    switch (chest.rarity) {
      case RewardRarity.common:
        return random.nextBool()
            ? Buff(
                id: uid(),
                type: BuffType.nextQuestXpBoost,
                title: 'Импульс',
                description: 'Следующий квест даст +15% XP в течение 24 часов.',
                bonusPercent: 15,
                charges: 1,
                createdAt: now,
                expiresAt: expiresAt,
                sourceChestId: chest.id,
                sourceKey: 'chest:${chest.id}',
              )
            : Buff(
                id: uid(),
                type: BuffType.questRushXpBoost,
                title: 'Темп',
                description:
                    'Следующие 2 квеста дадут по +10% XP в течение 24 часов.',
                bonusPercent: 10,
                charges: 2,
                createdAt: now,
                expiresAt: expiresAt,
                sourceChestId: chest.id,
                sourceKey: 'chest:${chest.id}',
              );
      case RewardRarity.rare:
        if (skill != null && random.nextBool()) {
          return Buff(
            id: uid(),
            type: BuffType.skillFocusXpBoost,
            title: 'Резонанс навыка',
            description:
                'Следующий квест по навыку ${skill.name} даст +25% XP в течение 24 часов.',
            bonusPercent: 25,
            charges: 1,
            skillId: skill.id,
            createdAt: now,
            expiresAt: expiresAt,
            sourceChestId: chest.id,
            sourceKey: 'chest:${chest.id}',
          );
        }
        return Buff(
          id: uid(),
          type: BuffType.questRushXpBoost,
          title: 'Боевой ритм',
          description:
              'Следующие 2 квеста дадут по +15% XP в течение 24 часов.',
          bonusPercent: 15,
          charges: 2,
          createdAt: now,
          expiresAt: expiresAt,
          sourceChestId: chest.id,
          sourceKey: 'chest:${chest.id}',
        );
      case RewardRarity.epic:
        return Buff(
          id: uid(),
          type: BuffType.questRushXpBoost,
          title: 'Критический заряд',
          description:
              'Следующие 2 квеста дадут по +35% XP в течение 24 часов.',
          bonusPercent: 35,
          charges: 2,
          createdAt: now,
          expiresAt: expiresAt,
          sourceChestId: chest.id,
          sourceKey: 'chest:${chest.id}',
        );
    }
  }

  void _removeRewardChestBySourceKey({
    required String sourceKey,
    required List<RewardChest> rewardChests,
    required List<Buff> buffs,
    required List<Task> tasks,
    required List<RewardChest> pendingRewardNotifications,
    required List<Buff> pendingBuffNotifications,
  }) {
    final removedChestIds = rewardChests
        .where((chest) => chest.sourceKey == sourceKey)
        .map((chest) => chest.id)
        .toSet();
    if (removedChestIds.isEmpty) return;

    rewardChests.removeWhere((chest) => removedChestIds.contains(chest.id));
    pendingRewardNotifications.removeWhere(
      (chest) =>
          removedChestIds.contains(chest.id) || chest.sourceKey == sourceKey,
    );
    _removeBuffsWhere(
      buffs: buffs,
      tasks: tasks,
      pendingNotifications: pendingBuffNotifications,
      shouldRemove: (buff) =>
          removedChestIds.contains(buff.sourceChestId) ||
          removedChestIds.any((id) => buff.sourceKey == 'chest:$id'),
    );
  }

  void _removeBuffsWhere({
    required List<Buff> buffs,
    required List<Task> tasks,
    required List<Buff> pendingNotifications,
    required bool Function(Buff buff) shouldRemove,
  }) {
    final removedBuffIds = buffs
        .where(shouldRemove)
        .map((buff) => buff.id)
        .toSet();
    if (removedBuffIds.isEmpty) return;

    buffs.removeWhere((buff) => removedBuffIds.contains(buff.id));
    pendingNotifications.removeWhere(
      (buff) => removedBuffIds.contains(buff.id),
    );
    for (final task in tasks) {
      if (!task.consumedBuffIds.any(removedBuffIds.contains)) continue;
      task.consumedBuffIds = task.consumedBuffIds
          .where((id) => !removedBuffIds.contains(id))
          .toList();
    }
  }
}
