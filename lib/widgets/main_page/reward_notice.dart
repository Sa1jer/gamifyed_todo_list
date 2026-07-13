part of '../main_page.dart';

class _RewardNotice {
  final int id;
  final List<String> chestTitles;
  final List<String> buffTitles;
  final List<String> achievementTitles;

  const _RewardNotice({
    required this.id,
    required this.chestTitles,
    required this.buffTitles,
    required this.achievementTitles,
  });

  bool get hasChests => chestTitles.isNotEmpty;
  bool get hasBuffs => buffTitles.isNotEmpty;
  bool get hasAchievements => achievementTitles.isNotEmpty;

  String get signature => [
    ...chestTitles.map((title) => 'chest:$title'),
    ...buffTitles.map((title) => 'buff:$title'),
    ...achievementTitles.map((title) => 'achievement:$title'),
  ].join('\u0000');

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

  Color get color => hasAchievements || hasChests
      ? const Color(0xFFFFCC00)
      : const Color(0xFF34C759);

  IconData get icon => hasAchievements
      ? Icons.emoji_events
      : hasChests
      ? Icons.redeem
      : Icons.bolt;
}

class _RewardNoticePopover extends StatefulWidget {
  final _RewardNotice notice;
  final bool isDark;
  final bool desktop;
  final DesktopResponsiveMetrics desktopMetrics;
  final bool reducedMotion;
  final int queuedCount;
  final VoidCallback onShow;
  final VoidCallback onHide;

  const _RewardNoticePopover({
    required this.notice,
    required this.isDark,
    required this.desktop,
    required this.desktopMetrics,
    required this.reducedMotion,
    required this.queuedCount,
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
  bool _hovered = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.reducedMotion ? Duration.zero : kMotionStandard,
    )..forward();
    _scheduleAutoHide();
  }

  @override
  void didUpdateWidget(covariant _RewardNoticePopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notice.id != widget.notice.id) {
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
    _autoHideTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    if (!mounted || _hovered || _closing) return;
    _closing = true;
    _controller.reverse().then((_) {
      if (mounted) widget.onHide();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxCardWidth = widget.desktop ? 340.0 : 360.0;
    final cardWidth = (width - 24).clamp(260.0, maxCardWidth).toDouble();
    final right = widget.desktop && widget.desktopMetrics.showRightRail
        ? widget.desktopMetrics.railWidth +
              widget.desktopMetrics.sectionGap +
              16
        : 12.0;
    final top = widget.desktop ? 16.0 : 118.0;
    final bg = surface(widget.isDark);
    final txt = textColor(widget.isDark);
    final sub = subtext(widget.isDark);

    return Positioned(
      top: top,
      right: right,
      width: cardWidth,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _controller.value,
          child: Transform.scale(
            scale: 0.98 + _controller.value * 0.02,
            alignment: Alignment.topRight,
            child: child,
          ),
        ),
        child: MouseRegion(
          onEnter: (_) {
            _hovered = true;
            _autoHideTimer?.cancel();
          },
          onExit: (_) {
            _hovered = false;
            _scheduleAutoHide();
          },
          child: Semantics(
            button: true,
            label: '${widget.notice.title}. ${widget.notice.subtitle}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: widget.onShow,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.notice.color.withAlpha(94),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(widget.isDark ? 85 : 22),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: widget.notice.color.withAlpha(
                            widget.isDark ? 30 : 22,
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          widget.notice.icon,
                          color: widget.notice.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.notice.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: txt,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.notice.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: sub,
                                fontSize: 11.5,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.queuedCount > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.notice.color.withAlpha(28),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+${widget.queuedCount - 1}',
                            style: TextStyle(
                              color: widget.notice.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      IconButton(
                        tooltip: 'Скрыть уведомление',
                        onPressed: _dismiss,
                        icon: Icon(Icons.close, color: sub, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
