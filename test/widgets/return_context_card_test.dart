import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/return_context_resolver.dart';
import 'package:todo_list_app/theme/app_typography.dart';
import 'package:todo_list_app/widgets/return_context_card.dart';

void main() {
  ReturnContextCandidate candidate({
    String? stage = 'Форма создания задачи',
    String? result = 'Проверена валидация',
  }) => ReturnContextCandidate(
    key: 'candidate',
    source: ReturnContextSource.completionHistory,
    sourceAt: DateTime.utc(2026, 7, 15),
    skillId: 'skill-a',
    skillName: 'Разработка приложения',
    taskId: 'task-a',
    taskTitle: 'Проверить редактирование',
    stageId: stage == null ? null : 'stage-a',
    stageTitle: stage,
    lastResult: result,
    reentryAction:
        'Проверить редактирование существующей задачи и сохранить результат',
    usesMinimumAction: false,
  );

  ThemeData theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7562FF),
      brightness: brightness,
    );
    final textTheme = AppTypography.textTheme(scheme);
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: [AppTextRoles.fromTheme(textTheme, brightness: brightness)],
    );
  }

  Widget harness({
    required ReturnContextCandidate data,
    bool desktop = false,
    bool dark = true,
    bool reducedMotion = false,
    double width = 393,
    double textScale = 1,
    VoidCallback? onContinue,
    VoidCallback? onAnother,
    VoidCallback? onDismiss,
  }) {
    return MaterialApp(
      theme: theme(dark ? Brightness.dark : Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                child: ReturnContextCard(
                  candidate: data,
                  isDark: dark,
                  desktop: desktop,
                  reducedMotion: reducedMotion,
                  onContinue: onContinue ?? () {},
                  onAnotherAction: onAnother ?? () {},
                  onDismiss: onDismiss ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders reliable rows and omits unavailable evidence', (
    tester,
  ) async {
    await tester.pumpWidget(harness(data: candidate()));

    expect(find.text('Продолжить путь'), findsOneWidget);
    expect(find.text('Разработка приложения'), findsOneWidget);
    expect(find.textContaining('Текущий этап:'), findsOneWidget);
    expect(find.textContaining('Где остановились:'), findsNothing);
    expect(find.textContaining('Последний результат:'), findsOneWidget);
    expect(find.textContaining('Следующий шаг:'), findsOneWidget);

    await tester.pumpWidget(
      harness(data: candidate(stage: null, result: null)),
    );
    expect(find.byKey(const ValueKey('return-context-stage')), findsNothing);
    expect(
      find.byKey(const ValueKey('return-context-last-result')),
      findsNothing,
    );
  });

  testWidgets('actions are reachable and keep 48dp touch targets', (
    tester,
  ) async {
    var continued = 0;
    var changed = 0;
    var dismissed = 0;
    await tester.pumpWidget(
      harness(
        data: candidate(),
        onContinue: () => continued++,
        onAnother: () => changed++,
        onDismiss: () => dismissed++,
      ),
    );

    for (final key in const [
      'return-context-continue',
      'return-context-another',
      'return-context-dismiss',
    ]) {
      expect(
        tester.getSize(find.byKey(ValueKey(key))).height,
        greaterThanOrEqualTo(48),
      );
    }
    await tester.tap(find.byKey(const ValueKey('return-context-continue')));
    await tester.tap(find.byKey(const ValueKey('return-context-another')));
    await tester.tap(find.byKey(const ValueKey('return-context-dismiss')));
    expect((continued, changed, dismissed), (1, 1, 1));
  });

  testWidgets('360dp at 200% text scale reflows without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(data: candidate(), width: 360, textScale: 2, reducedMotion: true),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('return-context-card')), findsOneWidget);
    expect(find.text('Продолжить'), findsOneWidget);
  });

  testWidgets('desktop and light variants retain semantics', (tester) async {
    await tester.pumpWidget(
      harness(data: candidate(), desktop: true, dark: false, width: 900),
    );

    expect(tester.takeException(), isNull);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('return-context-card')),
    );
    expect(semantics.label, contains('Продолжить путь'));
    expect(semantics.label, contains('Навык: Разработка приложения'));
    expect(semantics.label, contains('Следующий шаг:'));
  });
}
