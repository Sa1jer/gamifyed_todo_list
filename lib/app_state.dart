import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models.dart';
import 'utils.dart';
import 'storage_service.dart';

class AppState extends ChangeNotifier {
  bool _isDark = true;
  String? selectedSkillId;
  final StorageService _storage;

  bool get isDark => _isDark;

  UserProfile profile = UserProfile(name: 'Your Name');
  final List<HistoryEntry> history = [];
  final List<Skill> skills = [];
  final List<Task> tasks = [];
  final List<Achievement> achievements = [];
  final List<Boss> bosses = [];
  DailyStats? todayStats;

  int _totalTasksCompleted = 0;
  int _bestStreak = 0;

  AppState({required StorageService storage}) : _storage = storage {
    _initDefaults();
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

    _initAchievements();
  }

  void _initAchievements() {
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

    if (loadedSkills.isNotEmpty) {
      skills.clear();
      skills.addAll(loadedSkills);
      for (final s in skills) {
        s.syncChecklistDone();
      }
    }

    if (loadedTasks.isNotEmpty) {
      tasks.clear();
      tasks.addAll(loadedTasks);
    }

    if (loadedProfile.totalXpEarned > 0) {
      profile = loadedProfile;
    }

    if (loadedHistory.isNotEmpty) {
      history.clear();
      history.addAll(loadedHistory);
    }

    if (loadedAchievements.isNotEmpty) {
      achievements.clear();
      achievements.addAll(loadedAchievements);
      for (final a in achievements) {
        if (a.def == null) {
          final def = achievementDefinitions.where((d) => d.id == a.id).firstOrNull;
          if (def != null) a.def = def;
        }
      }
    } else {
      _initAchievements();
    }

    if (loadedStats != null) {
      todayStats = loadedStats;
    }

    if (loadedBosses.isNotEmpty) {
      bosses.clear();
      bosses.addAll(loadedBosses);
    }

    _totalTasksCompleted = profile.totalXpEarned > 0 ? loadedHistory.where((h) => h.isCompletion).length : 0;
    _bestStreak = loadedTasks.where((t) => t.type == TaskType.repeating).fold(0, (max, t) => t.streak > max ? t.streak : max);

    _resetExpiredTasks();
    notifyListeners();
  }

  Future<void> _saveAll() async {
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
  }

  // ── Resets ───────────────────────────────────────────────────────────────────

  bool _resetExpiredTasks() {
    final now = DateTime.now();
    var changed = false;
    for (final t in tasks) {
      if (t.type == TaskType.repeating &&
          t.isDone &&
          t.nextResetAt != null &&
          now.isAfter(t.nextResetAt!)) {
        t.isDone = false;
        t.earnedXP = 0;
        t.nextResetAt = null;
        changed = true;
      }
    }
    return changed;
  }

  void checkResets() {
    if (_resetExpiredTasks()) notifyListeners();
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

  Skill? get selectedSkill {
    if (selectedSkillId == null) return null;
    return _skillById(selectedSkillId!);
  }

  int get activeSkillCount => skills.length;

  // ── Task completion ──────────────────────────────────────────────────────────

  String? completeTask(String taskId) {
    final task = _taskById(taskId);
    if (task == null || task.isDone) return null;

    task.isDone = true;
    task.streak++;
    final earned = task.xpReward * task.activeMultiplier;
    task.earnedXP = earned;

    if (task.type == TaskType.repeating) {
      task.nextResetAt = nextReset(task.repeatFrequency, task.repeatCustomDays);
    }

    profile.totalXpEarned += earned;
    _totalTasksCompleted++;

    if (task.streak > _bestStreak) {
      _bestStreak = task.streak;
    }

    final globalUp = profile.addXP(earned);
    int skillUp = 0;
    final skill = _skillById(task.skillId);
    if (skill != null) skillUp = skill.addXP(earned);

    _updateDailyStats(earned);
    _addHistory(task, skill, earned, isCompletion: true);
    _checkAchievements();
    _checkBosses(task);
    notifyListeners();
    _saveAll();

    if (globalUp > 0) return '🎉 Уровень ${profile.level}!';
    if (skillUp > 0 && skill != null) {
      return '⬆️ ${skill.name} → ур.${skill.level}';
    }
    return '+$earned XP';
  }

  void _updateDailyStats(int xp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (todayStats == null || todayStats!.date.day != today.day) {
      todayStats = DailyStats(date: today);
    }
    todayStats!.tasksCompleted++;
    todayStats!.xpEarned += xp;
  }

  void _checkAchievements() {
    _unlockAchievement('first_task', _totalTasksCompleted >= 1);
    _unlockAchievement('tasks_100', _totalTasksCompleted >= 100);
    _unlockAchievement('tasks_500', _totalTasksCompleted >= 500);
    _unlockAchievement('streak_7', _bestStreak >= 7);
    _unlockAchievement('streak_30', _bestStreak >= 30);
    _unlockAchievement('level_5', profile.level >= 5);
    _unlockAchievement('level_10', profile.level >= 10);
    _unlockAchievement('skills_3', skills.length >= 3);
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

    for (final boss in bosses) {
      if (boss.isDefeated || boss.skillId != task.skillId) continue;

      boss.currentStreak = task.streak;
      boss.hp = ((1 - boss.currentStreak / boss.targetStreak) * boss.maxHp).round().clamp(0, boss.maxHp);

      if (boss.currentStreak >= boss.targetStreak && !boss.isDefeated) {
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
    final earned = task.earnedXP;

    task.isDone = false;
    task.streak = (task.streak - 1).clamp(0, 9999);
    task.earnedXP = 0;
    task.nextResetAt = null;

    profile.removeXP(earned);
    _skillById(task.skillId)?.removeXP(earned);

    _addHistory(task, _skillById(task.skillId), earned, isCompletion: false);
    notifyListeners();
    _saveAll();
  }

  // ── Checklist ────────────────────────────────────────────────────────────────

  void toggleChecklistItem(String skillId, int index) {
    final skill = _skillById(skillId);
    if (skill == null || index >= skill.checklistDone.length) return;
    skill.checklistDone[index] = !skill.checklistDone[index];
    notifyListeners();
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

  void removeSkill(String id) {
    skills.removeWhere((s) => s.id == id);
    tasks.removeWhere((t) => t.skillId == id);
    if (selectedSkillId == id) selectedSkillId = null;
    notifyListeners();
    _saveAll();
  }

  void addTask(Task t) {
    t.syncSubtaskDone();
    tasks.add(t);
    notifyListeners();
    _saveAll();
  }

  void removeTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    _saveAll();
  }

  void toggleSubtask(String taskId, int index) {
    final task = _taskById(taskId);
    if (task == null || index >= task.subtaskDone.length) return;
    task.subtaskDone[index] = !task.subtaskDone[index];
    notifyListeners();
    _saveAll();
  }

  // ── Bosses ──────────────────────────────────────────────────────────────────

  void addBoss(Boss b) {
    bosses.add(b);
    notifyListeners();
    _saveAll();
  }

  void removeBoss(String id) {
    bosses.removeWhere((b) => b.id == id);
    notifyListeners();
    _saveAll();
  }

  // ── Statistics helpers ───────────────────────────────────────────────────────

  int get totalTasksCompleted => _totalTasksCompleted;
  int get bestStreak => _bestStreak;

  void refresh() {
    notifyListeners();
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  void _addHistory(Task t, Skill? skill, int xp, {required bool isCompletion}) {
    history.insert(
      0,
      HistoryEntry(
        id: uid(),
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
