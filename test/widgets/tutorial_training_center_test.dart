import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models/tutorial_progress.dart';
import 'package:todo_list_app/tutorial/guided_tour_plan.dart';
import 'package:todo_list_app/tutorial/guided_tour_session.dart';
import 'package:todo_list_app/widgets/tutorial/tutorial_training_center.dart';

void main() {
  testWidgets(
    'fresh center offers full replay and completed topics remain active',
    (tester) async {
      TutorialTrainingSelection? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialTrainingCenter(
            progress: const TutorialProgress(
              completedModuleIds: {TutorialModuleIds.stats},
            ),
            session: null,
            onSelected: (value) => selected = value,
            onClose: () {},
          ),
        ),
      );

      expect(find.text('~3–5 минут · данные не изменятся'), findsOneWidget);
      expect(find.text('Пройдено · можно повторить'), findsOneWidget);
      final statsTopic = find.byKey(const ValueKey('tutorial-topic-stats'));
      await tester.ensureVisible(statsTopic);
      await tester.pumpAndSettle();
      await tester.tap(statsTopic);
      expect(selected?.action, TutorialTrainingAction.module);
      expect(selected?.moduleId, TutorialModuleIds.stats);
    },
  );

  testWidgets('paused replay offers continue and restart', (tester) async {
    final session = GuidedTourSession(
      GuidedTourPlan.fullProductTour(
        hasMinimumAction: false,
        hasRoadmapPractice: false,
      ),
    )..pause();
    TutorialTrainingSelection? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: TutorialTrainingCenter(
          progress: const TutorialProgress.empty(),
          session: session.snapshot,
          onSelected: (value) => selected = value,
          onClose: () {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('tutorial-continue-full-tour')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('tutorial-restart-full-tour')));
    expect(selected?.action, TutorialTrainingAction.restartTour);
  });

  testWidgets('paused topic replay does not masquerade as the full tour', (
    tester,
  ) async {
    final session = GuidedTourSession(
      GuidedTourPlan.moduleReplay(
        TutorialModuleIds.roadmap,
        hasMinimumAction: false,
        hasRoadmapPractice: false,
      ),
    )..pause();

    await tester.pumpWidget(
      MaterialApp(
        home: TutorialTrainingCenter(
          progress: const TutorialProgress.empty(),
          session: session.snapshot,
          onSelected: (_) {},
          onClose: () {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('tutorial-continue-full-tour')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tutorial-restart-full-tour')),
      findsNothing,
    );
  });
}
