import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../mobile_journal_tokens.dart';
import '../shared.dart';

class DialogChoiceChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool selected;
  final Color backgroundColor;
  final Color borderColor;
  final Color inactiveTextColor;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final FontWeight selectedWeight;

  const DialogChoiceChip({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.backgroundColor,
    required this.borderColor,
    required this.inactiveTextColor,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    this.radius = 8,
    this.selectedWeight = FontWeight.w700,
  });

  @override
  State<DialogChoiceChip> createState() => _DialogChoiceChipState();
}

class _DialogChoiceChipState extends State<DialogChoiceChip> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final appReducedMotion =
        AppStateProvider.maybeOf(context)?.reducedMotion ?? false;
    final motion = MobileMotion.duration(
      context,
      appReducedMotion: appReducedMotion,
      normal: kMotionStandard,
    );
    final fillColor = selected
        ? widget.color.withAlpha(38)
        : (_hovered ? widget.color.withAlpha(16) : widget.backgroundColor);
    final outlineColor = selected
        ? widget.color.withAlpha(150)
        : (_hovered ? widget.color.withAlpha(70) : widget.borderColor);
    final labelColor = selected
        ? widget.color
        : (_hovered ? widget.color.withAlpha(220) : widget.inactiveTextColor);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed && motion != Duration.zero ? 0.97 : 1,
          duration: motion,
          curve: kMotionCurve,
          child: AnimatedContainer(
            duration: motion,
            curve: kMotionCurve,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(color: outlineColor),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: selected ? widget.selectedWeight : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
