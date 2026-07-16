import 'package:flutter/material.dart';

import '../../utils.dart';
import '../shared.dart';

class ProgressHubSection extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final int startIndex;
  final List<ProgressHubCard> cards;

  const ProgressHubSection({
    super.key,
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.startIndex,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: txt,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(color: sub, fontSize: 11.5)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 520
                ? 1
                : constraints.maxWidth >= 980
                ? 3
                : 2;
            const spacing = 12.0;
            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var i = 0; i < cards.length; i++)
                  SizedBox(
                    width: cardWidth,
                    child: MotionListItem(
                      key: ValueKey('$title-card-$i'),
                      index: startIndex + i,
                      child: cards[i],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class ProgressHubCard extends StatefulWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;

  const ProgressHubCard({
    super.key,
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  @override
  State<ProgressHubCard> createState() => _ProgressHubCardState();
}

class _ProgressHubCardState extends State<ProgressHubCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final txt = textColor(widget.isDark);
    final sub = subtext(widget.isDark);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: kMotionFast,
          curve: kMotionCurve,
          child: AnimatedContainer(
            duration: kMotionStandard,
            curve: kMotionCurve,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withAlpha(widget.isDark ? 12 : 10)
                  : widget.isDark
                  ? const Color(0xFF121219)
                  : const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered
                    ? widget.color.withAlpha(44)
                    : borderColor(widget.isDark),
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.color.withAlpha(widget.isDark ? 20 : 16),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: txt,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: sub, fontSize: 11.5),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: sub.withAlpha(150), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
