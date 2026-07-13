import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';
import 'package:todo_list_app/widgets/mobile_journal_tokens.dart';
import 'package:todo_list_app/widgets/shared.dart';

void main() {
  test('completion toast resolves task source separately from reward gold', () {
    const red = Color(0xFFFF1635);
    const blue = Color(0xFF4A9EFF);
    final redSkill = Skill(
      id: 'red',
      name: 'Red',
      goal: '',
      color: red,
      icon: Icons.flag_rounded,
    );
    final blueSkill = Skill(
      id: 'blue',
      name: 'Blue',
      goal: '',
      color: blue,
      icon: Icons.flag_rounded,
    );
    final redTask = Task(
      id: 'red-task',
      title: 'Red task',
      skillId: redSkill.id,
      xpReward: 20,
      type: TaskType.shortTerm,
    );
    final blueTask = Task(
      id: 'blue-task',
      title: 'Blue task',
      skillId: blueSkill.id,
      xpReward: 20,
      type: TaskType.shortTerm,
    );
    final inboxTask = Task(
      id: 'inbox-task',
      title: 'Inbox task',
      skillId: kInboxSkillId,
      xpReward: 0,
      type: TaskType.shortTerm,
    );
    final orphanTask = Task(
      id: 'orphan-task',
      title: 'Orphan task',
      skillId: 'missing-skill',
      xpReward: 20,
      type: TaskType.shortTerm,
    );

    final skills = [redSkill, blueSkill];
    final redToast = completionToastColorsForTask(
      task: redTask,
      skills: skills,
    );
    final blueToast = completionToastColorsForTask(
      task: blueTask,
      skills: skills,
    );
    final inboxToast = completionToastColorsForTask(
      task: inboxTask,
      skills: skills,
    );
    final fallbackToast = completionToastColorsForTask(
      task: orphanTask,
      skills: skills,
    );

    expect(redToast.sourceAccentColor, red);
    expect(blueToast.sourceAccentColor, blue);
    expect(inboxToast.sourceAccentColor, MobileJournalTokens.inbox);
    expect(
      fallbackToast.sourceAccentColor,
      CompletionToastColors.fallbackSourceAccent,
    );
    for (final toast in [redToast, blueToast, inboxToast, fallbackToast]) {
      expect(toast.rewardColor, MobileJournalTokens.rewardGold);
    }
  });

  testWidgets('XP bubble uses source chrome and gold reward emphasis', (
    WidgetTester tester,
  ) async {
    const red = Color(0xFFFF1635);
    const colors = CompletionToastColors(sourceAccentColor: red);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Stack(
            children: [
              XPBubble(
                message: '+10 XP · быстрое действие',
                placement: ActionToastPlacement.resolve(
                  sourceRect: const Rect.fromLTWH(180, 180, 24, 24),
                  kind: ActionToastOriginKind.questCheckbox,
                  viewport: const Size(400, 400),
                ),
                colors: colors,
                onDone: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('xp-bubble-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.border!.top.color, colors.borderColor(isDark: true));
    expect(decoration.boxShadow!.last.color, colors.glowColor(isDark: true));
    final icon = tester.widget<Icon>(
      find.byKey(const ValueKey('xp-bubble-reward-icon')),
    );
    expect(icon.color, MobileJournalTokens.rewardGold);
    final rewardLine = tester.widget<Text>(
      find.byKey(const ValueKey('xp-bubble-reward-line')),
    );
    final spans = (rewardLine.textSpan! as TextSpan).children!
        .whereType<TextSpan>();
    expect(
      spans.any(
        (span) =>
            span.text == '+10 XP' &&
            span.style?.color == MobileJournalTokens.rewardGold,
      ),
      isTrue,
    );
    expect(find.text('Опыт получен'), findsOneWidget);
    expect(
      find.text('+10 XP · Быстрое действие', findRichText: true),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 2));
  });

  test('completion toast separates base XP from effect bonus', () {
    final content = CompletionToastContent.fromMessage(
      'Навык окреп\nСпорт +24 XP • эффект +2 XP • до ур. 2 92 XP',
    );

    expect(content.title, 'Навык окреп');
    expect(content.skillName, 'Спорт');
    expect(content.baseXp, 22);
    expect(content.bonusXp, 2);
    expect(content.nextLevelHint, 'До следующего уровня 92 XP');
  });

  test(
    'completion toast formats the AppState skill-level-up event as growth',
    () {
      final content = CompletionToastContent.fromMessage(
        'Навык вырос\nСпорт окреп до ур.2 • +24 XP • эффект +2 XP '
        '• до ур.3 92 XP',
      );

      expect(content.title, 'Навык окреп');
      expect(content.skillName, 'Спорт');
      expect(content.baseXp, 22);
      expect(content.bonusXp, 2);
      expect(content.nextLevelHint, 'До следующего уровня 92 XP');
    },
  );

  test('completion toast hides distant next-level progress by default', () {
    final content = CompletionToastContent.fromMessage(
      'Навык окреп\nСпорт +20 XP • до ур. 2 100 XP',
    );

    expect(content.nextLevelHint, isNull);
  });

  test('action toast stays inside a bottom-navigation safe region', () {
    final placement = ActionToastPlacement.resolve(
      sourceRect: const Rect.fromLTWH(370, 730, 20, 20),
      kind: ActionToastOriginKind.questCheckbox,
      viewport: const Size(400, 800),
      bottomReserved: 96,
    );

    expect(placement.topLeft.dx, inInclusiveRange(12, 128));
    expect(placement.topLeft.dy, lessThanOrEqualTo(588));
    expect(placement.topLeft.dy, greaterThanOrEqualTo(12));
  });

  test('action toast remains within its desktop source zone', () {
    const viewport = Size(1920, 1080);
    const rightRail = Rect.fromLTWH(1560, 84, 340, 900);
    final placement = ActionToastPlacement.resolve(
      sourceRect: const Rect.fromLTWH(1680, 520, 32, 32),
      kind: ActionToastOriginKind.focusTask,
      viewport: viewport,
      safeRegion: rightRail,
    );

    expect(placement.topLeft.dx, greaterThanOrEqualTo(rightRail.left + 12));
    expect(
      placement.topLeft.dx + placement.maxWidth,
      lessThanOrEqualTo(rightRail.right - 12),
    );
    expect(placement.topLeft.dy, greaterThanOrEqualTo(rightRail.top + 12));
  });

  test('action toast narrows instead of leaving a compact rail', () {
    const viewport = Size(1024, 768);
    const compactRail = Rect.fromLTWH(780, 84, 232, 620);
    final placement = ActionToastPlacement.resolve(
      sourceRect: const Rect.fromLTWH(836, 360, 32, 32),
      kind: ActionToastOriginKind.focusTask,
      viewport: viewport,
      safeRegion: compactRail,
    );

    expect(placement.maxWidth, lessThan(ActionToastPlacement.estimatedWidth));
    expect(placement.topLeft.dx, greaterThanOrEqualTo(compactRail.left + 12));
    expect(
      placement.topLeft.dx + placement.maxWidth,
      lessThanOrEqualTo(compactRail.right - 12),
    );
  });

  test('main-list checkbox placement does not use the row centre', () {
    const viewport = Size(1920, 1080);
    const workspace = Rect.fromLTWH(392, 84, 1246, 900);
    final checkboxPlacement = ActionToastPlacement.resolve(
      sourceRect: const Rect.fromLTWH(440, 572, 34, 34),
      kind: ActionToastOriginKind.questCheckbox,
      viewport: viewport,
      safeRegion: workspace,
    );
    final rowCentrePlacement = ActionToastPlacement.resolve(
      sourceRect: const Rect.fromLTWH(998, 572, 34, 34),
      kind: ActionToastOriginKind.questCheckbox,
      viewport: viewport,
      safeRegion: workspace,
    );

    expect(
      checkboxPlacement.topLeft.dx,
      lessThan(rowCentrePlacement.topLeft.dx),
    );
  });

  test('action toast tries the opposite horizontal side near a zone edge', () {
    final placement = ActionToastPlacement.resolve(
      sourceRect: const Rect.fromLTWH(1490, 520, 32, 32),
      kind: ActionToastOriginKind.questCheckbox,
      viewport: const Size(1920, 1080),
      safeRegion: const Rect.fromLTWH(392, 84, 1246, 900),
    );

    expect(placement.topLeft.dx, lessThan(1490));
  });

  test('minimum-action toast prefers a position below its source', () {
    final placement = ActionToastPlacement.resolve(
      sourceRect: const Rect.fromLTWH(620, 120, 32, 32),
      kind: ActionToastOriginKind.minimumAction,
      viewport: const Size(1920, 1080),
      safeRegion: const Rect.fromLTWH(392, 84, 1246, 900),
    );

    expect(placement.topLeft.dy, greaterThan(120));
  });

  test('action toast does not cover the source control', () {
    const sourceRect = Rect.fromLTWH(450, 540, 34, 34);
    final placement = ActionToastPlacement.resolve(
      sourceRect: sourceRect,
      kind: ActionToastOriginKind.questCheckbox,
      viewport: const Size(1920, 1080),
      safeRegion: const Rect.fromLTWH(392, 84, 1246, 900),
    );
    final toastRect =
        placement.topLeft &
        Size(placement.maxWidth, ActionToastPlacement.estimatedHeight);

    expect(toastRect.overlaps(sourceRect), isFalse);
  });

  test('action-toast jitter is deterministic and bounded for tiny zones', () {
    const region = Rect.fromLTWH(40, 40, 48, 48);
    final first = ActionToastPlacement.stableJitter(17, region);
    final second = ActionToastPlacement.stableJitter(17, region);

    expect(first, second);
    expect(first.dx.abs(), lessThanOrEqualTo(4));
    expect(first.dy.abs(), lessThanOrEqualTo(2.7));
  });

  testWidgets('XP bubble keeps its action placement while visible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              XPBubble(
                message: '+10 XP · быстрое действие',
                placement: ActionToastPlacement.resolve(
                  sourceRect: const Rect.fromLTWH(180, 180, 24, 24),
                  kind: ActionToastOriginKind.questCheckbox,
                  viewport: const Size(400, 400),
                ),
                reducedMotion: false,
                onDone: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    final before = tester.getTopLeft(
      find.byKey(const ValueKey('xp-bubble-surface')),
    );
    await tester.pump(const Duration(milliseconds: 700));
    final after = tester.getTopLeft(
      find.byKey(const ValueKey('xp-bubble-surface')),
    );

    expect(after.dx, closeTo(before.dx, 0.1));
    expect(after.dy, closeTo(before.dy, 0.1));
  });

  testWidgets('XP bar starts at the persisted value and animates updates', (
    WidgetTester tester,
  ) async {
    Future<void> pumpBar({required double progress, required int level}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: XPBar(
              key: const ValueKey('animated-xp-bar'),
              progress: progress,
              level: level,
              color: const Color(0xFF4A9EFF),
            ),
          ),
        ),
      );
    }

    await pumpBar(progress: 0.24, level: 1);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.24, 0.001),
    );

    await pumpBar(progress: 0.56, level: 1);
    await tester.pump();
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.24, 0.001),
    );
    await tester.pump(kMotionXp);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.56, 0.001),
    );

    await pumpBar(progress: 0.18, level: 2);
    await tester.pump(const Duration(milliseconds: 360));
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      greaterThan(0.90),
    );
    await tester.pump(kMotionXp);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.18, 0.001),
    );
  });

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
