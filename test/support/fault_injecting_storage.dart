import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/storage_snapshot.dart';

enum StorageOperation {
  init,
  loadSkills,
  loadTasks,
  loadProfile,
  loadHistory,
  loadAchievements,
  loadStats,
  loadBosses,
  loadRewardChests,
  loadBuffs,
  loadWeeklyGoals,
  loadBestStreak,
  hasSavedSkills,
  hasSavedTasks,
  loadTheme,
  loadSfxEnabled,
  loadTooltipsEnabled,
  loadOnboardingSeen,
  loadTutorialProgress,
  saveTheme,
  saveSfxEnabled,
  saveTooltipsEnabled,
  saveOnboardingSeen,
  saveTutorialProgress,
  saveSkills,
  saveTasks,
  saveProfile,
  saveHistory,
  saveAchievements,
  saveStats,
  saveBosses,
  saveRewardChests,
  saveBuffs,
  saveWeeklyGoals,
  saveBestStreak,
  loadSnapshot,
  saveSnapshot,
}

class InjectedStorageFailure implements Exception {
  const InjectedStorageFailure(this.operation, {this.message = 'injected'});

  final StorageOperation operation;
  final String message;

  @override
  String toString() => 'InjectedStorageFailure($operation, $message)';
}

/// In-memory storage with deterministic failures before or during operations.
class FaultInjectingStorageService extends StorageService {
  FaultInjectingStorageService({
    List<Skill>? skills,
    List<Task>? tasks,
    UserProfile? profile,
    this.snapshotSupport = false,
  }) : persistedSkills = List<Skill>.of(skills ?? const <Skill>[]),
       persistedTasks = List<Task>.of(tasks ?? const <Task>[]),
       persistedProfile = profile ?? UserProfile(name: 'Stored user'),
       savedSkillsMarker = skills?.isNotEmpty ?? false,
       savedTasksMarker = tasks?.isNotEmpty ?? false;

  final List<StorageOperation> operations = <StorageOperation>[];
  final Map<StorageOperation, int> failAfterItems = <StorageOperation, int>{};
  StorageOperation? failBeforeOperation;

  List<Skill> persistedSkills;
  List<Task> persistedTasks;
  UserProfile persistedProfile;
  List<HistoryEntry> persistedHistory = <HistoryEntry>[];
  List<Achievement> persistedAchievements = <Achievement>[];
  DailyStats? persistedStats;
  List<Boss> persistedBosses = <Boss>[];
  List<RewardChest> persistedRewardChests = <RewardChest>[];
  List<Buff> persistedBuffs = <Buff>[];
  List<WeeklyGoal> persistedWeeklyGoals = <WeeklyGoal>[];
  int persistedBestStreak = 0;
  bool persistedTheme = false;
  bool persistedSfxEnabled = true;
  bool persistedTooltipsEnabled = true;
  bool persistedOnboardingSeen = false;
  TutorialProgress? persistedTutorialProgress;
  bool savedSkillsMarker;
  bool savedTasksMarker;
  final bool snapshotSupport;
  CommittedSnapshot? committedSnapshot;
  final List<StorageSnapshot> savedSnapshots = <StorageSnapshot>[];

  @override
  bool get supportsSnapshots => snapshotSupport;

  @override
  Future<void> init() async {
    _record(StorageOperation.init);
  }

  void clearFailures() {
    failBeforeOperation = null;
    failAfterItems.clear();
  }

  void _record(StorageOperation operation) {
    operations.add(operation);
    if (failBeforeOperation == operation) {
      throw InjectedStorageFailure(operation);
    }
  }

  Future<void> _replaceList<T>(
    StorageOperation operation,
    List<T> target,
    List<T> values,
  ) async {
    _record(operation);
    target.clear();
    final failAfter = failAfterItems[operation];
    for (final value in values) {
      target.add(value);
      if (failAfter != null && target.length >= failAfter) {
        throw InjectedStorageFailure(
          operation,
          message: 'failed after $failAfter item(s)',
        );
      }
    }
  }

  T _load<T>(StorageOperation operation, T value) {
    _record(operation);
    return value;
  }

  Future<void> _save(StorageOperation operation) async {
    _record(operation);
  }

  @override
  Future<CommittedSnapshot?> loadLatestSnapshot() async =>
      _load(StorageOperation.loadSnapshot, committedSnapshot);

  @override
  Future<void> saveSnapshot(StorageSnapshot snapshot) async {
    await _save(StorageOperation.saveSnapshot);
    savedSnapshots.add(snapshot);
    committedSnapshot = CommittedSnapshot(
      snapshot: snapshot,
      source: SnapshotLoadSource.current,
    );
  }

  @override
  Future<List<Skill>> loadSkills() async =>
      List<Skill>.of(_load(StorageOperation.loadSkills, persistedSkills));

  @override
  Future<List<Task>> loadTasks() async =>
      List<Task>.of(_load(StorageOperation.loadTasks, persistedTasks));

  @override
  Future<UserProfile> loadProfile() async =>
      _load(StorageOperation.loadProfile, persistedProfile);

  @override
  Future<List<HistoryEntry>> loadHistory() async => List<HistoryEntry>.of(
    _load(StorageOperation.loadHistory, persistedHistory),
  );

  @override
  Future<List<Achievement>> loadAchievements() async => List<Achievement>.of(
    _load(StorageOperation.loadAchievements, persistedAchievements),
  );

  @override
  Future<DailyStats?> loadStats() async =>
      _load(StorageOperation.loadStats, persistedStats);

  @override
  Future<List<Boss>> loadBosses() async =>
      List<Boss>.of(_load(StorageOperation.loadBosses, persistedBosses));

  @override
  Future<List<RewardChest>> loadRewardChests() async => List<RewardChest>.of(
    _load(StorageOperation.loadRewardChests, persistedRewardChests),
  );

  @override
  Future<List<Buff>> loadBuffs() async =>
      List<Buff>.of(_load(StorageOperation.loadBuffs, persistedBuffs));

  @override
  Future<List<WeeklyGoal>> loadWeeklyGoals() async => List<WeeklyGoal>.of(
    _load(StorageOperation.loadWeeklyGoals, persistedWeeklyGoals),
  );

  @override
  Future<int> loadBestStreak() async =>
      _load(StorageOperation.loadBestStreak, persistedBestStreak);

  @override
  Future<bool> hasSavedSkills() async =>
      _load(StorageOperation.hasSavedSkills, savedSkillsMarker);

  @override
  Future<bool> hasSavedTasks() async =>
      _load(StorageOperation.hasSavedTasks, savedTasksMarker);

  @override
  Future<bool?> loadTheme() async =>
      _load(StorageOperation.loadTheme, persistedTheme);

  @override
  Future<bool?> loadSfxEnabled() async =>
      _load(StorageOperation.loadSfxEnabled, persistedSfxEnabled);

  @override
  Future<bool?> loadTooltipsEnabled() async =>
      _load(StorageOperation.loadTooltipsEnabled, persistedTooltipsEnabled);

  @override
  Future<bool?> loadOnboardingSeen() async =>
      _load(StorageOperation.loadOnboardingSeen, persistedOnboardingSeen);

  @override
  Future<TutorialProgress?> loadTutorialProgress() async =>
      _load(StorageOperation.loadTutorialProgress, persistedTutorialProgress);

  @override
  Future<void> saveTheme(bool isDark) async {
    await _save(StorageOperation.saveTheme);
    persistedTheme = isDark;
  }

  @override
  Future<void> saveSfxEnabled(bool enabled) async {
    await _save(StorageOperation.saveSfxEnabled);
    persistedSfxEnabled = enabled;
  }

  @override
  Future<void> saveTooltipsEnabled(bool enabled) async {
    await _save(StorageOperation.saveTooltipsEnabled);
    persistedTooltipsEnabled = enabled;
  }

  @override
  Future<void> saveOnboardingSeen(bool seen) async {
    await _save(StorageOperation.saveOnboardingSeen);
    persistedOnboardingSeen = seen;
  }

  @override
  Future<void> saveTutorialProgress(TutorialProgress progress) async {
    await _save(StorageOperation.saveTutorialProgress);
    persistedTutorialProgress = progress;
  }

  @override
  Future<void> saveSkills(List<Skill> skills) async {
    savedSkillsMarker = true;
    await _replaceList(StorageOperation.saveSkills, persistedSkills, skills);
  }

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    savedTasksMarker = true;
    await _replaceList(StorageOperation.saveTasks, persistedTasks, tasks);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _save(StorageOperation.saveProfile);
    persistedProfile = profile;
  }

  @override
  Future<void> saveHistory(List<HistoryEntry> history) =>
      _replaceList(StorageOperation.saveHistory, persistedHistory, history);

  @override
  Future<void> saveAchievements(List<Achievement> achievements) => _replaceList(
    StorageOperation.saveAchievements,
    persistedAchievements,
    achievements,
  );

  @override
  Future<void> saveStats(DailyStats stats) async {
    await _save(StorageOperation.saveStats);
    persistedStats = stats;
  }

  @override
  Future<void> saveBosses(List<Boss> bosses) =>
      _replaceList(StorageOperation.saveBosses, persistedBosses, bosses);

  @override
  Future<void> saveRewardChests(List<RewardChest> chests) => _replaceList(
    StorageOperation.saveRewardChests,
    persistedRewardChests,
    chests,
  );

  @override
  Future<void> saveBuffs(List<Buff> buffs) =>
      _replaceList(StorageOperation.saveBuffs, persistedBuffs, buffs);

  @override
  Future<void> saveWeeklyGoals(List<WeeklyGoal> goals) => _replaceList(
    StorageOperation.saveWeeklyGoals,
    persistedWeeklyGoals,
    goals,
  );

  @override
  Future<void> saveBestStreak(int streak) async {
    await _save(StorageOperation.saveBestStreak);
    persistedBestStreak = streak;
  }
}
