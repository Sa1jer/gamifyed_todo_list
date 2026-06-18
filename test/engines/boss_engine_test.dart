import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_list_app/engines/boss_engine.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

/// Tests for [BossEngine].
///
/// The engine is intentionally pure (no I/O, no global singletons, the only
/// wall-clock dependency is injectable via the `now` parameter), so every
/// test below pins a fixed `now` and observes mutations directly on the
/// supplied collections. There is no `setUp` for shared state on purpose:
/// each test composes the smallest possible fixture that exercises a single
/// invariant.
void main() {
  // A single anchor moment used for every wall-clock-sensitive test, picked
  // far from any DST edge to keep arithmetic obvious in case of regressions.
  final fixedNow = DateTime.utc(2025, 1, 15, 12);

  const engine = BossEngine();

  // ---------- Factories --------------------------------------------------
  //
  // Tiny, deliberately permissive builders. They only override fields that
  // we care about per-test; everything else falls back to model defaults so
  // failures point at the engine's behaviour, not at fixture drift.

  Skill makeSkill({
    String id = 'skill-1',
    List<String>? checklist,
    List<bool>? checklistDone,
    List<SkillTreeNode>? treeNodes,
  }) {
    return Skill(
      id: id,
      name: 'Skill',
      goal: 'Goal',
      color: const Color(0xFF000000),
      icon: Icons.star,
      checklist: checklist,
      checklistDone: checklistDone,
      treeNodes: treeNodes,
    );
  }

  Task makeTask({
    required String id,
    String skillId = 'skill-1',
    // shortTerm is the "non-repeating" baseline used throughout these
    // tests where the task type's exact flavour doesn't matter.
    TaskType type = TaskType.shortTerm,
    Priority priority = Priority.medium,
    bool isDone = false,
    int streak = 0,
    String minimumAction = '',
    DateTime? minimumActionDoneAt,
    int minimumActionEarnedXP = 0,
    DateTime? nextResetAt,
  }) {
    return Task(
      id: id,
      title: 'Task $id',
      skillId: skillId,
      xpReward: 10,
      type: type,
      priority: priority,
      isDone: isDone,
      streak: streak,
      minimumAction: minimumAction,
      minimumActionDoneAt: minimumActionDoneAt,
      minimumActionEarnedXP: minimumActionEarnedXP,
      nextResetAt: nextResetAt,
    );
  }

  Boss makeBoss({
    String id = 'boss-1',
    String skillId = 'skill-1',
    int hp = 100,
    int maxHp = 100,
    int targetStreak = 7,
    bool isDefeated = false,
  }) {
    return Boss(
      id: id,
      title: 'Boss',
      skillId: skillId,
      hp: hp,
      maxHp: maxHp,
      targetStreak: targetStreak,
      isDefeated: isDefeated,
    );
  }

  // ---------- buildSnapshot ---------------------------------------------

  group('BossEngine.buildSnapshot', () {
    test('empty world produces neutral snapshot (no contributions)', () {
      // When the boss has no associated tasks and no skill metadata, every
      // contributing dimension is "absent", so impact must collapse to zero
      // and the engine must not divide by zero.
      final snapshot = engine.buildSnapshot(
        boss: makeBoss(),
        tasks: const [],
        skill: null,
        now: fixedNow,
      );

      expect(snapshot.impactProgress, 0.0);
      expect(snapshot.totalTasks, 0);
      expect(snapshot.isUnderAttack, isFalse);
      expect(snapshot.phaseLabel, 'Силен');
    });

    test('targetStreak < 1 is clamped to 1 in the snapshot', () {
      // Guards against a divide-by-zero / negative-progress regression if a
      // misconfigured boss slips in with targetStreak <= 0.
      final repeating = makeTask(id: 't1', type: TaskType.repeating, streak: 5);

      final snapshot = engine.buildSnapshot(
        boss: makeBoss(targetStreak: 0),
        tasks: [repeating],
        skill: makeSkill(),
        now: fixedNow,
      );

      expect(snapshot.targetStreak, 1);
      // 5 / clamp(1) saturates at 1.0.
      expect(snapshot.streakProgress, 1.0);
    });

    test('currentStreak is the maximum streak across repeating tasks', () {
      final tasks = [
        makeTask(id: 't1', type: TaskType.repeating, streak: 2),
        makeTask(id: 't2', type: TaskType.repeating, streak: 9),
        makeTask(id: 't3', type: TaskType.repeating, streak: 4),
        // A non-repeating task with a high (legacy) streak must not
        // influence the boss snapshot, even though Task.streak technically
        // exists for every task type.
        makeTask(id: 't4', type: TaskType.shortTerm, streak: 99),
      ];

      final snapshot = engine.buildSnapshot(
        boss: makeBoss(targetStreak: 10),
        tasks: tasks,
        skill: makeSkill(),
        now: fixedNow,
      );

      expect(snapshot.currentStreak, 9);
      expect(snapshot.streakProgress, closeTo(0.9, 1e-9));
    });

    test('tasks from other skills are ignored', () {
      // Cross-skill bleed would be a serious correctness bug, so this is
      // checked at the snapshot level rather than only at sync.
      final tasks = [
        makeTask(id: 'own', skillId: 'skill-1', isDone: true),
        makeTask(id: 'foreign', skillId: 'skill-other', isDone: true),
      ];

      final snapshot = engine.buildSnapshot(
        boss: makeBoss(skillId: 'skill-1'),
        tasks: tasks,
        skill: makeSkill(id: 'skill-1'),
        now: fixedNow,
      );

      expect(snapshot.totalTasks, 1);
      expect(snapshot.completedTasks, 1);
      expect(snapshot.completionProgress, 1.0);
    });

    test('high-priority "relief" counts both done and minimum-action done', () {
      final tasks = [
        makeTask(id: 'h1', priority: Priority.high, isDone: true),
        makeTask(
          id: 'h2',
          priority: Priority.high,
          minimumAction: 'do 1 rep',
          minimumActionDoneAt: fixedNow,
          minimumActionEarnedXP: 3,
        ),
        makeTask(id: 'h3', priority: Priority.high), // stalled
        makeTask(id: 'm1', priority: Priority.medium), // ignored
      ];

      final snapshot = engine.buildSnapshot(
        boss: makeBoss(),
        tasks: tasks,
        skill: makeSkill(),
        now: fixedNow,
      );

      // 2 of 3 high-priority tasks are "relieved" -> 2/3 ≈ 0.6667.
      expect(snapshot.priorityProgress, closeTo(2 / 3, 1e-9));
      // Exactly one high-priority task is still completely untouched.
      expect(snapshot.stalledHighPriorityTasks, 1);
    });

    test('urgent repeating window is exactly 24h relative to injected now', () {
      // Reset boundary chosen to straddle the 24h cutoff: one task inside,
      // one task exactly at the edge (inclusive), one task outside.
      final tasks = [
        makeTask(
          id: 'inside',
          type: TaskType.repeating,
          nextResetAt: fixedNow.add(const Duration(hours: 5)),
        ),
        makeTask(
          id: 'edge',
          type: TaskType.repeating,
          // Exactly 24h -> still considered urgent (<=).
          nextResetAt: fixedNow.add(const Duration(hours: 24)),
        ),
        makeTask(
          id: 'outside',
          type: TaskType.repeating,
          nextResetAt: fixedNow.add(const Duration(hours: 25)),
        ),
        // A done repeating task is never urgent, even if reset is soon.
        makeTask(
          id: 'done',
          type: TaskType.repeating,
          isDone: true,
          nextResetAt: fixedNow.add(const Duration(hours: 1)),
        ),
      ];

      final snapshot = engine.buildSnapshot(
        boss: makeBoss(),
        tasks: tasks,
        skill: makeSkill(),
        now: fixedNow,
      );

      expect(snapshot.urgentRepeatingTasks, 2);
      expect(snapshot.isUnderAttack, isTrue);
    });

    test('phaseLabel "Побеждён" wins over impact-based labels', () {
      // Even when there are no contributions (impact == 0), an already
      // defeated boss must keep the "Побеждён" label so the UI never
      // shows a stale "Силен"/"Атакует" caption for a dead boss.
      final boss = makeBoss(isDefeated: true);
      final snapshot = engine.buildSnapshot(
        boss: boss,
        tasks: const [],
        skill: null,
        now: fixedNow,
      );

      expect(snapshot.phaseLabel, 'Побеждён');
    });

    test(
      'impactProgress is the weighted average of present dimensions only',
      () {
        // Single fully completed dimension (one shortTerm task done) -> 100%
        // of the only present weight. Locks in that missing dimensions are
        // dropped from BOTH numerator and denominator (not treated as 0).
        final tasks = [makeTask(id: 't1', isDone: true)];

        final snapshot = engine.buildSnapshot(
          boss: makeBoss(),
          tasks: tasks,
          skill: makeSkill(), // no checklist, no tree nodes
          now: fixedNow,
        );

        expect(snapshot.impactProgress, 1.0);
        expect(snapshot.completionProgress, 1.0);
      },
    );
  });

  // ---------- syncForSkill ----------------------------------------------

  group('BossEngine.syncForSkill', () {
    test('bosses bound to other skills are left completely untouched', () {
      final foreignBoss = makeBoss(
        id: 'foreign',
        skillId: 'other',
        hp: 42,
        targetStreak: 5,
      );
      final ownBoss = makeBoss(id: 'own', skillId: 'skill-1');
      final bosses = [foreignBoss, ownBoss];

      engine.syncForSkill(
        skillId: 'skill-1',
        bosses: bosses,
        tasks: const [],
        skill: makeSkill(),
        now: fixedNow,
      );

      // Foreign boss state is byte-for-byte unchanged.
      expect(foreignBoss.hp, 42);
      expect(foreignBoss.isDefeated, isFalse);
      expect(foreignBoss.defeatedAt, isNull);
    });

    test(
      'full impact transitions a live boss to defeated and fires callback',
      () {
        // 4 of 4 tasks done is the only contribution (no repeating, no
        // priority, no tree, no checklist) -> impact == 1.0 -> nextHp == 0
        // -> the boss should be marked defeated and the callback fired
        // exactly once.
        final boss = makeBoss(maxHp: 100);
        final tasks = [
          for (var i = 0; i < 4; i++) makeTask(id: 't$i', isDone: true),
        ];

        var callbackCount = 0;
        Boss? defeatedArg;
        final newlyDefeated = engine.syncForSkill(
          skillId: 'skill-1',
          bosses: [boss],
          tasks: tasks,
          skill: makeSkill(),
          onBossDefeated: (b, _) {
            callbackCount++;
            defeatedArg = b;
          },
          now: fixedNow,
        );

        expect(boss.hp, 0);
        expect(boss.isDefeated, isTrue);
        // The defeat timestamp must come from the injected clock, not
        // `DateTime.now()`, otherwise the engine would be untestable in
        // a deterministic way.
        expect(boss.defeatedAt, fixedNow);
        expect(newlyDefeated, {'boss-1'});
        expect(callbackCount, 1);
        expect(identical(defeatedArg, boss), isTrue);
      },
    );

    test('partial impact applies proportional HP without defeating', () {
      // 1 done out of 4 -> completion 0.25 is the only present dimension
      // -> impact 0.25 -> nextHp = round((1 - 0.25) * 100) = 75.
      final boss = makeBoss(maxHp: 100);
      final tasks = [
        makeTask(id: 't1', isDone: true),
        makeTask(id: 't2'),
        makeTask(id: 't3'),
        makeTask(id: 't4'),
      ];

      var callbackCount = 0;
      final newlyDefeated = engine.syncForSkill(
        skillId: 'skill-1',
        bosses: [boss],
        tasks: tasks,
        skill: makeSkill(),
        onBossDefeated: (_, _) => callbackCount++,
        now: fixedNow,
      );

      expect(boss.hp, 75);
      expect(boss.isDefeated, isFalse);
      expect(boss.defeatedAt, isNull);
      expect(newlyDefeated, isEmpty);
      expect(callbackCount, 0);
    });

    test('already-defeated boss whose impact falls back is fully revived', () {
      // The engine must be symmetric: if a previously defeated boss no
      // longer meets the defeat criterion (e.g. tasks were uncompleted,
      // a streak was lost), it has to be revived — otherwise undo flows
      // in AppState would leave ghost-defeated bosses on screen.
      final boss = makeBoss(maxHp: 100, hp: 0, isDefeated: true)
        ..defeatedAt = fixedNow.subtract(const Duration(days: 1));

      // No tasks, no skill metadata -> impact 0.0 -> nextHp 100.
      final newlyDefeated = engine.syncForSkill(
        skillId: 'skill-1',
        bosses: [boss],
        tasks: const [],
        skill: null,
        onBossDefeated: (_, _) =>
            fail('onBossDefeated must not fire on revival'),
        now: fixedNow,
      );

      expect(boss.hp, 100);
      expect(boss.isDefeated, isFalse);
      expect(boss.defeatedAt, isNull);
      expect(newlyDefeated, isEmpty);
    });

    test('already-defeated boss that stays defeated does not re-trigger', () {
      // If a boss is already marked defeated AND still satisfies the
      // defeat criterion, the engine must be idempotent: no callback,
      // no defeatedAt reset, HP stays clamped to 0.
      final originalDefeatedAt = fixedNow.subtract(const Duration(hours: 6));
      final boss = makeBoss(maxHp: 100, hp: 0, isDefeated: true)
        ..defeatedAt = originalDefeatedAt;

      final tasks = [
        for (var i = 0; i < 3; i++) makeTask(id: 't$i', isDone: true),
      ];

      var callbackCount = 0;
      final newlyDefeated = engine.syncForSkill(
        skillId: 'skill-1',
        bosses: [boss],
        tasks: tasks,
        skill: makeSkill(),
        onBossDefeated: (_, _) => callbackCount++,
        now: fixedNow,
      );

      expect(boss.hp, 0);
      expect(boss.isDefeated, isTrue);
      // Crucially: the original defeat timestamp is preserved (no
      // double-defeat artifacts in the history/UI).
      expect(boss.defeatedAt, originalDefeatedAt);
      expect(callbackCount, 0);
      expect(newlyDefeated, isEmpty);
    });

    test('currentStreak on the boss is refreshed from the snapshot', () {
      // Regression guard: even if the boss survives this sync (impact
      // below defeat threshold), its `currentStreak` field must mirror
      // the snapshot so the UI badge stays consistent.
      final boss = makeBoss(targetStreak: 100, hp: 100, maxHp: 100);
      final tasks = [
        makeTask(id: 't1', type: TaskType.repeating, streak: 7),
        makeTask(id: 't2', type: TaskType.repeating, streak: 3),
      ];

      engine.syncForSkill(
        skillId: 'skill-1',
        bosses: [boss],
        tasks: tasks,
        skill: makeSkill(),
        now: fixedNow,
      );

      expect(boss.currentStreak, 7);
      expect(boss.isDefeated, isFalse);
    });
  });

  // ---------- canStartMinimumAction -------------------------------------

  group('BossEngine.canStartMinimumAction', () {
    Task baseTask({
      String minimumAction = '',
      bool isDone = false,
      DateTime? minimumActionDoneAt,
      int minimumActionEarnedXP = 0,
    }) {
      return Task(
        id: 't',
        title: 't',
        skillId: 's',
        xpReward: 1,
        type: TaskType.shortTerm,
        minimumAction: minimumAction,
        isDone: isDone,
        minimumActionDoneAt: minimumActionDoneAt,
        minimumActionEarnedXP: minimumActionEarnedXP,
      );
    }

    test('requires a non-empty minimum action', () {
      expect(BossEngine.canStartMinimumAction(baseTask()), isFalse);
    });

    test('false when the task is already fully done', () {
      final task = baseTask(minimumAction: 'one push-up', isDone: true);
      expect(BossEngine.canStartMinimumAction(task), isFalse);
    });

    test('false when the minimum action has already been registered', () {
      final task = baseTask(
        minimumAction: 'one push-up',
        minimumActionDoneAt: DateTime.utc(2025, 1, 1),
        minimumActionEarnedXP: 1,
      );
      expect(BossEngine.canStartMinimumAction(task), isFalse);
    });

    test('true for a fresh task that has a minimum action declared', () {
      final task = baseTask(minimumAction: 'one push-up');
      expect(BossEngine.canStartMinimumAction(task), isTrue);
    });
  });
}
