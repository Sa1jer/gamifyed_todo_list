import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/next_action_resolver.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/persistence_status.dart';
import 'package:todo_list_app/utils.dart';
import 'package:todo_list_app/widgets/next_action_lens.dart';

void main() {
  final skill = Skill(
    id: 'skill-1',
    name: 'Разработка',
    goal: '',
    color: Colors.blue,
    icon: Icons.code_rounded,
  );

  Task task({
    String title = 'Открыть экран и исправить один заметный отступ',
  }) => Task(
    id: 'task-1',
    title: title,
    skillId: skill.id,
    xpReward: 20,
    type: TaskType.shortTerm,
    minimumAction: 'Открыть экран и исправить один отступ',
  );

  Widget lens(
    Task task, {
    PersistenceStatus status = const PersistenceStatus(
      phase: PersistencePhase.ready,
    ),
  }) {
    final result = const NextActionResolver().resolve(
      skills: [skill],
      tasks: [task],
    );
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: NextActionLens(
            resolution: result,
            persistenceStatus: status,
            isDark: true,
            onOpenTask: (_) {},
            onChooseTask: (_) {},
            onOpenEmptySkill: (_) {},
            onCreateSkill: () {},
          ),
        ),
      ),
    );
  }

  testWidgets(
    'mobile Lens is readable at 360dp and Boot completion is not quest completion',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = task(
        title:
            'Очень длинное действие, которое должно оставаться понятным даже на узком мобильном экране',
      );

      await tester.pumpWidget(lens(source));

      expect(find.byKey(const ValueKey('next-action-lens')), findsOneWidget);
      expect(find.byKey(const ValueKey('next-action-title')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('next-action-boot-entry')));
      await tester.pumpAndSettle();
      expect(find.text('С чего начать'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('boot-entry-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('boot-entry-active')), findsOneWidget);

      for (var index = 0; index < 3; index++) {
        await tester.tap(find.byType(Checkbox).at(index));
      }
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('boot-entry-complete')).first);
      await tester.pumpAndSettle();

      expect(find.text('Вход завершён'), findsOneWidget);
      expect(source.isDone, isFalse);
      expect(source.earnedXP, 0);
      expect(source.minimumActionEarnedXP, 0);
    },
  );

  testWidgets('recovery state does not expose Boot Entry editing', (
    tester,
  ) async {
    await tester.pumpWidget(
      lens(
        task(),
        status: const PersistenceStatus(
          phase: PersistencePhase.loading,
          blocksSaving: true,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('next-action-recovery')), findsOneWidget);
    expect(find.byKey(const ValueKey('next-action-boot-entry')), findsNothing);
  });
}
