import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/roadmap_engine.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/utils.dart';

Uint8List _validPngBytes() =>
    Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00]);

Uint8List _validJpegBytes() =>
    Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);

Uint8List _invalidImageBytes() => Uint8List.fromList([1, 2, 3, 4]);

void main() {
  group('TutorialProgress compatibility', () {
    test('roundtrip keeps modules, steps and active replay module', () {
      final progress = TutorialProgress(
        completedModuleIds: const {TutorialModuleIds.core},
        completedStepIds: const {
          TutorialStepIds.coreCreateSkill,
          TutorialStepIds.coreCreateQuest,
        },
        dismissedModuleIds: const {TutorialModuleIds.trophies},
        activeModuleId: TutorialModuleIds.roadmap,
        activeStepId: TutorialStepIds.roadmapPath,
        updatedAt: DateTime.utc(2026, 6, 22, 10),
      );

      final decoded = TutorialProgress.fromJson(progress.toJson());

      expect(decoded.completedModuleIds, {TutorialModuleIds.core});
      expect(decoded.completedStepIds, {
        TutorialStepIds.coreCreateSkill,
        TutorialStepIds.coreCreateQuest,
      });
      expect(decoded.dismissedModuleIds, {TutorialModuleIds.trophies});
      expect(decoded.activeModuleId, TutorialModuleIds.roadmap);
      expect(decoded.activeStepId, TutorialStepIds.roadmapPath);
      expect(decoded.updatedAt, DateTime.utc(2026, 6, 22, 10));
    });
  });

  group('StorageService enum compatibility', () {
    test('task roundtrip stores enum names', () {
      final storage = StorageService();
      final task = Task(
        id: 'task-1',
        title: 'String enum task',
        description: 'Keep this note with the quest',
        skillId: 'skill-1',
        xpReward: 25,
        type: TaskType.repeating,
        repeatFrequency: RepeatFrequency.weekly,
        priority: Priority.high,
      );

      final encoded = jsonDecode(storage.debugEncodeTask(task)) as Map;

      expect(encoded['type'], TaskType.repeating.name);
      expect(encoded['description'], 'Keep this note with the quest');
      expect(encoded['repeatFrequency'], RepeatFrequency.weekly.name);
      expect(encoded['priority'], Priority.high.name);

      final decoded = storage.debugDecodeTask(jsonEncode(encoded));

      expect(decoded.type, TaskType.repeating);
      expect(decoded.description, 'Keep this note with the quest');
      expect(decoded.repeatFrequency, RepeatFrequency.weekly);
      expect(decoded.priority, Priority.high);
    });

    test('old int enum task payload still decodes correctly', () {
      final storage = StorageService();
      final now = DateTime.now().toIso8601String();
      final decoded = storage.debugDecodeTask(
        jsonEncode({
          'id': 'legacy-task',
          'title': 'Legacy task',
          'skillId': 'skill-1',
          'xpReward': 20,
          'type': TaskType.midTerm.index,
          'repeatFrequency': RepeatFrequency.every3Days.index,
          'priority': Priority.low.index,
          'createdAt': now,
          'updatedAt': now,
        }),
      );

      expect(decoded.type, TaskType.midTerm);
      expect(decoded.skillId, 'skill-1');
      expect(decoded.repeatFrequency, RepeatFrequency.every3Days);
      expect(decoded.priority, Priority.low);
    });

    test('new string enum task payload decodes correctly', () {
      final storage = StorageService();
      final now = DateTime.now().toIso8601String();
      final decoded = storage.debugDecodeTask(
        jsonEncode({
          'id': 'string-task',
          'title': 'String task',
          'skillId': 'skill-1',
          'xpReward': 20,
          'type': TaskType.longTerm.name,
          'repeatFrequency': RepeatFrequency.monthly.name,
          'priority': Priority.high.name,
          'createdAt': now,
          'updatedAt': now,
        }),
      );

      expect(decoded.type, TaskType.longTerm);
      expect(decoded.repeatFrequency, RepeatFrequency.monthly);
      expect(decoded.priority, Priority.high);
    });

    test('inbox task roundtrip stores system skill id without scope', () {
      final storage = StorageService();
      final task = Task(
        id: 'inbox-task',
        title: 'Купить молоко',
        skillId: kInboxSkillId,
        xpReward: 50,
        type: TaskType.longTerm,
        treeNodeId: 'stale-node',
      );

      final encoded = jsonDecode(storage.debugEncodeTask(task)) as Map;
      expect(encoded.containsKey('scope'), isFalse);
      expect(encoded['skillId'], kInboxSkillId);
      expect(encoded['xpReward'], 0);
      expect(encoded['treeNodeId'], isNull);

      final decoded = storage.debugDecodeTask(jsonEncode(encoded));

      expect(decoded.isInbox, isTrue);
      expect(decoded.skillId, kInboxSkillId);
      expect(decoded.treeNodeId, isNull);
      expect(decoded.xpReward, 0);
      expect(decoded.type, TaskType.shortTerm);
    });

    test('legacy task without skill id decodes as inbox task safely', () {
      final storage = StorageService();
      final now = DateTime.now().toIso8601String();
      final decoded = storage.debugDecodeTask(
        jsonEncode({
          'id': 'legacy-floating-task',
          'title': 'Floating legacy task',
          'xpReward': 20,
          'type': TaskType.shortTerm.name,
          'createdAt': now,
          'updatedAt': now,
        }),
      );

      expect(decoded.isInbox, isTrue);
      expect(decoded.skillId, kInboxSkillId);
      expect(decoded.xpReward, 0);
    });

    test('legacy scope inbox decodes into system inbox skill', () {
      final storage = StorageService();
      final now = DateTime.now().toIso8601String();
      final decoded = storage.debugDecodeTask(
        jsonEncode({
          'id': 'legacy-scoped-inbox-task',
          'title': 'Scoped legacy task',
          'scope': 'inbox',
          'skillId': null,
          'xpReward': 20,
          'type': TaskType.longTerm.name,
          'createdAt': now,
          'updatedAt': now,
        }),
      );

      expect(decoded.isInbox, isTrue);
      expect(decoded.skillId, kInboxSkillId);
      expect(decoded.xpReward, 0);
      expect(decoded.type, TaskType.shortTerm);
    });
  });

  group('StorageService achievements', () {
    test('unknown achievement loads without crashing', () {
      final storage = StorageService();
      final achievement = storage.debugDecodeAchievement(
        jsonEncode({
          'id': 'removed_future_achievement',
          'unlockedAt': DateTime.now().toIso8601String(),
        }),
      );

      expect(achievement.id, 'removed_future_achievement');
      expect(achievement.def, isNull);
      expect(achievement.unlockedAt, isNotNull);
    });
  });

  group('StorageService profile image hardening', () {
    test('valid PNG/JPEG avatar and banner bytes roundtrip', () {
      final storage = StorageService();
      final avatar = _validPngBytes();
      final banner = _validJpegBytes();
      final profile = UserProfile(
        name: 'Tester',
        avatarBytes: avatar,
        bannerBytes: banner,
      );

      final decoded = storage.debugDecodeProfile(
        storage.debugEncodeProfile(profile),
      );

      expect(decoded.avatarBytes, orderedEquals(avatar));
      expect(decoded.bannerBytes, orderedEquals(banner));
    });

    test('invalid legacy avatar and banner bytes decode as null', () {
      final storage = StorageService();
      final decoded = storage.debugDecodeProfile(
        jsonEncode({
          'name': 'Tester',
          'avatarBytes': base64Encode(_invalidImageBytes()),
          'bannerBytes': base64Encode(_invalidImageBytes()),
        }),
      );

      expect(decoded.avatarBytes, isNull);
      expect(decoded.bannerBytes, isNull);
    });
  });

  group('StorageService JSON decode hardening', () {
    test('deeply nested JSON payloads are skipped safely', () {
      final storage = StorageService();
      Object? value = 'leaf';
      for (var i = 0; i < 70; i++) {
        value = {'child': value};
      }

      expect(storage.debugDecodeMapOrNull(jsonEncode(value)), isNull);
      expect(storage.debugDecodeMapOrNull(jsonEncode({'safe': true})), {
        'safe': true,
      });
    });
  });

  group('StorageService skill goalSpec compatibility', () {
    test('old skill payload with only goal decodes into goalSpec', () {
      final storage = StorageService();
      final decoded = storage.debugDecodeSkill(
        jsonEncode({
          'id': 'legacy-skill',
          'name': 'Pull-ups',
          'goal': 'Подтягиваться 20 раз',
          'color': const Color(0xFF4A9EFF).toARGB32(),
          'iconName': Icons.fitness_center.codePoint.toString(),
          'level': 2,
          'xp': 15,
        }),
      );

      expect(decoded.goal, 'Подтягиваться 20 раз');
      expect(decoded.goalSpec.text, 'Подтягиваться 20 раз');
      expect(decoded.goalSpec.reviews, isEmpty);
      expect(decoded.completedGoals, isEmpty);
      expect(decoded.completedRoadmaps, isEmpty);
      expect(decoded.triggeredGoalMilestones, isEmpty);
      expect(decoded.level, 2);
      expect(decoded.xp, 15);
    });

    test('v1 skill migration rewrites legacy goal into goalSpec', () {
      final storage = StorageService();
      final migrated = storage.debugMigrateSkillPayloadV1ToV2(
        jsonEncode({
          'id': 'legacy-migrate-skill',
          'name': 'Pull-ups',
          'goal': 'Подтягиваться 20 раз',
          'color': const Color(0xFF4A9EFF).toARGB32(),
          'iconName': Icons.fitness_center.codePoint.toString(),
          'level': 2,
          'xp': 15,
        }),
      );

      expect(migrated, isNotNull);
      final encoded = jsonDecode(migrated!) as Map;
      expect(encoded['goal'], 'Подтягиваться 20 раз');
      expect(encoded['goalSpec'], isA<Map>());
      expect((encoded['goalSpec'] as Map)['text'], 'Подтягиваться 20 раз');

      final decoded = storage.debugDecodeSkill(migrated);
      expect(decoded.goal, 'Подтягиваться 20 раз');
      expect(decoded.goalSpec.text, 'Подтягиваться 20 раз');
    });

    test('v1 skill migration skips corrupted payloads safely', () {
      final storage = StorageService();

      expect(storage.debugMigrateSkillPayloadV1ToV2('not-json'), isNull);
      expect(storage.debugMigrateSkillPayloadV1ToV2('[]'), isNull);
    });

    test('new skill payload with goalSpec decodes all goal fields', () {
      final storage = StorageService();
      final deadline = DateTime(2026, 12, 1);
      final updatedAt = DateTime(2026, 6, 13, 12);
      final reviewAt = DateTime(2026, 6, 14, 9);

      final decoded = storage.debugDecodeSkill(
        jsonEncode({
          'id': 'goal-skill',
          'name': 'Pull-ups',
          'goal': 'Legacy fallback',
          'goalSpec': {
            'text': 'Подтягиваться 20 раз',
            'deadline': deadline.toIso8601String(),
            'metric': 'повторения',
            'targetValue': 20,
            'currentValue': 7.5,
            'updatedAt': updatedAt.toIso8601String(),
            'reviews': [
              {
                'id': 'review-1',
                'createdAt': reviewAt.toIso8601String(),
                'wins': 'Три тренировки',
                'blockers': 'Не хватило сна',
                'adjustment': 'Снизить объём',
                'nextFocus': 'Техника',
                'updatedPlan': true,
              },
            ],
          },
        }),
      );

      expect(decoded.goal, 'Подтягиваться 20 раз');
      expect(decoded.goalSpec.deadline, deadline);
      expect(decoded.goalSpec.metric, 'повторения');
      expect(decoded.goalSpec.targetValue, 20);
      expect(decoded.goalSpec.currentValue, 7.5);
      expect(decoded.goalSpec.updatedAt, updatedAt);
      expect(decoded.goalSpec.reviews, hasLength(1));
      expect(decoded.goalSpec.reviews.single.id, 'review-1');
      expect(decoded.goalSpec.reviews.single.wins, 'Три тренировки');
      expect(decoded.goalSpec.reviews.single.updatedPlan, isTrue);
    });

    test('skill encode/decode roundtrip stores legacy goal and goalSpec', () {
      final storage = StorageService();
      final skill = Skill(
        id: 'roundtrip-skill',
        name: 'Python',
        goal: 'Legacy goal',
        goalSpec: GoalSpec(
          text: 'Собрать backend roadmap',
          deadline: DateTime(2026, 9, 1),
          metric: 'этапы',
          targetValue: 5,
          currentValue: 2,
          updatedAt: DateTime(2026, 6, 13),
          reviews: [
            GoalReviewEntry(
              id: 'review-rt',
              createdAt: DateTime(2026, 6, 14),
              wins: 'Закрыл API этап',
              nextFocus: 'Auth',
              updatedPlan: true,
            ),
          ],
        ),
        color: const Color(0xFF4A9EFF),
        icon: Icons.code,
        completedGoals: [
          CompletedGoal(
            id: 'goal-history-1',
            skillId: 'roundtrip-skill',
            goalText: 'Собрать первый backend',
            completedAt: DateTime(2026, 6, 20, 18),
            progressAtCompletion: 1.0,
            completedStages: 4,
            totalStages: 4,
          ),
        ],
        completedRoadmaps: [
          CompletedRoadmap(
            id: 'roadmap-history-1',
            skillId: 'roundtrip-skill',
            completedGoalId: 'goal-history-1',
            goalText: 'Собрать первый backend',
            completedAt: DateTime(2026, 6, 20, 18),
            progressAtCompletion: 1.0,
            completedStages: 2,
            totalStages: 2,
            stages: [
              RoadmapStageSnapshot(
                id: 'archive-stage-1',
                title: 'API',
                description: 'Собрать endpoint',
                xpReward: 30,
                requiredQuestCompletions: 2,
                checklist: ['Контракт'],
                checklistDone: [true],
                isMastered: true,
                masteredAt: DateTime(2026, 6, 18),
              ),
              RoadmapStageSnapshot(
                id: 'archive-stage-2',
                title: 'Auth',
                xpReward: 35,
                requiredQuestCompletions: 3,
                prerequisiteIds: ['archive-stage-1'],
                isMastered: true,
                masteredAt: DateTime(2026, 6, 20),
              ),
            ],
          ),
        ],
        triggeredGoalMilestones: [25, 50],
      );

      final encoded = jsonDecode(storage.debugEncodeSkill(skill)) as Map;

      expect(encoded['goal'], 'Собрать backend roadmap');
      expect(encoded['goalSpec'], isA<Map>());
      expect((encoded['goalSpec'] as Map)['text'], 'Собрать backend roadmap');

      final decoded = storage.debugDecodeSkill(jsonEncode(encoded));

      expect(decoded.goal, 'Собрать backend roadmap');
      expect(decoded.goalSpec.metric, 'этапы');
      expect(decoded.goalSpec.reviews.single.nextFocus, 'Auth');
      expect(decoded.triggeredGoalMilestones, [25, 50]);
      expect(decoded.completedGoals, hasLength(1));
      expect(decoded.completedGoals.single.id, 'goal-history-1');
      expect(decoded.completedGoals.single.skillId, 'roundtrip-skill');
      expect(decoded.completedGoals.single.goalText, 'Собрать первый backend');
      expect(
        decoded.completedGoals.single.completedAt,
        DateTime(2026, 6, 20, 18),
      );
      expect(decoded.completedGoals.single.progressAtCompletion, 1.0);
      expect(decoded.completedGoals.single.completedStages, 4);
      expect(decoded.completedGoals.single.totalStages, 4);
      expect(decoded.completedRoadmaps, hasLength(1));
      final archivedRoadmap = decoded.completedRoadmaps.single;
      expect(archivedRoadmap.id, 'roadmap-history-1');
      expect(archivedRoadmap.completedGoalId, 'goal-history-1');
      expect(archivedRoadmap.goalText, 'Собрать первый backend');
      expect(archivedRoadmap.stages, hasLength(2));
      expect(archivedRoadmap.stages.first.id, 'archive-stage-1');
      expect(archivedRoadmap.stages.first.checklist, ['Контракт']);
      expect(archivedRoadmap.stages.first.checklistDone, [true]);
      expect(archivedRoadmap.stages.last.prerequisiteIds, ['archive-stage-1']);
    });

    test('roadmap roads and linked task survive skill storage roundtrip', () {
      final storage = StorageService();
      const engine = RoadmapEngine();
      final skill = Skill(
        id: 'roadmap-roundtrip-skill',
        name: 'RoadMap storage',
        goal: 'Сохранить три дороги',
        color: const Color(0xFF4A9EFF),
        icon: Icons.route,
        treeNodes: engine.buildTemplate(
          const RoadmapTemplateConfig(
            template: RoadmapTemplate.hard,
            stagesPerPath: 2,
          ),
        ),
      );
      final before = engine.buildPathLayout(skill);
      final linkedStageId = before.paths[1].nodes.last.id;
      final task = Task(
        id: 'roadmap-linked-task',
        title: 'Практика второй дороги',
        skillId: skill.id,
        xpReward: 20,
        type: TaskType.shortTerm,
        treeNodeId: linkedStageId,
      );

      final decodedSkill = storage.debugDecodeSkill(
        storage.debugEncodeSkill(skill),
      );
      final decodedTask = storage.debugDecodeTask(
        storage.debugEncodeTask(task),
      );
      final after = engine.buildPathLayout(decodedSkill);

      expect(after.paths, hasLength(3));
      expect(after.paths.every((path) => path.nodes.length == 2), isTrue);
      expect(
        after.paths
            .map((path) => path.nodes.map((node) => node.id).toList())
            .toList(),
        before.paths
            .map((path) => path.nodes.map((node) => node.id).toList())
            .toList(),
      );
      expect(decodedTask.treeNodeId, linkedStageId);
      expect(
        decodedSkill.treeNodes.any((node) => node.id == decodedTask.treeNodeId),
        isTrue,
      );
    });

    test('invalid or partial goalSpec falls back without crashing', () {
      final storage = StorageService();
      final decoded = storage.debugDecodeSkill(
        jsonEncode({
          'id': 'partial-skill',
          'name': 'Voice',
          'goal': 'Поставить голос',
          'goalSpec': {
            'text': '',
            'targetValue': 'not-a-number',
            'reviews': [
              'bad-review',
              {'id': 'safe-review'},
            ],
          },
        }),
      );

      expect(decoded.goalSpec.text, 'Поставить голос');
      expect(decoded.goalSpec.targetValue, isNull);
      expect(decoded.goalSpec.reviews, hasLength(1));
      expect(decoded.goalSpec.reviews.single.id, 'safe-review');
    });

    test('schema version migration hook promotes legacy versions safely', () {
      final storage = StorageService();

      expect(storage.debugCurrentSchemaVersion, 2);
      expect(storage.debugVersionAfterMigration(null), 2);
      expect(storage.debugVersionAfterMigration('1'), 2);
      expect(storage.debugVersionAfterMigration(2), 2);
      expect(storage.debugVersionAfterMigration('9'), 9);
    });

    test('triggered goal milestone payload keeps only known thresholds', () {
      final storage = StorageService();
      final decoded = storage.debugDecodeSkill(
        jsonEncode({
          'id': 'milestone-skill',
          'name': 'Milestones',
          'goal': 'Cross thresholds',
          'triggeredGoalMilestones': [25, 33, '50', 'bad', 100],
        }),
      );

      expect(decoded.triggeredGoalMilestones, [25, 50, 100]);
    });
  });
}
