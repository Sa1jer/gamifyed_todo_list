import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/progress_engine.dart';
import 'package:todo_list_app/models.dart';

void main() {
  group('ProgressEngine', () {
    const engine = ProgressEngine();
    final now = DateTime(2026, 3, 16, 10);

    Skill skill({
      String id = 'skill-1',
      GoalSpec? goalSpec,
      List<SkillTreeNode>? treeNodes,
      int xp = 0,
    }) {
      return Skill(
        id: id,
        name: 'Подтягивания',
        goal: goalSpec?.text ?? 'Подтягиваться 20 раз',
        goalSpec: goalSpec,
        color: Colors.orange,
        icon: Icons.fitness_center,
        treeNodes: treeNodes,
        xp: xp,
      );
    }

    HistoryEntry win({
      String skillId = 'skill-1',
      String title = 'Практика',
      int xp = 20,
      DateTime? at,
    }) {
      return HistoryEntry(
        id: title,
        taskTitle: title,
        taskId: title,
        skillId: skillId,
        skillName: 'Подтягивания',
        skillColor: Colors.orange,
        skillIcon: Icons.fitness_center,
        xp: xp,
        isCompletion: true,
        at: at ?? now.subtract(const Duration(days: 1)),
      );
    }

    test('uses goal metric when current and target values exist', () {
      final snapshot = engine.snapshotForSkill(
        skill(
          goalSpec: GoalSpec(
            text: 'Подтягиваться 20 раз',
            currentValue: 10,
            targetValue: 20,
          ),
        ),
        const [],
        now: now,
      );

      expect(snapshot.percent, 0.5);
      expect(snapshot.basis, ProgressBasis.metric);
      expect(snapshot.percentLabel, '50%');
    });

    test('falls back to roadmap progress when metric is missing', () {
      final snapshot = engine.snapshotForSkill(
        skill(
          treeNodes: [
            SkillTreeNode(id: 'stage-1', title: 'Основа', isMastered: true),
            SkillTreeNode(
              id: 'stage-2',
              title: 'Сила',
              prerequisiteIds: ['stage-1'],
            ),
          ],
        ),
        const [],
        now: now,
      );

      expect(snapshot.percent, 0.5);
      expect(snapshot.basis, ProgressBasis.roadmap);
      expect(snapshot.currentStage?.id, 'stage-2');
    });

    test('collects weekly delta and recent wins for the skill', () {
      final snapshot = engine.snapshotForSkill(skill(), [
        win(title: 'Свежая победа', xp: 30),
        win(skillId: 'other', title: 'Чужая победа', xp: 50),
        win(
          title: 'Старая победа',
          xp: 40,
          at: now.subtract(const Duration(days: 9)),
        ),
      ], now: now);

      expect(snapshot.weeklyDelta, 30);
      expect(snapshot.weeklyQuestCount, 1);
      expect(snapshot.recentWins.single.taskTitle, 'Свежая победа');
    });

    test('flags goal that has no progress for two weeks', () {
      final snapshot = engine.snapshotForSkill(
        skill(
          goalSpec: GoalSpec(
            text: 'Подтягиваться 20 раз',
            updatedAt: now.subtract(const Duration(days: 20)),
          ),
        ),
        [win(at: now.subtract(const Duration(days: 18)))],
        now: now,
      );

      expect(snapshot.needsAdjust, isTrue);
    });

    test('fresh review suppresses stalled signal', () {
      final snapshot = engine.snapshotForSkill(
        skill(
          goalSpec: GoalSpec(
            text: 'Подтягиваться 20 раз',
            updatedAt: now.subtract(const Duration(days: 20)),
            reviews: [
              GoalReviewEntry(
                id: 'review-1',
                createdAt: now.subtract(const Duration(days: 2)),
              ),
            ],
          ),
        ),
        [win(at: now.subtract(const Duration(days: 18)))],
        now: now,
      );

      expect(snapshot.needsAdjust, isFalse);
    });
  });
}
