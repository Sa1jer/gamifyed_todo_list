import 'package:flutter/material.dart';

import '../../analytics/weekly_analytics_read_model.dart';

typedef WeeklySummary = WeeklyAnalyticsViewData;
typedef WeeklyTaskInsight = WeeklyTaskInsightData;

class WeeklySkillVisual {
  final Color color;
  final IconData icon;

  const WeeklySkillVisual({required this.color, required this.icon});
}

String formatWeeklyDayMonth(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month';
}

String weeklyQuestCount(int count) => '$count ${weeklyQuestWord(count)}';

String weeklyQuestWord(int count) {
  final lastTwo = count % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'квестов';
  return switch (count % 10) {
    1 => 'квест',
    2 || 3 || 4 => 'квеста',
    _ => 'квестов',
  };
}
