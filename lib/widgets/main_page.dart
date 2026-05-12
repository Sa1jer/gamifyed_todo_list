import 'package:flutter/material.dart';
import '../app_state.dart';
import '../utils.dart';
import 'shared.dart';
import 'dialogs.dart';
import 'skills_panel.dart';
import 'tasks_panel.dart';
import 'today_dashboard.dart';
import 'profile_dialog.dart';
import 'faq_dialog.dart';
import 'progress_hub_dialog.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════════

enum WorkspaceMode { act, plan, progress }

extension _WorkspaceModeMeta on WorkspaceMode {
  String get label => switch (this) {
    WorkspaceMode.act => 'Действовать',
    WorkspaceMode.plan => 'Планировать',
    WorkspaceMode.progress => 'Прогресс',
  };

  IconData get icon => switch (this) {
    WorkspaceMode.act => Icons.flash_on,
    WorkspaceMode.plan => Icons.edit_note,
    WorkspaceMode.progress => Icons.dashboard_customize,
  };

  Color get color => switch (this) {
    WorkspaceMode.act => const Color(0xFFFF9500),
    WorkspaceMode.plan => const Color(0xFF4A9EFF),
    WorkspaceMode.progress => const Color(0xFF34C759),
  };
}

class TopBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final AppState state;
  final WorkspaceMode mode;
  final ValueChanged<WorkspaceMode> onModeChanged;
  final GlobalKey? rewardsKey;
  final VoidCallback? onRewardsTap;
  const TopBar({
    super.key,
    required this.isDark,
    required this.onToggle,
    required this.state,
    required this.mode,
    required this.onModeChanged,
    this.rewardsKey,
    this.onRewardsTap,
  });

  @override
  Widget build(BuildContext context) {
    final sfc = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final rewardsCount = state.unopenedRewardChests.length;
    final activeBuffsCount = state.activeBuffs.length;
    final rewardsColor = rewardsCount > 0
        ? isDark
              ? const Color(0xFFFFCC00)
              : const Color(0xFFB87500)
        : activeBuffsCount > 0
        ? const Color(0xFF34C759)
        : sub;
    final rewardsBadge = rewardsCount > 0
        ? '$rewardsCount'
        : activeBuffsCount > 0
        ? '$activeBuffsCount'
        : null;

    return Container(
      color: sfc,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          return Row(
            children: [
              const Icon(Icons.security, color: Color(0xFF4A9EFF), size: 18),
              const SizedBox(width: 8),
              Text(
                'RPG To-Do List',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: txt,
                ),
              ),
              SizedBox(width: compact ? 10 : 18),
              _WorkspaceModeSwitch(
                mode: mode,
                isDark: isDark,
                compact: compact,
                onChanged: onModeChanged,
              ),
              const Spacer(),
              _TopBarPillButton(
                key: rewardsKey,
                icon: Icons.redeem,
                label: 'Награды',
                tooltip: rewardsCount > 0
                    ? 'Открыть новые сундуки'
                    : activeBuffsCount > 0
                    ? 'Посмотреть активные баффы'
                    : 'Открыть награды и баффы',
                color: rewardsColor,
                badge: rewardsBadge,
                compact: compact,
                elevated: !isDark && rewardsCount > 0,
                onTap:
                    onRewardsTap ??
                    () => showDialog(
                      context: context,
                      builder: (_) => RewardsDialog(state: state),
                    ),
              ),
              const SizedBox(width: 8),
              HoverIconBtn(
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                color: sub,
                tooltip: isDark
                    ? 'Переключить на светлую тему'
                    : 'Переключить на тёмную тему',
                onTap: onToggle,
              ),
              const SizedBox(width: 4),
              HoverIconBtn(
                icon: Icons.help_outline,
                color: sub,
                tooltip: 'Открыть гид по приложению',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => FAQDialog(isDark: isDark),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkspaceModeSwitch extends StatelessWidget {
  final WorkspaceMode mode;
  final bool isDark;
  final bool compact;
  final ValueChanged<WorkspaceMode> onChanged;

  const _WorkspaceModeSwitch({
    required this.mode,
    required this.isDark,
    required this.compact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bdr = borderColor(isDark);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121219) : const Color(0xFFE8EBF4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bdr),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in WorkspaceMode.values)
            _WorkspaceModeButton(
              mode: item,
              isDark: isDark,
              compact: compact,
              selected: item == mode,
              onTap: () => onChanged(item),
            ),
        ],
      ),
    );
  }
}

class _WorkspaceModeButton extends StatefulWidget {
  final WorkspaceMode mode;
  final bool isDark;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  const _WorkspaceModeButton({
    required this.mode,
    required this.isDark,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_WorkspaceModeButton> createState() => _WorkspaceModeButtonState();
}

class _WorkspaceModeButtonState extends State<_WorkspaceModeButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.mode.color;
    final sub = subtext(widget.isDark);
    final active = widget.selected || _hovered;

    final button = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 8 : 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: widget.selected
                  ? color.withAlpha(32)
                  : active
                  ? color.withAlpha(16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: widget.selected
                    ? color.withAlpha(62)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.mode.icon,
                  color: widget.selected ? color : sub,
                  size: 15,
                ),
                if (!widget.compact) ...[
                  const SizedBox(width: 5),
                  Text(
                    widget.mode.label,
                    style: TextStyle(
                      color: widget.selected ? color : sub,
                      fontSize: 12,
                      fontWeight: widget.selected
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Tooltip(message: widget.mode.label, child: button);
  }
}

class _TopBarPillButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final Color color;
  final String? badge;
  final VoidCallback onTap;
  final bool compact;
  final bool elevated;

  const _TopBarPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.badge,
    this.compact = false,
    this.elevated = false,
  });

  @override
  State<_TopBarPillButton> createState() => _TopBarPillButtonState();
}

class _TopBarPillButtonState extends State<_TopBarPillButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 8 : 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _hovered || _pressed
                  ? widget.color.withAlpha(widget.elevated ? 42 : 34)
                  : widget.color.withAlpha(widget.elevated ? 24 : 16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: widget.color.withAlpha(widget.elevated ? 112 : 55),
              ),
              boxShadow: widget.elevated
                  ? [
                      BoxShadow(
                        color: widget.color.withAlpha(_hovered ? 42 : 28),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.color, size: 17),
                if (!widget.compact) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (widget.badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withAlpha(36),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.badge!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Tooltip(message: widget.tooltip, child: button);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE BAR
// Direct AppStateProvider consumer for immediate XP bar updates.
// Avatar, name, and level badge all open the Profile dialog on tap.
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileBar extends StatelessWidget {
  final bool isDark;
  const ProfileBar({super.key, required this.isDark});

  void _openProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AppStateProvider(
        state: AppStateProvider.of(context),
        child: const ProfileDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppStateProvider.of(context).profile;
    final rank = profileRankForLevel(profile.level);
    final sfc = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      color: sfc,
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
      child: Row(
        children: [
          // Avatar — clickable → profile
          HoverScale(
            child: GestureDetector(
              onTap: () => _openProfile(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: profile.avatarBytes == null
                      ? const LinearGradient(
                          colors: [Color(0xFF4A9EFF), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  image: profile.avatarBytes != null
                      ? DecorationImage(
                          image: MemoryImage(profile.avatarBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  shape: BoxShape.circle,
                ),
                child: profile.avatarBytes == null
                    ? Center(
                        child: Text(
                          profile.initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Name — clickable → profile
                    GestureDetector(
                      onTap: () => _openProfile(context),
                      child: Text(
                        profile.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: txt,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Level badge — clickable → profile
                    GestureDetector(
                      onTap: () => _openProfile(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RankBadge(label: rank.label, color: rank.color),
                          const SizedBox(width: 6),
                          LvlBadge(
                            level: profile.level,
                            color: const Color(0xFF4A9EFF),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: XPBar(
                        progress: profile.progress,
                        color: const Color(0xFF4A9EFF),
                        height: 7,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${profile.xp} / ${profile.xpNeeded} XP',
                      style: TextStyle(color: sub, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class MainPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const MainPage({super.key, required this.onToggleTheme});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<XPBubble> _bubbles = [];
  final GlobalKey _pageStackKey = GlobalKey();
  final GlobalKey _rewardsButtonKey = GlobalKey();
  WorkspaceMode _mode = WorkspaceMode.act;
  _RewardNotice? _rewardNotice;
  Offset? _rewardNoticeAnchor;

  void _showBubble(String message, Offset pos) {
    setState(() {
      _bubbles.add(
        XPBubble(
          key: UniqueKey(),
          message: message,
          position: pos,
          onDone: (k) =>
              setState(() => _bubbles.removeWhere((b) => b.key == k)),
        ),
      );
    });
  }

  void _showRewardNotifications(AppState state) {
    final chests = state.consumeRewardChestNotifications();
    final buffs = state.consumeBuffNotifications();
    if ((chests.isEmpty && buffs.isEmpty) || !mounted) return;

    setState(() {
      _rewardNotice = _RewardNotice(
        chestTitles: chests.map((chest) => chest.title).toList(),
        buffTitles: buffs.map((buff) => buff.title).toList(),
      );
      _rewardNoticeAnchor = _resolveRewardsButtonAnchor();
    });
  }

  Offset? _resolveRewardsButtonAnchor() {
    final buttonContext = _rewardsButtonKey.currentContext;
    final stackContext = _pageStackKey.currentContext;
    if (buttonContext == null || stackContext == null) return null;

    final buttonBox = buttonContext.findRenderObject();
    final stackBox = stackContext.findRenderObject();
    if (buttonBox is! RenderBox || stackBox is! RenderBox) return null;

    final buttonTopLeft = buttonBox.localToGlobal(Offset.zero);
    final localTopLeft = stackBox.globalToLocal(buttonTopLeft);
    return Offset(
      localTopLeft.dx + buttonBox.size.width / 2,
      localTopLeft.dy + buttonBox.size.height,
    );
  }

  void _openRewardsDialog(AppState state) {
    setState(() => _rewardNotice = null);
    showDialog(
      context: context,
      builder: (_) => RewardsDialog(state: state),
    );
  }

  void _onComplete(String taskId, Offset pos) {
    final s = AppStateProvider.of(context);
    final msg = s.completeTask(taskId);
    if (msg == null) return;
    _showBubble(msg, pos);
    _showRewardNotifications(s);
  }

  void _onMinimumAction(String taskId, Offset pos) {
    final s = AppStateProvider.of(context);
    final msg = s.completeMinimumAction(taskId);
    if (msg == null) return;
    _showBubble(msg, pos);
    _showRewardNotifications(s);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateProvider.of(context);
    final isDark = s.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F13)
          : const Color(0xFFF0F2F8),
      body: Stack(
        key: _pageStackKey,
        children: [
          Column(
            children: [
              TopBar(
                isDark: isDark,
                onToggle: widget.onToggleTheme,
                state: s,
                mode: _mode,
                onModeChanged: (mode) {
                  if (_mode == mode) return;
                  setState(() => _mode = mode);
                },
                rewardsKey: _rewardsButtonKey,
                onRewardsTap: () => _openRewardsDialog(s),
              ),
              ProfileBar(isDark: isDark),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: switch (_mode) {
                      WorkspaceMode.act => _ActWorkspace(
                        key: const ValueKey('act-workspace'),
                        onComplete: _onComplete,
                        onMinimumAction: _onMinimumAction,
                      ),
                      WorkspaceMode.plan => _PlanWorkspace(
                        key: const ValueKey('plan-workspace'),
                        isDark: isDark,
                        onComplete: _onComplete,
                        onMinimumAction: _onMinimumAction,
                      ),
                      WorkspaceMode.progress => _ProgressWorkspace(
                        key: const ValueKey('progress-workspace'),
                        state: s,
                        isDark: isDark,
                        onOpenStats: () => showDialog(
                          context: context,
                          builder: (_) => StatsDialog(state: s),
                        ),
                        onOpenCalendar: () => showDialog(
                          context: context,
                          builder: (_) => CalendarDialog(state: s),
                        ),
                        onOpenBosses: () => showDialog(
                          context: context,
                          builder: (_) => BossesDialog(state: s),
                        ),
                        onOpenAchievements: () => showDialog(
                          context: context,
                          builder: (_) => AchievementsDialog(
                            achievements: s.achievements,
                            isDark: isDark,
                          ),
                        ),
                        onOpenHistory: () => showDialog(
                          context: context,
                          builder: (_) =>
                              HistoryDialog(history: s.history, isDark: isDark),
                        ),
                        onOpenRewards: () => _openRewardsDialog(s),
                      ),
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_rewardNotice != null)
            _RewardNoticePopover(
              notice: _rewardNotice!,
              anchor: _rewardNoticeAnchor,
              isDark: isDark,
              onShow: () => _openRewardsDialog(s),
              onHide: () => setState(() => _rewardNotice = null),
            ),
          ..._bubbles,
        ],
      ),
    );
  }
}

class _ActWorkspace extends StatelessWidget {
  final void Function(String taskId, Offset position) onComplete;
  final void Function(String taskId, Offset position) onMinimumAction;

  const _ActWorkspace({
    super.key,
    required this.onComplete,
    required this.onMinimumAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TodayDashboard(
          onComplete: onComplete,
          onMinimumAction: onMinimumAction,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _SkillTaskWorkspace(
            onComplete: onComplete,
            onMinimumAction: onMinimumAction,
          ),
        ),
      ],
    );
  }
}

class _PlanWorkspace extends StatelessWidget {
  final bool isDark;
  final void Function(String taskId, Offset position) onComplete;
  final void Function(String taskId, Offset position) onMinimumAction;

  const _PlanWorkspace({
    super.key,
    required this.isDark,
    required this.onComplete,
    required this.onMinimumAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModeHeader(
          isDark: isDark,
          icon: Icons.edit_note,
          color: const Color(0xFF4A9EFF),
          title: 'Планировать систему',
          subtitle:
              'Навыки, цели, квесты и дерево живут здесь. Это режим спокойной настройки, без давления “сделай сейчас”.',
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _SkillTaskWorkspace(
            onComplete: onComplete,
            onMinimumAction: onMinimumAction,
          ),
        ),
      ],
    );
  }
}

class _ProgressWorkspace extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenBosses;
  final VoidCallback onOpenAchievements;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenRewards;

  const _ProgressWorkspace({
    super.key,
    required this.state,
    required this.isDark,
    required this.onOpenStats,
    required this.onOpenCalendar,
    required this.onOpenBosses,
    required this.onOpenAchievements,
    required this.onOpenHistory,
    required this.onOpenRewards,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ProgressHubContent(
        state: state,
        isDark: isDark,
        subtitle:
            'Здесь живут аналитика, календарь, боссы, достижения и награды. Режим без срочности: только понять прогресс.',
        onOpenStats: onOpenStats,
        onOpenCalendar: onOpenCalendar,
        onOpenBosses: onOpenBosses,
        onOpenAchievements: onOpenAchievements,
        onOpenHistory: onOpenHistory,
        onOpenRewards: onOpenRewards,
      ),
    );
  }
}

class _SkillTaskWorkspace extends StatelessWidget {
  final void Function(String taskId, Offset position) onComplete;
  final void Function(String taskId, Offset position) onMinimumAction;

  const _SkillTaskWorkspace({
    required this.onComplete,
    required this.onMinimumAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 380, child: SkillsPanel()),
        const SizedBox(width: 12),
        Expanded(
          child: TasksPanel(
            onComplete: onComplete,
            onMinimumAction: onMinimumAction,
          ),
        ),
      ],
    );
  }
}

class _ModeHeader extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ModeHeader({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: surface(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: txt,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: sub, fontSize: 12.5, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardNotice {
  final List<String> chestTitles;
  final List<String> buffTitles;

  const _RewardNotice({required this.chestTitles, required this.buffTitles});

  bool get hasChests => chestTitles.isNotEmpty;
  bool get hasBuffs => buffTitles.isNotEmpty;

  String get title {
    if (hasChests && hasBuffs) return 'Награды обновлены';
    if (hasChests) {
      return chestTitles.length == 1 ? 'Получен сундук' : 'Получены сундуки';
    }
    return buffTitles.length == 1 ? 'Активирован бафф' : 'Активированы баффы';
  }

  String get subtitle {
    final parts = <String>[];
    if (hasChests) {
      parts.add(
        chestTitles.length == 1
            ? chestTitles.first
            : '${chestTitles.length} новых сундука',
      );
    }
    if (hasBuffs) {
      parts.add(
        buffTitles.length == 1
            ? buffTitles.first
            : '${buffTitles.length} активных баффа',
      );
    }
    return parts.join(' • ');
  }

  Color get color {
    if (hasChests) return const Color(0xFFFFCC00);
    return const Color(0xFF34C759);
  }

  IconData get icon {
    if (hasChests && hasBuffs) return Icons.auto_awesome;
    if (hasChests) return Icons.redeem;
    return Icons.bolt;
  }
}

class _RewardNoticePopover extends StatelessWidget {
  final _RewardNotice notice;
  final Offset? anchor;
  final bool isDark;
  final VoidCallback onShow;
  final VoidCallback onHide;

  const _RewardNoticePopover({
    required this.notice,
    required this.anchor,
    required this.isDark,
    required this.onShow,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    const width = 320.0;
    final fallbackAnchor = Offset(screenWidth - 190, 58);
    final resolvedAnchor = anchor ?? fallbackAnchor;
    final left = (resolvedAnchor.dx - width + 28).clamp(
      12.0,
      screenWidth - width - 12,
    );
    final top = resolvedAnchor.dy + 8;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Positioned(
      left: left,
      top: top,
      width: width,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, -10 * (1 - value)),
              child: Transform.scale(
                scale: 0.94 + value * 0.06,
                alignment: Alignment.topRight,
                child: child,
              ),
            ),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -5,
              right: 28,
              child: Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border(
                      left: BorderSide(color: bdr),
                      top: BorderSide(color: bdr),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: notice.color.withAlpha(90)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 110 : 36),
                    blurRadius: 22,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: notice.color.withAlpha(28),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(notice.icon, color: notice.color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notice.title,
                              style: TextStyle(
                                color: txt,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              notice.subtitle,
                              style: TextStyle(
                                color: sub,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _NoticeActionButton(
                          label: 'Скрыть',
                          color: sub,
                          isPrimary: false,
                          onTap: onHide,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NoticeActionButton(
                          label: 'Показать',
                          color: notice.color,
                          isPrimary: true,
                          onTap: onShow,
                        ),
                      ),
                    ],
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

class _NoticeActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _NoticeActionButton({
    required this.label,
    required this.color,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_NoticeActionButton> createState() => _NoticeActionButtonState();
}

class _NoticeActionButtonState extends State<_NoticeActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_pressed ? darken(widget.color) : widget.color)
                : widget.color.withAlpha(_pressed ? 34 : 22),
            borderRadius: BorderRadius.circular(10),
            border: widget.isPrimary
                ? null
                : Border.all(color: widget.color.withAlpha(55)),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.isPrimary ? Colors.white : widget.color,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
