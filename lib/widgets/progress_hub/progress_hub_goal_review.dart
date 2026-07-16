import 'package:flutter/material.dart';

import '../../engines/course_nudge_engine.dart';
import '../../engines/progress_engine.dart';
import '../../models.dart';
import '../../utils.dart';
import '../course_nudge_card.dart';
import '../goal_header.dart';
import '../shared.dart';

class ProgressReviewBlock extends StatelessWidget {
  final bool isDark;
  final CourseNudge? nudge;
  final VoidCallback? onApplyNudge;
  final VoidCallback? onDismissNudge;
  final Widget reviewCard;

  const ProgressReviewBlock({
    super.key,
    required this.isDark,
    required this.nudge,
    required this.onApplyNudge,
    required this.onDismissNudge,
    required this.reviewCard,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15151C) : const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9EFF).withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Color(0xFF4A9EFF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review цели',
                      style: TextStyle(
                        color: txt,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Коротко сверяем курс и, если нужно, делаем одну маленькую корректировку.',
                      style: TextStyle(
                        color: sub,
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          reviewCard,
          if (nudge != null) ...[
            const SizedBox(height: 12),
            CourseNudgeCard(
              nudge: nudge!,
              isDark: isDark,
              onPrimary: onApplyNudge ?? () {},
              onDismiss: onDismissNudge ?? () {},
            ),
          ],
        ],
      ),
    );
  }
}

class GoalProgressOverview extends StatelessWidget {
  final ProgressSnapshot snapshot;
  final bool isDark;
  final ValueChanged<Skill> onReviewSkill;

  const GoalProgressOverview({
    super.key,
    required this.snapshot,
    required this.isDark,
    required this.onReviewSkill,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final visibleGoals = snapshot.visibleGoals;
    final needsReviewCount = snapshot.needsReview.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Цели и путь',
                    style: TextStyle(
                      color: txt,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Где ты сейчас по навыкам и какой этап двигается дальше.',
                    style: TextStyle(color: sub, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (needsReviewCount > 0)
              TaskBadge(
                icon: Icons.rate_review,
                label: '$needsReviewCount review',
                color: const Color(0xFFFF9500),
              ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 620
                ? 1
                : visibleGoals.length;
            const spacing = 10.0;
            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final goal in visibleGoals)
                  SizedBox(
                    width: cardWidth,
                    child: _GoalProgressCard(
                      snapshot: goal,
                      isDark: isDark,
                      onReview: () => onReviewSkill(goal.skill),
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

class _GoalProgressCard extends StatelessWidget {
  final SkillProgressSnapshot snapshot;
  final bool isDark;
  final VoidCallback onReview;

  const _GoalProgressCard({
    required this.snapshot,
    required this.isDark,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final skill = snapshot.skill;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final stage = snapshot.currentStage;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121219) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: snapshot.needsAdjust
              ? const Color(0xFFFF9500).withAlpha(80)
              : borderColor(isDark),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: skill.color.withAlpha(24),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(skill.icon, color: skill.color, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: txt,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GoalHeader(
                      skill: skill,
                      isDark: isDark,
                      maxLines: 1,
                      emptyText: snapshot.basisLabel,
                    ),
                  ],
                ),
              ),
              Text(
                snapshot.percentLabel,
                style: TextStyle(
                  color: skill.color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          XPBar(
            progress: snapshot.percent.clamp(0.0, 1.0),
            color: skill.color,
            height: 5,
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TaskBadge(
                icon: Icons.route,
                label: stage == null ? snapshot.basisLabel : stage.title,
                color: skill.color,
              ),
              TaskBadge(
                icon: Icons.calendar_view_week,
                label: snapshot.weeklyQuestCount == 0
                    ? 'неделя тихая'
                    : '+${snapshot.weeklyDelta} XP',
                color: const Color(0xFF34C759),
              ),
              if (snapshot.needsAdjust)
                TaskBadge(
                  icon: Icons.hourglass_bottom,
                  label: 'пора review',
                  color: const Color(0xFFFF9500),
                ),
            ],
          ),
          if (snapshot.recentWins.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Свежая победа: ${snapshot.recentWins.first.taskTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: sub,
                fontSize: 11.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (snapshot.needsAdjust) ...[
            const SizedBox(height: 10),
            SmallBtn(
              label: 'Сделать review',
              icon: Icons.rate_review,
              color: const Color(0xFFFF9500),
              onTap: onReview,
            ),
          ],
        ],
      ),
    );
  }
}
