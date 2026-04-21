import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models.dart';
import 'utils.dart';

class AppState extends ChangeNotifier {
  bool _isDark = true;
  String? selectedSkillId;

  bool get isDark => _isDark;

  final UserProfile profile = UserProfile(name: 'Your Name');
  final List<HistoryEntry> history = [];

  final List<Skill> skills = [
    Skill(
      id: 's1',
      name: 'Подтягивания',
      goal: 'Подтягиваться 20 раз',
      color: const Color(0xFFFF9500),
      icon: Icons.fitness_center,
      xp: 60,
      checklist: ['3 подхода по 5 раз', 'Без рывков', 'Полная амплитуда'],
    ),
    Skill(
      id: 's2',
      name: 'Python',
      goal: 'Освоить backend на FastAPI',
      color: const Color(0xFF5856D6),
      icon: Icons.code,
      xp: 30,
      level: 2,
      checklist: ['Изучить async/await', 'Написать CRUD', 'Деплой на сервер'],
    ),
    Skill(
      id: 's3',
      name: 'Геймификация жизни',
      goal: 'Запустить RPGreal.org',
      color: const Color(0xFF34C759),
      icon: Icons.sports_esports,
      xp: 80,
    ),
  ];

  final List<Task> tasks = [
    Task(
      id: 't1',
      title: 'Сделать 3 подхода подтягиваний',
      skillId: 's1',
      xpReward: 25,
      type: TaskType.repeating,
      streak: 3,
      repeatFrequency: RepeatFrequency.daily,
    ),
    Task(
      id: 't2',
      title: 'Выйти на 15 подтягиваний за сет',
      skillId: 's1',
      xpReward: 100,
      type: TaskType.longTerm,
    ),
    Task(
      id: 't3',
      title: 'Пройти урок: функции и замыкания',
      skillId: 's2',
      xpReward: 20,
      type: TaskType.shortTerm,
    ),
    Task(
      id: 't4',
      title: 'Написать REST API на FastAPI',
      skillId: 's2',
      xpReward: 60,
      type: TaskType.midTerm,
    ),
    Task(
      id: 't5',
      title: 'Написать концепцию монетизации',
      skillId: 's3',
      xpReward: 50,
      type: TaskType.midTerm,
    ),
  ];

  AppState() {
    _resetExpiredTasks();
    for (final s in skills) {
      s.syncChecklistDone();
    }
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

    // Cumulative total — never decremented on uncomplete
    profile.totalXpEarned += earned;

    final globalUp = profile.addXP(earned);
    int skillUp = 0;
    final skill = _skillById(task.skillId);
    if (skill != null) skillUp = skill.addXP(earned);

    _addHistory(task, skill, earned, isCompletion: true);
    notifyListeners();

    if (globalUp > 0) return '🎉 Уровень ${profile.level}!';
    if (skillUp > 0 && skill != null) {
      return '⬆️ ${skill.name} → ур.${skill.level}';
    }
    return '+$earned XP';
  }

  void uncompleteTask(String taskId) {
    final task = _taskById(taskId);
    if (task == null || !task.isDone) return;
    final earned = task.earnedXP;

    task.isDone = false;
    task.streak = (task.streak - 1).clamp(0, 9999);
    task.earnedXP = 0;
    task.nextResetAt = null;

    // NOTE: totalXpEarned is NOT decremented — it's a historical total
    profile.removeXP(earned);
    _skillById(task.skillId)?.removeXP(earned);

    _addHistory(task, _skillById(task.skillId), earned, isCompletion: false);
    notifyListeners();
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
  }

  void updateProfileAge(int? age) {
    profile.age = age;
    notifyListeners();
  }

  void updateProfileGender(Gender? gender) {
    profile.gender = gender;
    notifyListeners();
  }

  void updateProfileAvatar(Uint8List? bytes) {
    profile.avatarBytes = bytes;
    notifyListeners();
  }

  void updateProfileBanner(Uint8List? bytes) {
    profile.bannerBytes = bytes;
    notifyListeners();
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
    notifyListeners();
  }

  void removeSkill(String id) {
    skills.removeWhere((s) => s.id == id);
    tasks.removeWhere((t) => t.skillId == id);
    if (selectedSkillId == id) selectedSkillId = null;
    notifyListeners();
  }

  void addTask(Task t) {
    tasks.add(t);
    notifyListeners();
  }

  void removeTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

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
