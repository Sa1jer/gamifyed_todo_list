import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';

/// Хранилище в памяти для тестов.
///
/// Раньше жило двумя копиями — в `widget_test.dart` и `app_state_test.dart`, —
/// которые успели разойтись: одна возвращала историю и сундуки по кругу,
/// другая молча их теряла. Копия здесь одна, и она круговая: что сохранили,
/// то и загрузится.
class InMemoryStorageService extends StorageService {
  InMemoryStorageService({this.snapshotsSupported = false});

  /// Умеет ли устройство единый документ состояния.
  ///
  /// От этого зависит, показывает ли приложение перенос данных, поэтому
  /// значение задаётся тестом, а не выводится из пустой заглушки `init`.
  final bool snapshotsSupported;

  // Поля ниже публичные: тесты выставляют их напрямую, а из другого файла
  // приватные недоступны.

  @override
  bool get supportsSnapshots => snapshotsSupported;

  List<Skill> skills = [];
  List<Task> tasks = [];
  List<HistoryEntry> history = [];
  List<RewardChest> rewardChests = [];
  DailyStats? dailyStats;
  bool? theme;
  bool? tooltipsEnabled;
  bool? welcomeSeen;
  bool? onboardingSeen;
  TutorialProgress? tutorialProgress;
  int? bestStreak;

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasSavedSkills() async => skills.isNotEmpty;

  @override
  Future<bool> hasSavedTasks() async => tasks.isNotEmpty;

  @override
  Future<bool?> loadTheme() async => theme;

  @override
  Future<void> saveTheme(bool isDark) async {
    theme = isDark;
  }

  @override
  Future<bool?> loadSfxEnabled() async => true;

  @override
  Future<void> saveSfxEnabled(bool enabled) async {}

  @override
  Future<bool?> loadTooltipsEnabled() async => tooltipsEnabled;

  @override
  Future<void> saveTooltipsEnabled(bool enabled) async {
    tooltipsEnabled = enabled;
  }

  @override
  Future<bool?> loadWelcomeSeen() async => welcomeSeen;

  @override
  Future<void> saveWelcomeSeen(bool seen) async {
    welcomeSeen = seen;
  }

  @override
  Future<bool?> loadOnboardingSeen() async => onboardingSeen;

  @override
  Future<void> saveOnboardingSeen(bool seen) async {
    onboardingSeen = seen;
  }

  @override
  Future<TutorialProgress?> loadTutorialProgress() async => tutorialProgress;

  @override
  Future<void> saveTutorialProgress(TutorialProgress progress) async {
    tutorialProgress = progress;
  }

  @override
  Future<List<Skill>> loadSkills() async => List.of(skills);

  @override
  Future<void> saveSkills(List<Skill> skills) async {
    this.skills = List.of(skills);
  }

  @override
  Future<List<Task>> loadTasks() async => List.of(tasks);

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    this.tasks = List.of(tasks);
  }

  @override
  Future<UserProfile> loadProfile() async => UserProfile(name: 'Your Name');

  @override
  Future<void> saveProfile(UserProfile profile) async {}

  @override
  Future<List<HistoryEntry>> loadHistory() async => List.of(history);

  @override
  Future<void> saveHistory(List<HistoryEntry> entries) async {
    history = List.of(entries);
  }

  @override
  Future<List<Achievement>> loadAchievements() async => [];

  @override
  Future<void> saveAchievements(List<Achievement> achievements) async {}

  @override
  Future<DailyStats?> loadStats() async => dailyStats;

  @override
  Future<void> saveStats(DailyStats stats) async {
    dailyStats = stats;
  }

  @override
  Future<List<Boss>> loadBosses() async => [];

  @override
  Future<void> saveBosses(List<Boss> bosses) async {}

  @override
  Future<List<RewardChest>> loadRewardChests() async => List.of(rewardChests);

  @override
  Future<void> saveRewardChests(List<RewardChest> rewardChests) async {
    this.rewardChests = List.of(rewardChests);
  }

  @override
  Future<List<Buff>> loadBuffs() async => [];

  @override
  Future<void> saveBuffs(List<Buff> buffs) async {}

  @override
  Future<List<WeeklyGoal>> loadWeeklyGoals() async => [];

  @override
  Future<void> saveWeeklyGoals(List<WeeklyGoal> goals) async {}

  @override
  Future<int?> loadBestStreak() async => bestStreak;

  @override
  Future<void> saveBestStreak(int value) async {
    bestStreak = value;
  }
}
