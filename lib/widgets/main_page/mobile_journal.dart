part of '../main_page.dart';

abstract final class _MobileJournalTokens {
  static const backgroundDark = Color(0xFF090A11);
  static const surfaceDark = Color(0xFF12131D);
  static const raisedDark = Color(0xFF171925);
  static const outlineDark = Color(0xFF2B2D3B);
  static const textDark = Color(0xFFF5F2FA);
  static const mutedDark = Color(0xFF9895A7);
  static const violet = Color(0xFF7562FF);
  static const amber = Color(0xFFFF8A1F);
  static const inbox = Color(0xFF35C76F);

  static const radiusLarge = 24.0;
  static const radiusMedium = 18.0;
  static const motion = Duration(milliseconds: 220);
  static const curve = Curves.easeOutCubic;

  static Color background(bool isDark) =>
      isDark ? backgroundDark : const Color(0xFFF5F1E8);

  static Color surfaceColor(bool isDark) =>
      isDark ? surfaceDark : const Color(0xFFFFFCF6);

  static Color raised(bool isDark) =>
      isDark ? raisedDark : const Color(0xFFF2EEE6);

  static Color outline(bool isDark) =>
      isDark ? outlineDark : const Color(0xFFD9D3C8);

  static Color text(bool isDark) => isDark ? textDark : const Color(0xFF17151C);

  static Color muted(bool isDark) =>
      isDark ? mutedDark : const Color(0xFF68636F);
}

class _MobileActJournal extends StatefulWidget {
  final void Function(String taskId, Offset position) onComplete;
  final void Function(String taskId, Offset position) onMinimumAction;
  final VoidCallback onCreateSkill;
  final Key? createFirstSkillButtonKey;
  final Key? createFirstQuestButtonKey;
  final Key? nextQuestActionKey;

  const _MobileActJournal({
    required this.onComplete,
    required this.onMinimumAction,
    required this.onCreateSkill,
    this.createFirstSkillButtonKey,
    this.createFirstQuestButtonKey,
    this.nextQuestActionKey,
  });

  @override
  State<_MobileActJournal> createState() => _MobileActJournalState();
}

class _MobileActJournalState extends State<_MobileActJournal> {
  bool _inboxExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final selected = state.selectedSkill;
    final selectedSkill = selected?.id == kInboxSkillId ? null : selected;

    if (selected?.id == kInboxSkillId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && state.selectedSkillId == kInboxSkillId) {
          state.selectSkill(kInboxSkillId);
        }
      });
    }

    return AnimatedSwitcher(
      duration: _motionDuration(context),
      switchInCurve: _MobileJournalTokens.curve,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: selectedSkill == null
          ? _buildOverview(context, state)
          : _buildFocus(context, state, selectedSkill),
    );
  }

  Widget _buildOverview(BuildContext context, AppState state) {
    final isDark = state.isDark;
    final skills = state.roadmapSkills;
    final inboxCount = state.inboxTasks.where((task) => !task.isDone).length;

    return CustomScrollView(
      key: const ValueKey('mobile-skill-panel-compact'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: _MobileMomentumRow(state: state)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Навыки',
                    style: TextStyle(
                      color: _MobileJournalTokens.text(isDark),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                KeyedSubtree(
                  key: widget.createFirstSkillButtonKey,
                  child: IconButton.filled(
                    key: const ValueKey('mobile-add-skill-open'),
                    tooltip: 'Создать навык',
                    onPressed: widget.onCreateSkill,
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(48),
                      backgroundColor: _MobileJournalTokens.violet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (skills.isEmpty)
          SliverToBoxAdapter(
            child: _MobileJournalEmptySkills(onCreate: widget.onCreateSkill),
          )
        else
          SliverToBoxAdapter(
            child: ReorderableListView.builder(
              key: const ValueKey('mobile-skill-overview-list'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: skills.length,
              onReorderItem: state.reorderSkills,
              itemBuilder: (context, index) {
                final skill = skills[index];
                final activeCount = state
                    .tasksForSkill(skill.id)
                    .where((task) => !task.isDone)
                    .length;
                return Padding(
                  key: ValueKey('mobile-skill-overview-${skill.id}'),
                  padding: EdgeInsets.only(
                    bottom: index == skills.length - 1 ? 0 : 10,
                  ),
                  child: ReorderableDelayedDragStartListener(
                    key: ValueKey('compact-skill-reorder-${skill.id}'),
                    index: index,
                    child: _MobileSkillOverviewCard(
                      skill: skill,
                      activeQuestCount: activeCount,
                      isDark: isDark,
                      onTap: () {
                        if (_inboxExpanded) {
                          setState(() => _inboxExpanded = false);
                        }
                        state.selectSkill(skill.id);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _MobileInboxAccordion(
              expanded: _inboxExpanded,
              taskCount: inboxCount,
              isDark: isDark,
              onToggle: () => setState(() => _inboxExpanded = !_inboxExpanded),
              onComplete: widget.onComplete,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TodayDashboard(
              initiallyExpanded: false,
              compactSummary: true,
              mobileJournal: true,
              hideEmptyWhenSkillsExist: true,
              onComplete: widget.onComplete,
              onMinimumAction: widget.onMinimumAction,
              onCreateFirstSkill: widget.onCreateSkill,
              nextQuestActionKey: widget.nextQuestActionKey,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
      ],
    );
  }

  Widget _buildFocus(BuildContext context, AppState state, Skill skill) {
    return Column(
      key: ValueKey('mobile-journal-focus-${skill.id}'),
      children: [
        _MobileFocusSwitcher(
          state: state,
          selectedSkill: skill,
          onOverview: () => state.selectSkill(skill.id),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TasksPanel(
            onComplete: widget.onComplete,
            onMinimumAction: widget.onMinimumAction,
            mobileFocus: true,
            createFirstQuestButtonKey: widget.createFirstQuestButtonKey,
          ),
        ),
      ],
    );
  }
}

class _MobileMomentumRow extends StatelessWidget {
  final AppState state;

  const _MobileMomentumRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final stats = state.todayStats;
    final streak = state.tasks
        .where((task) => task.type == TaskType.repeating && task.streak > 0)
        .fold<int>(0, (current, task) => math.max(current, task.streak));
    final cards = <Widget>[
      _MobileMomentumCard(
        key: const ValueKey('mobile-momentum-xp'),
        icon: Icons.bolt_rounded,
        value: '+${stats?.xpEarned ?? 0}',
        label: 'XP сегодня',
        color: _MobileJournalTokens.amber,
        isDark: state.isDark,
      ),
      _MobileMomentumCard(
        key: const ValueKey('mobile-momentum-completed'),
        icon: Icons.task_alt_rounded,
        value: '${stats?.tasksCompleted ?? 0}',
        label: 'Закрыто сегодня',
        color: _MobileJournalTokens.violet,
        isDark: state.isDark,
      ),
      if (streak > 0)
        _MobileMomentumCard(
          key: const ValueKey('mobile-momentum-streak'),
          icon: Icons.local_fire_department_rounded,
          value: '$streak дн.',
          label: 'Серия',
          color: const Color(0xFFFF5C45),
          isDark: state.isDark,
        ),
    ];

    return Row(
      key: const ValueKey('mobile-momentum-row'),
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          Expanded(child: cards[index]),
          if (index != cards.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _MobileMomentumCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _MobileMomentumCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 13 : 10),
        borderRadius: BorderRadius.circular(_MobileJournalTokens.radiusMedium),
        border: Border.all(color: color.withAlpha(isDark ? 46 : 55)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: _MobileJournalTokens.text(isDark),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _MobileJournalTokens.muted(isDark),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSkillOverviewCard extends StatelessWidget {
  final Skill skill;
  final int activeQuestCount;
  final bool isDark;
  final VoidCallback onTap;

  const _MobileSkillOverviewCard({
    required this.skill,
    required this.activeQuestCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = const GoalProgressEngine().snapshotForSkill(skill);
    final progressLabel = progress.isEmpty ? 'Нет пути' : progress.percentLabel;
    final semanticsProgress = progress.isEmpty
        ? 'Прогресс цели: путь не задан'
        : 'Прогресс цели: ${progress.percentLabel}';

    return Semantics(
      button: true,
      label:
          '${skill.name}, уровень ${skill.level}, активных квестов $activeQuestCount',
      value: semanticsProgress,
      child: PressFeedback(
        scale: 0.985,
        onTap: onTap,
        child: Container(
          key: ValueKey('mobile-skill-chip-${skill.id}'),
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: _MobileJournalTokens.surfaceColor(isDark),
            borderRadius: BorderRadius.circular(
              _MobileJournalTokens.radiusLarge,
            ),
            border: Border.all(
              color: skill.color.withAlpha(progress.isEmpty ? 30 : 62),
            ),
          ),
          child: Row(
            children: [
              _MobileGoalRing(
                value: progress.value,
                empty: progress.isEmpty,
                color: skill.color,
                icon: skill.icon,
                semanticsLabel: semanticsProgress,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _MobileJournalTokens.text(isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Ур. ${skill.level} · $activeQuestCount ${_questWord(activeQuestCount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _MobileJournalTokens.muted(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (skill.goal.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        skill.goal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _MobileJournalTokens.muted(isDark),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                progressLabel,
                key: ValueKey('mobile-skill-progress-${skill.id}'),
                style: TextStyle(
                  color: progress.isEmpty
                      ? _MobileJournalTokens.muted(isDark)
                      : skill.color,
                  fontSize: progress.isEmpty ? 10.5 : 13,
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

class _MobileGoalRing extends StatelessWidget {
  final double value;
  final bool empty;
  final Color color;
  final IconData icon;
  final String semanticsLabel;

  const _MobileGoalRing({
    required this.value,
    required this.empty,
    required this.color,
    required this.icon,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: semanticsLabel,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value),
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 360),
        curve: _MobileJournalTokens.curve,
        builder: (context, animatedValue, child) => CustomPaint(
          painter: _MobileGoalRingPainter(
            value: animatedValue,
            color: color,
            empty: empty,
          ),
          child: child,
        ),
        child: SizedBox.square(
          dimension: 62,
          child: Center(
            child: Icon(
              icon,
              color: empty ? color.withAlpha(145) : color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileGoalRingPainter extends CustomPainter {
  final double value;
  final Color color;
  final bool empty;

  const _MobileGoalRingPainter({
    required this.value,
    required this.color,
    required this.empty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = 5.0;
    final ring = rect.deflate(stroke / 2);
    canvas.drawArc(
      ring,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = color.withAlpha(empty ? 30 : 36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (!empty && value > 0) {
      canvas.drawArc(
        ring,
        -math.pi / 2,
        math.pi * 2 * value.clamp(0, 1),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MobileGoalRingPainter oldDelegate) =>
      value != oldDelegate.value ||
      color != oldDelegate.color ||
      empty != oldDelegate.empty;
}

class _MobileFocusSwitcher extends StatelessWidget {
  final AppState state;
  final Skill selectedSkill;
  final VoidCallback onOverview;

  const _MobileFocusSwitcher({
    required this.state,
    required this.selectedSkill,
    required this.onOverview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDark;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    return SizedBox(
      key: const ValueKey('mobile-focus-switcher'),
      height: largeText ? 70 : 50,
      child: Row(
        children: [
          OutlinedButton.icon(
            key: const ValueKey('mobile-overview-action'),
            onPressed: onOverview,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 46),
              foregroundColor: _MobileJournalTokens.text(isDark),
              side: BorderSide(color: _MobileJournalTokens.outline(isDark)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.grid_view_rounded, size: 17),
            label: const Text('Обзор'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.roadmapSkills.length,
              separatorBuilder: (_, _) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final skill = state.roadmapSkills[index];
                final selected = skill.id == selectedSkill.id;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: 'Открыть навык ${skill.name}',
                  child: ActionChip(
                    key: ValueKey('mobile-focus-skill-${skill.id}'),
                    onPressed: selected
                        ? () {}
                        : () => state.selectSkill(skill.id),
                    avatar: Icon(skill.icon, size: 16, color: skill.color),
                    label: Text(skill.name, overflow: TextOverflow.ellipsis),
                    labelStyle: TextStyle(
                      color: selected
                          ? skill.color
                          : _MobileJournalTokens.text(isDark),
                      fontWeight: FontWeight.w800,
                    ),
                    backgroundColor: selected
                        ? skill.color.withAlpha(isDark ? 26 : 16)
                        : _MobileJournalTokens.raised(isDark),
                    side: BorderSide(
                      color: selected
                          ? skill.color.withAlpha(100)
                          : _MobileJournalTokens.outline(isDark),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileInboxAccordion extends StatelessWidget {
  final bool expanded;
  final int taskCount;
  final bool isDark;
  final VoidCallback onToggle;
  final void Function(String taskId, Offset position) onComplete;

  const _MobileInboxAccordion({
    required this.expanded,
    required this.taskCount,
    required this.isDark,
    required this.onToggle,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final duration = _motionDuration(context);
    final taskHeight = (170.0 + taskCount * 52).clamp(230.0, 430.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_MobileJournalTokens.radiusLarge),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _MobileJournalTokens.inbox.withAlpha(isDark ? 14 : 9),
              _MobileJournalTokens.surfaceColor(isDark),
            ],
          ),
          border: Border.all(
            color: _MobileJournalTokens.inbox.withAlpha(isDark ? 48 : 60),
          ),
          borderRadius: BorderRadius.circular(_MobileJournalTokens.radiusLarge),
        ),
        child: Column(
          children: [
            Semantics(
              button: true,
              expanded: expanded,
              label: 'Задачник, быстрых задач $taskCount',
              child: InkWell(
                key: const ValueKey('mobile-inbox-accordion-toggle'),
                onTap: onToggle,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 76),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _MobileJournalTokens.inbox.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.inbox_rounded,
                            color: _MobileJournalTokens.inbox,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Задачник',
                                style: TextStyle(
                                  color: _MobileJournalTokens.text(isDark),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Быстрые дела без дорожной карты',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _MobileJournalTokens.muted(isDark),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InboxTaskCountBubble(
                          count: taskCount,
                          color: _MobileJournalTokens.inbox,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          duration: duration,
                          turns: expanded ? 0.5 : 0,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _MobileJournalTokens.muted(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: duration,
              curve: _MobileJournalTokens.curve,
              alignment: Alignment.topCenter,
              child: expanded
                  ? SizedBox(
                      key: const ValueKey('mobile-inbox-accordion-content'),
                      height: taskHeight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: InboxPanel(
                          onComplete: onComplete,
                          embedded: true,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileJournalEmptySkills extends StatelessWidget {
  final VoidCallback onCreate;

  const _MobileJournalEmptySkills({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final isDark = AppStateProvider.of(context).isDark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _MobileJournalTokens.surfaceColor(isDark),
        borderRadius: BorderRadius.circular(_MobileJournalTokens.radiusLarge),
        border: Border.all(color: _MobileJournalTokens.outline(isDark)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.explore_outlined,
            color: _MobileJournalTokens.violet,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            'Создай первый навык',
            style: TextStyle(
              color: _MobileJournalTokens.text(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Один ясный путь лучше десятка забытых планов.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _MobileJournalTokens.muted(isDark)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: _MobileJournalTokens.violet,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Создать навык'),
          ),
        ],
      ),
    );
  }
}

Duration _motionDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : _MobileJournalTokens.motion;

String _questWord(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return 'квест';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'квеста';
  }
  return 'квестов';
}
