import 'package:flutter/material.dart';

import '../../utils.dart';
import '../shared.dart';
import 'weekly_presentation_data.dart';
import 'weekly_section.dart';

class WeeklyXpChart extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;

  const WeeklyXpChart({super.key, required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final maxXp = summary.dayStats.fold<int>(
      0,
      (max, day) => day.xp > max ? day.xp : max,
    );

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.bar_chart,
      color: const Color(0xFFFFCC00),
      title: 'График XP',
      subtitle: 'Как распределялся рост по дням.',
      child: Column(
        children: [
          if (summary.completedTasks == 0)
            WeeklyAnalyticsEmptyState(
              icon: Icons.hourglass_empty,
              title: 'Неделя ещё пустая',
              subtitle: 'Закрой первый квест, и график начнёт жить.',
              isDark: isDark,
            )
          else
            ...summary.dayStats.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final ratio = maxXp == 0 ? 0.0 : day.xp / maxXp;
              return MotionListItem(
                key: ValueKey('week-day-${day.date.toIso8601String()}'),
                index: index,
                slide: 4,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 38,
                        child: Text(
                          _weekdayShort(day.date),
                          style: TextStyle(
                            color: sub,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = day.xp == 0
                                ? 4.0
                                : (constraints.maxWidth * ratio).clamp(
                                    16.0,
                                    constraints.maxWidth,
                                  );
                            return Stack(
                              children: [
                                Container(
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFCC00,
                                    ).withAlpha(22),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: kMotionProgress,
                                  curve: kMotionCurve,
                                  width: width,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: day.xp == 0
                                        ? sub.withAlpha(40)
                                        : const Color(0xFFFFCC00),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 9),
                      SizedBox(
                        width: 72,
                        child: Text(
                          '${day.xp} XP',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: day.xp == 0 ? sub : txt,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class WeeklySkillBreakdown extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;
  final Map<String, WeeklySkillVisual> skillVisuals;

  const WeeklySkillBreakdown({
    super.key,
    required this.summary,
    required this.isDark,
    required this.skillVisuals,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final stats = summary.skillStats;
    final maxXp = stats.fold<int>(
      0,
      (max, stat) => stat.xp > max ? stat.xp : max,
    );

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.auto_graph,
      color: const Color(0xFF4A9EFF),
      title: 'Навыки недели',
      subtitle: 'Какие направления двигали неделю',
      child: stats.isEmpty
          ? WeeklyAnalyticsEmptyState(
              icon: Icons.bolt,
              title: 'Пока нет лидера',
              subtitle:
                  'Когда появятся квесты, здесь будет видно вклад навыков.',
              isDark: isDark,
            )
          : Column(
              children: stats.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                final visual = skillVisuals[stat.skillId];
                final color = visual?.color ?? const Color(0xFF4A9EFF);
                final icon = visual?.icon ?? Icons.bolt;
                final progress = maxXp == 0 ? 0.0 : stat.xp / maxXp;
                return MotionListItem(
                  key: ValueKey('week-skill-${stat.skillId}'),
                  index: index,
                  slide: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      stat.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textColor(isDark),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${stat.xp} XP',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              XPBar(
                                progress: progress,
                                color: color,
                                height: 5,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                weeklyQuestCount(stat.tasksCompleted),
                                style: TextStyle(color: sub, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class WeeklyTaskList extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;
  final Map<String, WeeklySkillVisual> skillVisuals;

  const WeeklyTaskList({
    super.key,
    required this.summary,
    required this.isDark,
    required this.skillVisuals,
  });

  @override
  Widget build(BuildContext context) {
    final entries = summary.entries;
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.task_alt,
      color: const Color(0xFF34C759),
      title: 'Квесты недели',
      subtitle: 'Последние фактические закрытия',
      child: entries.isEmpty
          ? WeeklyAnalyticsEmptyState(
              icon: Icons.task_alt,
              title: 'Нет закрытых квестов',
              subtitle: 'Эта неделя пока ждёт первый выполненный шаг.',
              isDark: isDark,
            )
          : Column(
              children: entries.take(7).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final visual = skillVisuals[item.skillId];
                final color = visual?.color ?? const Color(0xFF4A9EFF);
                final icon = visual?.icon ?? Icons.bolt;
                return MotionListItem(
                  key: ValueKey(
                    'week-task-${item.id}-${item.at.millisecondsSinceEpoch}',
                  ),
                  index: index,
                  slide: 4,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF121219)
                          : const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: borderColor(isDark)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withAlpha(24),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(icon, color: color, size: 15),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.taskTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: txt,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.skillName} • ${formatShortDate(item.at)} ${formatTime(item.at)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: sub, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${item.xp}',
                          style: const TextStyle(
                            color: Color(0xFF34C759),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class WeeklyStreakRisks extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;
  final Map<String, WeeklySkillVisual> skillVisuals;

  const WeeklyStreakRisks({
    super.key,
    required this.summary,
    required this.isDark,
    required this.skillVisuals,
  });

  @override
  Widget build(BuildContext context) {
    final risks = summary.riskTasks;
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.local_fire_department,
      color: const Color(0xFFFF9500),
      title: 'Риски серии',
      subtitle: 'Повторяющиеся квесты, которые лучше мягко поддержать.',
      child: risks.isEmpty
          ? WeeklyAnalyticsEmptyState(
              icon: Icons.shield,
              title: 'Риски не горят',
              subtitle: 'Сейчас нет повторяющихся квестов на грани сброса.',
              isDark: isDark,
            )
          : Column(
              children: risks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                final visual = skillVisuals[task.skillId];
                final color = visual?.color ?? const Color(0xFFFF9500);
                return MotionListItem(
                  key: ValueKey('week-risk-${task.taskId}'),
                  index: index,
                  slide: 4,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(14),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: color.withAlpha(48)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.repeat, color: color, size: 17),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: txt,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${task.skillName} • серия ${task.streak} д. • ${formatResetLabel(task.nextResetAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: sub, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

String _weekdayShort(DateTime date) {
  const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  return weekdays[date.weekday - 1];
}
