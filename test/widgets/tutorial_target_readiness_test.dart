import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/widgets/tutorial/tutorial_target_readiness.dart';

Widget _harness({
  required GlobalKey targetKey,
  required bool showTarget,
  bool enabled = true,
  int maxFrameAttempts = 3,
}) {
  return MaterialApp(
    home: Stack(
      children: [
        if (showTarget) SizedBox(key: targetKey, width: 48, height: 48),
        TutorialTargetReadiness(
          stepId: 'step',
          targetKey: targetKey,
          enabled: enabled,
          maxFrameAttempts: maxFrameAttempts,
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
      _harness(targetKey: targetKey, showTarget: false, maxFrameAttempts: 2),
    );
    await tester.pump();
    await tester.pump();

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
          maxFrameAttempts: 1,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('waiting'), findsOneWidget);
      expect(find.text('fallback'), findsNothing);
    },
  );
}
