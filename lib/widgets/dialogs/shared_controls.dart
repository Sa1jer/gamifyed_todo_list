part of '../dialogs.dart';

class _DialogChoiceChip extends StatefulWidget {
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

  const _DialogChoiceChip({
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
  State<_DialogChoiceChip> createState() => _DialogChoiceChipState();
}

class _DialogChoiceChipState extends State<_DialogChoiceChip> {
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

class _IconChoiceButton extends StatefulWidget {
  final IconData icon;
  final bool selected;
  final Color color;
  final Color inactiveColor;
  final VoidCallback onTap;
  final bool mobile;
  final String semanticsLabel;
  final String? displayLabel;

  const _IconChoiceButton({
    required this.icon,
    required this.selected,
    required this.color,
    required this.inactiveColor,
    required this.onTap,
    this.mobile = false,
    this.semanticsLabel = 'Выбрать иконку',
    this.displayLabel,
  });

  @override
  State<_IconChoiceButton> createState() => _IconChoiceButtonState();
}

class _IconChoiceButtonState extends State<_IconChoiceButton> {
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
        ? widget.color.withAlpha(46)
        : (_hovered ? widget.color.withAlpha(14) : Colors.transparent);
    final outlineColor = selected
        ? widget.color.withAlpha(165)
        : (_hovered ? widget.color.withAlpha(60) : Colors.transparent);
    final iconColor = selected
        ? widget.color
        : (_hovered ? widget.color.withAlpha(220) : widget.inactiveColor);
    final iconTile = AnimatedContainer(
      duration: motion,
      curve: kMotionCurve,
      constraints: widget.mobile
          ? const BoxConstraints(minWidth: 44, minHeight: 44)
          : const BoxConstraints(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(widget.mobile ? 13 : 8),
        border: Border.all(color: outlineColor, width: 1.4),
        boxShadow: selected && widget.mobile
            ? [BoxShadow(color: widget.color.withAlpha(42), blurRadius: 10)]
            : null,
      ),
      child: Icon(widget.icon, size: widget.mobile ? 20 : 18, color: iconColor),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: widget.semanticsLabel,
      child: Tooltip(
        message: widget.semanticsLabel,
        child: MouseRegion(
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
              scale: _pressed && motion != Duration.zero ? 0.92 : 1,
              duration: motion,
              curve: kMotionCurve,
              child: widget.mobile
                  ? Column(
                      children: [
                        Expanded(child: iconTile),
                        const SizedBox(height: 3),
                        Text(
                          widget.displayLabel ?? widget.semanticsLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? widget.color
                                : widget.inactiveColor,
                            fontSize: 9,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : iconTile,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorChoiceButton extends StatefulWidget {
  final Color color;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final bool mobile;
  final String semanticsLabel;

  const _ColorChoiceButton({
    required this.color,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.mobile = false,
    this.semanticsLabel = 'Выбрать цвет',
  });

  @override
  State<_ColorChoiceButton> createState() => _ColorChoiceButtonState();
}

class _ColorChoiceButtonState extends State<_ColorChoiceButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final appReducedMotion =
        AppStateProvider.maybeOf(context)?.reducedMotion ?? false;
    final motion = MobileMotion.duration(
      context,
      appReducedMotion: appReducedMotion,
      normal: kMotionStandard,
    );
    final ringColor = widget.selected
        ? darken(widget.color, widget.isDark ? 0.05 : 0.2)
        : (_hovered
              ? widget.color.withAlpha(120)
              : widget.mobile
              ? widget.color.withAlpha(48)
              : Colors.transparent);
    final shadowAlpha = widget.selected
        ? 90
        : (_hovered ? 45 : (widget.mobile ? 24 : 0));

    final size = widget.mobile ? 40.0 : 28.0;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticsLabel,
      child: Tooltip(
        message: 'Выбрать цвет',
        child: MouseRegion(
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
              scale: _pressed && motion != Duration.zero ? 0.9 : 1,
              duration: motion,
              curve: kMotionCurve,
              child: AnimatedContainer(
                duration: motion,
                curve: kMotionCurve,
                width: size,
                height: size,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: widget.mobile ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: widget.mobile
                      ? BorderRadius.circular(13)
                      : null,
                  border: Border.all(
                    color: ringColor,
                    width: widget.selected ? 2 : 1,
                  ),
                  boxShadow: shadowAlpha == 0
                      ? null
                      : [
                          BoxShadow(
                            color: widget.color.withAlpha(shadowAlpha),
                            blurRadius: widget.selected ? 10 : 7,
                          ),
                        ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: widget.mobile ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: widget.mobile
                        ? BorderRadius.circular(9)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADD SKILL DIALOG
// FIX 1.0.7: Replaced "Ещё иконки" toggle with a single scrollable grid
//            showing all icons at once (2 rows visible, scrollable vertically).
// ═══════════════════════════════════════════════════════════════════════════════

typedef SkillSaveCallback =
    void Function(
      String name,
      String goal,
      List<String> checklist,
      Color color,
      IconData icon,
      List<SkillTreeNode> initialTreeNodes,
      InitialSkillQuestDraft? initialQuest,
    );

class InitialSkillQuestDraft {
  final String title;
  final String minimumAction;
  final String? treeNodeId;

  const InitialSkillQuestDraft({
    required this.title,
    required this.minimumAction,
    required this.treeNodeId,
  });
}

class FirstRunDialogHint extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const FirstRunDialogHint({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('first-run-dialog-hint'),
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 24 : 16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: color, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor(isDark),
                fontSize: 12.2,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
