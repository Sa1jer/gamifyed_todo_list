import 'package:flutter/material.dart';

import '../../utils.dart';
import 'weekly_presentation_data.dart';
import 'weekly_section.dart';

class WeeklyOverview extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;

  const WeeklyOverview({
    super.key,
    required this.summary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final storyTitle = summary.completedTasks == 0
        ? 'Неделя пока ждёт первый квест'
        : summary.topSkillName == null
        ? 'На этой неделе закрыто ${weeklyQuestCount(summary.completedTasks)}'
        : 'Главный навык недели — ${summary.topSkillName}';
    final storySubtitle = summary.completedTasks == 0
        ? 'Закрой один маленький квест или минимальный шаг, и здесь появится история роста.'
        : '${summary.completedTasks} ${weeklyQuestWord(summary.completedTasks)} · ${summary.totalXp} XP · ${summary.activeDays} активн. дн.';

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.auto_stories,
      color: const Color(0xFF34C759),
      title: 'Итог недели',
      subtitle: 'Сначала рост, потом детали.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withAlpha(14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF34C759).withAlpha(42)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withAlpha(24),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Color(0xFF34C759),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storyTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: txt,
                          fontSize: 14.5,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storySubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: sub,
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 440
                  ? 1
                  : constraints.maxWidth < 760
                  ? 2
                  : 4;
              const spacing = 10.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _WeeklyMetricCard(
                      isDark: isDark,
                      title: 'XP недели',
                      value: '${summary.totalXp}',
                      subtitle: summary.totalXp == 0
                          ? 'Пока без XP'
                          : '${summary.averageXpPerActiveDay} XP в активный день',
                      icon: Icons.bolt,
                      color: const Color(0xFFFFCC00),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _WeeklyMetricCard(
                      isDark: isDark,
                      title: 'Квесты',
                      value: '${summary.completedTasks}',
                      subtitle: summary.completedTasks == 0
                          ? 'Ещё не закрывались'
                          : '${summary.activeDays} активн. дн.',
                      icon: Icons.check_circle,
                      color: const Color(0xFF34C759),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _WeeklyMetricCard(
                      isDark: isDark,
                      title: 'Навыки',
                      value: '${summary.skillStats.length}',
                      subtitle: summary.topSkillName == null
                          ? 'Нет вклада'
                          : 'Лидер: ${summary.topSkillName}',
                      icon: Icons.auto_graph,
                      color: const Color(0xFF4A9EFF),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _WeeklyMetricCard(
                      isDark: isDark,
                      title: 'Серии',
                      value: summary.riskTasks.isEmpty
                          ? 'ок'
                          : '${summary.riskTasks.length}',
                      subtitle: summary.riskTasks.isEmpty
                          ? 'Спокойны'
                          : 'Есть риск сброса',
                      icon: Icons.local_fire_department,
                      color: const Color(0xFFFF9500),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeeklyMetricCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _WeeklyMetricCard({
    required this.isDark,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121219) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sub,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: txt,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: sub, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
