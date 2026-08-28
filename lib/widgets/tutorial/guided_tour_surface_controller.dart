import 'dart:async';

import 'package:flutter/material.dart';

import '../../tutorial/guided_tour_plan.dart';

enum GuidedTourSurface { root, statistics, trophies, profile }

/// Owns the route-local lifecycle used by guided-tour secondary surfaces.
///
/// Product navigation remains in MainPage. This object only tracks the
/// temporary route context, readiness signals, and manual-close distinction so
/// a dismissed mobile page or desktop dialog cannot leave an orphan overlay.
class GuidedTourSurfaceController {
  GuidedTourSurface _surface = GuidedTourSurface.root;
  BuildContext? _routeContext;
  Completer<void>? _surfaceReady;
  Completer<void>? _roadmapReady;
  int _generation = 0;
  bool _closingProgrammatically = false;
  bool _disposed = false;

  GuidedTourSurface get surface => _surface;
  int get generation => _generation;

  bool matches(GuidedTourSurface candidate) => _surface == candidate;

  GuidedTourDestination currentDestination(
    GuidedTourDestination rootDestination,
  ) => switch (_surface) {
    GuidedTourSurface.statistics => GuidedTourDestination.statistics,
    GuidedTourSurface.trophies => GuidedTourDestination.trophies,
    GuidedTourSurface.profile => GuidedTourDestination.profile,
    GuidedTourSurface.root => rootDestination,
  };

  int prepare(GuidedTourSurface surface) {
    _generation++;
    _routeContext = null;
    _surfaceReady = Completer<void>();
    _surface = surface;
    return _generation;
  }

  void registerRouteContext(BuildContext context) {
    if (_disposed) return;
    _routeContext = context;
    final generation = _generation;
    final ready = _surfaceReady;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || generation != _generation) return;
      if (ready != null && !ready.isCompleted) ready.complete();
    });
  }

  void beginRoadmapReadiness() {
    _complete(_roadmapReady);
    _roadmapReady = Completer<void>();
  }

  void reportRoadmapReady() => _complete(_roadmapReady);

  Future<void> waitFor(GuidedTourDestination destination) async {
    final readiness = destination == GuidedTourDestination.roadmap
        ? _roadmapReady?.future
        : _surface == GuidedTourSurface.root
        ? null
        : _surfaceReady?.future;
    if (readiness != null) {
      try {
        await readiness.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        // The step's missing-target policy owns the bounded fallback.
      }
    }
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<bool> close() async {
    if (_surface == GuidedTourSurface.root) return false;
    _closingProgrammatically = true;
    final routeContext = _routeContext;
    try {
      if (routeContext != null && routeContext.mounted) {
        await Navigator.of(routeContext).maybePop();
      }
    } finally {
      _resetSurface();
      _closingProgrammatically = false;
    }
    return true;
  }

  /// Returns true only when the user/system closed the current tour surface.
  bool handleRouteClosed(GuidedTourSurface surface, int generation) {
    if (_disposed || generation != _generation) return false;
    final interrupted = !_closingProgrammatically && _surface == surface;
    _resetSurface();
    return interrupted;
  }

  void dispose() {
    _disposed = true;
    _complete(_surfaceReady);
    _complete(_roadmapReady);
    _routeContext = null;
  }

  void _resetSurface() {
    _complete(_surfaceReady);
    _surface = GuidedTourSurface.root;
    _routeContext = null;
    _surfaceReady = null;
  }

  static void _complete(Completer<void>? completer) {
    if (completer != null && !completer.isCompleted) completer.complete();
  }
}
