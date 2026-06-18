part of '../main_page.dart';

class _RewardNotice {
  final List<String> chestTitles;
  final List<String> buffTitles;
  final List<String> achievementTitles;

  const _RewardNotice({
    required this.chestTitles,
    required this.buffTitles,
    required this.achievementTitles,
  });

  bool get hasChests => chestTitles.isNotEmpty;
  bool get hasBuffs => buffTitles.isNotEmpty;
  bool get hasAchievements => achievementTitles.isNotEmpty;
  bool get hasConfettiMoment => hasChests || hasAchievements;

  String get title {
    if (hasAchievements && !hasChests && !hasBuffs) {
      return achievementTitles.length == 1
          ? 'Открыто достижение'
          : 'Открыты достижения';
    }
    if (hasChests && hasBuffs) return 'Трофеи обновлены';
    if (hasChests) {
      return chestTitles.length == 1 ? 'Получен сундук' : 'Получены сундуки';
    }
    return buffTitles.length == 1
        ? 'Пассивный эффект активен'
        : 'Пассивные эффекты активны';
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
            : '${buffTitles.length} пассивных эффекта',
      );
    }
    if (hasAchievements) {
      parts.add(
        achievementTitles.length == 1
            ? achievementTitles.first
            : '${achievementTitles.length} достижения',
      );
    }
    return parts.join(' • ');
  }

  Color get color {
    if (hasAchievements) return const Color(0xFFFFCC00);
    if (hasChests) return const Color(0xFFFFCC00);
    return const Color(0xFF34C759);
  }

  IconData get icon {
    if (hasAchievements) return Icons.emoji_events;
    if (hasChests && hasBuffs) return Icons.auto_awesome;
    if (hasChests) return Icons.redeem;
    return Icons.bolt;
  }
}

class _RewardNoticePopover extends StatefulWidget {
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
  State<_RewardNoticePopover> createState() => _RewardNoticePopoverState();
}

class _RewardNoticePopoverState extends State<_RewardNoticePopover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _autoHideTimer;
  bool _closing = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kMotionSlow)
      ..forward();
    _scheduleAutoHide();
  }

  @override
  void didUpdateWidget(covariant _RewardNoticePopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    final noticeChanged =
        oldWidget.notice.title != widget.notice.title ||
        oldWidget.notice.subtitle != widget.notice.subtitle;
    if (noticeChanged) {
      _closing = false;
      _controller.forward(from: 0);
      _scheduleAutoHide();
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoHide() {
    _autoHideTimer?.cancel();
    if (_hovered || _closing) return;
    _autoHideTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _hovered || _closing) return;
      _closeThen(widget.onHide);
    });
  }

  void _pauseAutoHide() {
    _hovered = true;
    _autoHideTimer?.cancel();
  }

  void _resumeAutoHide() {
    _hovered = false;
    _scheduleAutoHide();
  }

  Future<void> _closeThen(VoidCallback action) async {
    if (_closing) return;
    _closing = true;
    _autoHideTimer?.cancel();
    await _controller.reverse();
    if (!mounted) return;
    action();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = (screenWidth - 24).clamp(280.0, 320.0).toDouble();
    final fallbackAnchor = Offset(screenWidth - 190, 58);
    final resolvedAnchor = widget.anchor ?? fallbackAnchor;
    final maxLeft = screenWidth - width - 12;
    final left = maxLeft <= 12
        ? 12.0
        : (resolvedAnchor.dx - width + 28).clamp(12.0, maxLeft).toDouble();
    final top = resolvedAnchor.dy + 8;
    final bg = surface(widget.isDark);
    final txt = textColor(widget.isDark);
    final sub = subtext(widget.isDark);
    final bdr = borderColor(widget.isDark);

    return Positioned(
      left: left,
      top: top,
      width: width,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = kMotionCurve.transform(_controller.value);
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
        child: MouseRegion(
          onEnter: (_) => _pauseAutoHide(),
          onExit: (_) => _resumeAutoHide(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.notice.hasConfettiMoment)
                Positioned(
                  top: 3,
                  right: 48,
                  child: MilestoneConfettiBurst(
                    color: widget.notice.color,
                    alignment: Alignment.topCenter,
                    particles: 12,
                  ),
                ),
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
                  border: Border.all(color: widget.notice.color.withAlpha(90)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(widget.isDark ? 110 : 36),
                      blurRadius: 22,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: widget.notice.color.withAlpha(
                        widget.isDark ? 32 : 22,
                      ),
                      blurRadius: 26,
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
                        RewardGlowIcon(
                          icon: widget.notice.icon,
                          color: widget.notice.color,
                          size: 38,
                          iconSize: 20,
                          sparkle: true,
                          loop: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.notice.title,
                                style: TextStyle(
                                  color: txt,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.notice.subtitle,
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
                            onTap: () => _closeThen(widget.onHide),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NoticeActionButton(
                            label: 'Показать',
                            color: widget.notice.color,
                            isPrimary: true,
                            onTap: () => _closeThen(widget.onShow),
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
    final primaryTextColor =
        ThemeData.estimateBrightnessForColor(widget.color) == Brightness.light
        ? const Color(0xFF15151D)
        : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
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
            duration: kMotionFast,
            curve: kMotionCurve,
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
                color: widget.isPrimary ? primaryTextColor : widget.color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
