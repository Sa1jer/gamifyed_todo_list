import 'package:flutter/material.dart';

import '../../utils.dart';

const _kPanelRadius = 14.0;

class AppPanel extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const AppPanel({super.key, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface(isDark),
        borderRadius: BorderRadius.circular(_kPanelRadius),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: child,
    );
  }
}

class PanelDivider extends StatelessWidget {
  final bool isDark;

  const PanelDivider({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: borderColor(isDark));
  }
}

class EmptyStateMessage extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateMessage({
    super.key,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final txt = textColor(isDark);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: sub, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: txt.withAlpha(isDark ? 220 : 230),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: sub.withAlpha(160), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
