import 'package:flutter/material.dart';

import '../../models.dart';
import '../../utils.dart';
import '../mobile_journal_tokens.dart';
import '../shared.dart';

class TaskStageContextCard extends StatelessWidget {
  final SkillTreeNode stage;
  final Color textColor;
  final Color subtextColor;
  final Color accent;
  final bool isDark;

  const TaskStageContextCard({
    super.key,
    required this.stage,
    required this.textColor,
    required this.subtextColor,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 14 : 9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withAlpha(48)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withAlpha(24),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.account_tree, color: accent, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Этап дорожной карты: ${stage.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Квест можно привязать к текущей ступени RoadMap.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TaskStageSuggestionCard extends StatelessWidget {
  final SkillTreeNode stage;
  final Color textColor;
  final Color subtextColor;
  final Color borderColor;
  final Color accent;
  final bool isDark;
  final VoidCallback onLink;

  const TaskStageSuggestionCard({
    super.key,
    required this.stage,
    required this.textColor,
    required this.subtextColor,
    required this.borderColor,
    required this.accent,
    required this.isDark,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17171F) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withAlpha(180)),
      ),
      child: Row(
        children: [
          Icon(Icons.route_rounded, color: accent, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Есть активный этап: ${stage.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Можно связать квест с текущей ступенью RoadMap.',
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SmallBtn(
            label: 'Привязать',
            icon: Icons.add_link,
            color: accent,
            onTap: onLink,
          ),
        ],
      ),
    );
  }
}

class TaskMinimumActionSection extends StatelessWidget {
  final bool enabled;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color fieldBackground;
  final Color textColor;
  final Color subtextColor;
  final Color borderColor;
  final Color accent;
  final bool isDark;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onTextChanged;

  const TaskMinimumActionSection({
    super.key,
    required this.enabled,
    required this.controller,
    required this.focusNode,
    required this.fieldBackground,
    required this.textColor,
    required this.subtextColor,
    required this.borderColor,
    required this.accent,
    required this.isDark,
    required this.onEnabledChanged,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fieldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.bolt_outlined, color: accent, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Минимальный шаг',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Лёгкий вход, если квест кажется тяжёлым',
                      style: TextStyle(color: subtextColor, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const ValueKey('minimum-action-toggle'),
                value: enabled,
                activeThumbColor: accent,
                onChanged: onEnabledChanged,
              ),
            ],
          ),
          MotionExpandable(
            expanded: enabled,
            expandedChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(color: textColor, fontSize: 13),
                minLines: 2,
                maxLines: 4,
                onChanged: onTextChanged,
                decoration: InputDecoration(
                  hintText: 'Например: открыть проект и сделать первый шаг',
                  hintStyle: TextStyle(color: subtextColor, fontSize: 12),
                  filled: true,
                  fillColor: surface(isDark),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: _inputBorder(borderColor),
                  enabledBorder: _inputBorder(borderColor),
                  focusedBorder: _inputBorder(accent.withAlpha(180)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color),
  );
}

class TaskXpSection extends StatelessWidget {
  final int xp;
  final int selectorValue;
  final int softCap;
  final String taskTypeLabel;
  final bool overCap;
  final Color subtextColor;
  final Color borderColor;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const TaskXpSection({
    super.key,
    required this.xp,
    required this.selectorValue,
    required this.softCap,
    required this.taskTypeLabel,
    required this.overCap,
    required this.subtextColor,
    required this.borderColor,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rewardColor = MobileJournalTokens.rewardGoldForeground(isDark);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withAlpha(180)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SubLbl('XP за квест', subtextColor),
              const Spacer(),
              PressFeedback(
                scale: 0.96,
                tooltip: 'Ввести XP числом',
                onTap: () => _editXp(context, rewardColor),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: MobileJournalTokens.rewardGoldBackground(isDark),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: MobileJournalTokens.rewardGoldBorder(isDark),
                    ),
                  ),
                  child: Text(
                    '$xp XP',
                    style: TextStyle(
                      color: rewardColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: selectorValue.toDouble(),
            min: 10,
            max: 500,
            divisions: 49,
            activeColor: rewardColor,
            inactiveColor: rewardColor.withAlpha(40),
            onChanged: (value) => onChanged(value.round()),
          ),
          AnimatedSize(
            duration: kMotionSlow,
            curve: kMotionCurve,
            child: overCap
                ? Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF9500).withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFF9500),
                          size: 15,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Не рекомендуется: лимит для «$taskTypeLabel» — $softCap XP.',
                            style: const TextStyle(
                              color: Color(0xFFFF9500),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _editXp(BuildContext context, Color rewardColor) async {
    final value = await showIntegerEditDialog(
      context,
      title: 'XP за квест',
      initialValue: xp,
      min: 10,
      max: 500,
      color: rewardColor,
      isDark: isDark,
      suffix: 'XP',
    );
    if (value != null && context.mounted) onChanged(value);
  }
}
