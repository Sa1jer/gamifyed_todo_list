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
  });

  int get activeMultiplier {
    if (type != TaskType.repeating || streak < 2) return 1;
    if (streak >= 14) return 4;
    if (streak >= 7) return 3;
    return 2;
  }

  bool get showStreakBadge =>
      type == TaskType.repeating && streak >= 2 && !isDone;
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
