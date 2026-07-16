import 'package:flutter/material.dart';

import '../../utils.dart';
import '../shared.dart';
import 'weekly_presentation_data.dart';
import 'weekly_section.dart';

class WeeklyProcrastinationInsightsCard extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;
  final Map<String, WeeklySkillVisual> skillVisuals;
  final ValueChanged<String> onStartMinimum;

  const WeeklyProcrastinationInsightsCard({
    super.key,
    required this.summary,
    required this.isDark,
    required this.skillVisuals,
    required this.onStartMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final insights = summary.procrastination;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final hasInsights =
        insights.stalled.isNotEmpty ||
        insights.oversized.isNotEmpty ||
        insights.minimumStarts.isNotEmpty;
    final primary = insights.primaryInsight;
    final primaryCanStart =
        primary != null &&
        insights.minimumStarts.any((item) => item.taskId == primary.taskId);

    return WeeklyAnalyticsSection(
      isDark: isDark,
      icon: Icons.next_plan,
      color: const Color(0xFF4A9EFF),
      title: 'Что поможет продолжить',
      subtitle: 'Один мягкий следующий шаг вместо панели тревог.',
      child: hasInsights
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (primary != null)
                  _PrimaryInsightCard(
                    insight: primary,
                    isDark: isDark,
                    skillVisuals: skillVisuals,
                    label: insights.primaryLabel,
                    onStartMinimum: primaryCanStart ? onStartMinimum : null,
                  ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF121219)
                        : const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: borderColor(isDark)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
                      collapsedIconColor: sub,
                      iconColor: const Color(0xFF4A9EFF),
                      title: Text(
                        'Детали: ${insights.totalCount} пунктов для разбора',
                        style: TextStyle(
                          color: txt,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        'Детали доступны, но не требуют внимания сразу.',
                        style: TextStyle(color: sub, fontSize: 10.5),
                      ),
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 760;
                            final columns = [
                              _InsightColumn(
                                isDark: isDark,
                                title: 'Зависшие',
                                subtitle: 'Давно без движения',
                                icon: Icons.hourglass_bottom,
                                color: const Color(0xFFFF3B30),
                                items: insights.stalled,
                                skillVisuals: skillVisuals,
                                emptyText: 'Нет зависших квестов',
                              ),
                              _InsightColumn(
                                isDark: isDark,
                                title: 'Крупные',
                                subtitle: 'Нужен мягкий вход',
                                icon: Icons.account_tree,
                                color: const Color(0xFFFF9500),
                                items: insights.oversized,
                                skillVisuals: skillVisuals,
                                emptyText: 'Крупные квесты под контролем',
                              ),
                              _InsightColumn(
                                isDark: isDark,
                                title: 'Лёгкий старт',
                                subtitle: 'Можно начать сейчас',
                                icon: Icons.play_circle,
                                color: const Color(0xFF34C759),
                                items: insights.minimumStarts,
                                skillVisuals: skillVisuals,
                                emptyText: 'Нет доступных лёгких стартов',
                                onStartMinimum: onStartMinimum,
                              ),
                            ];

                            if (!wide) {
                              return Column(
                                children: columns
                                    .map(
                                      (column) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: column,
                                      ),
                                    )
                                    .toList(),
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: columns[0]),
                                const SizedBox(width: 10),
                                Expanded(child: columns[1]),
                                const SizedBox(width: 10),
                                Expanded(child: columns[2]),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : WeeklyAnalyticsEmptyState(
              icon: Icons.shield,
              title: 'Неделя выглядит устойчиво',
              subtitle: 'Квесты достаточно понятны для продолжения без аудита.',
              isDark: isDark,
            ),
    );
  }
}

class _PrimaryInsightCard extends StatelessWidget {
  final WeeklyTaskInsight insight;
  final bool isDark;
  final Map<String, WeeklySkillVisual> skillVisuals;
  final String label;
  final ValueChanged<String>? onStartMinimum;

  const _PrimaryInsightCard({
    required this.insight,
    required this.isDark,
    required this.skillVisuals,
    required this.label,
    required this.onStartMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final color = insight.minimumAction != null
        ? const Color(0xFF34C759)
        : const Color(0xFF4A9EFF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withAlpha(46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: color, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: txt,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Это не тревога, а самый полезный следующий штрих недели.',
            style: TextStyle(color: sub, fontSize: 10.8, height: 1.25),
          ),
          const SizedBox(height: 10),
          _InsightTaskTile(
            insight: insight,
            isDark: isDark,
            skillVisuals: skillVisuals,
            color: color,
            onStartMinimum: onStartMinimum,
          ),
        ],
      ),
    );
  }
}

class _InsightColumn extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<WeeklyTaskInsight> items;
  final Map<String, WeeklySkillVisual> skillVisuals;
  final String emptyText;
  final ValueChanged<String>? onStartMinimum;

  const _InsightColumn({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.items,
    required this.skillVisuals,
    required this.emptyText,
    this.onStartMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121219) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: txt,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: sub, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                color: sub.withAlpha(9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emptyText,
                textAlign: TextAlign.center,
                style: TextStyle(color: sub, fontSize: 11),
              ),
            )
          else
            ...items.take(3).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final insight = entry.value;
              return MotionListItem(
                key: ValueKey('$title-${insight.taskId}'),
                index: index,
                slide: 4,
                child: _InsightTaskTile(
                  insight: insight,
                  isDark: isDark,
                  skillVisuals: skillVisuals,
                  color: color,
                  onStartMinimum: onStartMinimum,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _InsightTaskTile extends StatelessWidget {
  final WeeklyTaskInsight insight;
  final bool isDark;
  final Map<String, WeeklySkillVisual> skillVisuals;
  final Color color;
  final ValueChanged<String>? onStartMinimum;

  const _InsightTaskTile({
    required this.insight,
    required this.isDark,
    required this.skillVisuals,
    required this.color,
    required this.onStartMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final skillVisual = skillVisuals[insight.skillId];
    final skillColor = skillVisual?.color ?? color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: skillColor.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: skillColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                skillVisual?.icon ?? Icons.bolt,
                color: skillColor,
                size: 15,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  insight.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: txt,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            insight.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: sub, fontSize: 10.5, height: 1.25),
          ),
          if (insight.minimumAction != null) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Минимум: ${insight.minimumAction}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF34C759),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onStartMinimum != null) ...[
                  const SizedBox(width: 8),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Сделать лёгкий старт',
                    onTap: () => onStartMinimum!(insight.taskId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withAlpha(24),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF34C759).withAlpha(70),
                        ),
                      ),
                      child: const Text(
                        'Старт',
                        style: TextStyle(
                          color: Color(0xFF34C759),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
