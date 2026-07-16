import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../presentation/today_dashboard_view_data.dart';
import '../utils.dart';
import 'shared.dart';
import 'today_dashboard_sections.dart';

class TodayDashboard extends StatefulWidget {
  final void Function(String id, ActionToastOrigin origin) onComplete;
  final void Function(String id, ActionToastOrigin origin) onMinimumAction;
  final VoidCallback? onCreateFirstSkill;
  final Key? createFirstSkillButtonKey;
  final Key? nextQuestActionKey;
  final bool initiallyExpanded;
  final bool compactSummary;
  final bool mobileJournal;
  final bool hideEmptyWhenSkillsExist;

  const TodayDashboard({
    super.key,
    required this.onComplete,
    required this.onMinimumAction,
    this.onCreateFirstSkill,
    this.createFirstSkillButtonKey,
    this.nextQuestActionKey,
    this.initiallyExpanded = true,
    this.compactSummary = false,
    this.mobileJournal = false,
    this.hideEmptyWhenSkillsExist = false,
  });

  static bool _isActiveStageTask(AppState state, Task task) {
    final skill = todayDashboardSkillFor(state, task);
    final stage = todayDashboardStageFor(state, task);
    return skill != null &&
        stage != null &&
        skill.treeNodeStatus(stage) == SkillTreeNodeStatus.active;
  }

  @override
  State<TodayDashboard> createState() => _TodayDashboardState();
}

class _TodayDashboardState extends State<TodayDashboard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return AppStateSelector<
      ({int revision, String? selectedSkillId, bool isDark})
    >(
      selector: (state) => (
        revision: state.coreWorkspaceRevision,
        selectedSkillId: state.selectedSkillId,
        isDark: state.isDark,
      ),
      builder: (context, _, _) =>
          _buildDashboard(context, AppStateProvider.read(context)),
    );
  }

  Widget _buildDashboard(BuildContext context, AppState state) {
    final isDark = state.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final stats = state.todayStats;
    final viewData = const TodayDashboardViewDataBuilder().build(
      tasks: state.tasks,
      now: DateTime.now(),
      completedToday: stats?.tasksCompleted ?? 0,
      xpToday: stats?.xpEarned ?? 0,
      previewEarnedXp: state.previewEarnedXP,
      isActiveStageTask: (task) =>
          TodayDashboard._isActiveStageTask(state, task),
    );
    final tasksById = <String, Task>{
      for (final task in state.tasks) task.id: task,
    };
    List<Task> resolveTasks(List<String> ids) => ids
        .map((id) => tasksById[id])
        .whereType<Task>()
        .toList(growable: false);
    final activeTasks = resolveTasks(viewData.activeTaskIds);
    final dailyTasks = resolveTasks(viewData.dailyTaskIds);
    final riskyTasks = resolveTasks(viewData.riskyTaskIds);
    final focusTasks = resolveTasks(viewData.focusTaskIds);
    final nextTask = tasksById[viewData.nextTaskId];
    final statusLabels = _todayStatusLabels();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactDashboard = constraints.maxWidth < 720;
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
        final mobileSummary = _MobileNextActionSummary(
          state: state,
          task: nextTask,
          skill: nextTask == null
              ? null
              : todayDashboardSkillFor(state, nextTask),
          isDark: isDark,
          onComplete: widget.onComplete,
          onMinimumAction: widget.onMinimumAction,
          onCreateFirstSkill: widget.onCreateFirstSkill,
          createFirstSkillButtonKey: widget.createFirstSkillButtonKey,
          nextQuestActionKey: widget.nextQuestActionKey,
        );

        if (widget.compactSummary && !_expanded) {
          if (nextTask == null &&
              widget.hideEmptyWhenSkillsExist &&
              state.roadmapSkills.isNotEmpty) {
            return const SizedBox.shrink(
              key: ValueKey('mobile-next-action-hidden-empty'),
            );
          }
          final summaryContent = Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            child: largeText
                ? mobileSummary
                : Row(
                    children: [
                      Expanded(child: mobileSummary),
                      const SizedBox(width: 2),
                      TodayDashboardCollapseButton(
                        expanded: false,
                        color: sub,
                        onTap: () => setState(() => _expanded = true),
                      ),
                    ],
                  ),
          );
          return AnimatedContainer(
            key: const ValueKey('mobile-next-action-surface'),
            duration: kMotionSlow,
            curve: kMotionCurve,
            height: largeText ? 180 : (widget.mobileJournal ? 72 : 80),
            decoration: widget.mobileJournal
                ? BoxDecoration(
                    color: surface(isDark),
                    borderRadius: BorderRadius.circular(18),
                  )
                : null,
            child: widget.mobileJournal
                ? summaryContent
                : AppPanel(isDark: isDark, child: summaryContent),
          );
        }

        return AnimatedContainer(
          duration: kMotionSlow,
          curve: kMotionCurve,
          height: _expanded ? (compactDashboard ? 248 : 258) : 76,
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
                                : 'Сначала следующий квест. Статистика и трофеи живут отдельно.',
                            style: TextStyle(color: sub, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                      final statusRow = TodayStatusRow(
                        labels: statusLabels,
                        compact: !_expanded,
                      );

                      if (statusLabels.isEmpty) {
                        return SizedBox(
                          width: constraints.maxWidth,
                          height: 52,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFFFCC00),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: titleBlock),
                              const SizedBox(width: 8),
                              TodayDashboardCollapseButton(
                                expanded: _expanded,
                                color: sub,
                                onTap: () =>
                                    setState(() => _expanded = !_expanded),
                              ),
                            ],
                          ),
                        );
                      }

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
                                  TodayDashboardCollapseButton(
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
                                      focusTasks: focusTasks,
                                      activeTasks: activeTasks,
                                      dailyTasks: dailyTasks,
                                      todayTasks: viewData.completedToday,
                                      todayXp: viewData.xpToday,
                                      isDark: isDark,
                                      onComplete: widget.onComplete,
                                      onMinimumAction: widget.onMinimumAction,
                                      onCreateFirstSkill:
                                          widget.onCreateFirstSkill,
                                      createFirstSkillButtonKey:
                                          widget.createFirstSkillButtonKey,
                                      nextQuestActionKey:
                                          widget.nextQuestActionKey,
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
                                        createFirstSkillButtonKey:
                                            widget.createFirstSkillButtonKey,
                                        nextQuestActionKey:
                                            widget.nextQuestActionKey,
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

  List<TodayStatusLabelData> _todayStatusLabels() => const [];
}

class _DashboardContent extends StatelessWidget {
  final AppState state;
  final Task? nextTask;
  final List<Task> riskyTasks;
  final List<Task> focusTasks;
  final List<Task> activeTasks;
  final List<Task> dailyTasks;
  final int todayTasks;
  final int todayXp;
  final bool isDark;
  final void Function(String id, ActionToastOrigin origin) onComplete;
  final void Function(String id, ActionToastOrigin origin) onMinimumAction;
  final VoidCallback? onCreateFirstSkill;
  final Key? createFirstSkillButtonKey;
  final Key? nextQuestActionKey;

  const _DashboardContent({
    required this.state,
    required this.nextTask,
    required this.riskyTasks,
    required this.focusTasks,
    required this.activeTasks,
    required this.dailyTasks,
    required this.todayTasks,
    required this.todayXp,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
    required this.onCreateFirstSkill,
    required this.createFirstSkillButtonKey,
    required this.nextQuestActionKey,
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
                : todayDashboardSkillFor(state, nextTask!),
            isDark: isDark,
            onComplete: onComplete,
            onMinimumAction: onMinimumAction,
            onCreateFirstSkill: onCreateFirstSkill,
            createFirstSkillButtonKey: createFirstSkillButtonKey,
            nextQuestActionKey: nextQuestActionKey,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: TodayStatsGrid(
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
          child: TodayQuestQueue(
            state: state,
            title: riskyTasks.isEmpty ? 'Фокус на сегодня' : 'Серии под риском',
            subtitle: riskyTasks.isEmpty
                ? 'Начни с малого — поток придёт после первого действия'
                : 'Эти квесты лучше закрыть первыми',
            tasks: riskyTasks.isEmpty
                ? focusTasks
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
  final void Function(String id, ActionToastOrigin origin) onComplete;
  final void Function(String id, ActionToastOrigin origin) onMinimumAction;
  final VoidCallback? onCreateFirstSkill;
  final Key? createFirstSkillButtonKey;
  final Key? nextQuestActionKey;

  const _CompactDashboardContent({
    required this.state,
    required this.nextTask,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
    required this.onCreateFirstSkill,
    required this.createFirstSkillButtonKey,
    required this.nextQuestActionKey,
  });

  @override
  Widget build(BuildContext context) {
    return _NextActionCard(
      state: state,
      task: nextTask,
      skill: nextTask == null ? null : todayDashboardSkillFor(state, nextTask!),
      isDark: isDark,
      onComplete: onComplete,
      onMinimumAction: onMinimumAction,
      onCreateFirstSkill: onCreateFirstSkill,
      createFirstSkillButtonKey: createFirstSkillButtonKey,
      nextQuestActionKey: nextQuestActionKey,
    );
  }
}

class _MobileNextActionSummary extends StatelessWidget {
  final AppState state;
  final Task? task;
  final Skill? skill;
  final bool isDark;
  final void Function(String id, ActionToastOrigin origin) onComplete;
  final void Function(String id, ActionToastOrigin origin) onMinimumAction;
  final VoidCallback? onCreateFirstSkill;
  final Key? createFirstSkillButtonKey;
  final Key? nextQuestActionKey;

  const _MobileNextActionSummary({
    required this.state,
    required this.task,
    required this.skill,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
    required this.onCreateFirstSkill,
    required this.createFirstSkillButtonKey,
    required this.nextQuestActionKey,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final currentTask = task;
    final accent = skill?.color ?? const Color(0xFF4A9EFF);

    if (currentTask == null) {
      final hasSkills = state.roadmapSkills.isNotEmpty;
      return Semantics(
        key: const ValueKey('mobile-next-action-summary'),
        container: true,
        label: hasSkills
            ? 'Нет активных квестов. Выберите навык и добавьте квест.'
            : 'Нет навыков. Создайте первый навык.',
        child: Row(
          children: [
            Icon(
              hasSkills ? Icons.add_task_rounded : Icons.explore_rounded,
              color: accent,
              size: 22,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                hasSkills
                    ? 'Выбери навык и добавь квест, чтобы начать движение.'
                    : 'Создай первый навык — затем добавим небольшой квест.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: txt,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!hasSkills && onCreateFirstSkill != null) ...[
              const SizedBox(width: 8),
              _MobileSummaryButton(
                key: createFirstSkillButtonKey,
                label: 'Создать',
                icon: Icons.add_rounded,
                color: accent,
                semanticsLabel: 'Создать первый навык',
                onTap: onCreateFirstSkill!,
              ),
            ],
          ],
        ),
      );
    }

    final canStartMinimum = state.canCompleteMinimumAction(currentTask);
    final actionText = canStartMinimum
        ? currentTask.minimumAction
        : currentTask.title;
    final actionLabel = canStartMinimum ? 'Минимальный шаг' : 'Следующий квест';
    final trigger = canStartMinimum ? onMinimumAction : onComplete;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;

    Widget actionButton() {
      final controlKey = GlobalKey(
        debugLabel: 'mobile-next-action-control-${currentTask.id}',
      );
      return KeyedSubtree(
        key: nextQuestActionKey,
        child: _MobileSummaryButton(
          key: ValueKey('mobile-next-action-trigger-${currentTask.id}'),
          controlKey: controlKey,
          label: canStartMinimum ? 'Начать' : 'Готово',
          icon: canStartMinimum
              ? Icons.play_arrow_rounded
              : Icons.check_rounded,
          color: accent,
          semanticsLabel: canStartMinimum
              ? 'Начать минимальный шаг: $actionText'
              : 'Выполнить квест: ${currentTask.title}',
          onTap: () {
            final controlContext = controlKey.currentContext;
            trigger(
              currentTask.id,
              actionToastOriginForContext(
                controlContext ?? context,
                kind: canStartMinimum
                    ? ActionToastOriginKind.minimumAction
                    : ActionToastOriginKind.focusTask,
                zone: ActionToastZone.mobileContent,
                sourceId: currentTask.id,
              ),
            );
          },
        ),
      );
    }

    if (largeText) {
      return Semantics(
        key: const ValueKey('mobile-next-action-summary'),
        container: true,
        label: '$actionLabel. $actionText',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canStartMinimum
                      ? Icons.play_arrow_rounded
                      : Icons.flag_rounded,
                  color: accent,
                  size: 20,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Сейчас · $actionLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              actionText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: txt,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            SizedBox(width: double.infinity, child: actionButton()),
          ],
        ),
      );
    }

    return Semantics(
      key: const ValueKey('mobile-next-action-summary'),
      container: true,
      label: '$actionLabel. $actionText',
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withAlpha(isDark ? 34 : 22),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              canStartMinimum ? Icons.play_arrow_rounded : Icons.flag_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сейчас · $actionLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        actionText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: txt,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (skill != null) ...[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: Text(
                          skill!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          actionButton(),
        ],
      ),
    );
  }
}

class _MobileSummaryButton extends StatelessWidget {
  final GlobalKey? controlKey;
  final String label;
  final IconData icon;
  final Color color;
  final String semanticsLabel;
  final VoidCallback onTap;

  const _MobileSummaryButton({
    super.key,
    this.controlKey,
    required this.label,
    required this.icon,
    required this.color,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: PressFeedback(
        scale: 0.96,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 76),
          child: DecoratedBox(
            key: controlKey,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextActionCard extends StatelessWidget {
  final AppState state;
  final Task? task;
  final Skill? skill;
  final bool isDark;
  final void Function(String id, ActionToastOrigin origin) onComplete;
  final void Function(String id, ActionToastOrigin origin) onMinimumAction;
  final VoidCallback? onCreateFirstSkill;
  final Key? createFirstSkillButtonKey;
  final Key? nextQuestActionKey;

  const _NextActionCard({
    required this.state,
    required this.task,
    required this.skill,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
    required this.onCreateFirstSkill,
    required this.createFirstSkillButtonKey,
    required this.nextQuestActionKey,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = skill?.color ?? const Color(0xFF4A9EFF);
    final compact = MediaQuery.sizeOf(context).width < 600;

    if (task == null) {
      final hasSkills = state.roadmapSkills.isNotEmpty;
      final isFreshStart = !hasSkills && state.tasks.isEmpty;
      return TodaySoftCard(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFreshStart)
              Row(
                children: [
                  Icon(Icons.check_circle, color: accent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Начните с первого навыка',
                      style: TextStyle(
                        color: txt,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else ...[
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
            ],
            const SizedBox(height: 4),
            if (isFreshStart) ...[
              Text(
                'Сначала направление роста, затем первый квест.',
                style: TextStyle(
                  color: accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
            ],
            Text(
              hasSkills
                  ? 'Добавьте один маленький квест или минимальный шаг.'
                  : 'Создайте навык: первый этап появится сразу, а квест добавим следующим шагом.',
              style: TextStyle(color: sub, fontSize: 12, height: 1.25),
              maxLines: isFreshStart ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!hasSkills && onCreateFirstSkill != null) ...[
              const SizedBox(height: 12),
              SmallBtn(
                key: createFirstSkillButtonKey,
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
    final stage = todayDashboardStageFor(state, task!);

    return TodaySoftCard(
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
              if (!compact && buffBonus > 0) ...[
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
          TaskTitleWithDescription(
            task: task!,
            maxLines: compact ? 2 : (canStartMinimum ? 1 : 2),
            titleStyle: TextStyle(
              color: txt,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
            descriptionColor: sub,
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
          if (compact)
            Align(
              alignment: Alignment.centerRight,
              child: TodayQuickActionButton(
                key: nextQuestActionKey,
                task: task!,
                color: accent,
                label: actionLabel,
                tooltip: actionTooltip,
                icon: canStartMinimum ? Icons.play_arrow : Icons.check,
                compact: false,
                primary: true,
                zone: compact
                    ? ActionToastZone.mobileContent
                    : ActionToastZone.mainWorkspace,
                originKind: canStartMinimum
                    ? ActionToastOriginKind.minimumAction
                    : ActionToastOriginKind.questCheckbox,
                onTrigger: canStartMinimum ? onMinimumAction : onComplete,
              ),
            )
          else
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
                TodayQuickActionButton(
                  key: nextQuestActionKey,
                  task: task!,
                  color: accent,
                  label: actionLabel,
                  tooltip: actionTooltip,
                  icon: canStartMinimum ? Icons.play_arrow : Icons.check,
                  compact: false,
                  primary: true,
                  originKind: canStartMinimum
                      ? ActionToastOriginKind.minimumAction
                      : ActionToastOriginKind.questCheckbox,
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
    return Semantics(
      label: 'Минимальный шаг: $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withAlpha(34)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: color.withAlpha(220),
              size: 14,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Начни с этого: $text',
                style: TextStyle(
                  color: textColor(isDark).withAlpha(210),
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
