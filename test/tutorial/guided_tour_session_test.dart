import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models/tutorial_progress.dart';
import 'package:todo_list_app/tutorial/guided_tour_plan.dart';
import 'package:todo_list_app/tutorial/guided_tour_session.dart';

void main() {
  group('GuidedTourPlan', () {
    test('first-run Core stays Skill, Quest, Next Action', () {
      final plan = GuidedTourPlan.firstRunCore();

      expect(plan.mode, GuidedTourMode.firstRunCore);
      expect(plan.steps.map((step) => step.id), const [
        TutorialStepIds.coreCreateSkill,
        TutorialStepIds.coreCreateQuest,
        TutorialStepIds.coreCompleteQuest,
      ]);
      expect(plan.steps.last.title, 'Следующее действие');
    });

    test('full replay resolves optional steps before session starts', () {
      final shortPlan = GuidedTourPlan.fullProductTour(
        hasMinimumAction: false,
        hasRoadmapPractice: false,
      );
      final populatedPlan = GuidedTourPlan.fullProductTour(
        hasMinimumAction: true,
        hasRoadmapPractice: true,
      );

      expect(
        shortPlan.steps.any((step) => step.id == 'tour.act.minimum'),
        isFalse,
      );
      expect(
        shortPlan.steps.any((step) => step.id == 'tour.roadmap.optional'),
        isTrue,
      );
      expect(
        populatedPlan.steps.any((step) => step.id == 'tour.act.minimum'),
        isTrue,
      );
      expect(
        populatedPlan.steps.any((step) => step.id == 'tour.roadmap.practice'),
        isTrue,
      );
      expect(populatedPlan.steps.length, shortPlan.steps.length + 1);
      expect(
        populatedPlan.steps
            .where((step) => step.id.startsWith('tour.nav.'))
            .map((step) => step.destination),
        everyElement(GuidedTourDestination.act),
      );
    });

    test('module replay order is independent of historical completion', () {
      const historicallyCompleted = {
        TutorialModuleIds.core,
        TutorialModuleIds.roadmap,
        TutorialModuleIds.stats,
      };
      final plan = GuidedTourPlan.moduleReplay(
        TutorialModuleIds.roadmap,
        hasMinimumAction: false,
        hasRoadmapPractice: true,
      );

      expect(historicallyCompleted, contains(TutorialModuleIds.roadmap));
      expect(plan.steps.first.id, 'tour.nav.roadmap');
      expect(plan.steps.last.id, 'tour.roadmap.practice');
    });

    test('existing-user Basics replay never asks for duplicate creation', () {
      final plan = GuidedTourPlan.moduleReplay(
        TutorialModuleIds.core,
        hasMinimumAction: false,
        hasRoadmapPractice: false,
      );

      expect(plan.steps, hasLength(1));
      expect(plan.steps.single.id, 'tour.basics.recap');
      expect(
        plan.steps.any(
          (step) =>
              step.id == TutorialStepIds.coreCreateSkill ||
              step.id == TutorialStepIds.coreCreateQuest,
        ),
        isFalse,
      );
    });
  });

  group('GuidedTourSession', () {
    test('runs deterministic transition phases and completion', () {
      final session = GuidedTourSession(
        GuidedTourPlan.moduleReplay(
          TutorialModuleIds.stats,
          hasMinimumAction: false,
          hasRoadmapPractice: false,
        ),
      );

      expect(session.phase, GuidedTourPhase.entering);
      session.present();
      expect(session.phase, GuidedTourPhase.presenting);
      session.beginLeaving();
      expect(session.phase, GuidedTourPhase.leaving);
      session.beginNavigation();
      expect(session.phase, GuidedTourPhase.navigating);
      session.waitForAnchor();
      expect(session.phase, GuidedTourPhase.waitingForAnchor);
      expect(session.advance(), isTrue);
      expect(session.phase, GuidedTourPhase.entering);
      session.present();
      expect(session.advance(), isTrue);
      expect(session.isComplete, isTrue);
    });

    test('supports previous, pause, resume, and restart', () {
      final session = GuidedTourSession(
        GuidedTourPlan.fullProductTour(
          hasMinimumAction: true,
          hasRoadmapPractice: true,
        ),
      );

      session.advance();
      expect(session.canGoPrevious, isTrue);
      expect(session.previous(), isTrue);
      session.pause();
      expect(session.isPaused, isTrue);
      expect(session.advance(), isFalse);
      session.resume();
      expect(session.phase, GuidedTourPhase.entering);
      session.advance();
      session.restart();
      expect(session.currentIndex, 0);
      expect(session.phase, GuidedTourPhase.entering);
    });

    test('can resume first-run Core at persisted compatible step', () {
      final session = GuidedTourSession(
        GuidedTourPlan.firstRunCore(),
        initialStepId: TutorialStepIds.coreCreateQuest,
      );

      expect(session.currentIndex, 1);
      expect(session.currentStep?.id, TutorialStepIds.coreCreateQuest);
    });

    test('unknown legacy step safely starts at first step', () {
      final session = GuidedTourSession(
        GuidedTourPlan.firstRunCore(),
        initialStepId: 'removed.v3.step',
      );

      expect(session.currentIndex, 0);
      expect(session.currentStep?.id, TutorialStepIds.coreCreateSkill);
    });
  });
}
