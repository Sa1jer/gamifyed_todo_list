import 'dart:async';

import 'package:flutter/material.dart';
import '../utils.dart';

const _kPanelRadius = 14.0;
const kMotionFast = Duration(milliseconds: 90);
const kMotionStandard = Duration(milliseconds: 180);
const kMotionSlow = Duration(milliseconds: 240);
const kMotionProgress = Duration(milliseconds: 560);
const kMotionListStaggerStep = Duration(milliseconds: 14);
const kMotionListStaggerMaxIndex = 6;
const kMotionCurve = Curves.easeOutCubic;
const kMotionExitCurve = Curves.easeInCubic;

class AppPanel extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const AppPanel({super.key, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface(isDark),
        borderRadius: BorderRadius.circular(_kPanelRadius),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: child,
    );
  }
}

class PanelDivider extends StatelessWidget {
  final bool isDark;

  const PanelDivider({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: borderColor(isDark));
  }
}

class EmptyStateMessage extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateMessage({
    super.key,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final txt = textColor(isDark);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: sub, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: txt.withAlpha(isDark ? 220 : 230),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: sub.withAlpha(160), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRESS FEEDBACK WRAPPER
// ═══════════════════════════════════════════════════════════════════════════════

class PressFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final String? tooltip;
  const PressFeedback({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.96,
    this.tooltip,
  });
  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) {
        setState(() => _p = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? widget.scale : 1.0,
        duration: kMotionFast,
        curve: kMotionCurve,
        child: AnimatedOpacity(
          opacity: _p ? 0.86 : 1.0,
          duration: kMotionFast,
          child: widget.child,
        ),
      ),
    );

    final interactiveButton = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: button,
    );

    if (widget.tooltip == null) return interactiveButton;
    return Tooltip(message: widget.tooltip!, child: interactiveButton);
  }
}

class HoverScale extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Alignment alignment;
  const HoverScale({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.duration = kMotionStandard,
    this.alignment = Alignment.center,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _h = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: AnimatedScale(
      scale: _h ? widget.scale : 1.0,
      alignment: widget.alignment,
      duration: widget.duration,
      curve: kMotionCurve,
      child: widget.child,
    ),
  );
}

class MotionFadeSlideSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Offset offset;
  final Alignment alignment;

  const MotionFadeSlideSwitcher({
    super.key,
    required this.child,
    this.duration = kMotionSlow,
    this.offset = const Offset(0, 0.025),
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: kMotionStandard,
      switchInCurve: kMotionCurve,
      switchOutCurve: kMotionExitCurve,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: alignment,
          children: [...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: kMotionCurve,
          reverseCurve: kMotionExitCurve,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: offset,
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class MotionExpandable extends StatelessWidget {
  final bool expanded;
  final Widget expandedChild;
  final Widget collapsedChild;
  final Duration duration;

  const MotionExpandable({
    super.key,
    required this.expanded,
    required this.expandedChild,
    this.collapsedChild = const SizedBox.shrink(),
    this.duration = kMotionSlow,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: kMotionCurve,
      alignment: Alignment.topCenter,
      child: MotionFadeSlideSwitcher(
        duration: duration,
        child: KeyedSubtree(
          key: ValueKey(expanded),
          child: expanded ? expandedChild : collapsedChild,
        ),
      ),
    );
  }
}

class MotionListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final bool enabled;
  final double slide;
  final Duration duration;
  final Duration staggerStep;
  final int maxStaggerIndex;

  const MotionListItem({
    super.key,
    required this.child,
    required this.index,
    this.enabled = true,
    this.slide = 8,
    this.duration = kMotionSlow,
    this.staggerStep = kMotionListStaggerStep,
    this.maxStaggerIndex = kMotionListStaggerMaxIndex,
  });

  @override
  State<MotionListItem> createState() => _MotionListItemState();
}

class _MotionListItemState extends State<MotionListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.enabled ? 0 : 1,
    );
    _animation = CurvedAnimation(parent: _controller, curve: kMotionCurve);
    if (widget.enabled) {
      final maxIndex = widget.maxStaggerIndex < 0 ? 0 : widget.maxStaggerIndex;
      final staggerIndex = widget.index.clamp(0, maxIndex).toInt();
      final delayMs = staggerIndex * widget.staggerStep.inMilliseconds;
      if (delayMs == 0) {
        _controller.forward();
      } else {
        _delayTimer = Timer(Duration(milliseconds: delayMs), () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant MotionListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.enabled != widget.enabled) {
      _delayTimer?.cancel();
      if (widget.enabled) {
        _controller.forward(from: 0);
      } else {
        _controller.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final value = widget.enabled ? _animation.value : 1.0;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, widget.slide * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SMALL BUTTON  (solid color, press = scale + darken)
// ═══════════════════════════════════════════════════════════════════════════════

class SmallBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;
  const SmallBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
  @override
  State<SmallBtn> createState() => _SmallBtnState();
}

class _SmallBtnState extends State<SmallBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) {
        setState(() => _p = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.96 : 1.0,
        duration: kMotionFast,
        curve: kMotionCurve,
        child: AnimatedContainer(
          duration: kMotionFast,
          curve: kMotionCurve,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _p ? darken(widget.color) : widget.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 15),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MINI ICON BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class MiniBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;
  const MiniBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
  @override
  State<MiniBtn> createState() => _MiniBtnState();
}

class _MiniBtnState extends State<MiniBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) {
        setState(() => _p = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.92 : 1.0,
        duration: kMotionFast,
        curve: kMotionCurve,
        child: AnimatedOpacity(
          opacity: _p ? 0.75 : 1.0,
          duration: kMotionFast,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(widget.icon, size: 17, color: widget.color),
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOVER ICON BUTTON (TopBar)
// ═══════════════════════════════════════════════════════════════════════════════

class HoverIconBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;
  const HoverIconBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
  @override
  State<HoverIconBtn> createState() => _HoverIconBtnState();
}

class _HoverIconBtnState extends State<HoverIconBtn> {
  bool _h = false, _p = false;
  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() {
        _h = false;
        _p = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _p = true),
        onTapUp: (_) {
          setState(() => _p = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _p = false),
        child: AnimatedScale(
          scale: _p ? 0.94 : 1.0,
          duration: kMotionFast,
          curve: kMotionCurve,
          child: AnimatedContainer(
            duration: kMotionStandard,
            curve: kMotionCurve,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _h || _p ? widget.color.withAlpha(24) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED XP BAR
// ═══════════════════════════════════════════════════════════════════════════════

class XPBar extends StatefulWidget {
  final double progress;
  final Color color;
  final double height;
  const XPBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 8,
  });
  @override
  State<XPBar> createState() => _XPBarState();
}

class _XPBarState extends State<XPBar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  double _prev = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kMotionProgress);
    _a = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).chain(CurveTween(curve: kMotionCurve)).animate(_c);
    _prev = widget.progress;
    _c.forward();
  }

  @override
  void didUpdateWidget(XPBar old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _a = Tween<double>(
        begin: _prev,
        end: widget.progress,
      ).chain(CurveTween(curve: kMotionCurve)).animate(_c);
      _prev = widget.progress;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, child) => ClipRRect(
      borderRadius: BorderRadius.circular(widget.height / 2),
      child: LinearProgressIndicator(
        value: _a.value.clamp(0.0, 1.0),
        minHeight: widget.height,
        backgroundColor: widget.color.withAlpha(35),
        valueColor: AlwaysStoppedAnimation(widget.color),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEVEL BADGE
// ═══════════════════════════════════════════════════════════════════════════════

class RankBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const RankBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 10.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withAlpha(65)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class LvlBadge extends StatelessWidget {
  final int level;
  final Color color;
  const LvlBadge({super.key, required this.level, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withAlpha(30),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withAlpha(80)),
    ),
    child: Text(
      'Ур. $level',
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// BADGE (small colored label)
// ═══════════════════════════════════════════════════════════════════════════════

class TaskBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const TaskBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// FLOATING XP BUBBLE
// ═══════════════════════════════════════════════════════════════════════════════

class XPBubble extends StatefulWidget {
  final String message;
  final Offset position;
  final bool showMilestoneConfetti;
  final Widget Function(Color color)? confettiBuilder;
  final Function(Key?) onDone;
  const XPBubble({
    super.key,
    required this.message,
    required this.position,
    this.showMilestoneConfetti = false,
    this.confettiBuilder,
    required this.onDone,
  });
  @override
  State<XPBubble> createState() => _XPBubbleState();
}

class _XPBubbleState extends State<XPBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _lift, _opacity, _scale;
  late _XPBubbleTone _tone;

  @override
  void initState() {
    super.initState();
    _tone = _XPBubbleTone.fromMessage(widget.message);
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    final curved = CurvedAnimation(parent: _c, curve: kMotionCurve);
    _lift = Tween<double>(begin: 8, end: -58).animate(curved);
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 14),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 58),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 28),
    ]).animate(_c);
    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.04),
        weight: 18,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.04, end: 1), weight: 22),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 60),
    ]).animate(curved);
    _c.forward().then((_) => widget.onDone(widget.key));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF15151D) : Colors.white;
    final txt = isDark ? const Color(0xFFF4F4F8) : const Color(0xFF1B1B22);
    final sub = isDark ? const Color(0xFF9A9AA6) : const Color(0xFF5F6370);
    final screen = MediaQuery.sizeOf(context);

    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final maxLeft = screen.width > 356 ? screen.width - 332 : 12.0;
        final maxTop = screen.height > 104 ? screen.height - 92 : 12.0;
        final left = (widget.position.dx - 154).clamp(12.0, maxLeft);
        final top = (widget.position.dy + _lift.value - 4).clamp(12.0, maxTop);

        return Positioned(
          left: left.toDouble(),
          top: top.toDouble(),
          child: IgnorePointer(
            child: Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _tone.color.withAlpha(95)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 95 : 24),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(color: _tone.color.withAlpha(42), blurRadius: 22),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _tone.color.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_tone.icon, color: _tone.color, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tone.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: txt,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tone.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: sub,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showMilestoneConfetti && widget.confettiBuilder != null)
            Positioned(
              left: 150,
              top: -4,
              child: SizedBox(
                width: 1,
                height: 1,
                child: widget.confettiBuilder!(_tone.color),
              ),
            ),
        ],
      ),
    );
  }
}

class _XPBubbleTone {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _XPBubbleTone({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  factory _XPBubbleTone.fromMessage(String message) {
    final cleaned = message
        .replaceAll('🎉', '')
        .replaceAll('🏅', '')
        .replaceAll('⬆️', '')
        .trim();
    final lines = cleaned
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final customTitle = lines.length > 1 ? lines.first : null;
    final customSubtitle = lines.length > 1 ? lines.skip(1).join(' ') : cleaned;
    final lower = cleaned.toLowerCase();

    if (lower.contains('ранг')) {
      return _XPBubbleTone(
        icon: Icons.workspace_premium,
        color: const Color(0xFFFFCC00),
        title: customTitle ?? 'Новый ранг',
        subtitle: customSubtitle,
      );
    }

    if (lower.contains('уровень')) {
      return _XPBubbleTone(
        icon: Icons.workspace_premium,
        color: const Color(0xFFFFCC00),
        title: customTitle ?? 'Новый рубеж',
        subtitle: customSubtitle,
      );
    }

    if (lower.contains('окреп') ||
        lower.contains('ур.') ||
        lower.contains('→')) {
      return _XPBubbleTone(
        icon: Icons.trending_up,
        color: const Color(0xFFFF9500),
        title: customTitle ?? 'Навык вырос',
        subtitle: customSubtitle,
      );
    }

    if (lower.contains('босс') || lower.contains('сопротивлен')) {
      return _XPBubbleTone(
        icon: Icons.shield,
        color: const Color(0xFFFF2D55),
        title: customTitle ?? 'Сопротивление ослабло',
        subtitle: customSubtitle,
      );
    }

    if (lower.contains('старт')) {
      return _XPBubbleTone(
        icon: Icons.play_circle_fill,
        color: const Color(0xFF4A9EFF),
        title: customTitle ?? 'Лёгкий старт',
        subtitle: customSubtitle,
      );
    }

    if (lower.contains('бафф') || lower.contains('пассивн')) {
      return _XPBubbleTone(
        icon: Icons.bolt,
        color: const Color(0xFF34C759),
        title: customTitle ?? 'Эффект сработал',
        subtitle: customSubtitle,
      );
    }

    return _XPBubbleTone(
      icon: Icons.auto_awesome,
      color: const Color(0xFF4A9EFF),
      title: customTitle ?? 'Опыт получен',
      subtitle: customSubtitle,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DIALOG SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class DlgHeader extends StatelessWidget {
  final String title;
  final Color txtColor;
  const DlgHeader({super.key, required this.title, required this.txtColor});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: txtColor,
          fontSize: 18,
        ),
      ),
      const Spacer(),
      PressFeedback(
        scale: 0.82,
        tooltip: 'Закрыть',
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.close, color: Color(0xFF8E8E93), size: 22),
      ),
    ],
  );
}

class DlgField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final Color fBg, txt, sub, bdr;
  final int min;
  const DlgField({
    super.key,
    required this.label,
    required this.ctrl,
    required this.fBg,
    required this.txt,
    required this.sub,
    required this.bdr,
    this.min = 1,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SubLbl(label, sub),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: fBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bdr),
        ),
        child: TextField(
          controller: ctrl,
          style: TextStyle(color: txt, fontSize: 14),
          minLines: min,
          maxLines: min == 1 ? 1 : 4,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    ],
  );
}

class DlgActions extends StatelessWidget {
  final VoidCallback onCancel, onSave;
  final String saveLabel;
  const DlgActions({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = 'Сохранить',
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      PressFeedback(
        onTap: onCancel,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(45),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Отмена',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      PressFeedback(
        onTap: onSave,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF4A9EFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            saveLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    ],
  );
}

class SubLbl extends StatelessWidget {
  final String text;
  final Color color;
  const SubLbl(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
  );
}
