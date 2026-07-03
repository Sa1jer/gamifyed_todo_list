import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/widgets/mobile_journal_tokens.dart';

void main() {
  test('mobile responsive metrics cover the supported width buckets', () {
    expect(
      MobileResponsiveMetrics.fromWidth(360).bucket,
      MobileWidthBucket.compact,
    );
    expect(
      MobileResponsiveMetrics.fromWidth(393).bucket,
      MobileWidthBucket.normal,
    );
    expect(
      MobileResponsiveMetrics.fromWidth(430).bucket,
      MobileWidthBucket.largePhone,
    );
    expect(
      MobileResponsiveMetrics.fromWidth(760).bucket,
      MobileWidthBucket.tablet,
    );
    expect(MobileResponsiveMetrics.isMobileWidth(760), isTrue);
    expect(MobileResponsiveMetrics.isMobileWidth(761), isFalse);
  });

  testWidgets('mobile motion combines platform and app preferences', (
    WidgetTester tester,
  ) async {
    late Duration normal;
    late Duration appReduced;
    late Duration platformReduced;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            normal = MobileMotion.duration(context);
            appReduced = MobileMotion.duration(context, appReducedMotion: true);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Builder(
                builder: (reducedContext) {
                  platformReduced = MobileMotion.duration(reducedContext);
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(normal, const Duration(milliseconds: 220));
    expect(appReduced, Duration.zero);
    expect(platformReduced, Duration.zero);
  });

  test('light journal palette keeps readable foreground contrast', () {
    double contrast(Color a, Color b) {
      final bright = a.computeLuminance() + 0.05;
      final dark = b.computeLuminance() + 0.05;
      return bright > dark ? bright / dark : dark / bright;
    }

    expect(
      contrast(
        MobileJournalTokens.text(false),
        MobileJournalTokens.background(false),
      ),
      greaterThan(7),
    );
    expect(
      contrast(
        MobileJournalTokens.rewardGoldForeground(false),
        MobileJournalTokens.rewardGoldBackground(false),
      ),
      greaterThan(4.5),
    );
    expect(
      MobileJournalTokens.background(false),
      isNot(const Color(0xFFFFFFFF)),
    );
  });
}
