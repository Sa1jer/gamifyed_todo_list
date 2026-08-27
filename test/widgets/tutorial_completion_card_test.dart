import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/widgets/tutorial/tutorial_completion_card.dart';

Widget _harness({
  required bool isDark,
  required bool reducedMotion,
  required double textScale,
  required VoidCallback onDismiss,
  Duration displayDuration = const Duration(seconds: 4),
}) {
  return MaterialApp(
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Stack(
      children: [
        TutorialCompletionCard(
          isDark: isDark,
          reducedMotion: reducedMotion,
          onDismiss: onDismiss,
          displayDuration: displayDuration,
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('Core completion is dismissible without a continuation gate', (
    tester,
  ) async {
    var dismissed = false;

    await tester.pumpWidget(
      _harness(
        isDark: true,
        reducedMotion: true,
        textScale: 1,
        onDismiss: () => dismissed = true,
      ),
    );

    expect(find.text('Основу ты знаешь.'), findsOneWidget);
    expect(find.text('Остальные темы доступны в профиле.'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('tutorial-core-completion-dismiss')),
    );

    expect(dismissed, isTrue);
  });

  testWidgets('Core completion supports light theme and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var dismissed = false;
    await tester.pumpWidget(
      _harness(
        isDark: false,
        reducedMotion: false,
        textScale: 2,
        onDismiss: () => dismissed = true,
        displayDuration: const Duration(milliseconds: 500),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Основу ты знаешь.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tutorial-core-completion-dismiss')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 501));
    expect(dismissed, isTrue);
  });
}
