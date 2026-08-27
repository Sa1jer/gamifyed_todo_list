import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../utils.dart';
import '../mobile_journal_tokens.dart';
import '../shared/motion_controls.dart';

enum SkillIconCategory {
  all('Все'),
  body('Тело'),
  mind('Разум'),
  creativity('Творчество'),
  work('Работа'),
  home('Быт');

  const SkillIconCategory(this.label);

  final String label;
}

class SkillIconOption {
  const SkillIconOption(this.icon, this.label, this.category);

  final IconData icon;
  final String label;
  final SkillIconCategory category;
}

class SkillCreatorNameError extends StatelessWidget {
  const SkillCreatorNameError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      key: const ValueKey('add-skill-name-error'),
      style: const TextStyle(
        color: Color(0xFFFF453A),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class DesktopSkillIconPickerDialog extends StatefulWidget {
  const DesktopSkillIconPickerDialog({
    super.key,
    required this.options,
    required this.selectedIcon,
    required this.accentColor,
    required this.isDark,
  });

  final List<SkillIconOption> options;
  final IconData selectedIcon;
  final Color accentColor;
  final bool isDark;

  @override
  State<DesktopSkillIconPickerDialog> createState() =>
      _DesktopSkillIconPickerDialogState();
}

class _DesktopSkillIconPickerDialogState
    extends State<DesktopSkillIconPickerDialog> {
  SkillIconCategory _category = SkillIconCategory.all;

  List<SkillIconOption> get _visibleOptions =>
      _category == SkillIconCategory.all
      ? widget.options
      : widget.options
            .where((option) => option.category == _category)
            .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final secondary = subtext(widget.isDark);
    final outline = borderColor(widget.isDark);
    return Dialog(
      key: const ValueKey('desktop-skill-icon-picker'),
      backgroundColor: surface(widget.isDark),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Все иконки',
                      style: TextStyle(
                        color: textColor(widget.isDark),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: secondary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: SkillIconCategory.values.map((category) {
                    final selected = category == _category;
                    return ChoiceChip(
                      key: ValueKey('skill-icon-category-${category.name}'),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = category),
                      label: Text(category.label),
                      showCheckmark: false,
                      selectedColor: widget.accentColor.withAlpha(
                        widget.isDark ? 38 : 22,
                      ),
                      side: BorderSide(
                        color: selected
                            ? widget.accentColor.withAlpha(130)
                            : outline,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? widget.accentColor : secondary,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                key: const ValueKey('skill-full-icon-grid'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _visibleOptions.length,
                itemBuilder: (context, index) {
                  final option = _visibleOptions[index];
                  final selected = option.icon == widget.selectedIcon;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: option.label,
                    child: Tooltip(
                      message: option.label,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, option.icon),
                        borderRadius: BorderRadius.circular(12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selected
                                ? widget.accentColor.withAlpha(
                                    widget.isDark ? 44 : 28,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? widget.accentColor.withAlpha(170)
                                  : outline.withAlpha(150),
                            ),
                          ),
                          child: Icon(
                            option.icon,
                            color: selected ? widget.accentColor : secondary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DesktopSkillIdentityPreview extends StatelessWidget {
  const DesktopSkillIdentityPreview({
    super.key,
    required this.icon,
    required this.color,
    required this.name,
    required this.goal,
    required this.isDark,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String name;
  final String goal;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const ValueKey('desktop-skill-live-preview'),
          width: 224,
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 24 : 14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(74)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: const ValueKey('skill-preview-icon'),
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 34 : 24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withAlpha(120), width: 1.4),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.trim().isEmpty ? 'Новый навык' : name.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: name.trim().isEmpty
                            ? subtext(isDark)
                            : textColor(isDark),
                        fontSize: 14.5,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.trim().isEmpty ? 'Цель появится здесь' : goal.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtext(isDark),
                        fontSize: 10.5,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(child: child),
      ],
    );
  }
}

class MobileSkillEmblemPreview extends StatelessWidget {
  const MobileSkillEmblemPreview({
    super.key,
    required this.icon,
    required this.color,
    required this.name,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final String name;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MobileMotion.reduced(
      context,
      appReducedMotion:
          AppStateProvider.maybeOf(context)?.reducedMotion ?? false,
    );
    final displayName = name.trim().isEmpty ? 'Твой новый навык' : name.trim();

    return Center(
      child: Column(
        children: [
          AnimatedContainer(
            key: const ValueKey('skill-preview-icon'),
            duration: reduceMotion ? Duration.zero : kMotionSlow,
            curve: kMotionCurve,
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 24 : 16),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: color.withAlpha(150), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(isDark ? 46 : 30),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : kMotionStandard,
              child: Icon(
                icon,
                key: ValueKey(icon.codePoint),
                color: color,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : kMotionStandard,
            child: Text(
              displayName,
              key: ValueKey(displayName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: name.trim().isEmpty
                    ? subtext(isDark)
                    : textColor(isDark),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobileSkillFormSection extends StatelessWidget {
  const MobileSkillFormSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle.isNotEmpty;
    return Column(
      key: ValueKey('mobile-skill-section-$title'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor(isDark),
            fontSize: hasSubtitle ? 14.5 : 15.5,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (hasSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: subtext(isDark),
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
