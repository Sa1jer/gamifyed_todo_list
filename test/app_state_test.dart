import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';

class _InMemoryStorageService extends StorageService {
  bool? _theme;

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasSavedSkills() async => false;

  @override
  Future<bool> hasSavedTasks() async => false;

  @override
  Future<bool?> loadTheme() async => _theme;

  @override
  Future<void> saveTheme(bool isDark) async {
    _theme = isDark;
  }

  @override
  Future<List<Skill>> loadSkills() async => [];

  @override
  Future<void> saveSkills(List<Skill> skills) async {}

  @override
  Future<List<Task>> loadTasks() async => [];

  @override
  Future<void> saveTasks(List<Task> tasks) async {}

  @override
  Future<UserProfile> loadProfile() async => UserProfile(name: 'Your Name');

  @override
  Future<void> saveProfile(UserProfile profile) async {}

  @override
  Future<List<HistoryEntry>> loadHistory() async => [];

  @override
  Future<void> saveHistory(List<HistoryEntry> entries) async {}

  @override
  Future<List<Achievement>> loadAchievements() async => [];

  @override
  Future<void> saveAchievements(List<Achievement> achievements) async {}

  @override
  Future<DailyStats?> loadStats() async => null;

  @override
  Future<void> saveStats(DailyStats stats) async {}

  @override
  Future<List<Boss>> loadBosses() async => [];

  @override
  Future<void> saveBosses(List<Boss> bosses) async {}
}

void main() {
  group('minimum action flow', () {
    late AppState state;
    late Task task;

    setUp(() {
      state = AppState(storage: _InMemoryStorageService());
      task = state.tasks.firstWhere(
        (candidate) => candidate.title == 'Написать REST API на FastAPI',
      );
    });

    tearDown(() {
      state.dispose();
    });

    test('awards partial xp without completing non-repeating task', () {
      final profileXpBefore = state.profile.xp;
      final skill = state.skills.firstWhere((item) => item.id == task.skillId);
      final skillXpBefore = skill.xp;

      final message = state.completeMinimumAction(task.id);

      expect(message, 'Старт: +18 XP');
      expect(task.isDone, isFalse);
      expect(task.isMinimumActionDone, isTrue);
      expect(task.minimumActionEarnedXP, 18);
      expect(state.previewEarnedXP(task), 42);
      expect(state.profile.xp, profileXpBefore + 18);
      expect(skill.xp, skillXpBefore + 18);
      expect(state.todayStats?.tasksCompleted, 0);
      expect(state.todayStats?.xpEarned, 18);
    });

    test('full completion after minimum action awards only remaining xp', () {
      state.completeMinimumAction(task.id);

      final message = state.completeTask(task.id);

      expect(message, '+42 XP');
      expect(task.isDone, isTrue);
      expect(task.earnedXP, 60);
      expect(state.profile.totalXpEarned, 60);
      expect(state.todayStats?.tasksCompleted, 1);
      expect(state.todayStats?.xpEarned, 60);

      state.uncompleteTask(task.id);

      expect(task.isDone, isFalse);
      expect(task.isMinimumActionDone, isTrue);
      expect(task.minimumActionEarnedXP, 18);
      expect(state.profile.totalXpEarned, 18);
      expect(state.previewEarnedXP(task), 42);
      expect(state.todayStats?.tasksCompleted, 0);
      expect(state.todayStats?.xpEarned, 18);
    });
  });
}
