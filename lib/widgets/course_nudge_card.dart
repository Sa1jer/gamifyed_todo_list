import 'package:flutter/material.dart';

import '../engines/course_nudge_engine.dart';
import '../utils.dart';
import 'shared.dart';

class CourseNudgeCard extends StatelessWidget {
  final CourseNudge nudge;
  final bool isDark;
  final VoidCallback onPrimary;
  final VoidCallback onDismiss;

  const CourseNudgeCard({
    super.key,
    required this.nudge,
    required this.isDark,
    required this.onPrimary,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = nudge.skill.color;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 14 : 10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(54)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: color.withAlpha(42)),
                ),
                child: Icon(_iconFor(nudge.kind), color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Следующая корректировка',
                      style: TextStyle(
                        color: color,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nudge.title,
                      style: TextStyle(
                        color: txt,
                        fontSize: 14.5,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF15151C) : Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: bdr.withAlpha(180)),
            ),
            child: Text(
              nudge.reason,
              style: TextStyle(
                color: sub,
                fontSize: 12.2,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SmallBtn(
                  label: nudge.actionLabel,
                  icon: _actionIconFor(nudge.kind),
                  color: color,
                  onTap: onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              PressFeedback(
                scale: 0.94,
                tooltip: 'Скрыть до следующего запуска',
                onTap: onDismiss,
                child: Text(
                  'Позже',
                  style: TextStyle(
                    color: sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(CourseNudgeKind kind) {
    return switch (kind) {
      CourseNudgeKind.createFocusQuest => Icons.flag_rounded,
      CourseNudgeKind.clarifyFocus => Icons.edit_note_rounded,
      CourseNudgeKind.addMinimumToTask => Icons.bolt_rounded,
      CourseNudgeKind.createStageQuest => Icons.add_task_rounded,
      CourseNudgeKind.clarifyGoal => Icons.track_changes_rounded,
    };
  }

  IconData _actionIconFor(CourseNudgeKind kind) {
    return switch (kind) {
      CourseNudgeKind.createFocusQuest ||
      CourseNudgeKind.createStageQuest => Icons.add,
      CourseNudgeKind.addMinimumToTask => Icons.bolt_rounded,
      CourseNudgeKind.clarifyFocus => Icons.rate_review_rounded,
      CourseNudgeKind.clarifyGoal => Icons.edit_rounded,
    };
  }
}
