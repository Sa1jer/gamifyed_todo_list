import '../models/tutorial_progress.dart';

enum GuidedTourMode { firstRunCore, fullProductTour, moduleReplay }

enum GuidedTourDestination { act, roadmap, statistics, trophies, profile }

enum GuidedTourPresentation { spotlight, coachCard, inlineGuidance }

enum TutorialMissingTargetPolicy {
  skip,
  useParentAnchor,
  coachCard,
  endChapterSafely,
}

enum TutorialAnchorId {
  skillCreate,
  questCreate,
  actNextAction,
  actMinimumAction,
  actInbox,
  navRoadmap,
  roadmapCanvas,
  roadmapPractice,
  navStatistics,
  statisticsSummary,
  navTrophies,
  trophiesSummary,
  profileEntry,
  profileTraining,
}

class GuidedTourStep {
  const GuidedTourStep({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.presentation,
    this.anchorId,
    this.parentAnchorId,
    this.destination,
    this.navigateTo,
    this.missingTargetPolicy = TutorialMissingTargetPolicy.coachCard,
  });

  final String id;
  final String chapterId;
  final String title;
  final String body;
  final String primaryLabel;
  final GuidedTourPresentation presentation;
  final TutorialAnchorId? anchorId;
  final TutorialAnchorId? parentAnchorId;
  final GuidedTourDestination? destination;
  final GuidedTourDestination? navigateTo;
  final TutorialMissingTargetPolicy missingTargetPolicy;
}

class GuidedTourPlan {
  const GuidedTourPlan({
    required this.id,
    required this.mode,
    required this.steps,
    required this.initialDestination,
    this.moduleId,
  });

  final String id;
  final GuidedTourMode mode;
  final List<GuidedTourStep> steps;
  final GuidedTourDestination initialDestination;
  final String? moduleId;

  static GuidedTourPlan firstRunCore() => const GuidedTourPlan(
    id: 'first-run-core-v4',
    mode: GuidedTourMode.firstRunCore,
    initialDestination: GuidedTourDestination.act,
    moduleId: TutorialModuleIds.core,
    steps: [
      GuidedTourStep(
        id: TutorialStepIds.coreCreateSkill,
        chapterId: TutorialModuleIds.core,
        title: 'Первый навык',
        body:
            'Навык — направление роста. Для начала достаточно названия и цели.',
        primaryLabel: 'Создать навык',
        presentation: GuidedTourPresentation.spotlight,
        anchorId: TutorialAnchorId.skillCreate,
        destination: GuidedTourDestination.act,
        missingTargetPolicy: TutorialMissingTargetPolicy.endChapterSafely,
      ),
      GuidedTourStep(
        id: TutorialStepIds.coreCreateQuest,
        chapterId: TutorialModuleIds.core,
        title: 'Первый квест',
        body: 'Квест — конкретное действие внутри выбранного навыка.',
        primaryLabel: 'Создать квест',
        presentation: GuidedTourPresentation.spotlight,
        anchorId: TutorialAnchorId.questCreate,
        destination: GuidedTourDestination.act,
        missingTargetPolicy: TutorialMissingTargetPolicy.endChapterSafely,
      ),
      GuidedTourStep(
        id: TutorialStepIds.coreCompleteQuest,
        chapterId: TutorialModuleIds.core,
        title: 'Следующее действие',
        body:
            'Вот что можно сделать следующим. Завершать квест сейчас не нужно.',
        primaryLabel: 'Понятно',
        presentation: GuidedTourPresentation.spotlight,
        anchorId: TutorialAnchorId.actNextAction,
        destination: GuidedTourDestination.act,
        missingTargetPolicy: TutorialMissingTargetPolicy.useParentAnchor,
      ),
    ],
  );

  static GuidedTourPlan fullProductTour({
    required bool hasMinimumAction,
    required bool hasRoadmapPractice,
  }) {
    final steps = <GuidedTourStep>[
      ..._actSteps(hasMinimumAction: hasMinimumAction),
      ..._roadmapSteps(hasRoadmapPractice: hasRoadmapPractice),
      ..._growthSteps,
      ..._trophiesSteps,
      ..._profileSteps,
    ];
    return GuidedTourPlan(
      id: 'full-product-tour-v4',
      mode: GuidedTourMode.fullProductTour,
      initialDestination: GuidedTourDestination.act,
      steps: List.unmodifiable(steps),
    );
  }

  static GuidedTourPlan moduleReplay(
    String moduleId, {
    required bool hasMinimumAction,
    required bool hasRoadmapPractice,
  }) {
    final (destination, steps) = switch (moduleId) {
      TutorialModuleIds.core => (
        GuidedTourDestination.act,
        const [
          GuidedTourStep(
            id: 'tour.basics.recap',
            chapterId: TutorialModuleIds.core,
            title: 'Первый путь',
            body:
                'Навык задаёт направление, квест превращает его в действие, а этот экран показывает следующий шаг.',
            primaryLabel: 'Готово',
            presentation: GuidedTourPresentation.spotlight,
            anchorId: TutorialAnchorId.actNextAction,
            destination: GuidedTourDestination.act,
            missingTargetPolicy: TutorialMissingTargetPolicy.coachCard,
          ),
        ],
      ),
      TutorialModuleIds.act => (
        GuidedTourDestination.act,
        _actSteps(hasMinimumAction: hasMinimumAction),
      ),
      TutorialModuleIds.roadmap => (
        GuidedTourDestination.act,
        _roadmapSteps(hasRoadmapPractice: hasRoadmapPractice),
      ),
      TutorialModuleIds.stats => (GuidedTourDestination.act, _growthSteps),
      TutorialModuleIds.trophies => (GuidedTourDestination.act, _trophiesSteps),
      TutorialModuleIds.profile => (GuidedTourDestination.act, _profileSteps),
      _ => (
        GuidedTourDestination.act,
        const <GuidedTourStep>[
          GuidedTourStep(
            id: 'tour.unknown.safeEnd',
            chapterId: TutorialModuleIds.core,
            title: 'Обучение',
            body: 'Эта тема больше недоступна. Можно выбрать другую в профиле.',
            primaryLabel: 'Закрыть',
            presentation: GuidedTourPresentation.coachCard,
            missingTargetPolicy: TutorialMissingTargetPolicy.endChapterSafely,
          ),
        ],
      ),
    };
    return GuidedTourPlan(
      id: 'module-replay-v4-$moduleId',
      mode: GuidedTourMode.moduleReplay,
      initialDestination: destination,
      moduleId: moduleId,
      steps: List.unmodifiable(steps),
    );
  }

  static List<GuidedTourStep> _actSteps({required bool hasMinimumAction}) => [
    if (hasMinimumAction)
      const GuidedTourStep(
        id: 'tour.act.minimum',
        chapterId: TutorialModuleIds.act,
        title: 'Минимальный шаг',
        body:
            'Если начать трудно, минимальный шаг предлагает меньший вход в тот же квест.',
        primaryLabel: 'Дальше',
        presentation: GuidedTourPresentation.spotlight,
        anchorId: TutorialAnchorId.actMinimumAction,
        destination: GuidedTourDestination.act,
        missingTargetPolicy: TutorialMissingTargetPolicy.skip,
      ),
    const GuidedTourStep(
      id: 'tour.act.inbox',
      chapterId: TutorialModuleIds.act,
      title: 'Задачник',
      body: 'Сюда можно быстро записать дело, не превращая его в большой путь.',
      primaryLabel: 'Дальше',
      presentation: GuidedTourPresentation.spotlight,
      anchorId: TutorialAnchorId.actInbox,
      destination: GuidedTourDestination.act,
      missingTargetPolicy: TutorialMissingTargetPolicy.useParentAnchor,
      parentAnchorId: TutorialAnchorId.actNextAction,
    ),
    const GuidedTourStep(
      id: 'tour.act.context',
      chapterId: TutorialModuleIds.act,
      title: 'Вернуться без перегруза',
      body:
          'После паузы приложение кратко напомнит контекст. Импульс отражает только реальные завершённые действия.',
      primaryLabel: 'К карте',
      presentation: GuidedTourPresentation.coachCard,
      anchorId: TutorialAnchorId.actNextAction,
      destination: GuidedTourDestination.act,
      missingTargetPolicy: TutorialMissingTargetPolicy.coachCard,
    ),
  ];

  static List<GuidedTourStep> _roadmapSteps({
    required bool hasRoadmapPractice,
  }) => [
    const GuidedTourStep(
      id: 'tour.nav.roadmap',
      chapterId: TutorialModuleIds.roadmap,
      title: 'Дорожная карта',
      body:
          'Карта помогает разложить навык на этапы. Использовать её необязательно.',
      primaryLabel: 'Открыть карту',
      presentation: GuidedTourPresentation.spotlight,
      anchorId: TutorialAnchorId.navRoadmap,
      destination: GuidedTourDestination.act,
      navigateTo: GuidedTourDestination.roadmap,
      missingTargetPolicy: TutorialMissingTargetPolicy.endChapterSafely,
    ),
    const GuidedTourStep(
      id: 'tour.roadmap.canvas',
      chapterId: TutorialModuleIds.roadmap,
      title: 'Путь навыка',
      body:
          'Этапы показывают порядок движения, а связи сохраняют общую картину.',
      primaryLabel: 'Дальше',
      presentation: GuidedTourPresentation.spotlight,
      anchorId: TutorialAnchorId.roadmapCanvas,
      destination: GuidedTourDestination.roadmap,
      missingTargetPolicy: TutorialMissingTargetPolicy.coachCard,
    ),
    if (hasRoadmapPractice)
      const GuidedTourStep(
        id: 'tour.roadmap.practice',
        chapterId: TutorialModuleIds.roadmap,
        title: 'Практика этапа',
        body: 'Квесты внутри этапа превращают план в реальную практику.',
        primaryLabel: 'К росту',
        presentation: GuidedTourPresentation.spotlight,
        anchorId: TutorialAnchorId.roadmapPractice,
        destination: GuidedTourDestination.roadmap,
        missingTargetPolicy: TutorialMissingTargetPolicy.coachCard,
      )
    else
      const GuidedTourStep(
        id: 'tour.roadmap.optional',
        chapterId: TutorialModuleIds.roadmap,
        title: 'Карту можно собрать позже',
        body: 'Начать работать с навыком можно и без RoadMap.',
        primaryLabel: 'К росту',
        presentation: GuidedTourPresentation.coachCard,
        anchorId: TutorialAnchorId.roadmapCanvas,
        destination: GuidedTourDestination.roadmap,
        missingTargetPolicy: TutorialMissingTargetPolicy.coachCard,
      ),
  ];

  static const _growthSteps = <GuidedTourStep>[
    GuidedTourStep(
      id: 'tour.nav.statistics',
      chapterId: TutorialModuleIds.stats,
      title: 'История роста',
      body: 'Здесь собраны результаты дня, недели и развитие навыков.',
      primaryLabel: 'Открыть рост',
      presentation: GuidedTourPresentation.spotlight,
      anchorId: TutorialAnchorId.navStatistics,
      navigateTo: GuidedTourDestination.statistics,
      missingTargetPolicy: TutorialMissingTargetPolicy.endChapterSafely,
    ),
    GuidedTourStep(
      id: 'tour.statistics.summary',
      chapterId: TutorialModuleIds.stats,
      title: 'Смотри на общую картину',
      body: 'Не нужно следить за каждым графиком. Одного обзора достаточно.',
      primaryLabel: 'К трофеям',
      presentation: GuidedTourPresentation.spotlight,
      anchorId: TutorialAnchorId.statisticsSummary,
      destination: GuidedTourDestination.statistics,
      missingTargetPolicy: TutorialMissingTargetPolicy.coachCard,
    ),
  ];

  static const _trophiesSteps = <GuidedTourStep>[
    GuidedTourStep(
      id: 'tour.nav.trophies',
      chapterId: TutorialModuleIds.trophies,
      title: 'Трофеи',
      body: 'Трофеи дают обратную связь после заметных действий.',
      primaryLabel: 'Открыть трофеи',
      presentation: GuidedTourPresentation.spotlight,
      anchorId: TutorialAnchorId.navTrophies,
      navigateTo: GuidedTourDestination.trophies,
      missingTargetPolicy: TutorialMissingTargetPolicy.endChapterSafely,
    ),
    GuidedTourStep(
      id: 'tour.trophies.summary',
      chapterId: TutorialModuleIds.trophies,
      title: 'Обратная связь после действий',
      body:
          'Эффекты и сундуки появляются из реального прогресса. Это не новый список дел.',
      primaryLabel: 'К профилю',
      presentation: GuidedTourPresentation.spotlight,
      anchorId: TutorialAnchorId.trophiesSummary,
      destination: GuidedTourDestination.trophies,
      missingTargetPolicy: TutorialMissingTargetPolicy.coachCard,
    ),
  ];

  static const _profileSteps = <GuidedTourStep>[
    GuidedTourStep(
      id: 'tour.nav.profile',
      chapterId: TutorialModuleIds.profile,
      title: 'Профиль',
      body: 'В профиле находятся личные настройки и повтор обучения.',
      primaryLabel: 'Открыть профиль',
      presentation: GuidedTourPresentation.spotlight,
      anchorId: TutorialAnchorId.profileEntry,
      navigateTo: GuidedTourDestination.profile,
      missingTargetPolicy: TutorialMissingTargetPolicy.endChapterSafely,
    ),
    GuidedTourStep(
      id: 'tour.profile.training',
      chapterId: TutorialModuleIds.profile,
      title: 'Готово',
      body:
          'Здесь можно изменить тему, звук и движение. Обучение всегда можно запустить снова.',
      primaryLabel: 'Завершить',
      presentation: GuidedTourPresentation.inlineGuidance,
      anchorId: TutorialAnchorId.profileTraining,
      destination: GuidedTourDestination.profile,
      missingTargetPolicy: TutorialMissingTargetPolicy.endChapterSafely,
    ),
  ];
}
