import 'dart:async';

import 'package:flutter/material.dart';

import '../../tutorial/guided_tour_plan.dart';
import 'tutorial_target_readiness.dart';

class TutorialAnchorRegistry extends ChangeNotifier {
  final Map<TutorialAnchorId, GlobalKey> _keys = {};
  final Map<TutorialAnchorId, LayerLink> _links = {};
  final ChangeNotifier _disposeSignal = ChangeNotifier();
  bool _disposed = false;

  GlobalKey keyFor(TutorialAnchorId id) =>
      _keys.putIfAbsent(id, () => GlobalKey(debugLabel: id.name));

  LayerLink linkFor(TutorialAnchorId id) =>
      _links.putIfAbsent(id, LayerLink.new);

  bool isReady(TutorialAnchorId id) => TutorialTargetProbe.isReady(keyFor(id));

  Future<bool> waitUntilReady(
    TutorialAnchorId id, {
    Duration timeout = const Duration(milliseconds: 1200),
  }) {
    if (_disposed) return Future<bool>.value(false);
    return TutorialTargetProbe.waitUntilReady(
      keyFor(id),
      timeout: timeout,
      cancellation: _disposeSignal,
    );
  }

  Rect? rectFor(TutorialAnchorId id, RenderBox ancestor) {
    final target = keyFor(id).currentContext?.findRenderObject();
    if (!ancestor.attached ||
        !ancestor.hasSize ||
        target is! RenderBox ||
        !target.attached ||
        !target.hasSize ||
        target.size.isEmpty) {
      return null;
    }
    return Rect.fromPoints(
      ancestor.globalToLocal(target.localToGlobal(Offset.zero)),
      ancestor.globalToLocal(
        target.localToGlobal(target.size.bottomRight(Offset.zero)),
      ),
    );
  }

  void notifyAnchorChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _disposeSignal.notifyListeners();
    _disposeSignal.dispose();
    super.dispose();
  }
}

/// Stable semantic target for new tutorial-aware surfaces. Existing controls
/// may use [TutorialAnchorRegistry.keyFor] directly while they migrate.
class TutorialAnchorTarget extends StatelessWidget {
  const TutorialAnchorTarget({
    super.key,
    required this.registry,
    required this.id,
    required this.child,
  });

  final TutorialAnchorRegistry registry;
  final TutorialAnchorId id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (notification) {
        scheduleMicrotask(registry.notifyAnchorChanged);
        return false;
      },
      child: CompositedTransformTarget(
        link: registry.linkFor(id),
        child: SizeChangedLayoutNotifier(
          child: KeyedSubtree(key: registry.keyFor(id), child: child),
        ),
      ),
    );
  }
}
