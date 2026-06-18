part of '../mastery_map_workspace.dart';

class _SkillOrbButton extends StatefulWidget {
  final Skill skill;
  final bool isDark;
  final bool selected;
  final bool roadFocus;
  final bool hiddenInFocus;
  final bool dimmed;
  final VoidCallback onTap;

  const _SkillOrbButton({
    required this.skill,
    required this.isDark,
    required this.selected,
    this.roadFocus = false,
    this.hiddenInFocus = false,
    required this.dimmed,
    required this.onTap,
  });

  @override
  State<_SkillOrbButton> createState() => _SkillOrbButtonState();
}

class _SkillOrbButtonState extends State<_SkillOrbButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final orbSize = widget.roadFocus
        ? 124.0
        : widget.selected
        ? 82.0
        : 74.0;
    final iconSize = widget.roadFocus
        ? 43.0
        : widget.selected
        ? 31.0
        : 27.0;
    final levelSize = widget.roadFocus
        ? 27.0
        : widget.selected
        ? 18.0
        : 16.0;
    final glowAlpha = _hovered
        ? widget.roadFocus
              ? 128
              : 118
        : widget.roadFocus
        ? 92
        : widget.selected
        ? 105
        : 48;
    final glowBlur = _hovered
        ? widget.roadFocus
              ? 40.0
              : 34.0
        : widget.roadFocus
        ? 32.0
        : widget.selected
        ? 30.0
        : 18.0;

    return IgnorePointer(
      ignoring: widget.hiddenInFocus,
      child: AnimatedOpacity(
        duration: kMotionSlow,
        curve: kMotionCurve,
        opacity: widget.hiddenInFocus
            ? 0
            : widget.dimmed
            ? 0.48
            : 1,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            duration: kMotionSlow,
            curve: kMotionCurve,
            scale:
                (widget.hiddenInFocus ? 0.82 : 1) *
                (_hovered && !widget.hiddenInFocus ? 1.05 : 1),
            child: PressFeedback(
              scale: 0.95,
              onTap: widget.onTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: widget.skill.progress),
                    duration: kMotionProgress,
                    curve: kMotionCurve,
                    builder: (context, progress, child) {
                      return CustomPaint(
                        painter: _SkillOrbProgressPainter(
                          color: widget.skill.color,
                          progress: progress,
                          isDark: widget.isDark,
                        ),
                        child: child,
                      );
                    },
                    child: AnimatedContainer(
                      duration: kMotionSlow,
                      curve: kMotionCurve,
                      width: orbSize,
                      height: orbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.skill.color.withAlpha(
                          widget.isDark ? 36 : 28,
                        ),
                        border: Border.all(
                          color: widget.selected
                              ? Colors.white
                              : widget.skill.color,
                          width: widget.roadFocus
                              ? 3.4
                              : widget.selected
                              ? 3
                              : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.skill.color.withAlpha(glowAlpha),
                            blurRadius: glowBlur,
                            spreadRadius: _hovered
                                ? 2
                                : widget.roadFocus
                                ? 1
                                : widget.selected
                                ? 1
                                : 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Transform.translate(
                            offset: Offset(0, widget.roadFocus ? -8 : -5),
                            child: Icon(
                              widget.skill.icon,
                              color: widget.skill.color.withAlpha(
                                widget.selected ? 245 : 220,
                              ),
                              size: iconSize,
                            ),
                          ),
                          Positioned(
                            bottom: widget.roadFocus ? 18 : 7,
                            child: Text(
                              '${widget.skill.level}',
                              style: TextStyle(
                                color: widget.skill.color,
                                fontSize: levelSize,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(
                                      widget.isDark ? 200 : 80,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _AdaptiveOrbLabel(
                    text: widget.skill.name,
                    isDark: widget.isDark,
                    selected: widget.selected || widget.roadFocus,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveOrbLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final bool selected;

  const _AdaptiveOrbLabel({
    required this.text,
    required this.isDark,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: selected ? 190 : 160,
      height: 46,
      child: Center(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? textColor(isDark) : subtext(isDark),
            fontSize: _adaptiveSkillLabelFontSize(text, selected),
            height: 1.05,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SkillOrbProgressPainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool isDark;

  const _SkillOrbProgressPainter({
    required this.color,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 + 6;
    final base = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _SkillOrbProgressPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark;
  }
}

class _SelectSkillHint extends StatelessWidget {
  final bool isDark;

  const _SelectSkillHint({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface(isDark).withAlpha(isDark ? 105 : 145),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(isDark).withAlpha(105)),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, color: subtext(isDark), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Выберите навык',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Мастерство на карте, выполнение — в «Действовать».',
                  style: TextStyle(color: subtext(isDark), fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapNodeButton extends StatefulWidget {
  final AppState state;
  final Skill skill;
  final SkillTreeNode node;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  const _MapNodeButton({
    super.key,
    required this.state,
    required this.skill,
    required this.node,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_MapNodeButton> createState() => _MapNodeButtonState();
}

class _MapNodeButtonState extends State<_MapNodeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.skill.treeNodeStatus(widget.node);
    final statusColor = status == SkillTreeNodeStatus.active
        ? widget.skill.color
        : skillTreeNodeStatusColor[status]!;
    final completed = widget.state.completedTasksForTreeNode(
      widget.skill.id,
      widget.node.id,
    );
    final target = widget.node.questTarget;
    final diameter = switch (target) {
      <= 1 => 52.0,
      <= 3 => 62.0,
      _ => 72.0,
    };
    final icon = switch (status) {
      SkillTreeNodeStatus.locked => Icons.lock,
      SkillTreeNodeStatus.active => Icons.bolt_rounded,
      SkillTreeNodeStatus.mastered => Icons.workspace_premium,
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        duration: kMotionSlow,
        curve: kMotionCurve,
        scale: _hovered ? 1.05 : 1,
        child: PressFeedback(
          scale: 0.94,
          onTap: widget.onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: kMotionStandard,
                curve: kMotionCurve,
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  color: status == SkillTreeNodeStatus.locked
                      ? surface(
                          widget.isDark,
                        ).withAlpha(widget.isDark ? 180 : 230)
                      : statusColor.withAlpha(widget.isDark ? 34 : 24),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.selected ? Colors.white : statusColor,
                    width: widget.selected ? 3 : 2,
                  ),
                  boxShadow: [
                    if (_hovered ||
                        widget.selected ||
                        status == SkillTreeNodeStatus.active)
                      BoxShadow(
                        color: statusColor.withAlpha(
                          _hovered
                              ? 110
                              : widget.selected
                              ? 105
                              : 50,
                        ),
                        blurRadius: _hovered
                            ? 28
                            : widget.selected
                            ? 26
                            : 18,
                        spreadRadius: _hovered ? 1 : 0,
                      ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, color: statusColor, size: diameter * 0.42),
                    Positioned(
                      bottom: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? const Color(0xFF0D0D12)
                              : const Color(0xFFF7F8FC),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: statusColor, width: 1.5),
                        ),
                        child: Text(
                          '${math.min(completed, target)}/$target',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 13),
                child: _AdaptiveNodeLabel(
                  text: widget.node.title,
                  color: status == SkillTreeNodeStatus.locked
                      ? subtext(widget.isDark)
                      : textColor(widget.isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaptiveNodeLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _AdaptiveNodeLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 30,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: _adaptiveNodeLabelFontSize(text),
          height: 1.05,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RoadmapInsertStageButton extends StatefulWidget {
  final bool isDark;
  final Color color;
  final VoidCallback onTap;

  const _RoadmapInsertStageButton({
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  State<_RoadmapInsertStageButton> createState() =>
      _RoadmapInsertStageButtonState();
}

class _RoadmapInsertStageButtonState extends State<_RoadmapInsertStageButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: PressFeedback(
        scale: 0.9,
        onTap: widget.onTap,
        child: SizedBox.expand(
          child: Center(
            child: AnimatedOpacity(
              duration: kMotionStandard,
              curve: kMotionCurve,
              opacity: _hovered ? 1 : 0,
              child: AnimatedScale(
                duration: kMotionStandard,
                curve: kMotionCurve,
                scale: _hovered ? 1 : 0.72,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isDark
                        ? const Color(0xFF111119)
                        : Colors.white,
                    border: Border.all(
                      color: widget.color.withAlpha(190),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withAlpha(widget.isDark ? 52 : 38),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(Icons.add, color: widget.color, size: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
