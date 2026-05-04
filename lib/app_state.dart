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
  Timer? _resetTimer;

  bool get isDark => _isDark;

  UserProfile profile = UserProfile(name: 'Your Name');
  final List<HistoryEntry> history = [];
  final List<Skill> skills = [];
  final List<Task> tasks = [];
  final List<Achievement> achievements = [];
  final List<Boss> bosses = [];
  DailyStats? todayStats;

  int _bestStreak = 0;

  AppState({
    required StorageService storage,
    NotificationService? notifications,
  }) : _storage = storage,
       _notifications = notifications ?? NotificationService() {
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
    skills.addAll([
      Skill(
        id: uid(),
        name: 'Подтягивания',
        goal: 'Подтягиваться 20 раз',
        color: const Color(0xFFFF9500),
        icon: Icons.fitness_center,
        xp: 60,
        checklist: ['3 подхода по 5 раз', 'Без рывков', 'Полная амплитуда'],
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
      ),
      Skill(
        id: uid(),
        name: 'Геймификация жизни',
        goal: 'Запустить RPGreal.org',
        color: const Color(0xFF34C759),
        icon: Icons.sports_esports,
        xp: 80,
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

    todayStats = loadedStats;
    _resetDailyStatsIfNeeded();

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

  int previewMinimumActionXP(Task task) {
    if (!task.hasMinimumAction || task.isMinimumActionDone || task.isDone) {
      return 0;
    }
    return math.max(1, (_totalRewardFor(task) * _minimumActionRatio).round());
  }

  bool canCompleteMinimumAction(Task task) {
    return task.hasMinimumAction && !task.isDone && !task.isMinimumActionDone;
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
    final nextStreak = task.type == TaskType.repeating
        ? task.streak + 1
        : task.streak;
    final totalReward = _totalRewardFor(task);
    final alreadyEarned = task.type == TaskType.repeating
        ? 0
        : task.minimumActionEarnedXP.clamp(0, totalReward);
    final earned = math.max(0, totalReward - alreadyEarned);

    task.isDone = true;
    task.earnedXP = totalReward;
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

    final globalUp = profile.addXP(earned);
    int skillUp = 0;
    if (skill != null) skillUp = skill.addXP(earned);

    _updateDailyStats(earned, skillUp);
    _addHistory(task, skill, earned, isCompletion: true);
    _checkAchievements();
    _checkBosses(task);
    _syncTaskNotification(task);
    notifyListeners();
    _saveAll();

    return _xpMessage(skill, globalUp, skillUp, earned);
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
    final earned = previewMinimumActionXP(task);
    final nextStreak = task.type == TaskType.repeating
        ? task.streak + 1
        : task.streak;

    task.minimumActionDoneAt = now;
    task.minimumActionEarnedXP = earned;

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

    final globalUp = profile.addXP(earned);
    int skillUp = 0;
    if (skill != null) {
      skillUp = skill.addXP(earned);
    }

    if (task.type == TaskType.repeating) {
      _updateDailyStats(earned, skillUp);
      _addHistory(task, skill, earned, isCompletion: true);
      _checkBosses(task);
    } else {
      _updateDailyXp(earned, skillUp);
    }

    _checkAchievements();
    _syncTaskNotification(task);
    notifyListeners();
    _saveAll();

    return _xpMessage(
      skill,
      globalUp,
      skillUp,
      earned,
      fallbackLabel: task.type == TaskType.repeating ? 'Лёгкий старт' : 'Старт',
    );
  }

  void _updateDailyStats(int xp, [int skillUp = 0]) {
    _resetDailyStatsIfNeeded();
    todayStats!.tasksCompleted++;
    todayStats!.xpEarned += xp;
    todayStats!.skillsImproved += skillUp;
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
    if (task.type != TaskType.repeating) return;
    _syncBossesForSkill(task.skillId);
  }

  void _syncAllBosses() {
    final skillIds = bosses.map((b) => b.skillId).toSet();
    for (final skillId in skillIds) {
      _syncBossesForSkill(skillId);
    }
  }

  void _syncBossesForSkill(String skillId) {
    final skillStreak = tasks
        .where((t) => t.skillId == skillId && t.type == TaskType.repeating)
        .fold<int>(0, (max, t) => math.max(max, t.streak));

    for (final boss in bosses) {
      if (boss.skillId != skillId || boss.isDefeated) continue;
      boss.currentStreak = skillStreak;
      boss.hp = ((1 - boss.currentStreak / boss.targetStreak) * boss.maxHp)
          .round()
          .clamp(0, boss.maxHp);

      if (boss.currentStreak >= boss.targetStreak) {
        boss.isDefeated = true;
        boss.defeatedAt = DateTime.now();
        boss.hp = 0;
        _unlockAchievement('first_boss', true);
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
    task.lastCompletedAt = null;
    if (!restoresMinimumProgress) {
      task.minimumActionDoneAt = null;
      task.minimumActionEarnedXP = 0;
    }

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
    _checkAchievements();
    notifyListeners();
    _saveAll();
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
    String? fallbackLabel,
  }) {
    if (globalUp > 0) return '🎉 Уровень ${profile.level}!';
    if (skillUp > 0 && skill != null) {
      return '⬆️ ${skill.name} → ур.${skill.level}';
    }
    if (fallbackLabel == null || fallbackLabel.isEmpty) {
      return '+$earned XP';
    }
    return '$fallbackLabel: +$earned XP';
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
