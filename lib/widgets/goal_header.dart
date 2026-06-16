import 'package:flutter/material.dart';

import '../models.dart';
import '../utils.dart';

class GoalHeader extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final bool compact;
  final bool outlined;
  final int maxLines;
  final String emptyText;

  const GoalHeader({
    super.key,
    required this.skill,
    required this.isDark,
    this.compact = true,
    this.outlined = false,
    this.maxLines = 1,
    this.emptyText = 'Цель пока не описана',
  });

  @override
  Widget build(BuildContext context) {
    final goal = skill.goal.trim();
    final text = goal.isEmpty ? emptyText : goal;
    final sub = subtext(isDark);
    final color = goal.isEmpty ? sub : skill.color;
    final metric = _metricLabel(skill.goalSpec);
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.flag_rounded,
            color: color,
            size: compact ? 13 : 16,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: sub,
              fontSize: compact ? 12 : 12.5,
              height: 1.2,
              fontWeight: compact ? FontWeight.w700 : FontWeight.w800,
            ),
          ),
        ),
        if (metric != null) ...[
          const SizedBox(width: 6),
          Text(
            metric,
            style: TextStyle(
              color: skill.color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );

    if (!outlined) return content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: skill.color.withAlpha(isDark ? 12 : 8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: skill.color.withAlpha(40)),
      ),
      child: content,
    );
  }

  String? _metricLabel(GoalSpec goal) {
    final target = goal.targetValue;
    final current = goal.currentValue;
    if (target == null || target <= 0 || current == null) return null;
    return '${((current / target).clamp(0.0, 1.0) * 100).round()}%';
  }
}
