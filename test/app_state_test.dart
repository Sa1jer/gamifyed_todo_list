import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/engines/goal_progress_engine.dart';
import 'package:todo_list_app/engines/roadmap_engine.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/utils.dart';

class _InMemoryStorageService extends StorageService {
  List<Skill> _skills = [];
  List<Task> _tasks = [];
  bool? _theme;
  bool? _tooltipsEnabled;
  bool? _onboardingSeen;
  TutorialProgress? _tutorialProgress;
  int? _bestStreak;

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasSavedSkills() async => _skills.isNotEmpty;

  @override
  Future<bool> hasSavedTasks() async => _tasks.isNotEmpty;

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
  Future<bool?> loadTooltipsEnabled() async => _tooltipsEnabled;

  @override
  Future<void> saveTooltipsEnabled(bool enabled) async {
    _tooltipsEnabled = enabled;
  }

  @override
  Future<bool?> loadOnboardingSeen() async => _onboardingSeen;

  @override
  Future<void> saveOnboardingSeen(bool seen) async {
    _onboardingSeen = seen;
  }

  @override
  Future<TutorialProgress?> loadTutorialProgress() async => _tutorialProgress;

  @override
  Future<void> saveTutorialProgress(TutorialProgress progress) async {
    _tutorialProgress = progress;
  }

  @override
  Future<int?> loadBestStreak() async => _bestStreak;

  @override
  Future<void> saveBestStreak(int value) async {
    _bestStreak = value;
  }

  @override
  Future<List<Skill>> loadSkills() async => List.of(_skills);

  @override
  Future<void> saveSkills(List<Skill> skills) async {
    _skills = List.of(skills);
  }

  @override
  Future<List<Task>> loadTasks() async => List.of(_tasks);

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    _tasks = List.of(tasks);
  }

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

Uint8List _validPngBytes() =>
    Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00]);

Uint8List _validJpegBytes() =>
    Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);

Uint8List _invalidImageBytes() => Uint8List.fromList([1, 2, 3, 4]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('xp owner safety', () {
    test('removeXP rejects negative values', () {
      final profile = UserProfile(name: 'Tester')..xp = 20;

      expect(() => profile.removeXP(-5), throwsA(isA<ArgumentError>()));
      expect(profile.xp, 20);
    });
  });

  group('device UI preferences', () {
    test('reduced motion persists outside domain snapshots', () async {
      final storage = _InMemoryStorageService();
      await storage.init();
      final state = AppState(storage: storage);
      await state.loadSavedData();

      expect(state.reducedMotion, isFalse);
      state.toggleReducedMotion();
      await state.flushSaves();
      expect(await storage.loadReducedMotion(), isTrue);

      final restarted = AppState(storage: storage);
      await restarted.loadSavedData();
      expect(restarted.reducedMotion, isTrue);

      state.dispose();
      restarted.dispose();
    });
  });

  group('mutable model list safety', () {
    test('sync methods accept fixed-length constructor lists', () {
      final task = Task(
        id: 'fixed-task',
        title: 'Проверить подзадачи',
        skillId: 'skill-1',
        xpReward: 20,
        type: TaskType.shortTerm,
        subtasks: List<String>.filled(1, 'Первый шаг'),
        subtaskDone: List<bool>.filled(0, false),
      );
      final skill = Skill(
        id: 'fixed-skill',
        name: 'Навык',
        goal: 'Проверить список',
        color: Colors.blue,
        icon: Icons.check,
        checklist: List<String>.filled(1, 'Критерий'),
        checklistDone: List<bool>.filled(0, false),
      );
      final node = SkillTreeNode(
        id: 'fixed-node',
        title: 'Этап',
        checklist: List<String>.filled(1, 'Критерий этапа'),
        checklistDone: List<bool>.filled(0, false),
      );

      expect(task.syncSubtaskDone, returnsNormally);
      expect(skill.syncChecklistDone, returnsNormally);
      expect(node.syncChecklistDone, returnsNormally);
      expect(task.subtaskDone, [false]);
      expect(skill.checklistDone, [false]);
      expect(node.checklistDone, [false]);

      task.subtasks.add('Второй шаг');
      task.syncSubtaskDone();
      expect(task.subtaskDone, [false, false]);
    });

    test('goal, weekly, and skill mutation paths copy caller-owned lists', () {
      final review = GoalReviewEntry(id: 'review-1');
      final goal = GoalSpec(
        text: 'Надёжная цель',
        reviews: List<GoalReviewEntry>.filled(0, review),
      );
      final keyResult = WeeklyKeyResult(id: 'result-1', title: 'Шаг');
      final weeklyGoal = WeeklyGoal(
        id: 'week-1',
        weekStart: DateTime(2026, 6, 29),
        title: 'Неделя',
        keyResults: List<WeeklyKeyResult>.filled(0, keyResult),
      );

      expect(() => goal.reviews.add(review), returnsNormally);
      expect(() => weeklyGoal.keyResults.add(keyResult), returnsNormally);

      final state = AppState(
        storage: _InMemoryStorageService(),
        seedDefaults: false,
      );
      addTearDown(state.dispose);
      final skill = Skill(
        id: 'fixed-skill-update',
        name: 'Навык',
        goal: 'Цель',
        color: Colors.blue,
        icon: Icons.check,
      );
      state.addSkill(skill);

      expect(
        () => state.updateSkill(
          skill,
          name: skill.name,
          goal: skill.goal,
          checklist: List<String>.filled(2, 'Критерий'),
          color: skill.color,
          icon: skill.icon,
        ),
        returnsNormally,
      );
      expect(skill.checklistDone, [false, false]);
    });

    test('invalid notification time is normalized on create and update', () {
      final task = Task(
        id: 'invalid-reminder',
        title: 'Напоминание',
        skillId: 'skill-1',
        xpReward: 20,
        type: TaskType.shortTerm,
        notificationsEnabled: true,
        notificationHour: 24,
        notificationMinute: -1,
      );

      expect(task.notificationsEnabled, isFalse);
      expect(task.notificationHour, isNull);
      expect(task.notificationMinute, isNull);

      final state = AppState(
        storage: _InMemoryStorageService(),
        seedDefaults: false,
      );
      addTearDown(state.dispose);
      state.tasks.add(task);
      state.updateTask(
        task,
        title: task.title,
        description: task.description,
        xpReward: task.xpReward,
        type: task.type,
        repeatFrequency: task.repeatFrequency,
        repeatCustomDays: task.repeatCustomDays,
        priority: task.priority,
        minimumAction: task.minimumAction,
        subtasks: task.subtasks,
        tags: task.tags,
        notificationsEnabled: true,
        notificationHour: 12,
        notificationMinute: 60,
        treeNodeId: null,
      );

      expect(task.notificationsEnabled, isFalse);
      expect(task.notificationHour, isNull);
      expect(task.notificationMinute, isNull);
    });
  });

  group('course nudge runtime dismiss', () {
    test('dismissed keys are session-only', () {
      final storage = _InMemoryStorageService();
      final state = AppState(storage: storage, seedDefaults: false);

      state.dismissCourseNudge('skill:review:createFocusQuest:target');

      expect(
        state.isCourseNudgeDismissed('skill:review:createFocusQuest:target'),
        isTrue,
      );

      final restarted = AppState(storage: storage, seedDefaults: false);
      expect(
        restarted.isCourseNudgeDismissed(
          'skill:review:createFocusQuest:target',
        ),
        isFalse,
      );

      state.dispose();
      restarted.dispose();
    });
  });

  group('task inbox', () {
    late AppState state;
    late Skill skill;

    setUp(() {
      state = AppState(storage: _InMemoryStorageService(), seedDefaults: false);
      skill = Skill(
        id: 'skill-inbox-boundary',
        name: 'Flutter',
        goal: 'Не смешивать Задачник',
        color: Colors.blue,
        icon: Icons.code,
        treeNodes: [
          SkillTreeNode(
            id: 'stage-1',
            title: 'Stage 1',
            requiredQuestCompletions: 1,
          ),
        ],
      );
      state.addSkill(skill);
    });

    tearDown(() => state.dispose());

    test('creates inbox task under the permanent inbox skill', () {
      final created = state.addInboxTask('  Купить молоко  ');

      expect(created, isTrue);
      expect(state.tasks, hasLength(1));
      final task = state.tasks.single;
      expect(task.title, 'Купить молоко');
      expect(task.isInbox, isTrue);
      expect(task.skillId, kInboxSkillId);
      expect(task.treeNodeId, isNull);
      expect(task.xpReward, 0);
      expect(state.inboxTasks, [task]);
      expect(state.tasksForSkill(kInboxSkillId), [task]);
      expect(state.activeTaskCountForSkill(kInboxSkillId), 1);
      expect(state.tasksForSkill(skill.id), isEmpty);
      expect(state.activeTaskCountForSkill(skill.id), 0);
    });

    test('rejects blank inbox task title', () {
      expect(state.addInboxTask('   '), isFalse);
      expect(state.inboxTasks, isEmpty);
    });

    test('inbox skill is permanent and excluded from roadmap skills', () {
      expect(state.skills.any((skill) => skill.id == kInboxSkillId), isTrue);
      expect(
        state.roadmapSkills.any((skill) => skill.id == kInboxSkillId),
        isFalse,
      );

      final inbox = state.skills.firstWhere(
        (skill) => skill.id == kInboxSkillId,
      );
      state.updateSkill(
        inbox,
        name: 'Changed',
        goal: 'Changed',
        checklist: ['x'],
        color: Colors.red,
        icon: Icons.warning,
      );
      state.removeSkill(kInboxSkillId);

      final restored = state.skills.firstWhere(
        (skill) => skill.id == kInboxSkillId,
      );
      expect(restored.name, 'Задачник');
      expect(restored.level, 1);
      expect(restored.xp, 0);
      expect(restored.treeNodes, isEmpty);
    });

    test('completing inbox task grants isolated profile and daily XP', () {
      state.startTutorialModule(TutorialModuleIds.core);
      final tutorialStep = state.activeTutorialStepId;
      state.addInboxTask('Заплатить за интернет');
      final task = state.inboxTasks.single;
      final profileXp = state.profile.xp;
      final totalXp = state.profile.totalXpEarned;
      final skillXp = skill.xp;
      final skillLevel = skill.level;
      final achievementCount = state.achievements
          .where((achievement) => achievement.isUnlocked)
          .length;
      final chestCount = state.rewardChests.length;
      final buffCount = state.buffs.length;
      final progress = const GoalProgressEngine().snapshotForSkill(skill).value;

      final message = state.completeTask(task.id);

      expect(message, contains('+${AppState.inboxTaskXp} XP'));
      expect(task.isDone, isTrue);
      expect(task.earnedXP, AppState.inboxTaskXp);
      expect(state.profile.xp, profileXp + AppState.inboxTaskXp);
      expect(state.profile.totalXpEarned, totalXp + AppState.inboxTaskXp);
      expect(state.todayStats?.xpEarned, AppState.inboxTaskXp);
      expect(state.todayStats?.tasksCompleted, 1);
      expect(skill.xp, skillXp);
      expect(skill.level, skillLevel);
      expect(
        const GoalProgressEngine().snapshotForSkill(skill).value,
        progress,
      );
      expect(state.history, isEmpty);
      expect(
        state.achievements
            .where((achievement) => achievement.isUnlocked)
            .length,
        achievementCount,
      );
      expect(state.rewardChests.length, chestCount);
      expect(state.buffs.length, buffCount);
      expect(state.consumeGoalMilestoneNotifications(), isEmpty);
      expect(state.canMasterSkillTreeNode(skill.id, 'stage-1'), isFalse);
      expect(state.activeTutorialStepId, tutorialStep);
    });

    test('inbox task undo rolls back isolated profile and daily XP', () {
      state.addInboxTask('Разобрать почту');
      final task = state.inboxTasks.single;
      state.completeTask(task.id);

      state.uncompleteTask(task.id);

      expect(task.isDone, isFalse);
      expect(task.earnedXP, 0);
      expect(state.profile.xp, 0);
      expect(state.profile.totalXpEarned, 0);
      expect(state.todayStats?.xpEarned, 0);
      expect(state.todayStats?.tasksCompleted, 0);
      expect(skill.xp, 0);
      expect(state.history, isEmpty);
    });

    test('inbox task XP crosses and reverses a profile level boundary', () {
      state.profile.xp = state.profile.xpNeeded - 5;
      state.profile.totalXpEarned = state.profile.xp;
      state.addInboxTask('Закрыть маленькое дело');
      final task = state.inboxTasks.single;

      state.completeTask(task.id);

      expect(state.profile.level, 2);
      expect(state.profile.xp, 5);
      expect(state.profile.totalXpEarned, 1005);

      state.uncompleteTask(task.id);

      expect(state.profile.level, 1);
      expect(state.profile.xp, 995);
      expect(state.profile.totalXpEarned, 995);
    });

    test('normal skill quest still behaves as before', () {
      final quest = Task(
        id: 'skill-quest',
        title: 'Собрать экран',
        skillId: skill.id,
        xpReward: 20,
        type: TaskType.shortTerm,
      );
      state.addTask(quest);

      final message = state.completeTask(quest.id);

      expect(message, contains('+20 XP'));
      expect(state.profile.totalXpEarned, 20);
      expect(skill.xp, 20);
      expect(state.history, hasLength(1));
      expect(state.tasksForSkill(skill.id), [quest]);
      expect(state.inboxTasks, isEmpty);
    });

    test('completed quest archive is explicit and keeps earned XP', () {
      final quest = Task(
        id: 'archived-quest',
        title: 'Убрать выполненный квест',
        skillId: skill.id,
        xpReward: 20,
        type: TaskType.shortTerm,
      );
      state.addTask(quest);
      state.completeTask(quest.id);
      final profileXp = state.profile.xp;
      final skillXp = skill.xp;

      state.archiveCompletedTask(quest.id);

      expect(quest.isDone, isTrue);
      expect(quest.isArchived, isTrue);
      expect(state.profile.xp, profileXp);
      expect(skill.xp, skillXp);

      state.restoreArchivedTask(quest.id);

      expect(quest.isDone, isTrue);
      expect(quest.isArchived, isFalse);
      expect(state.profile.xp, profileXp);

      state.archiveCompletedTask(quest.id);
      state.uncompleteTask(quest.id);

      expect(quest.isDone, isFalse);
      expect(quest.isArchived, isFalse);
    });
  });

  group('next skill goal', () {
    late AppState state;
    late Skill skill;

    setUp(() {
      state = AppState(storage: _InMemoryStorageService(), seedDefaults: false);
      skill = Skill(
        id: 'skill-next-goal',
        name: 'Flutter',
        goal: 'Закрыть первую цель',
        goalSpec: GoalSpec(
          text: 'Закрыть первую цель',
          updatedAt: DateTime(2020),
        ),
        color: Colors.blue,
        icon: Icons.code,
        level: 4,
        xp: 35,
        treeNodes: [
          SkillTreeNode(
            id: 'completed-stage',
            title: 'Готовый этап',
            isMastered: true,
            masteredAt: DateTime(2024),
          ),
        ],
      );
      state.addSkill(skill);
    });

    tearDown(() => state.dispose());

    test('rejects empty, whitespace, and unchanged goal text', () {
      final updatedAt = skill.goalSpec.updatedAt;

      expect(
        state.setNextSkillGoal(skill.id, ''),
        NextGoalUpdateResult.invalid,
      );
      expect(
        state.setNextSkillGoal(skill.id, '   '),
        NextGoalUpdateResult.invalid,
      );
      expect(
        state.setNextSkillGoal(skill.id, '  Закрыть первую цель  '),
        NextGoalUpdateResult.unchanged,
      );
      expect(skill.goal, 'Закрыть первую цель');
      expect(skill.goalSpec.updatedAt, updatedAt);
      expect(skill.completedGoals, isEmpty);
    });

    test('requires completed RoadMap progress', () {
      skill.treeNodes.single.isMastered = false;

      expect(
        state.setNextSkillGoal(skill.id, 'Новая цель'),
        NextGoalUpdateResult.notCompleted,
      );
      expect(skill.goal, 'Закрыть первую цель');
      expect(skill.completedGoals, isEmpty);
    });

    test(
      'updates only goal text and timestamp after explicit confirmation',
      () {
        final stage = skill.treeNodes.single;
        final stageMasteredAt = stage.masteredAt;
        final skillId = skill.id;
        final level = skill.level;
        final xp = skill.xp;
        final profileXp = state.profile.xp;
        final oldUpdatedAt = skill.goalSpec.updatedAt;
        final completedAt = DateTime(2026, 6, 29, 12, 30);

        final result = state.setNextSkillGoal(
          skill.id,
          '  Выпустить следующее приложение  ',
          completedAt: completedAt,
        );

        expect(result, NextGoalUpdateResult.updated);
        expect(skill.goal, 'Выпустить следующее приложение');
        expect(skill.goalSpec.updatedAt.isAfter(oldUpdatedAt), isTrue);
        expect(skill.id, skillId);
        expect(skill.level, level);
        expect(skill.xp, xp);
        expect(state.profile.xp, profileXp);
        expect(skill.treeNodes, hasLength(1));
        expect(stage.isMastered, isTrue);
        expect(stage.masteredAt, stageMasteredAt);
        expect(skill.completedGoals, hasLength(1));
        expect(skill.completedRoadmaps, isEmpty);
        final archived = skill.completedGoals.single;
        expect(archived.id, isNotEmpty);
        expect(archived.skillId, skillId);
        expect(archived.goalText, 'Закрыть первую цель');
        expect(archived.completedAt, completedAt);
        expect(archived.progressAtCompletion, 1.0);
        expect(archived.completedStages, 1);
        expect(archived.totalStages, 1);
      },
    );

    test('setNextSkillGoal resets triggered goal milestones', () {
      skill.triggeredGoalMilestones.addAll([25, 50, 100]);

      expect(
        state.setNextSkillGoal(skill.id, 'Следующая цель'),
        NextGoalUpdateResult.updated,
      );
      expect(skill.triggeredGoalMilestones, isEmpty);
    });

    test('double save does not duplicate completed goal history', () {
      final completedAt = DateTime(2026, 6, 29, 13);

      expect(
        state.setNextSkillGoal(
          skill.id,
          'Следующая цель',
          completedAt: completedAt,
        ),
        NextGoalUpdateResult.updated,
      );
      expect(
        state.setNextSkillGoal(
          skill.id,
          'Следующая цель',
          completedAt: completedAt,
        ),
        NextGoalUpdateResult.unchanged,
      );
      expect(skill.completedGoals, hasLength(1));
    });

    test(
      'start new roadmap archives completed stages and clears active map',
      () {
        final stage = skill.treeNodes.single;
        final linkedQuest = Task(
          id: 'old-stage-quest',
          title: 'Сделать старый этап',
          skillId: skill.id,
          xpReward: 20,
          type: TaskType.shortTerm,
          treeNodeId: stage.id,
        );
        state.addTask(linkedQuest);

        final completedAt = DateTime(2026, 6, 29, 14);
        expect(
          state.setNextSkillGoal(
            skill.id,
            'Следующая цель',
            completedAt: completedAt,
          ),
          NextGoalUpdateResult.updated,
        );

        final result = state.startNewRoadmapForNextGoal(skill.id);

        expect(result, StartNewRoadmapResult.created);
        expect(skill.treeNodes, isEmpty);
        expect(linkedQuest.treeNodeId, isNull);
        expect(skill.completedRoadmaps, hasLength(1));
        final roadmap = skill.completedRoadmaps.single;
        expect(roadmap.completedGoalId, skill.completedGoals.single.id);
        expect(roadmap.goalText, 'Закрыть первую цель');
        expect(roadmap.completedAt, completedAt);
        expect(roadmap.progressAtCompletion, 1.0);
        expect(roadmap.completedStages, 1);
        expect(roadmap.totalStages, 1);
        expect(roadmap.stages, hasLength(1));
        expect(roadmap.stages.single.id, stage.id);
        expect(roadmap.stages.single.title, 'Готовый этап');

        state.addSkillTreeNode(
          skill.id,
          SkillTreeNode(id: 'new-active-stage', title: 'Новый этап'),
        );

        expect(skill.treeNodes.single.id, 'new-active-stage');
        expect(roadmap.stages.single.id, stage.id);
        expect(roadmap.stages.single.title, 'Готовый этап');
      },
    );

    test('start new roadmap requires an archived completed goal', () {
      expect(
        state.startNewRoadmapForNextGoal(skill.id),
        StartNewRoadmapResult.noCompletedGoal,
      );
      expect(skill.treeNodes, hasLength(1));
      expect(skill.completedRoadmaps, isEmpty);
    });
  });

  group('profile image hardening', () {
    late AppState state;

    setUp(() {
      state = AppState(storage: _InMemoryStorageService(), seedDefaults: false);
    });

    tearDown(() {
      state.dispose();
    });

    test('invalid avatar/banner bytes do not overwrite valid images', () {
      final avatar = _validPngBytes();
      final banner = _validJpegBytes();

      state.updateProfileAvatar(avatar);
      state.updateProfileBanner(banner);

      expect(state.profile.avatarBytes, orderedEquals(avatar));
      expect(state.profile.bannerBytes, orderedEquals(banner));

      state.updateProfileAvatar(_invalidImageBytes());
      state.updateProfileBanner(_invalidImageBytes());

      expect(state.profile.avatarBytes, orderedEquals(avatar));
      expect(state.profile.bannerBytes, orderedEquals(banner));
    });

    test('null avatar/banner still clears existing images', () {
      state.updateProfileAvatar(_validPngBytes());
      state.updateProfileBanner(_validJpegBytes());

      state.updateProfileAvatar(null);
      state.updateProfileBanner(null);

      expect(state.profile.avatarBytes, isNull);
      expect(state.profile.bannerBytes, isNull);
    });
  });

  group('fresh install safety', () {
    test('empty storage does not seed demo skills or quests', () async {
      final storage = _InMemoryStorageService();
      final state = AppState(storage: storage, seedDefaults: false);

      await state.loadSavedData();

      expect(state.skills.map((skill) => skill.id), [kInboxSkillId]);
      expect(state.roadmapSkills, isEmpty);
      expect(state.tasks, isEmpty);
      expect(state.history, isEmpty);
      expect(state.rewardChests, isEmpty);
      expect(state.buffs, isEmpty);
      expect(state.bosses, isEmpty);
      expect(state.profile.name, 'Your Name');
      expect(state.achievements, isNotEmpty);

      state.dispose();
    });

    test('first-run tutorial state loads and persists', () async {
      final storage = _InMemoryStorageService();
      final state = AppState(storage: storage, seedDefaults: false);

      await state.loadSavedData();

      expect(state.shouldShowFirstRunTutorial, isTrue);
      expect(state.onboardingSeen, isFalse);

      state.dismissFirstRunTutorial();
      await state.flushSaves();

      expect(state.shouldShowFirstRunTutorial, isFalse);
      expect(state.onboardingSeen, isTrue);
      expect(storage._onboardingSeen, isTrue);

      state.dispose();
    });

    test(
      'first-run tutorial continues through quest action before completion',
      () async {
        final storage = _InMemoryStorageService();
        final state = AppState(storage: storage, seedDefaults: false);

        await state.loadSavedData();
        state.startTutorialModule(TutorialModuleIds.core);

        state.addSkill(
          Skill(
            id: 'skill-1',
            name: 'Подтягивания',
            goal: 'Подтягиваться 20 раз',
            color: const Color(0xFFFF9500),
            icon: Icons.fitness_center,
            treeNodes: [SkillTreeNode(id: 'stage-1', title: 'Основа')],
          ),
        );

        expect(state.shouldShowFirstRunTutorial, isTrue);
        expect(state.onboardingSeen, isFalse);
        expect(state.activeTutorialStepId, TutorialStepIds.coreCreateQuest);
        state.completeTutorialStep(TutorialStepIds.coreCreateSkill);

        state.addTask(
          Task(
            id: 'task-1',
            title: 'Сделать первый подход',
            skillId: 'skill-1',
            xpReward: 20,
            type: TaskType.shortTerm,
            minimumAction: 'Сделать 1 подтягивание',
            treeNodeId: 'stage-1',
          ),
        );

        expect(state.shouldShowFirstRunTutorial, isTrue);
        expect(state.onboardingSeen, isFalse);
        expect(state.activeTutorialStepId, TutorialStepIds.coreCompleteQuest);

        state.completeMinimumAction('task-1');

        expect(state.shouldShowFirstRunTutorial, isTrue);
        expect(state.activeTutorialStepId, TutorialStepIds.coreXpFeedback);
        expect(state.onboardingSeen, isFalse);

        state.completeTutorialStep(TutorialStepIds.coreXpFeedback);
        state.completeTutorialStep(TutorialStepIds.coreOpenRoadmap);
        state.completeTutorialStep(TutorialStepIds.coreRoadmapDetails);
        state.completeTutorialStep(TutorialStepIds.coreOpenStats);
        await state.flushSaves();

        expect(state.shouldShowFirstRunTutorial, isFalse);
        expect(state.onboardingSeen, isTrue);
        expect(storage._onboardingSeen, isTrue);
        expect(
          storage._tutorialProgress!.isModuleCompleted(TutorialModuleIds.core),
          isTrue,
        );

        state.dispose();
      },
    );

    test('core tutorial starts from skill when no skills exist', () async {
      final storage = _InMemoryStorageService();
      final state = AppState(storage: storage, seedDefaults: false);

      await state.loadSavedData();
      state.startTutorialModule(TutorialModuleIds.core);

      expect(state.activeTutorialStepId, TutorialStepIds.coreCreateSkill);

      state.dispose();
    });

    test(
      'core tutorial starts from quest when skill exists without quests',
      () async {
        final storage = _InMemoryStorageService();
        final state = AppState(storage: storage, seedDefaults: false);

        await state.loadSavedData();
        state.addSkill(
          Skill(
            id: 'skill-1',
            name: 'Плавание',
            goal: 'Проплыть километр',
            color: const Color(0xFF4A9EFF),
            icon: Icons.pool,
          ),
        );
        state.startTutorialModule(TutorialModuleIds.core);

        expect(state.activeTutorialStepId, TutorialStepIds.coreCreateQuest);

        state.dispose();
      },
    );

    test('core tutorial starts from action when active quest exists', () async {
      final storage = _InMemoryStorageService();
      final state = AppState(storage: storage, seedDefaults: false);

      await state.loadSavedData();
      state.addSkill(
        Skill(
          id: 'skill-1',
          name: 'Плавание',
          goal: 'Проплыть километр',
          color: const Color(0xFF4A9EFF),
          icon: Icons.pool,
        ),
      );
      state.addTask(
        Task(
          id: 'task-1',
          title: 'Проплыть 100 метров',
          skillId: 'skill-1',
          xpReward: 20,
          type: TaskType.shortTerm,
        ),
      );
      state.startTutorialModule(TutorialModuleIds.core);

      expect(state.activeTutorialStepId, TutorialStepIds.coreCompleteQuest);

      state.dispose();
    });

    test(
      'legacy onboardingSeen maps to completed core tutorial module',
      () async {
        final storage = _InMemoryStorageService().._onboardingSeen = true;
        final state = AppState(storage: storage, seedDefaults: false);

        await state.loadSavedData();

        expect(state.shouldShowFirstRunTutorial, isFalse);
        expect(
          state.tutorialProgress.isModuleCompleted(TutorialModuleIds.core),
          isTrue,
        );

        state.dispose();
      },
    );
  });

  group('skill ordering', () {
    test(
      'reorder preserves selection and associations across save and load',
      () async {
        final storage = _InMemoryStorageService();
        final state = AppState(storage: storage, seedDefaults: false);
        final foundation = SkillTreeNode(
          id: 'foundation-stage',
          title: 'Foundation',
        );
        final first = Skill(
          id: 'skill-first',
          name: 'First',
          goal: 'First goal',
          color: const Color(0xFF4A9EFF),
          icon: Icons.looks_one,
          treeNodes: [foundation],
        );
        final second = Skill(
          id: 'skill-second',
          name: 'Second',
          goal: 'Second goal',
          color: const Color(0xFF34C759),
          icon: Icons.looks_two,
        );
        final third = Skill(
          id: 'skill-third',
          name: 'Third',
          goal: 'Third goal',
          color: const Color(0xFFFF9500),
          icon: Icons.looks_3,
        );
        state.addSkill(first);
        state.addSkill(second);
        state.addSkill(third);
        state.addTask(
          Task(
            id: 'linked-task',
            title: 'Linked quest',
            skillId: first.id,
            treeNodeId: foundation.id,
            xpReward: 20,
            type: TaskType.shortTerm,
          ),
        );
        state.selectSkill(second.id);

        state.reorderSkills(0, 2);

        expect(state.roadmapSkills.map((skill) => skill.id), [
          second.id,
          third.id,
          first.id,
        ]);
        expect(state.selectedSkillId, second.id);
        expect(state.tasks.single.skillId, first.id);
        expect(state.tasks.single.treeNodeId, foundation.id);
        expect(first.treeNodes.single.id, foundation.id);

        await state.flushSaves();
        final restarted = AppState(storage: storage, seedDefaults: false);
        await restarted.loadSavedData();

        expect(restarted.roadmapSkills.map((skill) => skill.id), [
          second.id,
          third.id,
          first.id,
        ]);
        expect(restarted.tasks.single.skillId, first.id);
        expect(restarted.tasks.single.treeNodeId, foundation.id);
        expect(restarted.roadmapSkills.last.treeNodes.single.id, foundation.id);

        state.dispose();
        restarted.dispose();
      },
    );

    test('invalid and no-op reorder requests leave order unchanged', () {
      final state = AppState(
        storage: _InMemoryStorageService(),
        seedDefaults: false,
      );
      state.skills.addAll([
        Skill(
          id: 'one',
          name: 'One',
          goal: 'One goal',
          color: const Color(0xFF4A9EFF),
          icon: Icons.looks_one,
        ),
        Skill(
          id: 'two',
          name: 'Two',
          goal: 'Two goal',
          color: const Color(0xFF34C759),
          icon: Icons.looks_two,
        ),
      ]);

      state.reorderSkills(-1, 1);
      state.reorderSkills(0, 0);
      state.reorderSkills(0, 2);

      expect(state.roadmapSkills.map((skill) => skill.id), ['one', 'two']);
      state.dispose();
    });
  });

  group('roadmap stage ordering', () {
    test(
      'rewires one linear road without changing stage or quest identity',
      () async {
        final storage = _InMemoryStorageService();
        final state = AppState(storage: storage, seedDefaults: false);
        final masteredAt = DateTime(2026, 6, 1);
        final first = SkillTreeNode(id: 'first', title: 'First');
        final second = SkillTreeNode(
          id: 'second',
          title: 'Second',
          prerequisiteIds: [first.id],
          isMastered: true,
          masteredAt: masteredAt,
        );
        final third = SkillTreeNode(
          id: 'third',
          title: 'Third',
          prerequisiteIds: [second.id],
        );
        final skill = Skill(
          id: 'ordered-road',
          name: 'Ordered road',
          goal: 'Keep progress',
          color: const Color(0xFF4A9EFF),
          icon: Icons.route,
          level: 4,
          xp: 120,
          treeNodes: [first, second, third],
        );
        state.addSkill(skill);
        state.addTask(
          Task(
            id: 'linked-quest',
            title: 'Linked quest',
            skillId: skill.id,
            treeNodeId: second.id,
            xpReward: 30,
            type: TaskType.shortTerm,
          ),
        );

        final changed = state.reorderRoadmapPath(skill.id, [
          third.id,
          first.id,
          second.id,
        ]);

        expect(changed, isTrue);
        final path = const RoadmapEngine().buildPathLayout(skill).paths.single;
        expect(path.nodes.map((node) => node.id), ['third', 'first', 'second']);
        expect(third.prerequisiteIds, isEmpty);
        expect(first.prerequisiteIds, ['third']);
        expect(second.prerequisiteIds, ['first']);
        expect(second.isMastered, isTrue);
        expect(second.masteredAt, masteredAt);
        expect(state.tasks.single.treeNodeId, second.id);
        expect(skill.level, 4);
        expect(skill.xp, 120);
        expect(state.consumeGoalMilestoneNotifications(), isEmpty);

        await state.flushSaves();
        final restarted = AppState(storage: storage, seedDefaults: false);
        await restarted.loadSavedData();
        final savedSkill = restarted.roadmapSkills.single;
        final savedPath = const RoadmapEngine()
            .buildPathLayout(savedSkill)
            .paths
            .single;
        expect(savedPath.nodes.map((node) => node.id), [
          'third',
          'first',
          'second',
        ]);
        expect(restarted.tasks.single.treeNodeId, 'second');

        state.dispose();
        restarted.dispose();
      },
    );

    test('rejects branching and cross-road reorder requests', () {
      final state = AppState(
        storage: _InMemoryStorageService(),
        seedDefaults: false,
      );
      final root = SkillTreeNode(id: 'root', title: 'Root');
      final left = SkillTreeNode(
        id: 'left',
        title: 'Left',
        prerequisiteIds: [root.id],
      );
      final right = SkillTreeNode(
        id: 'right',
        title: 'Right',
        prerequisiteIds: [root.id],
      );
      final other = SkillTreeNode(id: 'other', title: 'Other road');
      final skill = Skill(
        id: 'branching-road',
        name: 'Branching road',
        goal: 'Stay safe',
        color: const Color(0xFFFF9500),
        icon: Icons.account_tree,
        treeNodes: [root, left, right, other],
      );
      state.addSkill(skill);
      final originalOrder = skill.treeNodes.map((node) => node.id).toList();
      final originalLinks = {
        for (final node in skill.treeNodes)
          node.id: List<String>.from(node.prerequisiteIds),
      };

      expect(state.reorderRoadmapPath(skill.id, ['left', 'root']), isFalse);
      expect(state.reorderRoadmapPath(skill.id, ['other', 'left']), isFalse);
      expect(skill.treeNodes.map((node) => node.id), originalOrder);
      for (final node in skill.treeNodes) {
        expect(node.prerequisiteIds, originalLinks[node.id]);
      }
      state.dispose();
    });
  });

  group('achievement engine integration', () {
    test(
      'AppState keeps achievement unlock notifications as side effects',
      () async {
        final storage = _InMemoryStorageService();
        final state = AppState(storage: storage, seedDefaults: false);
        addTearDown(state.dispose);

        await state.loadSavedData();

        final skill = Skill(
          id: 'achievement-skill',
          name: 'Achievement skill',
          goal: 'Unlock first quest achievement',
          color: const Color(0xFFFF9500),
          icon: Icons.star,
        );
        final task = Task(
          id: 'achievement-task',
          title: 'Complete first quest',
          skillId: skill.id,
          xpReward: 20,
          type: TaskType.shortTerm,
        );

        state.addSkill(skill);
        state.addTask(task);
        state.completeTask(task.id);

        final unlocked = state.achievements.firstWhere(
          (achievement) => achievement.id == 'first_task',
        );
        final notifications = state.consumeAchievementNotifications();

        expect(unlocked.isUnlocked, isTrue);
        expect(notifications.map((achievement) => achievement.id), [
          'first_task',
        ]);
        expect(state.consumeAchievementNotifications(), isEmpty);
      },
    );
  });

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

    test('applies roadmap templates without duplicating roads', () {
      final skill = Skill(
        id: 'roadmap-skill',
        name: 'RoadMap навык',
        goal: 'Проверить шаблоны',
        color: const Color(0xFFFF9500),
        icon: Icons.route,
      );
      state.addSkill(skill);

      state.applyRoadmapTemplate(
        skill.id,
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.normal,
          stagesPerPath: 3,
        ),
      );
      expect(skill.treeNodes, hasLength(6));

      state.applyRoadmapTemplate(
        skill.id,
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.normal,
          stagesPerPath: 3,
        ),
      );
      expect(skill.treeNodes, hasLength(6));

      state.applyRoadmapTemplate(
        skill.id,
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.simple,
          stagesPerPath: 3,
        ),
      );
      expect(skill.treeNodes, hasLength(3));
      expect(
        skill.treeNodes.map((node) => node.prerequisiteIds.length).toList(),
        [0, 1, 1],
      );
    });

    test('reused stages can become roots when template adds roads', () {
      final skill = Skill(
        id: 'roadmap-split-skill',
        name: 'RoadMap split',
        goal: 'Разделить дороги',
        color: const Color(0xFFFF9500),
        icon: Icons.route,
      );
      state.addSkill(skill);

      state.applyRoadmapTemplate(
        skill.id,
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.simple,
          stagesPerPath: 4,
        ),
      );
      final originalIds = skill.treeNodes.map((node) => node.id).toList();

      state.applyRoadmapTemplate(
        skill.id,
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.normal,
          stagesPerPath: 3,
        ),
      );

      final layout = const RoadmapEngine().buildPathLayout(skill);
      final pathIds = layout.paths
          .map((path) => path.nodes.map((node) => node.id).toList())
          .toList();
      final reusedRoot = skill.treeNodes.firstWhere(
        (node) => node.id == originalIds[3],
      );

      expect(layout.paths, hasLength(2));
      expect(pathIds, contains(equals(originalIds.take(3).toList())));
      expect(pathIds.any((path) => path.first == originalIds[3]), isTrue);
      expect(reusedRoot.prerequisiteIds, isEmpty);
    });

    test(
      'template expansion keeps reused roads separate across three paths',
      () {
        final skill = Skill(
          id: 'roadmap-hard-skill',
          name: 'RoadMap hard split',
          goal: 'Три дороги',
          color: const Color(0xFFFF9500),
          icon: Icons.route,
        );
        state.addSkill(skill);

        state.applyRoadmapTemplate(
          skill.id,
          const RoadmapTemplateConfig(
            template: RoadmapTemplate.normal,
            stagesPerPath: 3,
          ),
        );
        final originalIds = skill.treeNodes.map((node) => node.id).toList();

        state.applyRoadmapTemplate(
          skill.id,
          const RoadmapTemplateConfig(
            template: RoadmapTemplate.hard,
            stagesPerPath: 2,
          ),
        );

        final layout = const RoadmapEngine().buildPathLayout(skill);
        final pathIds = layout.paths
            .map((path) => path.nodes.map((node) => node.id).toList())
            .toList();

        expect(layout.paths, hasLength(3));
        expect(pathIds, contains(equals([originalIds[0], originalIds[1]])));
        expect(pathIds, contains(equals([originalIds[2], originalIds[3]])));
        expect(pathIds, contains(equals([originalIds[4], originalIds[5]])));
        for (final rootId in [originalIds[0], originalIds[2], originalIds[4]]) {
          final root = skill.treeNodes.firstWhere((node) => node.id == rootId);
          expect(root.prerequisiteIds, isEmpty);
        }
      },
    );

    test('template shrink removes stale unlinked road stages', () {
      final skill = Skill(
        id: 'roadmap-shrink-skill',
        name: 'RoadMap shrink',
        goal: 'Сжать дороги',
        color: const Color(0xFFFF9500),
        icon: Icons.route,
      );
      state.addSkill(skill);

      state.applyRoadmapTemplate(
        skill.id,
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.hard,
          stagesPerPath: 2,
        ),
      );

      state.applyRoadmapTemplate(
        skill.id,
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.normal,
          stagesPerPath: 2,
        ),
      );

      final layout = const RoadmapEngine().buildPathLayout(skill);
      final nodeIds = skill.treeNodes.map((node) => node.id).toSet();

      expect(skill.treeNodes, hasLength(4));
      expect(layout.paths, hasLength(2));
      expect(layout.paths.every((path) => path.nodes.length == 2), isTrue);
      for (final node in skill.treeNodes) {
        expect(node.prerequisiteIds.every(nodeIds.contains), isTrue);
      }
    });

    test('repeated template changes keep every road independent', () {
      final skill = Skill(
        id: 'roadmap-repeated-transitions',
        name: 'RoadMap transitions',
        goal: 'Проверить стабильность дорог',
        color: const Color(0xFFFF9500),
        icon: Icons.route,
      );
      state.addSkill(skill);

      void applyAndExpect(
        RoadmapTemplate template,
        int pathCount,
        int stagesPerPath,
      ) {
        state.applyRoadmapTemplate(
          skill.id,
          RoadmapTemplateConfig(
            template: template,
            stagesPerPath: stagesPerPath,
          ),
        );

        final layout = const RoadmapEngine().buildPathLayout(skill);
        expect(layout.paths, hasLength(pathCount));
        expect(
          layout.paths.every((path) => path.nodes.length == stagesPerPath),
          isTrue,
        );

        final stageIds = <String>{};
        for (final path in layout.paths) {
          expect(path.nodes.first.prerequisiteIds, isEmpty);
          for (var index = 0; index < path.nodes.length; index++) {
            final node = path.nodes[index];
            expect(stageIds.add(node.id), isTrue);
            if (index > 0) {
              expect(node.prerequisiteIds.first, path.nodes[index - 1].id);
            }
          }
        }
      }

      applyAndExpect(RoadmapTemplate.simple, 1, 4);
      applyAndExpect(RoadmapTemplate.normal, 2, 3);
      applyAndExpect(RoadmapTemplate.hard, 3, 2);
      applyAndExpect(RoadmapTemplate.normal, 2, 2);
      applyAndExpect(RoadmapTemplate.simple, 1, 3);
    });

    test('preserves linked stages when applying a smaller template', () {
      final skill = Skill(
        id: 'linked-roadmap-skill',
        name: 'Связанный RoadMap',
        goal: 'Не потерять квесты',
        color: const Color(0xFFFF9500),
        icon: Icons.route,
        treeNodes: [
          SkillTreeNode(id: 'root-stage', title: 'Основа'),
          SkillTreeNode(
            id: 'linked-stage',
            title: 'Практика',
            prerequisiteIds: ['root-stage'],
          ),
        ],
      );
      state.addSkill(skill);
      final linkedQuest = Task(
        id: 'linked-quest',
        title: 'Сделать практику этапа',
        skillId: skill.id,
        xpReward: 20,
        type: TaskType.shortTerm,
        treeNodeId: 'linked-stage',
      );
      state.addTask(linkedQuest);

      state.applyRoadmapTemplate(
        skill.id,
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.simple,
          stagesPerPath: 1,
        ),
      );

      expect(skill.treeNodes.map((node) => node.id), contains('linked-stage'));
      expect(linkedQuest.treeNodeId, 'linked-stage');
    });

    test('merges valid existing roadmap prerequisites when reusing stages', () {
      final skill = Skill(
        id: 'dag-roadmap-skill',
        name: 'DAG RoadMap',
        goal: 'Сохранить связи',
        color: const Color(0xFFFF9500),
        icon: Icons.route,
        treeNodes: [
          SkillTreeNode(id: 'root-stage', title: 'Основа'),
          SkillTreeNode(
            id: 'middle-stage',
            title: 'Практика',
            prerequisiteIds: ['root-stage'],
          ),
          SkillTreeNode(
            id: 'terminal-stage',
            title: 'Результат',
            prerequisiteIds: ['middle-stage', 'side-stage'],
          ),
          SkillTreeNode(
            id: 'side-stage',
            title: 'Боковая практика',
            description: 'Сохранить как валидную зависимость',
          ),
        ],
      );
      state.addSkill(skill);
      final linkedQuest = Task(
        id: 'dag-linked-quest',
        title: 'Сделать результат',
        skillId: skill.id,
        xpReward: 20,
        type: TaskType.shortTerm,
        treeNodeId: 'terminal-stage',
      );
      state.addTask(linkedQuest);

      state.applyRoadmapTemplate(
        skill.id,
        const RoadmapTemplateConfig(
          template: RoadmapTemplate.simple,
          stagesPerPath: 3,
        ),
      );

      final terminal = skill.treeNodes.firstWhere(
        (node) => node.id == 'terminal-stage',
      );
      expect(
        terminal.prerequisiteIds,
        containsAll(['middle-stage', 'side-stage']),
      );
      expect(terminal.prerequisiteIds, hasLength(2));
      expect(linkedQuest.treeNodeId, 'terminal-stage');
    });

    test(
      'drops stale template-stage prerequisites when roads are reassigned',
      () {
        final skill = Skill(
          id: 'stale-road-prerequisite-skill',
          name: 'RoadMap stale parent',
          goal: 'Не склеивать дороги',
          color: const Color(0xFFFF9500),
          icon: Icons.route,
          treeNodes: [
            SkillTreeNode(id: 'road-1-root', title: 'Road 1 root'),
            SkillTreeNode(
              id: 'road-1-child',
              title: 'Road 1 child',
              prerequisiteIds: ['road-1-root'],
            ),
            SkillTreeNode(id: 'road-2-root', title: 'Road 2 root'),
            SkillTreeNode(
              id: 'road-2-child',
              title: 'Road 2 child',
              prerequisiteIds: ['road-2-root', 'road-1-child'],
            ),
          ],
        );
        state.addSkill(skill);

        state.applyRoadmapTemplate(
          skill.id,
          const RoadmapTemplateConfig(
            template: RoadmapTemplate.normal,
            stagesPerPath: 2,
          ),
        );

        final layout = const RoadmapEngine().buildPathLayout(skill);
        final roadTwoChild = skill.treeNodes.firstWhere(
          (node) => node.id == 'road-2-child',
        );

        expect(layout.paths, hasLength(2));
        expect(roadTwoChild.prerequisiteIds, ['road-2-root']);
        expect(
          layout.paths.map(
            (path) => path.nodes.map((node) => node.id).toList(),
          ),
          contains(equals(['road-2-root', 'road-2-child'])),
        );
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

    test('inserts a roadmap stage between existing stages safely', () {
      final skill = state.skills.first;
      final root = SkillTreeNode(id: 'insert-root-stage', title: 'Основа');
      final next = SkillTreeNode(
        id: 'insert-next-stage',
        title: 'Практика',
        prerequisiteIds: [root.id],
      );
      state.addSkillTreeNode(skill.id, root);
      state.addSkillTreeNode(skill.id, next);
      final linkedQuest = Task(
        id: 'insert-linked-quest',
        title: 'Закрыть практику',
        skillId: skill.id,
        xpReward: 20,
        type: TaskType.shortTerm,
        treeNodeId: next.id,
      );
      state.addTask(linkedQuest);

      final created = state.insertRoadmapStageAfter(
        skill.id,
        root.id,
        beforeNodeId: next.id,
        title: 'Средний этап',
      );

      expect(created, isNotNull);
      expect(created!.title, 'Средний этап');
      expect(created.prerequisiteIds, [root.id]);
      expect(next.prerequisiteIds, [created.id]);
      expect(
        skill.treeNodes.indexOf(created),
        lessThan(skill.treeNodes.indexOf(next)),
      );
      expect(linkedQuest.treeNodeId, next.id);
    });

    test('updates roadmap stage practice target without relinking quests', () {
      final skill = state.skills.first;
      final node = SkillTreeNode(
        id: 'practice-target-stage',
        title: 'Практика',
        requiredQuestCompletions: 3,
      );
      state.addSkillTreeNode(skill.id, node);
      final linkedQuest = Task(
        id: 'practice-target-quest',
        title: 'Закрыть практику',
        skillId: skill.id,
        xpReward: 20,
        type: TaskType.shortTerm,
        treeNodeId: node.id,
      );
      state.addTask(linkedQuest);

      state.updateSkillTreeNodePracticeTarget(
        skill.id,
        node.id,
        5,
        xpReward: 80,
      );
      expect(node.questTarget, 5);
      expect(node.xpReward, 80);
      expect(linkedQuest.treeNodeId, node.id);

      state.updateSkillTreeNodePracticeTarget(skill.id, node.id, 0);
      expect(node.questTarget, 1);
      expect(linkedQuest.treeNodeId, node.id);
    });

    test('renames roadmap stage without relinking quests', () {
      final skill = state.skills.first;
      final node = SkillTreeNode(id: 'rename-stage', title: 'Старый этап');
      state.addSkillTreeNode(skill.id, node);
      final linkedQuest = Task(
        id: 'rename-linked-quest',
        title: 'Закрыть практику',
        skillId: skill.id,
        xpReward: 20,
        type: TaskType.shortTerm,
        treeNodeId: node.id,
      );
      state.addTask(linkedQuest);

      state.renameSkillTreeNode(skill.id, node.id, 'Новый этап');

      expect(node.title, 'Новый этап');
      expect(linkedQuest.treeNodeId, node.id);

      state.renameSkillTreeNode(skill.id, node.id, '   ');

      expect(node.title, 'Новый этап');
      expect(linkedQuest.treeNodeId, node.id);
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

  group('history cache safety', () {
    late AppState state;

    setUp(() {
      state = AppState(storage: _InMemoryStorageService(), seedDefaults: true);
    });

    tearDown(() {
      state.dispose();
    });

    test('completion history caches recalculate after completion and undo', () {
      final task = state.tasks.firstWhere(
        (candidate) =>
            !candidate.isDone && candidate.type != TaskType.repeating,
      );

      expect(state.totalTasksCompleted, 0);
      expect(state.completionHistoryForDate(DateTime.now()), isEmpty);

      state.completeTask(task.id);

      expect(state.totalTasksCompleted, 1);
      expect(state.completionHistoryForDate(DateTime.now()), hasLength(1));

      state.uncompleteTask(task.id);

      expect(state.totalTasksCompleted, 0);
      expect(state.completionHistoryForDate(DateTime.now()), isEmpty);
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
        description: task.description,
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

    test('mastering stages queues milestone notifications once', () {
      final milestoneSkill = Skill(
        id: 'milestone-skill',
        name: 'Milestones',
        goal: 'Master four stages',
        color: Colors.amber,
        icon: Icons.flag,
        treeNodes: List.generate(
          4,
          (index) => SkillTreeNode(
            id: 'milestone-stage-$index',
            title: 'Stage $index',
            requiredQuestCompletions: 1,
          ),
        ),
      );
      state.addSkill(milestoneSkill);

      for (final stage in milestoneSkill.treeNodes) {
        state.addTask(
          Task(
            id: 'task-${stage.id}',
            title: 'Practice ${stage.title}',
            skillId: milestoneSkill.id,
            xpReward: 10,
            type: TaskType.shortTerm,
            isDone: true,
            treeNodeId: stage.id,
          ),
        );
      }

      state.masterSkillTreeNode(
        milestoneSkill.id,
        milestoneSkill.treeNodes[0].id,
      );
      var events = state.consumeGoalMilestoneNotifications();
      expect(events, hasLength(1));
      expect(events.single.milestone, GoalMilestone.quarter);
      expect(milestoneSkill.triggeredGoalMilestones, [25]);
      expect(state.consumeGoalMilestoneNotifications(), isEmpty);

      state.masterSkillTreeNode(
        milestoneSkill.id,
        milestoneSkill.treeNodes[1].id,
      );
      events = state.consumeGoalMilestoneNotifications();
      expect(events, hasLength(1));
      expect(events.single.milestone, GoalMilestone.half);
      expect(milestoneSkill.triggeredGoalMilestones, [25, 50]);

      state.masterSkillTreeNode(
        milestoneSkill.id,
        milestoneSkill.treeNodes[2].id,
      );
      expect(state.consumeGoalMilestoneNotifications(), isEmpty);
      expect(milestoneSkill.triggeredGoalMilestones, [25, 50]);

      state.masterSkillTreeNode(
        milestoneSkill.id,
        milestoneSkill.treeNodes[3].id,
      );
      events = state.consumeGoalMilestoneNotifications();
      expect(events, hasLength(1));
      expect(events.single.milestone, GoalMilestone.complete);
      expect(milestoneSkill.triggeredGoalMilestones, [25, 50, 100]);
    });

    test(
      'single mastery jump stores all crossed milestones but queues strongest event',
      () {
        final jumpSkill = Skill(
          id: 'jump-skill',
          name: 'Jump',
          goal: 'Master one stage',
          color: Colors.green,
          icon: Icons.rocket_launch,
          treeNodes: [
            SkillTreeNode(
              id: 'only-stage',
              title: 'Only stage',
              requiredQuestCompletions: 1,
            ),
          ],
        );
        state.addSkill(jumpSkill);
        state.addTask(
          Task(
            id: 'jump-task',
            title: 'Practice only stage',
            skillId: jumpSkill.id,
            xpReward: 10,
            type: TaskType.shortTerm,
            isDone: true,
            treeNodeId: 'only-stage',
          ),
        );

        state.masterSkillTreeNode(jumpSkill.id, 'only-stage');

        final events = state.consumeGoalMilestoneNotifications();
        expect(events, hasLength(1));
        expect(events.single.milestone, GoalMilestone.complete);
        expect(jumpSkill.triggeredGoalMilestones, [25, 50, 100]);
      },
    );

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
        description: task.description,
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
