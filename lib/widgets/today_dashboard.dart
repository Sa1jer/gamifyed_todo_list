import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'shared.dart';

class TodayDashboard extends StatefulWidget {
  final Function(String id, Offset pos) onComplete;
  final Function(String id, Offset pos) onMinimumAction;
  final VoidCallback? onCreateFirstSkill;

  const TodayDashboard({
    super.key,
    required this.onComplete,
    required this.onMinimumAction,
    this.onCreateFirstSkill,
  });

  static Skill? _skillFor(AppState state, Task task) {
    return state.skills.where((skill) => skill.id == task.skillId).firstOrNull;
  }

  static SkillTreeNode? _stageFor(AppState state, Task task) {
    final skill = _skillFor(state, task);
    final nodeId = task.treeNodeId;
    if (skill == null || nodeId == null) return null;
    return skill.treeNodes.where((node) => node.id == nodeId).firstOrNull;
  }

  static bool _isActiveStageTask(AppState state, Task task) {
    final skill = _skillFor(state, task);
    final stage = _stageFor(state, task);
    return skill != null &&
        stage != null &&
        skill.treeNodeStatus(stage) == SkillTreeNodeStatus.active;
  }

  static Task? _pickNextTask(AppState state, List<Task> tasks) {
    final sorted = _sortedTasks(state, tasks);
    if (sorted.isEmpty) return null;
    return sorted.first;
  }

  static List<Task> _sortedTasks(AppState state, List<Task> tasks) {
    final result = [...tasks];
    result.sort((a, b) {
      final byRisk = _riskScore(a).compareTo(_riskScore(b));
      if (byRisk != 0) return byRisk;

      final byMinimum = _minimumScore(a).compareTo(_minimumScore(b));
      if (byMinimum != 0) return byMinimum;

      final byStage = _stageScore(state, a).compareTo(_stageScore(state, b));
      if (byStage != 0) return byStage;

      final byRepeating = _repeatingScore(a).compareTo(_repeatingScore(b));
      if (byRepeating != 0) return byRepeating;

      final byPriority = _priorityScore(
        a.priority,
      ).compareTo(_priorityScore(b.priority));
      if (byPriority != 0) return byPriority;

      final byXp = state.previewEarnedXP(b).compareTo(state.previewEarnedXP(a));
      if (byXp != 0) return byXp;

      final byUpdated = b.updatedAt.compareTo(a.updatedAt);
      if (byUpdated != 0) return byUpdated;

      final byCreated = b.createdAt.compareTo(a.createdAt);
      if (byCreated != 0) return byCreated;

      return a.title.compareTo(b.title);
    });
    return result;
  }

  static List<Task> _riskTasks(List<Task> tasks) {
    final now = DateTime.now();
    final result = tasks
        .where((task) => task.nextResetAt != null)
        .where(
          (task) =>
              task.nextResetAt!.difference(now) <= const Duration(days: 1),
        )
        .toList();
    result.sort((a, b) => a.nextResetAt!.compareTo(b.nextResetAt!));
    return result;
  }

  static int _priorityScore(Priority priority) => switch (priority) {
    Priority.high => 0,
    Priority.medium => 1,
    Priority.low => 2,
  };

  static int _riskScore(Task task) {
    final resetAt = task.nextResetAt;
    if (task.type != TaskType.repeating || resetAt == null) return 1;
    final untilReset = resetAt.difference(DateTime.now());
    return !untilReset.isNegative && untilReset <= const Duration(hours: 24)
        ? 0
        : 1;
  }

  static int _minimumScore(Task task) =>
      task.hasMinimumAction && !task.isDone && !task.isMinimumActionDone
      ? 0
      : 1;

  static int _stageScore(AppState state, Task task) =>
      _isActiveStageTask(state, task) ? 0 : 1;

  static int _repeatingScore(Task task) =>
      task.type == TaskType.repeating ? 0 : 1;

  static bool _shouldRecommendMinimumAction(Task task) {
    return task.hasMinimumAction &&
        !task.isDone &&
        !task.isMinimumActionDone &&
        (task.type == TaskType.midTerm ||
            task.type == TaskType.longTerm ||
            task.subtasks.length >= 3 ||
            task.xpReward >= 80);
  }

  @override
  State<TodayDashboard> createState() => _TodayDashboardState();
}

class _TodayDashboardState extends State<TodayDashboard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isDark = state.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final activeTasks = state.tasks.where((task) => !task.isDone).toList();
    final dailyTasks = activeTasks
        .where((task) => task.type == TaskType.repeating)
        .toList();
    final nextTask = TodayDashboard._pickNextTask(state, activeTasks);
    final riskyTasks = TodayDashboard._riskTasks(dailyTasks);
    final stats = state.todayStats;
    final statusLabels = _todayStatusLabels(state: state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactDashboard = constraints.maxWidth < 720;

        return AnimatedContainer(
          duration: kMotionSlow,
          curve: kMotionCurve,
          height: _expanded ? (compactDashboard ? 236 : 258) : 76,
          child: AppPanel(
            isDark: isDark,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, _expanded ? 12 : 9, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final pinActions = constraints.maxWidth >= 1100;
                      final actionReserve =
                          (constraints.maxWidth * (pinActions ? 0.45 : 0.52))
                              .clamp(220.0, 720.0)
                              .toDouble();
                      final titleBlock = Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Действовать сегодня',
                            style: TextStyle(
                              color: txt,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            compactDashboard
                                ? 'Следующий шаг — без настройки системы.'
                                : 'Сначала следующий квест. Аналитика и трофеи живут в “Прогрессе”.',
                            style: TextStyle(color: sub, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                      final statusRow = _TodayStatusRow(
                        labels: statusLabels,
                        compact: !_expanded,
                      );

                      return SizedBox(
                        width: constraints.maxWidth,
                        height: 52,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 0,
                              right: actionReserve + 12,
                              top: 0,
                              bottom: 0,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFFFFCC00),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: titleBlock),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: actionReserve - 44,
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      reverse: true,
                                      child: statusRow,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _CollapseButton(
                                    expanded: _expanded,
                                    color: sub,
                                    onTap: () =>
                                        setState(() => _expanded = !_expanded),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: ClipRect(
                      child: MotionFadeSlideSwitcher(
                        child: _expanded
                            ? Padding(
                                key: const ValueKey('today-expanded-content'),
                                padding: const EdgeInsets.only(top: 8),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final content = _DashboardContent(
                                      state: state,
                                      nextTask: nextTask,
                                      riskyTasks: riskyTasks,
                                      activeTasks: activeTasks,
                                      dailyTasks: dailyTasks,
                                      todayTasks: stats?.tasksCompleted ?? 0,
                                      todayXp: stats?.xpEarned ?? 0,
                                      isDark: isDark,
                                      onComplete: widget.onComplete,
                                      onMinimumAction: widget.onMinimumAction,
                                      onCreateFirstSkill:
                                          widget.onCreateFirstSkill,
                                    );

                                    if (constraints.maxWidth < 720) {
                                      return _CompactDashboardContent(
                                        state: state,
                                        nextTask: nextTask,
                                        isDark: isDark,
                                        onComplete: widget.onComplete,
                                        onMinimumAction: widget.onMinimumAction,
                                        onCreateFirstSkill:
                                            widget.onCreateFirstSkill,
                                      );
                                    }

                                    if (constraints.maxWidth >= 960) {
                                      return content;
                                    }

                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: 960,
                                        child: content,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('today-collapsed-content'),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<_TodayStatusLabelData> _todayStatusLabels({required AppState state}) {
    return [
      _TodayStatusLabelData(
        label: 'до ур. ${state.profile.level + 1}',
        value: '${state.profile.xpNeeded - state.profile.xp} XP',
        color: const Color(0xFF4A9EFF),
      ),
      if (state.profile.streakProtectionCharges > 0)
        _TodayStatusLabelData(
          label: 'защита',
          value: '${state.profile.streakProtectionCharges} амулет',
          color: const Color(0xFF4A9EFF),
        ),
    ];
  }
}

class _DashboardContent extends StatelessWidget {
  final AppState state;
  final Task? nextTask;
  final List<Task> riskyTasks;
  final List<Task> activeTasks;
  final List<Task> dailyTasks;
  final int todayTasks;
  final int todayXp;
  final bool isDark;
  final Function(String id, Offset pos) onComplete;
  final Function(String id, Offset pos) onMinimumAction;
  final VoidCallback? onCreateFirstSkill;

  const _DashboardContent({
    required this.state,
    required this.nextTask,
    required this.riskyTasks,
    required this.activeTasks,
    required this.dailyTasks,
    required this.todayTasks,
    required this.todayXp,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
    required this.onCreateFirstSkill,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: _NextActionCard(
            state: state,
            task: nextTask,
            skill: nextTask == null
                ? null
                : TodayDashboard._skillFor(state, nextTask!),
            isDark: isDark,
            onComplete: onComplete,
            onMinimumAction: onMinimumAction,
            onCreateFirstSkill: onCreateFirstSkill,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: _StatsGrid(
            isDark: isDark,
            todayTasks: todayTasks,
            todayXp: todayXp,
            activeQuests: activeTasks.length,
            dailyQuests: dailyTasks.length,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: _QuestQueue(
            state: state,
            title: riskyTasks.isEmpty ? 'Фокус на сегодня' : 'Серии под риском',
            subtitle: riskyTasks.isEmpty
                ? 'Начни с малого — поток придёт после первого действия'
                : 'Эти квесты лучше закрыть первыми',
            tasks: riskyTasks.isEmpty
                ? TodayDashboard._sortedTasks(
                    state,
                    activeTasks,
                  ).take(3).toList()
                : riskyTasks.take(3).toList(),
            isDark: isDark,
            onComplete: onComplete,
            onMinimumAction: onMinimumAction,
          ),
        ),
      ],
    );
  }
}

class _CompactDashboardContent extends StatelessWidget {
  final AppState state;
  final Task? nextTask;
  final bool isDark;
  final Function(String id, Offset pos) onComplete;
  final Function(String id, Offset pos) onMinimumAction;
  final VoidCallback? onCreateFirstSkill;

  const _CompactDashboardContent({
    required this.state,
    required this.nextTask,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
    required this.onCreateFirstSkill,
  });

  @override
  Widget build(BuildContext context) {
    return _NextActionCard(
      state: state,
      task: nextTask,
      skill: nextTask == null
          ? null
          : TodayDashboard._skillFor(state, nextTask!),
      isDark: isDark,
      onComplete: onComplete,
      onMinimumAction: onMinimumAction,
      onCreateFirstSkill: onCreateFirstSkill,
    );
  }
}

class _NextActionCard extends StatelessWidget {
  final AppState state;
  final Task? task;
  final Skill? skill;
  final bool isDark;
  final Function(String id, Offset pos) onComplete;
  final Function(String id, Offset pos) onMinimumAction;
  final VoidCallback? onCreateFirstSkill;

  const _NextActionCard({
    required this.state,
    required this.task,
    required this.skill,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
    required this.onCreateFirstSkill,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = skill?.color ?? const Color(0xFF4A9EFF);

    if (task == null) {
      final hasSkills = state.skills.isNotEmpty;
      return _SoftCard(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: accent, size: 26),
            const SizedBox(height: 10),
            Text(
              hasSkills ? 'На сегодня всё чисто' : 'Начните с первого навыка',
              style: TextStyle(
                color: txt,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasSkills
                  ? 'Добавьте один маленький квест или минимальный шаг.'
                  : 'Создайте навык: первый этап и первый квест появятся сразу.',
              style: TextStyle(color: sub, fontSize: 12, height: 1.25),
            ),
            if (!hasSkills && onCreateFirstSkill != null) ...[
              const SizedBox(height: 12),
              SmallBtn(
                label: 'Создать первый навык',
                icon: Icons.add,
                color: accent,
                onTap: onCreateFirstSkill!,
              ),
            ],
          ],
        ),
      );
    }

    final earnedXp = state.previewEarnedXP(task!);
    final canStartMinimum = state.canCompleteMinimumAction(task!);
    final buffBonus = state.previewBuffBonusXP(task!);
    final fullDisplayedXp = earnedXp + buffBonus;
    final minimumXp = canStartMinimum ? state.previewMinimumActionXP(task!) : 0;
    final displayedXp = canStartMinimum ? minimumXp : fullDisplayedXp;
    final actionLabel = canStartMinimum ? 'Начать' : 'Выполнить';
    final actionTooltip = canStartMinimum
        ? 'Сделать минимальный шаг и получить частичный XP'
        : 'Закрыть квест полностью и начислить XP';
    final stage = TodayDashboard._stageFor(state, task!);

    return _SoftCard(
      isDark: isDark,
      accent: accent,
      prominent: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: accent, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Следующий квест · первое полезное действие',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              TaskBadge(
                icon: Icons.auto_awesome,
                label: '+$displayedXp XP',
                color: const Color(0xFF4A9EFF),
              ),
              if (buffBonus > 0) ...[
                const SizedBox(width: 6),
                TaskBadge(
                  icon: Icons.bolt,
                  label: 'эффект +$buffBonus',
                  color: const Color(0xFF34C759),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task!.title,
            style: TextStyle(
              color: txt,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (stage != null) ...[
            const SizedBox(height: 5),
            Text(
              'Этап: ${stage.title}',
              style: TextStyle(
                color: sub,
                fontSize: 11.2,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (canStartMinimum) ...[
            const SizedBox(height: 8),
            _MinimumActionHint(
              text: task!.minimumAction,
              color: accent,
              isDark: isDark,
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  canStartMinimum
                      ? 'Сделай самый маленький вход. Полное закрытие останется в списке.'
                      : 'Один маленький квест — и поток запущен.',
                  style: TextStyle(color: sub, fontSize: 11.5, height: 1.25),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              _QuickActionButton(
                task: task!,
                color: accent,
                label: actionLabel,
                tooltip: actionTooltip,
                icon: canStartMinimum ? Icons.play_arrow : Icons.check,
                compact: false,
                primary: true,
                onTrigger: canStartMinimum ? onMinimumAction : onComplete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MinimumActionHint extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const _MinimumActionHint({
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withAlpha(34)),
      ),
      child: Row(
        children: [
          Icon(Icons.play_arrow_rounded, color: color.withAlpha(220), size: 14),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Минимум: $text',
              style: TextStyle(
                color: textColor(isDark).withAlpha(210),
                fontSize: 11.2,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final bool isDark;
  final int todayTasks;
  final int todayXp;
  final int activeQuests;
  final int dailyQuests;

  const _StatsGrid({
    required this.isDark,
    required this.todayTasks,
    required this.todayXp,
    required this.activeQuests,
    required this.dailyQuests,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  isDark: isDark,
                  label: 'Сделано',
                  value: '$todayTasks',
                  icon: Icons.check_circle,
                  color: const Color(0xFF34C759),
                  muted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  isDark: isDark,
                  label: 'XP сегодня',
                  value: '$todayXp',
                  icon: Icons.bolt,
                  color: const Color(0xFFFFCC00),
                  muted: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  isDark: isDark,
                  label: 'Активно',
                  value: '$activeQuests',
                  icon: Icons.list_alt,
                  color: const Color(0xFF4A9EFF),
                  muted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  isDark: isDark,
                  label: 'Повтор.',
                  value: '$dailyQuests',
                  icon: Icons.repeat,
                  color: const Color(0xFFFF9500),
                  muted: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestQueue extends StatelessWidget {
  final AppState state;
  final String title;
  final String subtitle;
  final List<Task> tasks;
  final bool isDark;
  final Function(String id, Offset pos) onComplete;
  final Function(String id, Offset pos) onMinimumAction;

  const _QuestQueue({
    required this.state,
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return _SoftCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: txt,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: sub, fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: MotionFadeSlideSwitcher(
              child: tasks.isEmpty
                  ? Center(
                      key: const ValueKey('quest-queue-empty'),
                      child: Text(
                        'Добавьте один маленький квест',
                        style: TextStyle(color: sub, fontSize: 12),
                      ),
                    )
                  : ListView.separated(
                      key: const ValueKey('quest-queue-list'),
                      padding: EdgeInsets.zero,
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, index) {
                        final task = tasks[index];
                        final skill = state.skills
                            .where((s) => s.id == task.skillId)
                            .firstOrNull;
                        return MotionListItem(
                          key: ValueKey('quest-row-${task.id}'),
                          index: index,
                          slide: 5,
                          child: _QuestMiniRow(
                            task: task,
                            skill: skill,
                            stage: TodayDashboard._stageFor(state, task),
                            xp: state.previewEarnedXP(task),
                            buffBonus: state.previewBuffBonusXP(task),
                            minimumXp: state.previewMinimumActionXP(task),
                            isDark: isDark,
                            onComplete: onComplete,
                            onMinimumAction: onMinimumAction,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestMiniRow extends StatelessWidget {
  final Task task;
  final Skill? skill;
  final SkillTreeNode? stage;
  final int xp;
  final int buffBonus;
  final int minimumXp;
  final bool isDark;
  final Function(String id, Offset pos) onComplete;
  final Function(String id, Offset pos) onMinimumAction;

  const _QuestMiniRow({
    required this.task,
    required this.skill,
    required this.stage,
    required this.xp,
    required this.buffBonus,
    required this.minimumXp,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = skill?.color ?? const Color(0xFF4A9EFF);
    final recommendsMinimum = TodayDashboard._shouldRecommendMinimumAction(
      task,
    );
    final title = recommendsMinimum
        ? 'Минимум: ${task.minimumAction}'
        : task.title;
    final xpText = buffBonus > 0
        ? '+${xp + buffBonus} XP • эффект +$buffBonus'
        : '+$xp XP';
    final subtitle = recommendsMinimum
        ? 'Лёгкий старт • +$minimumXp XP'
        : stage != null
        ? 'Этап: ${stage!.title} • $xpText'
        : task.type == TaskType.repeating
        ? '${typeLabel[task.type]} • $xpText'
        : xpText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withAlpha(26)),
      ),
      child: Row(
        children: [
          Icon(skill?.icon ?? Icons.bolt, color: accent, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: txt,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(color: sub, fontSize: 9.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _QuickActionButton(
            task: task,
            color: accent,
            label: recommendsMinimum ? 'Старт' : 'OK',
            tooltip: recommendsMinimum
                ? 'Сделать лёгкий старт: ${task.minimumAction}'
                : 'Выполнить квест “${task.title}”',
            icon: recommendsMinimum ? Icons.play_arrow : Icons.check,
            compact: true,
            primary: false,
            onTrigger: recommendsMinimum ? onMinimumAction : onComplete,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final Task task;
  final Color color;
  final String label;
  final String tooltip;
  final IconData icon;
  final bool compact;
  final bool primary;
  final Function(String id, Offset pos) onTrigger;

  const _QuickActionButton({
    required this.task,
    required this.color,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.compact,
    this.primary = true,
    required this.onTrigger,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : color;
    return Tooltip(
      message: tooltip,
      child: PressFeedback(
        scale: 0.96,
        onTap: () {
          final box = context.findRenderObject() as RenderBox?;
          onTrigger(task.id, box?.localToGlobal(Offset.zero) ?? Offset.zero);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: primary ? color : color.withAlpha(18),
            borderRadius: BorderRadius.circular(9),
            border: primary ? null : Border.all(color: color.withAlpha(50)),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: color.withAlpha(58),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: compact
              ? Icon(icon, color: fg, size: 15)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: fg, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool muted;

  const _StatTile({
    required this.isDark,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return _SoftCard(
      isDark: isDark,
      accent: muted ? null : color,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color.withAlpha(muted ? 185 : 255), size: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: txt,
                  fontSize: 17,
                  fontWeight: muted ? FontWeight.w800 : FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: sub, fontSize: 10.5),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  final bool expanded;
  final Color color;
  final VoidCallback onTap;

  const _CollapseButton({
    required this.expanded,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: expanded
          ? 'Свернуть блок “Действовать сегодня”'
          : 'Показать блок “Действовать сегодня”',
      child: PressFeedback(
        scale: 0.94,
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(24),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: color,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _TinyProgressLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TinyProgressLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: color.withAlpha(190), fontSize: 10),
            ),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayStatusLabelData {
  final String label;
  final String value;
  final Color color;

  const _TodayStatusLabelData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _TodayStatusRow extends StatelessWidget {
  final List<_TodayStatusLabelData> labels;
  final bool compact;

  const _TodayStatusRow({required this.labels, required this.compact});

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    final visibleLabels = compact ? labels.take(3).toList() : labels;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < visibleLabels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _TinyProgressLabel(
            label: visibleLabels[i].label,
            value: visibleLabels[i].value,
            color: visibleLabels[i].color,
          ),
        ],
      ],
    );
  }
}

class _SoftCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final bool prominent;

  const _SoftCard({
    required this.isDark,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(12),
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? borderColor(isDark);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131A) : const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(
            prominent
                ? 120
                : accent == null
                ? 48
                : 65,
          ),
        ),
        boxShadow: prominent
            ? [
                BoxShadow(
                  color: color.withAlpha(isDark ? 28 : 22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
