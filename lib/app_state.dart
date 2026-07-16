import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models.dart';
import 'utils.dart';
import 'storage_service.dart';
import 'storage_snapshot.dart';
import 'notification_service.dart';
import 'persistence_status.dart';
import 'sfx_service.dart';
import 'engines/achievement_engine.dart';
import 'engines/boss_engine.dart';
import 'engines/completion_history_index.dart';
import 'engines/goal_milestone_engine.dart';
import 'engines/goal_progress_engine.dart';
import 'engines/roadmap_engine.dart';
import 'analytics/analytics_read_model.dart';
import 'coordinators/roadmap_mutation_coordinator.dart';
import 'coordinators/review_session_coordinator.dart';
import 'coordinators/reward_mutation_coordinator.dart';
import 'coordinators/skill_goal_mutation_coordinator.dart';
import 'coordinators/task_mutation_coordinator.dart';
import 'coordinators/task_completion_coordinator.dart';
import 'persistence/save_scheduler.dart';

export 'coordinators/skill_goal_mutation_coordinator.dart'
    show NextGoalUpdateResult, StartNewRoadmapResult;

part 'app_state/provider.dart';

class GoalMilestoneEvent {
  final String id;
  final String skillId;
  final String skillName;
  final Color skillColor;
  final GoalMilestone milestone;

  const GoalMilestoneEvent({
    required this.id,
    required this.skillId,
    required this.skillName,
    required this.skillColor,
    required this.milestone,
  });
}

class AppState extends ChangeNotifier {
  static const int inboxTaskXp = 10;

  static const double _minimumActionRatio = 0.3;
  static const Duration _resetCheckInterval = Duration(minutes: 15);
  static const int _maxStreakProtectionCharges = 1;
  static const int _maxHistoryEntries = 2000;

  bool _isDark = true;
  bool _sfxEnabled = true;
  bool _tooltipsEnabled = true;
  bool _reducedMotion = false;
  bool _onboardingSeen = false;
  bool _onboardingReplayRequested = false;
  TutorialProgress _tutorialProgress = const TutorialProgress.empty();
  bool _hasLoadedSavedData = false;
  PersistenceStatus _persistenceStatus = const PersistenceStatus();
  bool _isDisposed = false;
  String? selectedSkillId;
  final StorageService _storage;
  final NotificationService _notifications;
  final math.Random _random;
  final AchievementEngine _achievementEngine = const AchievementEngine();
  final BossEngine _bossEngine = const BossEngine();
  final CompletionHistoryIndex _completionHistoryIndex =
      CompletionHistoryIndex();
  final AnalyticsReadModelCache _analyticsReadModelCache =
      AnalyticsReadModelCache();
  final GoalMilestoneEngine _goalMilestoneEngine = const GoalMilestoneEngine();
  final RoadmapMutationCoordinator _roadmapMutations =
      const RoadmapMutationCoordinator();
  final ReviewSessionCoordinator _reviewSessions =
      const ReviewSessionCoordinator();
  final RewardMutationCoordinator _rewardMutations =
      const RewardMutationCoordinator();
  final SkillGoalMutationCoordinator _skillGoalMutations =
      const SkillGoalMutationCoordinator();
  final TaskMutationCoordinator _taskMutations =
      const TaskMutationCoordinator();
  final TaskCompletionCoordinator _taskCompletions =
      const TaskCompletionCoordinator();
  Timer? _resetTimer;
  late final SaveScheduler _saveScheduler;

  bool get isDark => _isDark;
  bool get sfxEnabled => _sfxEnabled;
  bool get tooltipsEnabled => _tooltipsEnabled;
  bool get reducedMotion => _reducedMotion;
  bool get onboardingSeen => _onboardingSeen;
  TutorialProgress get tutorialProgress => _tutorialProgress;
  String? get activeTutorialModuleId => _effectiveTutorialModuleId;
  String? get activeTutorialStepId => _effectiveTutorialStepId;
  bool get hasLoadedSavedData => _hasLoadedSavedData;
  PersistenceStatus get persistenceStatus => _persistenceStatus;
  bool get hasPersistenceError => _persistenceStatus.hasError;
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
  final List<GoalMilestoneEvent> _pendingGoalMilestoneNotifications = [];
  final Set<String> _dismissedCourseNudgeKeys = {};
  DailyStats? todayStats;

  int _bestStreak = 0;
  int _analyticsEpoch = 0;
  int _coreWorkspaceRevision = 0;

  /// Changes only when task, skill, or RoadMap presentation data may be stale.
  ///
  /// Persistence progress and profile/session-only notifications deliberately
  /// do not advance this revision, so task-heavy feature roots can avoid broad
  /// rebuilds while continuing to observe domain mutations through AppState.
  int get coreWorkspaceRevision => _coreWorkspaceRevision;

  AppState({
    required StorageService storage,
    NotificationService? notifications,
    math.Random? random,
    bool seedDefaults = false,
  }) : _storage = storage,
       _notifications = notifications ?? NotificationService(),
       _random = random ?? math.Random() {
    _saveScheduler = SaveScheduler(
      writer: _writeAllUnlocked,
      isBlocked: () => _persistenceStatus.blocksSaving,
      onSaving: () => _setPersistenceStatus(
        _persistenceStatus.copyWith(
          phase: PersistencePhase.saving,
          canRetry: false,
          blocksSaving: false,
          clearError: true,
        ),
      ),
      onSaved: (savedAt) => _setPersistenceStatus(
        _persistenceStatus.copyWith(
          phase: PersistencePhase.ready,
          lastSuccessfulSaveAt: savedAt,
          canRetry: false,
          isDirty: false,
          blocksSaving: false,
          clearError: true,
        ),
      ),
      onFailure: (error, stackTrace) => _setPersistenceStatus(
        _persistenceStatus.copyWith(
          phase: PersistencePhase.saveFailed,
          message: 'Не удалось сохранить изменения',
          errorType: error.runtimeType.toString(),
          debugDetails: '$error\n$stackTrace',
          lastFailureAt: DateTime.now(),
          canRetry: true,
          isDirty: true,
          blocksSaving: false,
        ),
      ),
    );
    if (seedDefaults) {
      _initDefaults();
    }
    _ensureInboxSkill();
    _startResetTimer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    pauseBackgroundWork();
    _saveScheduler.dispose();
    super.dispose();
  }

  void pauseBackgroundWork() {
    _resetTimer?.cancel();
    _resetTimer = null;
    _saveScheduler.cancelPending();
    if (_persistenceStatus.isDirty) {
      unawaited(_runObservedSave());
    }
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

    _ensureInboxSkill();
    _initAchievements();
    _recalculateBestStreakFromTasks();
  }

  Skill _createInboxSkill() {
    return Skill(
      id: kInboxSkillId,
      name: 'Задачник',
      goal: 'Быстрые действия · +10 XP · без RoadMap',
      color: const Color(0xFF34C759),
      icon: Icons.inbox_rounded,
    );
  }

  bool _ensureInboxSkill() {
    final existingIndex = skills.indexWhere(
      (skill) => skill.id == kInboxSkillId,
    );
    if (existingIndex == -1) {
      skills.add(_createInboxSkill());
      return true;
    }

    final inbox = skills[existingIndex];
    var changed = false;
    if (inbox.name != 'Задачник') {
      inbox.name = 'Задачник';
      changed = true;
    }
    if (inbox.goal != 'Быстрые действия · +10 XP · без RoadMap') {
      inbox.goal = 'Быстрые действия · +10 XP · без RoadMap';
      changed = true;
    }
    if (inbox.color != const Color(0xFF34C759)) {
      inbox.color = const Color(0xFF34C759);
      changed = true;
    }
    if (inbox.icon != Icons.inbox_rounded) {
      inbox.icon = Icons.inbox_rounded;
      changed = true;
    }
    if (inbox.level != 1) {
      inbox.level = 1;
      changed = true;
    }
    if (inbox.xp != 0) {
      inbox.xp = 0;
      changed = true;
    }
    if (inbox.checklist.isNotEmpty) {
      inbox.checklist.clear();
      changed = true;
    }
    if (inbox.checklistDone.isNotEmpty) {
      inbox.checklistDone.clear();
      changed = true;
    }
    if (inbox.treeNodes.isNotEmpty) {
      inbox.treeNodes.clear();
      changed = true;
    }
    return changed;
  }

  void _initAchievements() {
    achievements.clear();
    for (final def in achievementDefinitions) {
      achievements.add(Achievement(id: def.id)..def = def);
    }
  }

  Future<void> loadSavedData() async {
    await _loadSavedData(recovering: false);
  }

  Future<bool> retryLoadSavedData() async {
    try {
      await _loadSavedData(recovering: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  void reportStartupStorageFailure(Object error, StackTrace stackTrace) {
    _hasLoadedSavedData = false;
    _setPersistenceStatus(
      _persistenceStatus.copyWith(
        phase: PersistencePhase.loadFailed,
        message: 'Не удалось загрузить данные',
        errorType: error.runtimeType.toString(),
        debugDetails: '$error\n$stackTrace',
        lastFailureAt: DateTime.now(),
        canRetry: true,
        blocksSaving: true,
      ),
    );
  }

  Future<void> _loadSavedData({required bool recovering}) async {
    _setPersistenceStatus(
      _persistenceStatus.copyWith(
        phase: recovering
            ? PersistencePhase.recovering
            : PersistencePhase.loading,
        canRetry: false,
        blocksSaving: true,
        clearError: true,
      ),
    );

    bool needsNormalizationSave;
    try {
      needsNormalizationSave = await _loadSavedDataUnlocked();
    } catch (error, stackTrace) {
      _hasLoadedSavedData = false;
      _setPersistenceStatus(
        _persistenceStatus.copyWith(
          phase: PersistencePhase.loadFailed,
          message: 'Не удалось загрузить данные',
          errorType: error.runtimeType.toString(),
          debugDetails: '$error\n$stackTrace',
          lastFailureAt: DateTime.now(),
          canRetry: true,
          blocksSaving: true,
        ),
      );
      rethrow;
    }

    _hasLoadedSavedData = true;
    _invalidateAnalyticsReadModel();
    _coreWorkspaceRevision++;
    _setPersistenceStatus(
      _persistenceStatus.copyWith(
        phase: PersistencePhase.ready,
        lastSuccessfulLoadAt: DateTime.now(),
        canRetry: false,
        isDirty: needsNormalizationSave,
        blocksSaving: false,
        clearError: true,
      ),
    );

    if (needsNormalizationSave) {
      try {
        await flushSaves();
      } catch (_) {
        // Save status is already observable and retryable; loading succeeded.
      }
    }
  }

  Future<bool> _loadSavedDataUnlocked() async {
    final committed = _storage.supportsSnapshots
        ? await _storage.loadLatestSnapshot()
        : null;
    final snapshot = committed?.snapshot;
    final usedLegacyStorage = snapshot == null;

    late List<Skill> loadedSkills;
    late List<Task> loadedTasks;
    late UserProfile loadedProfile;
    late List<HistoryEntry> loadedHistory;
    late List<Achievement> loadedAchievements;
    late DailyStats? loadedStats;
    late List<Boss> loadedBosses;
    late List<RewardChest> loadedRewardChests;
    late List<Buff> loadedBuffs;
    late List<WeeklyGoal> loadedWeeklyGoals;
    late int? loadedBestStreak;
    late bool hasSavedSkills;
    late bool hasSavedTasks;
    late bool? savedTheme;
    late bool? savedSfxEnabled;
    late bool? savedTooltipsEnabled;
    late bool? savedReducedMotion;
    late bool? savedOnboardingSeen;
    late TutorialProgress? savedTutorialProgress;

    savedReducedMotion = await _storage.loadReducedMotion();
    if (snapshot != null) {
      loadedSkills = snapshot.skills;
      loadedTasks = snapshot.tasks;
      loadedProfile = snapshot.profile;
      loadedHistory = snapshot.history;
      loadedAchievements = snapshot.achievements;
      loadedStats = snapshot.stats;
      loadedBosses = snapshot.bosses;
      loadedRewardChests = snapshot.rewardChests;
      loadedBuffs = snapshot.buffs;
      loadedWeeklyGoals = snapshot.weeklyGoals;
      loadedBestStreak = snapshot.bestStreak;
      hasSavedSkills = true;
      hasSavedTasks = true;
      savedTheme = snapshot.isDark;
      savedSfxEnabled = snapshot.sfxEnabled;
      savedTooltipsEnabled = snapshot.tooltipsEnabled;
      savedOnboardingSeen = snapshot.onboardingSeen;
      savedTutorialProgress = snapshot.tutorialProgress;
    } else {
      loadedSkills = await _storage.loadSkills();
      loadedTasks = await _storage.loadTasks();
      loadedProfile = await _storage.loadProfile();
      loadedHistory = await _storage.loadHistory();
      loadedAchievements = await _storage.loadAchievements();
      loadedStats = await _storage.loadStats();
      loadedBosses = await _storage.loadBosses();
      loadedRewardChests = await _storage.loadRewardChests();
      loadedBuffs = await _storage.loadBuffs();
      loadedWeeklyGoals = await _storage.loadWeeklyGoals();
      loadedBestStreak = await _storage.loadBestStreak();
      hasSavedSkills = await _storage.hasSavedSkills();
      hasSavedTasks = await _storage.hasSavedTasks();
      savedTheme = await _storage.loadTheme();
      savedSfxEnabled = await _storage.loadSfxEnabled();
      savedTooltipsEnabled = await _storage.loadTooltipsEnabled();
      savedOnboardingSeen = await _storage.loadOnboardingSeen();
      savedTutorialProgress = await _storage.loadTutorialProgress();
    }

    if (savedTheme != null) {
      _isDark = savedTheme;
    }
    if (savedSfxEnabled != null) {
      _sfxEnabled = savedSfxEnabled;
    }
    if (savedTooltipsEnabled != null) {
      _tooltipsEnabled = savedTooltipsEnabled;
    }
    if (savedReducedMotion != null) {
      _reducedMotion = savedReducedMotion;
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
      t.normalizeScope();
      if (t.repeatCustomDays < 1) t.repeatCustomDays = 1;
    }
    final inboxSkillChanged = _ensureInboxSkill();

    profile = loadedProfile;
    final protectionChanged = _refillStreakProtectionIfNeeded();

    history
      ..clear()
      ..addAll(loadedHistory);
    _invalidateHistoryCaches();

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
    _syncAllTaskNotifications();
    return changed ||
        protectionChanged ||
        inboxSkillChanged ||
        (usedLegacyStorage && _storage.supportsSnapshots);
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
    _markPersistenceDirty();
    return _saveScheduler.request(immediate: immediate);
  }

  Future<void> flushSaves() => _saveScheduler.flush();

  Future<bool> retrySave() async {
    if (_persistenceStatus.blocksSaving) return false;
    try {
      await flushSaves();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _runObservedSave() async {
    await _saveScheduler.runObserved();
  }

  void _requestObservedImmediateSave() {
    _markPersistenceDirty();
    if (_persistenceStatus.blocksSaving) return;
    unawaited(_runObservedSave());
  }

  Future<void> _writeAllUnlocked() async {
    await _storage.saveReducedMotion(_reducedMotion);
    if (_storage.supportsSnapshots) {
      await _storage.saveSnapshot(_createStorageSnapshot());
      return;
    }
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

  StorageSnapshot _createStorageSnapshot() {
    return StorageSnapshot(
      id: uid(),
      createdAt: DateTime.now(),
      skills: List<Skill>.of(skills),
      tasks: List<Task>.of(tasks),
      profile: profile,
      history: List<HistoryEntry>.of(history),
      achievements: List<Achievement>.of(achievements),
      stats: todayStats ?? DailyStats(date: DateTime.now()),
      bosses: List<Boss>.of(bosses),
      rewardChests: List<RewardChest>.of(rewardChests),
      buffs: List<Buff>.of(buffs),
      weeklyGoals: List<WeeklyGoal>.of(weeklyGoals),
      bestStreak: _bestStreak,
      isDark: _isDark,
      sfxEnabled: _sfxEnabled,
      tooltipsEnabled: _tooltipsEnabled,
      onboardingSeen: _onboardingSeen,
      tutorialProgress: _tutorialProgress,
    );
  }

  void _markPersistenceDirty() {
    if (_persistenceStatus.isDirty) return;
    _setPersistenceStatus(_persistenceStatus.copyWith(isDirty: true));
  }

  void _setPersistenceStatus(PersistenceStatus status) {
    _persistenceStatus = status;
    _notifyViewStateChanged();
  }

  // ── Theme ────────────────────────────────────────────────────────────────────

  void toggleTheme() {
    _isDark = !_isDark;
    _notifyViewStateChanged();
    _requestObservedImmediateSave();
  }

  void toggleSfxEnabled() {
    _sfxEnabled = !_sfxEnabled;
    _applySfxEnabled();
    _notifyViewStateChanged();
    _requestObservedImmediateSave();
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
    _notifyViewStateChanged();
    _requestObservedImmediateSave();
  }

  void toggleReducedMotion() {
    _reducedMotion = !_reducedMotion;
    _notifyViewStateChanged();
    _requestObservedImmediateSave();
  }

  bool isCourseNudgeDismissed(String key) =>
      _dismissedCourseNudgeKeys.contains(key);

  void dismissCourseNudge(String key) {
    if (_reviewSessions.dismissNudge(_dismissedCourseNudgeKeys, key)) {
      _notifyViewStateChanged();
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
    _notifyViewStateChanged();
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
    _notifyViewStateChanged();
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
    _notifyViewStateChanged();
  }

  void dismissTutorialModule(String id) {
    final dismissed = Set<String>.from(_tutorialProgress.dismissedModuleIds)
      ..add(id);
    final clearActive = _effectiveTutorialModuleId == id;
    if (id == TutorialModuleIds.core && !_onboardingSeen) {
      _onboardingSeen = true;
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
    _notifyViewStateChanged();
  }

  void dismissActiveTutorial() {
    final module = _effectiveTutorialModuleId ?? TutorialModuleIds.core;
    dismissTutorialModule(module);
  }

  void resetTutorialProgress() {
    _onboardingReplayRequested = false;
    _onboardingSeen = false;
    _tutorialProgress = const TutorialProgress.empty();
    _persistTutorialProgress();
    _notifyViewStateChanged();
  }

  void _persistTutorialProgress() {
    _requestObservedImmediateSave();
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

  bool get _hasActiveTutorialQuest =>
      tasks.any((task) => task.isSkillTask && !task.isDone);

  String _defaultCoreTutorialStep() {
    if (roadmapSkills.isEmpty) return TutorialStepIds.coreCreateSkill;
    if (_hasActiveTutorialQuest) return TutorialStepIds.coreCompleteQuest;
    return TutorialStepIds.coreCreateQuest;
  }

  String _normalizedCoreTutorialStep(String stepId) {
    if (stepId == TutorialStepIds.coreCreateSkill && roadmapSkills.isNotEmpty) {
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
        t.isArchived = false;
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
        final reset = advanceRecurringReset(
          nextResetAt: t.nextResetAt!,
          now: now,
          frequency: t.repeatFrequency,
          customDays: t.repeatCustomDays,
        );
        final missedPeriods = reset.elapsedPeriods;
        t.nextResetAt = reset.nextResetAt;

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
    final weekStart = startOfWeek(now);
    final refilledAt = profile.streakProtectionRefilledAt;
    final refilledWeek = refilledAt == null ? null : startOfWeek(refilledAt);
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
      _commitMutation();
    }
  }

  // ── Queries ──────────────────────────────────────────────────────────────────

  List<Task> get inboxTasks => tasks.where((task) => task.isInbox).toList();

  List<Skill> get roadmapSkills =>
      skills.where((skill) => skill.id != kInboxSkillId).toList();

  List<Task> tasksForSkill(String id) => id == kInboxSkillId
      ? inboxTasks
      : tasks.where((t) => t.isSkillTask && t.skillId == id).toList();

  List<Task> tasksForTreeNode(String skillId, String nodeId) => tasks
      .where(
        (task) =>
            task.isSkillTask &&
            task.skillId == skillId &&
            task.treeNodeId == nodeId,
      )
      .toList();

  int completedTasksForTreeNode(String skillId, String nodeId) =>
      tasksForTreeNode(skillId, nodeId).where((task) => task.isDone).length;

  ({List<Task> active, List<Task> completed}) taskSectionsForSkill(
    String skillId,
  ) {
    final active = <Task>[], completed = <Task>[];
    for (final t in tasks) {
      if (!t.isSkillTask || t.skillId != skillId) continue;
      (t.isDone ? completed : active).add(t);
    }
    return (active: active, completed: completed);
  }

  int activeTaskCountForSkill(String skillId) =>
      tasksForSkill(skillId).where((task) => !task.isDone).length;

  Map<DateTime, List<HistoryEntry>> get completionHistoryByDate =>
      _completionHistoryIndex.resolve(history).byDate;

  List<HistoryEntry> completionHistoryForDate(DateTime date) {
    return _completionHistoryIndex.forDate(history, date);
  }

  bool hasCompletionOnDate(DateTime date) {
    return _completionHistoryIndex.hasCompletionOnDate(history, date);
  }

  HistoryEntry? get latestRecordedCompletion =>
      _completionHistoryIndex.resolve(history).latestRecordedCompletion;

  AnalyticsReadModel analyticsForWeek(DateTime weekStart) {
    return _analyticsReadModelCache.resolve(
      epoch: _analyticsEpoch,
      weekStart: weekStart,
      build: (normalizedWeekStart) {
        final completionSnapshot = _completionHistoryIndex.resolve(history);
        return AnalyticsReadModel.build(
          weekStart: normalizedWeekStart,
          completionHistoryByDate: completionSnapshot.byDate,
          skills: skills,
          tasks: tasks,
          todayStats: todayStats,
          totalCompletions: completionSnapshot.totalCompletions,
        );
      },
    );
  }

  AnalyticsReadModel get currentAnalytics => analyticsForWeek(DateTime.now());

  void _invalidateHistoryCaches() {
    _completionHistoryIndex.invalidate();
  }

  void _invalidateAnalyticsReadModel() {
    _analyticsEpoch++;
    _analyticsReadModelCache.invalidate();
  }

  void _notifyViewStateChanged() {
    if (!_isDisposed) super.notifyListeners();
  }

  void _commitMutation({
    bool affectsAnalytics = true,
    bool affectsCoreWorkspaces = true,
    bool invalidatesHistory = false,
    bool persist = true,
  }) {
    if (invalidatesHistory) {
      _invalidateHistoryCaches();
    }
    if (affectsAnalytics) {
      _invalidateAnalyticsReadModel();
    }
    if (affectsCoreWorkspaces) {
      _coreWorkspaceRevision++;
    }
    _notifyViewStateChanged();
    if (persist) _saveAll();
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
    final normalizedStart = startOfWeek(weekStart);
    return weeklyGoals
        .where((goal) => isSameDate(goal.weekStart, normalizedStart))
        .firstOrNull;
  }

  void saveWeeklyGoal({
    required DateTime weekStart,
    required String title,
    required List<WeeklyKeyResult> keyResults,
  }) {
    final changed = _reviewSessions.saveWeeklyGoal(
      goals: weeklyGoals,
      weekStart: weekStart,
      title: title,
      keyResults: keyResults,
      idFactory: uid,
      now: DateTime.now(),
    );
    if (changed) {
      _commitMutation(affectsAnalytics: false, affectsCoreWorkspaces: false);
    }
  }

  void toggleWeeklyKeyResult(String goalId, String keyResultId) {
    final changed = _reviewSessions.toggleWeeklyKeyResult(
      goals: weeklyGoals,
      goalId: goalId,
      keyResultId: keyResultId,
      now: DateTime.now(),
    );
    if (changed) {
      _commitMutation(affectsAnalytics: false, affectsCoreWorkspaces: false);
    }
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

  List<GoalMilestoneEvent> consumeGoalMilestoneNotifications() {
    final result = List<GoalMilestoneEvent>.of(
      _pendingGoalMilestoneNotifications,
    );
    _pendingGoalMilestoneNotifications.clear();
    return result;
  }

  Skill? get selectedSkill {
    if (selectedSkillId == null) return null;
    return _skillById(selectedSkillId!);
  }

  int get activeSkillCount => roadmapSkills.length;

  int previewEarnedXP(Task task) {
    return _taskCompletions.baseEarnedFor(task);
  }

  int previewBuffBonusXP(Task task) {
    final baseEarned = previewEarnedXP(task);
    if (baseEarned <= 0 || task.isDone) return 0;
    return _previewBuffOutcome(task, baseEarned).bonusXp;
  }

  int previewMinimumActionXP(Task task) {
    return _taskCompletions.previewMinimumActionXp(
      task,
      ratio: _minimumActionRatio,
    );
  }

  bool canCompleteMinimumAction(Task task) {
    return _taskCompletions.canCompleteMinimumAction(task);
  }

  String? openRewardChest(String chestId) {
    final buff = _rewardMutations.openChest(
      chestId: chestId,
      rewardChests: rewardChests,
      buffs: buffs,
      random: _random,
      skillById: _skillById,
    );
    if (buff == null) return null;
    final chest = rewardChests.firstWhere((item) => item.id == chestId);

    _commitMutation(affectsAnalytics: false);

    return '🎁 ${chest.title}: ${buff.title}';
  }

  // ── Task completion ──────────────────────────────────────────────────────────

  String? completeTask(String taskId) {
    final hadResetChanges = _resetExpiredTasks();
    final task = _taskById(taskId);
    if (task == null || task.isDone) {
      if (hadResetChanges) {
        _commitMutation();
      }
      return null;
    }
    if (task.isInbox) return _completeInboxTask(task);

    final now = DateTime.now();
    final skillId = task.skillId;
    final skill = _skillById(skillId);
    final bossMomentsBefore = _bossMomentsForSkill(skillId);
    final baseEarned = _taskCompletions.baseEarnedFor(task);
    final buffOutcome = _consumeBuffsForTask(task, baseEarned);
    final result = _taskCompletions.completeTask(
      task: task,
      skill: skill,
      profile: profile,
      bonusXp: buffOutcome.bonusXp,
      consumedBuffIds: buffOutcome.buffIds,
      currentBestStreak: _bestStreak,
      now: now,
    );
    _bestStreak = result.bestStreak;
    _maybeUnlockStreakRewardChest(task);

    _updateDailyStats(result.earnedXp, result.skillLevelsGained);
    _addHistory(task, skill, result.earnedXp, isCompletion: true);
    _maybeGrantBehaviorBuffs(task);
    _checkAchievements();
    _checkBosses(task);
    _completeCoreTutorialAfterFirstAction();
    final bossFeedback = _bossFeedbackForSkill(skillId, bossMomentsBefore);
    _syncTaskNotification(task);
    _commitMutation();

    return _xpMessage(
      skill,
      result.profileLevelsGained,
      result.skillLevelsGained,
      result.earnedXp,
      bonusXp: result.bonusXp,
      bossFeedback: bossFeedback,
    );
  }

  String _completeInboxTask(Task task) {
    final now = DateTime.now();
    final result = _taskCompletions.completeInboxTask(
      task: task,
      profile: profile,
      earnedXp: inboxTaskXp,
      currentBestStreak: _bestStreak,
      now: now,
    );
    _updateInboxDailyStats(inboxTaskXp);
    _syncTaskNotification(task);
    _commitMutation();
    return result.profileLevelsGained > 0
        ? '+$inboxTaskXp XP · новый уровень профиля'
        : '+$inboxTaskXp XP · быстрое действие';
  }

  String? completeMinimumAction(String taskId) {
    final hadResetChanges = _resetExpiredTasks();
    final task = _taskById(taskId);
    if (task == null || !canCompleteMinimumAction(task)) {
      if (hadResetChanges) {
        _commitMutation();
      }
      return null;
    }

    final now = DateTime.now();
    final skillId = task.skillId;
    final skill = _skillById(skillId);
    final bossMomentsBefore = _bossMomentsForSkill(skillId);
    final earned = previewMinimumActionXP(task);
    final result = _taskCompletions.completeMinimumAction(
      task: task,
      skill: skill,
      profile: profile,
      earnedXp: earned,
      currentBestStreak: _bestStreak,
      now: now,
    );
    _bestStreak = result.bestStreak;
    _maybeUnlockStreakRewardChest(task);

    if (task.type == TaskType.repeating) {
      _updateDailyStats(earned, result.skillLevelsGained);
      _addHistory(task, skill, earned, isCompletion: true);
    } else {
      _updateDailyXp(earned, result.skillLevelsGained);
    }

    _checkBosses(task);
    final bossFeedback = _bossFeedbackForSkill(skillId, bossMomentsBefore);
    _checkAchievements();
    _completeCoreTutorialAfterFirstAction();
    _syncTaskNotification(task);
    _commitMutation();

    return _xpMessage(
      skill,
      result.profileLevelsGained,
      result.skillLevelsGained,
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

  void _updateInboxDailyStats(int xp) {
    _resetDailyStatsIfNeeded();
    todayStats!.tasksCompleted++;
    todayStats!.xpEarned += xp;
  }

  void _resetDailyStatsIfNeeded() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (todayStats == null || !isSameDate(todayStats!.date, today)) {
      todayStats = DailyStats(date: today);
    }
  }

  void _checkAchievements() {
    final snapshot = _buildAchievementSnapshot();
    for (final id in _achievementEngine.achievementIdsFor(snapshot)) {
      _unlockAchievement(id, true);
    }
  }

  AchievementEngineSnapshot _buildAchievementSnapshot() {
    return AchievementEngineSnapshot(
      totalTasksCompleted: totalTasksCompleted,
      bestStreak: _bestStreak,
      profileLevel: profile.level,
      skillsCount: skills.length,
      hasFullyCompletedChecklist: _hasFullyCompletedChecklist(),
    );
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
    if (!task.isSkillTask) return;
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
    final now = DateTime.now();
    final skillId = task.skillId;
    final skill = task.isInbox ? null : _skillById(skillId);
    final result = _taskCompletions.undo(
      task: task,
      skill: skill,
      profile: profile,
      now: now,
    );
    _restoreConsumedBuffs(result.consumedBuffIds);

    if (result.completedToday) {
      _decrementDailyStats(result.earnedXp, result.skillLevelsLost);
    }
    if (!task.isInbox) {
      _addHistory(task, skill, result.earnedXp, isCompletion: false);
      _syncBossesForSkill(skillId);
      _rollbackInvalidRewardsAfterUndo(
        task,
        completedAt: result.completedAt,
        previousStreak: result.previousStreak,
      );
    }
    _syncTaskNotification(task);
    _commitMutation();
  }

  void archiveCompletedTask(String taskId) {
    final task = _taskById(taskId);
    if (task == null || task.isInbox || !task.isDone || task.isArchived) return;
    task.isArchived = true;
    task.updatedAt = DateTime.now();
    _commitMutation();
  }

  void restoreArchivedTask(String taskId) {
    final task = _taskById(taskId);
    if (task == null || !task.isArchived) return;
    task.isArchived = false;
    task.updatedAt = DateTime.now();
    _commitMutation();
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
    _commitMutation();
  }

  // ── Profile updates ──────────────────────────────────────────────────────────

  void updateProfileName(String name) {
    if (name.trim().isEmpty) return;
    profile.name = name.trim();
    _commitMutation(affectsAnalytics: false, affectsCoreWorkspaces: false);
  }

  void updateProfileAge(int? age) {
    profile.age = age;
    _commitMutation(affectsAnalytics: false, affectsCoreWorkspaces: false);
  }

  void updateProfileGender(Gender? gender) {
    profile.gender = gender;
    _commitMutation(affectsAnalytics: false, affectsCoreWorkspaces: false);
  }

  void updateProfileAvatar(Uint8List? bytes) {
    if (bytes != null && !hasSupportedImageMagicBytes(bytes)) return;
    profile.avatarBytes = bytes;
    _commitMutation(affectsAnalytics: false, affectsCoreWorkspaces: false);
  }

  void updateProfileBanner(Uint8List? bytes) {
    if (bytes != null && !hasSupportedImageMagicBytes(bytes)) return;
    profile.bannerBytes = bytes;
    _commitMutation(affectsAnalytics: false, affectsCoreWorkspaces: false);
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  void selectSkill(String id) {
    final result = _reviewSessions.select(
      currentSkillId: selectedSkillId,
      requestedSkillId: id,
      skills: skills,
      toggle: true,
    );
    if (result.changed) _setSelectedSkill(result.skillId);
  }

  void clearSkillSelection() {
    _setSelectedSkill(null);
  }

  void _setSelectedSkill(String? id) {
    if (selectedSkillId == id) return;
    selectedSkillId = id;
    _notifyViewStateChanged();
  }

  void addSkill(Skill s) {
    if (!_skillGoalMutations.add(skills: skills, skill: s)) return;
    _ensureInboxSkill();
    _checkAchievements();
    _commitMutation();
  }

  void reorderSkills(int oldIndex, int newIndex) {
    final changed = _skillGoalMutations.reorder(
      skills: skills,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    if (changed) _commitMutation();
  }

  void updateSkill(
    Skill skill, {
    required String name,
    required String goal,
    required List<String> checklist,
    required Color color,
    required IconData icon,
  }) {
    final changed = _skillGoalMutations.update(
      skill: skill,
      name: name,
      goal: goal,
      checklist: checklist,
    );
    if (!changed) return;
    skill.color = color;
    skill.icon = icon;
    _checkAchievements();
    _commitMutation();
  }

  NextGoalUpdateResult setNextSkillGoal(
    String skillId,
    String nextGoal, {
    DateTime? completedAt,
  }) {
    final result = _skillGoalMutations.setNextGoal(
      skill: _skillById(skillId),
      nextGoal: nextGoal,
      idFactory: uid,
      completedAt: completedAt ?? DateTime.now(),
    );
    if (result == NextGoalUpdateResult.updated) {
      _commitMutation();
    }
    return result;
  }

  StartNewRoadmapResult startNewRoadmapForNextGoal(String skillId) {
    final skill = _skillById(skillId);
    final result = _skillGoalMutations.startNewRoadmap(
      skill: skill,
      tasks: tasks,
      idFactory: uid,
      now: DateTime.now(),
    );
    if (result == StartNewRoadmapResult.created) {
      _syncBossesForSkill(skillId);
      _commitMutation();
    }
    return result;
  }

  void addGoalReview(String skillId, GoalReviewEntry review) {
    final changed = _reviewSessions.addGoalReview(
      skill: _skillById(skillId),
      review: review,
      now: DateTime.now(),
    );
    if (changed) _commitMutation();
  }

  void addSkillTreeNode(String skillId, SkillTreeNode node) {
    final skill = _skillById(skillId);
    if (skill == null) return;
    _roadmapMutations.addStage(skill, node);
    _syncBossesForSkill(skillId);
    _commitMutation();
  }

  bool canReorderRoadmapPath(String skillId, Iterable<String> nodeIds) {
    final skill = _skillById(skillId);
    if (skill == null) return false;
    return _roadmapMutations.canReorderPath(skill, nodeIds);
  }

  bool reorderRoadmapPath(String skillId, List<String> orderedNodeIds) {
    final skill = _skillById(skillId);
    if (skill == null ||
        !_roadmapMutations.reorderPath(skill, orderedNodeIds)) {
      return false;
    }
    _syncBossesForSkill(skillId);
    _commitMutation();
    return true;
  }

  void addRoadmapTemplate(String skillId, RoadmapTemplateConfig config) {
    applyRoadmapTemplate(skillId, config);
  }

  void applyRoadmapTemplate(String skillId, RoadmapTemplateConfig config) {
    final skill = _skillById(skillId);
    if (skill == null ||
        !_roadmapMutations.applyTemplate(skill, tasks, config)) {
      return;
    }
    _syncBossesForSkill(skillId);
    _commitMutation();
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
    final node = _roadmapMutations.extendPath(
      skill,
      pathNodeId,
      title: title,
      description: description,
      xpReward: xpReward,
      requiredQuestCompletions: requiredQuestCompletions,
    );
    if (node == null) return null;
    _syncBossesForSkill(skillId);
    _commitMutation();
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
    final node = _roadmapMutations.insertStageAfter(
      skill,
      leftNodeId,
      beforeNodeId: beforeNodeId,
      title: title,
      description: description,
      xpReward: xpReward,
      requiredQuestCompletions: requiredQuestCompletions,
    );
    if (node == null) return null;
    _syncBossesForSkill(skillId);
    _commitMutation();
    return node;
  }

  void updateSkillTreeNodePracticeTarget(
    String skillId,
    String nodeId,
    int requiredQuestCompletions, {
    int? xpReward,
  }) {
    final skill = _skillById(skillId);
    if (skill == null ||
        !_roadmapMutations.updatePracticeTarget(
          skill,
          nodeId,
          requiredQuestCompletions,
          xpReward: xpReward,
        )) {
      return;
    }
    _syncBossesForSkill(skillId);
    _commitMutation();
  }

  void renameSkillTreeNode(String skillId, String nodeId, String title) {
    final skill = _skillById(skillId);
    if (skill == null || !_roadmapMutations.renameStage(skill, nodeId, title)) {
      return;
    }
    _syncBossesForSkill(skillId);
    _commitMutation();
  }

  void removeSkillTreeNode(String skillId, String nodeId) {
    final skill = _skillById(skillId);
    if (skill == null ||
        !_roadmapMutations.removeStage(
          skill,
          tasks,
          nodeId,
          now: DateTime.now(),
        )) {
      return;
    }
    _syncBossesForSkill(skillId);
    _commitMutation();
  }

  void toggleSkillTreeNodeChecklist(String skillId, String nodeId, int index) {
    final skill = _skillById(skillId);
    if (skill == null ||
        !_roadmapMutations.toggleChecklist(skill, nodeId, index)) {
      return;
    }
    _syncBossesForSkill(skillId);
    _commitMutation();
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

  void _queueGoalMilestones({
    required Skill skill,
    required double oldProgress,
    required double newProgress,
  }) {
    final crossed = _goalMilestoneEngine.crossedMilestones(
      oldProgress: oldProgress,
      newProgress: newProgress,
      alreadyTriggered: skill.triggeredGoalMilestones,
    );
    if (crossed.isEmpty) return;

    for (final milestone in crossed) {
      if (!skill.triggeredGoalMilestones.contains(milestone.percent)) {
        skill.triggeredGoalMilestones.add(milestone.percent);
      }
    }

    final strongest = crossed.last;
    _pendingGoalMilestoneNotifications.add(
      GoalMilestoneEvent(
        id: uid(),
        skillId: skill.id,
        skillName: skill.name,
        skillColor: skill.color,
        milestone: strongest,
      ),
    );
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
    final oldProgress = const GoalProgressEngine()
        .snapshotForSkill(skill)
        .value;

    node.isMastered = true;
    node.masteredAt = DateTime.now();
    final newProgress = const GoalProgressEngine()
        .snapshotForSkill(skill)
        .value;
    _queueGoalMilestones(
      skill: skill,
      oldProgress: oldProgress,
      newProgress: newProgress,
    );

    profile.totalXpEarned += earned;
    final globalUp = profile.addXP(earned);
    final skillUp = skill.addXP(earned);

    _updateDailyXp(earned, skillUp);
    _syncBossesForSkill(skillId);
    final bossFeedback = _bossFeedbackForSkill(skillId, bossMomentsBefore);
    _checkAchievements();
    _commitMutation();

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
    final result = _skillGoalMutations.remove(
      skillId: id,
      skills: skills,
      tasks: tasks,
      bosses: bosses,
      rewardChests: rewardChests,
      buffs: buffs,
      selectedSkillId: selectedSkillId,
    );
    if (!result.changed) return;
    for (final taskId in result.removedTaskIds) {
      _notifications.cancelNotification(_notificationId(taskId));
    }
    if (result.clearsSelection) selectedSkillId = null;
    _commitMutation();
  }

  void addTask(Task t) {
    _taskMutations.add(
      tasks: tasks,
      skills: skills,
      task: t,
      now: DateTime.now(),
    );
    if (t.isSkillTask) _completeOnboardingAfterFirstTask();
    _syncTaskNotification(t);
    _commitMutation();
  }

  bool addInboxTask(String title, {String description = ''}) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) return false;
    _ensureInboxSkill();
    addTask(
      Task(
        id: uid(),
        title: normalizedTitle,
        description: description,
        skillId: kInboxSkillId,
        xpReward: 0,
        type: TaskType.shortTerm,
        priority: Priority.medium,
      ),
    );
    return true;
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
    final result = _taskMutations.update(
      task: task,
      skills: skills,
      data: TaskUpdateData(
        title: title,
        description: description,
        xpReward: xpReward,
        type: type,
        repeatFrequency: repeatFrequency,
        repeatCustomDays: repeatCustomDays,
        priority: priority,
        minimumAction: minimumAction,
        subtasks: subtasks,
        tags: tags,
        notificationsEnabled: notificationsEnabled,
        notificationHour: notificationHour,
        notificationMinute: notificationMinute,
        treeNodeId: treeNodeId,
      ),
      now: DateTime.now(),
    );
    if (result.skillIdToSync case final skillId?) {
      _syncBossesForSkill(skillId);
    }
    if (result.notificationWasDisabled) {
      _notifications.cancelNotification(_notificationId(task.id));
    }
    _syncTaskNotification(task);
    _commitMutation();
  }

  void removeTask(String id) {
    final task = _taskMutations.remove(tasks, id);
    if (task == null) return;
    _notifications.cancelNotification(_notificationId(task.id));
    if (task.isSkillTask) {
      _syncBossesForSkill(task.skillId);
    }
    _commitMutation();
  }

  void toggleSubtask(String taskId, int index) {
    final task = _taskById(taskId);
    if (task == null ||
        !_taskMutations.toggleSubtask(task, index, now: DateTime.now())) {
      return;
    }
    _commitMutation();
  }

  // ── Bosses ──────────────────────────────────────────────────────────────────

  void addBoss(Boss b) {
    bosses.add(b);
    _syncBossesForSkill(b.skillId);
    _commitMutation(affectsAnalytics: false, affectsCoreWorkspaces: false);
  }

  void removeBoss(String id) {
    final previousLength = bosses.length;
    bosses.removeWhere((b) => b.id == id);
    if (bosses.length == previousLength) return;
    _commitMutation(affectsAnalytics: false, affectsCoreWorkspaces: false);
  }

  // ── Statistics helpers ───────────────────────────────────────────────────────

  int get totalTasksCompleted =>
      _completionHistoryIndex.resolve(history).totalCompletions;

  int get bestStreak => _bestStreak;

  void normalizeAfterBulkStateChange({bool resetBestStreak = false}) {
    _ensureInboxSkill();
    for (final skill in skills) {
      skill.syncChecklistDone();
      skill.syncTreeNodes();
    }
    final validSkillIds = skills.map((skill) => skill.id).toSet();
    for (final task in tasks) {
      task.syncSubtaskDone();
      task.normalizeScope();
      if (task.isInbox) {
        task.treeNodeId = null;
      } else if (!task.isSkillTask || !validSkillIds.contains(task.skillId)) {
        task.skillId = kInboxSkillId;
        task.normalizeScope();
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
    _syncAllBosses();
    _checkAchievements();
    _syncAllTaskNotifications();
    _commitMutation(invalidatesHistory: true);
  }

  void refresh() {
    // Legacy callers may mutate public model collections before asking the
    // facade to refresh, so this remains a conservative domain boundary.
    _commitMutation();
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  ({int bonusXp, int bonusPercent}) _previewBuffOutcome(
    Task task,
    int baseEarned,
  ) {
    return _rewardMutations.previewBuffOutcome(
      buffs: buffs,
      task: task,
      baseEarned: baseEarned,
    );
  }

  ({int bonusXp, int bonusPercent, List<String> buffIds}) _consumeBuffsForTask(
    Task task,
    int baseEarned,
  ) {
    return _rewardMutations.consumeBuffsForTask(
      buffs: buffs,
      task: task,
      baseEarned: baseEarned,
    );
  }

  void _maybeUnlockDailyRewardChest({bool notify = true}) {
    _rewardMutations.unlockDailyRewardChests(
      stats: todayStats,
      rewardChests: rewardChests,
      pendingNotifications: _pendingRewardNotifications,
      notify: notify,
    );
  }

  void _maybeUnlockStreakRewardChest(Task task, {bool notify = true}) {
    _rewardMutations.unlockStreakRewardChest(
      task: task,
      rewardChests: rewardChests,
      pendingNotifications: _pendingRewardNotifications,
      notify: notify,
    );
  }

  void _maybeGrantBehaviorBuffs(Task task) {
    final stats = todayStats;
    _rewardMutations.grantBehaviorBuffs(
      task: task,
      stats: stats,
      completions: stats == null
          ? const <HistoryEntry>[]
          : completionHistoryForDate(stats.date),
      buffs: buffs,
      pendingNotifications: _pendingBuffNotifications,
    );
  }

  void _unlockRewardChest({
    required String sourceKey,
    required String title,
    required String description,
    required RewardRarity rarity,
    String? skillId,
    bool notify = true,
  }) {
    _rewardMutations.unlockRewardChest(
      rewardChests: rewardChests,
      pendingNotifications: _pendingRewardNotifications,
      sourceKey: sourceKey,
      title: title,
      description: description,
      rarity: rarity,
      skillId: skillId,
      notify: notify,
    );
  }

  void _restoreConsumedBuffs(List<String> buffIds) {
    _rewardMutations.restoreConsumedBuffs(buffs: buffs, buffIds: buffIds);
  }

  void _rollbackInvalidRewardsAfterUndo(
    Task task, {
    required DateTime? completedAt,
    required int previousStreak,
  }) {
    if (!task.isSkillTask) return;
    final skillId = task.skillId;
    final sourceKeys = <String>{};

    if (completedAt != null) {
      final dayKey = _rewardMutations.dayKey(completedAt);
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
      if (!_hasFocusRewardCondition(completedAt, skillId)) {
        sourceKeys.add('focus:$dayKey:$skillId');
      }
    }

    if (previousStreak == 7 || previousStreak == 30) {
      sourceKeys.add('streak:${task.id}:$previousStreak');
    }

    for (final boss in bosses.where((boss) => boss.skillId == skillId)) {
      if (!boss.isDefeated) {
        sourceKeys.add('boss:${boss.id}');
      }
    }

    _rewardMutations.removeSources(
      sourceKeys: sourceKeys,
      rewardChests: rewardChests,
      buffs: buffs,
      tasks: tasks,
      pendingRewardNotifications: _pendingRewardNotifications,
      pendingBuffNotifications: _pendingBuffNotifications,
    );
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

    unawaited(_scheduleTaskNotificationIfCurrent(task.id, notificationId));
  }

  Future<void> _scheduleTaskNotificationIfCurrent(
    String taskId,
    int notificationId,
  ) async {
    try {
      final granted = await _notifications.requestPermissions();
      if (!granted) return;

      final task = _taskById(taskId);
      final hour = task?.notificationHour;
      final minute = task?.notificationMinute;
      if (task == null ||
          !task.notificationsEnabled ||
          task.isDone ||
          hour == null ||
          minute == null) {
        return;
      }

      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (!scheduledTime.isAfter(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      if (task.type == TaskType.repeating) {
        await _notifications.scheduleRepeatingTask(
          id: notificationId,
          title: 'Напоминание о квесте',
          body: 'Пора выполнить повторяющийся квест.',
          scheduledTime: scheduledTime,
          repeatMode: _repeatNotificationMode(task),
        );
      } else {
        await _notifications.scheduleTaskReminder(
          id: notificationId,
          title: 'Напоминание о квесте',
          body: 'Не забудь выполнить квест.',
          scheduledTime: scheduledTime,
        );
      }
    } catch (_) {
      // Notification plugins are optional and must not break task mutations.
    }
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
