part of '../main_page.dart';

class TopBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final AppState state;
  final WorkspaceMode mode;
  final ValueChanged<WorkspaceMode> onModeChanged;
  final GlobalKey? rewardsKey;
  final VoidCallback? onRewardsTap;
  final VoidCallback onStatsTap;
  final bool showModeSwitch;
  const TopBar({
    super.key,
    required this.isDark,
    required this.onToggle,
    required this.state,
    required this.mode,
    required this.onModeChanged,
    required this.onStatsTap,
    this.rewardsKey,
    this.onRewardsTap,
    this.showModeSwitch = true,
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
        : sub;
    final rewardsBadge = rewardsCount > 0 ? '$rewardsCount' : null;

    return Container(
      width: double.infinity,
      color: sfc,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final veryCompact = constraints.maxWidth < 560;
          final showCompactModeLabels =
              constraints.maxWidth >= 520 && constraints.maxWidth < 900;

          return Row(
            children: [
              const Icon(Icons.security, color: Color(0xFF4A9EFF), size: 18),
              if (!veryCompact) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 150 : 190),
                  child: Text(
                    'RPG To-Do List',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: txt,
                    ),
                  ),
                ),
              ],
              if (showModeSwitch) ...[
                SizedBox(width: compact ? 10 : 18),
                _WorkspaceModeSwitch(
                  mode: mode,
                  isDark: isDark,
                  compact: compact,
                  showCompactLabels: showCompactModeLabels,
                  onChanged: onModeChanged,
                ),
              ],
              const Spacer(),
              _TopBarPillButton(
                key: rewardsKey,
                icon: Icons.redeem,
                label: 'Трофеи',
                tooltip: rewardsCount > 0
                    ? 'Открыть новые сундуки'
                    : activeBuffsCount > 0
                    ? 'Посмотреть пассивные эффекты'
                    : 'Открыть трофеи после действий',
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
              _TopBarPillButton(
                icon: WorkspaceMode.stats.icon,
                label: WorkspaceMode.stats.label,
                tooltip: 'Открыть статистику роста',
                color: WorkspaceMode.stats.color,
                compact: compact,
                onTap: onStatsTap,
              ),
              const SizedBox(width: 8),
              HoverIconBtn(
                icon: state.sfxEnabled ? Icons.volume_up : Icons.volume_off,
                color: state.sfxEnabled ? sub : const Color(0xFFFF9500),
                tooltip: state.sfxEnabled
                    ? 'Выключить звуки интерфейса'
                    : 'Включить звуки интерфейса',
                onTap: state.toggleSfxEnabled,
              ),
              const SizedBox(width: 4),
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
  final bool showCompactLabels;
  final ValueChanged<WorkspaceMode> onChanged;

  const _WorkspaceModeSwitch({
    required this.mode,
    required this.isDark,
    required this.compact,
    this.showCompactLabels = false,
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
          for (final item in _primaryWorkspaceModes)
            _WorkspaceModeButton(
              mode: item,
              isDark: isDark,
              compact: compact,
              showCompactLabel: showCompactLabels,
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
  final bool showCompactLabel;
  final bool selected;
  final VoidCallback onTap;

  const _WorkspaceModeButton({
    required this.mode,
    required this.isDark,
    required this.compact,
    this.showCompactLabel = false,
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
      cursor: SystemMouseCursors.click,
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
          duration: kMotionFast,
          curve: kMotionCurve,
          child: AnimatedContainer(
            duration: kMotionStandard,
            curve: kMotionCurve,
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
                if (!widget.compact || widget.showCompactLabel) ...[
                  const SizedBox(width: 5),
                  Text(
                    widget.compact ? widget.mode.shortLabel : widget.mode.label,
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

class _MobileWorkspaceNav extends StatelessWidget {
  final WorkspaceMode mode;
  final bool isDark;
  final ValueChanged<WorkspaceMode> onChanged;

  const _MobileWorkspaceNav({
    required this.mode,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bdr = borderColor(isDark);
    final sub = subtext(isDark);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: surface(isDark),
          border: Border(top: BorderSide(color: bdr)),
        ),
        child: Row(
          children: [
            for (final item in _primaryWorkspaceModes)
              Expanded(
                child: PressFeedback(
                  scale: 0.96,
                  tooltip: item.label,
                  onTap: () => onChanged(item),
                  child: AnimatedContainer(
                    duration: kMotionStandard,
                    curve: kMotionCurve,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: item == mode
                          ? item.color.withAlpha(isDark ? 34 : 24)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: item == mode
                            ? item.color.withAlpha(75)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: item == mode ? item.color : sub,
                          size: 18,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.shortLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item == mode ? item.color : sub,
                            fontSize: 11,
                            fontWeight: item == mode
                                ? FontWeight.w900
                                : FontWeight.w700,
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
    );
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
      cursor: SystemMouseCursors.click,
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
          duration: kMotionFast,
          curve: kMotionCurve,
          child: AnimatedContainer(
            duration: kMotionStandard,
            curve: kMotionCurve,
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
                  AnimatedSwitcher(
                    duration: kMotionStandard,
                    switchInCurve: kMotionCurve,
                    switchOutCurve: kMotionExitCurve,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: kMotionCurve,
                        reverseCurve: kMotionExitCurve,
                      );

                      return FadeTransition(
                        opacity: curved,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.82,
                            end: 1,
                          ).animate(curved),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey(widget.badge),
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
