import 'dart:async';

import 'package:flutter/material.dart';

enum TutorialTargetStatus { waiting, ready, fallback }

typedef TutorialTargetBuilder =
    Widget Function(BuildContext context, TutorialTargetStatus status);

/// Shared mounted/layout probe for tutorial navigation and presentation.
///
/// It retains no BuildContext and completes on a wall-clock deadline, so route
/// sequencing does not depend on display refresh rate or a fixed frame count.
class TutorialTargetProbe {
  const TutorialTargetProbe._();

  static bool isReady(GlobalKey targetKey) {
    final renderObject = targetKey.currentContext?.findRenderObject();
    return renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize &&
        !renderObject.size.isEmpty;
  }

  static Future<bool> waitUntilReady(
    GlobalKey targetKey, {
    Duration timeout = const Duration(milliseconds: 1200),
    Duration probeInterval = const Duration(milliseconds: 50),
  }) {
    assert(timeout > Duration.zero);
    assert(probeInterval > Duration.zero);
    if (isReady(targetKey)) return Future<bool>.value(true);

    final completer = Completer<bool>();
    Timer? probeTimer;
    Timer? timeoutTimer;

    void finish(bool ready) {
      if (completer.isCompleted) return;
      probeTimer?.cancel();
      timeoutTimer?.cancel();
      completer.complete(ready);
    }

    probeTimer = Timer.periodic(probeInterval, (_) {
      if (isReady(targetKey)) {
        finish(true);
      } else {
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    });
    timeoutTimer = Timer(timeout, () => finish(false));
    WidgetsBinding.instance.ensureVisualUpdate();
    return completer.future;
  }
}

/// Waits for a tutorial target to be mounted and laid out. Readiness is driven
/// by layout probes while a wall-clock timeout provides a bounded fallback.
/// This avoids treating a device-dependent number of rendered frames as time.
class TutorialTargetReadiness extends StatefulWidget {
  const TutorialTargetReadiness({
    super.key,
    required this.stepId,
    required this.targetKey,
    required this.enabled,
    required this.builder,
    this.fallbackTimeout = const Duration(milliseconds: 1200),
    this.probeInterval = const Duration(milliseconds: 50),
    this.onStatusChanged,
  }) : assert(fallbackTimeout > Duration.zero),
       assert(probeInterval > Duration.zero);

  final String stepId;
  final GlobalKey targetKey;
  final bool enabled;
  final Duration fallbackTimeout;
  final Duration probeInterval;
  final ValueChanged<TutorialTargetStatus>? onStatusChanged;
  final TutorialTargetBuilder builder;

  @override
  State<TutorialTargetReadiness> createState() =>
      _TutorialTargetReadinessState();
}

class _TutorialTargetReadinessState extends State<TutorialTargetReadiness> {
  TutorialTargetStatus _status = TutorialTargetStatus.waiting;
  Timer? _fallbackTimer;
  Timer? _probeTimer;
  bool _frameScheduled = false;

  @override
  void initState() {
    super.initState();
    _restartObservation();
  }

  @override
  void didUpdateWidget(TutorialTargetReadiness oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepId != widget.stepId ||
        oldWidget.targetKey != widget.targetKey ||
        oldWidget.enabled != widget.enabled) {
      _restartObservation();
      return;
    }
    if (oldWidget.fallbackTimeout != widget.fallbackTimeout ||
        oldWidget.probeInterval != widget.probeInterval) {
      _restartObservation();
    }
  }

  @override
  void dispose() {
    _cancelObservation();
    super.dispose();
  }

  void _restartObservation() {
    _cancelObservation();
    _frameScheduled = false;
    _status = TutorialTargetStatus.waiting;
    if (!widget.enabled) return;

    _fallbackTimer = Timer(widget.fallbackTimeout, _useFallback);
    _probeTimer = Timer.periodic(widget.probeInterval, (_) => _probeTarget());
    _scheduleProbe();
  }

  void _cancelObservation() {
    _fallbackTimer?.cancel();
    _probeTimer?.cancel();
    _fallbackTimer = null;
    _probeTimer = null;
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

    if (TutorialTargetProbe.isReady(widget.targetKey)) {
      _setStatus(TutorialTargetStatus.ready);
      return;
    }
  }

  void _useFallback() {
    if (!mounted || !widget.enabled) return;
    _setStatus(TutorialTargetStatus.fallback);
  }

  void _setStatus(TutorialTargetStatus status) {
    if (_status == status || !mounted) return;
    _cancelObservation();
    setState(() => _status = status);
    widget.onStatusChanged?.call(status);
  }

  @override
  Widget build(BuildContext context) {
    // A parent rebuild often means navigation or responsive composition just
    // mounted the target. Probe that concrete layout event immediately.
    _scheduleProbe();
    return widget.builder(context, _status);
  }
}
