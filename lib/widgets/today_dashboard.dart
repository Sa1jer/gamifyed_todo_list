import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'shared.dart';

class TodayDashboard extends StatefulWidget {
  final Function(String id, Offset pos) onComplete;
  final Function(String id, Offset pos) onMinimumAction;

  const TodayDashboard({
    super.key,
    required this.onComplete,
    required this.onMinimumAction,
  });

  static Skill? _skillFor(AppState state, Task task) {
    return state.skills.where((skill) => skill.id == task.skillId).firstOrNull;
  }

  static Task? _pickNextTask(AppState state, List<Task> tasks) {
    final sorted = _sortedTasks(state, tasks);
    if (sorted.isEmpty) return null;
    return sorted.first;
  }

  static List<Task> _sortedTasks(AppState state, List<Task> tasks) {
    final result = [...tasks];
    result.sort((a, b) {
      final byPriority = _priorityScore(
        a.priority,
      ).compareTo(_priorityScore(b.priority));
      if (byPriority != 0) return byPriority;

      final byType = _typeScore(a).compareTo(_typeScore(b));
      if (byType != 0) return byType;

      final byXp = state.previewEarnedXP(b).compareTo(state.previewEarnedXP(a));
      if (byXp != 0) return byXp;

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

  static int _typeScore(Task task) => switch (task.type) {
    TaskType.repeating => task.nextResetAt == null ? 1 : 0,
    TaskType.shortTerm => 2,
    TaskType.midTerm => 3,
    TaskType.longTerm => 4,
  };

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOutCubic,
      height: _expanded ? 242 : 58,
      child: AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFFFCC00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Сегодня',
                          style: TextStyle(
                            color: txt,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Один понятный следующий шаг вместо бесконечного списка',
                          style: TextStyle(color: sub, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_expanded)
                    _TinyProgressLabel(
                      label: 'до уровня',
                      value: '${state.profile.xpNeeded - state.profile.xp} XP',
                      color: const Color(0xFF4A9EFF),
                    ),
                  const SizedBox(width: 8),
                  _CollapseButton(
                    expanded: _expanded,
                    color: sub,
                    onTap: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
              if (_expanded) const SizedBox(height: 8),
              if (_expanded)
                Expanded(
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
                      );

                      if (constraints.maxWidth >= 960) return content;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(width: 960, child: content),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
            title: riskyTasks.isEmpty
                ? 'Фокус на сегодня'
                : 'Стрики под риском',
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

class _NextActionCard extends StatelessWidget {
  final AppState state;
  final Task? task;
  final Skill? skill;
  final bool isDark;
  final Function(String id, Offset pos) onComplete;
  final Function(String id, Offset pos) onMinimumAction;

  const _NextActionCard({
    required this.state,
    required this.task,
    required this.skill,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = skill?.color ?? const Color(0xFF4A9EFF);

    if (task == null) {
      return _SoftCard(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: accent, size: 26),
            const SizedBox(height: 10),
            Text(
              'На сегодня всё чисто',
              style: TextStyle(
                color: txt,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Можно добавить маленький квест или выбрать навык слева.',
              style: TextStyle(color: sub, fontSize: 12, height: 1.25),
            ),
          ],
        ),
      );
    }

    final earnedXp = state.previewEarnedXP(task!);
    final recommendsMinimum =
        state.canCompleteMinimumAction(task!) &&
        TodayDashboard._shouldRecommendMinimumAction(task!);
    final displayedXp = recommendsMinimum
        ? state.previewMinimumActionXP(task!)
        : earnedXp;
    final headline = recommendsMinimum
        ? 'Минимум: ${task!.minimumAction}'
        : task!.title;
    final footer = recommendsMinimum
        ? 'Лёгкий старт к квесту «${task!.title}».'
        : 'Один маленький квест — и поток запущен.';

    return _SoftCard(
      isDark: isDark,
      accent: accent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: accent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Следующий шаг',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
              const SizedBox(width: 6),
              _QuickActionButton(
                task: task!,
                color: accent,
                label: recommendsMinimum ? 'Начать' : 'Выполнить',
                icon: recommendsMinimum ? Icons.play_arrow : Icons.check,
                compact: false,
                onTrigger: recommendsMinimum ? onMinimumAction : onComplete,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            headline,
            style: TextStyle(
              color: txt,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: recommendsMinimum ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (skill != null)
                TaskBadge(icon: skill!.icon, label: skill!.name, color: accent),
              if (recommendsMinimum)
                TaskBadge(
                  icon: Icons.play_circle_fill,
                  label: 'Лёгкий старт',
                  color: accent,
                ),
              TaskBadge(
                label: typeLabel[task!.type]!,
                color: typeColor[task!.type]!,
              ),
              if (task!.priority != Priority.medium)
                TaskBadge(
                  label: priorityLabel[task!.priority]!,
                  color: priorityColor[task!.priority]!,
                ),
            ],
          ),
          const Spacer(),
          Text(
            footer,
            style: TextStyle(color: sub, fontSize: 11, height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  isDark: isDark,
                  label: 'Daily',
                  value: '$dailyQuests',
                  icon: Icons.repeat,
                  color: const Color(0xFFFF9500),
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
          if (tasks.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Нет активных квестов',
                  style: TextStyle(color: sub, fontSize: 12),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, index) {
                  final task = tasks[index];
                  final skill = state.skills
                      .where((s) => s.id == task.skillId)
                      .firstOrNull;
                  return _QuestMiniRow(
                    task: task,
                    skill: skill,
                    xp: state.previewEarnedXP(task),
                    minimumXp: state.previewMinimumActionXP(task),
                    isDark: isDark,
                    onComplete: onComplete,
                    onMinimumAction: onMinimumAction,
                  );
                },
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
  final int xp;
  final int minimumXp;
  final bool isDark;
  final Function(String id, Offset pos) onComplete;
  final Function(String id, Offset pos) onMinimumAction;

  const _QuestMiniRow({
    required this.task,
    required this.skill,
    required this.xp,
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
    final subtitle = recommendsMinimum
        ? 'Лёгкий старт • ${task.title} • +$minimumXp XP'
        : '${typeLabel[task.type]} • +$xp XP';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withAlpha(14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withAlpha(38)),
      ),
      child: Row(
        children: [
          Icon(skill?.icon ?? Icons.bolt, color: accent, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: txt,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: recommendsMinimum ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: sub, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _QuickActionButton(
            task: task,
            color: accent,
            label: recommendsMinimum ? 'Старт' : 'OK',
            icon: recommendsMinimum ? Icons.play_arrow : Icons.check,
            compact: true,
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
  final IconData icon;
  final bool compact;
  final Function(String id, Offset pos) onTrigger;

  const _QuickActionButton({
    required this.task,
    required this.color,
    required this.label,
    required this.icon,
    required this.compact,
    required this.onTrigger,
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      scale: 0.9,
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
          color: color,
          borderRadius: BorderRadius.circular(9),
        ),
        child: compact
            ? Icon(icon, color: Colors.white, size: 15)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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

  const _StatTile({
    required this.isDark,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return _SoftCard(
      isDark: isDark,
      accent: color,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: txt,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
    return PressFeedback(
      scale: 0.86,
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
      child: Row(
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
    );
  }
}

class _SoftCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;

  const _SoftCard({
    required this.isDark,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? borderColor(isDark);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131A) : const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(accent == null ? 55 : 65)),
      ),
      child: child,
    );
  }
}
