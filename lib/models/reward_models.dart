import 'package:flutter/material.dart';

enum RewardRarity { common, rare, epic }

const rewardRarityLabel = {
  RewardRarity.common: 'Обычный',
  RewardRarity.rare: 'Редкий',
  RewardRarity.epic: 'Эпический',
};

const rewardRarityColor = {
  RewardRarity.common: Color(0xFF4A9EFF),
  RewardRarity.rare: Color(0xFFFF9500),
  RewardRarity.epic: Color(0xFFAF52DE),
};

enum BuffType { nextQuestXpBoost, skillFocusXpBoost, questRushXpBoost }

const buffTypeLabel = {
  BuffType.nextQuestXpBoost: 'Следующий квест',
  BuffType.skillFocusXpBoost: 'Фокус навыка',
  BuffType.questRushXpBoost: 'Серия квестов',
};

class RewardChest {
  final String id;
  String title;
  String description;
  RewardRarity rarity;
  String sourceKey;
  String? skillId;
  DateTime unlockedAt;
  DateTime? openedAt;

  RewardChest({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.sourceKey,
    required this.unlockedAt,
    this.skillId,
    this.openedAt,
  });

  bool get isOpened => openedAt != null;
}

class Buff {
  final String id;
  BuffType type;
  String title;
  String description;
  int bonusPercent;
  int charges;
  String? skillId;
  String? sourceChestId;
  String? sourceKey;
  DateTime createdAt;
  DateTime? expiresAt;

  Buff({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.bonusPercent,
    required this.charges,
    required this.createdAt,
    this.skillId,
    this.sourceChestId,
    this.sourceKey,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && !DateTime.now().isBefore(expiresAt!);

  bool get isActive => !isExpired && charges > 0;
}

// ─── Boss ─────────────────────────────────────────────────────────────────────

class Boss {
  final String id;
  String title;
  String skillId;
  int hp;
  int maxHp;
  int targetStreak;
  int currentStreak;
  bool isDefeated;
  DateTime? defeatedAt;

  Boss({
    required this.id,
    required this.title,
    required this.skillId,
    this.hp = 100,
    this.maxHp = 100,
    required this.targetStreak,
    this.currentStreak = 0,
    this.isDefeated = false,
    this.defeatedAt,
  });

  double get hpPercent => (hp / maxHp).clamp(0.0, 1.0);
}

class BossSnapshot {
  final int currentStreak;
  final int targetStreak;
  final int completedTasks;
  final int totalTasks;
  final int startedTasks;
  final int startableTasks;
  final int checklistCompleted;
  final int checklistTotal;
  final int masteredTreeNodes;
  final int totalTreeNodes;
  final int urgentRepeatingTasks;
  final int stalledHighPriorityTasks;
  final double impactProgress;
  final double streakProgress;
  final double priorityProgress;
  final double startProgress;
  final double completionProgress;
  final double checklistProgress;
  final double treeProgress;
  final bool isUnderAttack;
  final String phaseLabel;
  final String recommendation;

  const BossSnapshot({
    required this.currentStreak,
    required this.targetStreak,
    required this.completedTasks,
    required this.totalTasks,
    required this.startedTasks,
    required this.startableTasks,
    required this.checklistCompleted,
    required this.checklistTotal,
    required this.masteredTreeNodes,
    required this.totalTreeNodes,
    required this.urgentRepeatingTasks,
    required this.stalledHighPriorityTasks,
    required this.impactProgress,
    required this.streakProgress,
    required this.priorityProgress,
    required this.startProgress,
    required this.completionProgress,
    required this.checklistProgress,
    required this.treeProgress,
    required this.isUnderAttack,
    required this.phaseLabel,
    required this.recommendation,
  });

  int get impactPercent => (impactProgress * 100).round().clamp(0, 100);
  int get streakPercent => (streakProgress * 100).round().clamp(0, 100);
  int get priorityPercent => (priorityProgress * 100).round().clamp(0, 100);
  int get startPercent => (startProgress * 100).round().clamp(0, 100);
  int get completionPercent => (completionProgress * 100).round().clamp(0, 100);
  int get checklistPercent => (checklistProgress * 100).round().clamp(0, 100);
  int get treePercent => (treeProgress * 100).round().clamp(0, 100);
}
