import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models.dart';
import 'utils.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'sfx_service.dart';
import 'engines/boss_engine.dart';
import 'engines/roadmap_engine.dart';

part 'app_state/provider.dart';

class AppState extends ChangeNotifier {
  static const double _minimumActionRatio = 0.3;
  static const Duration _resetCheckInterval = Duration(minutes: 15);
  static const Duration _saveDebounceDuration = Duration(milliseconds: 750);
  static const int _maxStreakProtectionCharges = 1;
  static const int _maxHistoryEntries = 2000;
  static const int _maxBuffBonusPercent = 50;
  static const Duration _buffLifetime = Duration(hours: 24);

  bool _isDark = true;
  bool _sfxEnabled = true;
  bool _tooltipsEnabled = true;
  bool _onboardingSeen = false;
  bool _onboardingReplayRequested = false;
  TutorialProgress _tutorialProgress = const TutorialProgress.empty();
  bool _hasLoadedSavedData = false;
  String? selectedSkillId;
  final StorageService _storage;
  final NotificationService _notifications;
  final math.Random _random;
  final BossEngine _bossEngine = const BossEngine();
  Timer? _resetTimer;
  Timer? _saveDebounceTimer;
  Future<void>? _saveInFlight;
  bool _saveAgainAfterInFlight = false;

  bool get isDark => _isDark;
  bool get sfxEnabled => _sfxEnabled;
  bool get tooltipsEnabled => _tooltipsEnabled;
  bool get onboardingSeen => _onboardingSeen;
  TutorialProgress get tutorialProgress => _tutorialProgress;
  String? get activeTutorialModuleId => _effectiveTutorialModuleId;
  String? get activeTutorialStepId => _effectiveTutorialStepId;
  bool get hasLoadedSavedData => _hasLoadedSavedData;
  bool get shouldShowFirstRunTutorial =>
      _hasLoadedSavedData &&
      (_effectiveTutorialModuleId != null || _shouldAutoShowCoreTutorial);

  bool get _coreTutorialCompleted =>
      _tutorialProgress.isModuleCompleted(TutorialModuleIds.core);

  bool get _shouldAutoShowCoreTutorial =>
      !_coreTutorialCompleted && !_onboardingSeen && tasks.isEmpty;

  String? get _effectiveTutorialModuleId {
    if (_tutorialProgress.activeModuleId != null) {
      return _tutorialProgress.activeModuleId;
    }
    if (_onboardingReplayRequested || _shouldAutoShowCoreTutorial) {
      return TutorialModuleIds.core;
    }
    return null;
  }

  String? get _effectiveTutorialStepId {
    final activeStep = _tutorialProgress.activeStepId;
    final module = _effectiveTutorialModuleId;
    if (module == null) return null;
    final step = activeStep ?? _defaultTutorialStepForModule(module);
    if (module == TutorialModuleIds.core) {
      return _normalizedCoreTutorialStep(step);
    }
    return step;
  }

  UserProfile profile = UserProfile(name: 'Your Name');
  final List<HistoryEntry> history = [];
  final List<Skill> skills = [];
  final List<Task> tasks = [];
  final List<Achievement> achievements = [];
  final List<Boss> bosses = [];
  final List<RewardChest> rewardChests = [];
  final List<Buff> buffs = [];
  final List<WeeklyGoal> weeklyGoals = [];
  final List<RewardChest> _pendingRewardNotifications = [];
  final List<Buff> _pendingBuffNotifications = [];
  final List<Achievement> _pendingAchievementNotifications = [];
  final Set<String> _dismissedCourseNudgeKeys = {};
  DailyStats? todayStats;

  int _bestStreak = 0;
  Map<DateTime, List<HistoryEntry>>? _completionHistoryByDateCache;
  int? _totalTasksCompletedCache;
  int? _historyCacheFingerprint;

  AppState({
    required StorageService storage,
    NotificationService? notifications,
    math.Random? random,
    bool seedDefaults = false,
  }) : _storage = storage,
       _notifications = notifications ?? NotificationService(),
       _random = random ?? math.Random() {
    if (seedDefaults) {
      _initDefaults();
    }
    _startResetTimer();
  }

  @override
  void dispose() {
    pauseBackgroundWork();
    super.dispose();
  }

  void pauseBackgroundWork() {
    _resetTimer?.cancel();
    _resetTimer = null;
    unawaited(flushSaves());
  }

  void resumeBackgroundWork() {
    _notifications.invalidatePermissionCache();
    _startResetTimer();
    checkResets();
  }

  void _startResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = Timer.periodic(_resetCheckInterval, (_) => checkResets());
  }

  void _initDefaults() {
    final pullTechnique = uid();
    final pullVolume = uid();
    final pythonSyntax = uid();
    final pythonApi = uid();
    final gamificationLoop = uid();
    final gamificationRewards = uid();

    skills.addAll([
      Skill(
        id: uid(),
        name: 'Подтягивания',
        goal: 'Подтягиваться 20 раз',
        color: const Color(0xFFFF9500),
        icon: Icons.fitness_center,
        xp: 60,
        checklist: ['3 подхода по 5 раз', 'Без рывков', 'Полная амплитуда'],
        treeNodes: [
          SkillTreeNode(
            id: pullTechnique,
            title: 'Чистая техника',
            description: 'Закрепить амплитуду и контроль движения.',
            xpReward: 25,
            requiredQuestCompletions: 1,
            checklist: ['Полная амплитуда', 'Без рывков'],
          ),
          SkillTreeNode(
            id: pullVolume,
            title: 'Рабочий объём',
            description: 'Собрать базу для выхода на 20 повторений.',
            xpReward: 40,
            requiredQuestCompletions: 1,
            prerequisiteIds: [pullTechnique],
            checklist: ['3 подхода', 'Отдых не больше 2 минут'],
          ),
        ],
      ),
      Skill(
        id: uid(),
        name: 'Python',
        goal: 'Освоить backend на FastAPI',
        color: const Color(0xFF5856D6),
        icon: Icons.code,
        xp: 30,
        level: 2,
        checklist: ['Изучить async/await', 'Написать CRUD', 'Деплой на сервер'],
        treeNodes: [
          SkillTreeNode(
            id: pythonSyntax,
            title: 'Основы backend',
            description: 'Синтаксис, функции и работа с проектом.',
            xpReward: 30,
            requiredQuestCompletions: 1,
            checklist: ['Функции', 'Модули', 'Виртуальное окружение'],
          ),
          SkillTreeNode(
            id: pythonApi,
            title: 'FastAPI CRUD',
            description: 'Первый рабочий API с роутами и моделями.',
            xpReward: 60,
            requiredQuestCompletions: 1,
            prerequisiteIds: [pythonSyntax],
            checklist: [
              'Создать endpoint',
              'Подключить модели',
              'Проверить CRUD',
            ],
          ),
        ],
      ),
      Skill(
        id: uid(),
        name: 'Геймификация жизни',
        goal: 'Запустить RPGreal.org',
        color: const Color(0xFF34C759),
        icon: Icons.sports_esports,
        xp: 80,
        treeNodes: [
          SkillTreeNode(
            id: gamificationLoop,
            title: 'Core loop',
            description: 'Навык, квест, XP, обратная связь.',
            xpReward: 35,
            requiredQuestCompletions: 1,
            checklist: ['Квесты', 'XP', 'Профиль'],
          ),
          SkillTreeNode(
            id: gamificationRewards,
            title: 'Трофеи и эффекты',
            description:
                'Сундуки, пассивные эффекты и приятное усиление прогресса.',
            xpReward: 55,
            requiredQuestCompletions: 1,
            prerequisiteIds: [gamificationLoop],
            checklist: ['Сундуки', 'Эффекты', 'Уведомления'],
          ),
        ],
      ),
    ]);

    tasks.addAll([
      Task(
        id: uid(),
        title: 'Сделать 3 подхода подтягиваний',
        skillId: skills[0].id,
        xpReward: 25,
        type: TaskType.repeating,
        streak: 3,
        repeatFrequency: RepeatFrequency.daily,
        treeNodeId: pullTechnique,
      ),
      Task(
        id: uid(),
        title: 'Выйти на 15 подтягиваний за сет',
        skillId: skills[0].id,
        xpReward: 100,
        type: TaskType.longTerm,
        treeNodeId: pullVolume,
      ),
      Task(
        id: uid(),
        title: 'Пройти урок: функции и замыкания',
        skillId: skills[1].id,
        xpReward: 20,
        type: TaskType.shortTerm,
        treeNodeId: pythonSyntax,
      ),
      Task(
        id: uid(),
        title: 'Написать REST API на FastAPI',
        skillId: skills[1].id,
        xpReward: 60,
        type: TaskType.midTerm,
        minimumAction: 'Создать первый endpoint и проверить ответ 200 OK',
        treeNodeId: pythonApi,
      ),
      Task(
        id: uid(),
        title: 'Написать концепцию монетизации',
        skillId: skills[2].id,
        xpReward: 50,
        type: TaskType.midTerm,
        treeNodeId: gamificationLoop,
      ),
    ]);

    for (final s in skills) {
      s.syncChecklistDone();
      s.syncTreeNodes();
    }
    for (final t in tasks) {
      t.syncSubtaskDone();
    }

    _initAchievements();
    _recalculateBestStreakFromTasks();
  }

  void _initAchievements() {
    achievements.clear();
    for (final def in achievementDefinitions) {
      achievements.add(Achievement(id: def.id)..def = def);
    }
  }

  Future<void> loadSavedData() async {
    final loadedSkills = await _storage.loadSkills();
    final loadedTasks = await _storage.loadTasks();
    final loadedProfile = await _storage.loadProfile();
    final loadedHistory = await _storage.loadHistory();
    final loadedAchievements = await _storage.loadAchievements();
    final loadedStats = await _storage.loadStats();
    final loadedBosses = await _storage.loadBosses();
    final loadedRewardChests = await _storage.loadRewardChests();
    final loadedBuffs = await _storage.loadBuffs();
    final loadedWeeklyGoals = await _storage.loadWeeklyGoals();
    final loadedBestStreak = await _storage.loadBestStreak();
    final hasSavedSkills = await _storage.hasSavedSkills();
    final hasSavedTasks = await _storage.hasSavedTasks();
    final savedTheme = await _storage.loadTheme();
    final savedSfxEnabled = await _storage.loadSfxEnabled();
    final savedTooltipsEnabled = await _storage.loadTooltipsEnabled();
    final savedOnboardingSeen = await _storage.loadOnboardingSeen();
    final savedTutorialProgress = await _storage.loadTutorialProgress();

    if (savedTheme != null) {
      _isDark = savedTheme;
    }
    if (savedSfxEnabled != null) {
      _sfxEnabled = savedSfxEnabled;
    }
    if (savedTooltipsEnabled != null) {
      _tooltipsEnabled = savedTooltipsEnabled;
    }
    if (savedOnboardingSeen != null) {
      _onboardingSeen = savedOnboardingSeen;
    }
    _tutorialProgress =
        savedTutorialProgress ?? _legacyTutorialProgress(_onboardingSeen);
    _applySfxEnabled();

    if (hasSavedSkills || loadedSkills.isNotEmpty) {
      skills.clear();
      skills.addAll(loadedSkills);
    }

    if (hasSavedTasks || loadedTasks.isNotEmpty) {
      tasks.clear();
      tasks.addAll(loadedTasks);
    }

    for (final s in skills) {
      s.syncChecklistDone();
      s.syncTreeNodes();
    }
    for (final t in tasks) {
      t.syncSubtaskDone();
      if (t.repeatCustomDays < 1) t.repeatCustomDays = 1;
    }

    profile = loadedProfile;
    final protectionChanged = _refillStreakProtectionIfNeeded();

    if (loadedHistory.isNotEmpty) {
      history.clear();
      history.addAll(loadedHistory);
      _invalidateHistoryCaches();
    }

    if (loadedAchievements.isNotEmpty) {
      achievements.clear();
      achievements.addAll(loadedAchievements);
      _ensureAchievementDefinitions();
    } else {
      _initAchievements();
    }

    rewardChests.clear();
    rewardChests.addAll(loadedRewardChests);

    buffs.clear();
    buffs.addAll(loadedBuffs);

    weeklyGoals.clear();
    weeklyGoals.addAll(loadedWeeklyGoals);

    todayStats = loadedStats;
    _resetDailyStatsIfNeeded();
    _maybeUnlockDailyRewardChest(notify: false);

    bosses.clear();
    bosses.addAll(loadedBosses);

    if (selectedSkillId != null && _skillById(selectedSkillId!) == null) {
      selectedSkillId = null;
    }

    _bestStreak = loadedBestStreak ?? 0;
    _recalculateBestStreakFromTasks();
    final changed = _resetExpiredTasks();
    _syncAllBosses();
    _checkAchievements();
    if (changed || protectionChanged) {
      await _saveAll(immediate: true);
    }

    _syncAllTaskNotifications();

    _hasLoadedSavedData = true;
    notifyListeners();
  }

  void _ensureAchievementDefinitions() {
    for (final a in achievements) {
      a.def ??= achievementDefinitions.where((d) => d.id == a.id).firstOrNull;
    }
    for (final def in achievementDefinitions) {
      if (!achievements.any((a) => a.id == def.id)) {
        achievements.add(Achievement(id: def.id)..def = def);
      }
    }
  }

  Future<void> _saveAll({bool immediate = false}) {
    if (immediate) return flushSaves();

    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_saveDebounceDuration, () {
      _saveDebounceTimer = null;
      unawaited(_writeAll());
    });
    return Future.value();
  }

  Future<void> flushSaves() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    return _writeAll();
  }

  Future<void> _writeAll() {
    final inFlight = _saveInFlight;
    if (inFlight != null) {
      _saveAgainAfterInFlight = true;
      return inFlight;
    }

    final completer = Completer<void>();
    _saveInFlight = completer.future;

    () async {
      try {
        do {
          _saveAgainAfterInFlight = false;
          await _writeAllUnlocked();
        } while (_saveAgainAfterInFlight);
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        _saveInFlight = null;
      }
    }();

    return completer.future;
  }

  Future<void> _writeAllUnlocked() async {
    await _storage.saveTheme(_isDark);
    await _storage.saveSfxEnabled(_sfxEnabled);
    await _storage.saveTooltipsEnabled(_tooltipsEnabled);
    await _storage.saveOnboardingSeen(_onboardingSeen);
    await _storage.saveTutorialProgress(_tutorialProgress);
    await _storage.saveSkills(skills);
    await _storage.saveTasks(tasks);
    await _storage.saveProfile(profile);
    await _storage.saveHistory(history);
    await _storage.saveAchievements(achievements);
    await _storage.saveStats(todayStats ?? DailyStats(date: DateTime.now()));
    await _storage.saveBosses(bosses);
    await _storage.saveRewardChests(rewardChests);
    await _storage.saveBuffs(buffs);
    await _storage.saveWeeklyGoals(weeklyGoals);
    await _storage.saveBestStreak(_bestStreak);
  }

  // ── Theme ────────────────────────────────────────────────────────────────────

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
    _storage.saveTheme(_isDark);
  }

  void toggleSfxEnabled() {
    _sfxEnabled = !_sfxEnabled;
    _applySfxEnabled();
    notifyListeners();
    _storage.saveSfxEnabled(_sfxEnabled);
  }

  void _applySfxEnabled() {
    try {
      SfxService.instance.enabled = _sfxEnabled;
    } catch (_) {
      // Unit tests and unsupported platforms may not have the audio plugin.
    }
  }

  void toggleTooltipsEnabled() {
    _tooltipsEnabled = !_tooltipsEnabled;
    notifyListeners();
    _storage.saveTooltipsEnabled(_tooltipsEnabled);
  }

  bool isCourseNudgeDismissed(String key) =>
      _dismissedCourseNudgeKeys.contains(key);

  void dismissCourseNudge(String key) {
    if (_dismissedCourseNudgeKeys.add(key)) {
      notifyListeners();
    }
  }

  void dismissFirstRunTutorial() {
    dismissActiveTutorial();
  }

  void resetFirstRunTutorial() {
    resetTutorialProgress();
  }

  void _completeOnboardingAfterFirstTask() {
    completeTutorialStep(TutorialStepIds.coreCreateQuest);
  }

  void replayFirstRunTutorial() {
    startTutorialModule(TutorialModuleIds.core);
  }

  void startTutorialModule(String id) {
    final safeId = TutorialModuleIds.all.contains(id)
        ? id
        : TutorialModuleIds.core;
    final dismissed = Set<String>.from(_tutorialProgress.dismissedModuleIds)
      ..remove(safeId);
    _onboardingReplayRequested = safeId == TutorialModuleIds.core;
    _tutorialProgress = _tutorialProgress.copyWith(
      dismissedModuleIds: dismissed,
      activeModuleId: safeId,
      activeStepId: _defaultTutorialStepForModule(safeId),
      updatedAt: DateTime.now(),
    );
    _persistTutorialProgress();
    notifyListeners();
  }

  void completeTutorialStep(String stepId) {
    final moduleId = _moduleForTutorialStep(stepId);
    if (moduleId == null) return;

    final completedSteps = Set<String>.from(_tutorialProgress.completedStepIds)
      ..add(stepId);
    final activeModule = _effectiveTutorialModuleId;
    final activeStep = _effectiveTutorialStepId;
    final shouldAdvance =
        activeModule == moduleId &&
        (activeStep == null || activeStep == stepId);
    final nextStep = shouldAdvance ? _nextTutorialStep(stepId) : activeStep;

    _tutorialProgress = _tutorialProgress.copyWith(
      completedStepIds: completedSteps,
      activeModuleId: activeModule,
      activeStepId: nextStep,
      clearActive: shouldAdvance && nextStep == null,
      updatedAt: DateTime.now(),
    );

    if (shouldAdvance && nextStep == null) {
      completeTutorialModule(moduleId);
      return;
    }

    _persistTutorialProgress();
    notifyListeners();
  }

  void completeTutorialModule(String id) {
    final completedModules = Set<String>.from(
      _tutorialProgress.completedModuleIds,
    )..add(id);
    final completedSteps = Set<String>.from(_tutorialProgress.completedStepIds)
      ..addAll(_tutorialStepsForModule(id));
    final clearActive = _effectiveTutorialModuleId == id;

    if (id == TutorialModuleIds.core && !_onboardingSeen) {
      _onboardingSeen = true;
      _storage.saveOnboardingSeen(true);
    }
    if (id == TutorialModuleIds.core) {
      _onboardingReplayRequested = false;
    }

    _tutorialProgress = _tutorialProgress.copyWith(
      completedModuleIds: completedModules,
      completedStepIds: completedSteps,
      clearActive: clearActive,
      updatedAt: DateTime.now(),
    );
    _persistTutorialProgress();
    notifyListeners();
  }

  void dismissTutorialModule(String id) {
    final dismissed = Set<String>.from(_tutorialProgress.dismissedModuleIds)
      ..add(id);
    final clearActive = _effectiveTutorialModuleId == id;
    if (id == TutorialModuleIds.core && !_onboardingSeen) {
      _onboardingSeen = true;
      _storage.saveOnboardingSeen(true);
    }
    if (id == TutorialModuleIds.core) {
      _onboardingReplayRequested = false;
    }
    _tutorialProgress = _tutorialProgress.copyWith(
      dismissedModuleIds: dismissed,
      clearActive: clearActive,
      updatedAt: DateTime.now(),
    );
    _persistTutorialProgress();
    notifyListeners();
  }

  void dismissActiveTutorial() {
    final module = _effectiveTutorialModuleId ?? TutorialModuleIds.core;
    dismissTutorialModule(module);
  }

  void resetTutorialProgress() {
    _onboardingReplayRequested = false;
    _onboardingSeen = false;
    _tutorialProgress = const TutorialProgress.empty();
    _storage.saveOnboardingSeen(false);
    _persistTutorialProgress();
    notifyListeners();
  }

  void _persistTutorialProgress() {
    _storage.saveTutorialProgress(_tutorialProgress);
  }

  TutorialProgress _legacyTutorialProgress(bool onboardingSeen) {
    if (!onboardingSeen) return const TutorialProgress.empty();
    return TutorialProgress(
      completedModuleIds: const {TutorialModuleIds.core},
      completedStepIds: _tutorialStepsForModule(TutorialModuleIds.core).toSet(),
      updatedAt: DateTime.now(),
    );
  }

  String _defaultTutorialStepForModule(String moduleId) {
    if (moduleId == TutorialModuleIds.core) {
      return _defaultCoreTutorialStep();
    }
    final steps = _tutorialStepsForModule(moduleId);
    for (final step in steps) {
      if (!_tutorialProgress.isStepCompleted(step)) return step;
    }
    return steps.firstOrNull ?? TutorialStepIds.coreCreateSkill;
  }

  bool get _hasActiveTutorialQuest => tasks.any((task) => !task.isDone);

  String _defaultCoreTutorialStep() {
    if (skills.isEmpty) return TutorialStepIds.coreCreateSkill;
    if (_hasActiveTutorialQuest) return TutorialStepIds.coreCompleteQuest;
    return TutorialStepIds.coreCreateQuest;
  }

  String _normalizedCoreTutorialStep(String stepId) {
    if (stepId == TutorialStepIds.coreCreateSkill && skills.isNotEmpty) {
      return _defaultCoreTutorialStep();
    }
    if (stepId == TutorialStepIds.coreCreateQuest && _hasActiveTutorialQuest) {
      return TutorialStepIds.coreCompleteQuest;
    }
    return stepId;
  }

  List<String> _tutorialStepsForModule(String moduleId) {
    return switch (moduleId) {
      TutorialModuleIds.core => const [
        TutorialStepIds.coreCreateSkill,
        TutorialStepIds.coreCreateQuest,
        TutorialStepIds.coreCompleteQuest,
        TutorialStepIds.coreXpFeedback,
        TutorialStepIds.coreOpenRoadmap,
        TutorialStepIds.coreRoadmapDetails,
        TutorialStepIds.coreOpenStats,
      ],
      TutorialModuleIds.act => const [
        TutorialStepIds.actNextQuest,
        TutorialStepIds.actMinimum,
      ],
      TutorialModuleIds.roadmap => const [
        TutorialStepIds.roadmapPath,
        TutorialStepIds.roadmapPractice,
      ],
      TutorialModuleIds.stats => const [TutorialStepIds.statsGrowth],
      TutorialModuleIds.trophies => const [TutorialStepIds.trophiesFeedback],
      TutorialModuleIds.profile => const [TutorialStepIds.profileReplay],
      _ => const [],
    };
  }

  String? _moduleForTutorialStep(String stepId) {
    for (final moduleId in TutorialModuleIds.all) {
      if (_tutorialStepsForModule(moduleId).contains(stepId)) return moduleId;
    }
    return null;
  }

  String? _nextTutorialStep(String stepId) {
    final moduleId = _moduleForTutorialStep(stepId);
    if (moduleId == null) return null;
    final steps = _tutorialStepsForModule(moduleId);
    final index = steps.indexOf(stepId);
    if (index == -1 || index >= steps.length - 1) return null;
    return steps[index + 1];
  }

  void _completeCoreTutorialAfterFirstAction() {
    final activeCoreAction =
        activeTutorialModuleId == TutorialModuleIds.core &&
        activeTutorialStepId == TutorialStepIds.coreCompleteQuest;
    if (!activeCoreAction && (_onboardingSeen || tasks.isEmpty)) return;
    completeTutorialStep(TutorialStepIds.coreCompleteQuest);
  }

  // ── Resets ───────────────────────────────────────────────────────────────────

  bool _resetExpiredTasks() {
    final now = DateTime.now();
    var changed = _refillStreakProtectionIfNeeded(now);

    for (final t in tasks) {
      if (t.type != TaskType.repeating) continue;
      if (t.repeatCustomDays < 1) {
        t.repeatCustomDays = 1;
        changed = true;
      }

      if (t.isDone && t.nextResetAt != null && !now.isBefore(t.nextResetAt!)) {
        final resetFrom = t.nextResetAt!;
        t.isDone = false;
        t.earnedXP = 0;
        t.minimumActionDoneAt = null;
        t.minimumActionEarnedXP = 0;
        t.nextResetAt = nextResetFrom(
          resetFrom,
          t.repeatFrequency,
          t.repeatCustomDays,
        );
        changed = true;
      }

      if (!t.isDone && t.nextResetAt != null) {
        var missedPeriods = 0;
        var guard = 0;
        while (!now.isBefore(t.nextResetAt!) && guard < 3700) {
          missedPeriods++;
          t.nextResetAt = nextResetFrom(
            t.nextResetAt!,
            t.repeatFrequency,
            t.repeatCustomDays,
          );
          guard++;
        }

        if (missedPeriods > 0) {
          if (t.streak != 0 && !_protectMissedStreak(t, missedPeriods, now)) {
            t.streak = 0;
          }
          changed = true;
        }
      }
    }

    if (changed) {
      _syncAllBosses();
    }
    return changed;
  }

  bool _refillStreakProtectionIfNeeded([DateTime? at]) {
    final now = at ?? DateTime.now();
    final weekStart = _startOfWeek(now);
    final refilledAt = profile.streakProtectionRefilledAt;
    final refilledWeek = refilledAt == null ? null : _startOfWeek(refilledAt);
    var changed = false;

    if (profile.streakProtectionCharges < 0) {
      profile.streakProtectionCharges = 0;
      changed = true;
    }
    if (profile.streakProtectionCharges > _maxStreakProtectionCharges) {
      profile.streakProtectionCharges = _maxStreakProtectionCharges;
      changed = true;
    }

    if (refilledWeek == null || !isSameDate(refilledWeek, weekStart)) {
      profile.streakProtectionCharges = _maxStreakProtectionCharges;
      profile.streakProtectionRefilledAt = weekStart;
      changed = true;
    }

    return changed;
  }

  bool _protectMissedStreak(Task task, int missedPeriods, DateTime now) {
    if (missedPeriods != 1 || profile.streakProtectionCharges < 1) {
      return false;
    }

    profile.streakProtectionCharges--;
    profile.lastStreakProtectionUsedAt = now;
    profile.lastStreakProtectionTaskTitle = task.title;
    return true;
  }

  void checkResets() {
    if (_resetExpiredTasks()) {
      _syncAllTaskNotifications();
      notifyListeners();
      _saveAll();
    }
  }

  // ── Queries ──────────────────────────────────────────────────────────────────

  List<Task> tasksForSkill(String id) =>
      tasks.where((t) => t.skillId == id).toList();

  List<Task> tasksForTreeNode(String skillId, String nodeId) => tasks
      .where((task) => task.skillId == skillId && task.treeNodeId == nodeId)
      .toList();

  int completedTasksForTreeNode(String skillId, String nodeId) =>
      tasksForTreeNode(skillId, nodeId).where((task) => task.isDone).length;

  ({List<Task> active, List<Task> completed}) taskSectionsForSkill(
    String skillId,
  ) {
    final active = <Task>[], completed = <Task>[];
    for (final t in tasks) {
      if (t.skillId != skillId) continue;
      (t.isDone ? completed : active).add(t);
    }
    return (active: active, completed: completed);
  }

  int activeTaskCountForSkill(String skillId) =>
      tasks.where((t) => t.skillId == skillId && !t.isDone).length;

  Map<DateTime, List<HistoryEntry>> get completionHistoryByDate {
    assert(_historyCachesAreFreshForDebug());
    final cached = _completionHistoryByDateCache;
    if (cached != null) return cached;

    return _rebuildCompletionHistoryCaches();
  }

  Map<DateTime, List<HistoryEntry>> _rebuildCompletionHistoryCaches() {
    // History хранится в обратном порядке вставки (новые через insert(0,…)),
    // поэтому при равных значениях `at` (а это случается, когда несколько
    // действий выполнены в одну миллисекунду — особенно в тестах) сортировка
    // по только `at` теряет фактический порядок вставки и может перепутать
    // completion/undo. Используем индекс в исходном списке как вторичный ключ:
    // больший index в `history` = добавлено раньше = должно идти раньше
    // в orderedHistory.
    final indexedHistory =
        List<MapEntry<int, HistoryEntry>>.generate(
          history.length,
          (i) => MapEntry(i, history[i]),
        )..sort((a, b) {
          final byTime = a.value.at.compareTo(b.value.at);
          if (byTime != 0) return byTime;
          return b.key.compareTo(a.key);
        });
    final orderedHistory = indexedHistory.map((e) => e.value);
    final effectiveCompletionsByTask = <String, List<HistoryEntry>>{};

    for (final entry in orderedHistory) {
      final taskKey = _historyTaskKey(entry);
      final taskCompletions = effectiveCompletionsByTask.putIfAbsent(
        taskKey,
        () => <HistoryEntry>[],
      );

      if (entry.isCompletion) {
        taskCompletions.add(entry);
      } else if (taskCompletions.isNotEmpty) {
        taskCompletions.removeLast();
      }
    }

    final completionsByDate = <DateTime, List<HistoryEntry>>{};

    for (final taskCompletions in effectiveCompletionsByTask.values) {
      for (final completion in taskCompletions) {
        final day = dateOnly(completion.at);
        completionsByDate
            .putIfAbsent(day, () => <HistoryEntry>[])
            .add(completion);
      }
    }

    for (final dayCompletions in completionsByDate.values) {
      dayCompletions.sort((a, b) => a.at.compareTo(b.at));
    }

    final stableCompletionsByDate = <DateTime, List<HistoryEntry>>{};
    var totalCompletions = 0;
    for (final entry in completionsByDate.entries) {
      totalCompletions += entry.value.length;
      stableCompletionsByDate[entry.key] = List.unmodifiable(entry.value);
    }

    _completionHistoryByDateCache = Map.unmodifiable(stableCompletionsByDate);
    _totalTasksCompletedCache = totalCompletions;
    _historyCacheFingerprint = _historyFingerprint();
    return _completionHistoryByDateCache!;
  }

  List<HistoryEntry> completionHistoryForDate(DateTime date) {
    final day = dateOnly(date);
    final dayCompletions = completionHistoryByDate[day];
    if (dayCompletions == null) return const <HistoryEntry>[];
    return List.unmodifiable(dayCompletions);
  }

  bool hasCompletionOnDate(DateTime date) {
    return completionHistoryByDate.containsKey(dateOnly(date));
  }

  void _invalidateHistoryCaches() {
    _completionHistoryByDateCache = null;
    _totalTasksCompletedCache = null;
    _historyCacheFingerprint = null;
  }

  bool _historyCachesAreFreshForDebug() {
    if (_completionHistoryByDateCache == null &&
        _totalTasksCompletedCache == null) {
      return true;
    }
    return _historyCacheFingerprint == _historyFingerprint();
  }

  int _historyFingerprint() {
    return Object.hashAll(
      history.map(
        (entry) => Object.hash(
          entry.id,
          entry.taskId,
          entry.skillId,
          entry.xp,
          entry.isCompletion,
          entry.at.millisecondsSinceEpoch,
        ),
      ),
    );
  }

  List<Boss> get activeBosses =>
      bosses.where((boss) => !boss.isDefeated).toList(growable: false);

  int get activeBossThreatCount =>
      activeBosses.where((boss) => bossSnapshot(boss).isUnderAttack).length;

  BossSnapshot bossSnapshot(Boss boss) => _buildBossSnapshot(boss);

  List<RewardChest> get unopenedRewardChests =>
      rewardChests.where((chest) => !chest.isOpened).toList(growable: false)
        ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));

  List<Buff> get activeBuffs =>
      buffs.where((buff) => buff.isActive).toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  WeeklyGoal? weeklyGoalForWeek(DateTime weekStart) {
    final normalizedStart = _startOfWeek(weekStart);
    return weeklyGoals
        .where((goal) => isSameDate(goal.weekStart, normalizedStart))
        .firstOrNull;
  }

  void saveWeeklyGoal({
    required DateTime weekStart,
    required String title,
    required List<WeeklyKeyResult> keyResults,
  }) {
    final normalizedStart = _startOfWeek(weekStart);
    final normalizedTitle = title.trim();
    final normalizedResults = keyResults
        .map(
          (result) => WeeklyKeyResult(
            id: result.id.isEmpty ? uid() : result.id,
            title: result.title.trim(),
            isDone: result.isDone,
            completedAt: result.completedAt,
          ),
        )
        .where((result) => result.title.isNotEmpty)
        .take(5)
        .toList();

    final existing = weeklyGoalForWeek(normalizedStart);
    if (normalizedTitle.isEmpty && normalizedResults.isEmpty) {
      if (existing == null) return;
      weeklyGoals.remove(existing);
      notifyListeners();
      _saveAll();
      return;
    }

    final now = DateTime.now();
    if (existing == null) {
      weeklyGoals.add(
        WeeklyGoal(
          id: uid(),
          weekStart: normalizedStart,
          title: normalizedTitle.isEmpty ? 'Цель недели' : normalizedTitle,
          keyResults: normalizedResults,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      existing.title = normalizedTitle.isEmpty
          ? 'Цель недели'
          : normalizedTitle;
      existing.keyResults = normalizedResults;
      existing.updatedAt = now;
    }

    weeklyGoals.sort((a, b) => b.weekStart.compareTo(a.weekStart));
    notifyListeners();
    _saveAll();
  }

  void toggleWeeklyKeyResult(String goalId, String keyResultId) {
    final goal = weeklyGoals.where((item) => item.id == goalId).firstOrNull;
    final keyResult = goal?.keyResults
        .where((item) => item.id == keyResultId)
        .firstOrNull;
    if (goal == null || keyResult == null) return;

    keyResult.isDone = !keyResult.isDone;
    keyResult.completedAt = keyResult.isDone ? DateTime.now() : null;
    goal.updatedAt = DateTime.now();
    notifyListeners();
    _saveAll();
  }

  List<RewardChest> consumeRewardChestNotifications() {
    final result = List<RewardChest>.of(_pendingRewardNotifications);
    _pendingRewardNotifications.clear();
    return result;
  }

  List<Buff> consumeBuffNotifications() {
    final result = List<Buff>.of(_pendingBuffNotifications);
    _pendingBuffNotifications.clear();
    return result;
  }

  List<Achievement> consumeAchievementNotifications() {
    final result = List<Achievement>.of(_pendingAchievementNotifications);
    _pendingAchievementNotifications.clear();
    return result;
  }

  Skill? get selectedSkill {
    if (selectedSkillId == null) return null;
    return _skillById(selectedSkillId!);
  }

  int get activeSkillCount => skills.length;

  int previewEarnedXP(Task task) {
    final totalReward = _totalRewardFor(task);
    if (task.type == TaskType.repeating) {
      return totalReward;
    }
    return math.max(0, totalReward - task.minimumActionEarnedXP);
  }

  int previewBuffBonusXP(Task task) {
    final baseEarned = previewEarnedXP(task);
    if (baseEarned <= 0 || task.isDone) return 0;
    return _previewBuffOutcome(task, baseEarned).bonusXp;
  }

  int previewMinimumActionXP(Task task) {
    if (!task.hasMinimumAction || task.isMinimumActionDone || task.isDone) {
      return 0;
    }
    return math.max(1, (_totalRewardFor(task) * _minimumActionRatio).round());
  }

  bool canCompleteMinimumAction(Task task) {
    return task.hasMinimumAction && !task.isDone && !task.isMinimumActionDone;
  }

  String? openRewardChest(String chestId) {
    final chest = rewardChests.where((item) => item.id == chestId).firstOrNull;
    if (chest == null || chest.isOpened) return null;

    chest.openedAt = DateTime.now();
    final buff = _createBuffFromChest(chest);
    buffs.add(buff);

    notifyListeners();
    _saveAll();

    return '🎁 ${chest.title}: ${buff.title}';
  }

  // ── Task completion ──────────────────────────────────────────────────────────

  String? completeTask(String taskId) {
    final hadResetChanges = _resetExpiredTasks();
    final task = _taskById(taskId);
    if (task == null || task.isDone) {
      if (hadResetChanges) {
        notifyListeners();
        _saveAll();
      }
      return null;
    }

    final now = DateTime.now();
    final skill = _skillById(task.skillId);
    final bossMomentsBefore = _bossMomentsForSkill(task.skillId);
    final nextStreak = task.type == TaskType.repeating
        ? task.streak + 1
        : task.streak;
    final totalReward = _totalRewardFor(task);
    final alreadyEarned = task.type == TaskType.repeating
        ? 0
        : task.minimumActionEarnedXP.clamp(0, totalReward);
    final baseEarned = math.max(0, totalReward - alreadyEarned);
    final buffOutcome = _consumeBuffsForTask(task, baseEarned);
    final earned = baseEarned + buffOutcome.bonusXp;

    task.isDone = true;
    task.earnedXP = alreadyEarned + earned;
    task.bonusXpEarned = buffOutcome.bonusXp;
    task.consumedBuffIds = List.of(buffOutcome.buffIds);
    task.lastCompletedAt = now;
    task.updatedAt = now;

    if (task.type == TaskType.repeating) {
      task.streak = nextStreak;
      task.nextResetAt = nextResetFrom(
        now,
        task.repeatFrequency,
        task.repeatCustomDays,
      );
    }

    profile.totalXpEarned += earned;
    if (task.streak > _bestStreak) {
      _bestStreak = task.streak;
    }
    _maybeUnlockStreakRewardChest(task);

    final globalUp = profile.addXP(earned);
    int skillUp = 0;
    if (skill != null) skillUp = skill.addXP(earned);

    _updateDailyStats(earned, skillUp);
    _addHistory(task, skill, earned, isCompletion: true);
    _maybeGrantBehaviorBuffs(task);
    _checkAchievements();
    _checkBosses(task);
    _completeCoreTutorialAfterFirstAction();
    final bossFeedback = _bossFeedbackForSkill(task.skillId, bossMomentsBefore);
    _syncTaskNotification(task);
    notifyListeners();
    _saveAll();

    return _xpMessage(
      skill,
      globalUp,
      skillUp,
      earned,
      bonusXp: buffOutcome.bonusXp,
      bossFeedback: bossFeedback,
    );
  }

  String? completeMinimumAction(String taskId) {
    final hadResetChanges = _resetExpiredTasks();
    final task = _taskById(taskId);
    if (task == null || !canCompleteMinimumAction(task)) {
      if (hadResetChanges) {
        notifyListeners();
        _saveAll();
      }
      return null;
    }

    final now = DateTime.now();
    final skill = _skillById(task.skillId);
    final bossMomentsBefore = _bossMomentsForSkill(task.skillId);
    final earned = previewMinimumActionXP(task);
    final nextStreak = task.type == TaskType.repeating
        ? task.streak + 1
        : task.streak;

    task.minimumActionDoneAt = now;
    task.minimumActionEarnedXP = earned;
    task.bonusXpEarned = 0;
    task.consumedBuffIds = const <String>[];
    task.updatedAt = now;

    if (task.type == TaskType.repeating) {
      task.isDone = true;
      task.earnedXP = earned;
      task.lastCompletedAt = now;
      task.streak = nextStreak;
      task.nextResetAt = nextResetFrom(
        now,
        task.repeatFrequency,
        task.repeatCustomDays,
      );
    }

    profile.totalXpEarned += earned;
    if (task.streak > _bestStreak) {
      _bestStreak = task.streak;
    }
    _maybeUnlockStreakRewardChest(task);

    final globalUp = profile.addXP(earned);
    int skillUp = 0;
    if (skill != null) {
      skillUp = skill.addXP(earned);
    }

    if (task.type == TaskType.repeating) {
      _updateDailyStats(earned, skillUp);
      _addHistory(task, skill, earned, isCompletion: true);
    } else {
      _updateDailyXp(earned, skillUp);
    }

    _checkBosses(task);
    final bossFeedback = _bossFeedbackForSkill(task.skillId, bossMomentsBefore);
    _checkAchievements();
    _completeCoreTutorialAfterFirstAction();
    _syncTaskNotification(task);
    notifyListeners();
    _saveAll();

    return _xpMessage(
      skill,
      globalUp,
      skillUp,
      earned,
      bonusXp: 0,
      bossFeedback: bossFeedback,
      fallbackLabel: task.type == TaskType.repeating ? 'Лёгкий старт' : 'Старт',
    );
  }

  void _updateDailyStats(int xp, [int skillUp = 0]) {
    _resetDailyStatsIfNeeded();
    todayStats!.tasksCompleted++;
    todayStats!.xpEarned += xp;
    todayStats!.skillsImproved += skillUp;
    _maybeUnlockDailyRewardChest();
  }

  void _updateDailyXp(int xp, [int skillUp = 0]) {
    _resetDailyStatsIfNeeded();
    todayStats!.xpEarned += xp;
    todayStats!.skillsImproved += skillUp;
  }

  void _resetDailyStatsIfNeeded() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (todayStats == null || !isSameDate(todayStats!.date, today)) {
      todayStats = DailyStats(date: today);
    }
  }

  void _checkAchievements() {
    _unlockAchievement('first_task', totalTasksCompleted >= 1);
    _unlockAchievement('tasks_100', totalTasksCompleted >= 100);
    _unlockAchievement('tasks_500', totalTasksCompleted >= 500);
    _unlockAchievement('streak_7', _bestStreak >= 7);
    _unlockAchievement('streak_30', _bestStreak >= 30);
    _unlockAchievement('level_5', profile.level >= 5);
    _unlockAchievement('level_10', profile.level >= 10);
    _unlockAchievement('skills_3', skills.length >= 3);
    _unlockAchievement('all_checklist', _hasFullyCompletedChecklist());
  }

  bool _hasFullyCompletedChecklist() {
    return skills.any(
      (s) =>
          s.checklist.isNotEmpty &&
          s.checklistDone.length == s.checklist.length &&
          s.checklistDone.every((done) => done),
    );
  }

  void _unlockAchievement(String id, bool condition) {
    if (!condition) return;
    final a = achievements.where((a) => a.id == id).firstOrNull;
    if (a != null && !a.isUnlocked) {
      a.unlockedAt = DateTime.now();
      _pendingAchievementNotifications.add(a);
    }
  }

  void _checkBosses(Task task) {
    _syncBossesForSkill(task.skillId);
  }

  void _syncAllBosses() {
    final skillIds = bosses.map((b) => b.skillId).toSet();
    for (final skillId in skillIds) {
      _syncBossesForSkill(skillId);
    }
  }

  void _syncBossesForSkill(String skillId) {
    _bossEngine.syncForSkill(
      skillId: skillId,
      bosses: bosses,
      tasks: tasks,
      skill: _skillById(skillId),
      onBossDefeated: (boss, _) {
        _unlockAchievement('first_boss', true);
        final rarity = boss.targetStreak >= 14
            ? RewardRarity.epic
            : RewardRarity.rare;
        _unlockRewardChest(
          sourceKey: 'boss:${boss.id}',
          title: rarity == RewardRarity.epic
              ? 'Эпический сундук победы'
              : 'Сундук победы',
          description:
              'Трофей за преодоление сопротивления ${boss.title}. Внутри усиление для следующего рывка.',
          rarity: rarity,
          skillId: boss.skillId,
        );
      },
    );
  }

  Map<String, _BossMoment> _bossMomentsForSkill(String skillId) {
    return {
      for (final boss in bosses.where((boss) => boss.skillId == skillId))
        boss.id: _BossMoment(hp: boss.hp, isDefeated: boss.isDefeated),
    };
  }

  String? _bossFeedbackForSkill(
    String skillId,
    Map<String, _BossMoment> before,
  ) {
    for (final boss in bosses.where((boss) => boss.skillId == skillId)) {
      final previous = before[boss.id];
      if (previous == null || previous.isDefeated) continue;
      if (boss.isDefeated) {
        return 'сопротивление “${boss.title}” преодолено';
      }
      if (boss.hp < previous.hp) {
        return 'сопротивление “${boss.title}” ослабло';
      }
    }
    return null;
  }

  void uncompleteTask(String taskId) {
    final task = _taskById(taskId);
    if (task == null || !task.isDone) return;

    final completedAt = task.lastCompletedAt;
    final previousStreak = task.streak;
    final restoresMinimumProgress =
        task.type != TaskType.repeating &&
        task.minimumActionDoneAt != null &&
        task.minimumActionEarnedXP > 0;
    final earned = restoresMinimumProgress
        ? math.max(0, task.earnedXP - task.minimumActionEarnedXP)
        : task.earnedXP;
    final completedToday =
        task.lastCompletedAt != null &&
        isSameDate(task.lastCompletedAt!, DateTime.now());
    final skill = _skillById(task.skillId);
    final skillLevelBefore = skill?.level ?? 1;

    task.isDone = false;
    if (task.type == TaskType.repeating) {
      task.streak = math.max(0, task.streak - 1);
    }
    task.earnedXP = 0;
    task.bonusXpEarned = 0;
    task.lastCompletedAt = null;
    task.updatedAt = DateTime.now();
    if (!restoresMinimumProgress) {
      task.minimumActionDoneAt = null;
      task.minimumActionEarnedXP = 0;
    }
    _restoreConsumedBuffs(task.consumedBuffIds);
    task.consumedBuffIds = const <String>[];

    profile.totalXpEarned = math.max(0, profile.totalXpEarned - earned);
    profile.removeXP(earned);
    skill?.removeXP(earned);
    final skillLevelsLost = math.max(0, skillLevelBefore - (skill?.level ?? 1));

    if (completedToday) {
      _decrementDailyStats(earned, skillLevelsLost);
    }
    _addHistory(task, skill, earned, isCompletion: false);
    _syncBossesForSkill(task.skillId);
    _rollbackInvalidRewardsAfterUndo(
      task,
      completedAt: completedAt,
      previousStreak: previousStreak,
    );
    _syncTaskNotification(task);
    notifyListeners();
    _saveAll();
  }

  // ── Checklist ────────────────────────────────────────────────────────────────

  void toggleChecklistItem(String skillId, int index) {
    final skill = _skillById(skillId);
    if (skill == null || index < 0 || index >= skill.checklistDone.length) {
      return;
    }
    skill.checklistDone[index] = !skill.checklistDone[index];
    _syncBossesForSkill(skillId);
    _checkAchievements();
    notifyListeners();
    _saveAll();
  }

  // ── Profile updates ──────────────────────────────────────────────────────────

  void updateProfileName(String name) {
    if (name.trim().isEmpty) return;
    profile.name = name.trim();
    notifyListeners();
    _saveAll();
  }

  void updateProfileAge(int? age) {
    profile.age = age;
    notifyListeners();
    _saveAll();
  }

  void updateProfileGender(Gender? gender) {
    profile.gender = gender;
    notifyListeners();
    _saveAll();
  }

  void updateProfileAvatar(Uint8List? bytes) {
    if (bytes != null && !hasSupportedImageMagicBytes(bytes)) return;
    profile.avatarBytes = bytes;
    notifyListeners();
    _saveAll();
  }

  void updateProfileBanner(Uint8List? bytes) {
    if (bytes != null && !hasSupportedImageMagicBytes(bytes)) return;
    profile.bannerBytes = bytes;
    notifyListeners();
    _saveAll();
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  void selectSkill(String id) {
    final next = selectedSkillId == id ? null : id;
    if (selectedSkillId == next) return;
    selectedSkillId = next;
    notifyListeners();
  }

  void addSkill(Skill s) {
    s.syncChecklistDone();
    s.syncTreeNodes();
    skills.add(s);
    _checkAchievements();
    notifyListeners();
    _saveAll();
  }

  void updateSkill(
    Skill skill, {
    required String name,
    required String goal,
    required List<String> checklist,
    required Color color,
    required IconData icon,
  }) {
    skill.name = name;
    skill.goal = goal;
    skill.checklist = checklist;
    skill.color = color;
    skill.icon = icon;
    skill.syncChecklistDone();
    skill.syncTreeNodes();
    _checkAchievements();
    notifyListeners();
    _saveAll();
  }

  void addGoalReview(String skillId, GoalReviewEntry review) {
    final skill = _skillById(skillId);
    if (skill == null) return;
    skill.goalSpec.reviews.insert(0, review);
    skill.goalSpec.updatedAt = DateTime.now();
    notifyListeners();
    _saveAll();
  }

  void addSkillTreeNode(String skillId, SkillTreeNode node) {
    final skill = _skillById(skillId);
    if (skill == null) return;
    if (node.requiredQuestCompletions < 1) {
      node.requiredQuestCompletions = 1;
    }
    node.syncChecklistDone();
    skill.treeNodes.add(node);
    skill.syncTreeNodes();
    _syncBossesForSkill(skillId);
    notifyListeners();
    _saveAll();
  }

  void addRoadmapTemplate(String skillId, RoadmapTemplateConfig config) {
    applyRoadmapTemplate(skillId, config);
  }

  void applyRoadmapTemplate(String skillId, RoadmapTemplateConfig config) {
    final skill = _skillById(skillId);
    if (skill == null) return;
    final engine = const RoadmapEngine();
    final templatePaths = engine.buildTemplatePaths(config);
    if (templatePaths.isEmpty) return;

    final linkedNodeIds = tasks
        .where((task) => task.skillId == skill.id && task.treeNodeId != null)
        .map((task) => task.treeNodeId!)
        .toSet();
    final orderedExisting = engine.orderedUniqueStages(skill);
    final originalPrerequisitesByNodeId = <String, List<String>>{
      for (final node in orderedExisting)
        node.id: List<String>.from(node.prerequisiteIds),
    };
    final selectedNodes = <SkillTreeNode>[];
    final selectedIds = <String>{};
    final reusedNodeIds = <String>{};
    final requiredPrerequisiteByNodeId = <String, String?>{};
    var cursor = 0;

    for (final path in templatePaths) {
      String? previousId;
      for (final templateNode in path.nodes) {
        final reused = cursor < orderedExisting.length;
        final node = reused ? orderedExisting[cursor++] : templateNode;
        if (reused) {
          reusedNodeIds.add(node.id);
        }
        if (selectedIds.add(node.id)) {
          selectedNodes.add(node);
        }
        requiredPrerequisiteByNodeId[node.id] = previousId;
        if (node.requiredQuestCompletions < 1) {
          node.requiredQuestCompletions = 1;
        }
        node.syncChecklistDone();
        previousId = node.id;
      }
    }

    final preservedExtraNodes = orderedExisting
        .skip(cursor)
        .where(
          (node) =>
              !selectedIds.contains(node.id) &&
              _shouldPreserveRoadmapStage(node, linkedNodeIds),
        )
        .toList(growable: false);
    final finalNodes = [...selectedNodes, ...preservedExtraNodes];
    final finalNodeIds = finalNodes.map((node) => node.id).toSet();
    final prerequisitesByNodeId = <String, List<String>>{
      for (final node in finalNodes)
        node.id: List<String>.from(node.prerequisiteIds),
    };

    for (final node in finalNodes) {
      final isTemplateNode = requiredPrerequisiteByNodeId.containsKey(node.id);
      final requiredPrerequisite = requiredPrerequisiteByNodeId[node.id];
      final isTemplateRoot = isTemplateNode && requiredPrerequisite == null;
      // A reused stage can become the first stage of a new road. Keeping its
      // old parent would silently attach that road back to the previous road.
      final shouldMergeExistingPrerequisites =
          !isTemplateRoot &&
          (reusedNodeIds.contains(node.id) ||
              preservedExtraNodes.any((extra) => extra.id == node.id));
      final existingPrerequisites = shouldMergeExistingPrerequisites
          ? originalPrerequisitesByNodeId[node.id] ?? const <String>[]
          : const <String>[];
      final mergedPrerequisites = _mergeRoadmapPrerequisites(
        nodeId: node.id,
        requiredPrerequisiteId: requiredPrerequisite,
        existingPrerequisiteIds: existingPrerequisites,
        finalNodeIds: finalNodeIds,
        prerequisitesByNodeId: prerequisitesByNodeId,
      );
      node.prerequisiteIds = mergedPrerequisites;
      prerequisitesByNodeId[node.id] = mergedPrerequisites;
    }

    skill.treeNodes
      ..clear()
      ..addAll(finalNodes);
    skill.syncTreeNodes();
    _syncBossesForSkill(skillId);
    notifyListeners();
    _saveAll();
  }

  List<String> _mergeRoadmapPrerequisites({
    required String nodeId,
    required String? requiredPrerequisiteId,
    required Iterable<String> existingPrerequisiteIds,
    required Set<String> finalNodeIds,
    required Map<String, List<String>> prerequisitesByNodeId,
  }) {
    final merged = <String>[];

    void tryAdd(String? prerequisiteId) {
      if (prerequisiteId == null) return;
      if (prerequisiteId == nodeId) return;
      if (!finalNodeIds.contains(prerequisiteId)) return;
      if (merged.contains(prerequisiteId)) return;
      final candidateMap = <String, List<String>>{
        for (final entry in prerequisitesByNodeId.entries)
          entry.key: List<String>.from(entry.value),
      };
      candidateMap[nodeId] = [...merged, prerequisiteId];
      if (_roadmapPrerequisitesCreateCycle(nodeId, candidateMap)) return;
      merged.add(prerequisiteId);
    }

    tryAdd(requiredPrerequisiteId);
    for (final prerequisiteId in existingPrerequisiteIds) {
      tryAdd(prerequisiteId);
    }
    return merged;
  }

  bool _roadmapPrerequisitesCreateCycle(
    String nodeId,
    Map<String, List<String>> prerequisitesByNodeId,
  ) {
    bool visit(String currentId, Set<String> seen) {
      final prerequisites = prerequisitesByNodeId[currentId];
      if (prerequisites == null) return false;
      for (final prerequisiteId in prerequisites) {
        if (prerequisiteId == nodeId) return true;
        if (!seen.add(prerequisiteId)) continue;
        if (visit(prerequisiteId, seen)) return true;
      }
      return false;
    }

    return visit(nodeId, <String>{});
  }

  bool _shouldPreserveRoadmapStage(
    SkillTreeNode node,
    Set<String> linkedNodeIds,
  ) {
    return linkedNodeIds.contains(node.id) ||
        node.isMastered ||
        node.masteredAt != null ||
        node.description.trim().isNotEmpty ||
        node.checklist.isNotEmpty;
  }

  SkillTreeNode? extendRoadmapPath(
    String skillId,
    String pathNodeId, {
    String title = 'Новый этап',
    String description = '',
    int xpReward = 30,
    int requiredQuestCompletions = 3,
  }) {
    final skill = _skillById(skillId);
    if (skill == null) return null;
    final terminalNode =
        const RoadmapEngine().terminalStageForNode(skill, pathNodeId) ??
        skill.treeNodes
            .where((candidate) => candidate.id == pathNodeId)
            .firstOrNull;
    if (terminalNode == null) return null;

    final safeTitle = title.trim().isEmpty ? 'Новый этап' : title.trim();
    final node = SkillTreeNode(
      id: uid(),
      title: safeTitle,
      description: description,
      xpReward: xpReward,
      requiredQuestCompletions: math.max(1, requiredQuestCompletions),
      prerequisiteIds: [terminalNode.id],
    )..syncChecklistDone();

    skill.treeNodes.add(node);
    skill.syncTreeNodes();
    _syncBossesForSkill(skillId);
    notifyListeners();
    _saveAll();
    return node;
  }

  SkillTreeNode? insertRoadmapStageAfter(
    String skillId,
    String leftNodeId, {
    required String beforeNodeId,
    String title = 'Новый этап',
    String description = '',
    int xpReward = 30,
    int requiredQuestCompletions = 3,
  }) {
    final skill = _skillById(skillId);
    if (skill == null) return null;
    final leftNodeIndex = skill.treeNodes.indexWhere(
      (candidate) => candidate.id == leftNodeId,
    );
    final rightNodeIndex = skill.treeNodes.indexWhere(
      (candidate) => candidate.id == beforeNodeId,
    );
    if (leftNodeIndex == -1 || rightNodeIndex == -1) return null;

    final rightNode = skill.treeNodes[rightNodeIndex];
    if (!rightNode.prerequisiteIds.contains(leftNodeId)) return null;

    final safeTitle = title.trim().isEmpty ? 'Новый этап' : title.trim();
    final node = SkillTreeNode(
      id: uid(),
      title: safeTitle,
      description: description,
      xpReward: xpReward,
      requiredQuestCompletions: math.max(1, requiredQuestCompletions),
      prerequisiteIds: [leftNodeId],
    )..syncChecklistDone();

    rightNode.prerequisiteIds = rightNode.prerequisiteIds
        .map((id) => id == leftNodeId ? node.id : id)
        .toList(growable: true);
    skill.treeNodes.insert(rightNodeIndex, node);
    skill.syncTreeNodes();
    _syncBossesForSkill(skillId);
    notifyListeners();
    _saveAll();
    return node;
  }

  void updateSkillTreeNodePracticeTarget(
    String skillId,
    String nodeId,
    int requiredQuestCompletions, {
    int? xpReward,
  }) {
    final skill = _skillById(skillId);
    final node = skill?.treeNodes
        .where((candidate) => candidate.id == nodeId)
        .firstOrNull;
    if (skill == null || node == null) return;
    node.requiredQuestCompletions = math.max(1, requiredQuestCompletions);
    if (xpReward != null) {
      node.xpReward = math.max(0, xpReward);
    }
    skill.syncTreeNodes();
    _syncBossesForSkill(skillId);
    notifyListeners();
    _saveAll();
  }

  void renameSkillTreeNode(String skillId, String nodeId, String title) {
    final skill = _skillById(skillId);
    final node = skill?.treeNodes
        .where((candidate) => candidate.id == nodeId)
        .firstOrNull;
    final safeTitle = title.trim();
    if (skill == null || node == null || safeTitle.isEmpty) return;
    if (node.title == safeTitle) return;
    node.title = safeTitle;
    skill.syncTreeNodes();
    _syncBossesForSkill(skillId);
    notifyListeners();
    _saveAll();
  }

  void removeSkillTreeNode(String skillId, String nodeId) {
    final skill = _skillById(skillId);
    if (skill == null) return;
    skill.treeNodes.removeWhere((node) => node.id == nodeId);
    for (final node in skill.treeNodes) {
      node.prerequisiteIds.remove(nodeId);
    }
    for (final task in tasksForTreeNode(skillId, nodeId)) {
      task.treeNodeId = null;
      task.updatedAt = DateTime.now();
    }
    skill.syncTreeNodes();
    _syncBossesForSkill(skillId);
    notifyListeners();
    _saveAll();
  }

  void toggleSkillTreeNodeChecklist(String skillId, String nodeId, int index) {
    final skill = _skillById(skillId);
    final node = skill?.treeNodes
        .where((item) => item.id == nodeId)
        .firstOrNull;
    if (skill == null ||
        node == null ||
        index < 0 ||
        index >= node.checklistDone.length ||
        node.isMastered) {
      return;
    }

    node.checklistDone[index] = !node.checklistDone[index];
    _syncBossesForSkill(skillId);
    notifyListeners();
    _saveAll();
  }

  bool canMasterSkillTreeNode(String skillId, String nodeId) {
    final skill = _skillById(skillId);
    final node = skill?.treeNodes
        .where((item) => item.id == nodeId)
        .firstOrNull;
    if (skill == null || node == null) return false;
    return skill.treeNodeStatus(node) == SkillTreeNodeStatus.active &&
        completedTasksForTreeNode(skillId, nodeId) >= node.questTarget;
  }

  String? masterSkillTreeNode(String skillId, String nodeId) {
    final skill = _skillById(skillId);
    final node = skill?.treeNodes
        .where((item) => item.id == nodeId)
        .firstOrNull;
    if (skill == null ||
        node == null ||
        !canMasterSkillTreeNode(skillId, nodeId)) {
      return null;
    }

    final bossMomentsBefore = _bossMomentsForSkill(skillId);
    final earned = node.xpReward;

    node.isMastered = true;
    node.masteredAt = DateTime.now();

    profile.totalXpEarned += earned;
    final globalUp = profile.addXP(earned);
    final skillUp = skill.addXP(earned);

    _updateDailyXp(earned, skillUp);
    _syncBossesForSkill(skillId);
    final bossFeedback = _bossFeedbackForSkill(skillId, bossMomentsBefore);
    _checkAchievements();
    notifyListeners();
    _saveAll();

    return _xpMessage(
      skill,
      globalUp,
      skillUp,
      earned,
      bonusXp: 0,
      bossFeedback: bossFeedback,
      fallbackLabel: 'Этап освоен',
    );
  }

  void removeSkill(String id) {
    final removedTaskIds = tasks
        .where((t) => t.skillId == id)
        .map((t) => t.id)
        .toList();
    for (final taskId in removedTaskIds) {
      _notifications.cancelNotification(_notificationId(taskId));
    }

    skills.removeWhere((s) => s.id == id);
    tasks.removeWhere((t) => t.skillId == id);
    bosses.removeWhere((b) => b.skillId == id);
    rewardChests.removeWhere((chest) => chest.skillId == id);
    buffs.removeWhere((buff) => buff.skillId == id);
    if (selectedSkillId == id) selectedSkillId = null;
    notifyListeners();
    _saveAll();
  }

  void addTask(Task t) {
    t.syncSubtaskDone();
    t.treeNodeId = _normalizedTreeNodeId(t.skillId, t.treeNodeId);
    if (t.repeatCustomDays < 1) t.repeatCustomDays = 1;
    t.createdAt = DateTime.now();
    t.updatedAt = t.createdAt;
    tasks.add(t);
    _completeOnboardingAfterFirstTask();
    _syncTaskNotification(t);
    notifyListeners();
    _saveAll();
  }

  void updateTask(
    Task task, {
    required String title,
    required String description,
    required int xpReward,
    required TaskType type,
    required RepeatFrequency repeatFrequency,
    required int repeatCustomDays,
    required Priority priority,
    required String minimumAction,
    required List<String> subtasks,
    required List<String> tags,
    required bool notificationsEnabled,
    required int? notificationHour,
    required int? notificationMinute,
    required String? treeNodeId,
  }) {
    final oldType = task.type;
    final hadNotification = task.notificationsEnabled;
    final oldMinimumAction = task.minimumAction;
    task.title = title;
    task.description = description.trim();
    task.xpReward = xpReward;
    task.type = type;
    task.repeatFrequency = repeatFrequency;
    task.repeatCustomDays = repeatCustomDays < 1 ? 1 : repeatCustomDays;
    task.priority = priority;
    final nextMinimumAction = minimumAction.trim();
    if (nextMinimumAction.isEmpty && task.isMinimumActionDone) {
      task.minimumAction = oldMinimumAction;
    } else {
      task.minimumAction = nextMinimumAction;
    }
    task.subtasks = subtasks;
    task.syncSubtaskDone();
    task.tags = tags;
    task.treeNodeId = _normalizedTreeNodeId(task.skillId, treeNodeId);
    task.notificationsEnabled = notificationsEnabled;
    task.notificationHour = notificationHour;
    task.notificationMinute = notificationMinute;
    task.updatedAt = DateTime.now();

    if (oldType == TaskType.repeating && type != TaskType.repeating) {
      task.streak = 0;
      task.nextResetAt = null;
    } else if (type == TaskType.repeating && task.isDone) {
      task.nextResetAt = nextResetFrom(
        task.lastCompletedAt ?? DateTime.now(),
        task.repeatFrequency,
        task.repeatCustomDays,
      );
    }

    _syncBossesForSkill(task.skillId);
    if (hadNotification && !task.notificationsEnabled) {
      _notifications.cancelNotification(_notificationId(task.id));
    }
    _syncTaskNotification(task);
    notifyListeners();
    _saveAll();
  }

  String? _normalizedTreeNodeId(String skillId, String? nodeId) {
    final trimmed = nodeId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final skill = _skillById(skillId);
    if (skill == null) return null;
    final exists = skill.treeNodes.any((node) => node.id == trimmed);
    return exists ? trimmed : null;
  }

  void removeTask(String id) {
    final task = _taskById(id);
    if (task != null) {
      _notifications.cancelNotification(_notificationId(task.id));
    }
    tasks.removeWhere((t) => t.id == id);
    if (task != null) _syncBossesForSkill(task.skillId);
    notifyListeners();
    _saveAll();
  }

  void toggleSubtask(String taskId, int index) {
    final task = _taskById(taskId);
    if (task == null || index < 0 || index >= task.subtaskDone.length) return;
    task.subtaskDone[index] = !task.subtaskDone[index];
    task.updatedAt = DateTime.now();
    notifyListeners();
    _saveAll();
  }

  // ── Bosses ──────────────────────────────────────────────────────────────────

  void addBoss(Boss b) {
    bosses.add(b);
    _syncBossesForSkill(b.skillId);
    notifyListeners();
    _saveAll();
  }

  void removeBoss(String id) {
    bosses.removeWhere((b) => b.id == id);
    notifyListeners();
    _saveAll();
  }

  // ── Statistics helpers ───────────────────────────────────────────────────────

  int get totalTasksCompleted {
    assert(_historyCachesAreFreshForDebug());
    final cached = _totalTasksCompletedCache;
    if (cached != null) return cached;

    _rebuildCompletionHistoryCaches();
    return _totalTasksCompletedCache ?? 0;
  }

  int get bestStreak => _bestStreak;

  void normalizeAfterBulkStateChange({bool resetBestStreak = false}) {
    for (final skill in skills) {
      skill.syncChecklistDone();
      skill.syncTreeNodes();
    }
    final validSkillIds = skills.map((skill) => skill.id).toSet();
    for (final task in tasks) {
      task.syncSubtaskDone();
      if (!validSkillIds.contains(task.skillId)) {
        task.treeNodeId = null;
      } else if (task.treeNodeId != null) {
        final skill = _skillById(task.skillId);
        final nodeExists =
            skill?.treeNodes.any((node) => node.id == task.treeNodeId) ?? false;
        if (!nodeExists) task.treeNodeId = null;
      }
    }
    if (selectedSkillId != null && _skillById(selectedSkillId!) == null) {
      selectedSkillId = null;
    }
    _ensureAchievementDefinitions();
    if (resetBestStreak) {
      _bestStreak = 0;
    }
    _recalculateBestStreakFromTasks();
    _invalidateHistoryCaches();
    _syncAllBosses();
    _checkAchievements();
    _syncAllTaskNotifications();
    notifyListeners();
    _saveAll();
  }

  void refresh() {
    notifyListeners();
    _saveAll();
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  int _totalRewardFor(Task task) {
    final nextStreak = task.type == TaskType.repeating
        ? task.streak + 1
        : task.streak;
    final multiplier = task.type == TaskType.repeating
        ? multiplierForStreak(nextStreak)
        : 1;
    return task.xpReward * multiplier;
  }

  ({int bonusXp, int bonusPercent}) _previewBuffOutcome(
    Task task,
    int baseEarned,
  ) {
    if (baseEarned <= 0) return (bonusXp: 0, bonusPercent: 0);

    final applicableBuffs = activeBuffs
        .where((buff) => _buffAppliesToTask(buff, task))
        .toList(growable: false);
    final totalBonusPercent = applicableBuffs.fold<int>(
      0,
      (sum, buff) => sum + buff.bonusPercent,
    );
    final bonusPercent = math.min(_maxBuffBonusPercent, totalBonusPercent);
    final bonusXp = bonusPercent <= 0
        ? 0
        : math.max(1, (baseEarned * bonusPercent / 100).round());
    return (bonusXp: bonusXp, bonusPercent: bonusPercent);
  }

  ({int bonusXp, int bonusPercent, List<String> buffIds}) _consumeBuffsForTask(
    Task task,
    int baseEarned,
  ) {
    final outcome = _previewBuffOutcome(task, baseEarned);
    if (outcome.bonusXp == 0) {
      return (bonusXp: 0, bonusPercent: 0, buffIds: const <String>[]);
    }

    final consumedBuffIds = <String>[];
    var consumedBonusPercent = 0;
    for (final buff in buffs.where((buff) => buff.isActive).toList()) {
      if (!_buffAppliesToTask(buff, task)) continue;
      if (consumedBonusPercent >= _maxBuffBonusPercent) continue;
      buff.charges = math.max(0, buff.charges - 1);
      consumedBuffIds.add(buff.id);
      consumedBonusPercent = math.min(
        _maxBuffBonusPercent,
        consumedBonusPercent + buff.bonusPercent,
      );
    }
    return (
      bonusXp: outcome.bonusXp,
      bonusPercent: outcome.bonusPercent,
      buffIds: consumedBuffIds,
    );
  }

  bool _buffAppliesToTask(Buff buff, Task task) {
    return switch (buff.type) {
      BuffType.nextQuestXpBoost => true,
      BuffType.questRushXpBoost => true,
      BuffType.skillFocusXpBoost =>
        buff.skillId == null || buff.skillId == task.skillId,
    };
  }

  void _maybeUnlockDailyRewardChest({bool notify = true}) {
    final stats = todayStats;
    if (stats == null || stats.tasksCompleted < 5) return;

    final dayKey =
        '${stats.date.year.toString().padLeft(4, '0')}-'
        '${stats.date.month.toString().padLeft(2, '0')}-'
        '${stats.date.day.toString().padLeft(2, '0')}';
    _unlockRewardChest(
      sourceKey: 'daily5:$dayKey',
      title: 'Сундук дисциплины',
      description:
          'Пять закрытых квестов за день. Внутри эффект, который усилит следующий рывок.',
      rarity: RewardRarity.common,
      notify: notify,
    );

    if (stats.tasksCompleted < 10) return;
    _unlockRewardChest(
      sourceKey: 'daily10:$dayKey',
      title: 'Редкий сундук продуктивности',
      description:
          'Десять закрытых квестов за день. Внутри более сильный эффект на серию квестов.',
      rarity: RewardRarity.rare,
      notify: notify,
    );
  }

  void _maybeUnlockStreakRewardChest(Task task, {bool notify = true}) {
    if (task.type != TaskType.repeating) return;

    final milestone = switch (task.streak) {
      7 => (rarity: RewardRarity.rare, title: 'Сундук серии'),
      30 => (rarity: RewardRarity.epic, title: 'Эпический сундук серии'),
      _ => null,
    };
    if (milestone == null) return;

    _unlockRewardChest(
      sourceKey: 'streak:${task.id}:${task.streak}',
      title: milestone.title,
      description:
          'Трофей за серию ${task.streak} дней по квесту «${task.title}».',
      rarity: milestone.rarity,
      skillId: task.skillId,
      notify: notify,
    );
  }

  void _maybeGrantBehaviorBuffs(Task task) {
    final stats = todayStats;
    if (stats == null) return;

    final dayKey = _dayKey(stats.date);
    final expiresAt = _buffExpiresAt();

    if (stats.tasksCompleted >= 3) {
      _grantBehaviorBuff(
        sourceKey: 'flow3:$dayKey',
        type: BuffType.questRushXpBoost,
        title: 'Поток',
        description:
            'Три квеста за день запустили поток: следующие 2 квеста дадут +10% XP.',
        bonusPercent: 10,
        charges: 2,
        expiresAt: expiresAt,
      );
    }

    final completions = completionHistoryForDate(stats.date);
    if (completions.length < 2) return;

    final last = completions.last;
    final previous = completions[completions.length - 2];
    if (last.skillId != task.skillId || previous.skillId != task.skillId) {
      return;
    }

    _grantBehaviorBuff(
      sourceKey: 'focus:$dayKey:${task.skillId}',
      type: BuffType.skillFocusXpBoost,
      title: 'Фокус',
      description:
          'Два квеста одного навыка подряд: следующий квест этого навыка даст +12% XP.',
      bonusPercent: 12,
      charges: 1,
      skillId: task.skillId,
      expiresAt: expiresAt,
    );
  }

  void _grantBehaviorBuff({
    required String sourceKey,
    required BuffType type,
    required String title,
    required String description,
    required int bonusPercent,
    required int charges,
    required DateTime expiresAt,
    String? skillId,
  }) {
    final alreadyGranted = buffs.any((buff) => buff.sourceKey == sourceKey);
    if (alreadyGranted) return;

    final buff = Buff(
      id: uid(),
      type: type,
      title: title,
      description: description,
      bonusPercent: bonusPercent,
      charges: charges,
      skillId: skillId,
      sourceKey: sourceKey,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
    );

    buffs.add(buff);
    _pendingBuffNotifications.add(buff);
  }

  void _unlockRewardChest({
    required String sourceKey,
    required String title,
    required String description,
    required RewardRarity rarity,
    String? skillId,
    bool notify = true,
  }) {
    final alreadyUnlocked = rewardChests.any(
      (chest) => chest.sourceKey == sourceKey,
    );
    if (alreadyUnlocked) return;

    final chest = RewardChest(
      id: uid(),
      title: title,
      description: description,
      rarity: rarity,
      sourceKey: sourceKey,
      skillId: skillId,
      unlockedAt: DateTime.now(),
    );
    rewardChests.add(chest);
    if (notify) {
      _pendingRewardNotifications.add(chest);
    }
  }

  Buff _createBuffFromChest(RewardChest chest) {
    final skill = chest.skillId == null ? null : _skillById(chest.skillId!);
    final now = DateTime.now();
    final expiresAt = _buffExpiresAt(now);

    switch (chest.rarity) {
      case RewardRarity.common:
        return _random.nextBool()
            ? Buff(
                id: uid(),
                type: BuffType.nextQuestXpBoost,
                title: 'Импульс',
                description: 'Следующий квест даст +15% XP в течение 24 часов.',
                bonusPercent: 15,
                charges: 1,
                createdAt: now,
                expiresAt: expiresAt,
                sourceChestId: chest.id,
                sourceKey: 'chest:${chest.id}',
              )
            : Buff(
                id: uid(),
                type: BuffType.questRushXpBoost,
                title: 'Темп',
                description:
                    'Следующие 2 квеста дадут по +10% XP в течение 24 часов.',
                bonusPercent: 10,
                charges: 2,
                createdAt: now,
                expiresAt: expiresAt,
                sourceChestId: chest.id,
                sourceKey: 'chest:${chest.id}',
              );
      case RewardRarity.rare:
        if (skill != null && _random.nextBool()) {
          return Buff(
            id: uid(),
            type: BuffType.skillFocusXpBoost,
            title: 'Резонанс навыка',
            description:
                'Следующий квест по навыку ${skill.name} даст +25% XP в течение 24 часов.',
            bonusPercent: 25,
            charges: 1,
            skillId: skill.id,
            createdAt: now,
            expiresAt: expiresAt,
            sourceChestId: chest.id,
            sourceKey: 'chest:${chest.id}',
          );
        }
        return Buff(
          id: uid(),
          type: BuffType.questRushXpBoost,
          title: 'Боевой ритм',
          description:
              'Следующие 2 квеста дадут по +15% XP в течение 24 часов.',
          bonusPercent: 15,
          charges: 2,
          createdAt: now,
          expiresAt: expiresAt,
          sourceChestId: chest.id,
          sourceKey: 'chest:${chest.id}',
        );
      case RewardRarity.epic:
        return Buff(
          id: uid(),
          type: BuffType.questRushXpBoost,
          title: 'Критический заряд',
          description:
              'Следующие 2 квеста дадут по +35% XP в течение 24 часов.',
          bonusPercent: 35,
          charges: 2,
          createdAt: now,
          expiresAt: expiresAt,
          sourceChestId: chest.id,
          sourceKey: 'chest:${chest.id}',
        );
    }
  }

  DateTime _buffExpiresAt([DateTime? now]) {
    return (now ?? DateTime.now()).add(_buffLifetime);
  }

  String _dayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _restoreConsumedBuffs(List<String> buffIds) {
    if (buffIds.isEmpty) return;
    for (final buffId in buffIds) {
      final buff = buffs.where((item) => item.id == buffId).firstOrNull;
      if (buff != null) {
        buff.charges += 1;
      }
    }
  }

  void _rollbackInvalidRewardsAfterUndo(
    Task task, {
    required DateTime? completedAt,
    required int previousStreak,
  }) {
    final sourceKeys = <String>{};

    if (completedAt != null) {
      final dayKey = _dayKey(completedAt);
      final dayCompletions = completionHistoryForDate(completedAt);

      if (dayCompletions.length < 5) {
        sourceKeys.add('daily5:$dayKey');
      }
      if (dayCompletions.length < 10) {
        sourceKeys.add('daily10:$dayKey');
      }
      if (dayCompletions.length < 3) {
        sourceKeys.add('flow3:$dayKey');
      }
      if (!_hasFocusRewardCondition(completedAt, task.skillId)) {
        sourceKeys.add('focus:$dayKey:${task.skillId}');
      }
    }

    if (previousStreak == 7 || previousStreak == 30) {
      sourceKeys.add('streak:${task.id}:$previousStreak');
    }

    for (final boss in bosses.where((boss) => boss.skillId == task.skillId)) {
      if (!boss.isDefeated) {
        sourceKeys.add('boss:${boss.id}');
      }
    }

    for (final sourceKey in sourceKeys) {
      _removeRewardChestBySourceKey(sourceKey);
      _removeBuffsBySourceKey(sourceKey);
    }
  }

  bool _hasFocusRewardCondition(DateTime date, String skillId) {
    final completions = completionHistoryForDate(date);
    for (var i = 1; i < completions.length; i++) {
      if (completions[i - 1].skillId == skillId &&
          completions[i].skillId == skillId) {
        return true;
      }
    }
    return false;
  }

  void _removeRewardChestBySourceKey(String sourceKey) {
    final removedChestIds = rewardChests
        .where((chest) => chest.sourceKey == sourceKey)
        .map((chest) => chest.id)
        .toSet();
    if (removedChestIds.isEmpty) return;

    rewardChests.removeWhere((chest) => removedChestIds.contains(chest.id));
    _pendingRewardNotifications.removeWhere(
      (chest) =>
          removedChestIds.contains(chest.id) || chest.sourceKey == sourceKey,
    );
    _removeBuffsWhere(
      (buff) =>
          removedChestIds.contains(buff.sourceChestId) ||
          removedChestIds.any((id) => buff.sourceKey == 'chest:$id'),
    );
  }

  void _removeBuffsBySourceKey(String sourceKey) {
    _removeBuffsWhere((buff) => buff.sourceKey == sourceKey);
  }

  void _removeBuffsWhere(bool Function(Buff buff) shouldRemove) {
    final removedBuffIds = buffs
        .where(shouldRemove)
        .map((buff) => buff.id)
        .toSet();
    if (removedBuffIds.isEmpty) return;

    buffs.removeWhere((buff) => removedBuffIds.contains(buff.id));
    _pendingBuffNotifications.removeWhere(
      (buff) => removedBuffIds.contains(buff.id),
    );

    for (final task in tasks) {
      if (!task.consumedBuffIds.any(removedBuffIds.contains)) continue;
      task.consumedBuffIds = task.consumedBuffIds
          .where((id) => !removedBuffIds.contains(id))
          .toList();
    }
  }

  BossSnapshot _buildBossSnapshot(Boss boss) {
    return _bossEngine.buildSnapshot(
      boss: boss,
      tasks: tasks,
      skill: _skillById(boss.skillId),
    );
  }

  void _recalculateBestStreakFromTasks() {
    final currentBest = tasks
        .where((t) => t.type == TaskType.repeating)
        .fold(0, (max, t) => math.max(max, t.streak));
    _bestStreak = math.max(_bestStreak, currentBest);
  }

  void _decrementDailyStats(int xp, [int skillLevelsLost = 0]) {
    if (todayStats == null) return;
    if (!isSameDate(todayStats!.date, DateTime.now())) return;

    todayStats!.tasksCompleted = math.max(0, todayStats!.tasksCompleted - 1);
    todayStats!.xpEarned = math.max(0, todayStats!.xpEarned - xp);
    todayStats!.skillsImproved = math.max(
      0,
      todayStats!.skillsImproved - skillLevelsLost,
    );
  }

  void _addHistory(Task t, Skill? skill, int xp, {required bool isCompletion}) {
    history.insert(
      0,
      HistoryEntry(
        id: uid(),
        taskId: t.id,
        taskTitle: t.title,
        skillId: t.skillId,
        skillName: skill?.name ?? '—',
        skillColor: skill?.color ?? const Color(0xFF8E8E93),
        skillIcon: skill?.icon ?? Icons.bolt,
        xp: xp,
        isCompletion: isCompletion,
        at: DateTime.now(),
      ),
    );
    if (history.length > _maxHistoryEntries) {
      history.removeRange(_maxHistoryEntries, history.length);
    }
    _invalidateHistoryCaches();
  }

  Task? _taskById(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Skill? _skillById(String id) {
    for (final s in skills) {
      if (s.id == id) return s;
    }
    return null;
  }

  String _historyTaskKey(HistoryEntry entry) {
    return entry.taskId ?? '${entry.skillId}::${entry.taskTitle}';
  }

  DateTime _startOfWeek(DateTime date) {
    final day = dateOnly(date);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  int _notificationId(String taskId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in taskId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  String _xpMessage(
    Skill? skill,
    int globalUp,
    int skillUp,
    int earned, {
    required int bonusXp,
    String? bossFeedback,
    String? fallbackLabel,
  }) {
    if (globalUp > 0) {
      return _characterEvent('Новый уровень', [
        'персонаж стал увереннее: ур. ${profile.level}',
        '+$earned XP',
        if (bonusXp > 0) 'эффект +$bonusXp XP',
        _nextProfileLevelHint(),
        ?bossFeedback,
      ]);
    }
    if (skillUp > 0 && skill != null) {
      return _characterEvent('Навык вырос', [
        '${skill.name} окреп до ур.${skill.level}',
        '+$earned XP',
        if (bonusXp > 0) 'эффект +$bonusXp XP',
        _nextSkillLevelHint(skill),
        ?bossFeedback,
      ]);
    }

    if (fallbackLabel != null &&
        fallbackLabel.toLowerCase().contains('старт')) {
      return _characterEvent(fallbackLabel, [
        skill == null ? 'первый шаг сделан' : '${skill.name} запущен',
        '+$earned XP',
        _nextSkillLevelHint(skill),
        ?bossFeedback,
      ]);
    }

    return _characterEvent(
      fallbackLabel == null || fallbackLabel.isEmpty
          ? 'Навык окреп'
          : fallbackLabel,
      [
        skill == null ? '+$earned XP' : '${skill.name} +$earned XP',
        if (bonusXp > 0) 'эффект +$bonusXp XP',
        _nextSkillLevelHint(skill),
        ?bossFeedback,
      ],
    );
  }

  String _characterEvent(String title, List<String?> details) {
    final filtered = details
        .whereType<String>()
        .map((detail) => detail.trim())
        .where((detail) => detail.isNotEmpty)
        .toList();
    return filtered.isEmpty ? title : '$title\n${filtered.join(' • ')}';
  }

  String? _nextProfileLevelHint() {
    return 'до ур.${profile.level + 1} ${profile.xpNeeded - profile.xp} XP';
  }

  String? _nextSkillLevelHint(Skill? skill) {
    if (skill == null) return null;
    return 'до ур.${skill.level + 1} ${skill.xpNeeded - skill.xp} XP';
  }

  void _syncTaskNotification(Task task) {
    final notificationId = _notificationId(task.id);
    final hour = task.notificationHour;
    final minute = task.notificationMinute;

    if (!task.notificationsEnabled) {
      return;
    }

    if (hour == null || minute == null || task.isDone) {
      _notifications.cancelNotification(notificationId);
      return;
    }

    _notifications.requestPermissions().then((granted) {
      if (!granted) return;

      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (!scheduledTime.isAfter(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      if (task.type == TaskType.repeating) {
        _notifications.scheduleRepeatingTask(
          id: notificationId,
          title: 'Напоминание: ${task.title}',
          body: 'Пора выполнить повторяющийся квест.',
          scheduledTime: scheduledTime,
          repeatMode: _repeatNotificationMode(task),
        );
      } else {
        _notifications.scheduleTaskReminder(
          id: notificationId,
          title: 'Напоминание: ${task.title}',
          body: 'Не забудь выполнить квест.',
          scheduledTime: scheduledTime,
        );
      }
    });
  }

  void _syncAllTaskNotifications() {
    for (final task in tasks) {
      _syncTaskNotification(task);
    }
  }

  ReminderRepeatMode _repeatNotificationMode(Task task) {
    return switch (task.repeatFrequency) {
      RepeatFrequency.daily => ReminderRepeatMode.daily,
      RepeatFrequency.weekly => ReminderRepeatMode.weekly,
      RepeatFrequency.every3Days ||
      RepeatFrequency.biweekly ||
      RepeatFrequency.monthly ||
      RepeatFrequency.custom => ReminderRepeatMode.none,
    };
  }
}
