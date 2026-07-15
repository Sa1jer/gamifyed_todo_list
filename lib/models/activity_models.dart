import 'package:flutter/material.dart';

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
  }) : keyResults = List.of(keyResults ?? const <WeeklyKeyResult>[]),
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
