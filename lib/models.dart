import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'utils.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════════

mixin XPOwner {
  int get level;
  set level(int v);
  int get xp;
  set xp(int v);

  int get xpNeeded => xpForLevel(level);
  double get progress => (xp / xpNeeded).clamp(0.0, 1.0);

  int addXP(int amount) {
    xp += amount;
    int gained = 0;
    while (xp >= xpNeeded) {
      xp -= xpForLevel(level);
      level++;
      gained++;
    }
    return gained;
  }

  void removeXP(int amount) {
    xp -= amount;
    while (xp < 0 && level > 1) {
      level--;
      xp += xpForLevel(level);
    }
    if (xp < 0) xp = 0;
  }
}

// ─── Skill Tree ───────────────────────────────────────────────────────────────

enum SkillTreeNodeStatus { locked, active, mastered }

const skillTreeNodeStatusLabel = {
  SkillTreeNodeStatus.locked: 'Закрыто',
  SkillTreeNodeStatus.active: 'Активно',
  SkillTreeNodeStatus.mastered: 'Освоено',
};

const skillTreeNodeStatusColor = {
  SkillTreeNodeStatus.locked: Color(0xFF8E8E93),
  SkillTreeNodeStatus.active: Color(0xFF4A9EFF),
  SkillTreeNodeStatus.mastered: Color(0xFF34C759),
};

class SkillTreeNode {
  final String id;
  String title;
  String description;
  int xpReward;
  List<String> prerequisiteIds;
  List<String> checklist;
  List<bool> checklistDone;
  bool isMastered;
  DateTime? masteredAt;

  SkillTreeNode({
    required this.id,
    required this.title,
    this.description = '',
    this.xpReward = 20,
    List<String>? prerequisiteIds,
    List<String>? checklist,
    List<bool>? checklistDone,
    this.isMastered = false,
    this.masteredAt,
  }) : prerequisiteIds = prerequisiteIds ?? [],
       checklist = checklist ?? [],
       checklistDone =
           checklistDone ?? List.filled((checklist ?? []).length, false);

  int get checklistCompletedCount => checklistDone.where((done) => done).length;

  bool get isChecklistReady =>
      checklist.isEmpty || checklistDone.every((done) => done);

  double get progress {
    if (checklist.isEmpty) return isMastered ? 1.0 : 0.0;
    return (checklistCompletedCount / checklist.length).clamp(0.0, 1.0);
  }

  void syncChecklistDone() {
    while (checklistDone.length < checklist.length) {
      checklistDone.add(false);
    }
    while (checklistDone.length > checklist.length) {
      checklistDone.removeLast();
    }
  }
}

// ─── Skill ────────────────────────────────────────────────────────────────────

class Skill with XPOwner {
  final String id;
  String name, goal;
  List<String> checklist;
  List<bool> checklistDone;
  List<SkillTreeNode> treeNodes;
  Color color;
  IconData icon;
  @override
  int level, xp;

  Skill({
    required this.id,
    required this.name,
    required this.goal,
    required this.color,
    required this.icon,
    List<String>? checklist,
    List<bool>? checklistDone,
    List<SkillTreeNode>? treeNodes,
    this.level = 1,
    this.xp = 0,
  }) : checklist = checklist ?? [],
       treeNodes = treeNodes ?? [],
       checklistDone =
           checklistDone ?? List.filled((checklist ?? []).length, false);

  String get initial => name.isNotEmpty ? name[0] : '?';

  void syncChecklistDone() {
    while (checklistDone.length < checklist.length) {
      checklistDone.add(false);
    }
    while (checklistDone.length > checklist.length) {
      checklistDone.removeLast();
    }
  }

  int get checklistCompletedCount => checklistDone.where((v) => v).length;

  int get masteredTreeNodeCount => treeNodes.where((n) => n.isMastered).length;

  int get activeTreeNodeCount => treeNodes
      .where((node) => treeNodeStatus(node) == SkillTreeNodeStatus.active)
      .length;

  double get treeProgress {
    if (treeNodes.isEmpty) return 0.0;
    return (masteredTreeNodeCount / treeNodes.length).clamp(0.0, 1.0);
  }

  SkillTreeNodeStatus treeNodeStatus(SkillTreeNode node) {
    if (node.isMastered) return SkillTreeNodeStatus.mastered;
    final masteredIds = treeNodes
        .where((candidate) => candidate.isMastered)
        .map((candidate) => candidate.id)
        .toSet();
    final unlocked = node.prerequisiteIds.every(masteredIds.contains);
    return unlocked ? SkillTreeNodeStatus.active : SkillTreeNodeStatus.locked;
  }

  void syncTreeNodes() {
    final validIds = treeNodes.map((node) => node.id).toSet();
    for (final node in treeNodes) {
      node.syncChecklistDone();
      node.prerequisiteIds.removeWhere((id) => !validIds.contains(id));
    }
  }
}

// ─── Priority ──────────────────────────────────────────────────────────────────

enum Priority { high, medium, low }

const priorityLabel = {
  Priority.high: 'Высокий',
  Priority.medium: 'Средний',
  Priority.low: 'Низкий',
};

const priorityColor = {
  Priority.high: Color(0xFFFF3B30),
  Priority.medium: Color(0xFFFF9500),
  Priority.low: Color(0xFF4A9EFF),
};

// ─── Task ─────────────────────────────────────────────────────────────────────

class Task {
  final String id;
  String title;
  String skillId;
  int xpReward;
  TaskType type;
  bool isDone;
  int streak;
  int earnedXP;
  RepeatFrequency repeatFrequency;
  int repeatCustomDays;
  DateTime? nextResetAt;
  DateTime? lastCompletedAt;
  Priority priority;
  String minimumAction;
  DateTime? minimumActionDoneAt;
  int minimumActionEarnedXP;
  int bonusXpEarned;
  List<String> consumedBuffIds;
  List<String> subtasks;
  List<bool> subtaskDone;
  List<String> tags;
  bool notificationsEnabled;
  int? notificationHour;
  int? notificationMinute;
  DateTime createdAt;
  DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.skillId,
    required this.xpReward,
    required this.type,
    this.isDone = false,
    this.streak = 0,
    this.earnedXP = 0,
    this.repeatFrequency = RepeatFrequency.daily,
    this.repeatCustomDays = 1,
    this.nextResetAt,
    this.lastCompletedAt,
    this.priority = Priority.medium,
    this.minimumAction = '',
    this.minimumActionDoneAt,
    this.minimumActionEarnedXP = 0,
    this.bonusXpEarned = 0,
    List<String>? consumedBuffIds,
    List<String>? subtasks,
    List<bool>? subtaskDone,
    List<String>? tags,
    this.notificationsEnabled = false,
    this.notificationHour,
    this.notificationMinute,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : subtasks = subtasks ?? [],
       consumedBuffIds = consumedBuffIds ?? [],
       subtaskDone = subtaskDone ?? List.filled((subtasks ?? []).length, false),
       tags = tags ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  int get activeMultiplier {
    if (type != TaskType.repeating || streak < 2) return 1;
    if (streak >= 14) return 4;
    if (streak >= 7) return 3;
    return 2;
  }

  bool get showStreakBadge =>
      type == TaskType.repeating && streak >= 2 && !isDone;

  bool get hasMinimumAction => minimumAction.trim().isNotEmpty;

  bool get isMinimumActionDone =>
      minimumActionDoneAt != null && minimumActionEarnedXP > 0;

  int get subtaskCompletedCount => subtaskDone.where((v) => v).length;

  void syncSubtaskDone() {
    while (subtaskDone.length < subtasks.length) {
      subtaskDone.add(false);
    }
    while (subtaskDone.length > subtasks.length) {
      subtaskDone.removeLast();
    }
  }
}

// ─── UserProfile ──────────────────────────────────────────────────────────────

enum Gender { male, female, nonBinary }

const genderLabel = {
  Gender.male: 'Мужской',
  Gender.female: 'Женский',
  Gender.nonBinary: 'Многофункциональный',
};

class UserProfile with XPOwner {
  String name;
  @override
  int level, xp;

  /// Cumulative credited XP, adjusted when a completion is undone.
  int totalXpEarned;

  int? age;
  Gender? gender;

  /// Raw bytes of the user's chosen avatar image (PNG/JPG)
  Uint8List? avatarBytes;

  /// Raw bytes of the profile banner image (PNG/JPG)
  Uint8List? bannerBytes;

  UserProfile({
    required this.name,
    this.level = 1,
    this.xp = 0,
    this.totalXpEarned = 0,
    this.age,
    this.gender,
    this.avatarBytes,
    this.bannerBytes,
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

// ─── HistoryEntry ─────────────────────────────────────────────────────────────

class HistoryEntry {
  final String id, taskTitle, skillId, skillName;
  final String? taskId;
  final Color skillColor;
  final IconData skillIcon;
  final int xp;
  final bool isCompletion;
  final DateTime at;

  HistoryEntry({
    required this.id,
    required this.taskTitle,
    this.taskId,
    required this.skillId,
    required this.skillName,
    required this.skillColor,
    required this.skillIcon,
    required this.xp,
    required this.isCompletion,
    required this.at,
  });
}

// ─── Daily Stats ───────────────────────────────────────────────────────────────

class DailyStats {
  final DateTime date;
  int tasksCompleted;
  int xpEarned;
  int skillsImproved;

  DailyStats({
    required this.date,
    this.tasksCompleted = 0,
    this.xpEarned = 0,
    this.skillsImproved = 0,
  });
}

// ─── Weekly Goal / OKR ────────────────────────────────────────────────────────

class WeeklyKeyResult {
  final String id;
  String title;
  bool isDone;
  DateTime? completedAt;

  WeeklyKeyResult({
    required this.id,
    required this.title,
    this.isDone = false,
    this.completedAt,
  });
}

class WeeklyGoal {
  final String id;
  DateTime weekStart;
  String title;
  List<WeeklyKeyResult> keyResults;
  DateTime createdAt;
  DateTime updatedAt;

  WeeklyGoal({
    required this.id,
    required this.weekStart,
    required this.title,
    List<WeeklyKeyResult>? keyResults,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : keyResults = keyResults ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  int get completedKeyResults =>
      keyResults.where((result) => result.isDone).length;

  double get progress {
    if (keyResults.isEmpty) return 0.0;
    return (completedKeyResults / keyResults.length).clamp(0.0, 1.0);
  }

  bool get isCompleted => keyResults.isNotEmpty && progress >= 1.0;
}

// ─── Achievement Definition ────────────────────────────────────────────────────

class AchievementDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const AchievementDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class Achievement {
  final String id;
  DateTime? unlockedAt;
  AchievementDef? def;

  Achievement({required this.id, this.unlockedAt});

  bool get isUnlocked => unlockedAt != null;
}

const achievementDefinitions = <AchievementDef>[
  AchievementDef(
    id: 'first_task',
    name: 'Первая победа',
    description: 'Выполни свою первую задачу',
    icon: Icons.star_border,
    color: Color(0xFF4A9EFF),
  ),
  AchievementDef(
    id: 'streak_7',
    name: 'Недельная серия',
    description: '7 дней подряд выполняй повторяющиеся задачи',
    icon: Icons.local_fire_department,
    color: Color(0xFFFF9500),
  ),
  AchievementDef(
    id: 'streak_30',
    name: 'Месячная серия',
    description: '30 дней подряд выполняй повторяющиеся задачи',
    icon: Icons.whatshot,
    color: Color(0xFFFF3B30),
  ),
  AchievementDef(
    id: 'tasks_100',
    name: 'Столетие',
    description: 'Выполни 100 задач',
    icon: Icons.emoji_events,
    color: Color(0xFFFFCC00),
  ),
  AchievementDef(
    id: 'tasks_500',
    name: 'Полтысячи',
    description: 'Выполни 500 задач',
    icon: Icons.military_tech,
    color: Color(0xFFAF52DE),
  ),
  AchievementDef(
    id: 'level_5',
    name: 'Подмастерье',
    description: 'Достигни 5 уровня',
    icon: Icons.trending_up,
    color: Color(0xFF34C759),
  ),
  AchievementDef(
    id: 'level_10',
    name: 'Мастер',
    description: 'Достигни 10 уровня',
    icon: Icons.workspace_premium,
    color: Color(0xFF5856D6),
  ),
  AchievementDef(
    id: 'skills_3',
    name: 'Три пути',
    description: 'Создай 3 навыка',
    icon: Icons.bolt,
    color: Color(0xFF5AC8FA),
  ),
  AchievementDef(
    id: 'first_boss',
    name: 'Охотник на боссов',
    description: 'Победи первого босса',
    icon: Icons.shield,
    color: Color(0xFFFF2D55),
  ),
  AchievementDef(
    id: 'all_checklist',
    name: 'Перфекционист',
    description: 'Заверши все чеклисты навыка',
    icon: Icons.checklist,
    color: Color(0xFF8E8E93),
  ),
];

// ─── Rewards & Buffs ─────────────────────────────────────────────────────────

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
