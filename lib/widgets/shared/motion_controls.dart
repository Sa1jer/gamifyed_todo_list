import 'package:flutter/material.dart';

const kMotionFast = Duration(milliseconds: 90);
const kMotionStandard = Duration(milliseconds: 180);
const kMotionSlow = Duration(milliseconds: 240);
const kMotionProgress = Duration(milliseconds: 560);
const kMotionXp = Duration(milliseconds: 840);
const kMotionListStaggerStep = Duration(milliseconds: 14);
const kMotionListStaggerMaxIndex = 6;
const kMotionCurve = Curves.easeOutCubic;
const kMotionExitCurve = Curves.easeInCubic;

class PressFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final String? tooltip;

  const PressFeedback({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.96,
    this.tooltip,
  });

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: kMotionFast,
        curve: kMotionCurve,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.86 : 1,
          duration: kMotionFast,
          child: widget.child,
        ),
      ),
    );
    final interactiveButton = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: button,
    );
    final tooltip = widget.tooltip;
    return tooltip == null
        ? interactiveButton
        : Tooltip(message: tooltip, child: interactiveButton);
  }
}
