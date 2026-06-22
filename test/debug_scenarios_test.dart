import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/debug/debug_admin_controller.dart';
import 'package:todo_list_app/debug/debug_scenarios.dart';
import 'package:todo_list_app/debug/debug_service.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/utils.dart';

class _InMemoryStorageService extends StorageService {
  int? bestStreak;
  bool? onboardingSeen;
  TutorialProgress? tutorialProgress;

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasSavedSkills() async => false;

  @override
  Future<bool> hasSavedTasks() async => false;

  @override
  Future<bool?> loadTheme() async => null;

  @override
  Future<void> saveTheme(bool isDark) async {}

  @override
  Future<bool?> loadSfxEnabled() async => true;

  @override
  Future<void> saveSfxEnabled(bool enabled) async {}

  @override
  Future<bool?> loadTooltipsEnabled() async => true;

  @override
  Future<void> saveTooltipsEnabled(bool enabled) async {}

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
  Future<int?> loadBestStreak() async => bestStreak;

  @override
  Future<void> saveBestStreak(int value) async {
    bestStreak = value;
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

  @override
  Future<List<RewardChest>> loadRewardChests() async => [];

  @override
  Future<void> saveRewardChests(List<RewardChest> rewardChests) async {}

  @override
  Future<List<Buff>> loadBuffs() async => [];

  @override
  Future<void> saveBuffs(List<Buff> buffs) async {}

  @override
  Future<List<WeeklyGoal>> loadWeeklyGoals() async => [];

  @override
  Future<void> saveWeeklyGoals(List<WeeklyGoal> goals) async {}
}

class _FakeDebugService extends DebugService {
  DebugAdminDraftState draft = const DebugAdminDraftState.empty();
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  Future<DebugAdminDraftState> loadDraftState() async => draft;

  @override
  Future<void> saveDraftState(DebugAdminDraftState state) async {
    draft = state;
  }

  @override
  Future<void> clear() async {
    draft = const DebugAdminDraftState.empty();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({AppState state, _FakeDebugService debug})> applyScenario(
    DebugScenarioDef scenario, {
    bool seedDefaults = false,
  }) async {
    final state = AppState(
      storage: _InMemoryStorageService(),
      seedDefaults: seedDefaults,
    );
    final debug = _FakeDebugService();
    final controller = DebugAdminController(state: state, debugService: debug);
    await controller.applyScenario(scenario);
    return (state: state, debug: debug);
  }

  group('Debug scenarios', () {
    test('fresh user clears app entities and resets achievements', () async {
      final result = await applyScenario(
        debugScenarioFreshUser,
        seedDefaults: true,
      );
      addTearDown(result.state.dispose);

      expect(result.state.skills, isEmpty);
      expect(result.state.tasks, isEmpty);
      expect(result.state.history, isEmpty);
      expect(result.state.rewardChests, isEmpty);
      expect(result.state.buffs, isEmpty);
      expect(result.state.bosses, isEmpty);
      expect(result.state.weeklyGoals, isEmpty);
      expect(result.state.bestStreak, 0);
      expect(
        result.state.achievements,
        hasLength(achievementDefinitions.length),
      );
      expect(
        result.state.achievements.every((item) => !item.isUnlocked),
        isTrue,
      );
      expect(result.debug.draft.selectedScenarioId, debugScenarioFreshUser.id);
    });

    test('fresh user resets first-run tutorial state', () async {
      final storage = _InMemoryStorageService()..onboardingSeen = true;
      final state = AppState(storage: storage, seedDefaults: true);
      final debug = _FakeDebugService();
      final controller = DebugAdminController(
        state: state,
        debugService: debug,
      );
      addTearDown(state.dispose);

      await state.loadSavedData();
      expect(state.onboardingSeen, isTrue);

      await controller.applyScenario(debugScenarioFreshUser);

      expect(state.onboardingSeen, isFalse);
      expect(storage.onboardingSeen, isFalse);
      expect(state.shouldShowFirstRunTutorial, isTrue);
    });

    test(
      'streak 7 creates repeating quest and unlocks streak achievement',
      () async {
        final result = await applyScenario(debugScenarioStreak7);
        addTearDown(result.state.dispose);

        expect(result.state.skills, hasLength(1));
        expect(result.state.tasks, hasLength(1));
        expect(result.state.tasks.single.type, TaskType.repeating);
        expect(result.state.tasks.single.streak, 7);
        expect(result.state.bestStreak, 7);
        expect(
          result.state.achievements
              .firstWhere((item) => item.id == 'streak_7')
              .isUnlocked,
          isTrue,
        );
      },
    );

    test('all achievements scenario unlocks every definition', () async {
      final result = await applyScenario(debugScenarioAllAchievements);
      addTearDown(result.state.dispose);

      expect(
        result.state.achievements,
        hasLength(achievementDefinitions.length),
      );
      expect(
        result.state.achievements.every((item) => item.isUnlocked),
        isTrue,
      );
      expect(
        result.debug.draft.selectedScenarioId,
        debugScenarioAllAchievements.id,
      );
    });

    test('epic chest scenario adds unopened epic chest', () async {
      final result = await applyScenario(debugScenarioEpicChest);
      addTearDown(result.state.dispose);

      expect(result.state.rewardChests, hasLength(1));
      expect(result.state.rewardChests.single.rarity, RewardRarity.epic);
      expect(result.state.rewardChests.single.isOpened, isFalse);
    });

    test(
      'boss defeated scenario creates defeated resistance and reward',
      () async {
        final result = await applyScenario(debugScenarioBossDefeated);
        addTearDown(result.state.dispose);

        expect(result.state.bosses, hasLength(1));
        expect(result.state.bosses.single.isDefeated, isTrue);
        expect(result.state.bosses.single.defeatedAt, isNotNull);
        expect(result.state.rewardChests, isNotEmpty);
        expect(
          result.state.achievements
              .firstWhere((item) => item.id == 'first_boss')
              .isUnlocked,
          isTrue,
        );
      },
    );

    test('active effects scenario adds active effects with charges', () async {
      final result = await applyScenario(debugScenarioActiveBuffs);
      addTearDown(result.state.dispose);

      expect(result.state.activeBuffs, hasLength(2));
      expect(
        result.state.activeBuffs.every((buff) => buff.charges > 0),
        isTrue,
      );
      expect(
        result.state.activeBuffs.every(
          (buff) =>
              buff.expiresAt != null && buff.expiresAt!.isAfter(DateTime.now()),
        ),
        isTrue,
      );
      expect(
        result.state.activeBuffs.map((buff) => buff.type).toSet(),
        containsAll([BuffType.nextQuestXpBoost, BuffType.skillFocusXpBoost]),
      );
    });
  });
}
