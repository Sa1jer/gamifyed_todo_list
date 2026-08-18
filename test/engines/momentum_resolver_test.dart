import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/momentum_resolver.dart';

void main() {
  const resolver = MomentumResolver();
  final now = DateTime(2026, 8, 18, 12);

  MomentumSkillRecord skill(
    String id, {
    double progress = 0,
    bool completed = false,
  }) => MomentumSkillRecord(
    skillId: id,
    skillName: 'Навык $id',
    goalProgress: progress,
    goalCompleted: completed,
  );

  MomentumActionRecord action(
    String skillId, {
    String? taskId,
    String? stageId,
    int order = 0,
    bool minimum = false,
  }) => MomentumActionRecord(
    taskId: taskId ?? 'task-$skillId',
    taskTitle: 'Квест $skillId',
    skillId: skillId,
    skillName: 'Навык $skillId',
    actionLabel: minimum ? 'Минимальный шаг $skillId' : 'Квест $skillId',
    sourceOrder: order,
    usesMinimumAction: minimum,
    stageId: stageId,
  );

  MomentumStageRecord stage(
    String skillId, {
    required String id,
    MomentumStageRole role = MomentumStageRole.current,
    double progress = 0,
    int completed = 0,
    int required = 3,
    DateTime? completedAt,
  }) => MomentumStageRecord(
    skillId: skillId,
    stageId: id,
    stageTitle: 'Этап $id',
    role: role,
    progress: progress,
    completedQuestCount: completed,
    requiredQuestCount: required,
    completedAt:
        completedAt ??
        (role == MomentumStageRole.completed
            ? now.subtract(const Duration(days: 1))
            : null),
  );

  MomentumHistoryRecord history(
    String skillId, {
    String id = 'history',
    DateTime? at,
    bool inbox = false,
    bool completion = true,
    String? taskId,
  }) => MomentumHistoryRecord(
    id: id,
    skillId: skillId,
    at: at ?? now.subtract(const Duration(days: 1)),
    isCompletion: completion,
    isInbox: inbox,
    taskId: taskId,
  );

  MomentumInput input({
    List<MomentumSkillRecord> skills = const [],
    List<MomentumStageRecord> stages = const [],
    List<MomentumActionRecord> actions = const [],
    List<MomentumHistoryRecord> history = const [],
    String? selectedSkillId,
    String? returnContextSkillId,
    DateTime? at,
    Iterable<String>? existingTaskIds,
  }) {
    final taskIds =
        existingTaskIds ??
        {
          ...actions.map((item) => item.taskId),
          ...history.map((item) => item.taskId).whereType<String>(),
        };
    return MomentumInput(
      now: at ?? now,
      skills: skills,
      stages: stages,
      actions: actions,
      history: history,
      existingTaskIds: taskIds,
      selectedSkillId: selectedSkillId,
      returnContextSkillId: returnContextSkillId,
    );
  }

  test('1. empty app has no Momentum', () {
    expect(resolver.resolve(input()), isNull);
  });

  test('2. skill without evidence has no misleading Momentum', () {
    expect(
      resolver.resolve(input(skills: [skill('a')], actions: [action('a')])),
      isNull,
    );
  });

  test('3. one remaining stage quest is the strongest boundary', () {
    final result = resolver.resolve(
      input(
        skills: [skill('a', progress: .8)],
        actions: [action('a', stageId: 's')],
        stages: [stage('a', id: 's', progress: .8, completed: 4, required: 5)],
        history: [history('a')],
      ),
    );
    expect(result?.reason, MomentumReason.stageOneQuestRemaining);
    expect(result?.remainingCount, 1);
    expect(result?.supportingText, contains('один квест'));
  });

  test('4. known mostly complete stage reports factual counts', () {
    final result = resolver.resolve(
      input(
        skills: [skill('a')],
        actions: [action('a', stageId: 's')],
        stages: [stage('a', id: 's', progress: .7, completed: 7, required: 10)],
      ),
    );
    expect(result?.reason, MomentumReason.stageNearlyComplete);
    expect(result?.supportingText, contains('7 из 10'));
  });

  test('5. completed stage with a valid continuation is evidence', () {
    final result = resolver.resolve(
      input(
        skills: [skill('a')],
        actions: [action('a', stageId: 'current')],
        stages: [
          stage('a', id: 'done', role: MomentumStageRole.completed),
          stage('a', id: 'current'),
        ],
      ),
    );
    expect(result?.reason, MomentumReason.completedStageContinuation);
    expect(result?.supportingText, contains('завершён'));
  });

  test('6. substantially advanced goal is projected as evidence', () {
    final result = resolver.resolve(
      input(skills: [skill('a', progress: .75)], actions: [action('a')]),
    );
    expect(result?.reason, MomentumReason.goalMeaningfullyAdvanced);
    expect(result?.progressFraction, .75);
  });

  test('7. weak goal progress is not described as near completion', () {
    expect(
      resolver.resolve(
        input(skills: [skill('a', progress: .51)], actions: [action('a')]),
      ),
      isNull,
    );
  });

  test('8. recent real completion is evidence', () {
    final result = resolver.resolve(
      input(
        skills: [skill('a')],
        actions: [action('a')],
        history: [history('a')],
      ),
    );
    expect(result?.reason, MomentumReason.recentRealProgress);
    expect(result?.evidenceAt, now.subtract(const Duration(days: 1)));
  });

  test('9. old activity is not presented as recent', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a')],
          actions: [action('a')],
          history: [history('a', at: now.subtract(const Duration(days: 8)))],
        ),
      ),
      isNull,
    );
  });

  test('10. Inbox completion is excluded from skill Momentum', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a')],
          actions: [action('a')],
          history: [history('a', inbox: true)],
        ),
      ),
      isNull,
    );
  });

  test('11. action for deleted skill is excluded', () {
    expect(resolver.resolve(input(actions: [action('deleted')])), isNull);
  });

  test('12. evidence for a deleted task cannot support another action', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a')],
          actions: [action('a')],
          history: [history('a', taskId: 'gone')],
          existingTaskIds: const ['task-a'],
        ),
      ),
      isNull,
    );
  });

  test('13. action attached to a deleted stage has no stage evidence', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a')],
          actions: [action('a', stageId: 'gone')],
        ),
      ),
      isNull,
    );
  });

  test('14. missing RoadMap stays safe', () {
    final result = resolver.resolve(
      input(skills: [skill('a')], actions: [action('a', minimum: true)]),
    );
    expect(result?.reason, MomentumReason.minimumActionAvailable);
  });

  test('15. single-task skill can expose its existing minimum action', () {
    final result = resolver.resolve(
      input(skills: [skill('a')], actions: [action('a', minimum: true)]),
    );
    expect(result?.taskId, 'task-a');
    expect(result?.supportingText, contains('минимальный шаг'));
  });

  test('16. completed path without continuation has no Momentum', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a', progress: 1, completed: true)],
          actions: [action('a')],
          stages: [stage('a', id: 'done', role: MomentumStageRole.completed)],
        ),
      ),
      isNull,
    );
  });

  test('17. large RoadMap remains deterministic', () {
    final stages = List.generate(
      100,
      (index) => stage(
        'a',
        id: 's$index',
        role: index == 73
            ? MomentumStageRole.current
            : MomentumStageRole.locked,
        progress: index == 73 ? .8 : 0,
        completed: index == 73 ? 4 : 0,
        required: 5,
      ),
    );
    final result = resolver.resolve(
      input(
        skills: [skill('a')],
        actions: [action('a', stageId: 's73')],
        stages: stages,
      ),
    );
    expect(result?.reason, MomentumReason.stageOneQuestRemaining);
  });

  test('18. unfinished Minimum Action is a low-priority truthful signal', () {
    final result = resolver.resolve(
      input(skills: [skill('a')], actions: [action('a', minimum: true)]),
    );
    expect(result?.reason, MomentumReason.minimumActionAvailable);
  });

  test('19. locked stage cannot create near-finish Momentum', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a')],
          actions: [action('a', stageId: 'locked')],
          stages: [
            stage(
              'a',
              id: 'locked',
              role: MomentumStageRole.locked,
              progress: .9,
              completed: 9,
              required: 10,
            ),
          ],
        ),
      ),
      isNull,
    );
  });

  test('20. equal candidates use deterministic source order', () {
    final result = resolver.resolve(
      input(
        skills: [skill('a'), skill('b')],
        actions: [action('b', order: 1), action('a', order: 0)],
        history: [
          history('a'),
          history('b', id: 'h2'),
        ],
      ),
    );
    expect(result?.skillId, 'a');
  });

  test('21. explicit now rejects future history evidence', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a')],
          actions: [action('a')],
          history: [history('a', at: now.add(const Duration(minutes: 1)))],
          at: now,
        ),
      ),
      isNull,
    );
  });

  test('22. source list mutation after input creation cannot alter result', () {
    final sourceSkills = [skill('a', progress: .8)];
    final sourceActions = [action('a')];
    final captured = input(skills: sourceSkills, actions: sourceActions);
    sourceSkills.clear();
    sourceActions.clear();
    expect(
      resolver.resolve(captured)?.reason,
      MomentumReason.goalMeaningfullyAdvanced,
    );
  });

  test('23. generated copy never invents a time estimate', () {
    final result = resolver.resolve(
      input(skills: [skill('a')], actions: [action('a', minimum: true)]),
    );
    expect(result?.supportingText, isNot(contains('минут')));
    expect(result?.supportingText, isNot(contains('быстро')));
  });

  test('24. real stage boundary outranks lower supporting evidence', () {
    final result = resolver.resolve(
      input(
        skills: [skill('a', progress: .9)],
        actions: [action('a', stageId: 's', minimum: true)],
        stages: [stage('a', id: 's', progress: .9, completed: 9, required: 10)],
        history: [history('a')],
      ),
    );
    expect(result?.reason, MomentumReason.stageOneQuestRemaining);
  });

  test('25. Return Context scopes Momentum to the same thread', () {
    final result = resolver.resolve(
      input(
        skills: [skill('a'), skill('b', progress: .9)],
        actions: [
          action('a', order: 0, minimum: true),
          action('b', order: 1, stageId: 'b-stage'),
        ],
        stages: [
          stage('b', id: 'b-stage', progress: .9, completed: 4, required: 5),
        ],
        returnContextSkillId: 'a',
      ),
    );
    expect(result?.skillId, 'a');
    expect(result?.reason, MomentumReason.minimumActionAvailable);
  });

  test('26. selected thread wins an otherwise equal tie', () {
    final result = resolver.resolve(
      input(
        skills: [skill('a'), skill('b')],
        actions: [action('a', order: 0), action('b', order: 1)],
        history: [
          history('a'),
          history('b', id: 'h2'),
        ],
        selectedSkillId: 'b',
      ),
    );
    expect(result?.skillId, 'b');
  });

  test('27. negative recent window disables resolution safely', () {
    final invalid = MomentumInput(
      now: now,
      recentWindow: const Duration(days: -1),
      skills: [skill('a', progress: .9)],
      stages: const [],
      actions: [action('a')],
      history: const [],
      existingTaskIds: const ['task-a'],
    );
    expect(resolver.resolve(invalid), isNull);
  });

  test('28. non-completion history is not progress evidence', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a')],
          actions: [action('a')],
          history: [history('a', completion: false)],
        ),
      ),
      isNull,
    );
  });

  test('29. completed goal is not presented as pending Momentum', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a', progress: 1, completed: true)],
          actions: [action('a')],
        ),
      ),
      isNull,
    );
  });

  test('30. vague percentage below stage threshold is rejected', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a')],
          actions: [action('a', stageId: 's')],
          stages: [
            stage('a', id: 's', progress: .66, completed: 6, required: 10),
          ],
        ),
      ),
      isNull,
    );
  });

  test('31. old completed milestone does not shadow advanced goal', () {
    final result = resolver.resolve(
      input(
        skills: [skill('a', progress: .75)],
        actions: [action('a', stageId: 'current')],
        stages: [
          stage(
            'a',
            id: 'done',
            role: MomentumStageRole.completed,
            completedAt: now.subtract(const Duration(days: 8)),
          ),
          stage('a', id: 'current'),
        ],
      ),
    );

    expect(result?.reason, MomentumReason.goalMeaningfullyAdvanced);
  });

  test('32. action for a deleted task is rejected', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a', progress: .8)],
          actions: [action('a')],
          existingTaskIds: const [],
        ),
      ),
      isNull,
    );
  });

  test('33. invalid negative stage target is ignored safely', () {
    expect(
      resolver.resolve(
        input(
          skills: [skill('a')],
          actions: [action('a', stageId: 'invalid')],
          stages: [
            stage('a', id: 'invalid', progress: 1, completed: 1, required: -1),
          ],
        ),
      ),
      isNull,
    );
  });
}
