import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../analytics/analytics_read_model.dart';
import '../../models.dart';
import '../desktop_journal_tokens.dart';

class DesktopStatisticsSummaryStrip extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final int todayXp;
  final int weekXp;
  final AnalyticsSkillSummary? mainSkill;
  final Skill? mainSkillIdentity;

  const DesktopStatisticsSummaryStrip({
    super.key,
    required this.tokens,
    required this.todayXp,
    required this.weekXp,
    required this.mainSkill,
    required this.mainSkillIdentity,
  });

  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('desktop-statistics-summary-strip'),
    children: [
      Expanded(
        child: _summary(
          Icons.today_outlined,
          'Сегодня',
          '$todayXp XP',
          tokens.streakAmber,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _summary(
          Icons.trending_up,
          'Неделя',
          '$weekXp XP',
          tokens.successGreen,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _summary(
          mainSkillIdentity?.icon ?? Icons.star_outline,
          'Главный навык',
          mainSkill == null
              ? 'Нет данных'
              : '${mainSkill!.name} · ${mainSkill!.weeklyXp} XP',
          mainSkillIdentity?.color ?? tokens.mutedText,
        ),
      ),
    ],
  );

  Widget _summary(IconData icon, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: TextStyle(
                color: tokens.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
}

class DesktopStatisticsAnalyticsPanel extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final AnalyticsReadModel week;
  final List<Skill> skills;

  const DesktopStatisticsAnalyticsPanel({
    super.key,
    required this.tokens,
    required this.week,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: tokens.cardSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: tokens.outline),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('XP ЗА НЕДЕЛЮ'),
          const SizedBox(height: 14),
          _DesktopStatisticsWeekBars(week: week, tokens: tokens),
          const SizedBox(height: 24),
          Divider(color: tokens.subtleOutline, height: 1),
          const SizedBox(height: 24),
          _label('XP ПО НАВЫКАМ'),
          const SizedBox(height: 12),
          if (skills.isEmpty)
            Text('Нет данных', style: TextStyle(color: tokens.mutedText))
          else
            ...skills.map(
              (skill) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: skill.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        skill.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.text,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${week.skillById(skill.id)?.weeklyXp ?? 0}',
                      style: TextStyle(
                        color: skill.color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _label(String value) => Text(
    value,
    style: TextStyle(
      color: tokens.mutedText,
      fontSize: 10.5,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.7,
    ),
  );
}

class _DesktopStatisticsWeekBars extends StatelessWidget {
  final AnalyticsReadModel week;
  final DesktopJournalTokens tokens;

  const _DesktopStatisticsWeekBars({required this.week, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final dailyXp = week.days.map((day) => day.xp).toList(growable: false);
    final maxValue = dailyXp.fold<int>(1, math.max);
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Semantics(
      label: 'Недельный XP: ${dailyXp.join(', ')}',
      child: SizedBox(
        height: 96,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
            7,
            (index) => Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 9,
                    height: 8 + 55 * (dailyXp[index] / maxValue),
                    decoration: BoxDecoration(
                      color: tokens.profilePurple.withValues(
                        alpha: dailyXp[index] == 0 ? 0.25 : 0.85,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    labels[index],
                    style: TextStyle(color: tokens.mutedText, fontSize: 9.5),
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
