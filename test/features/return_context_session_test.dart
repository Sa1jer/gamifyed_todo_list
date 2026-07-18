import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/return_context_resolver.dart';
import 'package:todo_list_app/features/return_context/return_context_session.dart';

void main() {
  ReturnContextCandidate candidate(String key) => ReturnContextCandidate(
    key: key,
    source: ReturnContextSource.completionHistory,
    sourceAt: DateTime.utc(2026, 7, 15),
    skillId: 'skill-a',
    skillName: 'Разработка',
    taskId: 'task-a',
    taskTitle: 'Проверить форму',
    reentryAction: 'Открыть форму',
    usesMinimumAction: false,
  );

  test('dismisses only the current stable candidate key', () {
    final session = ReturnContextSession();
    final first = candidate('first');

    expect(session.visibleCandidate(first), same(first));
    expect(session.dismiss(first), isTrue);
    expect(session.dismiss(first), isFalse);
    expect(session.visibleCandidate(first), isNull);
    expect(session.visibleCandidate(candidate('second')), isNotNull);
  });

  test('a new session restores eligibility without persistence', () {
    final dismissed = candidate('same-key');
    final firstSession = ReturnContextSession()..dismiss(dismissed);
    final restartedSession = ReturnContextSession();

    expect(firstSession.visibleCandidate(dismissed), isNull);
    expect(restartedSession.visibleCandidate(dismissed), isNotNull);
    expect(restartedSession.dismissedCandidateKey, isNull);
  });

  test('reset clears transient dismissal state', () {
    final session = ReturnContextSession();
    final dismissed = candidate('same-key');
    session.dismiss(dismissed);

    session.reset();

    expect(session.visibleCandidate(dismissed), same(dismissed));
  });
}
