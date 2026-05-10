import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models.dart';
import 'utils.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class AppState extends ChangeNotifier {
  static const double _minimumActionRatio = 0.3;

  bool _isDark = true;
  String? selectedSkillId;
  final StorageService _storage;
  final NotificationService _notifications;
  final math.Random _random;
  Timer? _resetTimer;

  bool get isDark => _isDark;

  UserProfile profile = UserProfile(name: 'Your Name');
  final List<HistoryEntry> history = [];
  final List<Skill> skills = [];
  final List<Task> tasks = [];
  final List<Achievement> achievements = [];
  final List<Boss> bosses = [];
  final List<RewardChest> rewardChests = [];
  final List<Buff> buffs = [];
  final List<RewardChest> _pendingRewardNotifications = [];
  final List<Buff> _pendingBuffNotifications = [];
  DailyStats? todayStats;

  int _bestStreak = 0;

  AppState({
    required StorageService storage,
    NotificationService? notifications,
    math.Random? random,
  }) : _storage = storage,
       _notifications = notifications ?? NotificationService(),
       _random = random ?? math.Random() {
    _initDefaults();
    _resetTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => checkResets(),
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
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
            checklist: ['Полная амплитуда', 'Без рывков'],
          ),
          SkillTreeNode(
            id: pullVolume,
            title: 'Рабочий объём',
            description: 'Собрать базу для выхода на 20 повторений.',
            xpReward: 40,
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
            checklist: ['Функции', 'Модули', 'Виртуальное окружение'],
          ),
          SkillTreeNode(
            id: pythonApi,
            title: 'FastAPI CRUD',
            description: 'Первый рабочий API с роутами и моделями.',
            xpReward: 60,
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
            checklist: ['Квесты', 'XP', 'Профиль'],
          ),
          SkillTreeNode(
            id: gamificationRewards,
            title: 'Rewards layer',
            description: 'Сундуки, баффы и приятное усиление прогресса.',
            xpReward: 55,
            prerequisiteIds: [gamificationLoop],
            checklist: ['Сундуки', 'Баффы', 'Уведомления'],
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
      ),
      Task(
        id: uid(),
        title: 'Выйти на 15 подтягиваний за сет',
        skillId: skills[0].id,
        xpReward: 100,
        type: TaskType.longTerm,
      ),
      Task(
        id: uid(),
        title: 'Пройти урок: функции и замыкания',
        skillId: skills[1].id,
        xpReward: 20,
        type: TaskType.shortTerm,
      ),
      Task(
        id: uid(),
        title: 'Написать REST API на FastAPI',
        skillId: skills[1].id,
        xpReward: 60,
        type: TaskType.midTerm,
        minimumAction: 'Создать первый endpoint и проверить ответ 200 OK',
      ),
      Task(
        id: uid(),
        title: 'Написать концепцию монетизации',
        skillId: skills[2].id,
        xpReward: 50,
        type: TaskType.midTerm,
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
    final hasSavedSkills = await _storage.hasSavedSkills();
    final hasSavedTasks = await _storage.hasSavedTasks();
    final savedTheme = await _storage.loadTheme();

    if (savedTheme != null) {
      _isDark = savedTheme;
    }

    if (hasSavedSkills || loadedSkills.isNotEmpty) {
      skills.clear();
      skills.addAll(loadedSkills);
    }
    for (final s in skills) {
      s.syncChecklistDone();
      s.syncTreeNodes();
    }

    if (hasSavedTasks || loadedTasks.isNotEmpty) {
      tasks.clear();
      tasks.addAll(loadedTasks);
    }
    for (final t in tasks) {
      t.syncSubtaskDone();
      if (t.repeatCustomDays < 1) t.repeatCustomDays = 1;
    }

    profile = loadedProfile;

    if (loadedHistory.isNotEmpty) {
      history.clear();
      history.addAll(loadedHistory);
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

    todayStats = loadedStats;
    _resetDailyStatsIfNeeded();
    _maybeUnlockDailyRewardChest(notify: false);

    bosses.clear();
    bosses.addAll(loadedBosses);

    if (selectedSkillId != null && _skillById(selectedSkillId!) == null) {
      selectedSkillId = null;
    }

    _recalculateBestStreakFromTasks();
    final changed = _resetExpiredTasks();
    _syncAllBosses();
    _checkAchievements();
    if (changed) {
      await _saveAll();
    }

    for (final task in tasks) {
      _syncTaskNotification(task);
    }

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

  Future<void> _saveAll() async {
    await _storage.saveTheme(_isDark);
    await _storage.saveSkills(skills);
    await _storage.saveTasks(tasks);
    await _storage.saveProfile(profile);
    await _storage.saveHistory(history);
    await _storage.saveAchievements(achievements);
    await _storage.saveStats(todayStats ?? DailyStats(date: DateTime.now()));
    await _storage.saveBosses(bosses);
    await _storage.saveRewardChests(rewardChests);
    await _storage.saveBuffs(buffs);
  }

  // ── Theme ────────────────────────────────────────────────────────────────────

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
    _storage.saveTheme(_isDark);
  }

  // ── Resets ───────────────────────────────────────────────────────────────────

  bool _resetExpiredTasks() {
    final now = DateTime.now();
    var changed = false;

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
        t.nextResetAt = nextResetFrom(
          resetFrom,
          t.repeatFrequency,
          t.repeatCustomDays,
        );
        changed = true;
      }

      if (!t.isDone && t.nextResetAt != null) {
        var missedPeriod = false;
        var guard = 0;
        while (!now.isBefore(t.nextResetAt!) && guard < 3700) {
          missedPeriod = true;
          t.nextResetAt = nextResetFrom(
            t.nextResetAt!,
            t.repeatFrequency,
            t.repeatCustomDays,
          );
          guard++;
        }

        if (missedPeriod) {
          if (t.streak != 0) {
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

  void checkResets() {
    if (_resetExpiredTasks()) {
      notifyListeners();
      _saveAll();
    }
  }

  // ── Queries ──────────────────────────────────────────────────────────────────

  List<Task> tasksForSkill(String id) =>
      tasks.where((t) => t.skillId == id).toList();

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
    final orderedHistory = [...history]..sort((a, b) => a.at.compareTo(b.at));
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

    return completionsByDate;
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
    final profileRankBefore = profileRankForLevel(profile.level);
    final skillRankBefore = skill != null
        ? skillRankForLevel(skill.level)
        : null;
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
    _syncTaskNotification(task);
    notifyListeners();
    _saveAll();

    return _xpMessage(
      skill,
      globalUp,
      skillUp,
      earned,
      bonusXp: buffOutcome.bonusXp,
      profileRankBefore: profileRankBefore,
      skillRankBefore: skillRankBefore,
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
    final profileRankBefore = profileRankForLevel(profile.level);
    final skillRankBefore = skill != null
        ? skillRankForLevel(skill.level)
        : null;
    final earned = previewMinimumActionXP(task);
    final nextStreak = task.type == TaskType.repeating
        ? task.streak + 1
        : task.streak;

    task.minimumActionDoneAt = now;
    task.minimumActionEarnedXP = earned;
    task.bonusXpEarned = 0;
    task.consumedBuffIds = const <String>[];

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
    _checkAchievements();
    _syncTaskNotification(task);
    notifyListeners();
    _saveAll();

    return _xpMessage(
      skill,
      globalUp,
      skillUp,
      earned,
      bonusXp: 0,
      profileRankBefore: profileRankBefore,
      skillRankBefore: skillRankBefore,
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
    for (final boss in bosses) {
      if (boss.skillId != skillId || boss.isDefeated) continue;
      final snapshot = _buildBossSnapshot(boss);
      boss.currentStreak = snapshot.currentStreak;
      boss.hp = ((1 - snapshot.impactProgress) * boss.maxHp).round().clamp(
        0,
        boss.maxHp,
      );

      if (boss.hp <= 0 || snapshot.impactProgress >= 0.999) {
        boss.isDefeated = true;
        boss.defeatedAt = DateTime.now();
        boss.hp = 0;
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
              'Награда за победу над боссом ${boss.title}. Внутри усиление для следующего рывка.',
          rarity: rarity,
          skillId: boss.skillId,
        );
      }
    }
  }

  void uncompleteTask(String taskId) {
    final task = _taskById(taskId);
    if (task == null || !task.isDone) return;

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
    profile.avatarBytes = bytes;
    notifyListeners();
    _saveAll();
  }

  void updateProfileBanner(Uint8List? bytes) {
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

  void addSkillTreeNode(String skillId, SkillTreeNode node) {
    final skill = _skillById(skillId);
    if (skill == null) return;
    node.syncChecklistDone();
    skill.treeNodes.add(node);
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
        node.isChecklistReady;
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

    final profileRankBefore = profileRankForLevel(profile.level);
    final skillRankBefore = skillRankForLevel(skill.level);
    final earned = node.xpReward;

    node.isMastered = true;
    node.masteredAt = DateTime.now();

    profile.totalXpEarned += earned;
    final globalUp = profile.addXP(earned);
    final skillUp = skill.addXP(earned);

    _updateDailyXp(earned, skillUp);
    _syncBossesForSkill(skillId);
    _checkAchievements();
    notifyListeners();
    _saveAll();

    return _xpMessage(
      skill,
      globalUp,
      skillUp,
      earned,
      bonusXp: 0,
      profileRankBefore: profileRankBefore,
      skillRankBefore: skillRankBefore,
      fallbackLabel: 'Узел освоен',
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
    if (t.repeatCustomDays < 1) t.repeatCustomDays = 1;
    tasks.add(t);
    _syncTaskNotification(t);
    notifyListeners();
    _saveAll();
  }

  void updateTask(
    Task task, {
    required String title,
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
  }) {
    final oldType = task.type;
    final hadNotification = task.notificationsEnabled;
    final oldMinimumAction = task.minimumAction;
    task.title = title;
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
    task.notificationsEnabled = notificationsEnabled;
    task.notificationHour = notificationHour;
    task.notificationMinute = notificationMinute;

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
    final effectiveCompletionsByTask = <String, List<HistoryEntry>>{};
    final orderedHistory = [...history]..sort((a, b) => a.at.compareTo(b.at));

    for (final entry in orderedHistory) {
      final taskKey = _historyTaskKey(entry);
      final list = effectiveCompletionsByTask.putIfAbsent(taskKey, () => []);
      if (entry.isCompletion) {
        list.add(entry);
      } else if (list.isNotEmpty) {
        list.removeLast();
      }
    }
    return effectiveCompletionsByTask.values.fold(
      0,
      (sum, list) => sum + list.length,
    );
  }

  int get bestStreak => _bestStreak;

  void refresh() {
    notifyListeners();
    _saveAll();
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  int _multiplierFor(TaskType type, int streak) {
    if (type != TaskType.repeating || streak < 2) return 1;
    if (streak >= 14) return 4;
    if (streak >= 7) return 3;
    return 2;
  }

  int _totalRewardFor(Task task) {
    final nextStreak = task.type == TaskType.repeating
        ? task.streak + 1
        : task.streak;
    return task.xpReward * _multiplierFor(task.type, nextStreak);
  }

  ({int bonusXp, int bonusPercent}) _previewBuffOutcome(
    Task task,
    int baseEarned,
  ) {
    if (baseEarned <= 0) return (bonusXp: 0, bonusPercent: 0);

    final applicableBuffs = activeBuffs
        .where((buff) => _buffAppliesToTask(buff, task))
        .toList(growable: false);
    final bonusPercent = applicableBuffs.fold<int>(
      0,
      (sum, buff) => sum + buff.bonusPercent,
    );
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
    for (final buff in buffs.where((buff) => buff.isActive).toList()) {
      if (!_buffAppliesToTask(buff, task)) continue;
      buff.charges = math.max(0, buff.charges - 1);
      consumedBuffIds.add(buff.id);
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
          'Пять закрытых квестов за день. Внутри бафф, который усилит следующий рывок.',
      rarity: RewardRarity.common,
      notify: notify,
    );

    if (stats.tasksCompleted < 10) return;
    _unlockRewardChest(
      sourceKey: 'daily10:$dayKey',
      title: 'Редкий сундук продуктивности',
      description:
          'Десять закрытых квестов за день. Внутри более сильный бафф на серию задач.',
      rarity: RewardRarity.rare,
      notify: notify,
    );
  }

  void _maybeUnlockStreakRewardChest(Task task, {bool notify = true}) {
    if (task.type != TaskType.repeating) return;

    final milestone = switch (task.streak) {
      7 => (rarity: RewardRarity.rare, title: 'Сундук стрика'),
      30 => (rarity: RewardRarity.epic, title: 'Эпический сундук стрика'),
      _ => null,
    };
    if (milestone == null) return;

    _unlockRewardChest(
      sourceKey: 'streak:${task.id}:${task.streak}',
      title: milestone.title,
      description:
          'Награда за стрик ${task.streak} дней по квесту «${task.title}».',
      rarity: milestone.rarity,
      skillId: task.skillId,
      notify: notify,
    );
  }

  void _maybeGrantBehaviorBuffs(Task task) {
    final stats = todayStats;
    if (stats == null) return;

    final dayKey = _dayKey(stats.date);
    final expiresAt = _endOfDay(stats.date);

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
          'Две задачи одного навыка подряд: следующий квест этого навыка даст +12% XP.',
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
    final expiresAt = _endOfDay(now);

    switch (chest.rarity) {
      case RewardRarity.common:
        return _random.nextBool()
            ? Buff(
                id: uid(),
                type: BuffType.nextQuestXpBoost,
                title: 'Импульс',
                description: 'Следующий квест даст +15% XP до конца дня.',
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
                    'Следующие 2 квеста дадут по +10% XP до конца дня.',
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
                'Следующий квест по навыку ${skill.name} даст +25% XP до конца дня.',
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
          description: 'Следующие 2 квеста дадут по +15% XP до конца дня.',
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
          description: 'Следующие 2 квеста дадут по +35% XP до конца дня.',
          bonusPercent: 35,
          charges: 2,
          createdAt: now,
          expiresAt: expiresAt,
          sourceChestId: chest.id,
          sourceKey: 'chest:${chest.id}',
        );
    }
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day + 1);
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

  BossSnapshot _buildBossSnapshot(Boss boss) {
    final now = DateTime.now();
    final targetStreak = boss.targetStreak < 1 ? 1 : boss.targetStreak;
    final skill = _skillById(boss.skillId);
    final skillTasks = tasks
        .where((task) => task.skillId == boss.skillId)
        .toList();
    final repeatingTasks = skillTasks
        .where((task) => task.type == TaskType.repeating)
        .toList();
    final highPriorityTasks = skillTasks
        .where((task) => task.priority == Priority.high)
        .toList();
    final minimumTasks = skillTasks
        .where((task) => task.hasMinimumAction)
        .toList();

    final currentStreak = repeatingTasks.fold<int>(
      0,
      (max, task) => math.max(max, task.streak),
    );
    final completedTasks = skillTasks.where((task) => task.isDone).length;
    final startedTasks = minimumTasks
        .where((task) => task.isMinimumActionDone || task.isDone)
        .length;
    final relievedHighPriorityTasks = highPriorityTasks
        .where((task) => task.isDone || task.isMinimumActionDone)
        .length;
    final checklistTotal = skill?.checklist.length ?? 0;
    final checklistCompleted = skill?.checklistCompletedCount ?? 0;
    final totalTreeNodes = skill?.treeNodes.length ?? 0;
    final masteredTreeNodes = skill?.masteredTreeNodeCount ?? 0;
    final urgentRepeatingTasks = repeatingTasks
        .where((task) => !task.isDone)
        .where((task) {
          final nextResetAt = task.nextResetAt;
          if (nextResetAt == null) return false;
          return nextResetAt.difference(now) <= const Duration(hours: 24);
        })
        .length;
    final stalledHighPriorityTasks = highPriorityTasks
        .where((task) => !task.isDone && !task.isMinimumActionDone)
        .length;

    final contributions = <({double value, double weight})>[
      if (repeatingTasks.isNotEmpty)
        (value: (currentStreak / targetStreak).clamp(0.0, 1.0), weight: 0.32),
      if (highPriorityTasks.isNotEmpty)
        (
          value: (relievedHighPriorityTasks / highPriorityTasks.length).clamp(
            0.0,
            1.0,
          ),
          weight: 0.26,
        ),
      if (minimumTasks.isNotEmpty)
        (
          value: (startedTasks / minimumTasks.length).clamp(0.0, 1.0),
          weight: 0.18,
        ),
      if (skillTasks.isNotEmpty)
        (
          value: (completedTasks / skillTasks.length).clamp(0.0, 1.0),
          weight: 0.12,
        ),
      if (checklistTotal > 0)
        (
          value: (checklistCompleted / checklistTotal).clamp(0.0, 1.0),
          weight: 0.10,
        ),
      if (totalTreeNodes > 0)
        (
          value: (masteredTreeNodes / totalTreeNodes).clamp(0.0, 1.0),
          weight: 0.14,
        ),
    ];

    final totalWeight = contributions.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    final weightedScore = contributions.fold<double>(
      0,
      (sum, item) => sum + item.value * item.weight,
    );
    final impactProgress = totalWeight == 0
        ? 0.0
        : (weightedScore / totalWeight).clamp(0.0, 1.0);

    final streakProgress = repeatingTasks.isEmpty
        ? 0.0
        : (currentStreak / targetStreak).clamp(0.0, 1.0);
    final priorityProgress = highPriorityTasks.isEmpty
        ? 0.0
        : (relievedHighPriorityTasks / highPriorityTasks.length).clamp(
            0.0,
            1.0,
          );
    final startProgress = minimumTasks.isEmpty
        ? 0.0
        : (startedTasks / minimumTasks.length).clamp(0.0, 1.0);
    final completionProgress = skillTasks.isEmpty
        ? 0.0
        : (completedTasks / skillTasks.length).clamp(0.0, 1.0);
    final checklistProgress = checklistTotal == 0
        ? 0.0
        : (checklistCompleted / checklistTotal).clamp(0.0, 1.0);
    final treeProgress = totalTreeNodes == 0
        ? 0.0
        : (masteredTreeNodes / totalTreeNodes).clamp(0.0, 1.0);

    final isUnderAttack =
        urgentRepeatingTasks > 0 || stalledHighPriorityTasks > 0;

    final phaseLabel = boss.isDefeated
        ? 'Побеждён'
        : impactProgress >= 0.85
        ? 'При смерти'
        : impactProgress >= 0.6
        ? 'Ослабевает'
        : isUnderAttack
        ? 'Атакует'
        : impactProgress >= 0.3
        ? 'Выжидает'
        : 'Силен';

    final recommendation = urgentRepeatingTasks > 0
        ? 'Удержи repeating-квесты: босс восстановится, если пропустить день.'
        : stalledHighPriorityTasks > 0
        ? 'Закрой high-priority задачу по навыку, чтобы сбить давление.'
        : minimumTasks.any(canCompleteMinimumAction)
        ? 'Сделай лёгкий старт по крупной задаче — это тоже наносит урон.'
        : totalTreeNodes > 0 && masteredTreeNodes < totalTreeNodes
        ? 'Освой следующий узел дерева навыка — это сильно ослабит босса.'
        : checklistTotal > 0 && checklistCompleted < checklistTotal
        ? 'Продвигай чеклист навыка — он тоже ослабляет босса.'
        : 'Поддерживай темп по навыку: любой прогресс добивает босса.';

    return BossSnapshot(
      currentStreak: currentStreak,
      targetStreak: targetStreak,
      completedTasks: completedTasks,
      totalTasks: skillTasks.length,
      startedTasks: startedTasks,
      startableTasks: minimumTasks.length,
      checklistCompleted: checklistCompleted,
      checklistTotal: checklistTotal,
      masteredTreeNodes: masteredTreeNodes,
      totalTreeNodes: totalTreeNodes,
      urgentRepeatingTasks: urgentRepeatingTasks,
      stalledHighPriorityTasks: stalledHighPriorityTasks,
      impactProgress: impactProgress,
      streakProgress: streakProgress,
      priorityProgress: priorityProgress,
      startProgress: startProgress,
      completionProgress: completionProgress,
      checklistProgress: checklistProgress,
      treeProgress: treeProgress,
      isUnderAttack: isUnderAttack,
      phaseLabel: phaseLabel,
      recommendation: recommendation,
    );
  }

  void _recalculateBestStreakFromTasks() {
    _bestStreak = tasks
        .where((t) => t.type == TaskType.repeating)
        .fold(0, (max, t) => math.max(max, t.streak));
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
    RankInfo? profileRankBefore,
    RankInfo? skillRankBefore,
    String? fallbackLabel,
  }) {
    if (globalUp > 0) {
      final profileRankAfter = profileRankForLevel(profile.level);
      if (profileRankBefore != null &&
          profileRankAfter.code != profileRankBefore.code) {
        return '🏅 Достигнут ${profileRankAfter.label}!';
      }
      return bonusXp > 0
          ? '🎉 Уровень ${profile.level}! • бафф +$bonusXp XP'
          : '🎉 Уровень ${profile.level}!';
    }
    if (skillUp > 0 && skill != null) {
      final skillRankAfter = skillRankForLevel(skill.level);
      if (skillRankBefore != null &&
          skillRankAfter.code != skillRankBefore.code) {
        return '🏅 ${skill.name} → ${skillRankAfter.label}';
      }
      return bonusXp > 0
          ? '⬆️ ${skill.name} → ур.${skill.level} • бафф +$bonusXp XP'
          : '⬆️ ${skill.name} → ур.${skill.level}';
    }
    if (fallbackLabel == null || fallbackLabel.isEmpty) {
      return bonusXp > 0 ? '+$earned XP • бафф +$bonusXp' : '+$earned XP';
    }
    return bonusXp > 0
        ? '$fallbackLabel: +$earned XP • бафф +$bonusXp'
        : '$fallbackLabel: +$earned XP';
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
          body: 'Пора выполнить повторяющуюся задачу.',
          interval: scheduledTime.difference(now),
        );
      } else {
        _notifications.scheduleTaskReminder(
          id: notificationId,
          title: 'Напоминание: ${task.title}',
          body: 'Не забудь выполнить задачу.',
          scheduledTime: scheduledTime,
        );
      }
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP STATE PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class AppStateProvider extends InheritedWidget {
  final AppState state;
  const AppStateProvider({
    super.key,
    required this.state,
    required super.child,
  });

  static AppState of(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<AppStateProvider>()!.state;

  @override
  bool updateShouldNotify(AppStateProvider old) => true;
}
