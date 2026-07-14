import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/completion_history_index.dart';
import 'package:todo_list_app/models.dart';

void main() {
  group('CompletionHistoryIndex', () {
    final at = DateTime(2026, 7, 14, 10);

    HistoryEntry entry({
      required String id,
      required bool isCompletion,
      String? taskId = 'task-1',
      String taskTitle = 'Квест',
      String skillId = 'skill-1',
      DateTime? timestamp,
    }) {
      return HistoryEntry(
        id: id,
        taskTitle: taskTitle,
        taskId: taskId,
        skillId: skillId,
        skillName: 'Навык',
        skillColor: Colors.blue,
        skillIcon: Icons.fitness_center,
        xp: 20,
        isCompletion: isCompletion,
        at: timestamp ?? at,
      );
    }

    test('completion followed by undo has no effective completion', () {
      final index = CompletionHistoryIndex();
      final history = [
        entry(id: 'undo', isCompletion: false),
        entry(id: 'completion', isCompletion: true),
      ];

      final snapshot = index.resolve(history);

      expect(snapshot.totalCompletions, 0);
      expect(snapshot.byDate, isEmpty);
    });

    test('equal timestamps retain newest-first insertion semantics', () {
      final index = CompletionHistoryIndex();
      final history = [
        entry(id: 'undo', isCompletion: false, timestamp: at),
        entry(id: 'completion', isCompletion: true, timestamp: at),
      ];

      expect(index.resolve(history).totalCompletions, 0);
    });

    test('one undo removes only the most recent matching completion', () {
      final index = CompletionHistoryIndex();
      final history = [
        entry(
          id: 'undo',
          isCompletion: false,
          timestamp: at.add(const Duration(minutes: 2)),
        ),
        entry(
          id: 'second',
          isCompletion: true,
          timestamp: at.add(const Duration(minutes: 1)),
        ),
        entry(id: 'first', isCompletion: true),
      ];

      final snapshot = index.resolve(history);

      expect(snapshot.totalCompletions, 1);
      expect(snapshot.byDate[DateTime(2026, 7, 14)]?.single.id, 'first');
      expect(snapshot.latestRecordedCompletion?.id, 'second');
    });

    test('legacy entries without task ids use skill and title identity', () {
      final index = CompletionHistoryIndex();
      final history = [
        entry(
          id: 'undo',
          isCompletion: false,
          taskId: null,
          taskTitle: 'Старый квест',
        ),
        entry(
          id: 'completion',
          isCompletion: true,
          taskId: null,
          taskTitle: 'Старый квест',
        ),
      ];

      expect(index.resolve(history).totalCompletions, 0);
    });

    test('snapshot collections are immutable', () {
      final index = CompletionHistoryIndex();
      final snapshot = index.resolve([
        entry(id: 'completion', isCompletion: true),
      ]);

      expect(
        () => snapshot.byDate[DateTime(2026, 7, 14)]!.add(
          entry(id: 'other', isCompletion: true),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => snapshot.byDate[DateTime(2026, 7, 15)] = const [],
        throwsUnsupportedError,
      );
    });

    test(
      'invalidation replaces cached data with authoritative empty history',
      () {
        final index = CompletionHistoryIndex();
        final history = [entry(id: 'completion', isCompletion: true)];
        expect(index.resolve(history).totalCompletions, 1);

        history.clear();
        index.invalidate();

        final snapshot = index.resolve(history);
        expect(snapshot.totalCompletions, 0);
        expect(snapshot.byDate, isEmpty);
        expect(snapshot.latestRecordedCompletion, isNull);
        expect(index.forDate(history, at), isEmpty);
        expect(index.hasCompletionOnDate(history, at), isFalse);
      },
    );
  });
}
