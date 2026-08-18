import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/momentum_resolver.dart';
import 'package:todo_list_app/theme/app_typography.dart';
import 'package:todo_list_app/widgets/momentum_evidence_card.dart';

void main() {
  const snapshot = MomentumSnapshot(
    key: 'momentum-stage-a-task-a',
    reason: MomentumReason.stageOneQuestRemaining,
    headline: 'Движение уже есть',
    supportingText: 'До завершения этапа «Практика» остался один квест.',
    skillId: 'skill-a',
    skillName: 'Разработка приложения',
    taskId: 'task-a',
    actionLabel: 'Проверить сценарий',
    stageId: 'stage-a',
    progressFraction: .67,
    remainingCount: 1,
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
    double width = 393,
    double textScale = 1,
    bool dark = true,
    bool desktop = false,
    bool reducedMotion = false,
  }) {
    return MaterialApp(
      theme: theme(dark ? Brightness.dark : Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: width,
              child: MomentumEvidenceCard(
                snapshot: snapshot,
                isDark: dark,
                desktop: desktop,
                reducedMotion: reducedMotion,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('is passive, truthful, and semantically complete', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    final card = find.byKey(const ValueKey('momentum-evidence-card'));

    expect(card, findsOneWidget);
    expect(find.text('Движение уже есть'), findsOneWidget);
    expect(find.textContaining('остался один квест'), findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.byType(ButtonStyleButton)),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.byType(InkWell)),
      findsNothing,
    );
    final semantics = tester.getSemantics(card);
    expect(semantics.label, contains('Движение уже есть'));
    expect(semantics.label, contains('Навык: Разработка приложения'));
  });

  for (final width in [360.0, 393.0, 430.0, 700.0]) {
    testWidgets('mobile $width dp remains readable at 200% text scale', (
      tester,
    ) async {
      await tester.pumpWidget(harness(width: width, textScale: 2));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('momentum-evidence-copy')),
        findsOneWidget,
      );
    });
  }

  testWidgets('light and desktop variants stay within their constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(width: 1024, desktop: true, dark: false, textScale: 1.3),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      harness(width: 1440, desktop: true, dark: true, textScale: 2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion makes shell transitions immediate', (
    tester,
  ) async {
    await tester.pumpWidget(harness(reducedMotion: true));

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('momentum-evidence-card')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final switcher = tester.widget<AnimatedSwitcher>(
      find.descendant(
        of: find.byKey(const ValueKey('momentum-evidence-card')),
        matching: find.byType(AnimatedSwitcher),
      ),
    );
    expect(container.duration, Duration.zero);
    expect(switcher.duration, Duration.zero);
  });
}
