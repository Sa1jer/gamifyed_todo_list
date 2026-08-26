import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/widgets/tutorial/tutorial_completion_card.dart';

Widget _harness({
  required bool isDark,
  required bool reducedMotion,
  required double textScale,
  required VoidCallback onContinue,
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
          onContinue: onContinue,
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('Core completion is accessible and has one continuation action', (
    tester,
  ) async {
    var continued = false;

    await tester.pumpWidget(
      _harness(
        isDark: true,
        reducedMotion: true,
        textScale: 1,
        onContinue: () => continued = true,
      ),
    );

    expect(find.text('Готово. Основу ты знаешь.'), findsOneWidget);
    expect(find.textContaining('Остальные темы'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('tutorial-core-completion-continue')),
    );

    expect(continued, isTrue);
  });

  testWidgets('Core completion supports light theme and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _harness(
        isDark: false,
        reducedMotion: false,
        textScale: 2,
        onContinue: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Готово. Основу ты знаешь.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tutorial-core-completion-continue')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
