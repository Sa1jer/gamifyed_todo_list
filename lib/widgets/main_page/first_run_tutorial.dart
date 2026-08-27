part of '../main_page.dart';

enum _TutorialRuntimePhase {
  idle,
  transitioning,
  waitingForTarget,
  presenting,
  completing,
  completed,
}

class _MainPageTutorialBoundary extends StatefulWidget {
  const _MainPageTutorialBoundary({
    required this.state,
    required this.blocked,
    required this.transitioning,
    required this.isDark,
    required this.resolveStep,
    this.onBuildForTesting,
  });

  final AppState state;
  final bool blocked;
  final bool transitioning;
  final bool isDark;
  final _GuidedTutorialStep? Function() resolveStep;
  final VoidCallback? onBuildForTesting;

  @override
  State<_MainPageTutorialBoundary> createState() =>
      _MainPageTutorialBoundaryState();
}

class _MainPageTutorialBoundaryState extends State<_MainPageTutorialBoundary> {
  bool _sawCoreActionStep = false;
  bool _showCoreCompletion = false;
  String? _runtimeStepId;
  _TutorialRuntimePhase _runtimePhase = _TutorialRuntimePhase.idle;

  void _setRuntimePhase(_TutorialRuntimePhase phase) {
    if (!mounted || _runtimePhase == phase) return;
    setState(() => _runtimePhase = phase);
  }

  void _runPrimaryAction(_GuidedTutorialStep step) {
    _setRuntimePhase(_TutorialRuntimePhase.completing);
    step.onPrimaryAction();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateSelector<MainPageTutorialProjection>(
      state: widget.state,
      selector: MainPageTutorialProjection.fromState,
      builder: (context, projection, child) {
        widget.onBuildForTesting?.call();
        final isCoreActionStep =
            projection.visible &&
            projection.moduleId == TutorialModuleIds.core &&
            projection.stepId == TutorialStepIds.coreCompleteQuest;
        if (isCoreActionStep) {
          _sawCoreActionStep = true;
        } else if (_sawCoreActionStep && projection.coreCompleted) {
          _sawCoreActionStep = false;
          _showCoreCompletion = true;
        }

        final step = projection.visible ? widget.resolveStep() : null;
        if (step == null) {
          _runtimeStepId = null;
          _runtimePhase = _showCoreCompletion
              ? _TutorialRuntimePhase.completed
              : _TutorialRuntimePhase.idle;
          if (!_showCoreCompletion) {
            return const SizedBox.shrink(
              key: ValueKey('tutorial-runtime-idle'),
            );
          }
          return TutorialCompletionCard(
            isDark: widget.isDark,
            reducedMotion: widget.state.reducedMotion,
            onDismiss: () => setState(() => _showCoreCompletion = false),
          );
        }
        _showCoreCompletion = false;
        if (_runtimeStepId != step.id) {
          _runtimeStepId = step.id;
          _runtimePhase = _TutorialRuntimePhase.transitioning;
        }

        if (widget.blocked) {
          _runtimePhase = widget.transitioning
              ? _TutorialRuntimePhase.transitioning
              : _TutorialRuntimePhase.waitingForTarget;
          return SizedBox.shrink(
            key: ValueKey('tutorial-runtime-${_runtimePhase.name}'),
          );
        }

        if (step.presentationMode != TutorialPresentationMode.spotlight) {
          _runtimePhase = _TutorialRuntimePhase.presenting;
          return _FirstRunTutorialOverlay(
            stepId: step.id,
            visible: true,
            useFallback: true,
            presentationMode: step.presentationMode,
            runtimePhase: _runtimePhase,
            targetKey: step.targetKey,
            isDark: widget.isDark,
            reducedMotion: widget.state.reducedMotion,
            title: step.title,
            body: step.body,
            primaryLabel: step.primaryLabel,
            primaryIcon: step.primaryIcon,
            secondaryLabel: step.secondaryLabel,
            onDismiss: widget.state.dismissActiveTutorial,
            onPrimaryAction: () => _runPrimaryAction(step),
          );
        }

        return TutorialTargetReadiness(
          key: ValueKey('tutorial-target-readiness-${step.id}'),
          stepId: step.id,
          targetKey: step.targetKey,
          enabled: true,
          onStatusChanged: (status) => _setRuntimePhase(
            status == TutorialTargetStatus.waiting
                ? _TutorialRuntimePhase.waitingForTarget
                : _TutorialRuntimePhase.presenting,
          ),
          builder: (context, status) {
            if (status == TutorialTargetStatus.waiting) {
              _runtimePhase = _TutorialRuntimePhase.waitingForTarget;
              return const SizedBox.shrink(
                key: ValueKey('tutorial-runtime-waitingForTarget'),
              );
            }
            _runtimePhase = _TutorialRuntimePhase.presenting;
            return _FirstRunTutorialOverlay(
              stepId: step.id,
              visible: true,
              useFallback: status == TutorialTargetStatus.fallback,
              presentationMode: status == TutorialTargetStatus.fallback
                  ? TutorialPresentationMode.coachCard
                  : step.presentationMode,
              runtimePhase: _runtimePhase,
              targetKey: step.targetKey,
              isDark: widget.isDark,
              reducedMotion: widget.state.reducedMotion,
              title: step.title,
              body: step.body,
              primaryLabel: step.primaryLabel,
              primaryIcon: step.primaryIcon,
              secondaryLabel: step.secondaryLabel,
              onDismiss: widget.state.dismissActiveTutorial,
              onPrimaryAction: () => _runPrimaryAction(step),
            );
          },
        );
      },
    );
  }
}

class _GuidedTutorialStep {
  final String id;
  final GlobalKey targetKey;
  final String title;
  final String body;
  final String primaryLabel;
  final IconData primaryIcon;
  final String? secondaryLabel;
  final TutorialPresentationMode presentationMode;
  final VoidCallback onPrimaryAction;

  const _GuidedTutorialStep({
    required this.id,
    required this.targetKey,
    required this.title,
    required this.body,
    required this.primaryLabel,
    this.primaryIcon = Icons.arrow_forward_rounded,
    this.secondaryLabel = 'Пропустить обучение',
    this.presentationMode = TutorialPresentationMode.spotlight,
    required this.onPrimaryAction,
  });
}

class _FirstRunTutorialOverlay extends StatefulWidget {
  final String stepId;
  final GlobalKey targetKey;
  final bool isDark;
  final bool visible;
  final bool useFallback;
  final TutorialPresentationMode presentationMode;
  final _TutorialRuntimePhase runtimePhase;
  final bool reducedMotion;
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
    required this.useFallback,
    required this.presentationMode,
    required this.runtimePhase,
    required this.reducedMotion,
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
  bool _trackingFrameScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleTargetTracking();
  }

  @override
  void didUpdateWidget(covariant _FirstRunTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleTargetTracking();
  }

  void _scheduleTargetTracking() {
    if (_trackingFrameScheduled || !widget.visible) return;
    _trackingFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackingFrameScheduled = false;
      if (!mounted) return;
      _syncTargetRect();
      // Register for the next real frame. This follows scrolling and resize
      // without forcing the app to render while the interface is idle.
      _scheduleTargetTracking();
    });
  }

  void _syncTargetRect() {
    if (!mounted) return;
    if (widget.useFallback) {
      if (_targetRect != null) setState(() => _targetRect = null);
      return;
    }
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
    final animationDuration =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : kMotionSlow;
    final txt = textColor(widget.isDark);
    final sub = subtext(widget.isDark);
    final panelColor = widget.isDark
        ? const Color(0xFF181820)
        : const Color(0xFFFFFFFF);
    final border = widget.isDark
        ? Colors.white.withAlpha(26)
        : Colors.black.withAlpha(18);

    return Positioned.fill(
      key: ValueKey('tutorial-runtime-${widget.runtimePhase.name}'),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss,
        },
        child: Focus(
          autofocus: true,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: widget.visible ? 1 : 0),
              duration: animationDuration,
              curve: kMotionCurve,
              builder: (context, t, child) => IgnorePointer(
                ignoring: !widget.visible || t < 0.05,
                child: Opacity(
                  key: const ValueKey('first-run-tutorial-opacity'),
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - t)),
                    child: child,
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final target =
                      widget.presentationMode ==
                          TutorialPresentationMode.spotlight
                      ? _targetRect
                      : null;
                  final panelWidth = math.min(size.width - 32, 380.0);
                  final targetCenter =
                      target?.center ?? size.center(Offset.zero);
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
                            presentationMode: widget.presentationMode,
                          ),
                        ),
                      ),
                      if (target != null)
                        AnimatedPositioned(
                          duration: animationDuration,
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
                                    color: const Color(
                                      0xFFFF9500,
                                    ).withAlpha(90),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      AnimatedPositioned(
                        key: ValueKey(
                          'tutorial-${widget.presentationMode.name}-card',
                        ),
                        duration: animationDuration,
                        curve: kMotionCurve,
                        left: panelLeft,
                        top: panelTop,
                        width: panelWidth,
                        child: Semantics(
                          container: true,
                          explicitChildNodes: true,
                          label: 'Обучение: ${widget.title}',
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                      FilledButton.icon(
                                        onPressed: widget.onPrimaryAction,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFF9500,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(
                                          widget.primaryIcon,
                                          size: 15,
                                        ),
                                        label: Text(
                                          widget.primaryLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
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
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialSpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final bool isDark;
  final TutorialPresentationMode presentationMode;

  const _TutorialSpotlightPainter({
    required this.targetRect,
    required this.isDark,
    required this.presentationMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = switch (presentationMode) {
      TutorialPresentationMode.spotlight => isDark ? 176 : 118,
      TutorialPresentationMode.coachCard => isDark ? 56 : 28,
      TutorialPresentationMode.inlineGuidance => 0,
    };
    final overlay = Paint()..color = Colors.black.withAlpha(alpha);
    final target = targetRect;
    if (target == null) {
      if (alpha > 0) canvas.drawRect(Offset.zero & size, overlay);
      return;
    }

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, overlay);

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(
      RRect.fromRectAndRadius(target.inflate(10), const Radius.circular(16)),
      clearPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TutorialSpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.isDark != isDark ||
        oldDelegate.presentationMode != presentationMode;
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
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: textColor(isDark),
        backgroundColor: isDark
            ? Colors.white.withAlpha(12)
            : Colors.black.withAlpha(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(24)
                : Colors.black.withAlpha(18),
          ),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}
