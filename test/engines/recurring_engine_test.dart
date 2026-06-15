import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/recurring_engine.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  group('RecurringEngine', () {
    const engine = RecurringEngine();
    final now = DateTime(2026, 1, 12, 10);

    Task quest(
      String id, {
      TaskType type = TaskType.repeating,
      RepeatFrequency frequency = RepeatFrequency.daily,
      DateTime? nextResetAt,
      bool done = false,
      String skillId = 'skill-1',
      String? stageId,
    }) {
      return Task(
        id: id,
        title: 'Квест $id',
        skillId: skillId,
        xpReward: 20,
        type: type,
        repeatFrequency: frequency,
        nextResetAt: nextResetAt,
        isDone: done,
        treeNodeId: stageId,
      );
    }

    Skill skillWithStage({bool mastered = false}) {
      return Skill(
        id: 'skill-1',
        name: 'Подтягивания',
        goal: 'Подтягиваться 20 раз',
        color: Colors.orange,
        icon: Icons.fitness_center,
        treeNodes: [
          SkillTreeNode(id: 'stage-1', title: 'Основа', isMastered: mastered),
        ],
      );
    }

    test('ignores non-repeating quests and groups repeating quests', () {
      final snapshot = engine.buildSnapshot([
        quest('daily', frequency: RepeatFrequency.daily),
        quest('weekly', frequency: RepeatFrequency.weekly),
        quest('one-off', type: TaskType.shortTerm),
      ], now: now);

      expect(snapshot.quests.map((info) => info.task.id), ['daily', 'weekly']);
      expect(snapshot.grouped[RepeatFrequency.daily], hasLength(1));
      expect(snapshot.grouped[RepeatFrequency.weekly], hasLength(1));
    });

    test('builds today, week, and month due lists from reset time', () {
      final snapshot = engine.buildSnapshot([
        quest('today', nextResetAt: now.add(const Duration(hours: 12))),
        quest('week', nextResetAt: now.add(const Duration(days: 3))),
        quest('month', nextResetAt: DateTime(2026, 1, 28)),
        quest('later', nextResetAt: DateTime(2026, 2, 10)),
      ], now: now);

      expect(snapshot.dueToday.map((info) => info.task.id), ['today']);
      expect(snapshot.dueThisWeek.map((info) => info.task.id), [
        'today',
        'week',
      ]);
      expect(snapshot.dueThisMonth.map((info) => info.task.id), [
        'today',
        'week',
        'month',
      ]);
    });

    test('completed recurring quests stay grouped but not due', () {
      final snapshot = engine.buildSnapshot([
        quest(
          'done',
          nextResetAt: now.add(const Duration(hours: 8)),
          done: true,
        ),
      ], now: now);

      expect(snapshot.quests, hasLength(1));
      expect(snapshot.dueToday, isEmpty);
      expect(snapshot.grouped[RepeatFrequency.daily], hasLength(1));
    });

    test('missing reset date falls back to next reset from reference time', () {
      final snapshot = engine.buildSnapshot([quest('fallback')], now: now);

      expect(
        snapshot.quests.single.resetAt,
        nextResetFrom(now, RepeatFrequency.daily, 1),
      );
      expect(snapshot.dueToday.map((info) => info.task.id), ['fallback']);
    });

    test('detects recurring quest linked to active stage', () {
      final snapshot = engine.buildSnapshot(
        [
          quest(
            'stage-linked',
            stageId: 'stage-1',
            nextResetAt: now.add(const Duration(hours: 10)),
          ),
        ],
        skills: [skillWithStage()],
        now: now,
      );

      expect(snapshot.quests.single.skill?.id, 'skill-1');
      expect(snapshot.quests.single.stage?.id, 'stage-1');
      expect(snapshot.quests.single.linkedToActiveStage, isTrue);
    });

    test('mastered stage is not considered active for recurring focus', () {
      final snapshot = engine.buildSnapshot(
        [
          quest(
            'mastered-stage',
            stageId: 'stage-1',
            nextResetAt: now.add(const Duration(hours: 10)),
          ),
        ],
        skills: [skillWithStage(mastered: true)],
        now: now,
      );

      expect(snapshot.quests.single.linkedToActiveStage, isFalse);
    });
  });
}
