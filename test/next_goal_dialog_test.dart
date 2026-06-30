import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/widgets/dialogs.dart';

void main() {
  Future<void> openRoadmapPrompt(
    WidgetTester tester,
    ValueChanged<NextRoadmapChoice?> onResult, {
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showDialog<NextRoadmapChoice>(
                  context: context,
                  builder: (_) => const NextRoadmapPromptDialog(
                    isDark: false,
                    color: Colors.blue,
                  ),
                );
                onResult(result);
              },
              child: const Text('Открыть prompt'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть prompt'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('next-goal dialog validates input and returns trimmed goal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => const NextGoalDialog(
                    isDark: false,
                    color: Colors.blue,
                    currentGoal: 'Освоить основы Flutter',
                  ),
                );
              },
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    expect(find.text('Освоить основы Flutter'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Задать цель'));
    await tester.pump();
    expect(find.text('Введите следующую цель'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('next-goal-field')),
      '  Освоить архитектуру Flutter  ',
    );
    await tester.tap(find.text('Задать цель'));
    await tester.pumpAndSettle();

    expect(result, 'Освоить архитектуру Flutter');
    expect(find.byType(NextGoalDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel closes next-goal dialog without a value', (tester) async {
    String? result = 'not-closed';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => const NextGoalDialog(
                    isDark: false,
                    color: Colors.blue,
                    currentGoal: 'Освоить основы Flutter',
                  ),
                );
              },
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('next-goal-field')),
      'Несохранённая цель',
    );
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(find.byType(NextGoalDialog), findsNothing);
    expect(result, isNull);
  });

  testWidgets('roadmap prompt is readable at 360dp and keeps current map', (
    tester,
  ) async {
    NextRoadmapChoice? result;
    var resolved = false;
    await openRoadmapPrompt(tester, (choice) {
      result = choice;
      resolved = true;
    });
    expect(resolved, isFalse);
    expect(find.text('Следующая цель задана'), findsOneWidget);
    expect(find.text('Оставить текущую карту'), findsOneWidget);
    expect(find.text('Создать новую карту'), findsOneWidget);
    expect(find.text('Добавить этап'), findsOneWidget);

    await tester.tap(find.text('Оставить текущую карту'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(result, NextRoadmapChoice.keepCurrent);
    expect(find.byType(NextRoadmapPromptDialog), findsNothing);
  });

  testWidgets('roadmap prompt returns add-stage choice', (tester) async {
    NextRoadmapChoice? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<NextRoadmapChoice>(
                  context: context,
                  builder: (_) => const NextRoadmapPromptDialog(
                    isDark: true,
                    color: Colors.orange,
                  ),
                );
              },
              child: const Text('Открыть prompt'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть prompt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить этап'));
    await tester.pumpAndSettle();

    expect(result, NextRoadmapChoice.addStage);
    expect(find.byType(NextRoadmapPromptDialog), findsNothing);
  });

  testWidgets('roadmap prompt returns create-new choice', (tester) async {
    NextRoadmapChoice? result;
    await openRoadmapPrompt(tester, (choice) => result = choice);

    await tester.tap(find.text('Создать новую карту'));
    await tester.pumpAndSettle();

    expect(result, NextRoadmapChoice.createNew);
    expect(find.byType(NextRoadmapPromptDialog), findsNothing);
  });

  testWidgets('closing roadmap prompt returns no choice', (tester) async {
    NextRoadmapChoice? result = NextRoadmapChoice.addStage;
    var resolved = false;
    await openRoadmapPrompt(tester, (choice) {
      result = choice;
      resolved = true;
    });

    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(result, isNull);
  });
}
