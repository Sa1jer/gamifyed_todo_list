import 'package:flutter/material.dart';

class MobileSecondaryNavigator {
  int _routeDepth = 0;

  Future<void> push(
    BuildContext context,
    WidgetBuilder pageBuilder, {
    bool allowNested = false,
  }) async {
    if (!context.mounted || (!allowNested && _routeDepth > 0)) return;
    _routeDepth += 1;
    try {
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(fullscreenDialog: true, builder: pageBuilder),
      );
    } finally {
      if (_routeDepth > 0) _routeDepth -= 1;
    }
  }
}

/// Shared route frame for mobile-only secondary product surfaces.
///
/// Feature content keeps ownership of its journal header and scroll view. This
/// shell only establishes one full-screen, SafeArea-aware route contract.
class MobileSecondaryPage extends StatelessWidget {
  final String routeName;
  final Color backgroundColor;
  final Widget child;

  const MobileSecondaryPage({
    super.key,
    required this.routeName,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: routeName,
      child: Scaffold(
        key: ValueKey('mobile-secondary-page-$routeName'),
        backgroundColor: backgroundColor,
        body: SafeArea(child: SizedBox.expand(child: child)),
      ),
    );
  }
}
