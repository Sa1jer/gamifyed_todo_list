import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/widgets/skill_goal_progress.dart';

void main() {
  Skill skillWithStages(List<SkillTreeNode> stages) {
    return Skill(
      id: 'skill-1',
      name: 'Навык',
      goal: 'Достичь цели',
      color: Colors.orange,
      icon: Icons.flag,
      treeNodes: stages,
    );
  }

  Future<void> pumpProgress(WidgetTester tester, Skill skill) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: SkillGoalProgress(skill: skill, isDark: false),
          ),
        ),
      ),
    );
  }

  testWidgets('zero-stage skill shows a neutral empty state', (tester) async {
    await pumpProgress(tester, skillWithStages([]));

    expect(find.text('Добавьте этапы'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Цель достигнута'), findsNothing);
  });

  testWidgets('skill progress displays completed stage percentage', (
    tester,
  ) async {
    await pumpProgress(
      tester,
      skillWithStages([
        SkillTreeNode(id: '1', title: '1', isMastered: true),
        SkillTreeNode(id: '2', title: '2'),
        SkillTreeNode(id: '3', title: '3'),
        SkillTreeNode(id: '4', title: '4'),
      ]),
    );

    expect(find.text('Прогресс цели'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.25,
    );
  });

  testWidgets('completed skill suggests setting the next goal', (tester) async {
    await pumpProgress(
      tester,
      skillWithStages([SkillTreeNode(id: '1', title: '1', isMastered: true)]),
    );

    expect(find.text('Цель достигнута'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Можно задать следующую цель'), findsOneWidget);
  });

  testWidgets('next-goal action is only exposed for completed progress', (
    tester,
  ) async {
    var pressed = false;
    final completedSkill = skillWithStages([
      SkillTreeNode(id: '1', title: '1', isMastered: true),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkillGoalProgress(
            skill: completedSkill,
            isDark: false,
            onSetNextGoal: () => pressed = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Задать следующую цель'));

    expect(pressed, isTrue);

    await pumpProgress(
      tester,
      skillWithStages([SkillTreeNode(id: '2', title: '2')]),
    );
    expect(find.text('Задать следующую цель'), findsNothing);
  });
}
