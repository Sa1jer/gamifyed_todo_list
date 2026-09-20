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

  /// Перехватывает канал url_launcher и буфер обмена.
  ///
  /// [canOpen] решает, притворяется ли платформа способной открыть ссылку:
  /// именно на этой развилке и живёт запасной путь.
  ({List<String> launched, List<String> copied}) mockChannels(
    WidgetTester tester, {
    required bool canOpen,
  }) {
    final launched = <String>[];
    final copied = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        if (call.method == 'launch') {
          launched.add((call.arguments as Map)['url'] as String);
          return canOpen;
        }
        if (call.method == 'canLaunch') return canOpen;
        return null;
      },
    );

    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      );
    });
    return (launched: launched, copied: copied);
  }

  testWidgets('the release page opens in a browser', (tester) async {
    final channels = mockChannels(tester, canOpen: true);
    final checker = UpdateChecker(
      currentBuild: 2,
      fetch: () async => release('v1.4.0+9'),
    );

    await tester.pumpWidget(harness(checker));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-update-open')));
    await tester.pumpAndSettle();

    expect(channels.launched, ['https://example.invalid/v1.4.0+9']);
    expect(
      channels.copied,
      isEmpty,
      reason: 'браузер открылся, копировать нечего',
    );
  });

  testWidgets('a browser that will not open falls back to the clipboard', (
    tester,
  ) async {
    final channels = mockChannels(tester, canOpen: false);
    final checker = UpdateChecker(
      currentBuild: 2,
      fetch: () async => release('v1.4.0+9'),
    );

    await tester.pumpWidget(harness(checker));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-update-open')));
    await tester.pumpAndSettle();

    // Без ссылки человек не сможет обновиться вовсе, поэтому отказ браузера —
    // это запасной путь, а не сообщение об ошибке.
    expect(channels.copied, ['https://example.invalid/v1.4.0+9']);
    expect(find.textContaining('ссылка скопирована'), findsOneWidget);
  });
}
