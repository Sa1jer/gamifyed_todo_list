import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/analytics/analytics_read_model.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  Skill skill(String id, String name, Color color) => Skill(
    id: id,
    name: name,
    goal: 'Цель',
    color: color,
    icon: Icons.star,
    treeNodes: [
      SkillTreeNode(id: '$id-stage', title: 'Этап', isMastered: id == 'a'),
    ],
  );

  Task task(String id, String skillId, {bool isDone = false}) => Task(
    id: id,
    title: id,
    skillId: skillId,
    xpReward: 20,
    type: TaskType.shortTerm,
    isDone: isDone,
  );

  HistoryEntry entry({
    required String id,
    required String skillId,
    required int xp,
    required DateTime at,
    String? skillName,
  }) => HistoryEntry(
    id: id,
    taskTitle: id,
    taskId: id,
    skillId: skillId,
    skillName: skillName ?? skillId,
    skillColor: Colors.blue,
    skillIcon: Icons.star,
    xp: xp,
    isCompletion: true,
    at: at,
  );

  test('build aggregates one week without including adjacent dates', () {
    final weekStart = DateTime(2026, 7, 13);
    final monday = entry(
      id: 'monday',
      skillId: 'a',
      xp: 20,
      at: weekStart.add(const Duration(hours: 9)),
    );
    final tuesday = entry(
      id: 'tuesday',
      skillId: 'b',
      xp: 40,
      at: weekStart.add(const Duration(days: 1, hours: 10)),
    );
    final previous = entry(
      id: 'previous',
      skillId: 'a',
      xp: 500,
      at: weekStart.subtract(const Duration(days: 1)),
    );

    final model = AnalyticsReadModel.build(
      weekStart: weekStart,
      completionHistoryByDate: {
        dateOnly(monday.at): [monday],
        dateOnly(tuesday.at): [tuesday],
        dateOnly(previous.at): [previous],
      },
      skills: [skill('a', 'А', Colors.red), skill('b', 'Б', Colors.blue)],
      tasks: [
        task('a-active', 'a'),
        task('a-done', 'a', isDone: true),
        task('b-active', 'b'),
        task('inbox', kInboxSkillId),
      ],
      todayStats: DailyStats(date: weekStart, tasksCompleted: 3, xpEarned: 70),
      totalCompletions: 12,
    );

    expect(model.weekStart, weekStart);
    expect(model.days.map((day) => day.xp), [20, 40, 0, 0, 0, 0, 0]);
    expect(model.entries.map((item) => item.id), ['tuesday', 'monday']);
    expect(model.totalXp, 60);
    expect(model.completedTasks, 2);
    expect(model.activeDays, 2);
    expect(model.averageXpPerActiveDay, 30);
    expect(model.todayXp, 70);
    expect(model.todayCompletedTasks, 3);
    expect(model.totalCompletions, 12);
    expect(model.leadingSkill?.skillId, 'b');
    expect(model.activityLeader?.skillId, 'b');
    expect(model.dayFor(weekStart)?.completedTasks, 1);
    expect(model.dayFor(weekStart.subtract(const Duration(days: 1))), isNull);
    expect(model.skillById('a')?.weeklyXp, 20);
    expect(model.skillById('a')?.activeTasks, 1);
    expect(model.skillById('a')?.totalTasks, 2);
    expect(model.skillById('a')?.completedStages, 1);
    expect(model.skillById(kInboxSkillId), isNull);
  });

  test('activity leader preserves XP then completion-count tie-break', () {
    final weekStart = DateTime(2026, 7, 13);
    final a = entry(
      id: 'a',
      skillId: 'a',
      skillName: 'Старое имя A',
      xp: 40,
      at: weekStart.add(const Duration(hours: 9)),
    );
    final b1 = entry(
      id: 'b1',
      skillId: 'b',
      skillName: 'Старое имя B',
      xp: 20,
      at: weekStart.add(const Duration(hours: 10)),
    );
    final b2 = entry(
      id: 'b2',
      skillId: 'b',
      skillName: 'Новое имя B',
      xp: 20,
      at: weekStart.add(const Duration(hours: 11)),
    );

    final model = AnalyticsReadModel.build(
      weekStart: weekStart,
      completionHistoryByDate: {
        dateOnly(weekStart): [a, b1, b2],
      },
      skills: [
        skill('a', 'Текущее A', Colors.red),
        skill('b', 'Текущее B', Colors.blue),
      ],
      tasks: const [],
      todayStats: null,
      totalCompletions: 3,
    );

    expect(model.activityLeader?.skillId, 'b');
    expect(model.activityLeader?.xp, 40);
    expect(model.activityLeader?.completedTasks, 2);
    expect(model.activityLeader?.name, 'Новое имя B');
  });

  test('leading current skill uses a deterministic tie break', () {
    final weekStart = DateTime(2026, 7, 13);
    final model = AnalyticsReadModel.build(
      weekStart: weekStart,
      completionHistoryByDate: {
        dateOnly(weekStart): [
          entry(id: 'z', skillId: 'z', xp: 20, at: weekStart),
          entry(id: 'a', skillId: 'a', xp: 20, at: weekStart),
        ],
      },
      skills: [
        skill('z', 'Я первый', Colors.red),
        skill('a', 'А по алфавиту', Colors.blue),
      ],
      tasks: const [],
      todayStats: null,
      totalCompletions: 2,
    );

    expect(model.leadingSkill?.skillId, 'a');
    expect(model.skills.map((skill) => skill.skillId), ['a', 'z']);
  });

  test('weekly summaries retain deleted skill history identity', () {
    final weekStart = DateTime(2026, 7, 13);
    final model = AnalyticsReadModel.build(
      weekStart: weekStart,
      completionHistoryByDate: {
        dateOnly(weekStart): [
          entry(
            id: 'historical',
            skillId: 'deleted',
            skillName: 'Удалённый навык',
            xp: 30,
            at: weekStart,
          ),
        ],
      },
      skills: [skill('current', 'Текущий', Colors.red)],
      tasks: const [],
      todayStats: null,
      totalCompletions: 1,
    );

    final historical = model.skillById('deleted');
    expect(historical?.name, 'Удалённый навык');
    expect(historical?.weeklyXp, 30);
    expect(historical?.completedTasks, 1);
    expect(historical?.isExistingSkill, isFalse);
    expect(model.leadingSkill, isNull);
  });

  test('cache reuses a week only while the analytics epoch is unchanged', () {
    final cache = AnalyticsReadModelCache();
    var builds = 0;

    AnalyticsReadModel build(DateTime weekStart) {
      builds++;
      return AnalyticsReadModel.build(
        weekStart: weekStart,
        completionHistoryByDate: const {},
        skills: const [],
        tasks: const [],
        todayStats: null,
        totalCompletions: 0,
      );
    }

    final first = cache.resolve(
      epoch: 1,
      weekStart: DateTime(2026, 7, 14),
      build: build,
    );
    final sameWeek = cache.resolve(
      epoch: 1,
      weekStart: DateTime(2026, 7, 16),
      build: build,
    );
    final invalidated = cache.resolve(
      epoch: 2,
      weekStart: DateTime(2026, 7, 16),
      build: build,
    );

    expect(identical(first, sameWeek), isTrue);
    expect(identical(first, invalidated), isFalse);
    expect(builds, 2);
  });
}
