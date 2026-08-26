import 'package:flutter/material.dart';

enum TutorialTargetStatus { waiting, ready, fallback }

typedef TutorialTargetBuilder =
    Widget Function(BuildContext context, TutorialTargetStatus status);

/// Waits for a tutorial target to be mounted and laid out without relying on
/// wall-clock delays. A bounded fallback keeps a tutorial step dismissible
/// when its target is unavailable in the current responsive composition.
class TutorialTargetReadiness extends StatefulWidget {
  const TutorialTargetReadiness({
    super.key,
    required this.stepId,
    required this.targetKey,
    required this.enabled,
    required this.builder,
    this.maxFrameAttempts = 12,
  }) : assert(maxFrameAttempts > 0);

  final String stepId;
  final GlobalKey targetKey;
  final bool enabled;
  final int maxFrameAttempts;
  final TutorialTargetBuilder builder;

  @override
  State<TutorialTargetReadiness> createState() =>
      _TutorialTargetReadinessState();
}

class _TutorialTargetReadinessState extends State<TutorialTargetReadiness> {
  TutorialTargetStatus _status = TutorialTargetStatus.waiting;
  int _attempts = 0;
  bool _frameScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleProbe();
  }

  @override
  void didUpdateWidget(TutorialTargetReadiness oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepId != widget.stepId ||
        oldWidget.targetKey != widget.targetKey ||
        oldWidget.enabled != widget.enabled) {
      _status = TutorialTargetStatus.waiting;
      _attempts = 0;
      _frameScheduled = false;
    }
    _scheduleProbe();
  }

  void _scheduleProbe() {
    if (!widget.enabled ||
        _status != TutorialTargetStatus.waiting ||
        _frameScheduled) {
      return;
    }
    _frameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _probeTarget());
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _probeTarget() {
    _frameScheduled = false;
    if (!mounted || !widget.enabled) return;

    final renderObject = widget.targetKey.currentContext?.findRenderObject();
    final ready =
        renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize &&
        !renderObject.size.isEmpty;
    if (ready) {
      setState(() => _status = TutorialTargetStatus.ready);
      return;
    }

    _attempts += 1;
    if (_attempts >= widget.maxFrameAttempts) {
      setState(() => _status = TutorialTargetStatus.fallback);
      return;
    }
    _scheduleProbe();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleProbe();
    return widget.builder(context, _status);
  }
}
