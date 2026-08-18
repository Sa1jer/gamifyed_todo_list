import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/engines/goal_progress_engine.dart';
import 'package:todo_list_app/engines/momentum_resolver.dart';
import 'package:todo_list_app/engines/next_action_resolver.dart';
import 'package:todo_list_app/features/momentum/momentum_view_data.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/utils.dart';

class _MomentumStorage extends StorageService {
  _MomentumStorage({required this.skills, required this.tasks, this.history});

  List<Skill> skills;
  List<Task> tasks;
  List<HistoryEntry>? history;
  int saveCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasSavedSkills() async => true;

  @override
  Future<bool> hasSavedTasks() async => true;

  @override
  Future<List<Skill>> loadSkills() async => List.of(skills);

  @override
  Future<List<Task>> loadTasks() async => List.of(tasks);

  @override
  Future<List<HistoryEntry>> loadHistory() async =>
      List.of(history ?? const []);

  @override
  Future<UserProfile> loadProfile() async => UserProfile(name: 'Tester');

  @override
  Future<List<Achievement>> loadAchievements() async => const [];

  @override
  Future<DailyStats?> loadStats() async => null;

  @override
  Future<List<Boss>> loadBosses() async => const [];

  @override
  Future<List<RewardChest>> loadRewardChests() async => const [];

  @override
  Future<List<Buff>> loadBuffs() async => const [];

  @override
  Future<List<WeeklyGoal>> loadWeeklyGoals() async => const [];

  @override
  Future<int?> loadBestStreak() async => 0;

  @override
  Future<bool?> loadTheme() async => true;

  @override
  Future<bool?> loadSfxEnabled() async => true;

  @override
  Future<bool?> loadTooltipsEnabled() async => true;

  @override
  Future<bool?> loadOnboardingSeen() async => true;

  @override
  Future<TutorialProgress?> loadTutorialProgress() async =>
      const TutorialProgress(completedModuleIds: {TutorialModuleIds.core});

  void _saved() => saveCalls++;

  @override
  Future<void> saveSkills(List<Skill> values) async => _saved();

  @override
  Future<void> saveTasks(List<Task> values) async => _saved();

  @override
  Future<void> saveHistory(List<HistoryEntry> values) async => _saved();

  @override
  Future<void> saveProfile(UserProfile value) async => _saved();

  @override
  Future<void> saveAchievements(List<Achievement> values) async => _saved();

  @override
  Future<void> saveStats(DailyStats value) async => _saved();

  @override
  Future<void> saveBosses(List<Boss> values) async => _saved();

  @override
  Future<void> saveRewardChests(List<RewardChest> values) async => _saved();

  @override
  Future<void> saveBuffs(List<Buff> values) async => _saved();

  @override
  Future<void> saveWeeklyGoals(List<WeeklyGoal> values) async => _saved();

  @override
  Future<void> saveBestStreak(int value) async => _saved();

  @override
  Future<void> saveTheme(bool value) async => _saved();

  @override
  Future<void> saveSfxEnabled(bool value) async => _saved();

  @override
  Future<void> saveTooltipsEnabled(bool value) async => _saved();

  @override
  Future<void> saveOnboardingSeen(bool value) async => _saved();

  @override
  Future<void> saveTutorialProgress(TutorialProgress value) async => _saved();

  @override
  Future<void> saveReducedMotion(bool value) async => _saved();
}

class _FixedGoalProgressEngine extends GoalProgressEngine {
  const _FixedGoalProgressEngine(this.value);

  final double value;

  @override
  GoalProgressSnapshot snapshotForSkill(Skill skill) =>
      GoalProgressSnapshot(completedStages: 3, totalStages: 4, value: value);
}

void main() {
  const builder = MomentumViewDataBuilder();
  final now = DateTime.utc(2026, 8, 18, 12);

  Skill skill({List<SkillTreeNode>? stages}) => Skill(
    id: 'skill-a',
    name: 'Разработка',
    goal: 'Собрать устойчивый рабочий поток',
    color: Colors.blue,
    icon: Icons.code_rounded,
    treeNodes: stages,
  );

  Task task(
    String id, {
    bool done = false,
    String? stageId,
    String minimumAction = '',
    Priority priority = Priority.medium,
  }) => Task(
    id: id,
    title: 'Квест $id',
    skillId: 'skill-a',
    xpReward: 20,
    type: TaskType.shortTerm,
    isDone: done,
    treeNodeId: stageId,
    minimumAction: minimumAction,
    priority: priority,
  );

  Future<({AppState state, _MomentumStorage storage})> load({
    required Skill skill,
    required List<Task> tasks,
    List<HistoryEntry> history = const [],
  }) async {
    final storage = _MomentumStorage(
      skills: [skill],
      tasks: tasks,
      history: history,
    );
    final state = AppState(storage: storage, seedDefaults: false);
    await state.loadSavedData();
    storage.saveCalls = 0;
    return (state: state, storage: storage);
  }

  HistoryEntry completion(String taskId) => HistoryEntry(
    id: 'history-$taskId',
    taskId: taskId,
    taskTitle: 'Завершённый квест',
    skillId: 'skill-a',
    skillName: 'Разработка',
    skillColor: Colors.blue,
    skillIcon: Icons.code_rounded,
    xp: 20,
    isCompletion: true,
    at: now.subtract(const Duration(days: 1)),
  );

  test('uses Roadmap progress and the existing Next Action ordering', () async {
    final stage = SkillTreeNode(
      id: 'stage-a',
      title: 'Практика',
      requiredQuestCompletions: 3,
    );
    final fixture = await load(
      skill: skill(stages: [stage]),
      tasks: [
        task('done-1', done: true, stageId: stage.id),
        task('done-2', done: true, stageId: stage.id),
        task('active', stageId: stage.id, priority: Priority.high),
      ],
    );
    addTearDown(fixture.state.dispose);

    final nextAction = const NextActionResolver().resolve(
      skills: fixture.state.roadmapSkills,
      tasks: fixture.state.tasks,
      selectedSkillId: fixture.state.selectedSkillId,
    );
    final momentum = builder.build(state: fixture.state, now: now);

    expect(momentum?.reason, MomentumReason.stageOneQuestRemaining);
    expect(momentum?.taskId, nextAction.candidate?.task.id);
    expect(momentum?.remainingCount, 1);
  });

  test(
    'uses the injected Goal progress authority without local formula',
    () async {
      final fixture = await load(skill: skill(), tasks: [task('active')]);
      addTearDown(fixture.state.dispose);
      const goalBuilder = MomentumViewDataBuilder(
        goalProgressEngine: _FixedGoalProgressEngine(.8),
      );

      final momentum = goalBuilder.build(state: fixture.state, now: now);

      expect(momentum?.reason, MomentumReason.goalMeaningfullyAdvanced);
      expect(momentum?.progressFraction, .8);
    },
  );

  test(
    'building is read-only: no notify, save, XP, or selection change',
    () async {
      final fixture = await load(
        skill: skill(),
        tasks: [task('active', minimumAction: 'Открыть проект')],
      );
      addTearDown(fixture.state.dispose);
      var notifications = 0;
      fixture.state.addListener(() => notifications++);
      final beforeXp = fixture.state.profile.xp;
      final beforeSkill = fixture.state.selectedSkillId;
      final beforeStatus = fixture.state.persistenceStatus;

      final momentum = builder.build(state: fixture.state, now: now);
      await Future<void>.delayed(Duration.zero);

      expect(momentum?.reason, MomentumReason.minimumActionAvailable);
      expect(notifications, 0);
      expect(fixture.storage.saveCalls, 0);
      expect(fixture.state.profile.xp, beforeXp);
      expect(fixture.state.selectedSkillId, beforeSkill);
      expect(identical(fixture.state.persistenceStatus, beforeStatus), isTrue);
    },
  );

  test(
    'profile/theme persistence signals do not change detached result',
    () async {
      final fixture = await load(
        skill: skill(),
        tasks: [task('active', minimumAction: 'Открыть проект')],
      );
      addTearDown(fixture.state.dispose);
      final before = builder.build(state: fixture.state, now: now);

      fixture.state.profile.name = 'Другое имя';
      fixture.state.toggleTheme();
      await fixture.state.flushSaves();
      final after = builder.build(state: fixture.state, now: now);

      expect(after, before);
    },
  );

  test(
    'relevant history and Stage facts change the derived snapshot',
    () async {
      final stage = SkillTreeNode(
        id: 'stage-a',
        title: 'Практика',
        requiredQuestCompletions: 3,
      );
      final active = task('active', stageId: stage.id);
      final first = task('first', stageId: stage.id);
      final second = task('second', stageId: stage.id);
      final fixture = await load(
        skill: skill(stages: [stage]),
        tasks: [active, first, second],
      );
      addTearDown(fixture.state.dispose);

      expect(builder.build(state: fixture.state, now: now), isNull);

      fixture.state.history.add(completion(active.id));
      expect(
        builder.build(state: fixture.state, now: now)?.reason,
        MomentumReason.recentRealProgress,
      );

      fixture.state.history.clear();
      first.isDone = true;
      second.isDone = true;
      final stageMomentum = builder.build(state: fixture.state, now: now);
      expect(stageMomentum?.reason, MomentumReason.stageOneQuestRemaining);
      expect(stageMomentum?.remainingCount, 1);
    },
  );
}
