import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/widgets/goal_milestone_banner.dart';

void main() {
  GoalMilestoneEvent eventFor(GoalMilestone milestone) {
    return GoalMilestoneEvent(
      id: 'event-${milestone.percent}',
      skillId: 'skill-1',
      skillName: 'Flutter',
      skillColor: Colors.orange,
      milestone: milestone,
    );
  }

  Future<void> pumpBanner(
    WidgetTester tester,
    GoalMilestone milestone, {
    VoidCallback? onDismiss,
    VoidCallback? onOpenRoadmap,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              GoalMilestoneBanner(
                event: eventFor(milestone),
                isDark: false,
                onDismiss: onDismiss ?? () {},
                onOpenRoadmap: onOpenRoadmap,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 220));
  }

  testWidgets('25 percent banner uses subtle milestone copy', (tester) async {
    await pumpBanner(tester, GoalMilestone.quarter);

    expect(find.text('25% цели'), findsOneWidget);
    expect(find.textContaining('Первые шаги сделаны'), findsOneWidget);
    expect(find.text('К RoadMap'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('50 percent banner uses halfway copy', (tester) async {
    await pumpBanner(tester, GoalMilestone.half);

    expect(find.text('50% цели'), findsOneWidget);
    expect(find.textContaining('Половина пути'), findsOneWidget);
    expect(find.text('К RoadMap'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('100 percent banner exposes RoadMap CTA', (tester) async {
    var opened = false;
    await pumpBanner(
      tester,
      GoalMilestone.complete,
      onOpenRoadmap: () => opened = true,
    );

    expect(find.text('Цель достигнута'), findsOneWidget);
    expect(find.textContaining('100% выполнено'), findsOneWidget);
    expect(find.text('К RoadMap'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('К RoadMap'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(opened, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('banner dismisses from close button', (tester) async {
    var dismissed = false;
    await pumpBanner(
      tester,
      GoalMilestone.quarter,
      onDismiss: () => dismissed = true,
    );

    await tester.tap(find.byTooltip('Скрыть'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(dismissed, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
