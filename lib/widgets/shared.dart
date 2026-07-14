import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models.dart';
import '../utils.dart';
import 'mobile_journal_tokens.dart';

const _kPanelRadius = 14.0;
const kMotionFast = Duration(milliseconds: 90);
const kMotionStandard = Duration(milliseconds: 180);
const kMotionSlow = Duration(milliseconds: 240);
const kMotionProgress = Duration(milliseconds: 560);
const kMotionXp = Duration(milliseconds: 840);
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
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
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
  final Color? backgroundColor;
  final int? level;
  const XPBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 8,
    this.backgroundColor,
    this.level,
  });
  @override
  State<XPBar> createState() => _XPBarState();
}

class _XPBarState extends State<XPBar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  late double _target;

  @override
  void initState() {
    super.initState();
    _target = widget.progress.clamp(0.0, 1.0);
    _c = AnimationController(vsync: this, duration: kMotionXp, value: 1);
    _a = AlwaysStoppedAnimation(_target);
  }

  @override
  void didUpdateWidget(XPBar old) {
    super.didUpdateWidget(old);
    final target = widget.progress.clamp(0.0, 1.0);
    if (old.progress != widget.progress || old.level != widget.level) {
      final reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final displayed = _a.value.clamp(0.0, 1.0);
      _target = target;
      if (reducedMotion) {
        _c.value = 1;
        _a = AlwaysStoppedAnimation(target);
        return;
      }

      final isLevelUp =
          old.level != null &&
          widget.level != null &&
          widget.level! > old.level!;
      final isLevelDown =
          old.level != null &&
          widget.level != null &&
          widget.level! < old.level!;
      _a =
          (isLevelUp
                  ? TweenSequence<double>([
                      TweenSequenceItem(
                        tween: Tween(
                          begin: displayed,
                          end: 1.0,
                        ).chain(CurveTween(curve: kMotionCurve)),
                        weight: 58,
                      ),
                      TweenSequenceItem(
                        tween: Tween(
                          begin: 0.0,
                          end: target,
                        ).chain(CurveTween(curve: kMotionCurve)),
                        weight: 42,
                      ),
                    ])
                  : isLevelDown
                  ? TweenSequence<double>([
                      TweenSequenceItem(
                        tween: Tween(
                          begin: displayed,
                          end: 0.0,
                        ).chain(CurveTween(curve: kMotionCurve)),
                        weight: 42,
                      ),
                      TweenSequenceItem(
                        tween: Tween(
                          begin: 1.0,
                          end: target,
                        ).chain(CurveTween(curve: kMotionCurve)),
                        weight: 58,
                      ),
                    ])
                  : Tween<double>(
                      begin: displayed,
                      end: target,
                    ).chain(CurveTween(curve: kMotionCurve)))
              .animate(_c);
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) {
        final value = reducedMotion ? _target : _a.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: widget.height,
            backgroundColor:
                widget.backgroundColor ?? widget.color.withAlpha(35),
            valueColor: AlwaysStoppedAnimation(widget.color),
          ),
        );
      },
    );
  }
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

class XpRewardPill extends StatelessWidget {
  final int xp;
  final bool isDark;
  final bool isReversal;

  const XpRewardPill({
    super.key,
    required this.xp,
    required this.isDark,
    this.isReversal = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = xp < 0 ? -xp : xp;
    final copy = '${isReversal ? '-' : '+'}$value XP';
    final foreground = MobileJournalTokens.rewardGoldForeground(isDark);
    return Semantics(
      label: isReversal ? 'Откат $value XP' : 'Награда $value XP',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: MobileJournalTokens.rewardGoldBackground(isDark),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: MobileJournalTokens.rewardGoldBorder(isDark),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 13, color: foreground),
            const SizedBox(width: 3),
            Text(
              copy,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color? backgroundColor;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const DashedBorderContainer({
    super.key,
    required this.child,
    required this.color,
    this.backgroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.strokeWidth = 1.2,
    this.dashLength = 7,
    this.gapLength = 5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: const ValueKey('dashed-border-painter'),
      foregroundPainter: _DashedRoundedRectPainter(
        color: color,
        radius: borderRadius.topLeft.x,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const _DashedRoundedRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final inset = strokeWidth / 2;
    final rect = (Offset.zero & size).deflate(inset);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(math.max(0, radius - inset)),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashLength != oldDelegate.dashLength ||
      gapLength != oldDelegate.gapLength;
}

class InboxTaskCountBubble extends StatelessWidget {
  final int count;
  final Color color;
  final bool isDark;
  final double size;

  const InboxTaskCountBubble({
    super.key,
    required this.count,
    required this.color,
    required this.isDark,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Активных быстрых задач',
      value: '$count',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 34 : 22),
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(isDark ? 105 : 82)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: size * 0.46,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class TaskTitleWithDescription extends StatelessWidget {
  final Task task;
  final TextStyle titleStyle;
  final Color descriptionColor;
  final int maxLines;
  final TextDecoration? titleDecoration;
  final Color? decorationColor;

  const TaskTitleWithDescription({
    super.key,
    required this.task,
    required this.titleStyle,
    required this.descriptionColor,
    this.maxLines = 2,
    this.titleDecoration,
    this.decorationColor,
  });

  @override
  Widget build(BuildContext context) {
    final description = task.description.trim();
    final effectiveTitleStyle = titleStyle.copyWith(
      decoration: titleDecoration,
      decorationColor: decorationColor,
    );
    if (description.isEmpty) {
      return Text(
        task.title,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: effectiveTitleStyle,
      );
    }
    return Text.rich(
      TextSpan(
        text: task.title,
        style: effectiveTitleStyle,
        children: [
          TextSpan(
            text: '  $description',
            style: titleStyle.copyWith(
              color: descriptionColor,
              fontSize: (titleStyle.fontSize ?? 14) * 0.86,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
              height: titleStyle.height,
            ),
          ),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FLOATING XP BUBBLE
// ═══════════════════════════════════════════════════════════════════════════════

CompletionToastColors completionToastColorsForTask({
  required Task? task,
  required Iterable<Skill> skills,
}) {
  if (task == null) return const CompletionToastColors.fallback();
  if (task.isInbox) return CompletionToastColors.resolve(isInbox: true);
  for (final skill in skills) {
    if (skill.id == task.skillId) {
      return CompletionToastColors.resolve(skillColor: skill.color);
    }
  }
  return const CompletionToastColors.fallback();
}

enum ActionToastOriginKind {
  /// Used only when no actionable control exists, such as keyboard fallback.
  questRow,
  questCheckbox,
  minimumAction,
  focusTask,
  roadmapInspectorTask,
  roadmapCanvasNode,
  inboxTask,
  fallback,
}

enum ActionToastZone {
  mainWorkspace,
  rightRail,
  roadmapCanvas,
  roadmapInspector,
  mobileContent,
  mobileBottomContextual,
  fallback,
}

/// Presentation-only completion source. It intentionally stores the action
/// control's global bounds instead of a pointer coordinate: keyboard and mouse
/// activation therefore share a stable visual origin.
@immutable
class ActionToastOrigin {
  final Rect globalSourceRect;
  final ActionToastOriginKind kind;
  final ActionToastZone zone;
  final String? sourceId;
  final int eventSeed;

  const ActionToastOrigin({
    required this.globalSourceRect,
    required this.kind,
    required this.zone,
    this.sourceId,
    this.eventSeed = 0,
  });

  bool get hasSourceRect => !globalSourceRect.isEmpty;

  ActionToastOrigin withEventSeed(int seed) => ActionToastOrigin(
    globalSourceRect: globalSourceRect,
    kind: kind,
    zone: zone,
    sourceId: sourceId,
    eventSeed: seed,
  );
}

ActionToastOrigin actionToastOriginForContext(
  BuildContext context, {
  required ActionToastOriginKind kind,
  required ActionToastZone zone,
  String? sourceId,
}) {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox &&
      renderObject.hasSize &&
      renderObject.attached) {
    return ActionToastOrigin(
      globalSourceRect:
          renderObject.localToGlobal(Offset.zero) & renderObject.size,
      kind: kind,
      zone: zone,
      sourceId: sourceId,
    );
  }
  return ActionToastOrigin(
    globalSourceRect: Rect.zero,
    kind: ActionToastOriginKind.fallback,
    zone: ActionToastZone.fallback,
    sourceId: sourceId,
  );
}

/// Transitional adapter for legacy leaf widgets that still expose a global
/// interaction position. New controls must create origins from their own
/// [BuildContext] so the placement resolver can use real action bounds.
ActionToastOrigin legacyActionToastOrigin(
  Offset globalPosition, {
  required ActionToastZone zone,
  ActionToastOriginKind kind = ActionToastOriginKind.fallback,
  String? sourceId,
}) {
  return ActionToastOrigin(
    globalSourceRect: Rect.fromCenter(
      center: globalPosition,
      width: 1,
      height: 1,
    ),
    kind: kind,
    zone: zone,
    sourceId: sourceId,
  );
}

@immutable
class ActionToastPlacement {
  static const double edgeInset = 12;
  static const double estimatedWidth = 260;
  static const double estimatedHeight = 104;

  final Offset topLeft;
  final double maxWidth;

  const ActionToastPlacement(this.topLeft, {this.maxWidth = estimatedWidth});

  /// Local visual envelope around the control that started the completion.
  /// The envelope is deliberately based on the control type, never on the
  /// containing task row or workspace.
  static ActionToastSpawnPolicy policyFor(
    ActionToastOriginKind kind,
    ActionToastZone zone,
  ) {
    switch (zone) {
      case ActionToastZone.rightRail:
      case ActionToastZone.roadmapInspector:
        return const ActionToastSpawnPolicy(
          preferredDistance: 150,
          hardDistance: 190,
          jitterX: 10,
          jitterY: 8,
        );
      case ActionToastZone.roadmapCanvas:
        return const ActionToastSpawnPolicy(
          preferredDistance: 170,
          hardDistance: 230,
          jitterX: 14,
          jitterY: 10,
        );
      case ActionToastZone.mobileContent:
      case ActionToastZone.mobileBottomContextual:
        return const ActionToastSpawnPolicy(
          preferredDistance: 140,
          hardDistance: 190,
          jitterX: 8,
          jitterY: 6,
        );
      case ActionToastZone.mainWorkspace:
      case ActionToastZone.fallback:
        return const ActionToastSpawnPolicy(
          preferredDistance: 160,
          hardDistance: 210,
          jitterX: 12,
          jitterY: 9,
        );
    }
  }

  /// Resolves once, when the completion event is received. `XPBubble` only
  /// consumes the result, so rebuilds cannot move the toast or re-roll jitter.
  factory ActionToastPlacement.resolve({
    required Rect sourceRect,
    required ActionToastOriginKind kind,
    required ActionToastZone zone,
    required Size viewport,
    Rect? safeRegion,
    Offset jitter = Offset.zero,
    double bottomReserved = 0,
  }) {
    final viewportBounds = Offset.zero & viewport;
    final requestedRegion = safeRegion ?? viewportBounds;
    final boundedRegion = requestedRegion.intersect(viewportBounds);
    final available =
        boundedRegion.width > edgeInset * 2 &&
            boundedRegion.height > edgeInset * 2
        ? boundedRegion.deflate(edgeInset)
        : viewportBounds.deflate(edgeInset);
    final toastWidth = math.min(estimatedWidth, available.width);
    final maxLeft = math.max(available.left, available.right - toastWidth);
    final maxTop = math.max(
      available.top,
      available.bottom - bottomReserved - estimatedHeight,
    );
    const gap = 14.0;
    // A source-less event is a keyboard/fallback interaction. It is the only
    // case allowed to use the local safe-region centre; pointer paths always
    // provide the concrete action-control rect before mutating AppState.
    final source = sourceRect.isEmpty
        ? Rect.fromCenter(center: available.center, width: 1, height: 1)
        : sourceRect;
    final policy = policyFor(kind, zone);
    final prefersBelow =
        kind == ActionToastOriginKind.minimumAction ||
        kind == ActionToastOriginKind.roadmapCanvasNode;
    final aboveRight = Offset(
      source.right + gap,
      source.top - estimatedHeight - gap,
    );
    final aboveLeft = Offset(
      source.left - toastWidth - gap,
      source.top - estimatedHeight - gap,
    );
    final belowRight = Offset(source.right + gap, source.bottom + gap);
    final belowLeft = Offset(
      source.left - toastWidth - gap,
      source.bottom + gap,
    );
    final candidates = <Offset>[
      if (prefersBelow) belowRight else aboveRight,
      if (prefersBelow) belowLeft else aboveLeft,
      if (prefersBelow) aboveRight else belowRight,
      if (prefersBelow) aboveLeft else belowLeft,
    ].map((candidate) => candidate + jitter).toList();

    bool fits(Offset topLeft) {
      final rect = topLeft & Size(toastWidth, estimatedHeight);
      final isInside =
          rect.left >= available.left &&
          rect.right <= available.right &&
          rect.top >= available.top &&
          rect.bottom <= available.bottom - bottomReserved;
      return isInside &&
          !rect.overlaps(source) &&
          (rect.center - source.center).distance <= policy.hardDistance;
    }

    for (final candidate in candidates) {
      if (fits(candidate)) {
        return ActionToastPlacement(candidate, maxWidth: toastWidth);
      }
    }

    // Clamp each local candidate and choose the closest valid local outcome.
    // This never falls back to the centre of the workspace for a pointer event.
    final clamped = candidates
        .map(
          (candidate) => Offset(
            candidate.dx.clamp(available.left, maxLeft),
            candidate.dy.clamp(available.top, maxTop),
          ),
        )
        .map((topLeft) => topLeft & Size(toastWidth, estimatedHeight))
        .where((rect) => !rect.overlaps(source))
        .where(
          (rect) =>
              (rect.center - source.center).distance <= policy.hardDistance,
        )
        .toList();
    if (clamped.isNotEmpty) {
      clamped.sort((a, b) {
        final aDistance = (a.center - source.center).distance;
        final bDistance = (b.center - source.center).distance;
        final aScore = (aDistance - policy.preferredDistance).abs();
        final bScore = (bDistance - policy.preferredDistance).abs();
        return aScore == bScore
            ? aDistance.compareTo(bDistance)
            : aScore.compareTo(bScore);
      });
      return ActionToastPlacement(clamped.first.topLeft, maxWidth: toastWidth);
    }

    // Extremely constrained regions can leave no non-overlapping candidate.
    // Stay adjacent to the actual control rather than jumping to a broad zone.
    final fallback = candidates.first;
    return ActionToastPlacement(
      Offset(
        fallback.dx.clamp(available.left, maxLeft),
        fallback.dy.clamp(available.top, maxTop),
      ),
      maxWidth: toastWidth,
    );
  }

  static Offset stableJitter(
    int seed,
    ActionToastOriginKind kind,
    ActionToastZone zone,
  ) {
    // Deterministic, bounded event variation. It is intentionally calculated
    // outside widget build and stays small on constrained regions.
    final policy = policyFor(kind, zone);
    final x = ((seed * 37) % 25) - 12;
    final y = ((seed * 19) % 19) - 9;
    return Offset(
      x.clamp(-policy.jitterX, policy.jitterX).toDouble(),
      y.clamp(-policy.jitterY, policy.jitterY).toDouble(),
    );
  }
}

@immutable
class ActionToastSpawnPolicy {
  final double preferredDistance;
  final double hardDistance;
  final double jitterX;
  final double jitterY;

  const ActionToastSpawnPolicy({
    required this.preferredDistance,
    required this.hardDistance,
    required this.jitterX,
    required this.jitterY,
  });
}

@immutable
class CompletionToastContent {
  final IconData icon;
  final String title;
  final String? skillName;
  final int? baseXp;
  final int? bonusXp;
  final String? detail;
  final String? nextLevelHint;

  const CompletionToastContent({
    required this.icon,
    required this.title,
    this.skillName,
    this.baseXp,
    this.bonusXp,
    this.detail,
    this.nextLevelHint,
  });

  factory CompletionToastContent.fromMessage(String message) {
    final cleaned = message
        .replaceAll('🎉', '')
        .replaceAll('🏅', '')
        .replaceAll('⬆️', '')
        .trim();
    final lower = cleaned.toLowerCase();
    final lines = cleaned
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final raw = lines.length > 1 ? lines.skip(1).join(' ') : cleaned;
    final parts = raw
        .split('•')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final bonusMatch = RegExp(
      r'эффект\s*\+(\d+)\s*XP',
      caseSensitive: false,
    ).firstMatch(raw);
    final totalMatch = RegExp(r'\+(\d+)\s*XP').firstMatch(raw);
    final totalXp = totalMatch == null
        ? null
        : int.tryParse(totalMatch.group(1)!);
    final bonusXp = bonusMatch == null
        ? null
        : int.tryParse(bonusMatch.group(1)!);
    final baseXp = totalXp == null
        ? null
        : math.max(0, totalXp - (bonusXp ?? 0));
    final remainingMatch = RegExp(
      r'до\s+ур\.?\s*\d+\s+(\d+)\s*XP',
      caseSensitive: false,
    ).firstMatch(raw);
    final remaining = remainingMatch == null
        ? null
        : int.tryParse(remainingMatch.group(1)!);
    final nextLevelHint = remaining != null && remaining > 0 && remaining < 100
        ? 'До следующего уровня $remaining XP'
        : null;

    final isQuickAction = lower.contains('быстрое действие');
    final isSkillGrowth =
        lower.contains('навык окреп') ||
        lower.contains('навык вырос') ||
        lower.contains('окреп до ур');
    final isLevelUp = lower.contains('новый уровень') && !isSkillGrowth;
    String? skillName;
    if (isSkillGrowth || isLevelUp) {
      final candidate = parts.firstWhere(
        (part) =>
            part.toLowerCase().contains('окреп') ||
            (part.contains('+') && !part.toLowerCase().contains('эффект')),
        orElse: () => '',
      );
      final name = candidate
          .replaceFirst(
            RegExp(r'\s+окреп\s+до\s+ур\.?\s*\d+.*$', caseSensitive: false),
            '',
          )
          .replaceFirst(RegExp(r'\+\d+\s*XP.*$', caseSensitive: false), '')
          .replaceFirst(
            RegExp(r'окреп\s+до\s+ур\.?\s*\d+', caseSensitive: false),
            '',
          )
          .trim();
      skillName = name.isEmpty ? null : name;
    }

    return CompletionToastContent(
      icon: isLevelUp
          ? Icons.workspace_premium
          : isSkillGrowth
          ? Icons.trending_up
          : isQuickAction
          ? Icons.auto_awesome
          : lower.contains('сопротивлен')
          ? Icons.shield
          : Icons.auto_awesome,
      title: isLevelUp
          ? 'Новый уровень'
          : isSkillGrowth
          ? 'Навык окреп'
          : isQuickAction
          ? 'Опыт получен'
          : lines.length > 1
          ? lines.first
          : 'Опыт получен',
      skillName: skillName,
      baseXp: baseXp,
      bonusXp: bonusXp,
      detail: isQuickAction ? 'Быстрое действие' : null,
      nextLevelHint: nextLevelHint,
    );
  }

  String get semanticsLabel {
    final values = <String>[title];
    if (skillName != null) values.add(skillName!);
    if (baseXp != null) values.add('плюс $baseXp XP');
    if (bonusXp != null) values.add('эффект плюс $bonusXp XP');
    if (nextLevelHint != null) values.add(nextLevelHint!);
    return values.join(', ');
  }
}

class XPBubble extends StatefulWidget {
  final String message;
  final ActionToastPlacement placement;
  final CompletionToastColors colors;
  final bool showConfetti;
  final Widget Function(Color color)? confettiBuilder;
  final bool reducedMotion;
  final Function(Key?) onDone;
  const XPBubble({
    super.key,
    required this.message,
    required this.placement,
    this.colors = const CompletionToastColors.fallback(),
    this.showConfetti = false,
    this.confettiBuilder,
    this.reducedMotion = false,
    required this.onDone,
  });
  @override
  State<XPBubble> createState() => _XPBubbleState();
}

class _XPBubbleState extends State<XPBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _opacity, _scale;
  late CompletionToastContent _content;

  @override
  void initState() {
    super.initState();
    _content = CompletionToastContent.fromMessage(widget.message);
    _c = AnimationController(
      vsync: this,
      duration: widget.reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 1800),
    );
    final curved = CurvedAnimation(parent: _c, curve: kMotionCurve);
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
    _c.forward().then((_) {
      if (mounted) widget.onDone(widget.key);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? const Color(0xFF15151D) : Colors.white;
    final bg = widget.colors.surfaceTint(baseBg, isDark: isDark);
    final txt = isDark ? const Color(0xFFF4F4F8) : const Color(0xFF1B1B22);
    final sub = isDark ? const Color(0xFF9A9AA6) : const Color(0xFF5F6370);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        return Positioned(
          left: widget.placement.topLeft.dx,
          top: widget.placement.topLeft.dy,
          child: IgnorePointer(
            child: Semantics(
              liveRegion: true,
              label: _content.semanticsLabel,
              child: Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  alignment: Alignment.topLeft,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.placement.maxWidth),
            child: Container(
              key: const ValueKey('xp-bubble-surface'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.colors.borderColor(isDark: isDark),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 95 : 24),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: widget.colors.glowColor(isDark: isDark),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.colors.rewardSoft(isDark: isDark),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _content.icon,
                      key: const ValueKey('xp-bubble-reward-icon'),
                      color: widget.colors.rewardColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _content.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: txt,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            height: 1,
                          ),
                        ),
                        if (_content.skillName != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            _content.skillName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: sub,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 3),
                        _XPBubbleRewardLine(
                          content: _content,
                          textColor: sub,
                          rewardColor: widget.colors.rewardColor,
                          bonusColor: MobileJournalTokens.inbox,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showConfetti && widget.confettiBuilder != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 230,
                    height: 104,
                    child: widget.confettiBuilder!(
                      widget.colors.sourceAccentColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _XPBubbleRewardLine extends StatelessWidget {
  final CompletionToastContent content;
  final Color textColor;
  final Color rewardColor;
  final Color bonusColor;

  const _XPBubbleRewardLine({
    required this.content,
    required this.textColor,
    required this.rewardColor,
    required this.bonusColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1,
    );
    final spans = <InlineSpan>[];
    if (content.baseXp != null) {
      spans.add(
        TextSpan(
          text: '+${content.baseXp} XP',
          style: style.copyWith(
            color: rewardColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
    if (content.bonusXp != null) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' · '));
      spans.add(
        TextSpan(
          text: 'эффект +${content.bonusXp} XP',
          style: style.copyWith(color: bonusColor, fontWeight: FontWeight.w900),
        ),
      );
    }
    if (content.detail != null) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' · '));
      spans.add(TextSpan(text: content.detail));
    }
    if (content.nextLevelHint != null) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' · '));
      spans.add(TextSpan(text: content.nextLevelHint));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: 'Действие засчитано'));

    return Text.rich(
      TextSpan(style: style, children: spans),
      key: const ValueKey('xp-bubble-reward-line'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
  final String? hintText;
  final TextEditingController ctrl;
  final Color fBg, txt, sub, bdr;
  final int min;
  final int? max;
  final bool showLabel;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;
  const DlgField({
    super.key,
    required this.label,
    required this.ctrl,
    required this.fBg,
    required this.txt,
    required this.sub,
    required this.bdr,
    this.min = 1,
    this.max,
    this.hintText,
    this.showLabel = true,
    this.fieldKey,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (showLabel) ...[SubLbl(label, sub), const SizedBox(height: 6)],
      Container(
        decoration: BoxDecoration(
          color: fBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bdr),
        ),
        child: TextField(
          key: fieldKey,
          controller: ctrl,
          onChanged: onChanged,
          style: TextStyle(color: txt, fontSize: 14),
          minLines: min,
          maxLines: max ?? (min == 1 ? 1 : 4),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: TextStyle(color: sub, fontSize: 13, height: 1.25),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ),
    ],
  );
}

class MobileFormPage extends StatelessWidget {
  final Key pageKey;
  final Key saveKey;
  final String title;
  final Color backgroundColor;
  final Color accentColor;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final Widget child;
  final Widget? bottomAction;
  final bool showTopSaveAction;
  final String saveLabel;
  final TextStyle? titleStyle;

  const MobileFormPage({
    super.key,
    required this.pageKey,
    required this.saveKey,
    required this.title,
    required this.backgroundColor,
    required this.accentColor,
    required this.onSave,
    this.onCancel,
    required this.child,
    this.bottomAction,
    this.showTopSaveAction = true,
    this.saveLabel = 'Создать',
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: pageKey,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const ValueKey('mobile-form-cancel'),
          tooltip: 'Отмена',
          onPressed: onCancel ?? () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          title,
          key: const ValueKey('mobile-form-title'),
          style: titleStyle,
        ),
        actions: showTopSaveAction
            ? [
                TextButton(
                  key: saveKey,
                  onPressed: onSave,
                  style: TextButton.styleFrom(foregroundColor: accentColor),
                  child: Text(
                    saveLabel,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 4),
              ]
            : const [
                SizedBox(
                  key: ValueKey('mobile-form-top-save-hidden'),
                  width: 8,
                ),
              ],
      ),
      body: SafeArea(
        top: false,
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: child,
        ),
      ),
      bottomNavigationBar: bottomAction == null
          ? null
          : SafeArea(top: false, child: bottomAction!),
    );
  }
}

Future<bool> showDiscardMobileFormDialog(
  BuildContext context, {
  required bool isDark,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: surface(isDark),
      title: Text(
        'Отменить изменения?',
        style: TextStyle(color: textColor(isDark)),
      ),
      content: Text(
        'Введённые данные не сохранятся. Можно продолжить редактирование или удалить черновик.',
        style: TextStyle(color: subtext(isDark), height: 1.35),
      ),
      actions: [
        TextButton(
          key: const ValueKey('mobile-form-keep-editing'),
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Продолжить редактирование'),
        ),
        TextButton(
          key: const ValueKey('mobile-form-discard'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF453A)),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Удалить черновик'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class DlgActions extends StatelessWidget {
  final VoidCallback onCancel, onSave;
  final String saveLabel;
  final Color saveColor;
  const DlgActions({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = 'Сохранить',
    this.saveColor = const Color(0xFF4A9EFF),
  });
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 10,
    runSpacing: 8,
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
      PressFeedback(
        onTap: onSave,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: saveColor,
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

Future<int?> showIntegerEditDialog(
  BuildContext context, {
  required String title,
  required int initialValue,
  required int min,
  required int max,
  required Color color,
  required bool isDark,
  String suffix = '',
}) async {
  final controller = TextEditingController(text: '$initialValue');
  String? errorText;

  try {
    return await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        final txt = textColor(isDark);
        final sub = subtext(isDark);
        final bdr = borderColor(isDark);
        final bg = surface(isDark);
        final fBg = isDark ? const Color(0xFF181820) : const Color(0xFFFFFFFF);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void save() {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null) {
                setDialogState(() => errorText = 'Введите число');
                return;
              }
              Navigator.pop(dialogContext, parsed.clamp(min, max).toInt());
            }

            return Dialog(
              backgroundColor: bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: SizedBox(
                width: 360,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DlgHeader(title: title, txtColor: txt),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: txt,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                        decoration: InputDecoration(
                          suffixText: suffix,
                          suffixStyle: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                          ),
                          errorText: errorText,
                          helperText: 'Диапазон: $min-$max',
                          helperStyle: TextStyle(color: sub, fontSize: 11),
                          filled: true,
                          fillColor: fBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: bdr),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: color, width: 1.4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => save(),
                      ),
                      const SizedBox(height: 16),
                      DlgActions(
                        onCancel: () => Navigator.pop(dialogContext),
                        onSave: save,
                        saveColor: color,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    unawaited(Future<void>.delayed(kMotionSlow, controller.dispose));
  }
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
