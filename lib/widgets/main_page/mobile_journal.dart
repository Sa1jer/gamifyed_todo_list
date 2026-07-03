part of '../main_page.dart';

enum _MobileSkillAction { edit, delete }

abstract final class _MobileJournalTokens {
  static const raisedDark = MobileJournalTokens.raisedDark;
  static const violet = MobileJournalTokens.violet;
  static const amber = MobileJournalTokens.amber;
  static const inbox = MobileJournalTokens.inbox;

  static const radiusLarge = MobileJournalTokens.radiusLarge;
  static const radiusMedium = MobileJournalTokens.radiusMedium;
  static const motion = MobileJournalTokens.motion;
  static const curve = MobileJournalTokens.curve;

  static Color background(bool isDark) =>
      MobileJournalTokens.background(isDark);

  static Color surfaceColor(bool isDark) => MobileJournalTokens.surface(isDark);

  static Color raised(bool isDark) => MobileJournalTokens.raised(isDark);

  static Color outline(bool isDark) => MobileJournalTokens.outline(isDark);

  static Color text(bool isDark) => MobileJournalTokens.text(isDark);

  static Color muted(bool isDark) => MobileJournalTokens.muted(isDark);
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

    return AnimatedSize(
      duration: _motionDuration(context),
      curve: _MobileJournalTokens.curve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: _motionDuration(context),
        switchInCurve: _MobileJournalTokens.curve,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide =
              Tween<Offset>(
                begin: const Offset(0, 0.055),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: _MobileJournalTokens.curve,
                ),
              );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: _MobileJournalTokens.curve,
                  ),
                ),
                child: child,
              ),
            ),
          );
        },
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: selectedSkill == null
            ? _buildOverview(context, state)
            : _buildFocus(context, state, selectedSkill),
      ),
    );
  }

  Widget _buildOverview(BuildContext context, AppState state) {
    final isDark = state.isDark;
    final skills = state.roadmapSkills;
    final inboxCount = state.inboxTasks.where((task) => !task.isDone).length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final skillListHeight = skills.isEmpty
            ? 150.0
            : skills.length * 94.0 + math.max(0, skills.length - 1) * 10.0;
        final inboxContentHeight = _inboxExpanded
            ? (170.0 + inboxCount * 52).clamp(230.0, 430.0)
            : 0.0;
        final fixedHeight =
            84.0 +
            73.0 +
            skillListHeight +
            12.0 +
            76.0 +
            inboxContentHeight +
            12.0;
        final placeholderSlot = constraints.maxHeight.isFinite
            ? math.max(0.0, constraints.maxHeight - fixedHeight - 12.0)
            : 0.0;

        return KeyedSubtree(
          key: const ValueKey('mobile-act-overview'),
          child: CustomScrollView(
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
                  child: _MobileJournalEmptySkills(
                    onCreate: widget.onCreateSkill,
                  ),
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
                      final card = _MobileSkillOverviewCard(
                        skill: skill,
                        activeQuestCount: activeCount,
                        isDark: isDark,
                        reorderIndex: index,
                        onTap: () {
                          if (_inboxExpanded) {
                            setState(() => _inboxExpanded = false);
                          }
                          state.selectSkill(skill.id);
                        },
                        onLongPress: () => _showSkillActions(
                          context,
                          state: state,
                          skill: skill,
                        ),
                        onEdit: () =>
                            _editSkill(context, state: state, skill: skill),
                        onDelete: () => _confirmDeleteSkill(
                          context,
                          state: state,
                          skill: skill,
                        ),
                      );
                      return Padding(
                        key: ValueKey('mobile-skill-overview-${skill.id}'),
                        padding: EdgeInsets.only(
                          bottom: index == skills.length - 1 ? 0 : 10,
                        ),
                        child: KeyedSubtree(
                          key: index == 0 ? widget.nextQuestActionKey : null,
                          child: card,
                        ),
                      );
                    },
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: placeholderSlot >= 108 ? 12 : 0,
                  ),
                  child: _MobileFocusPlaceholder(
                    availableHeight: placeholderSlot,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _MobileInboxAccordion(
                    expanded: _inboxExpanded,
                    taskCount: inboxCount,
                    isDark: isDark,
                    onToggle: () =>
                        setState(() => _inboxExpanded = !_inboxExpanded),
                    onComplete: widget.onComplete,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFocus(BuildContext context, AppState state, Skill skill) {
    return KeyedSubtree(
      key: ValueKey('mobile-act-focus-${skill.id}'),
      child: SingleChildScrollView(
        key: ValueKey('mobile-journal-focus-${skill.id}'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 12),
        child: TasksPanel(
          onComplete: widget.onComplete,
          onMinimumAction: widget.onMinimumAction,
          mobileFocus: true,
          onMobileOverview: () => state.selectSkill(skill.id),
          onMobileDeleteSkill: () =>
              _confirmDeleteSkill(context, state: state, skill: skill),
          createFirstQuestButtonKey: widget.createFirstQuestButtonKey,
        ),
      ),
    );
  }

  Future<void> _showSkillActions(
    BuildContext context, {
    required AppState state,
    required Skill skill,
  }) async {
    AppFeedback.selection();
    final isDark = state.isDark;
    final action = await showModalBottomSheet<_MobileSkillAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          key: ValueKey('mobile-skill-actions-${skill.id}'),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: surface(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  key: ValueKey('mobile-skill-edit-${skill.id}'),
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Редактировать навык'),
                  onTap: () =>
                      Navigator.pop(sheetContext, _MobileSkillAction.edit),
                ),
                ListTile(
                  key: ValueKey('mobile-skill-delete-${skill.id}'),
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFF3B30),
                  ),
                  title: const Text(
                    'Удалить навык',
                    style: TextStyle(color: Color(0xFFFF3B30)),
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, _MobileSkillAction.delete),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == _MobileSkillAction.edit) {
      await _editSkill(context, state: state, skill: skill);
      return;
    }
    await _confirmDeleteSkill(context, state: state, skill: skill);
  }

  Future<void> _editSkill(
    BuildContext context, {
    required AppState state,
    required Skill skill,
  }) {
    final isDark = state.isDark;
    return showAdaptiveCreationForm<void>(
      context: context,
      builder: (_, fullScreen) => AddSkillDialog(
        isDark: isDark,
        fullScreen: fullScreen,
        existing: skill,
        onSave: (name, goal, checklist, color, icon, _, _) => state.updateSkill(
          skill,
          name: name,
          goal: goal,
          checklist: checklist,
          color: color,
          icon: icon,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSkill(
    BuildContext context, {
    required AppState state,
    required Skill skill,
  }) async {
    final isDark = state.isDark;
    final taskCount = state.tasksForSkill(skill.id).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surface(isDark),
        title: Text(
          'Удалить навык «${skill.name}»?',
          style: TextStyle(color: textColor(isDark)),
        ),
        content: Text(
          'Будут удалены уровень и XP навыка, его RoadMap и $taskCount ${_questWord(taskCount)}. Это действие нельзя отменить.',
          style: TextStyle(color: subtext(isDark), height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            key: ValueKey('confirm-delete-skill-${skill.id}'),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить навык'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    AppFeedback.destructive();
    state.removeSkill(skill.id);
  }
}

class _MobileFocusPlaceholder extends StatelessWidget {
  final double availableHeight;

  const _MobileFocusPlaceholder({required this.availableHeight});

  @override
  Widget build(BuildContext context) {
    final isDark = AppStateProvider.of(context).isDark;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final visible = textScale < 1.7 && availableHeight >= 108;
    final slotHeight = visible ? availableHeight : 0.0;
    final large = slotHeight >= 170;
    final cardHeight = math.min(slotHeight, 300.0);
    final duration = _motionDuration(context);

    return AnimatedSize(
      duration: duration,
      curve: _MobileJournalTokens.curve,
      alignment: Alignment.bottomCenter,
      child: AnimatedOpacity(
        duration: duration,
        opacity: visible ? 1 : 0,
        child: visible
            ? SizedBox(
                key: const ValueKey('mobile-focus-placeholder'),
                height: slotHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: double.infinity,
                    height: cardHeight,
                    child: DashedBorderContainer(
                      color: _MobileJournalTokens.outline(isDark),
                      backgroundColor: _MobileJournalTokens.surfaceColor(
                        isDark,
                      ),
                      borderRadius: BorderRadius.circular(
                        _MobileJournalTokens.radiusLarge,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: large ? 20 : 14,
                        ),
                        child: large
                            ? _MobileFocusPlaceholderLarge(isDark: isDark)
                            : _MobileFocusPlaceholderCompact(isDark: isDark),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox(key: ValueKey('mobile-focus-placeholder-hidden')),
      ),
    );
  }
}

class _MobileFocusPlaceholderLarge extends StatelessWidget {
  final bool isDark;

  const _MobileFocusPlaceholderLarge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: _MobileJournalTokens.violet.withAlpha(isDark ? 20 : 14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _MobileJournalTokens.violet.withAlpha(70),
            ),
          ),
          child: const Icon(
            Icons.adjust_rounded,
            color: _MobileJournalTokens.violet,
            size: 28,
          ),
        ),
        const SizedBox(height: 14),
        _MobileFocusPlaceholderCopy(isDark: isDark, centered: true),
      ],
    );
  }
}

class _MobileFocusPlaceholderCompact extends StatelessWidget {
  final bool isDark;

  const _MobileFocusPlaceholderCompact({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _MobileJournalTokens.violet.withAlpha(isDark ? 20 : 14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.adjust_rounded,
            color: _MobileJournalTokens.violet,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(child: _MobileFocusPlaceholderCopy(isDark: isDark)),
      ],
    );
  }
}

class _MobileFocusPlaceholderCopy extends StatelessWidget {
  final bool isDark;
  final bool centered;

  const _MobileFocusPlaceholderCopy({
    required this.isDark,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Выбери навык для фокуса',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: _MobileJournalTokens.text(isDark),
            fontSize: centered ? 16 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Здесь появятся квесты, прогресс и цели',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: _MobileJournalTokens.muted(isDark),
            fontSize: 11.5,
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
  final int reorderIndex;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MobileSkillOverviewCard({
    required this.skill,
    required this.activeQuestCount,
    required this.isDark,
    required this.reorderIndex,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = skill.progress.clamp(0.0, 1.0);
    final progressLabel = '${(progress * 100).round()}%';
    final semanticsProgress = 'Прогресс уровня: $progressLabel';

    ActionPane actions() => ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.44,
      children: [
        SlidableAction(
          onPressed: (_) => onEdit(),
          backgroundColor: const Color(0xFF4A9EFF),
          foregroundColor: Colors.white,
          icon: Icons.edit_rounded,
          label: 'Править',
          borderRadius: BorderRadius.circular(18),
        ),
        SlidableAction(
          onPressed: (_) => onDelete(),
          backgroundColor: const Color(0xFFFF3B30),
          foregroundColor: Colors.white,
          icon: Icons.delete_outline_rounded,
          label: 'Удалить',
          borderRadius: BorderRadius.circular(18),
        ),
      ],
    );

    return Slidable(
      key: ValueKey('mobile-skill-slidable-${skill.id}'),
      startActionPane: actions(),
      endActionPane: actions(),
      child: Semantics(
        button: true,
        label:
            '${skill.name}, уровень ${skill.level}, активных квестов $activeQuestCount',
        value: semanticsProgress,
        hint: 'Долгое нажатие открывает действия с навыком',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onLongPress,
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
                border: Border.all(color: skill.color.withAlpha(62)),
              ),
              child: Row(
                children: [
                  _MobileGoalRing(
                    value: progress,
                    empty: false,
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        progressLabel,
                        key: ValueKey('mobile-skill-progress-${skill.id}'),
                        style: TextStyle(
                          color: skill.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      ReorderableDelayedDragStartListener(
                        key: ValueKey('compact-skill-reorder-${skill.id}'),
                        index: reorderIndex,
                        child: Tooltip(
                          message: 'Переместить навык',
                          child: SizedBox.square(
                            dimension: 44,
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: _MobileJournalTokens.muted(isDark),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
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
