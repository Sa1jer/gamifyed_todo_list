import 'package:flutter/material.dart';

import '../../models.dart';
import '../desktop_journal_tokens.dart';
import '../shared.dart';

class DesktopSelectedSkillHeader extends StatelessWidget {
  final Skill skill;
  final DesktopJournalTokens tokens;
  final VoidCallback onAddTask;
  final int totalQuestCount;

  const DesktopSelectedSkillHeader({
    super.key,
    required this.skill,
    required this.tokens,
    required this.totalQuestCount,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final goal = skill.goal.trim();

    Widget emblem(double size) => KeyedSubtree(
      key: ValueKey('desktop-skill-emblem-${skill.id}'),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: skill.progress,
              strokeWidth: 4,
              backgroundColor: skill.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(skill.color),
            ),
            Icon(skill.icon, color: skill.color, size: size * 0.4),
          ],
        ),
      ),
    );

    Widget skillTitle({required bool compact}) => KeyedSubtree(
      key: ValueKey('desktop-skill-title-${skill.id}'),
      child: Text(
        skill.name,
        maxLines: compact ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: tokens.text,
          fontSize: compact ? 18 : 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    Widget goalLabel() => KeyedSubtree(
      key: ValueKey('desktop-skill-goal-${skill.id}'),
      child: Text(
        goal,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: tokens.mutedText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    Widget identityRow({required bool compact, required bool reflowGoal}) {
      final titleAndLevel = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: skillTitle(compact: compact)),
          const SizedBox(width: DesktopJournalTokens.selectedSkillHeaderRowGap),
          DesktopLevelPill(
            level: skill.level,
            color: skill.color,
            tokens: tokens,
          ),
        ],
      );
      if (goal.isEmpty) return titleAndLevel;
      if (reflowGoal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [titleAndLevel, const SizedBox(height: 4), goalLabel()],
        );
      }
      return Row(
        children: [
          Flexible(child: skillTitle(compact: compact)),
          const SizedBox(width: DesktopJournalTokens.selectedSkillHeaderRowGap),
          DesktopLevelPill(
            level: skill.level,
            color: skill.color,
            tokens: tokens,
          ),
          const SizedBox(width: 12),
          Flexible(child: goalLabel()),
        ],
      );
    }

    Widget progressRow({required bool stackValue}) {
      final progressTrack = KeyedSubtree(
        key: ValueKey('desktop-skill-progress-track-${skill.id}'),
        child: DesktopProgressBar(
          value: skill.progress,
          color: skill.color,
          background: tokens.raisedSurface,
          height: 7,
          level: skill.level,
        ),
      );
      final value = Text(
        '${skill.xp} / ${skill.xpNeeded} XP',
        style: TextStyle(
          color: tokens.mutedText,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      );
      return KeyedSubtree(
        key: ValueKey('desktop-skill-xp-row-${skill.id}'),
        child: stackValue
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: double.infinity, child: progressTrack),
                  const SizedBox(height: 6),
                  value,
                ],
              )
            : Row(
                children: [
                  Expanded(child: progressTrack),
                  const SizedBox(width: 12),
                  value,
                ],
              ),
      );
    }

    Widget questCount() => KeyedSubtree(
      key: ValueKey('desktop-skill-quest-count-${skill.id}'),
      child: Text(
        'Всего квестов: $totalQuestCount',
        style: TextStyle(
          color: tokens.mutedText,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Semantics(
      container: true,
      label:
          '${skill.name}, уровень ${skill.level}${goal.isEmpty ? '' : ', цель: $goal'}, ${skill.xp} из ${skill.xpNeeded} XP',
      child: Container(
        key: ValueKey('desktop-raised-skill-header-${skill.id}'),
        padding: DesktopJournalTokens.selectedSkillHeaderPadding,
        decoration: BoxDecoration(
          color: skill.color.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: skill.color.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(
              color: skill.color.withValues(alpha: 0.035),
              blurRadius: 18,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720 || textScale >= 1.6;
            final iconSize = compact
                ? DesktopJournalTokens.selectedSkillHeaderCompactIconSize
                : DesktopJournalTokens.selectedSkillHeaderIconSize;
            final remainingForContent =
                constraints.maxWidth -
                iconSize -
                (DesktopJournalTokens.selectedSkillHeaderContentGap * 2) -
                DesktopJournalTokens.selectedSkillHeaderActionWidth;
            final moveActionBelow =
                remainingForContent < 280 || textScale >= 1.8;
            final contentWidth = moveActionBelow
                ? constraints.maxWidth -
                      iconSize -
                      DesktopJournalTokens.selectedSkillHeaderContentGap
                : remainingForContent;
            final reflowGoal = textScale >= 1.3 || contentWidth < 440;
            final stackXpValue = textScale >= 1.6 || contentWidth < 250;
            final button = _DesktopSelectedSkillPrimaryButton(
              key: ValueKey('desktop-add-task-${skill.id}'),
              label: 'Новый квест',
              icon: Icons.add_rounded,
              color: skill.color,
              onTap: onAddTask,
            );
            final contentBlock = KeyedSubtree(
              key: ValueKey('desktop-skill-content-block-${skill.id}'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  identityRow(compact: compact, reflowGoal: reflowGoal),
                  const SizedBox(
                    height: DesktopJournalTokens.selectedSkillHeaderRowGap,
                  ),
                  progressRow(stackValue: stackXpValue),
                  const SizedBox(height: 6),
                  questCount(),
                ],
              ),
            );
            final action = SizedBox(
              width: DesktopJournalTokens.selectedSkillHeaderActionWidth,
              child: button,
            );

            if (moveActionBelow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      emblem(iconSize),
                      const SizedBox(
                        width:
                            DesktopJournalTokens.selectedSkillHeaderContentGap,
                      ),
                      Expanded(child: contentBlock),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                emblem(iconSize),
                const SizedBox(
                  width: DesktopJournalTokens.selectedSkillHeaderContentGap,
                ),
                Expanded(child: contentBlock),
                const SizedBox(
                  width: DesktopJournalTokens.selectedSkillHeaderContentGap,
                ),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}

class DesktopLevelPill extends StatelessWidget {
  final int level;
  final Color color;
  final DesktopJournalTokens tokens;

  const DesktopLevelPill({
    super.key,
    required this.level,
    required this.color,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Ур. $level',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class DesktopProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color background;
  final double height;
  final int? level;

  const DesktopProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.background,
    required this.height,
    this.level,
  });

  @override
  Widget build(BuildContext context) {
    return XPBar(
      progress: value,
      color: color,
      height: height,
      backgroundColor: background,
      level: level,
    );
  }
}

class _DesktopSelectedSkillPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DesktopSelectedSkillPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF171821);
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foreground,
        minimumSize: const Size(136, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}
