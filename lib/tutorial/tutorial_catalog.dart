import '../models/tutorial_progress.dart';

enum TutorialPresentationMode { spotlight, coachCard, inlineGuidance }

class TutorialModuleDefinition {
  const TutorialModuleDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.stepIds,
    required this.isMandatory,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> stepIds;
  final bool isMandatory;
}

class TutorialStepDefinition {
  const TutorialStepDefinition({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.body,
    required this.primaryLabel,
    this.secondaryLabel = 'Пропустить обучение',
    this.presentationMode = TutorialPresentationMode.spotlight,
  });

  final String id;
  final String moduleId;
  final String title;
  final String body;
  final String primaryLabel;
  final String? secondaryLabel;
  final TutorialPresentationMode presentationMode;
}

/// Static tutorial knowledge. It intentionally owns no navigation, context,
/// widget keys, or persisted state.
class TutorialCatalog {
  const TutorialCatalog._();

  static const legacyCoreStepIds = <String>{
    TutorialStepIds.coreXpFeedback,
    TutorialStepIds.coreOpenRoadmap,
    TutorialStepIds.coreRoadmapDetails,
    TutorialStepIds.coreOpenStats,
  };

  static const modules = <TutorialModuleDefinition>[
    TutorialModuleDefinition(
      id: TutorialModuleIds.core,
      title: 'Первый путь',
      subtitle: 'Навык → квест → первое полезное действие',
      stepIds: [
        TutorialStepIds.coreCreateSkill,
        TutorialStepIds.coreCreateQuest,
        TutorialStepIds.coreCompleteQuest,
      ],
      isMandatory: true,
    ),
    TutorialModuleDefinition(
      id: TutorialModuleIds.act,
      title: 'Действовать',
      subtitle: 'Следующее действие, минимум, Задачник и возвращение',
      stepIds: [TutorialStepIds.actNextQuest, TutorialStepIds.actMinimum],
      isMandatory: false,
    ),
    TutorialModuleDefinition(
      id: TutorialModuleIds.roadmap,
      title: 'Дорожная карта',
      subtitle: 'Путь навыка, этапы, шаблоны и практика',
      stepIds: [TutorialStepIds.roadmapPath, TutorialStepIds.roadmapPractice],
      isMandatory: false,
    ),
    TutorialModuleDefinition(
      id: TutorialModuleIds.stats,
      title: 'Рост',
      subtitle: 'Победы дня, неделя и летопись роста',
      stepIds: [TutorialStepIds.statsGrowth],
      isMandatory: false,
    ),
    TutorialModuleDefinition(
      id: TutorialModuleIds.trophies,
      title: 'Трофеи',
      subtitle: 'Обратная связь после реальных действий',
      stepIds: [TutorialStepIds.trophiesFeedback],
      isMandatory: false,
    ),
    TutorialModuleDefinition(
      id: TutorialModuleIds.profile,
      title: 'Профиль',
      subtitle: 'Тема, звук, движение и повтор обучения',
      stepIds: [TutorialStepIds.profileReplay],
      isMandatory: false,
    ),
  ];

  static const steps = <TutorialStepDefinition>[
    TutorialStepDefinition(
      id: TutorialStepIds.coreCreateSkill,
      moduleId: TutorialModuleIds.core,
      title: 'Первый навык',
      body:
          'Навык — направление, в котором ты хочешь двигаться. Для начала достаточно названия и цели.',
      primaryLabel: 'Создать навык',
    ),
    TutorialStepDefinition(
      id: TutorialStepIds.coreCreateQuest,
      moduleId: TutorialModuleIds.core,
      title: 'Первый квест',
      body:
          'Квест — конкретное действие внутри навыка. Выбери небольшой реальный шаг.',
      primaryLabel: 'Создать квест',
    ),
    TutorialStepDefinition(
      id: TutorialStepIds.coreCompleteQuest,
      moduleId: TutorialModuleIds.core,
      title: 'Первое полезное действие',
      body:
          'Здесь видно, что сделать следующим. Квест можно завершить целиком или начать с минимального шага — сейчас выполнять его не обязательно.',
      primaryLabel: 'Понятно',
      secondaryLabel: 'Пропустить обучение',
    ),
    TutorialStepDefinition(
      id: TutorialStepIds.actNextQuest,
      moduleId: TutorialModuleIds.act,
      title: 'Действовать',
      body:
          'Экран помогает выбрать следующее действие. Задачник хранит быстрые дела, а контекст возвращения и импульс появляются только из реальной истории.',
      primaryLabel: 'Понятно',
    ),
    TutorialStepDefinition(
      id: TutorialStepIds.actMinimum,
      moduleId: TutorialModuleIds.act,
      title: 'Минимальный шаг',
      body:
          'Минимальный шаг помогает начать с меньшего действия и не меняет сам квест.',
      primaryLabel: 'Завершить тему',
      presentationMode: TutorialPresentationMode.coachCard,
    ),
    TutorialStepDefinition(
      id: TutorialStepIds.roadmapPath,
      moduleId: TutorialModuleIds.roadmap,
      title: 'Дорожная карта',
      body:
          'Навык становится путём из этапов. Связи показывают порядок, а шаблоны помогают быстро выбрать структуру.',
      primaryLabel: 'Открыть карту',
    ),
    TutorialStepDefinition(
      id: TutorialStepIds.roadmapPractice,
      moduleId: TutorialModuleIds.roadmap,
      title: 'Практика этапа',
      body:
          'Квесты подтверждают практику этапа. Если этапов пока нет, к ним можно вернуться позже.',
      primaryLabel: 'Завершить тему',
    ),
    TutorialStepDefinition(
      id: TutorialStepIds.statsGrowth,
      moduleId: TutorialModuleIds.stats,
      title: 'История роста',
      body:
          'Здесь можно посмотреть на реальные победы дня, неделю и летопись, не изучая каждый график.',
      primaryLabel: 'Открыть рост',
    ),
    TutorialStepDefinition(
      id: TutorialStepIds.trophiesFeedback,
      moduleId: TutorialModuleIds.trophies,
      title: 'Трофеи после действий',
      body:
          'Трофеи, сундуки и эффекты — это обратная связь после реальных действий. Их не нужно обслуживать каждый день.',
      primaryLabel: 'Открыть трофеи',
    ),
    TutorialStepDefinition(
      id: TutorialStepIds.profileReplay,
      moduleId: TutorialModuleIds.profile,
      title: 'Профиль и обучение',
      body:
          'В профиле доступны тема, звук, уменьшение движения и повтор любого раздела обучения.',
      primaryLabel: 'Открыть профиль',
      presentationMode: TutorialPresentationMode.inlineGuidance,
    ),
  ];

  static TutorialModuleDefinition? module(String id) {
    for (final module in modules) {
      if (module.id == id) return module;
    }
    return null;
  }

  static TutorialStepDefinition? step(String id) {
    for (final step in steps) {
      if (step.id == id) return step;
    }
    return null;
  }

  static List<String> stepIdsForModule(String id) =>
      module(id)?.stepIds ?? const [];
}
