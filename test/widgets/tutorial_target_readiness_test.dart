import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/widgets/tutorial/tutorial_target_readiness.dart';

Widget _harness({
  required GlobalKey targetKey,
  required bool showTarget,
  bool enabled = true,
  Duration fallbackTimeout = const Duration(milliseconds: 300),
}) {
  return MaterialApp(
    home: Stack(
      children: [
        if (showTarget) SizedBox(key: targetKey, width: 48, height: 48),
        TutorialTargetReadiness(
          stepId: 'step',
          targetKey: targetKey,
          enabled: enabled,
          fallbackTimeout: fallbackTimeout,
          probeInterval: const Duration(milliseconds: 25),
          builder: (context, status) =>
              Text(status.name, textDirection: TextDirection.ltr),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('reports ready after target is laid out', (tester) async {
    final targetKey = GlobalKey();

    await tester.pumpWidget(_harness(targetKey: targetKey, showTarget: true));
    await tester.pump();

    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('waits for a target added on a later frame', (tester) async {
    final targetKey = GlobalKey();

    await tester.pumpWidget(_harness(targetKey: targetKey, showTarget: false));
    expect(find.text('waiting'), findsOneWidget);

    await tester.pumpWidget(_harness(targetKey: targetKey, showTarget: true));
    await tester.pump();

    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('uses bounded fallback when target never appears', (
    tester,
  ) async {
    final targetKey = GlobalKey();

    await tester.pumpWidget(
      _harness(
        targetKey: targetKey,
        showTarget: false,
        fallbackTimeout: const Duration(milliseconds: 100),
      ),
    );
    await tester.pump(const Duration(milliseconds: 99));
    expect(find.text('waiting'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('fallback'), findsOneWidget);
  });

  testWidgets('scheduled probe is disposal safe', (tester) async {
    final targetKey = GlobalKey();

    await tester.pumpWidget(_harness(targetKey: targetKey, showTarget: false));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disabled readiness remains waiting without scheduling fallback',
    (tester) async {
      final targetKey = GlobalKey();

      await tester.pumpWidget(
        _harness(
          targetKey: targetKey,
          showTarget: false,
          enabled: false,
          fallbackTimeout: const Duration(milliseconds: 50),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('waiting'), findsOneWidget);
      expect(find.text('fallback'), findsNothing);
    },
  );

  testWidgets('navigation probe completes only after target is laid out', (
    tester,
  ) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(_harness(targetKey: targetKey, showTarget: false));

    var completed = false;
    var ready = false;
    TutorialTargetProbe.waitUntilReady(
      targetKey,
      timeout: const Duration(milliseconds: 200),
      probeInterval: const Duration(milliseconds: 25),
    ).then((value) {
      completed = true;
      ready = value;
    });

    await tester.pump(const Duration(milliseconds: 24));
    expect(completed, isFalse);

    await tester.pumpWidget(_harness(targetKey: targetKey, showTarget: true));
    await tester.pump(const Duration(milliseconds: 25));

    expect(completed, isTrue);
    expect(ready, isTrue);
  });

  testWidgets('navigation probe has a wall-clock bounded fallback', (
    tester,
  ) async {
    final targetKey = GlobalKey();
    await tester.pumpWidget(_harness(targetKey: targetKey, showTarget: false));

    bool? ready;
    TutorialTargetProbe.waitUntilReady(
      targetKey,
      timeout: const Duration(milliseconds: 100),
      probeInterval: const Duration(milliseconds: 25),
    ).then((value) => ready = value);

    await tester.pump(const Duration(milliseconds: 99));
    expect(ready, isNull);
    await tester.pump(const Duration(milliseconds: 1));

    expect(ready, isFalse);
  });
}
