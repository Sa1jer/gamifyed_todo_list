part of '../main_page.dart';

enum _DesktopTaskMenuAction { edit, archive, restore, delete }

class _DesktopWorkspaceShell extends StatelessWidget {
  final AppState state;
  final WorkspaceMode mode;
  final DesktopResponsiveMetrics metrics;
  final ValueChanged<WorkspaceMode> onModeChanged;
  final VoidCallback onAddSkill;
  final VoidCallback onOpenRewards;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenProfile;
  final VoidCallback? onDebugAppTap;
  final ValueChanged<Skill> onOpenRoadmap;
  final void Function(String taskId, ActionToastOrigin origin) onComplete;
  final void Function(String taskId, ActionToastOrigin origin) onMinimumAction;
  final Widget? alternateWorkspace;
  final GlobalKey? profileKey;
  final GlobalKey? rewardsKey;
  final GlobalKey? roadmapKey;
  final GlobalKey? statsKey;
  final GlobalKey? contextualToastHostKey;
  final GlobalKey? rightRailKey;

  const _DesktopWorkspaceShell({
    required this.state,
    required this.mode,
    required this.metrics,
    required this.onModeChanged,
    required this.onAddSkill,
    required this.onOpenRewards,
    required this.onOpenStatistics,
    required this.onOpenSettings,
    required this.onOpenProfile,
    this.onDebugAppTap,
    required this.onOpenRoadmap,
    required this.onComplete,
    required this.onMinimumAction,
    this.alternateWorkspace,
    this.profileKey,
    this.rewardsKey,
    this.roadmapKey,
    this.statsKey,
    this.contextualToastHostKey,
    this.rightRailKey,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesktopJournalTokens.resolve(state.isDark);
    final selected = state.selectedSkill;
    final actMode = mode == WorkspaceMode.act;
    final effectiveSkill = mode == WorkspaceMode.mastery
        ? selected?.id == kInboxSkillId
              ? null
              : selected
        : selected ?? state.roadmapSkills.firstOrNull;

    return ColoredBox(
      key: const ValueKey('desktop-three-panel-shell'),
      color: tokens.background,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const ValueKey('desktop-sidebar-region'),
              width: metrics.sidebarWidth,
              child: _DesktopSidebar(
                state: state,
                tokens: tokens,
                mode: mode,
                effectiveSkill: effectiveSkill,
                onModeChanged: onModeChanged,
                onAddSkill: onAddSkill,
                onOpenRewards: onOpenRewards,
                onOpenStatistics: onOpenStatistics,
                onOpenSettings: onOpenSettings,
                onOpenProfile: onOpenProfile,
                onDebugAppTap: onDebugAppTap,
                onEditSkill: (skill) =>
                    _showDesktopEditSkill(context, state, skill),
                onDeleteSkill: (skill) =>
                    _showDesktopDeleteSkill(context, state, skill),
                onOpenRoadmap: onOpenRoadmap,
                profileKey: profileKey,
                rewardsKey: rewardsKey,
                roadmapKey: roadmapKey,
                statsKey: statsKey,
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: tokens.outline),
            Expanded(
              key: const ValueKey('desktop-main-region'),
              child: KeyedSubtree(
                key: contextualToastHostKey,
                child: actMode
                    ? _DesktopMainWorkspace(
                        state: state,
                        skill: effectiveSkill,
                        tokens: tokens,
                        metrics: metrics,
                        onAddSkill: onAddSkill,
                        onAddTask: (skill) =>
                            _showDesktopAddTask(context, state, skill),
                        onEditTask: (skill, task) =>
                            _showDesktopEditTask(context, state, skill, task),
                        onComplete: onComplete,
                        onMinimumAction: onMinimumAction,
                      )
                    : Padding(
                        padding: EdgeInsets.all(metrics.mainPadding),
                        child: alternateWorkspace ?? const SizedBox.shrink(),
                      ),
              ),
            ),
            if (actMode && metrics.showRightRail) ...[
              VerticalDivider(width: 1, thickness: 1, color: tokens.outline),
              KeyedSubtree(
                key: const ValueKey('desktop-right-rail-region'),
                child: SizedBox(
                  key: rightRailKey,
                  width: metrics.railWidth,
                  child: DesktopRightRail(
                    state: state,
                    tokens: tokens,
                    onComplete: onComplete,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final AppState state;
  final DesktopJournalTokens tokens;
  final WorkspaceMode mode;
  final Skill? effectiveSkill;
  final ValueChanged<WorkspaceMode> onModeChanged;
  final VoidCallback onAddSkill;
  final VoidCallback onOpenRewards;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenProfile;
  final VoidCallback? onDebugAppTap;
  final ValueChanged<Skill> onEditSkill;
  final ValueChanged<Skill> onDeleteSkill;
  final ValueChanged<Skill> onOpenRoadmap;
  final GlobalKey? profileKey;
  final GlobalKey? rewardsKey;
  final GlobalKey? roadmapKey;
  final GlobalKey? statsKey;

  const _DesktopSidebar({
    required this.state,
    required this.tokens,
    required this.mode,
    required this.effectiveSkill,
    required this.onModeChanged,
    required this.onAddSkill,
    required this.onOpenRewards,
    required this.onOpenStatistics,
    required this.onOpenSettings,
    required this.onOpenProfile,
    this.onDebugAppTap,
    required this.onEditSkill,
    required this.onDeleteSkill,
    required this.onOpenRoadmap,
    this.profileKey,
    this.rewardsKey,
    this.roadmapKey,
    this.statsKey,
  });

  @override
  Widget build(BuildContext context) {
    final skills = state.roadmapSkills;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeight = constraints.maxHeight < 620;
        return ColoredBox(
          color: tokens.sidebarSurface,
          child: Column(
            children: [
              _DesktopBrand(
                key: const ValueKey('top-bar-app-mark'),
                tokens: tokens,
                onTap: onDebugAppTap,
                compact: compactHeight,
              ),
              Divider(height: 1, color: tokens.subtleOutline),
              _DesktopProfileSummary(
                key: profileKey,
                state: state,
                tokens: tokens,
                onTap: onOpenProfile,
                compact: compactHeight,
              ),
              Divider(height: 1, color: tokens.subtleOutline),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  compactHeight ? 6 : 12,
                  12,
                  compactHeight ? 5 : 10,
                ),
                child: Column(
                  children: [
                    _DesktopNavItem(
                      key: const ValueKey('desktop-nav-act'),
                      icon: Icons.bolt_rounded,
                      label: 'Действовать',
                      selected: mode == WorkspaceMode.act,
                      tokens: tokens,
                      compact: compactHeight,
                      onTap: () => onModeChanged(WorkspaceMode.act),
                    ),
                    KeyedSubtree(
                      key: roadmapKey,
                      child: _DesktopNavItem(
                        key: const ValueKey('desktop-nav-map'),
                        icon: Icons.account_tree,
                        label: 'Карта',
                        selected: mode == WorkspaceMode.mastery,
                        tokens: tokens,
                        compact: compactHeight,
                        onTap: () => onModeChanged(WorkspaceMode.mastery),
                      ),
                    ),
                    KeyedSubtree(
                      key: rewardsKey,
                      child: _DesktopNavItem(
                        key: const ValueKey('desktop-nav-trophies'),
                        icon: Icons.emoji_events_outlined,
                        label: 'Трофеи',
                        selected: mode == WorkspaceMode.rewards,
                        tokens: tokens,
                        compact: compactHeight,
                        onTap: onOpenRewards,
                      ),
                    ),
                    KeyedSubtree(
                      key: statsKey,
                      child: _DesktopNavItem(
                        key: const ValueKey('desktop-nav-statistics'),
                        icon: Icons.query_stats,
                        label: 'Статистика',
                        selected: mode == WorkspaceMode.stats,
                        tokens: tokens,
                        compact: compactHeight,
                        onTap: onOpenStatistics,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.subtleOutline),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  compactHeight ? 7 : 12,
                  12,
                  compactHeight ? 4 : 7,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'НАВЫКИ',
                        style: context.appTextRoles.sectionEyebrow.copyWith(
                          color: tokens.mutedText,
                        ),
                      ),
                    ),
                    _DesktopCompactButton(
                      key: const ValueKey('desktop-add-skill'),
                      label: 'Навык',
                      icon: Icons.add_rounded,
                      color: tokens.profilePurple,
                      onTap: onAddSkill,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: skills.isEmpty
                    ? _DesktopSidebarEmpty(tokens: tokens, onAdd: onAddSkill)
                    : ReorderableListView.builder(
                        key: const ValueKey('desktop-skill-list'),
                        padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                        buildDefaultDragHandles: false,
                        itemCount: skills.length,
                        onReorderItem: state.reorderSkills,
                        itemBuilder: (context, index) {
                          final skill = skills[index];
                          return Padding(
                            key: ValueKey('desktop-skill-reorder-${skill.id}'),
                            padding: const EdgeInsets.only(bottom: 5),
                            child: ReorderableDelayedDragStartListener(
                              index: index,
                              child: _DesktopSkillRow(
                                key: ValueKey('desktop-skill-${skill.id}'),
                                skill: skill,
                                tokens: tokens,
                                selected: effectiveSkill?.id == skill.id,
                                activeCount: state.activeTaskCountForSkill(
                                  skill.id,
                                ),
                                onTap: () {
                                  if (state.selectedSkillId != skill.id) {
                                    state.selectSkill(skill.id);
                                  }
                                  if (mode == WorkspaceMode.mastery) {
                                    onOpenRoadmap(skill);
                                  }
                                },
                                onEdit: () => onEditSkill(skill),
                                onDelete: () => onDeleteSkill(skill),
                                onRoadmap: () => onOpenRoadmap(skill),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              _DesktopInboxShortcut(state: state, tokens: tokens),
              Divider(height: 1, color: tokens.subtleOutline),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                child: _DesktopNavItem(
                  key: const ValueKey('desktop-settings'),
                  icon: Icons.settings_outlined,
                  label: 'Настройки',
                  selected: mode == WorkspaceMode.settings,
                  tokens: tokens,
                  compact: true,
                  onTap: onOpenSettings,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopBrand extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final VoidCallback? onTap;
  final bool compact;

  const _DesktopBrand({
    super.key,
    required this.tokens,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 52 : 64),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 16),
            child: Row(
              children: [
                Container(
                  width: compact ? 30 : 34,
                  height: compact ? 30 : 34,
                  decoration: BoxDecoration(
                    color: tokens.profilePurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: compact ? 17 : 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'RPG To-Do',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTextTheme.titleMedium?.copyWith(
                      color: tokens.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopProfileSummary extends StatelessWidget {
  final AppState state;
  final DesktopJournalTokens tokens;
  final VoidCallback onTap;
  final bool compact;

  const _DesktopProfileSummary({
    super.key,
    required this.state,
    required this.tokens,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    return Semantics(
      button: true,
      label:
          '${profile.name}, уровень ${profile.level}, ${profile.xp} из ${profile.xpNeeded} XP',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              compact ? 10 : 16,
              16,
              compact ? 9 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: compact ? 38 : 48,
                      height: compact ? 38 : 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tokens.profilePurple.withValues(alpha: 0.82),
                            tokens.profilePurple,
                          ],
                        ),
                        image: profile.avatarBytes == null
                            ? null
                            : DecorationImage(
                                image: MemoryImage(profile.avatarBytes!),
                                fit: BoxFit.cover,
                              ),
                      ),
                      alignment: Alignment.center,
                      child: profile.avatarBytes == null
                          ? Text(
                              profile.initial,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 15 : 18,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: compact ? 3 : 5),
                          DesktopLevelPill(
                            level: profile.level,
                            color: tokens.profilePurple,
                            tokens: tokens,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Опыт персонажа',
                          style: TextStyle(
                            color: tokens.mutedText,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${profile.xp}/${profile.xpNeeded}',
                        style: TextStyle(
                          color: tokens.profilePurple,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DesktopProgressBar(
                    value: profile.progress,
                    color: tokens.profilePurple,
                    background: tokens.profilePurple.withValues(alpha: 0.15),
                    height: 7,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final DesktopJournalTokens tokens;
  final VoidCallback onTap;
  final bool compact;

  const _DesktopNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.tokens,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_DesktopNavItem> createState() => _DesktopNavItemState();
}

class _DesktopNavItemState extends State<_DesktopNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final active = widget.selected;
    return Semantics(
      button: true,
      selected: active,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                DesktopJournalTokens.navRadius,
              ),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: DesktopJournalTokens.fastMotion,
                curve: DesktopJournalTokens.motionCurve,
                constraints: BoxConstraints(
                  minHeight: widget.compact ? 36 : 42,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? tokens.profilePurple.withValues(alpha: 0.16)
                      : _hovered
                      ? tokens.raisedSurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    DesktopJournalTokens.navRadius,
                  ),
                  border: Border.all(
                    color: active
                        ? tokens.profilePurple.withValues(alpha: 0.42)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: active ? tokens.profilePurple : tokens.mutedText,
                      size: 19,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.appTextTheme.labelLarge?.copyWith(
                          color: active ? tokens.text : tokens.mutedText,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (active)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: tokens.profilePurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopSkillRow extends StatefulWidget {
  final Skill skill;
  final DesktopJournalTokens tokens;
  final bool selected;
  final int activeCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRoadmap;

  const _DesktopSkillRow({
    super.key,
    required this.skill,
    required this.tokens,
    required this.selected,
    required this.activeCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onRoadmap,
  });

  @override
  State<_DesktopSkillRow> createState() => _DesktopSkillRowState();
}

class _DesktopSkillRowState extends State<_DesktopSkillRow> {
  bool _hovered = false;
  bool _focused = false;
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final tokens = widget.tokens;
    final selected = widget.selected;
    final actionsVisible = _hovered || _focused || _menuOpen;
    final textTheme = context.appTextTheme;
    final roles = context.appTextRoles;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final allowSecondTitleLine = textScale >= 1.6;
    const actionTrayWidth = 58.0;
    return Semantics(
      key: ValueKey('desktop-skill-semantics-${skill.id}'),
      button: true,
      selected: selected,
      label:
          '${skill.name}, уровень ${skill.level}, ${widget.activeCount} активных квестов',
      hint: 'Удерживайте и перетащите, чтобы изменить порядок',
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(
                DesktopJournalTokens.skillRadius,
              ),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              child: AnimatedContainer(
                key: ValueKey('desktop-skill-surface-${skill.id}'),
                duration: DesktopJournalTokens.fastMotion,
                curve: DesktopJournalTokens.motionCurve,
                constraints: const BoxConstraints(minHeight: 62),
                padding: const EdgeInsets.fromLTRB(10, 7, 7, 7),
                decoration: BoxDecoration(
                  color: selected
                      ? skill.color.withValues(alpha: 0.11)
                      : _hovered
                      ? tokens.raisedSurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    DesktopJournalTokens.skillRadius,
                  ),
                  border: Border.all(
                    color: selected
                        ? skill.color.withValues(alpha: 0.42)
                        : Colors.transparent,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    AnimatedPadding(
                      key: ValueKey('desktop-skill-content-${skill.id}'),
                      duration: DesktopJournalTokens.fastMotion,
                      curve: DesktopJournalTokens.motionCurve,
                      padding: EdgeInsets.only(
                        right: actionsVisible ? actionTrayWidth : 0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: skill.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              skill.icon,
                              color: skill.color,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  skill.name,
                                  maxLines: allowSecondTitleLine ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: tokens.text,
                                    height: 1.08,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Ур. ${skill.level} · ${widget.activeCount} кв.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: roles.compactMetadata.copyWith(
                                    color: selected
                                        ? skill.color
                                        : tokens.mutedText,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                DesktopProgressBar(
                                  value: skill.progress,
                                  color: skill.color,
                                  background: skill.color.withValues(
                                    alpha: 0.12,
                                  ),
                                  height: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IgnorePointer(
                      ignoring: !actionsVisible,
                      child: AnimatedSlide(
                        duration: DesktopJournalTokens.fastMotion,
                        curve: DesktopJournalTokens.motionCurve,
                        offset: actionsVisible
                            ? Offset.zero
                            : const Offset(0.28, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedOpacity(
                              key: ValueKey(
                                'desktop-skill-roadmap-${skill.id}',
                              ),
                              duration: DesktopJournalTokens.fastMotion,
                              opacity: actionsVisible ? 1 : 0,
                              child: SizedBox(
                                width: 28,
                                child: IconButton(
                                  tooltip: 'Открыть путь навыка в RoadMap',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 28,
                                    height: 40,
                                  ),
                                  onPressed: widget.onRoadmap,
                                  icon: Icon(
                                    Icons.route_rounded,
                                    size: 16,
                                    color: skill.color,
                                  ),
                                ),
                              ),
                            ),
                            AnimatedOpacity(
                              key: ValueKey(
                                'desktop-skill-overflow-${skill.id}',
                              ),
                              duration: DesktopJournalTokens.fastMotion,
                              opacity: actionsVisible ? 1 : 0,
                              child: SizedBox(
                                width: 28,
                                child: PopupMenuButton<String>(
                                  tooltip: 'Действия с навыком ${skill.name}',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 28,
                                    height: 40,
                                  ),
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    size: 17,
                                    color: tokens.mutedText,
                                  ),
                                  color: tokens.raisedSurface,
                                  onOpened: () =>
                                      setState(() => _menuOpen = true),
                                  onCanceled: () =>
                                      setState(() => _menuOpen = false),
                                  onSelected: (value) {
                                    setState(() => _menuOpen = false);
                                    if (value == 'edit') widget.onEdit();
                                    if (value == 'delete') widget.onDelete();
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(
                                        'Редактировать навык',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: tokens.text,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Удалить навык',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: tokens.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopInboxShortcut extends StatelessWidget {
  final AppState state;
  final DesktopJournalTokens tokens;

  const _DesktopInboxShortcut({required this.state, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final active = state.inboxTasks.where((task) => !task.isDone).length;
    return Padding(
      key: const ValueKey('desktop-inbox-shortcut'),
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: _DesktopInteractiveSurface(
        borderRadius: 12,
        baseColor: const Color(0xFF22C55E).withValues(alpha: 0.08),
        hoverColor: const Color(0xFF22C55E).withValues(alpha: 0.13),
        borderColor: const Color(0xFF22C55E).withValues(alpha: 0.22),
        onTap: () {
          if (state.selectedSkillId != kInboxSkillId) {
            state.selectSkill(kInboxSkillId);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              const Icon(
                Icons.inbox_rounded,
                color: Color(0xFF2ED36F),
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Задачник',
                  style: context.appTextTheme.labelLarge?.copyWith(
                    color: tokens.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$active',
                style: context.appTextRoles.compactMetadata.copyWith(
                  color: Color(0xFF2ED36F),
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

class _DesktopSidebarEmpty extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final VoidCallback onAdd;

  const _DesktopSidebarEmpty({required this.tokens, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 86) {
          return const SizedBox.shrink();
        }
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: tokens.mutedText, size: 24),
                const SizedBox(height: 8),
                Text(
                  'Создай первый навык',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.appTextTheme.bodySmall?.copyWith(
                    color: tokens.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _DesktopCompactButton(
                  label: 'Навык',
                  icon: Icons.add_rounded,
                  color: tokens.profilePurple,
                  onTap: onAdd,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DesktopMainWorkspace extends StatelessWidget {
  final AppState state;
  final Skill? skill;
  final DesktopJournalTokens tokens;
  final DesktopResponsiveMetrics metrics;
  final VoidCallback onAddSkill;
  final ValueChanged<Skill> onAddTask;
  final void Function(Skill skill, Task task) onEditTask;
  final void Function(String taskId, ActionToastOrigin origin) onComplete;
  final void Function(String taskId, ActionToastOrigin origin) onMinimumAction;

  const _DesktopMainWorkspace({
    required this.state,
    required this.skill,
    required this.tokens,
    required this.metrics,
    required this.onAddSkill,
    required this.onAddTask,
    required this.onEditTask,
    required this.onComplete,
    required this.onMinimumAction,
  });

  @override
  Widget build(BuildContext context) {
    if (skill?.id == kInboxSkillId) {
      return InboxPanel(onComplete: onComplete, desktopJournal: true);
    }
    final currentSkill = skill;
    final stats = state.todayStats;
    final activeGlobal = state.tasks
        .where((task) => task.isSkillTask && !task.isDone)
        .length;
    final streak = state.tasks
        .where((task) => task.type == TaskType.repeating)
        .fold<int>(0, (value, task) => math.max(value, task.streak));
    final tasks = currentSkill == null
        ? const <Task>[]
        : state.tasksForSkill(currentSkill.id);
    final active = tasks.where((task) => !task.isDone).toList();
    final completed =
        tasks.where((task) => task.isDone && !task.isArchived).toList()
          ..sort((a, b) {
            final aAt = a.lastCompletedAt ?? a.updatedAt;
            final bAt = b.lastCompletedAt ?? b.updatedAt;
            return bAt.compareTo(aAt);
          });
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final hasQuestHistory =
        currentSkill != null &&
        (tasks.isNotEmpty ||
            state.history.any((entry) => entry.skillId == currentSkill.id));

    Widget buildTodaySummary() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tokens.streakAmber.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: tokens.streakAmber,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Действовать сегодня',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextTheme.titleLarge?.copyWith(
                  color: tokens.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 690 ? 4 : 2;
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final childAspectRatio = textScale >= 1.6
                ? (columns == 4 ? 1.25 : 1.6)
                : (columns == 4 ? 2.25 : 2.7);
            return GridView.count(
              key: const ValueKey('desktop-today-stats'),
              crossAxisCount: columns,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DesktopStatCard(
                  icon: Icons.check_rounded,
                  value: '${stats?.tasksCompleted ?? 0}',
                  label: 'Выполнено',
                  color: tokens.successGreen,
                  tokens: tokens,
                ),
                _DesktopStatCard(
                  icon: Icons.bolt_rounded,
                  value: '+${stats?.xpEarned ?? 0}',
                  label: 'XP сегодня',
                  color: tokens.rewardGold,
                  tokens: tokens,
                ),
                _DesktopStatCard(
                  icon: Icons.radio_button_unchecked_rounded,
                  value: '$activeGlobal',
                  label: 'Активных',
                  color: tokens.semanticBlue,
                  tokens: tokens,
                ),
                _DesktopStatCard(
                  icon: Icons.local_fire_department_outlined,
                  value: '$streak дн.',
                  label: 'Серия',
                  color: tokens.streakAmber,
                  tokens: tokens,
                ),
              ],
            );
          },
        ),
      ],
    );

    if (currentSkill != null && !hasQuestHistory) {
      final header = DesktopSelectedSkillHeader(
        skill: currentSkill,
        tokens: tokens,
        totalQuestCount: tasks.length,
        onAddTask: () => onAddTask(currentSkill),
      );
      final firstQuest = _DesktopFirstQuestEmpty(
        tokens: tokens,
        color: currentSkill.color,
      );
      return ColoredBox(
        color: tokens.mainSurface,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = EdgeInsets.fromLTRB(
              metrics.mainPadding,
              22,
              metrics.mainPadding,
              32,
            );
            final needsScrollableLayout =
                constraints.maxHeight < 540 ||
                MediaQuery.textScalerOf(context).scale(1) >= 1.6;
            if (needsScrollableLayout) {
              return ListView(
                key: const ValueKey('desktop-first-quest-scroll'),
                padding: padding,
                children: [
                  buildTodaySummary(),
                  SizedBox(height: metrics.sectionGap + 10),
                  header,
                  const SizedBox(height: 24),
                  firstQuest,
                ],
              );
            }
            return Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTodaySummary(),
                  SizedBox(height: metrics.sectionGap + 10),
                  header,
                  const SizedBox(height: 18),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, workspaceConstraints) => Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: math.min(
                              720,
                              workspaceConstraints.maxWidth,
                            ),
                          ),
                          child: firstQuest,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return ColoredBox(
      color: tokens.mainSurface,
      child: Scrollbar(
        child: ListView(
          key: const ValueKey('desktop-main-scroll'),
          padding: EdgeInsets.fromLTRB(
            metrics.mainPadding,
            22,
            metrics.mainPadding,
            32,
          ),
          children: [
            buildTodaySummary(),
            SizedBox(height: metrics.sectionGap + 10),
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : DesktopJournalTokens.standardMotion,
              switchInCurve: DesktopJournalTokens.motionCurve,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topLeft,
                children: [...previousChildren, ?currentChild],
              ),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: currentSkill == null
                  ? _DesktopNoSkillMain(
                      key: const ValueKey('desktop-no-skill'),
                      tokens: tokens,
                      onAdd: onAddSkill,
                    )
                  : Column(
                      key: ValueKey('desktop-selected-${currentSkill.id}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DesktopSelectedSkillHeader(
                          skill: currentSkill,
                          tokens: tokens,
                          totalQuestCount: tasks.length,
                          onAddTask: () => onAddTask(currentSkill),
                        ),
                        const SizedBox(height: 24),
                        if (!hasQuestHistory)
                          _DesktopFirstQuestEmpty(
                            tokens: tokens,
                            color: currentSkill.color,
                          )
                        else ...[
                          _DesktopQuestSectionTitle(
                            label: 'АКТИВНЫЕ',
                            count: active.length,
                            tokens: tokens,
                          ),
                          const SizedBox(height: 10),
                          if (active.isEmpty)
                            Text(
                              'Активных квестов пока нет.',
                              style: TextStyle(
                                color: tokens.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ...active.map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _DesktopQuestRow(
                                key: ValueKey('desktop-active-task-${task.id}'),
                                state: state,
                                task: task,
                                skill: currentSkill,
                                tokens: tokens,
                                onComplete: onComplete,
                                onMinimumAction: onMinimumAction,
                                onEdit: () => onEditTask(currentSkill, task),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _DesktopQuestSectionTitle(
                            label: 'ВЫПОЛНЕНО',
                            count: completed.length,
                            tokens: tokens,
                          ),
                          const SizedBox(height: 10),
                          if (completed.isEmpty)
                            Text(
                              'Завершённые квесты появятся здесь.',
                              style: TextStyle(
                                color: tokens.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ...completed.map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _DesktopQuestRow(
                                key: ValueKey(
                                  'desktop-completed-task-${task.id}',
                                ),
                                state: state,
                                task: task,
                                skill: currentSkill,
                                tokens: tokens,
                                onComplete: onComplete,
                                onMinimumAction: onMinimumAction,
                                onEdit: () => onEditTask(currentSkill, task),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final DesktopJournalTokens tokens;

  const _DesktopStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          // Compact stat cards have a bounded row height. Reclaim a little
          // vertical room before enlarged text would overflow that contract.
          vertical: textScale >= 1.2 ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(DesktopJournalTokens.statRadius),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.mutedText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopQuestSectionTitle extends StatelessWidget {
  final String label;
  final int count;
  final DesktopJournalTokens tokens;

  const _DesktopQuestSectionTitle({
    required this.label,
    required this.count,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label · $count',
      style: TextStyle(
        color: tokens.mutedText,
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.55,
      ),
    );
  }
}

class _DesktopFirstQuestEmpty extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final Color color;

  const _DesktopFirstQuestEmpty({required this.tokens, required this.color});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeText = textScale >= 1.6;
    return Container(
      key: const ValueKey('desktop-first-quest-empty'),
      constraints: BoxConstraints(
        minHeight: largeText ? 178 : 156,
        maxWidth: 720,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: largeText ? 26 : 32,
        vertical: largeText ? 20 : 24,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(DesktopJournalTokens.taskRadius),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded, color: color, size: largeText ? 30 : 34),
          const SizedBox(height: 12),
          Text(
            'Добавь свой первый квест',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.appTextTheme.titleMedium?.copyWith(
              color: tokens.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Начни с небольшого действия, которое поможет двигаться к цели.',
            maxLines: largeText ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.appTextTheme.bodySmall?.copyWith(
              color: tokens.mutedText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopQuestRow extends StatefulWidget {
  final AppState state;
  final Task task;
  final Skill skill;
  final DesktopJournalTokens tokens;
  final void Function(String taskId, ActionToastOrigin origin) onComplete;
  final void Function(String taskId, ActionToastOrigin origin) onMinimumAction;
  final VoidCallback onEdit;

  const _DesktopQuestRow({
    super.key,
    required this.state,
    required this.task,
    required this.skill,
    required this.tokens,
    required this.onComplete,
    required this.onMinimumAction,
    required this.onEdit,
  });

  @override
  State<_DesktopQuestRow> createState() => _DesktopQuestRowState();
}

class _DesktopQuestRowState extends State<_DesktopQuestRow> {
  bool _hovered = false;
  bool _focused = false;
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final tokens = widget.tokens;
    final done = task.isDone;
    final reward = done
        ? math.max(task.earnedXP, task.xpReward)
        : widget.state.previewEarnedXP(task);
    final type = typeLabel[task.type] ?? 'Квест';
    final badgeColor = typeColor[task.type] ?? widget.skill.color;
    final actionsVisible = _hovered || _focused || _menuOpen;
    return Semantics(
      button: true,
      label:
          '${task.title}, ${done ? 'выполненный' : 'активный'} квест, награда $reward XP',
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: DesktopJournalTokens.fastMotion,
            curve: DesktopJournalTokens.motionCurve,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
            decoration: BoxDecoration(
              color: done
                  ? tokens.successGreen.withValues(alpha: 0.045)
                  : _hovered
                  ? tokens.raisedSurface
                  : tokens.cardSurface,
              borderRadius: BorderRadius.circular(
                DesktopJournalTokens.taskRadius,
              ),
              border: Border.all(
                color: done
                    ? tokens.successGreen.withValues(alpha: 0.18)
                    : _hovered
                    ? widget.skill.color.withValues(alpha: 0.22)
                    : tokens.outline,
              ),
              boxShadow: done
                  ? null
                  : [
                      BoxShadow(
                        color: widget.skill.color.withValues(alpha: 0.022),
                        blurRadius: 12,
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DesktopQuestCheck(
                  done: done,
                  color: done ? tokens.successGreen : widget.skill.color,
                  onTap: (origin) {
                    if (done) {
                      widget.state.uncompleteTask(task.id);
                    } else {
                      widget.onComplete(task.id, origin);
                    }
                  },
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: done ? tokens.mutedText : tokens.text,
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tokens.mutedText,
                            fontSize: 11.5,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _DesktopTypeBadge(label: type, color: badgeColor),
                          if (!done &&
                              task.hasMinimumAction &&
                              !task.isMinimumActionDone)
                            _DesktopMiniAction(
                              label: 'Минимальный шаг',
                              color: widget.skill.color,
                              onTap: (origin) =>
                                  widget.onMinimumAction(task.id, origin),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _DesktopRewardPill(value: reward, tokens: tokens),
                AnimatedOpacity(
                  key: ValueKey('desktop-task-overflow-${task.id}'),
                  duration: DesktopJournalTokens.fastMotion,
                  opacity: actionsVisible ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !actionsVisible,
                    child: SizedBox(
                      width: 34,
                      child: PopupMenuButton<_DesktopTaskMenuAction>(
                        tooltip: 'Действия с квестом ${task.title}',
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: tokens.mutedText,
                          size: 19,
                        ),
                        color: tokens.raisedSurface,
                        onOpened: () => setState(() => _menuOpen = true),
                        onCanceled: () => setState(() => _menuOpen = false),
                        onSelected: (action) {
                          setState(() => _menuOpen = false);
                          switch (action) {
                            case _DesktopTaskMenuAction.edit:
                              widget.onEdit();
                            case _DesktopTaskMenuAction.archive:
                              widget.state.archiveCompletedTask(task.id);
                            case _DesktopTaskMenuAction.restore:
                              widget.state.restoreArchivedTask(task.id);
                            case _DesktopTaskMenuAction.delete:
                              widget.state.removeTask(task.id);
                          }
                        },
                        itemBuilder: (_) => [
                          if (!done)
                            PopupMenuItem(
                              value: _DesktopTaskMenuAction.edit,
                              child: Text(
                                'Редактировать',
                                style: TextStyle(color: tokens.text),
                              ),
                            ),
                          if (done && !task.isArchived)
                            PopupMenuItem(
                              value: _DesktopTaskMenuAction.archive,
                              child: Text(
                                'Убрать в выполнено',
                                style: TextStyle(color: tokens.text),
                              ),
                            ),
                          if (done && task.isArchived)
                            PopupMenuItem(
                              value: _DesktopTaskMenuAction.restore,
                              child: Text(
                                'Вернуть из выполненных',
                                style: TextStyle(color: tokens.text),
                              ),
                            ),
                          PopupMenuItem(
                            value: _DesktopTaskMenuAction.delete,
                            child: Text(
                              'Удалить',
                              style: TextStyle(color: tokens.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopQuestCheck extends StatefulWidget {
  final bool done;
  final Color color;
  final ValueChanged<ActionToastOrigin> onTap;

  const _DesktopQuestCheck({
    required this.done,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DesktopQuestCheck> createState() => _DesktopQuestCheckState();
}

class _DesktopQuestCheckState extends State<_DesktopQuestCheck> {
  ActionToastOrigin? _origin;
  final GlobalKey _checkKey = GlobalKey();

  void _completeTap() {
    final origin =
        _origin ??
        actionToastOriginForContext(
          _checkKey.currentContext ?? context,
          kind: ActionToastOriginKind.questCheckbox,
          zone: ActionToastZone.mainWorkspace,
        );
    _origin = null;
    widget.onTap(origin);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: widget.done,
      label: widget.done ? 'Вернуть квест' : 'Выполнить квест',
      child: Tooltip(
        message: widget.done ? 'Вернуть квест' : 'Выполнить квест',
        child: InkResponse(
          key: _checkKey,
          onTapDown: (_) => _origin = actionToastOriginForContext(
            _checkKey.currentContext ?? context,
            kind: ActionToastOriginKind.questCheckbox,
            zone: ActionToastZone.mainWorkspace,
          ),
          onTapCancel: () => _origin = null,
          onTap: _completeTap,
          radius: 24,
          child: AnimatedContainer(
            duration: DesktopJournalTokens.fastMotion,
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.done ? widget.color : Colors.transparent,
              border: Border.all(
                color: widget.color.withValues(alpha: 0.75),
                width: 2,
              ),
            ),
            child: widget.done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        ),
      ),
    );
  }
}

class _DesktopTypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DesktopTypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DesktopMiniAction extends StatefulWidget {
  final String label;
  final Color color;
  final ValueChanged<ActionToastOrigin> onTap;

  const _DesktopMiniAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DesktopMiniAction> createState() => _DesktopMiniActionState();
}

class _DesktopMiniActionState extends State<_DesktopMiniAction> {
  ActionToastOrigin? _origin;
  final GlobalKey _actionKey = GlobalKey();

  void _completeTap() {
    final origin =
        _origin ??
        actionToastOriginForContext(
          _actionKey.currentContext ?? context,
          kind: ActionToastOriginKind.minimumAction,
          zone: ActionToastZone.mainWorkspace,
        );
    _origin = null;
    widget.onTap(origin);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: _actionKey,
      onTapDown: (_) => _origin = actionToastOriginForContext(
        _actionKey.currentContext ?? context,
        kind: ActionToastOriginKind.minimumAction,
        zone: ActionToastZone.mainWorkspace,
      ),
      onTapCancel: () => _origin = null,
      onTap: _completeTap,
      borderRadius: BorderRadius.circular(99),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.color,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DesktopRewardPill extends StatelessWidget {
  final int value;
  final DesktopJournalTokens tokens;

  const _DesktopRewardPill({required this.value, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Награда $value XP',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: tokens.rewardGold.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: tokens.rewardGold.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: tokens.rewardGold, size: 13),
            const SizedBox(width: 4),
            Text(
              '+$value XP',
              style: context.appTextRoles.reward.copyWith(
                color: tokens.rewardGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopNoSkillMain extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final VoidCallback onAdd;

  const _DesktopNoSkillMain({
    super.key,
    required this.tokens,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return _DesktopInlineEmpty(
      tokens: tokens,
      text: 'Создай первый навык, чтобы начать путь.',
      actionLabel: 'Создать навык',
      onAction: onAdd,
    );
  }
}

class _DesktopInlineEmpty extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const _DesktopInlineEmpty({
    required this.tokens,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.cardSurface,
        borderRadius: BorderRadius.circular(DesktopJournalTokens.taskRadius),
        border: Border.all(color: tokens.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: tokens.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _DesktopCompactButton(
            label: actionLabel,
            icon: Icons.add_rounded,
            color: tokens.profilePurple,
            onTap: onAction,
          ),
        ],
      ),
    );
  }
}

class _DesktopCompactButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DesktopCompactButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(40, 34),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: 0.35)),
        ),
      ),
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _DesktopInteractiveSurface extends StatefulWidget {
  final double borderRadius;
  final Color baseColor;
  final Color hoverColor;
  final Color borderColor;
  final VoidCallback onTap;
  final Widget child;

  const _DesktopInteractiveSurface({
    required this.borderRadius,
    required this.baseColor,
    required this.hoverColor,
    required this.borderColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_DesktopInteractiveSurface> createState() =>
      _DesktopInteractiveSurfaceState();
}

class _DesktopInteractiveSurfaceState
    extends State<_DesktopInteractiveSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: AnimatedContainer(
            duration: DesktopJournalTokens.fastMotion,
            curve: DesktopJournalTokens.motionCurve,
            decoration: BoxDecoration(
              color: _hovered ? widget.hoverColor : widget.baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: widget.borderColor),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

void _showDesktopAddTask(BuildContext context, AppState state, Skill skill) {
  showAdaptiveCreationForm<void>(
    context: context,
    builder: (_, fullScreen) => AddTaskDialog(
      isDark: state.isDark,
      fullScreen: fullScreen,
      skillColor: skill.color,
      skill: skill,
      onSave:
          (
            title,
            description,
            xp,
            type,
            frequency,
            customDays,
            priority,
            minimumAction,
            subtasks,
            tags,
            notificationsEnabled,
            notificationHour,
            notificationMinute,
            treeNodeId,
          ) => state.addTask(
            Task(
              id: uid(),
              title: title,
              description: description,
              skillId: skill.id,
              xpReward: xp,
              type: type,
              repeatFrequency: frequency,
              repeatCustomDays: customDays,
              priority: priority,
              minimumAction: minimumAction,
              subtasks: subtasks,
              tags: tags,
              treeNodeId: treeNodeId,
              notificationsEnabled: notificationsEnabled,
              notificationHour: notificationHour,
              notificationMinute: notificationMinute,
            ),
          ),
    ),
  );
}

void _showDesktopEditTask(
  BuildContext context,
  AppState state,
  Skill skill,
  Task task,
) {
  showAdaptiveCreationForm<void>(
    context: context,
    builder: (_, fullScreen) => AddTaskDialog(
      isDark: state.isDark,
      fullScreen: fullScreen,
      skillColor: skill.color,
      skill: skill,
      existing: task,
      onSave:
          (
            title,
            description,
            xp,
            type,
            frequency,
            customDays,
            priority,
            minimumAction,
            subtasks,
            tags,
            notificationsEnabled,
            notificationHour,
            notificationMinute,
            treeNodeId,
          ) => state.updateTask(
            task,
            title: title,
            description: description,
            xpReward: xp,
            type: type,
            repeatFrequency: frequency,
            repeatCustomDays: customDays,
            priority: priority,
            minimumAction: minimumAction,
            subtasks: subtasks,
            tags: tags,
            notificationsEnabled: notificationsEnabled,
            notificationHour: notificationHour,
            notificationMinute: notificationMinute,
            treeNodeId: treeNodeId,
          ),
    ),
  );
}

void _showDesktopEditSkill(BuildContext context, AppState state, Skill skill) {
  showDialog<void>(
    context: context,
    builder: (_) => AddSkillDialog(
      isDark: state.isDark,
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

void _showDesktopDeleteSkill(
  BuildContext context,
  AppState state,
  Skill skill,
) {
  final tokens = DesktopJournalTokens.resolve(state.isDark);
  final taskCount = state.tasksForSkill(skill.id).length;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: tokens.raisedSurface,
      title: Text('Удалить навык?', style: TextStyle(color: tokens.text)),
      content: Text(
        '«${skill.name}» и $taskCount связанных квестов будут удалены.',
        style: TextStyle(color: tokens.mutedText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            state.removeSkill(skill.id);
            Navigator.pop(dialogContext);
          },
          style: TextButton.styleFrom(foregroundColor: tokens.danger),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
}
