import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tutorial/guided_tour_plan.dart';
import '../../tutorial/guided_tour_session.dart';
import '../../utils.dart';
import 'guided_tour_session_controller.dart';
import 'tutorial_anchor_registry.dart';
import 'tutorial_card_placement.dart';
import 'tutorial_target_readiness.dart';

typedef GuidedTourStepCallback = FutureOr<void> Function(GuidedTourStep step);

class GuidedTourHost extends StatefulWidget {
  const GuidedTourHost({
    super.key,
    required this.controller,
    required this.anchors,
    required this.isDark,
    required this.reducedMotion,
    required this.mobile,
    required this.onPrimary,
    required this.onDismiss,
    required this.onPrevious,
    this.blocked = false,
    this.reservedRegions = const [],
  });

  final GuidedTourSessionController controller;
  final TutorialAnchorRegistry anchors;
  final bool isDark;
  final bool reducedMotion;
  final bool mobile;
  final bool blocked;
  final List<Rect> reservedRegions;
  final GuidedTourStepCallback onPrimary;
  final GuidedTourStepCallback onDismiss;
  final GuidedTourStepCallback onPrevious;

  @override
  State<GuidedTourHost> createState() => _GuidedTourHostState();
}

class _GuidedTourHostState extends State<GuidedTourHost>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  final FocusNode _focusNode = FocusNode(debugLabel: 'guided-tour-card');
  final GlobalKey _overlayKey = GlobalKey(debugLabel: 'guided-tour-overlay');
  String? _stepId;
  TutorialTargetStatus _targetStatus = TutorialTargetStatus.waiting;
  TutorialAnchorId? _effectiveAnchorId;
  Rect? _targetRect;
  bool _actionInFlight = false;
  bool _skipScheduled = false;
  bool _targetRectSyncScheduled = false;

  Duration get _duration =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 180);

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this);
    _opacity = CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
    widget.controller.addListener(_handleControllerChanged);
    widget.anchors.addListener(_handleAnchorChanged);
    WidgetsBinding.instance.addObserver(this);
    _syncStep();
  }

  @override
  void didUpdateWidget(covariant GuidedTourHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
    if (oldWidget.anchors != widget.anchors) {
      oldWidget.anchors.removeListener(_handleAnchorChanged);
      widget.anchors.addListener(_handleAnchorChanged);
    }
    _syncStep();
    if (oldWidget.blocked && !widget.blocked) {
      _presentStep();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    widget.anchors.removeListener(_handleAnchorChanged);
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(_syncStep);
  }

  void _handleAnchorChanged() {
    if (!mounted || _targetStatus != TutorialTargetStatus.ready) return;
    _scheduleTargetRectSync();
  }

  @override
  void didChangeMetrics() => _scheduleTargetRectSync();

  void _syncStep() {
    final step = widget.controller.currentStep;
    if (_stepId == step?.id) return;
    _stepId = step?.id;
    _effectiveAnchorId = step?.anchorId;
    _targetRect = null;
    _targetStatus =
        step == null ||
            step.presentation == GuidedTourPresentation.coachCard ||
            step.anchorId == null
        ? TutorialTargetStatus.fallback
        : TutorialTargetStatus.waiting;
    _skipScheduled = false;
    _animation.value = 0;
    if (_targetStatus == TutorialTargetStatus.fallback && step != null) {
      _presentStep();
    }
  }

  void _presentStep() {
    if (!mounted || widget.blocked) return;
    widget.controller.present();
    _animation.duration = _duration;
    unawaited(_animation.forward(from: 0));
    _scheduleTargetRectSync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _scheduleTargetRectSync() {
    if (_targetRectSyncScheduled || !mounted) return;
    _targetRectSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _targetRectSyncScheduled = false;
      _syncTargetRect();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _syncTargetRect() {
    if (!mounted) return;
    final overlay = _overlayKey.currentContext?.findRenderObject();
    final anchorId = _targetStatus == TutorialTargetStatus.ready
        ? _effectiveAnchorId
        : null;
    final next = overlay is RenderBox && anchorId != null
        ? widget.anchors.rectFor(anchorId, overlay)
        : null;
    if (next == _targetRect) return;
    setState(() => _targetRect = next);
  }

  void _handleTargetStatus(TutorialTargetStatus status) {
    if (!mounted || status == TutorialTargetStatus.waiting) return;
    final step = widget.controller.currentStep;
    if (step == null) return;
    if (status == TutorialTargetStatus.fallback) {
      if (step.missingTargetPolicy == TutorialMissingTargetPolicy.skip) {
        if (_skipScheduled) return;
        _skipScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_runAction(widget.onPrimary, step));
        });
        return;
      }
      if (step.missingTargetPolicy ==
          TutorialMissingTargetPolicy.endChapterSafely) {
        if (_skipScheduled) return;
        _skipScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_runAction(widget.onDismiss, step));
        });
        return;
      }
      if (step.missingTargetPolicy ==
              TutorialMissingTargetPolicy.useParentAnchor &&
          step.parentAnchorId != null &&
          _effectiveAnchorId != step.parentAnchorId) {
        setState(() {
          _effectiveAnchorId = step.parentAnchorId;
          _targetStatus = TutorialTargetStatus.waiting;
        });
        return;
      }
    }
    setState(() => _targetStatus = status);
    _presentStep();
  }

  Future<void> _runAction(
    GuidedTourStepCallback callback,
    GuidedTourStep step,
  ) async {
    if (_actionInFlight) return;
    _actionInFlight = true;
    widget.controller.beginLeaving();
    _animation.duration = _duration;
    try {
      await _animation.reverse();
      if (!mounted) return;
      await callback(step);
    } finally {
      _actionInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.session;
    final step = session?.currentStep;
    if (session == null ||
        step == null ||
        widget.blocked ||
        session.isPaused ||
        session.isComplete ||
        session.phase == GuidedTourPhase.navigating ||
        session.phase == GuidedTourPhase.waitingForAnchor) {
      return const SizedBox.shrink(key: ValueKey('guided-tour-host-hidden'));
    }

    final anchorId = _effectiveAnchorId;
    if (_targetStatus == TutorialTargetStatus.waiting && anchorId != null) {
      return SizedBox.expand(
        child: TutorialTargetReadiness(
          key: ValueKey('guided-tour-readiness-${step.id}-${anchorId.name}'),
          stepId: step.id,
          targetKey: widget.anchors.keyFor(anchorId),
          enabled: true,
          onStatusChanged: _handleTargetStatus,
          builder: (context, status) =>
              const SizedBox.shrink(key: ValueKey('guided-tour-host-waiting')),
        ),
      );
    }

    final canGoPrevious =
        session.plan.mode != GuidedTourMode.firstRunCore &&
        session.canGoPrevious;
    return SizedBox.expand(
      key: const ValueKey('guided-tour-host'),
      child: SizedBox.expand(
        key: _overlayKey,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                unawaited(_runAction(widget.onDismiss, step)),
          },
          child: Focus(
            focusNode: _focusNode,
            child: FadeTransition(
              opacity: _opacity,
              child: SlideTransition(
                position: widget.reducedMotion
                    ? const AlwaysStoppedAnimation(Offset.zero)
                    : _slide,
                child: _GuidedTourOverlay(
                  step: step,
                  currentIndex: session.currentIndex,
                  totalSteps: session.totalSteps,
                  target: _targetRect,
                  isDark: widget.isDark,
                  mobile: widget.mobile,
                  reservedRegions: widget.reservedRegions,
                  canGoPrevious: canGoPrevious,
                  onPrimary: () =>
                      unawaited(_runAction(widget.onPrimary, step)),
                  onPrevious: canGoPrevious
                      ? () => unawaited(_runAction(widget.onPrevious, step))
                      : null,
                  onDismiss: () =>
                      unawaited(_runAction(widget.onDismiss, step)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidedTourOverlay extends StatelessWidget {
  const _GuidedTourOverlay({
    required this.step,
    required this.currentIndex,
    required this.totalSteps,
    required this.target,
    required this.isDark,
    required this.mobile,
    required this.reservedRegions,
    required this.canGoPrevious,
    required this.onPrimary,
    required this.onDismiss,
    this.onPrevious,
  });

  final GuidedTourStep step;
  final int currentIndex;
  final int totalSteps;
  final Rect? target;
  final bool isDark;
  final bool mobile;
  final List<Rect> reservedRegions;
  final bool canGoPrevious;
  final VoidCallback onPrimary;
  final VoidCallback onDismiss;
  final VoidCallback? onPrevious;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetRect = target;
        final safeInsets = MediaQuery.paddingOf(context);
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GuidedTourSpotlightPainter(
                  targetRect: targetRect,
                  isDark: isDark,
                  enabled: targetRect != null,
                ),
              ),
            ),
            const ModalBarrier(dismissible: false, color: Colors.transparent),
            if (targetRect != null)
              Positioned.fromRect(
                rect: targetRect.inflate(7),
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey('guided-tour-highlight'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFF9500),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9500).withAlpha(50),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            CustomSingleChildLayout(
              delegate: _GuidedTourCardLayoutDelegate(
                target: targetRect,
                safeInsets: safeInsets,
                reservedRegions: reservedRegions,
                mobile: mobile,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: mobile ? constraints.maxWidth - 24 : 390,
                  maxHeight:
                      constraints.maxHeight -
                      safeInsets.vertical -
                      (mobile ? 104 : 32),
                ),
                child: _GuidedTourCard(
                  step: step,
                  displayIndex: currentIndex + 1,
                  totalSteps: totalSteps,
                  isDark: isDark,
                  canGoPrevious: canGoPrevious,
                  onPrimary: onPrimary,
                  onPrevious: onPrevious,
                  onDismiss: onDismiss,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GuidedTourCardLayoutDelegate extends SingleChildLayoutDelegate {
  const _GuidedTourCardLayoutDelegate({
    required this.target,
    required this.safeInsets,
    required this.reservedRegions,
    required this.mobile,
  });

  final Rect? target;
  final EdgeInsets safeInsets;
  final List<Rect> reservedRegions;
  final bool mobile;

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      TutorialCardPlacement.resolve(
        viewport: size,
        cardSize: childSize,
        safeInsets: safeInsets,
        target: target,
        reservedRegions: reservedRegions,
        mobile: mobile,
      ).offset;

  @override
  bool shouldRelayout(covariant _GuidedTourCardLayoutDelegate oldDelegate) =>
      oldDelegate.target != target ||
      oldDelegate.safeInsets != safeInsets ||
      oldDelegate.mobile != mobile ||
      oldDelegate.reservedRegions != reservedRegions;
}

class _GuidedTourCard extends StatelessWidget {
  const _GuidedTourCard({
    required this.step,
    required this.displayIndex,
    required this.totalSteps,
    required this.isDark,
    required this.canGoPrevious,
    required this.onPrimary,
    required this.onDismiss,
    this.onPrevious,
  });

  final GuidedTourStep step;
  final int displayIndex;
  final int totalSteps;
  final bool isDark;
  final bool canGoPrevious;
  final VoidCallback onPrimary;
  final VoidCallback onDismiss;
  final VoidCallback? onPrevious;

  @override
  Widget build(BuildContext context) {
    final foreground = textColor(isDark);
    final secondary = subtext(isDark);
    const accent = Color(0xFFFF9500);
    return Material(
      key: const ValueKey('guided-tour-card'),
      color: isDark ? const Color(0xFF181820) : Colors.white,
      elevation: 16,
      shadowColor: Colors.black.withAlpha(isDark ? 120 : 38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? Colors.white.withAlpha(28)
              : Colors.black.withAlpha(20),
        ),
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Обучение, шаг $displayIndex из $totalSteps',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: accent,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ОБУЧЕНИЕ · $displayIndex ИЗ $totalSteps',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('guided-tour-close'),
                    tooltip: 'Закрыть обучение',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDismiss,
                    icon: Icon(Icons.close_rounded, color: secondary, size: 19),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: displayIndex / totalSteps,
                  backgroundColor: accent.withAlpha(24),
                  valueColor: const AlwaysStoppedAnimation(accent),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                step.title,
                style: TextStyle(
                  color: foreground,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step.body,
                style: TextStyle(
                  color: secondary,
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (canGoPrevious)
                    TextButton(
                      key: const ValueKey('guided-tour-previous'),
                      onPressed: onPrevious,
                      child: const Text('Назад'),
                    ),
                  FilledButton(
                    key: const ValueKey('guided-tour-primary'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onPrimary,
                    child: Text(step.primaryLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidedTourSpotlightPainter extends CustomPainter {
  const _GuidedTourSpotlightPainter({
    required this.targetRect,
    required this.isDark,
    required this.enabled,
  });

  final Rect? targetRect;
  final bool isDark;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withAlpha(isDark ? 154 : 92);
    final target = targetRect;
    if (!enabled || target == null) {
      canvas.drawRect(
        Offset.zero & size,
        overlay..color = overlay.color.withAlpha(isDark ? 46 : 28),
      );
      return;
    }
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, overlay);
    canvas.drawRRect(
      RRect.fromRectAndRadius(target.inflate(8), const Radius.circular(15)),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GuidedTourSpotlightPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect ||
      oldDelegate.isDark != isDark ||
      oldDelegate.enabled != enabled;
}
