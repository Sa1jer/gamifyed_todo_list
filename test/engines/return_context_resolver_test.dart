import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/return_context_resolver.dart';

void main() {
  const resolver = ReturnContextResolver();
  final now = DateTime.utc(2026, 7, 18, 12);

  ReturnContextSkillRecord skill(String id, [String? name]) =>
      ReturnContextSkillRecord(id: id, name: name ?? id);

  ReturnContextHistoryRecord history({
    String id = 'history',
    String skillId = 'skill-a',
    String? taskId = 'task-a',
    String title = 'Завершённый квест',
    DateTime? at,
    bool completion = true,
    bool inbox = false,
  }) => ReturnContextHistoryRecord(
    id: id,
    taskId: taskId,
    taskTitle: title,
    skillId: skillId,
    skillName: skillId,
    at: at ?? now.subtract(const Duration(days: 3)),
    isCompletion: completion,
    isInbox: inbox,
  );

  ReturnContextActionRecord action({
    String taskId = 'task-a',
    String skillId = 'skill-a',
    String label = 'Продолжить квест',
    int order = 0,
    bool minimum = false,
    String? stageId,
    String? stageTitle,
  }) => ReturnContextActionRecord(
    taskId: taskId,
    taskTitle: taskId,
    skillId: skillId,
    skillName: skillId,
    actionLabel: label,
    sourceOrder: order,
    usesMinimumAction: minimum,
    stageId: stageId,
    stageTitle: stageTitle,
  );

  ReturnContextReviewRecord review({
    String id = 'review',
    String skillId = 'skill-a',
    DateTime? at,
    String wins = '',
    String nextFocus = 'Вернуться к фокусу',
    bool meaningful = true,
  }) => ReturnContextReviewRecord(
    id: id,
    skillId: skillId,
    skillName: skillId,
    at: at ?? now.subtract(const Duration(days: 3)),
    wins: wins,
    nextFocus: nextFocus,
    isMeaningful: meaningful,
  );

  ReturnContextCandidate? resolve({
    DateTime? at,
    Duration threshold = defaultReturnContextPauseThreshold,
    List<ReturnContextSkillRecord>? skills,
    List<ReturnContextHistoryRecord>? histories,
    List<ReturnContextReviewRecord>? reviews,
    List<ReturnContextActionRecord>? actions,
    String? selectedSkillId,
  }) {
    return resolver.resolve(
      ReturnContextInput(
        now: now,
        pauseThreshold: threshold,
        selectedSkillId: selectedSkillId,
        skills: skills ?? [skill('skill-a')],
        history: histories ?? [history(at: at)],
        reviews: reviews ?? const [],
        actions: actions ?? [action()],
      ),
    );
  }

  group('pause boundary', () {
    test('requires reliable meaningful evidence', () {
      expect(resolve(histories: const [], reviews: const []), isNull);
      expect(resolve(histories: [history(completion: false)]), isNull);
    });

    test('does not show before threshold and accepts exact one day', () {
      expect(resolve(at: now.subtract(const Duration(hours: 23))), isNull);
      expect(resolve(at: now.subtract(const Duration(days: 1))), isNotNull);
    });

    test('supports explicit three and seven day returns', () {
      expect(
        resolve(
          at: now.subtract(const Duration(days: 3)),
          threshold: const Duration(days: 3),
        ),
        isNotNull,
      );
      expect(
        resolve(
          at: now.subtract(const Duration(days: 7)),
          threshold: const Duration(days: 7),
        ),
        isNotNull,
      );
    });

    test('explicit now rejects future evidence', () {
      expect(resolve(at: now.add(const Duration(minutes: 1))), isNull);
    });
  });

  group('candidate policy', () {
    test('latest direct activity for an existing normal skill wins', () {
      final candidate = resolve(
        skills: [skill('skill-a'), skill('skill-b')],
        histories: [
          history(
            id: 'older',
            skillId: 'skill-a',
            at: now.subtract(const Duration(days: 5)),
          ),
          history(
            id: 'newer',
            skillId: 'skill-b',
            taskId: 'task-b',
            at: now.subtract(const Duration(days: 2)),
          ),
        ],
        actions: [
          action(),
          action(taskId: 'task-b', skillId: 'skill-b'),
        ],
      );

      expect(candidate?.skillId, 'skill-b');
      expect(candidate?.source, ReturnContextSource.completionHistory);
    });

    test('Inbox and deleted-skill activity cannot establish a pause', () {
      expect(
        resolve(histories: [history(skillId: 'inbox', inbox: true)]),
        isNull,
      );
      expect(
        resolve(
          histories: [history(skillId: 'deleted')],
          selectedSkillId: 'skill-a',
        ),
        isNull,
      );
    });

    test('deleted task falls back to the first valid action in its skill', () {
      final candidate = resolve(
        histories: [history(taskId: 'deleted-task')],
        actions: [
          action(taskId: 'valid-task', label: 'Надёжный следующий шаг'),
        ],
      );

      expect(candidate?.taskId, 'valid-task');
      expect(candidate?.reentryAction, 'Надёжный следующий шаг');
    });

    test('missing or locked stage is never reconstructed by the resolver', () {
      final candidate = resolve(
        histories: [history(taskId: 'deleted-stage-task')],
        actions: [action(taskId: 'safe-task')],
      );

      expect(candidate?.taskId, 'safe-task');
      expect(candidate?.stageId, isNull);
      expect(candidate?.stageTitle, isNull);
    });

    test('recurring reset returns to the same now-unfinished task', () {
      final candidate = resolve(
        histories: [history(taskId: 'repeat-task')],
        actions: [action(taskId: 'repeat-task', label: 'Повторить сегодня')],
      );

      expect(candidate?.taskId, 'repeat-task');
      expect(candidate?.reentryAction, 'Повторить сегодня');
    });

    test('unfinished Minimum Action is preserved as the re-entry action', () {
      final candidate = resolve(
        actions: [
          action(
            label: 'Открыть один файл',
            minimum: true,
            stageId: 'stage-a',
            stageTitle: 'Основа',
          ),
        ],
      );

      expect(candidate?.usesMinimumAction, isTrue);
      expect(candidate?.reentryAction, 'Открыть один файл');
      expect(candidate?.stageTitle, 'Основа');
    });

    test('review next focus is weaker than direct work evidence', () {
      final direct = resolve(
        histories: [history(at: now.subtract(const Duration(days: 6)))],
        reviews: [review(at: now.subtract(const Duration(days: 2)))],
      );
      expect(direct?.source, ReturnContextSource.completionHistory);

      final fallback = resolve(
        histories: const [],
        reviews: [review(wins: 'Проверена архитектура')],
        actions: const [],
      );
      expect(fallback?.source, ReturnContextSource.goalReview);
      expect(fallback?.lastResult, 'Проверена архитектура');
      expect(fallback?.reentryAction, 'Вернуться к фокусу');
    });

    test('selected skill is only a weak fallback after pause evidence', () {
      final candidate = resolve(
        histories: const [],
        reviews: [review(nextFocus: '', wins: 'Есть результат')],
        selectedSkillId: 'skill-a',
        actions: [action(taskId: 'selected-task')],
      );

      expect(candidate?.source, ReturnContextSource.selectedSkillFallback);
      expect(candidate?.taskId, 'selected-task');
    });

    test('history and action tie-breaks are deterministic', () {
      final candidate = resolve(
        histories: [
          history(id: 'z'),
          history(id: 'a'),
        ],
        actions: [
          action(taskId: 'task-z', order: 1),
          action(taskId: 'task-b', order: 0),
          action(taskId: 'task-a', order: 0),
        ],
      );

      expect(candidate?.lastResult, 'Завершённый квест');
      expect(candidate?.taskId, 'task-a');
      expect(candidate?.key, startsWith('completionHistory|a|'));
    });
  });

  group('detached output', () {
    test('candidate key is stable through unrelated input changes', () {
      final first = resolve();
      final second = resolve(
        skills: [skill('skill-a'), skill('unrelated')],
        actions: [
          action(),
          action(taskId: 'other', skillId: 'unrelated'),
        ],
      );

      expect(second?.key, first?.key);
    });

    test('result retains only copied scalar values', () {
      final sourceActions = <ReturnContextActionRecord>[
        action(label: 'Исходный шаг'),
      ];
      final input = ReturnContextInput(
        now: now,
        skills: [skill('skill-a')],
        history: [history()],
        reviews: const [],
        actions: sourceActions,
      );
      final candidate = resolver.resolve(input);

      sourceActions
        ..clear()
        ..add(action(label: 'Изменённый шаг'));

      expect(candidate?.reentryAction, 'Исходный шаг');
      expect(candidate?.skillId, 'skill-a');
      expect(candidate?.taskId, 'task-a');
    });
  });
}
