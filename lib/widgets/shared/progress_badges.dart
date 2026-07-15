import 'package:flutter/material.dart';

import '../../models.dart';
import '../mobile_journal_tokens.dart';
import 'motion_controls.dart';

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
  late final AnimationController _controller;
  late Animation<double> _animation;
  late double _target;

  @override
  void initState() {
    super.initState();
    _target = widget.progress.clamp(0.0, 1.0);
    _controller = AnimationController(
      vsync: this,
      duration: kMotionXp,
      value: 1,
    );
    _animation = AlwaysStoppedAnimation(_target);
  }

  @override
  void didUpdateWidget(XPBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.progress.clamp(0.0, 1.0);
    if (oldWidget.progress == widget.progress &&
        oldWidget.level == widget.level) {
      return;
    }
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final displayed = _animation.value.clamp(0.0, 1.0);
    _target = target;
    if (reducedMotion) {
      _controller.value = 1;
      _animation = AlwaysStoppedAnimation(target);
      return;
    }
    final isLevelUp =
        oldWidget.level != null &&
        widget.level != null &&
        widget.level! > oldWidget.level!;
    final isLevelDown =
        oldWidget.level != null &&
        widget.level != null &&
        widget.level! < oldWidget.level!;
    _animation =
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
            .animate(_controller);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = reducedMotion ? _target : _animation.value;
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
    final value = xp.abs();
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
              '${isReversal ? '-' : '+'}$value XP',
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
  Widget build(BuildContext context) => Semantics(
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
