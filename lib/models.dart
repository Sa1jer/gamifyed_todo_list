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

// ─── Skill ────────────────────────────────────────────────────────────────────

class Skill with XPOwner {
  final String id;
  String name, goal;
  List<String> checklist;
  List<bool> checklistDone;
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
    this.level = 1,
    this.xp = 0,
  }) : checklist = checklist ?? [],
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
  Priority priority;
  List<String> subtasks;
  List<bool> subtaskDone;
  List<String> tags;
  bool notificationsEnabled;
  int? notificationHour;
  int? notificationMinute;

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
    this.priority = Priority.medium,
    List<String>? subtasks,
    List<bool>? subtaskDone,
    List<String>? tags,
    this.notificationsEnabled = false,
    this.notificationHour,
    this.notificationMinute,
  }) : subtasks = subtasks ?? [],
       subtaskDone = subtaskDone ?? List.filled((subtasks ?? []).length, false),
       tags = tags ?? [];

  int get activeMultiplier {
    if (type != TaskType.repeating || streak < 2) return 1;
    if (streak >= 14) return 4;
    if (streak >= 7) return 3;
    return 2;
  }

  bool get showStreakBadge =>
      type == TaskType.repeating && streak >= 2 && !isDone;

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

  /// Cumulative XP earned all-time — never decreases on uncomplete
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
  final Color skillColor;
  final IconData skillIcon;
  final int xp;
  final bool isCompletion;
  final DateTime at;

  HistoryEntry({
    required this.id,
    required this.taskTitle,
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
    name: 'Недельный стрик',
    description: '7 дней подряд выполняй повторяющиеся задачи',
    icon: Icons.local_fire_department,
    color: Color(0xFFFF9500),
  ),
  AchievementDef(
    id: 'streak_30',
    name: 'Месячный стрик',
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
