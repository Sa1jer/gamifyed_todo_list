import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'shared.dart';

class DailyVictoriesDialog extends StatelessWidget {
  final AppState state;
  final bool fullScreen;

  const DailyVictoriesDialog({
    super.key,
    required this.state,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final bg = surface(isDark);
    final summary = _DailyVictorySummary.fromState(state);

    final content = Container(
      width: fullScreen ? double.infinity : 860,
      constraints: fullScreen
          ? const BoxConstraints()
          : const BoxConstraints(maxHeight: 720),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(fullScreen ? 0 : 24),
        border: fullScreen ? null : Border.all(color: bdr),
        boxShadow: fullScreen
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 92 : 30),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00).withAlpha(26),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Color(0xFFFFCC00),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Победы дня',
                        style: TextStyle(
                          color: txt,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatShortDate(summary.today)} • итог сегодняшнего рывка',
                        style: TextStyle(color: sub, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                PressFeedback(
                  scale: 0.94,
                  tooltip: 'Закрыть победы дня',
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: sub, size: 22),
                ),
              ],
            ),
          ),
          Container(height: 1, color: bdr),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MotionListItem(
                    index: 0,
                    child: _VictoryHero(summary: summary, isDark: isDark),
                  ),
                  const SizedBox(height: 12),
                  MotionListItem(
                    index: 1,
                    child: _VictoryMetrics(summary: summary, isDark: isDark),
                  ),
                  const SizedBox(height: 12),
                  _VictoryOverview(summary: summary, isDark: isDark),
                  const SizedBox(height: 12),
                  MotionListItem(
                    index: 5,
                    child: _VictoryTimeline(
                      entries: summary.entries,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(child: SizedBox.expand(child: content)),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: content,
    );
  }
}

class _DailyVictorySummary {
  final DateTime today;
  final List<HistoryEntry> entries;
  final List<_SkillVictoryStat> skillStats;
  final List<_VictoryEvent> events;
  final HistoryEntry? bestWin;
  final int totalXp;

  const _DailyVictorySummary({
    required this.today,
    required this.entries,
    required this.skillStats,
    required this.events,
    required this.bestWin,
    required this.totalXp,
  });

  factory _DailyVictorySummary.fromState(AppState state) {
    final today = dateOnly(DateTime.now());
    final entries = List<HistoryEntry>.of(state.completionHistoryForDate(today))
      ..sort((a, b) => b.at.compareTo(a.at));
    final totalXp = entries.fold<int>(0, (sum, entry) => sum + entry.xp);

    final skillStatsById = <String, _SkillVictoryStat>{};
    for (final entry in entries) {
      final current = skillStatsById[entry.skillId];
      if (current == null) {
        skillStatsById[entry.skillId] = _SkillVictoryStat(
          skillId: entry.skillId,
          name: entry.skillName,
          icon: entry.skillIcon,
          color: entry.skillColor,
          xp: entry.xp,
          quests: 1,
        );
      } else {
        current.xp += entry.xp;
        current.quests += 1;
      }
    }

    final skillStats = skillStatsById.values.toList()
      ..sort((a, b) {
        final byXp = b.xp.compareTo(a.xp);
        if (byXp != 0) return byXp;
        return b.quests.compareTo(a.quests);
      });

    HistoryEntry? bestWin;
    if (entries.isNotEmpty) {
      final rankedEntries = List<HistoryEntry>.of(entries)
        ..sort((a, b) => b.xp.compareTo(a.xp));
      bestWin = rankedEntries.first;
    }

    final skillsById = {for (final skill in state.skills) skill.id: skill};
    final events = <_VictoryEvent>[
      for (final chest in state.rewardChests.where(
        (chest) => isSameDate(chest.unlockedAt, today),
      ))
        _VictoryEvent(
          title: chest.title,
          subtitle: '${rewardRarityLabel[chest.rarity]} сундук получен',
          icon: Icons.redeem,
          color: rewardRarityColor[chest.rarity] ?? const Color(0xFFFFCC00),
          at: chest.unlockedAt,
        ),
      for (final buff in state.buffs.where(
        (buff) => isSameDate(buff.createdAt, today),
      ))
        _VictoryEvent(
          title: buff.title,
          subtitle:
              'Пассивный эффект • +${buff.bonusPercent}% XP • ${_chargeCount(buff.charges)}',
          icon: Icons.bolt,
          color: const Color(0xFF34C759),
          at: buff.createdAt,
        ),
      for (final achievement in state.achievements.where(
        (achievement) =>
            achievement.unlockedAt != null &&
            isSameDate(achievement.unlockedAt!, today),
      ))
        _VictoryEvent(
          title: achievement.def?.name ?? 'Достижение открыто',
          subtitle: achievement.def?.description ?? 'Новый рубеж в профиле',
          icon: achievement.def?.icon ?? Icons.emoji_events,
          color: achievement.def?.color ?? const Color(0xFFFFCC00),
          at: achievement.unlockedAt!,
        ),
      for (final boss in state.bosses.where(
        (boss) =>
            boss.defeatedAt != null && isSameDate(boss.defeatedAt!, today),
      ))
        _VictoryEvent(
          title: boss.title,
          subtitle: 'Сопротивление преодолено',
          icon: Icons.shield,
          color: skillsById[boss.skillId]?.color ?? const Color(0xFFFF2D55),
          at: boss.defeatedAt!,
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return _DailyVictorySummary(
      today: today,
      entries: entries,
      skillStats: skillStats,
      events: events,
      bestWin: bestWin,
      totalXp: totalXp,
    );
  }

  int get completedQuests => entries.length;
  int get improvedSkills => skillStats.length;
  bool get hasWins => completedQuests > 0 || events.isNotEmpty;

  String get dayToneLabel {
    if (completedQuests >= 7 || totalXp >= 220) return 'Сильный день';
    if (completedQuests >= 5 || totalXp >= 150) return 'Большой рывок';
    if (completedQuests >= 3 || totalXp >= 80) return 'День роста';
    if (completedQuests >= 1) return 'Победа дня';
    return 'День ждёт старта';
  }

  Color get dayToneColor {
    if (completedQuests >= 7 || totalXp >= 220) return const Color(0xFFFFCC00);
    if (completedQuests >= 5 || totalXp >= 150) return const Color(0xFFFF2D55);
    if (completedQuests >= 3 || totalXp >= 80) return const Color(0xFFFF9500);
    if (completedQuests >= 1) return const Color(0xFF34C759);
    return const Color(0xFF8E8E93);
  }
}

class _SkillVictoryStat {
  final String skillId;
  final String name;
  final IconData icon;
  final Color color;
  int xp;
  int quests;

  _SkillVictoryStat({
    required this.skillId,
    required this.name,
    required this.icon,
    required this.color,
    required this.xp,
    required this.quests,
  });
}

class _VictoryEvent {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime at;

  const _VictoryEvent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.at,
  });
}

class _VictoryHero extends StatelessWidget {
  final _DailyVictorySummary summary;
  final bool isDark;

  const _VictoryHero({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final heroColor = summary.hasWins
        ? const Color(0xFFFFCC00)
        : const Color(0xFF4A9EFF);
    final bestWin = summary.bestWin;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121219) : const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: heroColor.withAlpha(summary.hasWins ? 88 : 44),
        ),
        boxShadow: summary.hasWins
            ? [
                BoxShadow(
                  color: heroColor.withAlpha(isDark ? 16 : 20),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: heroColor.withAlpha(26),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: heroColor.withAlpha(48)),
            ),
            child: Icon(
              summary.hasWins ? Icons.auto_awesome : Icons.flag,
              color: heroColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary.hasWins
                            ? 'Сегодня ты стал сильнее'
                            : 'Первая победа ещё впереди',
                        style: TextStyle(
                          color: txt,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _TonePill(
                      label: summary.dayToneLabel,
                      color: summary.dayToneColor,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  bestWin == null
                      ? 'Закрой один маленький квест или лёгкий старт, и здесь появится итог дня.'
                      : 'Главная победа: “${bestWin.taskTitle}” принесла ${bestWin.xp} XP навыку ${bestWin.skillName}.',
                  style: TextStyle(color: sub, fontSize: 13.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryMetrics extends StatelessWidget {
  final _DailyVictorySummary summary;
  final bool isDark;

  const _VictoryMetrics({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth < 700;
        final itemWidth = twoColumns
            ? (constraints.maxWidth - 10) / 2
            : (constraints.maxWidth - 30) / 4;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricTile(
              width: itemWidth,
              isDark: isDark,
              icon: Icons.bolt,
              color: const Color(0xFFFFCC00),
              value: '${summary.totalXp}',
              label: 'XP сегодня',
            ),
            _MetricTile(
              width: itemWidth,
              isDark: isDark,
              icon: Icons.check_circle,
              color: const Color(0xFF34C759),
              value: '${summary.completedQuests}',
              label: 'Квестов закрыто',
            ),
            _MetricTile(
              width: itemWidth,
              isDark: isDark,
              icon: Icons.psychology,
              color: const Color(0xFF4A9EFF),
              value: '${summary.improvedSkills}',
              label: 'Навыков усилено',
            ),
            _MetricTile(
              width: itemWidth,
              isDark: isDark,
              icon: Icons.redeem,
              color: const Color(0xFFFF9500),
              value: '${summary.events.length}',
              label: 'Трофеев и событий',
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final double width;
  final bool isDark;
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MetricTile({
    required this.width,
    required this.isDark,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      width: width,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121219) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: txt,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: sub, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryOverview extends StatelessWidget {
  final _DailyVictorySummary summary;
  final bool isDark;

  const _VictoryOverview({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760;
        final skills = MotionListItem(
          index: 2,
          child: _SkillWinsSection(summary: summary, isDark: isDark),
        );
        final events = MotionListItem(
          index: 3,
          child: _EventsSection(summary: summary, isDark: isDark),
        );

        if (narrow) {
          return Column(children: [skills, const SizedBox(height: 12), events]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: skills),
            const SizedBox(width: 12),
            Expanded(child: events),
          ],
        );
      },
    );
  }
}

class _SkillWinsSection extends StatelessWidget {
  final _DailyVictorySummary summary;
  final bool isDark;

  const _SkillWinsSection({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxXp = summary.skillStats.fold<int>(
      1,
      (maxValue, stat) => stat.xp > maxValue ? stat.xp : maxValue,
    );

    return _SectionShell(
      isDark: isDark,
      title: 'Навыки, которые окрепли',
      subtitle: 'Где сегодня появился реальный прогресс',
      icon: Icons.psychology,
      color: const Color(0xFF4A9EFF),
      child: summary.skillStats.isEmpty
          ? _SoftEmpty(
              isDark: isDark,
              icon: Icons.flag,
              text:
                  'Пока нет усиленных навыков. Один квест уже изменит этот экран.',
            )
          : Column(
              children: [
                for (final stat in summary.skillStats.take(5))
                  _SkillVictoryTile(
                    stat: stat,
                    progress: stat.xp / maxXp,
                    isDark: isDark,
                  ),
              ],
            ),
    );
  }
}

class _EventsSection extends StatelessWidget {
  final _DailyVictorySummary summary;
  final bool isDark;

  const _EventsSection({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      isDark: isDark,
      title: 'Трофеи и события',
      subtitle: 'Сундуки, пассивные эффекты, достижения, сопротивление',
      icon: Icons.auto_awesome,
      color: const Color(0xFFFF9500),
      child: summary.events.isEmpty
          ? _SoftEmpty(
              isDark: isDark,
              icon: Icons.redeem,
              text:
                  'Событий пока нет. Они появятся после трофеев, пассивных эффектов и больших побед.',
            )
          : Column(
              children: [
                for (final event in summary.events.take(5))
                  _VictoryEventTile(event: event, isDark: isDark),
              ],
            ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _SectionShell({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121219) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: txt,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: sub, fontSize: 11.5)),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _SkillVictoryTile extends StatelessWidget {
  final _SkillVictoryStat stat;
  final double progress;
  final bool isDark;

  const _SkillVictoryTile({
    required this.stat,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: stat.color.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(stat.icon, color: stat.color, size: 18),
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
                          color: txt,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '+${stat.xp} XP',
                      style: TextStyle(
                        color: stat.color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                XPBar(progress: progress, color: stat.color, height: 5),
                const SizedBox(height: 4),
                Text(
                  _questCount(stat.quests),
                  style: TextStyle(color: sub, fontSize: 10.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryEventTile extends StatelessWidget {
  final _VictoryEvent event;
  final bool isDark;

  const _VictoryEventTile({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: event.color.withAlpha(24),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(event.icon, color: event.color, size: 17),
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
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: txt,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      formatTime(event.at),
                      style: TextStyle(color: sub, fontSize: 10.5),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  event.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: sub, fontSize: 11.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryTimeline extends StatelessWidget {
  final List<HistoryEntry> entries;
  final bool isDark;

  const _VictoryTimeline({required this.entries, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      isDark: isDark,
      title: 'Лента побед',
      subtitle: 'Что именно было закрыто сегодня',
      icon: Icons.timeline,
      color: const Color(0xFF34C759),
      child: entries.isEmpty
          ? _SoftEmpty(
              isDark: isDark,
              icon: Icons.check_circle_outline,
              text: 'Здесь появятся выполненные квесты сегодняшнего дня.',
            )
          : Column(
              children: [
                for (var i = 0; i < entries.take(7).length; i++)
                  MotionListItem(
                    index: i,
                    enabled: false,
                    child: _VictoryEntryTile(entry: entries[i], isDark: isDark),
                  ),
              ],
            ),
    );
  }
}

class _VictoryEntryTile extends StatelessWidget {
  final HistoryEntry entry;
  final bool isDark;

  const _VictoryEntryTile({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: entry.skillColor.withAlpha(isDark ? 12 : 10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: entry.skillColor.withAlpha(38)),
      ),
      child: Row(
        children: [
          Icon(entry.skillIcon, color: entry.skillColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.taskTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.skillName} • ${formatTime(entry.at)}',
                  style: TextStyle(color: sub, fontSize: 11.2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+${entry.xp} XP',
            style: TextStyle(
              color: entry.skillColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TonePill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _TonePill({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 22 : 18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(isDark ? 64 : 72)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SoftEmpty extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String text;

  const _SoftEmpty({
    required this.isDark,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: sub.withAlpha(isDark ? 12 : 10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sub.withAlpha(24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: sub.withAlpha(170), size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: sub, fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

String _questCount(int count) => '$count ${_questWord(count)}';

String _questWord(int count) {
  final lastTwo = count % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'квестов';
  return switch (count % 10) {
    1 => 'квест',
    2 || 3 || 4 => 'квеста',
    _ => 'квестов',
  };
}

String _chargeCount(int count) => '$count ${_chargeWord(count)}';

String _chargeWord(int count) {
  final lastTwo = count % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'зарядов';
  return switch (count % 10) {
    1 => 'заряд',
    2 || 3 || 4 => 'заряда',
    _ => 'зарядов',
  };
}
