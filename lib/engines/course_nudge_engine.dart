import '../models.dart';
import 'goal_engine.dart';

enum CourseNudgeKind {
  createFocusQuest,
  clarifyFocus,
  addMinimumToTask,
  createStageQuest,
  clarifyGoal,
}

class CourseNudge {
  final CourseNudgeKind kind;
  final Skill skill;
  final Task? task;
  final SkillTreeNode? stage;
  final GoalReviewEntry? review;
  final String title;
  final String reason;
  final String actionLabel;
  final String? initialTitle;
  final String? initialMinimumAction;

  const CourseNudge({
    required this.kind,
    required this.skill,
    required this.title,
    required this.reason,
    required this.actionLabel,
    this.task,
    this.stage,
    this.review,
    this.initialTitle,
    this.initialMinimumAction,
  });

  String get key {
    final target =
        task?.id ??
        stage?.id ??
        initialTitle?.trim().toLowerCase() ??
        skill.goal.trim().toLowerCase();
    return '${skill.id}:${review?.id ?? 'no-review'}:${kind.name}:$target';
  }
}

class CourseNudgeEngine {
  const CourseNudgeEngine();

  static const _goalEngine = GoalEngine();

  CourseNudge? suggestPrimary(Iterable<Skill> skills, Iterable<Task> tasks) {
    final nudges = skills
        .map((skill) => suggestForSkill(skill, tasks))
        .whereType<CourseNudge>()
        .toList();
    if (nudges.isEmpty) return null;
    nudges.sort(_compareNudges);
    return nudges.first;
  }

  CourseNudge? suggestForSkill(Skill skill, Iterable<Task> tasks) {
    final skillTasks = tasks.where((task) => task.skillId == skill.id).toList();
    final latestReview = _latestReview(skill);
    final reviewFocus = _reviewFocus(latestReview);

    if (latestReview != null && reviewFocus.isNotEmpty) {
      if (isActionableFocus(reviewFocus)) {
        final title = cleanedFocus(reviewFocus);
        if (!_hasSimilarActiveQuest(skillTasks, title)) {
          final activeStage = _activeStage(skill);
          return CourseNudge(
            kind: CourseNudgeKind.createFocusQuest,
            skill: skill,
            stage: activeStage,
            review: latestReview,
            title: 'Сделай фокус квестом',
            reason:
                'В review уже есть конкретный следующий фокус. Превратим его в один практический квест.',
            actionLabel: 'Создать квест',
            initialTitle: title,
            initialMinimumAction: _suggestMinimumFor(title),
          );
        }
      } else {
        return CourseNudge(
          kind: CourseNudgeKind.clarifyFocus,
          skill: skill,
          review: latestReview,
          title: 'Уточни следующий фокус',
          reason:
              'Фокус из review пока звучит слишком широко. Сделай его маленьким действием на неделю.',
          actionLabel: 'Уточнить фокус',
        );
      }
    }

    final taskWithoutMinimum = _activeTaskWithoutMinimum(skillTasks);
    if (taskWithoutMinimum != null) {
      return CourseNudge(
        kind: CourseNudgeKind.addMinimumToTask,
        skill: skill,
        task: taskWithoutMinimum,
        title: 'Добавь лёгкий старт',
        reason:
            'У квеста “${taskWithoutMinimum.title}” нет минимального шага, поэтому начать его сложнее.',
        actionLabel: 'Добавить минимум',
      );
    }

    final activeStage = _activeStage(skill);
    if (activeStage != null && !_hasActiveStageQuest(skillTasks, activeStage)) {
      return CourseNudge(
        kind: CourseNudgeKind.createStageQuest,
        skill: skill,
        stage: activeStage,
        title: 'Создай практику этапа',
        reason:
            'Этап “${activeStage.title}” активен, но у него пока нет открытого квеста-практики.',
        actionLabel: 'Создать квест',
        initialTitle: 'Практика: ${activeStage.title}',
        initialMinimumAction: 'Сделать 5 минут практики',
      );
    }

    if (!_goalEngine.analyze(skill.goalSpec).isStrong) {
      return CourseNudge(
        kind: CourseNudgeKind.clarifyGoal,
        skill: skill,
        title: 'Сделай цель яснее',
        reason:
            'Цель навыка пока не даёт достаточно опоры для следующих квестов и этапов.',
        actionLabel: 'Уточнить цель',
      );
    }

    return null;
  }

  bool isActionableFocus(String text) {
    final cleaned = cleanedFocus(text);
    final lower = cleaned.toLowerCase();
    if (cleaned.length < 8) return false;
    if (cleaned.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length <
        2) {
      return false;
    }

    const vagueMarkers = [
      'быть лучше',
      'не лениться',
      'заниматься больше',
      'продолжить',
      'стать стабильнее',
      'быть стабильнее',
      'делать больше',
    ];
    if (vagueMarkers.any((marker) => lower.contains(marker))) return false;

    const actionVerbs = [
      'сделать',
      'выполнить',
      'прочитать',
      'написать',
      'дописать',
      'создать',
      'пройти',
      'потренировать',
      'тренировать',
      'закрыть',
      'подготовить',
      'собрать',
      'изучить',
      'повторить',
      'решить',
      'настроить',
      'запустить',
    ];
    final hasVerb = actionVerbs.any((verb) => lower.contains(verb));
    final hasNumber = RegExp(r'\d').hasMatch(lower);
    return hasVerb || hasNumber;
  }

  String cleanedFocus(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), ' ');

  int _compareNudges(CourseNudge a, CourseNudge b) {
    final byPriority = _priority(a.kind).compareTo(_priority(b.kind));
    if (byPriority != 0) return byPriority;
    return a.skill.name.toLowerCase().compareTo(b.skill.name.toLowerCase());
  }

  int _priority(CourseNudgeKind kind) {
    return switch (kind) {
      CourseNudgeKind.createFocusQuest => 0,
      CourseNudgeKind.clarifyFocus => 1,
      CourseNudgeKind.addMinimumToTask => 2,
      CourseNudgeKind.createStageQuest => 3,
      CourseNudgeKind.clarifyGoal => 4,
    };
  }

  GoalReviewEntry? _latestReview(Skill skill) {
    if (skill.goalSpec.reviews.isEmpty) return null;
    final reviews = [...skill.goalSpec.reviews]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews.first;
  }

  String _reviewFocus(GoalReviewEntry? review) {
    if (review == null) return '';
    final nextFocus = review.nextFocus.trim();
    if (nextFocus.isNotEmpty) return nextFocus;
    return review.adjustment.trim();
  }

  Task? _activeTaskWithoutMinimum(List<Task> tasks) {
    final candidates = tasks
        .where((task) => !task.isDone && task.minimumAction.trim().isEmpty)
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final byPriority = _taskPriority(
        a.priority,
      ).compareTo(_taskPriority(b.priority));
      if (byPriority != 0) return byPriority;
      final byXp = b.xpReward.compareTo(a.xpReward);
      if (byXp != 0) return byXp;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return candidates.first;
  }

  int _taskPriority(Priority priority) {
    return switch (priority) {
      Priority.high => 0,
      Priority.medium => 1,
      Priority.low => 2,
    };
  }

  SkillTreeNode? _activeStage(Skill skill) {
    return skill.treeNodes
        .where(
          (node) => skill.treeNodeStatus(node) == SkillTreeNodeStatus.active,
        )
        .firstOrNull;
  }

  bool _hasActiveStageQuest(List<Task> tasks, SkillTreeNode stage) {
    return tasks.any((task) => !task.isDone && task.treeNodeId == stage.id);
  }

  bool _hasSimilarActiveQuest(List<Task> tasks, String title) {
    final normalizedTitle = _normalize(title);
    return tasks.any((task) {
      if (task.isDone) return false;
      final taskTitle = _normalize(task.title);
      return taskTitle == normalizedTitle ||
          taskTitle.contains(normalizedTitle) ||
          normalizedTitle.contains(taskTitle);
    });
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^а-яa-z0-9]+', unicode: true), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  String _suggestMinimumFor(String title) {
    final lower = title.toLowerCase();
    if (RegExp(r'\d').hasMatch(lower)) return 'Начать с 5 минут';
    return 'Сделать первый маленький шаг';
  }
}
