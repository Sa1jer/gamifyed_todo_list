import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'reward_animations.dart';
import 'shared.dart';

class GoalMilestoneBanner extends StatefulWidget {
  final GoalMilestoneEvent event;
  final bool isDark;
  final VoidCallback onDismiss;
  final VoidCallback? onOpenRoadmap;

  const GoalMilestoneBanner({
    super.key,
    required this.event,
    required this.isDark,
    required this.onDismiss,
    this.onOpenRoadmap,
  });

  @override
  State<GoalMilestoneBanner> createState() => _GoalMilestoneBannerState();
}

class _GoalMilestoneBannerState extends State<GoalMilestoneBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _autoHideTimer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kMotionStandard)
      ..forward();
    _scheduleAutoHide();
  }

  @override
  void didUpdateWidget(covariant GoalMilestoneBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id) {
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
    final duration = widget.event.milestone == GoalMilestone.complete
        ? const Duration(seconds: 5)
        : const Duration(seconds: 4);
    _autoHideTimer = Timer(duration, () => _closeThen(widget.onDismiss));
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
    final event = widget.event;
    final milestone = event.milestone;
    final isComplete = milestone == GoalMilestone.complete;
    final color = isComplete ? const Color(0xFFFFCC00) : event.skillColor;
    final text = textColor(widget.isDark);
    final secondary = subtext(widget.isDark);
    final background = surface(widget.isDark);
    final width = (MediaQuery.sizeOf(context).width - 24)
        .clamp(280.0, 360.0)
        .toDouble();

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = kMotionCurve.transform(_controller.value);
              return IgnorePointer(
                ignoring: value == 0,
                child: Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, -12 * (1 - value)),
                    child: Transform.scale(
                      scale: 0.96 + value * 0.04,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: SizedBox(
              width: width,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (isComplete)
                    Positioned(
                      top: -4,
                      right: 58,
                      child: MilestoneConfettiBurst(
                        color: color,
                        alignment: Alignment.topCenter,
                        particles: 10,
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withAlpha(90)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(
                            widget.isDark ? 84 : 26,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MilestoneIcon(
                                milestone: milestone,
                                color: color,
                                isDark: widget.isDark,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _titleFor(milestone),
                                      style: TextStyle(
                                        color: text,
                                        fontWeight: FontWeight.w900,
                                        fontSize: isComplete ? 15.5 : 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _subtitleFor(milestone, event.skillName),
                                      style: TextStyle(
                                        color: secondary,
                                        fontSize: 12,
                                        height: 1.28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Скрыть',
                                onPressed: () => _closeThen(widget.onDismiss),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: secondary,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          if (isComplete && widget.onOpenRoadmap != null) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: () =>
                                    _closeThen(widget.onOpenRoadmap!),
                                style: FilledButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: const Color(0xFF15151D),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.add_road, size: 17),
                                label: const Text('К RoadMap'),
                              ),
                            ),
                          ],
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
    );
  }

  String _titleFor(GoalMilestone milestone) {
    return switch (milestone) {
      GoalMilestone.quarter => '25% цели',
      GoalMilestone.half => '50% цели',
      GoalMilestone.complete => 'Цель достигнута',
    };
  }

  String _subtitleFor(GoalMilestone milestone, String skillName) {
    return switch (milestone) {
      GoalMilestone.quarter => '$skillName: Первые шаги сделаны',
      GoalMilestone.half => '$skillName: Половина пути',
      GoalMilestone.complete =>
        '$skillName: 100% выполнено. Можно задать следующую цель.',
    };
  }
}

class _MilestoneIcon extends StatelessWidget {
  final GoalMilestone milestone;
  final Color color;
  final bool isDark;

  const _MilestoneIcon({
    required this.milestone,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (milestone) {
      GoalMilestone.quarter => Icons.flag_rounded,
      GoalMilestone.half => Icons.timeline_rounded,
      GoalMilestone.complete => Icons.workspace_premium_rounded,
    };

    return Container(
      width: milestone == GoalMilestone.complete ? 42 : 38,
      height: milestone == GoalMilestone.complete ? 42 : 38,
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 34 : 24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}
