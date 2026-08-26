import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/tutorial/welcome_copy.dart';
import 'package:todo_list_app/widgets/welcome_page.dart';

Widget _welcomeHarness({
  required bool isDark,
  required double textScale,
  bool reducedMotion = true,
  VoidCallback? onBegin,
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
    home: WelcomePage(
      isDark: isDark,
      reducedMotion: reducedMotion,
      onBegin: onBegin ?? () {},
    ),
  );
}

void main() {
  testWidgets('Welcome CTA is the only primary first-run action', (
    tester,
  ) async {
    var began = false;
    await tester.pumpWidget(
      _welcomeHarness(isDark: true, textScale: 1, onBegin: () => began = true),
    );

    expect(find.text(WelcomeCopy.title), findsOneWidget);
    expect(find.text(WelcomeCopy.beginLabel), findsOneWidget);
    expect(find.text(WelcomeCopy.localDataNote), findsOneWidget);
    expect(find.textContaining('Войти'), findsNothing);
    expect(find.textContaining('Язык'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('welcome-begin-action')));

    expect(began, isTrue);
  });

  testWidgets('Welcome remains usable across supported widths and themes', (
    tester,
  ) async {
    for (final width in <double>[360, 393, 430, 700, 1180]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;

      for (final isDark in <bool>[true, false]) {
        await tester.pumpWidget(
          _welcomeHarness(isDark: isDark, textScale: 1.3),
        );
        await tester.pump();

        expect(find.byKey(const ValueKey('welcome-page')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('welcome-begin-action')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: 'width=$width');
      }
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Welcome supports 200 percent text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_welcomeHarness(isDark: true, textScale: 2));
    await tester.pump();

    expect(find.text(WelcomeCopy.title), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-begin-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Welcome supports both animated and reduced-motion entry', (
    tester,
  ) async {
    for (final reducedMotion in <bool>[false, true]) {
      await tester.pumpWidget(
        _welcomeHarness(
          isDark: true,
          textScale: 1,
          reducedMotion: reducedMotion,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('welcome-page')), findsOneWidget);
      expect(find.text(WelcomeCopy.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
