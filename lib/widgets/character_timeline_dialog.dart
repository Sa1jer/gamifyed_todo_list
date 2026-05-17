import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'shared.dart';

class CharacterTimelineDialog extends StatelessWidget {
  final AppState state;

  const CharacterTimelineDialog({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final bg = surface(isDark);
    final summary = _CharacterTimelineSummary.fromState(state);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 730),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: bdr),
          boxShadow: [
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
                      color: const Color(0xFFAF52DE).withAlpha(26),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_stories,
                      color: Color(0xFFAF52DE),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Летопись роста',
                          style: TextStyle(
                            color: txt,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Уровни, ранги, дерево навыков, боссы и важные недели',
                          style: TextStyle(color: sub, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть летопись',
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
                      child: _TimelineHero(summary: summary, isDark: isDark),
                    ),
                    const SizedBox(height: 12),
                    MotionListItem(
                      index: 1,
                      child: _TimelineMetrics(summary: summary, isDark: isDark),
                    ),
                    const SizedBox(height: 12),
                    MotionListItem(
                      index: 2,
                      child: _TimelineList(summary: summary, isDark: isDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TimelineKind { profile, skill, tree, boss, week, achievement }

class _CharacterTimelineSummary {
  final AppState state;
  final List<_TimelineEvent> events;
  final int masteredNodes;
  final int defeatedBosses;
  final int importantWeeks;

  const _CharacterTimelineSummary({
    required this.state,
    required this.events,
    required this.masteredNodes,
    required this.defeatedBosses,
    required this.importantWeeks,
  });

  factory _CharacterTimelineSummary.fromState(AppState state) {
    final events = <_TimelineEvent>[];
    final xpSources = <_XpTimelineSource>[];
    final skillSources = <String, List<_XpTimelineSource>>{};

    final completionEntries =
        state.completionHistoryByDate.values
            .expand((entries) => entries)
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at));

    for (final entry in completionEntries) {
      final source = _XpTimelineSource(
        at: entry.at,
        xp: entry.xp,
        skillId: entry.skillId,
        skillName: entry.skillName,
        skillColor: entry.skillColor,
        skillIcon: entry.skillIcon,
      );
      xpSources.add(source);
      skillSources.putIfAbsent(entry.skillId, () => []).add(source);
    }

    for (final skill in state.skills) {
      for (final node in skill.treeNodes.where((node) => node.isMastered)) {
        final masteredAt = node.masteredAt;
        if (masteredAt == null) continue;

        final source = _XpTimelineSource(
          at: masteredAt,
          xp: node.xpReward,
          skillId: skill.id,
          skillName: skill.name,
          skillColor: skill.color,
          skillIcon: skill.icon,
        );
        xpSources.add(source);
        skillSources.putIfAbsent(skill.id, () => []).add(source);

        events.add(
          _TimelineEvent(
            kind: _TimelineKind.tree,
            at: masteredAt,
            title: 'Освоен узел “${node.title}”',
            subtitle:
                '${skill.name} стал глубже • +${node.xpReward} XP за освоение',
            icon: Icons.account_tree,
            color: skill.color,
            importance: 72,
          ),
        );
      }
    }

    events.addAll(_buildProfileLevelEvents(xpSources));
    events.addAll(_buildSkillLevelEvents(skillSources));

    for (final boss in state.bosses.where((boss) => boss.defeatedAt != null)) {
      final skill = state.skills
          .where((item) => item.id == boss.skillId)
          .firstOrNull;
      events.add(
        _TimelineEvent(
          kind: _TimelineKind.boss,
          at: boss.defeatedAt!,
          title: 'Побеждён босс “${boss.title}”',
          subtitle: skill == null
              ? 'Сопротивление стало слабее'
              : '${skill.name}: сопротивление стало слабее',
          icon: Icons.shield,
          color: skill?.color ?? const Color(0xFFFF2D55),
          importance: 88,
        ),
      );
    }

    for (final achievement in state.achievements.where(
      (achievement) => achievement.unlockedAt != null,
    )) {
      final def = achievement.def;
      events.add(
        _TimelineEvent(
          kind: _TimelineKind.achievement,
          at: achievement.unlockedAt!,
          title: def?.name ?? 'Достижение открыто',
          subtitle: def?.description ?? 'Новый рубеж персонажа',
          icon: def?.icon ?? Icons.emoji_events,
          color: def?.color ?? const Color(0xFFFFCC00),
          importance: 68,
        ),
      );
    }

    final weekEvents = _buildWeekEvents(state);
    events.addAll(weekEvents);

    events.sort((a, b) {
      final byDate = b.at.compareTo(a.at);
      if (byDate != 0) return byDate;
      return b.importance.compareTo(a.importance);
    });

    return _CharacterTimelineSummary(
      state: state,
      events: events,
      masteredNodes: state.skills.fold<int>(
        0,
        (sum, skill) =>
            sum + skill.treeNodes.where((node) => node.isMastered).length,
      ),
      defeatedBosses: state.bosses.where((boss) => boss.isDefeated).length,
      importantWeeks: weekEvents.length,
    );
  }

  RankInfo get currentRank => profileRankForLevel(state.profile.level);
  int get currentLevel => state.profile.level;
  int get totalXp => state.profile.totalXpEarned;
  bool get hasEvents => events.isNotEmpty;
  List<_TimelineEvent> get visibleEvents => events.take(36).toList();
  int get hiddenEventsCount {
    final hidden = events.length - visibleEvents.length;
    return hidden < 0 ? 0 : hidden;
  }
}

class _TimelineEvent {
  final _TimelineKind kind;
  final DateTime at;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int importance;

  const _TimelineEvent({
    required this.kind,
    required this.at,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.importance,
  });

  String get kindLabel => switch (kind) {
    _TimelineKind.profile => 'Персонаж',
    _TimelineKind.skill => 'Навык',
    _TimelineKind.tree => 'Дерево',
    _TimelineKind.boss => 'Босс',
    _TimelineKind.week => 'Неделя',
    _TimelineKind.achievement => 'Трофей',
  };
}

class _XpTimelineSource {
  final DateTime at;
  final int xp;
  final String skillId;
  final String skillName;
  final Color skillColor;
  final IconData skillIcon;

  const _XpTimelineSource({
    required this.at,
    required this.xp,
    required this.skillId,
    required this.skillName,
    required this.skillColor,
    required this.skillIcon,
  });
}

List<_TimelineEvent> _buildProfileLevelEvents(List<_XpTimelineSource> sources) {
  final sorted = List<_XpTimelineSource>.of(sources)
    ..sort((a, b) => a.at.compareTo(b.at));
  final events = <_TimelineEvent>[];
  var level = 1;
  var xp = 0;
  var rank = profileRankForLevel(level);

  for (final source in sorted) {
    xp += source.xp;
    while (xp >= xpForLevel(level)) {
      xp -= xpForLevel(level);
      level++;
      final nextRank = profileRankForLevel(level);
      final rankChanged = nextRank.code != rank.code;
      events.add(
        _TimelineEvent(
          kind: _TimelineKind.profile,
          at: source.at,
          title: rankChanged
              ? 'Персонаж достиг ${nextRank.label}'
              : 'Персонаж получил уровень $level',
          subtitle: rankChanged
              ? 'Новый ранг открыт на уровне $level'
              : 'Накопленный опыт вывел персонажа на новый уровень',
          icon: rankChanged ? Icons.workspace_premium : Icons.trending_up,
          color: rankChanged ? nextRank.color : const Color(0xFF4A9EFF),
          importance: rankChanged ? 96 : 78,
        ),
      );
      rank = nextRank;
    }
  }

  return events;
}

List<_TimelineEvent> _buildSkillLevelEvents(
  Map<String, List<_XpTimelineSource>> sourcesBySkill,
) {
  final events = <_TimelineEvent>[];

  for (final skillSources in sourcesBySkill.values) {
    final sorted = List<_XpTimelineSource>.of(skillSources)
      ..sort((a, b) => a.at.compareTo(b.at));
    if (sorted.isEmpty) continue;

    var level = 1;
    var xp = 0;
    var rank = skillRankForLevel(level);

    for (final source in sorted) {
      xp += source.xp;
      while (xp >= xpForLevel(level)) {
        xp -= xpForLevel(level);
        level++;
        final nextRank = skillRankForLevel(level);
        final rankChanged = nextRank.code != rank.code;
        events.add(
          _TimelineEvent(
            kind: _TimelineKind.skill,
            at: source.at,
            title: rankChanged
                ? '${source.skillName} получил ранг “${nextRank.label}”'
                : '${source.skillName} вырос до уровня $level',
            subtitle: rankChanged
                ? 'Навык перешёл в новую ступень мастерства'
                : 'Регулярные квесты усилили навык',
            icon: source.skillIcon,
            color: rankChanged ? nextRank.color : source.skillColor,
            importance: rankChanged ? 86 : 64,
          ),
        );
        rank = nextRank;
      }
    }
  }

  return events;
}

List<_TimelineEvent> _buildWeekEvents(AppState state) {
  final events = <_TimelineEvent>[];

  for (final goal in state.weeklyGoals) {
    if (!goal.isCompleted) continue;
    final completedAt = goal.keyResults
        .where((result) => result.completedAt != null)
        .map((result) => result.completedAt!)
        .fold<DateTime?>(null, (latest, date) {
          if (latest == null || date.isAfter(latest)) return date;
          return latest;
        });

    events.add(
      _TimelineEvent(
        kind: _TimelineKind.week,
        at: completedAt ?? goal.updatedAt,
        title: 'Неделя закрыта: ${goal.title}',
        subtitle:
            '${goal.completedKeyResults}/${goal.keyResults.length} ${_keyResultWord(goal.keyResults.length)} выполнено',
        icon: Icons.flag_circle,
        color: const Color(0xFF34C759),
        importance: 82,
      ),
    );
  }

  final entriesByWeek = <DateTime, List<HistoryEntry>>{};
  for (final dayEntry in state.completionHistoryByDate.entries) {
    final weekStart = dayEntry.key.subtract(
      Duration(days: dayEntry.key.weekday - 1),
    );
    entriesByWeek.putIfAbsent(weekStart, () => []).addAll(dayEntry.value);
  }

  for (final weekEntry in entriesByWeek.entries) {
    final entries = weekEntry.value;
    final xp = entries.fold<int>(0, (sum, entry) => sum + entry.xp);
    if (xp < 180 && entries.length < 7) continue;

    final latest = entries.map((entry) => entry.at).fold<DateTime>(
      entries.first.at,
      (latest, date) {
        if (date.isAfter(latest)) return date;
        return latest;
      },
    );
    events.add(
      _TimelineEvent(
        kind: _TimelineKind.week,
        at: latest,
        title: 'Сильная неделя',
        subtitle: '$xp XP • ${_questCount(entries.length)} за неделю',
        icon: Icons.calendar_view_week,
        color: const Color(0xFFFF9500),
        importance: 70,
      ),
    );
  }

  return events;
}

class _TimelineHero extends StatelessWidget {
  final _CharacterTimelineSummary summary;
  final bool isDark;

  const _TimelineHero({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final rank = summary.currentRank;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121219) : const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rank.color.withAlpha(72)),
        boxShadow: [
          BoxShadow(
            color: rank.color.withAlpha(isDark ? 18 : 16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: rank.color.withAlpha(24),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: rank.color.withAlpha(54)),
            ),
            child: Icon(Icons.person_4, color: rank.color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Путь персонажа',
                      style: TextStyle(
                        color: txt,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _TimelinePill(
                      label: rank.label,
                      color: rank.color,
                      isDark: isDark,
                    ),
                    _TimelinePill(
                      label: 'Ур. ${summary.currentLevel}',
                      color: const Color(0xFF4A9EFF),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary.hasEvents
                      ? 'Здесь собраны события, которые меняли персонажа: ранги, освоение, боссы и сильные недели.'
                      : 'Летопись начнётся после первых больших событий: закрытых квестов, освоенных узлов и побед над боссами.',
                  style: TextStyle(color: sub, fontSize: 13.2, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMetrics extends StatelessWidget {
  final _CharacterTimelineSummary summary;
  final bool isDark;

  const _TimelineMetrics({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth < 720;
        final itemWidth = twoColumns
            ? (constraints.maxWidth - 10) / 2
            : (constraints.maxWidth - 30) / 4;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _TimelineMetricTile(
              width: itemWidth,
              isDark: isDark,
              icon: Icons.auto_stories,
              color: const Color(0xFFAF52DE),
              value: '${summary.events.length}',
              label: 'Событий в летописи',
            ),
            _TimelineMetricTile(
              width: itemWidth,
              isDark: isDark,
              icon: Icons.account_tree,
              color: const Color(0xFF4A9EFF),
              value: '${summary.masteredNodes}',
              label: 'Узлов освоено',
            ),
            _TimelineMetricTile(
              width: itemWidth,
              isDark: isDark,
              icon: Icons.shield,
              color: const Color(0xFFFF2D55),
              value: '${summary.defeatedBosses}',
              label: 'Боссов побеждено',
            ),
            _TimelineMetricTile(
              width: itemWidth,
              isDark: isDark,
              icon: Icons.calendar_view_week,
              color: const Color(0xFF34C759),
              value: '${summary.importantWeeks}',
              label: 'Важных недель',
            ),
          ],
        );
      },
    );
  }
}

class _TimelineMetricTile extends StatelessWidget {
  final double width;
  final bool isDark;
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _TimelineMetricTile({
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

class _TimelineList extends StatelessWidget {
  final _CharacterTimelineSummary summary;
  final bool isDark;

  const _TimelineList({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.timeline, color: Color(0xFFAF52DE), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Таймлайн событий',
                  style: TextStyle(
                    color: txt,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Обычные задачи остаются в журнале XP. Здесь только рубежи роста.',
            style: TextStyle(color: sub, fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          if (summary.events.isEmpty)
            _TimelineEmpty(isDark: isDark)
          else
            Column(
              children: [
                for (var i = 0; i < summary.visibleEvents.length; i++)
                  MotionListItem(
                    index: i,
                    child: _TimelineEventTile(
                      event: summary.visibleEvents[i],
                      isDark: isDark,
                      isLast: i == summary.visibleEvents.length - 1,
                    ),
                  ),
                if (summary.hiddenEventsCount > 0)
                  _TimelineOlderNote(
                    hiddenEventsCount: summary.hiddenEventsCount,
                    isDark: isDark,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimelineEventTile extends StatelessWidget {
  final _TimelineEvent event;
  final bool isDark;
  final bool isLast;

  const _TimelineEventTile({
    required this.event,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: event.color.withAlpha(24),
                shape: BoxShape.circle,
                border: Border.all(color: event.color.withAlpha(70)),
              ),
              child: Icon(event.icon, color: event.color, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 54,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: event.color.withAlpha(34),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: event.color.withAlpha(isDark ? 12 : 9),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: event.color.withAlpha(38)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          color: txt,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TimelinePill(
                      label: event.kindLabel,
                      color: event.color,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.subtitle,
                  style: TextStyle(color: sub, fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatShortDate(event.at)} • ${formatTime(event.at)}',
                  style: TextStyle(
                    color: sub.withAlpha(190),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineOlderNote extends StatelessWidget {
  final int hiddenEventsCount;
  final bool isDark;

  const _TimelineOlderNote({
    required this.hiddenEventsCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sub.withAlpha(isDark ? 12 : 10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sub.withAlpha(24)),
      ),
      child: Row(
        children: [
          Icon(Icons.unfold_more, color: sub.withAlpha(170), size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Ещё $hiddenEventsCount старых событий скрыто, чтобы летопись оставалась читаемой.',
              style: TextStyle(color: sub, fontSize: 11.8, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _TimelinePill({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 22 : 18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(isDark ? 64 : 72)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TimelineEmpty extends StatelessWidget {
  final bool isDark;

  const _TimelineEmpty({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: sub.withAlpha(isDark ? 12 : 10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sub.withAlpha(24)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_stories_outlined, color: sub, size: 34),
          const SizedBox(height: 10),
          Text(
            'Летопись пока пуста',
            style: TextStyle(
              color: sub,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Освой узел дерева, победи босса или закрой сильную неделю.',
            textAlign: TextAlign.center,
            style: TextStyle(color: sub.withAlpha(170), fontSize: 12),
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

String _keyResultWord(int count) {
  final lastTwo = count % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'ключевых результатов';
  return switch (count % 10) {
    1 => 'ключевой результат',
    2 || 3 || 4 => 'ключевых результата',
    _ => 'ключевых результатов',
  };
}
