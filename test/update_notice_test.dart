import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/update_check.dart';
import 'package:todo_list_app/widgets/shared/update_notice.dart';

void main() {
  Widget harness(UpdateChecker checker) => MaterialApp(
    home: Scaffold(body: UpdateNotice(checker: checker, isDark: true)),
  );

  Map<String, dynamic> release(String tag) => {
    'tag_name': tag,
    'draft': false,
    'prerelease': false,
    'html_url': 'https://example.invalid/$tag',
  };

  testWidgets('a newer build lights a notice with the version', (tester) async {
    final checker = UpdateChecker(
      currentBuild: 2,
      fetch: () async => release('v1.4.0+9'),
    );

    await tester.pumpWidget(harness(checker));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-update-notice')), findsOneWidget);
    expect(find.textContaining('1.4.0+9'), findsOneWidget);
  });

  testWidgets('being up to date takes no space at all', (tester) async {
    final checker = UpdateChecker(
      currentBuild: 9,
      fetch: () async => release('v1.4.0+9'),
    );

    await tester.pumpWidget(harness(checker));
    await tester.pumpAndSettle();

    // Не пустая рамка и не «у вас последняя версия»: сказать нечего — значит
    // не занимать место.
    expect(find.byKey(const ValueKey('profile-update-notice')), findsNothing);
    expect(tester.getSize(find.byType(UpdateNotice)), Size.zero);
  });

  testWidgets('a failed check stays quiet', (tester) async {
    final checker = UpdateChecker(
      currentBuild: 2,
      fetch: () async => throw Exception('нет сети'),
    );

    await tester.pumpWidget(harness(checker));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-update-notice')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the link can be copied', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final checker = UpdateChecker(
      currentBuild: 2,
      fetch: () async => release('v1.4.0+9'),
    );

    await tester.pumpWidget(harness(checker));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-update-copy-link')));
    await tester.pumpAndSettle();

    expect(copied, ['https://example.invalid/v1.4.0+9']);
  });
}
