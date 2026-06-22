part of '../main_page.dart';

class _GuidedTutorialStep {
  final String id;
  final GlobalKey targetKey;
  final String title;
  final String body;
  final String primaryLabel;
  final IconData primaryIcon;
  final String? secondaryLabel;
  final VoidCallback onPrimaryAction;

  const _GuidedTutorialStep({
    required this.id,
    required this.targetKey,
    required this.title,
    required this.body,
    required this.primaryLabel,
    this.primaryIcon = Icons.arrow_forward_rounded,
    this.secondaryLabel = 'Пропустить обучение',
    required this.onPrimaryAction,
  });
}

class _FirstRunTutorialOverlay extends StatefulWidget {
  final String stepId;
  final GlobalKey targetKey;
  final bool isDark;
  final bool visible;
  final String title;
  final String body;
  final String primaryLabel;
  final IconData primaryIcon;
  final String? secondaryLabel;
  final VoidCallback onDismiss;
  final VoidCallback onPrimaryAction;

  _FirstRunTutorialOverlay({
    required this.stepId,
    required this.targetKey,
    required this.isDark,
    required this.visible,
    required this.title,
    required this.body,
    required this.primaryLabel,
    this.primaryIcon = Icons.arrow_forward_rounded,
    this.secondaryLabel = 'Пропустить обучение',
    required this.onDismiss,
    required this.onPrimaryAction,
  }) : super(key: ValueKey('first-run-tutorial-overlay-$stepId'));

  @override
  State<_FirstRunTutorialOverlay> createState() =>
      _FirstRunTutorialOverlayState();
}

class _FirstRunTutorialOverlayState extends State<_FirstRunTutorialOverlay> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTargetRect());
  }

  @override
  void didUpdateWidget(covariant _FirstRunTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTargetRect());
  }

  void _syncTargetRect() {
    if (!mounted) return;
    final overlayBox = context.findRenderObject();
    final targetBox = widget.targetKey.currentContext?.findRenderObject();
    if (overlayBox is! RenderBox || targetBox is! RenderBox) {
      if (_targetRect != null) setState(() => _targetRect = null);
      return;
    }

    final offset = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final nextRect = offset & targetBox.size;
    if (_targetRect == nextRect) return;
    setState(() => _targetRect = nextRect);
  }

  @override
  Widget build(BuildContext context) {
    final txt = textColor(widget.isDark);
    final sub = subtext(widget.isDark);
    final panelColor = widget.isDark
        ? const Color(0xFF181820)
        : const Color(0xFFFFFFFF);
    final border = widget.isDark
        ? Colors.white.withAlpha(26)
        : Colors.black.withAlpha(18);

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.visible ? 1 : 0),
          duration: kMotionSlow,
          curve: kMotionCurve,
          builder: (context, t, child) => IgnorePointer(
            ignoring: !widget.visible || t < 0.05,
            child: Opacity(
              key: const ValueKey('first-run-tutorial-opacity'),
              opacity: t,
              child: Transform.scale(scale: 0.98 + (0.02 * t), child: child),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final target = _targetRect;
              final panelWidth = math.min(size.width - 32, 380.0);
              final targetCenter = target?.center ?? size.center(Offset.zero);
              final showBelow =
                  target == null || targetCenter.dy < size.height * 0.54;
              final panelLeft = (targetCenter.dx - panelWidth / 2)
                  .clamp(16.0, math.max(16.0, size.width - panelWidth - 16))
                  .toDouble();
              final preferredTop = showBelow
                  ? (target?.bottom ?? size.height * 0.5) + 22
                  : target.top - 244;
              final panelTop = preferredTop
                  .clamp(16.0, math.max(16.0, size.height - 252))
                  .toDouble();

              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TutorialSpotlightPainter(
                        targetRect: target,
                        isDark: widget.isDark,
                      ),
                    ),
                  ),
                  if (target != null)
                    AnimatedPositioned(
                      duration: kMotionSlow,
                      curve: kMotionCurve,
                      left: target.left - 8,
                      top: target.top - 8,
                      width: target.width + 16,
                      height: target.height + 16,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFFF9500),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9500).withAlpha(90),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  AnimatedPositioned(
                    duration: kMotionSlow,
                    curve: kMotionCurve,
                    left: panelLeft,
                    top: panelTop,
                    width: panelWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(
                              widget.isDark ? 130 : 36,
                            ),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF9500,
                                    ).withAlpha(32),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFFFF9500),
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: TextStyle(
                                      color: txt,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.body,
                              style: TextStyle(
                                color: sub,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                SmallBtn(
                                  label: widget.primaryLabel,
                                  icon: widget.primaryIcon,
                                  color: const Color(0xFFFF9500),
                                  onTap: widget.onPrimaryAction,
                                ),
                                if (widget.secondaryLabel != null)
                                  _TutorialGhostButton(
                                    label: widget.secondaryLabel!,
                                    isDark: widget.isDark,
                                    onTap: widget.onDismiss,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TutorialSpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final bool isDark;

  const _TutorialSpotlightPainter({
    required this.targetRect,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withAlpha(isDark ? 176 : 118);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, overlay);

    final target = targetRect;
    if (target != null) {
      final clearPaint = Paint()..blendMode = BlendMode.clear;
      canvas.drawRRect(
        RRect.fromRectAndRadius(target.inflate(10), const Radius.circular(16)),
        clearPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TutorialSpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.isDark != isDark;
  }
}

class _TutorialGhostButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _TutorialGhostButton({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withAlpha(12)
              : Colors.black.withAlpha(8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(24)
                : Colors.black.withAlpha(18),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor(isDark),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
