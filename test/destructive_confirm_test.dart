import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/widgets/shared/destructive_confirm.dart';

void main() {
  /// Ответы копятся здесь: диалог отвечает уже после закрытия, поэтому
  /// проверять возвращённое значение можно только после `pumpAndSettle`.
  late List<bool> answers;

  Future<void> open(WidgetTester tester) async {
    answers = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                answers.add(
                  await confirmDestructiveAction(
                    context,
                    isDark: false,
                    title: 'Удалить этап?',
                    message: 'Этап и его чек-лист будут удалены.',
                    confirmLabel: 'Удалить этап',
                    confirmKey: const ValueKey('confirm-destructive'),
                  ),
                );
              },
              child: const Text('открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('открыть'));
    await tester.pumpAndSettle();
  }

  testWidgets('the confirming action is named by an icon, not only by colour', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Удалить этап?'), findsOneWidget);
    expect(find.text('Этап и его чек-лист будут удалены.'), findsOneWidget);

    // Смысл пункта аудита: одного красного мало. При дальтонизме и в режиме
    // принудительных цветов от сигнала остаются только иконка и подпись.
    final confirm = find.byKey(const ValueKey('confirm-destructive'));
    expect(confirm, findsOneWidget);
    expect(
      find.descendant(
        of: confirm,
        matching: find.byIcon(Icons.delete_outline_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: confirm, matching: find.text('Удалить этап')),
      findsOneWidget,
    );
  });

  testWidgets('confirming answers yes', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('confirm-destructive')));
    await tester.pumpAndSettle();

    expect(answers, [true]);
    expect(find.text('Удалить этап?'), findsNothing);
  });

  testWidgets('cancelling answers no rather than nothing', (tester) async {
    await open(tester);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    // Именно false, а не null: вызывающий код ветвится по булеву значению,
    // и на null удаление прошло бы молча.
    expect(answers, [false]);
    expect(find.text('Удалить этап?'), findsNothing);
  });

  testWidgets('dismissing by the barrier is refusal, not consent', (
    tester,
  ) async {
    await open(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(answers, [false]);
    expect(find.text('Удалить этап?'), findsNothing);
  });
}
