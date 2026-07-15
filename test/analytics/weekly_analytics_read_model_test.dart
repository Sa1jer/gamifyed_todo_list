import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/analytics/analytics_read_model.dart';
import 'package:todo_list_app/analytics/weekly_analytics_read_model.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  test(
    'weekly view data is detached from mutable tasks, skills, and goals',
    () {
      final weekStart = DateTime(2026, 7, 13);
      final skill = Skill(
        id: 'skill',
        name: 'Исходный навык',
        goal: 'Цель',
        color: Colors.blue,
        icon: Icons.star,
      );
      final task = Task(
        id: 'task',
        title: 'Исходный квест',
        skillId: skill.id,
        xpReward: 100,
        type: TaskType.longTerm,
        priority: Priority.high,
        minimumAction: 'Открыть документ',
        updatedAt: weekStart.subtract(const Duration(days: 8)),
      );
      final repeating = Task(
        id: 'repeat',
        title: 'Повтор',
        skillId: skill.id,
        xpReward: 20,
        type: TaskType.repeating,
        nextResetAt: weekStart.add(const Duration(hours: 3)),
      );
      final goal = WeeklyGoal(
        id: 'goal',
        weekStart: weekStart,
        title: 'Исходная цель недели',
        keyResults: [WeeklyKeyResult(id: 'kr', title: 'Результат')],
      );
      final analytics = AnalyticsReadModel.build(
        weekStart: weekStart,
        completionHistoryByDate: const {},
        skills: [skill],
        tasks: [task, repeating],
        todayStats: null,
        totalCompletions: 0,
      );

      final viewData = const WeeklyAnalyticsBuilder().build(
        analytics: analytics,
        tasks: [
          _input(task, skillName: skill.name, minimumActionXp: 10),
          _input(repeating, skillName: skill.name),
        ],
        weeklyGoal: WeeklyGoalData.fromGoal(goal),
        now: weekStart,
      );

      task.title = 'Изменённый квест';
      repeating.title = 'Изменённый повтор';
      skill.name = 'Изменённый навык';
      goal.title = 'Изменённая цель недели';
      goal.keyResults.first.title = 'Изменённый результат';

      expect(viewData.procrastination.stalled.single.title, 'Исходный квест');
      expect(viewData.riskTasks.single.title, 'Повтор');
      expect(viewData.riskTasks.single.skillName, 'Исходный навык');
      expect(viewData.weeklyGoal?.title, 'Исходная цель недели');
      expect(viewData.weeklyGoal?.keyResults.single.title, 'Результат');
    },
  );

  test('weekly insight collections and goal key results are unmodifiable', () {
    final weekStart = DateTime(2026, 7, 13);
    final analytics = AnalyticsReadModel.build(
      weekStart: weekStart,
      completionHistoryByDate: const {},
      skills: const [],
      tasks: const [],
      todayStats: null,
      totalCompletions: 0,
    );
    final goal = WeeklyGoal(
      id: 'goal',
      weekStart: weekStart,
      title: 'Цель',
      keyResults: [WeeklyKeyResult(id: 'kr', title: 'Результат')],
    );
    final viewData = const WeeklyAnalyticsBuilder().build(
      analytics: analytics,
      tasks: const [],
      weeklyGoal: WeeklyGoalData.fromGoal(goal),
      now: weekStart,
    );

    expect(
      () => viewData.procrastination.stalled.add(
        const WeeklyTaskInsightData(
          taskId: 'x',
          title: 'x',
          skillId: 'x',
          skillName: 'x',
          reason: 'x',
          minimumAction: null,
          daysSinceActivity: 0,
          xpReward: 10,
          priority: Priority.low,
        ),
      ),
      throwsUnsupportedError,
    );
    expect(
      () => viewData.weeklyGoal!.keyResults.add(
        const WeeklyKeyResultData(
          id: 'x',
          title: 'x',
          isDone: false,
          completedAt: null,
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('public weekly data constructors defensively copy input lists', () {
    final dayStats = <AnalyticsDaySummary>[];
    final entries = <AnalyticsHistoryRecord>[];
    final skillStats = <AnalyticsSkillSummary>[];
    final riskTasks = <WeeklyTaskRiskData>[];
    final stalled = <WeeklyTaskInsightData>[];
    final oversized = <WeeklyTaskInsightData>[];
    final minimumStarts = <WeeklyTaskInsightData>[];
    final keyResults = <WeeklyKeyResultData>[
      const WeeklyKeyResultData(
        id: 'kr',
        title: 'Результат',
        isDone: false,
        completedAt: null,
      ),
    ];
    final procrastination = ProcrastinationInsightsData(
      stalled: stalled,
      oversized: oversized,
      minimumStarts: minimumStarts,
    );
    final goal = WeeklyGoalData(
      id: 'goal',
      weekStart: DateTime(2026, 7, 13),
      title: 'Цель',
      keyResults: keyResults,
      createdAt: DateTime(2026, 7, 13),
      updatedAt: DateTime(2026, 7, 13),
    );
    final viewData = WeeklyAnalyticsViewData(
      weekStart: DateTime(2026, 7, 13),
      dayStats: dayStats,
      entries: entries,
      skillStats: skillStats,
      riskTasks: riskTasks,
      weeklyGoal: goal,
      procrastination: procrastination,
    );

    dayStats.add(
      AnalyticsDaySummary(
        date: DateTime(2026, 7, 13),
        xp: 10,
        completedTasks: 1,
      ),
    );
    entries.add(
      AnalyticsHistoryRecord(
        id: 'history',
        taskId: 'task',
        taskTitle: 'Квест',
        skillId: 'skill',
        skillName: 'Навык',
        xp: 10,
        isCompletion: true,
        at: DateTime(2026, 7, 13),
      ),
    );
    skillStats.add(
      const AnalyticsSkillSummary(
        skillId: 'skill',
        name: 'Навык',
        weeklyXp: 10,
        completedTasks: 1,
        activeTasks: 0,
        totalTasks: 1,
        completedStages: 0,
        totalStages: 0,
        goalProgress: 0,
        isExistingSkill: true,
      ),
    );
    riskTasks.add(
      WeeklyTaskRiskData(
        taskId: 'task',
        title: 'Квест',
        skillId: 'skill',
        skillName: 'Навык',
        streak: 1,
        nextResetAt: DateTime(2026, 7, 14),
      ),
    );
    stalled.add(
      const WeeklyTaskInsightData(
        taskId: 'task',
        title: 'Квест',
        skillId: 'skill',
        skillName: 'Навык',
        reason: 'Причина',
        minimumAction: null,
        daysSinceActivity: 7,
        xpReward: 10,
        priority: Priority.low,
      ),
    );
    oversized.addAll(stalled);
    minimumStarts.addAll(stalled);
    keyResults.clear();

    expect(viewData.dayStats, isEmpty);
    expect(viewData.entries, isEmpty);
    expect(viewData.skillStats, isEmpty);
    expect(viewData.riskTasks, isEmpty);
    expect(viewData.procrastination.stalled, isEmpty);
    expect(viewData.procrastination.oversized, isEmpty);
    expect(viewData.procrastination.minimumStarts, isEmpty);
    expect(viewData.weeklyGoal!.keyResults.single.title, 'Результат');
  });
}

WeeklyTaskInputData _input(
  Task task, {
  required String skillName,
  int minimumActionXp = 0,
}) => WeeklyTaskInputData(
  taskId: task.id,
  title: task.title,
  skillId: task.skillId,
  skillName: skillName,
  xpReward: task.xpReward,
  type: task.type,
  priority: task.priority,
  streak: task.streak,
  nextResetAt: task.nextResetAt,
  updatedAt: task.updatedAt,
  minimumActionDoneAt: task.minimumActionDoneAt,
  minimumAction: task.minimumAction,
  subtaskCount: task.subtasks.length,
  canCompleteMinimumAction: task.hasMinimumAction,
  minimumActionXp: minimumActionXp,
);
