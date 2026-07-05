part of '../mastery_map_workspace.dart';

const _roadmapEngine = RoadmapEngine();
const _roadmapGoalAnchorTopOffset = 198.0;
const _roadmapGoalAnchorEstimatedHeight = 120.0;
const _roadmapGoalAnchorHorizontalPadding = 20.0;
const _roadmapGoalAnchorHeaderFontSize = 14.0;
const _roadmapGoalAnchorHeaderIconSize = 17.0;

Offset _feedbackOriginFor(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null) return Offset.zero;
  final topLeft = box.localToGlobal(Offset.zero);
  return Offset(topLeft.dx + box.size.width / 2, topLeft.dy + box.size.height);
}

double _roadmapGoalAnchorWidth(String text) {
  final goal = text.trim();
  final goalFontSize = _roadmapGoalAnchorGoalFontSize(goal);
  final headerWidth =
      _roadmapGoalAnchorHeaderIconSize +
      8 +
      _measureRoadmapAnchorText(
        'Цель пути',
        fontSize: _roadmapGoalAnchorHeaderFontSize,
      );
  final goalWidth = _measureRoadmapAnchorText(goal, fontSize: goalFontSize);
  final contentWidth = math.max(headerWidth, goalWidth);
  final width = contentWidth + _roadmapGoalAnchorHorizontalPadding * 2;
  return width.clamp(178.0, 340.0).toDouble();
}

double _roadmapGoalAnchorGoalFontSize(String text) {
  final length = text.trim().length;
  if (length <= 28) return 17.7;
  if (length <= 44) return 16.4;
  return 15.4;
}

double _measureRoadmapAnchorText(String text, {required double fontSize}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text.trim().isEmpty ? ' ' : text.trim(),
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900),
    ),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

class _RoadmapGoalAnchor extends StatelessWidget {
  final Skill skill;
  final bool isDark;

  const _RoadmapGoalAnchor({required this.skill, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final goal = skill.goal.trim();
    if (goal.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface(isDark).withAlpha(isDark ? 210 : 238),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: skill.color.withAlpha(isDark ? 70 : 54)),
          boxShadow: [
            BoxShadow(
              color: skill.color.withAlpha(isDark ? 28 : 20),
              blurRadius: 26,
              offset: const Offset(0, 13),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _roadmapGoalAnchorHorizontalPadding,
            16,
            _roadmapGoalAnchorHorizontalPadding,
            18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag_rounded,
                    color: skill.color,
                    size: _roadmapGoalAnchorHeaderIconSize,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Цель пути',
                    style: TextStyle(
                      color: skill.color,
                      fontSize: _roadmapGoalAnchorHeaderFontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                goal,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor(isDark),
                  fontSize: _roadmapGoalAnchorGoalFontSize(goal),
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoadmapTemplatePanel extends StatefulWidget {
  final Skill skill;
  final bool isDark;
  final ValueChanged<RoadmapTemplateConfig> onApply;
  final VoidCallback onHide;
  final bool sheetMode;

  const _RoadmapTemplatePanel({
    required this.skill,
    required this.isDark,
    required this.onApply,
    required this.onHide,
    this.sheetMode = false,
    super.key,
  });

  @override
  State<_RoadmapTemplatePanel> createState() => _RoadmapTemplatePanelState();
}

class _RoadmapTemplatePanelState extends State<_RoadmapTemplatePanel> {
  RoadmapTemplate _template = RoadmapTemplate.simple;
  int _customPathCount = 1;
  int _stagesPerPath = 3;

  int get _pathCount => switch (_template) {
    RoadmapTemplate.simple => 1,
    RoadmapTemplate.normal => 2,
    RoadmapTemplate.hard => 3,
    RoadmapTemplate.custom => _customPathCount,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final color = widget.skill.color;
    final config = RoadmapTemplateConfig(
      template: _template,
      customPathCount: _customPathCount,
      stagesPerPath: _stagesPerPath,
    );
    final content = Padding(
      padding: EdgeInsets.all(widget.sheetMode ? 18 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.route, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Шаблоны путей',
                      style: TextStyle(
                        color: textColor(isDark),
                        fontSize: 13.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Выберите одну структуру пути для навыка.',
                      style: TextStyle(
                        color: subtext(isDark),
                        fontSize: 10.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              key: const ValueKey('desktop-roadmap-template-grid'),
              crossAxisCount: constraints.maxWidth >= 430 ? 4 : 2,
              childAspectRatio: 1.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _RoadmapTemplateChoice(
                  label: 'Простой',
                  subtitle: '1 дорога',
                  icon: Icons.linear_scale_rounded,
                  selected: _template == RoadmapTemplate.simple,
                  isDark: isDark,
                  color: color,
                  onTap: () => setState(() {
                    _template = RoadmapTemplate.simple;
                    _customPathCount = 1;
                  }),
                ),
                _RoadmapTemplateChoice(
                  label: 'Нормальный',
                  subtitle: '2 дороги',
                  icon: Icons.call_split_rounded,
                  selected: _template == RoadmapTemplate.normal,
                  isDark: isDark,
                  color: color,
                  onTap: () => setState(() {
                    _template = RoadmapTemplate.normal;
                    _customPathCount = 2;
                  }),
                ),
                _RoadmapTemplateChoice(
                  label: 'Сложный',
                  subtitle: '3 дороги',
                  icon: Icons.hub_outlined,
                  selected: _template == RoadmapTemplate.hard,
                  isDark: isDark,
                  color: color,
                  onTap: () => setState(() {
                    _template = RoadmapTemplate.hard;
                    _customPathCount = 3;
                  }),
                ),
                _RoadmapTemplateChoice(
                  label: 'Свой',
                  subtitle: 'Точная настройка',
                  icon: Icons.tune_rounded,
                  selected: _template == RoadmapTemplate.custom,
                  isDark: isDark,
                  color: color,
                  onTap: () =>
                      setState(() => _template = RoadmapTemplate.custom),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          _RoadmapCounterControl(
            isDark: isDark,
            color: color,
            label: 'Этапов в дороге',
            value: _stagesPerPath,
            onDecrease: _stagesPerPath <= 1
                ? null
                : () => setState(() => _stagesPerPath--),
            onIncrease: _stagesPerPath >= 12
                ? null
                : () => setState(() => _stagesPerPath++),
          ),
          AnimatedSwitcher(
            duration: kMotionStandard,
            switchInCurve: kMotionCurve,
            switchOutCurve: kMotionExitCurve,
            child: _template == RoadmapTemplate.custom
                ? Padding(
                    key: const ValueKey('custom-path-count'),
                    padding: const EdgeInsets.only(top: 7),
                    child: _RoadmapCounterControl(
                      isDark: isDark,
                      color: color,
                      label: 'Дорог',
                      value: _pathCount,
                      onDecrease: _pathCount <= 1
                          ? null
                          : () => setState(() => _customPathCount--),
                      onIncrease: _pathCount >= 12
                          ? null
                          : () => setState(() => _customPathCount++),
                    ),
                  )
                : const SizedBox(key: ValueKey('fixed-path-count')),
          ),
          if (config.canOverloadFocus) ...[
            const SizedBox(height: 7),
            _RoadmapTemplateWarning(isDark: isDark),
          ],
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: PressFeedback(
                  scale: 0.96,
                  onTap: () => widget.onApply(config),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_road,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Применить',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PressFeedback(
                scale: 0.94,
                onTap: widget.onHide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 7, 0, 2),
                  child: Text(
                    widget.sheetMode ? 'Закрыть' : 'Скрыть',
                    style: TextStyle(
                      color: subtext(isDark),
                      fontSize: 11.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (widget.sheetMode) {
      return Material(color: Colors.transparent, child: content);
    }
    return Container(
      key: const ValueKey('desktop-roadmap-template-surface'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11121A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: content,
    );
  }
}

class _RoadmapTemplateChoice extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;

  const _RoadmapTemplateChoice({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$label, $subtitle',
    child: PressFeedback(
      scale: 0.98,
      onTap: onTap,
      child: AnimatedContainer(
        duration: kMotionStandard,
        curve: kMotionCurve,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.13)
              : isDark
              ? const Color(0xFF171821)
              : const Color(0xFFF4F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : borderColor(isDark),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : subtext(isDark), size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? color : textColor(isDark),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subtext(isDark), fontSize: 9.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RoadmapCounterControl extends StatelessWidget {
  final bool isDark;
  final Color color;
  final String label;
  final int value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _RoadmapCounterControl({
    required this.isDark,
    required this.color,
    required this.label,
    required this.value,
    this.onDecrease,
    this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: surface(isDark).withAlpha(isDark ? 170 : 235),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor(isDark),
                fontSize: 11.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _RoadmapCounterButton(
            icon: Icons.remove,
            isDark: isDark,
            color: color,
            onTap: onDecrease,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _RoadmapCounterButton(
            icon: Icons.add,
            isDark: isDark,
            color: color,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _RoadmapCounterButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final Color color;
  final VoidCallback? onTap;

  const _RoadmapCounterButton({
    required this.icon,
    required this.isDark,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    final button = Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: active ? color.withAlpha(28) : surface(isDark),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: active ? color.withAlpha(150) : borderColor(isDark),
        ),
      ),
      child: Icon(
        icon,
        color: active ? color : subtext(isDark).withAlpha(120),
        size: 15,
      ),
    );
    if (!active) return button;
    return PressFeedback(scale: 0.9, onTap: onTap!, child: button);
  }
}

class _RoadmapTemplateWarning extends StatelessWidget {
  final bool isDark;

  const _RoadmapTemplateWarning({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFFC247);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 24 : 34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: color, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Больше 5 дорог может перегрузить систему квестами и вниманием.',
              style: TextStyle(
                color: textColor(isDark),
                fontSize: 10.6,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCanvasAction extends StatelessWidget {
  final bool isDark;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _MapCanvasAction({
    required this.isDark,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF4A9EFF),
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      scale: 0.96,
      tooltip: label,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: surface(isDark).withAlpha(isDark ? 225 : 238),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(100)),
          boxShadow: [
            BoxShadow(color: color.withAlpha(isDark ? 25 : 18), blurRadius: 14),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
