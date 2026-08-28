import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/widgets/tutorial/tutorial_completion_card.dart';

Widget _harness({
  required bool isDark,
  required bool reducedMotion,
  required double textScale,
  required VoidCallback onShowRest,
  required VoidCallback onStartUsing,
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
          onShowRest: onShowRest,
          onStartUsing: onStartUsing,
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('Core completion offers optional continuation and normal use', (
    tester,
  ) async {
    var showRest = false;
    var startUsing = false;

    await tester.pumpWidget(
      _harness(
        isDark: true,
        reducedMotion: true,
        textScale: 1,
        onShowRest: () => showRest = true,
        onStartUsing: () => startUsing = true,
      ),
    );

    expect(find.text('Основу ты знаешь.'), findsOneWidget);
    expect(find.text('Показать остальное'), findsOneWidget);
    expect(find.text('Начать пользоваться'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorial-core-show-rest')));
    expect(showRest, isTrue);
    expect(startUsing, isFalse);
  });

  testWidgets('Core completion supports light theme and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var startUsing = false;
    await tester.pumpWidget(
      _harness(
        isDark: false,
        reducedMotion: false,
        textScale: 2,
        onShowRest: () {},
        onStartUsing: () => startUsing = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Основу ты знаешь.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tutorial-core-start-using')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('tutorial-core-start-using')));
    expect(startUsing, isTrue);
  });
}
