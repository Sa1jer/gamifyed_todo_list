import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../models.dart';
import '../mobile_journal_tokens.dart';
import '../shared.dart';

class MobileMomentumRow extends StatelessWidget {
  final int todayXp;
  final int completedToday;
  final int streak;
  final bool isDark;

  const MobileMomentumRow({
    super.key,
    required this.todayXp,
    required this.completedToday,
    required this.streak,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      MobileMomentumCard(
        key: const ValueKey('mobile-momentum-xp'),
        icon: Icons.bolt_rounded,
        value: '+$todayXp',
        label: 'XP сегодня',
        color: MobileJournalTokens.amber,
        isDark: isDark,
      ),
      MobileMomentumCard(
        key: const ValueKey('mobile-momentum-completed'),
        icon: Icons.task_alt_rounded,
        value: '$completedToday',
        label: 'Закрыто сегодня',
        color: MobileJournalTokens.violet,
        isDark: isDark,
      ),
      if (streak > 0)
        MobileMomentumCard(
          key: const ValueKey('mobile-momentum-streak'),
          icon: Icons.local_fire_department_rounded,
          value: '$streak дн.',
          label: 'Серия',
          color: const Color(0xFFFF5C45),
          isDark: isDark,
        ),
    ];

    return Row(
      key: const ValueKey('mobile-momentum-row'),
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          Expanded(child: cards[index]),
          if (index != cards.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class MobileMomentumCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const MobileMomentumCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 84),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
    decoration: BoxDecoration(
      color: color.withAlpha(isDark ? 13 : 10),
      borderRadius: BorderRadius.circular(MobileJournalTokens.radiusMedium),
      border: Border.all(color: color.withAlpha(isDark ? 46 : 55)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: MobileJournalTokens.text(isDark),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: MobileJournalTokens.muted(isDark),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class MobileSkillOverviewCard extends StatelessWidget {
  final Skill skill;
  final int activeQuestCount;
  final bool isDark;
  final int reorderIndex;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MobileSkillOverviewCard({
    super.key,
    required this.skill,
    required this.activeQuestCount,
    required this.isDark,
    required this.reorderIndex,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = skill.progress.clamp(0.0, 1.0);
    final progressLabel = '${(progress * 100).round()}%';
    final semanticsProgress = 'Прогресс уровня: $progressLabel';

    ActionPane actions() => ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.44,
      children: [
        SlidableAction(
          onPressed: (_) => onEdit(),
          backgroundColor: const Color(0xFF4A9EFF),
          foregroundColor: Colors.white,
          icon: Icons.edit_rounded,
          label: 'Править',
          borderRadius: BorderRadius.circular(18),
        ),
        SlidableAction(
          onPressed: (_) => onDelete(),
          backgroundColor: const Color(0xFFFF3B30),
          foregroundColor: Colors.white,
          icon: Icons.delete_outline_rounded,
          label: 'Удалить',
          borderRadius: BorderRadius.circular(18),
        ),
      ],
    );

    return Slidable(
      key: ValueKey('mobile-skill-slidable-${skill.id}'),
      startActionPane: actions(),
      endActionPane: actions(),
      child: Semantics(
        button: true,
        label:
            '${skill.name}, уровень ${skill.level}, активных квестов $activeQuestCount',
        value: semanticsProgress,
        hint: 'Долгое нажатие открывает действия с навыком',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onLongPress,
          child: PressFeedback(
            scale: 0.985,
            onTap: onTap,
            child: Container(
              key: ValueKey('mobile-skill-chip-${skill.id}'),
              constraints: const BoxConstraints(minHeight: 94),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: MobileJournalTokens.surface(isDark),
                borderRadius: BorderRadius.circular(
                  MobileJournalTokens.radiusLarge,
                ),
                border: Border.all(color: skill.color.withAlpha(62)),
              ),
              child: Row(
                children: [
                  _MobileGoalRing(
                    value: progress,
                    color: skill.color,
                    icon: skill.icon,
                    semanticsLabel: semanticsProgress,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: MobileJournalTokens.text(isDark),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Ур. ${skill.level} · $activeQuestCount ${_questWord(activeQuestCount)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: MobileJournalTokens.muted(isDark),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (skill.goal.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            skill.goal,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: MobileJournalTokens.muted(isDark),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        progressLabel,
                        key: ValueKey('mobile-skill-progress-${skill.id}'),
                        style: TextStyle(
                          color: skill.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      ReorderableDelayedDragStartListener(
                        key: ValueKey('compact-skill-reorder-${skill.id}'),
                        index: reorderIndex,
                        child: Tooltip(
                          message: 'Переместить навык',
                          child: SizedBox.square(
                            dimension: 44,
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: MobileJournalTokens.muted(isDark),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileGoalRing extends StatelessWidget {
  final double value;
  final Color color;
  final IconData icon;
  final String semanticsLabel;

  const _MobileGoalRing({
    required this.value,
    required this.color,
    required this.icon,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: semanticsLabel,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value),
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 360),
        curve: MobileJournalTokens.curve,
        builder: (context, animatedValue, child) => CustomPaint(
          painter: _MobileGoalRingPainter(value: animatedValue, color: color),
          child: child,
        ),
        child: SizedBox.square(
          dimension: 62,
          child: Center(child: Icon(icon, color: color, size: 24)),
        ),
      ),
    );
  }
}

class _MobileGoalRingPainter extends CustomPainter {
  final double value;
  final Color color;

  const _MobileGoalRingPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final ring = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      ring,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = color.withAlpha(36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value > 0) {
      canvas.drawArc(
        ring,
        -math.pi / 2,
        math.pi * 2 * value.clamp(0, 1),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MobileGoalRingPainter oldDelegate) =>
      value != oldDelegate.value || color != oldDelegate.color;
}

class MobileJournalEmptySkills extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCreate;

  const MobileJournalEmptySkills({
    super.key,
    required this.isDark,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: MobileJournalTokens.surface(isDark),
      borderRadius: BorderRadius.circular(MobileJournalTokens.radiusLarge),
      border: Border.all(color: MobileJournalTokens.outline(isDark)),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.explore_outlined,
          color: MobileJournalTokens.violet,
          size: 30,
        ),
        const SizedBox(height: 8),
        Text(
          'Создай первый навык',
          style: TextStyle(
            color: MobileJournalTokens.text(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'После этого здесь появятся квесты и фокус.',
          textAlign: TextAlign.center,
          style: TextStyle(color: MobileJournalTokens.muted(isDark)),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            backgroundColor: MobileJournalTokens.violet,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Создать навык'),
        ),
      ],
    ),
  );
}

String _questWord(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return 'квест';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'квеста';
  }
  return 'квестов';
}
