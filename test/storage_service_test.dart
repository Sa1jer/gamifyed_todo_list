import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  group('StorageService enum compatibility', () {
    test('task roundtrip stores enum names', () {
      final storage = StorageService();
      final task = Task(
        id: 'task-1',
        title: 'String enum task',
        skillId: 'skill-1',
        xpReward: 25,
        type: TaskType.repeating,
        repeatFrequency: RepeatFrequency.weekly,
        priority: Priority.high,
      );

      final encoded = jsonDecode(storage.debugEncodeTask(task)) as Map;

      expect(encoded['type'], TaskType.repeating.name);
      expect(encoded['repeatFrequency'], RepeatFrequency.weekly.name);
      expect(encoded['priority'], Priority.high.name);

      final decoded = storage.debugDecodeTask(jsonEncode(encoded));

      expect(decoded.type, TaskType.repeating);
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
}
