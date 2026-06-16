import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/engines/roadmap_engine.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/utils.dart';

class _InMemoryStorageService extends StorageService {
  bool? _theme;
  int? _bestStreak;

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
  Future<bool?> loadSfxEnabled() async => true;

  @override
  Future<void> saveSfxEnabled(bool enabled) async {}

  @override
  Future<int?> loadBestStreak() async => _bestStreak;

  @override
  Future<void> saveBestStreak(int value) async {
    _bestStreak = value;
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

void main() {
  group('streak protection', () {
    late AppState state;
    late Task task;

    DateTime startOfWeek(DateTime date) {
      final day = dateOnly(date);
      return day.subtract(Duration(days: day.weekday - 1));
    }

    setUp(() {
      state = AppState(storage: _InMemoryStorageService(), seedDefaults: true);
      task = state.tasks.firstWhere(
        (candidate) => candidate.type == TaskType.repeating,
      );
    });

    tearDown(() {
      state.dispose();
    });

    test('uses weekly protection charge for a single missed repeat period', () {
      final now = DateTime.now();
      task
        ..isDone = false
        ..streak = 5
        ..nextResetAt = now.subtract(const Duration(hours: 1));
      state.profile
        ..streakProtectionCharges = 1
        ..streakProtectionRefilledAt = startOfWeek(now);

      state.checkResets();

      expect(task.streak, 5);
      expect(state.profile.streakProtectionCharges, 0);
      expect(state.profile.lastStreakProtectionTaskTitle, task.title);
      expect(task.nextResetAt, isNotNull);
      expect(task.nextResetAt!.isAfter(DateTime.now()), isTrue);
    });

    test('resets streak when protection charge is already spent', () {
      final now = DateTime.now();
      task
        ..isDone = false
        ..streak = 5
        ..nextResetAt = now.subtract(const Duration(hours: 1));
      state.profile
        ..streakProtectionCharges = 0
        ..streakProtectionRefilledAt = startOfWeek(now);

      state.checkResets();

      expect(task.streak, 0);
      expect(state.profile.streakProtectionCharges, 0);
    });

    test('reset clears repeating minimum action progress', () {
      final now = DateTime.now();
      task
        ..isDone = true
        ..minimumAction = 'Start small'
        ..minimumActionDoneAt = now.subtract(const Duration(hours: 2))
        ..minimumActionEarnedXP = 10
        ..earnedXP = 10
        ..nextResetAt = now.subtract(const Duration(minutes: 1));

      state.checkResets();

      expect(task.isDone, isFalse);
      expect(task.minimumActionDoneAt, isNull);
      expect(task.minimumActionEarnedXP, 0);
      expect(state.canCompleteMinimumAction(task), isTrue);
    });

    test('best streak does not decrease after undo', () {
      task.streak = 6;

      state.completeTask(task.id);

      expect(task.streak, 7);
      expect(state.bestStreak, 7);

      state.uncompleteTask(task.id);

      expect(task.streak, 6);
      expect(state.bestStreak, 7);
    });
  });

  group('weekly goals', () {
    late AppState state;

    setUp(() {
      state = AppState(storage: _InMemoryStorageService(), seedDefaults: true);
    });

    tearDown(() {
      state.dispose();
    });

    test('saves one goal per week and tracks key result progress', () {
      final weekDate = DateTime(2026, 5, 14);

      state.saveWeeklyGoal(
        weekStart: weekDate,
        title: 'Build weekly analytics',
        keyResults: [
          WeeklyKeyResult(id: '', title: 'Create week chart'),
          WeeklyKeyResult(id: '', title: 'Add key results'),
        ],
      );

      final goal = state.weeklyGoalForWeek(DateTime(2026, 5, 11));

      expect(goal, isNotNull);
      expect(goal!.title, 'Build weekly analytics');
      expect(goal.weekStart, DateTime(2026, 5, 11));
      expect(goal.keyResults, hasLength(2));
      expect(goal.progress, 0);

      state.toggleWeeklyKeyResult(goal.id, goal.keyResults.first.id);

      expect(goal.completedKeyResults, 1);
      expect(goal.progress, 0.5);
      expect(goal.keyResults.first.completedAt, isNotNull);
    });
  });

  group('goal reviews', () {
    late AppState state;

    setUp(() {
      state = AppState(storage: _InMemoryStorageService(), seedDefaults: true);
    });

    tearDown(() {
      state.dispose();
    });

    test('adds review entry to skill goal history', () {
      final skill = state.skills.first;
      final review = GoalReviewEntry(
        id: 'review-1',
        wins: 'Закрыт первый квест',
        blockers: 'Мало времени',
        adjustment: 'Упростить следующий шаг',
        nextFocus: 'Вернуться к этапу Основа',
        updatedPlan: true,
      );

      state.addGoalReview(skill.id, review);

      expect(skill.goalSpec.reviews, hasLength(1));
      expect(skill.goalSpec.reviews.first.id, 'review-1');
      expect(skill.goalSpec.reviews.first.updatedPlan, isTrue);
    });
  });

  group('roadmap templates', () {
    late AppState state;

    setUp(() {
      state = AppState(storage: _InMemoryStorageService(), seedDefaults: true);
    });

    tearDown(() {
      state.dispose();
    });

    test(
      'adds roadmap roads without deleting existing stages or quest links',
      () {
        final skill = state.skills.first;
        final existingStage = SkillTreeNode(
          id: 'existing-stage',
          title: 'Существующий этап',
          requiredQuestCompletions: 2,
        );
        state.addSkillTreeNode(skill.id, existingStage);
        final linkedQuest = Task(
          id: 'linked-quest',
          title: 'Сделать практику этапа',
          skillId: skill.id,
          xpReward: 20,
          type: TaskType.shortTerm,
          treeNodeId: existingStage.id,
        );
        state.addTask(linkedQuest);

        final beforeCount = skill.treeNodes.length;
        final beforeIds = skill.treeNodes.map((node) => node.id).toSet();

        state.addRoadmapTemplate(
          skill.id,
          const RoadmapTemplateConfig(
            template: RoadmapTemplate.normal,
            stagesPerPath: 3,
          ),
        );

        expect(skill.treeNodes, hasLength(beforeCount + 6));
        final addedStages = skill.treeNodes
            .where((node) => !beforeIds.contains(node.id))
            .toList();
        expect(addedStages, hasLength(6));
        expect(
          addedStages.where((node) => node.prerequisiteIds.isEmpty),
          hasLength(2),
        );
        expect(
          skill.treeNodes.any((node) => node.id == existingStage.id),
          isTrue,
        );
        expect(linkedQuest.treeNodeId, existingStage.id);
      },
    );

    test('extends a roadmap path after its terminal stage', () {
      final skill = state.skills.first;
      final root = SkillTreeNode(id: 'root-stage', title: 'Основа');
      final terminal = SkillTreeNode(
        id: 'terminal-stage',
        title: 'Практика',
        prerequisiteIds: [root.id],
      );
      state.addSkillTreeNode(skill.id, root);
      state.addSkillTreeNode(skill.id, terminal);
      final linkedQuest = Task(
        id: 'terminal-quest',
        title: 'Сделать практику',
        skillId: skill.id,
        xpReward: 20,
        type: TaskType.shortTerm,
        treeNodeId: terminal.id,
      );
      state.addTask(linkedQuest);

      final created = state.extendRoadmapPath(
        skill.id,
        root.id,
        title: 'Новый рубеж',
      );

      expect(created, isNotNull);
      expect(created!.title, 'Новый рубеж');
      expect(created.prerequisiteIds, [terminal.id]);
      expect(skill.treeNodes, contains(created));
      expect(linkedQuest.treeNodeId, terminal.id);
    });
  });

  group('minimum action flow', () {
    late AppState state;
    late Task task;

    setUp(() {
      state = AppState(storage: _InMemoryStorageService(), seedDefaults: true);
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

      expect(message, contains('Старт'));
      expect(message, contains('+18 XP'));
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

      expect(message, contains('+42 XP'));
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

  group('boss improvements', () {
    late AppState state;
    late Skill skill;
    late Task task;
    late Boss boss;

    setUp(() {
      state = AppState(storage: _InMemoryStorageService(), seedDefaults: true);
      skill = state.skills.firstWhere((item) => item.name == 'Python');
      task = state.tasks.firstWhere(
        (candidate) => candidate.title == 'Написать REST API на FastAPI',
      );

      state.updateTask(
        task,
        title: task.title,
        xpReward: task.xpReward,
        type: task.type,
        repeatFrequency: task.repeatFrequency,
        repeatCustomDays: task.repeatCustomDays,
        priority: Priority.high,
        minimumAction: task.minimumAction,
        subtasks: List.of(task.subtasks),
        tags: List.of(task.tags),
        notificationsEnabled: false,
        notificationHour: null,
        notificationMinute: null,
        treeNodeId: task.treeNodeId,
      );

      boss = Boss(
        id: 'python-boss',
        title: 'Прокрастинация',
        skillId: skill.id,
        targetStreak: 7,
      );
      state.addBoss(boss);
    });

    tearDown(() {
      state.dispose();
    });

    test('boss starts attacking when high priority task is stalled', () {
      final snapshot = state.bossSnapshot(boss);

      expect(snapshot.stalledHighPriorityTasks, 1);
      expect(snapshot.isUnderAttack, isTrue);
      expect(snapshot.phaseLabel, 'Атакует');
      expect(boss.hp, 100);
    });

    test('minimum action relieves pressure and damages boss', () {
      state.completeMinimumAction(task.id);
      final snapshot = state.bossSnapshot(boss);

      expect(snapshot.stalledHighPriorityTasks, 0);
      expect(snapshot.startPercent, greaterThan(0));
      expect(snapshot.priorityPercent, 100);
      expect(snapshot.isUnderAttack, isFalse);
      expect(boss.hp, lessThan(100));
    });
  });

  group('skill tree', () {
    late AppState state;
    late Skill skill;

    setUp(() {
      state = AppState(storage: _InMemoryStorageService(), seedDefaults: true);
      skill = Skill(
        id: 'backend',
        name: 'Backend',
        goal: 'Build production APIs',
        color: const Color(0xFF4A9EFF),
        icon: Icons.code,
        treeNodes: [
          SkillTreeNode(
            id: 'basics',
            title: 'API basics',
            xpReward: 20,
            requiredQuestCompletions: 1,
          ),
          SkillTreeNode(
            id: 'auth',
            title: 'JWT auth',
            xpReward: 30,
            prerequisiteIds: ['basics'],
            requiredQuestCompletions: 1,
          ),
        ],
      );
      state.addSkill(skill);
    });

    tearDown(() {
      state.dispose();
    });

    test('unlocks dependent nodes and awards xp on mastery', () {
      final basics = skill.treeNodes.first;
      final auth = skill.treeNodes.last;

      expect(skill.treeNodeStatus(basics), SkillTreeNodeStatus.active);
      expect(skill.treeNodeStatus(auth), SkillTreeNodeStatus.locked);
      expect(state.canMasterSkillTreeNode(skill.id, basics.id), isFalse);

      state.addTask(
        Task(
          id: 'basics-practice',
          title: 'Create first endpoint',
          skillId: skill.id,
          xpReward: 20,
          type: TaskType.shortTerm,
          isDone: true,
          treeNodeId: basics.id,
        ),
      );
      final message = state.masterSkillTreeNode(skill.id, basics.id);

      expect(message, contains('Этап освоен'));
      expect(message, contains('+20 XP'));
      expect(basics.isMastered, isTrue);
      expect(skill.treeNodeStatus(auth), SkillTreeNodeStatus.active);
      expect(skill.masteredTreeNodeCount, 1);
      expect(skill.treeProgress, 0.5);
      expect(state.profile.totalXpEarned, 20);
      expect(state.todayStats?.xpEarned, 20);
    });

    test('tree mastery contributes to boss progress', () {
      final boss = Boss(
        id: 'backend-boss',
        title: 'Fear of complexity',
        skillId: skill.id,
        targetStreak: 7,
      );
      state.addBoss(boss);

      state.addTask(
        Task(
          id: 'basics-boss-practice',
          title: 'Create first endpoint',
          skillId: skill.id,
          xpReward: 20,
          type: TaskType.shortTerm,
          isDone: true,
          treeNodeId: 'basics',
        ),
      );
      state.masterSkillTreeNode(skill.id, 'basics');

      final snapshot = state.bossSnapshot(boss);

      expect(snapshot.masteredTreeNodes, 1);
      expect(snapshot.totalTreeNodes, 2);
      expect(snapshot.treePercent, 50);
      expect(
        snapshot.impactPercent,
        greaterThanOrEqualTo(snapshot.treePercent),
      );
      expect(boss.hp, lessThan(100));
    });

    test(
      'links tasks to mastery map nodes and clears link on node removal',
      () {
        final task = Task(
          id: 'linked-task',
          title: 'Create first endpoint',
          skillId: skill.id,
          xpReward: 20,
          type: TaskType.shortTerm,
          treeNodeId: 'basics',
        );
        state.addTask(task);

        expect(state.tasksForTreeNode(skill.id, 'basics'), [task]);
        expect(task.treeNodeId, 'basics');

        state.removeSkillTreeNode(skill.id, 'basics');

        expect(task.treeNodeId, isNull);
        expect(state.tasksForTreeNode(skill.id, 'basics'), isEmpty);
        expect(skill.treeNodes.single.prerequisiteIds, isEmpty);
      },
    );

    test('ignores invalid mastery map node links on task update', () {
      final task = Task(
        id: 'invalid-linked-task',
        title: 'Protect route',
        skillId: skill.id,
        xpReward: 20,
        type: TaskType.shortTerm,
        treeNodeId: 'basics',
      );
      state.addTask(task);

      state.updateTask(
        task,
        title: task.title,
        xpReward: task.xpReward,
        type: task.type,
        repeatFrequency: task.repeatFrequency,
        repeatCustomDays: task.repeatCustomDays,
        priority: task.priority,
        minimumAction: task.minimumAction,
        subtasks: List.of(task.subtasks),
        tags: List.of(task.tags),
        notificationsEnabled: task.notificationsEnabled,
        notificationHour: task.notificationHour,
        notificationMinute: task.notificationMinute,
        treeNodeId: 'missing-node',
      );

      expect(task.treeNodeId, isNull);
    });

    test('requires completed linked quests before mastery', () {
      final node = SkillTreeNode(
        id: 'deploy',
        title: 'Deploy API',
        xpReward: 40,
        requiredQuestCompletions: 2,
      );
      state.addSkillTreeNode(skill.id, node);

      state.addTask(
        Task(
          id: 'deploy-1',
          title: 'Prepare Dockerfile',
          skillId: skill.id,
          xpReward: 20,
          type: TaskType.shortTerm,
          isDone: true,
          treeNodeId: node.id,
        ),
      );
      expect(state.canMasterSkillTreeNode(skill.id, node.id), isFalse);

      state.addTask(
        Task(
          id: 'deploy-2',
          title: 'Push image',
          skillId: skill.id,
          xpReward: 20,
          type: TaskType.shortTerm,
          isDone: true,
          treeNodeId: node.id,
        ),
      );
      expect(state.canMasterSkillTreeNode(skill.id, node.id), isTrue);
    });

    test('new mastery map nodes default to three required quests', () {
      final legacyNode = SkillTreeNode(id: 'legacy', title: 'Legacy node');

      expect(legacyNode.questTarget, 3);
    });
  });

  group('rewards and buffs', () {
    late AppState state;

    setUp(() {
      state = AppState(
        storage: _InMemoryStorageService(),
        random: math.Random(1),
        seedDefaults: true,
      );
    });

    tearDown(() {
      state.dispose();
    });

    test('unlocks a daily reward chest after five completed quests', () {
      final questIds = state.tasks.map((task) => task.id).toList();

      for (final questId in questIds) {
        state.completeTask(questId);
      }

      expect(state.todayStats?.tasksCompleted, 5);
      expect(state.unopenedRewardChests, hasLength(1));
      expect(state.unopenedRewardChests.first.title, 'Сундук дисциплины');
      expect(state.consumeRewardChestNotifications(), hasLength(1));
      expect(state.consumeRewardChestNotifications(), isEmpty);

      final rewardMessage = state.openRewardChest(
        state.unopenedRewardChests.first.id,
      );

      expect(rewardMessage, contains('Сундук дисциплины'));
      expect(state.unopenedRewardChests, isEmpty);
      final chestBuff = state.activeBuffs.firstWhere(
        (buff) => buff.sourceChestId != null,
      );
      expect(chestBuff.expiresAt, isNotNull);
      expect(chestBuff.expiresAt!.isAfter(DateTime.now()), isTrue);
      expect(
        chestBuff.expiresAt!.difference(DateTime.now()),
        greaterThan(const Duration(hours: 23)),
      );
    });

    test('undo removes an invalid daily chest and its opened buff', () {
      final questIds = state.tasks.map((task) => task.id).toList();

      for (final questId in questIds) {
        state.completeTask(questId);
      }

      final chest = state.rewardChests.firstWhere(
        (item) => item.sourceKey.startsWith('daily5:'),
      );
      final chestId = chest.id;
      state.openRewardChest(chestId);

      expect(state.rewardChests.any((item) => item.id == chestId), isTrue);
      expect(state.buffs.any((buff) => buff.sourceChestId == chestId), isTrue);

      state.uncompleteTask(questIds.last);

      expect(state.todayStats?.tasksCompleted, 4);
      expect(state.rewardChests.any((item) => item.id == chestId), isFalse);
      expect(state.buffs.any((buff) => buff.sourceChestId == chestId), isFalse);
      expect(
        state.consumeRewardChestNotifications().any(
          (item) => item.id == chestId,
        ),
        isFalse,
      );
    });

    test('grants a focus buff after two same-skill quests in a row', () {
      final pullUpTasks = state.tasks
          .where((task) => task.skillId == state.skills.first.id)
          .take(2)
          .toList();

      state.completeTask(pullUpTasks[0].id);
      state.completeTask(pullUpTasks[1].id);

      final focusBuff = state.activeBuffs.firstWhere(
        (buff) => buff.title == 'Фокус',
      );

      expect(focusBuff.type, BuffType.skillFocusXpBoost);
      expect(focusBuff.skillId, state.skills.first.id);
      expect(focusBuff.bonusPercent, 12);
      expect(state.consumeBuffNotifications().last.title, 'Фокус');
    });

    test('undo removes focus buff when same-skill chain is broken', () {
      final pullUpTasks = state.tasks
          .where((task) => task.skillId == state.skills.first.id)
          .take(2)
          .toList();

      state.completeTask(pullUpTasks[0].id);
      state.completeTask(pullUpTasks[1].id);

      final focusBuff = state.activeBuffs.firstWhere(
        (buff) => buff.title == 'Фокус',
      );

      state.uncompleteTask(pullUpTasks[1].id);

      expect(state.buffs.any((buff) => buff.id == focusBuff.id), isFalse);
      expect(
        state.consumeBuffNotifications().any((buff) => buff.id == focusBuff.id),
        isFalse,
      );
    });

    test('grants a flow buff after three completed quests in a day', () {
      final questIds = state.tasks.take(3).map((task) => task.id).toList();

      for (final questId in questIds) {
        state.completeTask(questId);
      }

      final flowBuff = state.activeBuffs.firstWhere(
        (buff) => buff.title == 'Поток',
      );

      expect(flowBuff.type, BuffType.questRushXpBoost);
      expect(flowBuff.charges, 2);
      expect(flowBuff.bonusPercent, 10);
      expect(
        state.consumeBuffNotifications().any((buff) => buff.title == 'Поток'),
        isTrue,
      );
    });

    test('undo removes flow buff when daily count drops below trigger', () {
      final questIds = state.tasks.take(3).map((task) => task.id).toList();

      for (final questId in questIds) {
        state.completeTask(questId);
      }

      final flowBuff = state.activeBuffs.firstWhere(
        (buff) => buff.title == 'Поток',
      );

      state.uncompleteTask(questIds.last);

      expect(state.todayStats?.tasksCompleted, 2);
      expect(state.buffs.any((buff) => buff.id == flowBuff.id), isFalse);
      expect(
        state.consumeBuffNotifications().any((buff) => buff.id == flowBuff.id),
        isFalse,
      );
    });

    test('unlocks a streak chest on important repeating milestones', () {
      final task = state.tasks.firstWhere(
        (candidate) => candidate.title == 'Сделать 3 подхода подтягиваний',
      );
      task.streak = 6;

      state.completeTask(task.id);

      expect(task.streak, 7);
      expect(state.unopenedRewardChests, hasLength(1));
      expect(state.unopenedRewardChests.first.title, 'Сундук серии');
      expect(state.unopenedRewardChests.first.rarity, RewardRarity.rare);
      expect(
        state.consumeRewardChestNotifications().first.title,
        'Сундук серии',
      );

      final chestId = state.rewardChests.first.id;

      state.uncompleteTask(task.id);

      expect(task.streak, 6);
      expect(state.rewardChests.any((chest) => chest.id == chestId), isFalse);
    });

    test('defeating a stronger boss unlocks an epic chest', () {
      final skill = Skill(
        id: 'discipline',
        name: 'Discipline',
        goal: 'Hold the line',
        color: const Color(0xFF34C759),
        icon: Icons.shield,
      );
      state.addSkill(skill);

      final task = Task(
        id: 'discipline-daily',
        title: 'Daily discipline quest',
        skillId: skill.id,
        xpReward: 10,
        type: TaskType.repeating,
        streak: 13,
      );
      state.addTask(task);

      final boss = Boss(
        id: 'discipline-boss',
        title: 'Resistance',
        skillId: skill.id,
        targetStreak: 14,
      );
      state.addBoss(boss);

      state.completeTask(task.id);

      expect(boss.isDefeated, isTrue);
      expect(state.unopenedRewardChests, hasLength(1));
      expect(state.unopenedRewardChests.first.title, 'Эпический сундук победы');
      expect(state.unopenedRewardChests.first.rarity, RewardRarity.epic);

      final chestId = state.unopenedRewardChests.first.id;

      state.uncompleteTask(task.id);

      expect(boss.isDefeated, isFalse);
      expect(boss.hp, greaterThan(0));
      expect(state.rewardChests.any((chest) => chest.id == chestId), isFalse);
    });

    test('buff increases xp on completion and is restored on undo', () {
      final task = state.tasks.firstWhere(
        (candidate) => candidate.title == 'Пройти урок: функции и замыкания',
      );

      state.buffs.add(
        Buff(
          id: 'buff-1',
          type: BuffType.nextQuestXpBoost,
          title: 'Импульс',
          description: 'Следующий квест даст +20% XP.',
          bonusPercent: 20,
          charges: 1,
          createdAt: DateTime.now(),
        ),
      );

      expect(state.previewBuffBonusXP(task), 4);

      final message = state.completeTask(task.id);

      expect(message, contains('эффект +4'));
      expect(task.earnedXP, 24);
      expect(task.bonusXpEarned, 4);
      expect(state.activeBuffs, isEmpty);

      state.uncompleteTask(task.id);

      expect(task.isDone, isFalse);
      expect(task.bonusXpEarned, 0);
      expect(task.consumedBuffIds, isEmpty);
      expect(state.activeBuffs, hasLength(1));
      expect(state.activeBuffs.first.charges, 1);
      expect(state.previewBuffBonusXP(task), 4);
    });

    test('buff bonus is capped per quest', () {
      final task = state.tasks.firstWhere(
        (candidate) => candidate.title == 'Пройти урок: функции и замыкания',
      );
      state.buffs.addAll([
        Buff(
          id: 'buff-1',
          type: BuffType.nextQuestXpBoost,
          title: 'Boost 1',
          description: '+25%',
          bonusPercent: 25,
          charges: 1,
          createdAt: DateTime.now(),
        ),
        Buff(
          id: 'buff-2',
          type: BuffType.nextQuestXpBoost,
          title: 'Boost 2',
          description: '+25%',
          bonusPercent: 25,
          charges: 1,
          createdAt: DateTime.now(),
        ),
        Buff(
          id: 'buff-3',
          type: BuffType.nextQuestXpBoost,
          title: 'Boost 3',
          description: '+25%',
          bonusPercent: 25,
          charges: 1,
          createdAt: DateTime.now(),
        ),
      ]);

      expect(state.previewBuffBonusXP(task), 10);

      state.completeTask(task.id);

      expect(task.bonusXpEarned, 10);
      expect(task.consumedBuffIds, ['buff-1', 'buff-2']);
      expect(state.activeBuffs.map((buff) => buff.id), ['buff-3']);
    });
  });
}
