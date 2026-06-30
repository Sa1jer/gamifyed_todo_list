import 'package:flutter/material.dart';

import '../engines/goal_progress_engine.dart';
import '../models.dart';
import '../utils.dart';

class SkillGoalProgress extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final bool compact;
  final VoidCallback? onSetNextGoal;

  const SkillGoalProgress({
    super.key,
    required this.skill,
    required this.isDark,
    this.compact = false,
    this.onSetNextGoal,
  });

  @override
  Widget build(BuildContext context) {
    final progress = const GoalProgressEngine().snapshotForSkill(skill);
    final secondary = subtext(isDark);
    final title = progress.isEmpty
        ? 'Добавьте этапы'
        : progress.isComplete
        ? 'Цель достигнута'
        : 'Прогресс цели';
    final semanticsValue = progress.isEmpty
        ? 'Этапы не добавлены, 0%'
        : progress.percentLabel;

    return Semantics(
      label: 'Прогресс цели ${skill.name}',
      value: semanticsValue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: progress.isComplete ? skill.color : secondary,
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                progress.percentLabel,
                key: ValueKey('skill-goal-percent-${skill.id}'),
                style: TextStyle(
                  color: progress.isEmpty ? secondary : skill.color,
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (!progress.isEmpty) ...[
            SizedBox(height: compact ? 4 : 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                key: ValueKey('skill-goal-bar-${skill.id}'),
                value: progress.value,
                minHeight: compact ? 4 : 6,
                backgroundColor: skill.color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation(skill.color),
                semanticsLabel: 'Прогресс цели ${skill.name}',
                semanticsValue: progress.percentLabel,
              ),
            ),
          ],
          if (!compact && progress.isComplete) ...[
            const SizedBox(height: 5),
            Text(
              'Можно задать следующую цель',
              style: TextStyle(
                color: secondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (progress.isComplete && onSetNextGoal != null) ...[
            SizedBox(height: compact ? 6 : 8),
            TextButton.icon(
              key: ValueKey('set-next-goal-${skill.id}'),
              onPressed: onSetNextGoal,
              style: TextButton.styleFrom(
                foregroundColor: skill.color,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.flag_outlined, size: 16),
              label: const Text(
                'Задать следующую цель',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
