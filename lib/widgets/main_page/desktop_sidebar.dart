import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../theme/app_typography.dart';
import '../desktop_journal_tokens.dart';
import 'desktop_selected_skill_header.dart';
import 'desktop_workspace_support.dart';
import 'main_page_observation.dart';
import 'mode.dart';

class DesktopSidebar extends StatelessWidget {
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

  const DesktopSidebar({
    super.key,
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
              MainPageProfileBoundary(
                key: profileKey,
                state: state,
                builder: (context) => _DesktopProfileSummary(
                  state: state,
                  tokens: tokens,
                  onTap: onOpenProfile,
                  compact: compactHeight,
                ),
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
                    DesktopCompactButton(
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
    required this.state,
    required this.tokens,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 38.0 : 48.0;
    final avatarDecodeSize =
        (avatarSize * MediaQuery.devicePixelRatioOf(context)).round();
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
                      width: avatarSize,
                      height: avatarSize,
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
                                image: ResizeImage.resizeIfNeeded(
                                  avatarDecodeSize,
                                  avatarDecodeSize,
                                  MemoryImage(profile.avatarBytes!),
                                ),
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
      child: DesktopInteractiveSurface(
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
                DesktopCompactButton(
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
