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
  final MobileSecondaryHeader? header;
  final Widget child;

  const MobileSecondaryPage({
    super.key,
    required this.routeName,
    required this.backgroundColor,
    this.header,
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
        body: SafeArea(
          child: Column(
            children: [
              ?header,
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact journal-style header shared by mobile secondary routes.
///
/// The shell owns navigation geometry while each feature keeps control of its
/// title, supporting copy, and semantic accent.
class MobileSecondaryHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onBack;

  const MobileSecondaryHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = subtitle;
    final border = theme.dividerColor.withAlpha(170);

    return Semantics(
      container: true,
      header: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                key: ValueKey('mobile-secondary-back-$title'),
                tooltip: 'Назад',
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitleText != null && subtitleText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
