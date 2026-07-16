import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/coordinators/reward_mutation_coordinator.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  const coordinator = RewardMutationCoordinator();
  final now = DateTime(2026, 7, 15, 12);

  test('preview caps cumulative buffs and ignores Inbox tasks', () {
    final buffs = [
      _buff('first', bonus: 35, now: now),
      _buff('second', bonus: 35, now: now),
    ];

    final normal = coordinator.previewBuffOutcome(
      buffs: buffs,
      task: _task(),
      baseEarned: 100,
    );
    final inbox = coordinator.previewBuffOutcome(
      buffs: buffs,
      task: _task(skillId: kInboxSkillId),
      baseEarned: 100,
    );

    expect(normal.bonusPercent, RewardMutationCoordinator.maxBuffBonusPercent);
    expect(normal.bonusXp, 50);
    expect(inbox, (bonusXp: 0, bonusPercent: 0));
  });

  test('consumption and restore mutate the same bounded buff charges', () {
    final buffs = [
      _buff('first', bonus: 15, now: now, charges: 2),
      _buff('second', bonus: 10, now: now),
    ];

    final result = coordinator.consumeBuffsForTask(
      buffs: buffs,
      task: _task(),
      baseEarned: 20,
    );

    expect(result.bonusPercent, 25);
    expect(result.bonusXp, 5);
    expect(result.buffIds, ['first', 'second']);
    expect(buffs.map((buff) => buff.charges), [1, 0]);

    coordinator.restoreConsumedBuffs(buffs: buffs, buffIds: result.buffIds);
    expect(buffs.map((buff) => buff.charges), [2, 1]);
  });

  test(
    'reward source is idempotent and cleanup removes dependent references',
    () {
      final chests = <RewardChest>[];
      final pendingChests = <RewardChest>[];
      final buffs = <Buff>[];
      final pendingBuffs = <Buff>[];
      final task = _task()..consumedBuffIds = ['buff'];

      final first = coordinator.unlockRewardChest(
        rewardChests: chests,
        pendingNotifications: pendingChests,
        sourceKey: 'daily:2026-07-15',
        title: 'Chest',
        description: 'Reward',
        rarity: RewardRarity.common,
        now: now,
      );
      final duplicate = coordinator.unlockRewardChest(
        rewardChests: chests,
        pendingNotifications: pendingChests,
        sourceKey: 'daily:2026-07-15',
        title: 'Duplicate',
        description: 'Reward',
        rarity: RewardRarity.common,
        now: now,
      );
      buffs.add(
        _buff('buff', bonus: 10, now: now)..sourceKey = 'daily:2026-07-15',
      );

      expect(first, isNotNull);
      expect(duplicate, isNull);
      expect(chests, hasLength(1));

      coordinator.removeSources(
        sourceKeys: const {'daily:2026-07-15'},
        rewardChests: chests,
        buffs: buffs,
        tasks: [task],
        pendingRewardNotifications: pendingChests,
        pendingBuffNotifications: pendingBuffs,
      );

      expect(chests, isEmpty);
      expect(buffs, isEmpty);
      expect(pendingChests, isEmpty);
      expect(task.consumedBuffIds, isEmpty);
    },
  );
}

Task _task({String skillId = 'skill'}) => Task(
  id: 'task',
  title: 'Task',
  skillId: skillId,
  xpReward: 20,
  type: TaskType.shortTerm,
);

Buff _buff(
  String id, {
  required int bonus,
  required DateTime now,
  int charges = 1,
}) => Buff(
  id: id,
  type: BuffType.nextQuestXpBoost,
  title: id,
  description: id,
  bonusPercent: bonus,
  charges: charges,
  createdAt: now,
  // Buff.isActive reads the wall clock, so keep this coordinator fixture
  // active independently of the date on which the suite is executed.
  expiresAt: DateTime.utc(9999),
);
