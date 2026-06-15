import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'shared.dart';
import 'weekly_review_card.dart';

class ProgressHubDialog extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final VoidCallback onOpenDailyVictories;
  final VoidCallback onOpenCharacterTimeline;
  final VoidCallback onOpenWeekly;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenBosses;
  final VoidCallback onOpenAchievements;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenRewards;

  const ProgressHubDialog({
    super.key,
    required this.state,
    required this.isDark,
    required this.onOpenDailyVictories,
    required this.onOpenCharacterTimeline,
    required this.onOpenWeekly,
    required this.onOpenStats,
    required this.onOpenCalendar,
    required this.onOpenBosses,
    required this.onOpenAchievements,
    required this.onOpenHistory,
    required this.onOpenRewards,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final availableWidth = size.width - 40;
    final availableHeight = size.height - 48;
    final dialogWidth = availableWidth < 360
        ? availableWidth
        : availableWidth.clamp(360.0, 620.0).toDouble();
    final maxHeight = availableHeight < 520
        ? availableHeight
        : availableHeight.clamp(520.0, 620.0).toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ProgressHubContent(
        state: state,
        isDark: isDark,
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: maxHeight),
        showCloseButton: true,
        subtitle: 'Что получилось, какой навык вырос и что продолжить.',
        onClose: () => Navigator.pop(context),
        onOpenDailyVictories: onOpenDailyVictories,
        onOpenCharacterTimeline: onOpenCharacterTimeline,
        onOpenWeekly: onOpenWeekly,
        onOpenStats: onOpenStats,
        onOpenCalendar: onOpenCalendar,
        onOpenBosses: onOpenBosses,
        onOpenAchievements: onOpenAchievements,
        onOpenHistory: onOpenHistory,
        onOpenRewards: onOpenRewards,
      ),
    );
  }
}

class ProgressHubContent extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final double? width;
  final BoxConstraints? constraints;
  final bool showCloseButton;
  final String subtitle;
  final VoidCallback? onClose;
  final VoidCallback onOpenDailyVictories;
  final VoidCallback onOpenCharacterTimeline;
  final VoidCallback onOpenWeekly;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenBosses;
  final VoidCallback onOpenAchievements;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenRewards;

  const ProgressHubContent({
    super.key,
    required this.state,
    required this.isDark,
    this.width,
    this.constraints,
    this.showCloseButton = false,
    this.subtitle = 'Что получилось, какой навык вырос и что продолжить.',
    this.onClose,
    required this.onOpenDailyVictories,
    required this.onOpenCharacterTimeline,
    required this.onOpenWeekly,
    required this.onOpenStats,
    required this.onOpenCalendar,
    required this.onOpenBosses,
    required this.onOpenAchievements,
    required this.onOpenHistory,
    required this.onOpenRewards,
  });

  @override
  Widget build(BuildContext context) {
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final story = _ProgressStorySnapshot.fromState(state);
    final unlockedAchievements = state.achievements
        .where((achievement) => achievement.isUnlocked)
        .length;
    final trophyValue = state.unopenedRewardChests.isNotEmpty
        ? '${state.unopenedRewardChests.length} новых'
        : state.activeBuffs.isNotEmpty
        ? 'эффекты активны'
        : 'нет событий';
    final resistanceValue = state.activeBossThreatCount > 0
        ? 'есть сопротивление'
        : state.activeBosses.isNotEmpty
        ? 'события пути'
        : 'спокойно';

    return Container(
      width: width,
      constraints: constraints,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: bdr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A9EFF).withAlpha(26),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Color(0xFF4A9EFF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'История роста',
                        style: TextStyle(
                          color: txt,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: sub,
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 9),
                      _ProgressStoryFacts(story: story, isDark: isDark),
                    ],
                  ),
                ),
                if (showCloseButton && onClose != null)
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть историю роста',
                    onTap: onClose!,
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: bdr),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProgressHubSection(
                    isDark: isDark,
                    title: 'История роста',
                    subtitle:
                        'Сначала то, что уже получилось и стало частью пути.',
                    startIndex: 0,
                    cards: [
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.celebration,
                        color: const Color(0xFFFF9500),
                        title: 'Победы дня',
                        subtitle: 'Итог сегодняшнего рывка',
                        value: story.todayValue,
                        onTap: onOpenDailyVictories,
                      ),
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.calendar_view_week,
                        color: const Color(0xFF34C759),
                        title: 'Неделя',
                        subtitle: 'XP, квесты, навыки и риск серии',
                        value: story.weekValue,
                        onTap: onOpenWeekly,
                      ),
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.auto_stories,
                        color: const Color(0xFFAF52DE),
                        title: 'Летопись',
                        subtitle: 'Уровни, сопротивление, освоение и недели',
                        value: 'Ур. ${state.profile.level}',
                        onTap: onOpenCharacterTimeline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProgressContinueCard(
                    story: story,
                    isDark: isDark,
                    onTap: story.continuationPrefersWeekly
                        ? onOpenWeekly
                        : onOpenCharacterTimeline,
                  ),
                  if (state.skills.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    WeeklyReviewCard(state: state, isDark: isDark),
                  ],
                  const SizedBox(height: 14),
                  _ProgressHubSection(
                    isDark: isDark,
                    title: 'Разобраться глубже',
                    subtitle: 'Цифры и журнал остаются рядом, но не первыми.',
                    startIndex: 4,
                    cards: [
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.bar_chart,
                        color: const Color(0xFF4A9EFF),
                        title: 'Срез роста',
                        subtitle: 'XP, уровни, темп дня',
                        value: '${state.todayStats?.xpEarned ?? 0} XP сегодня',
                        onTap: onOpenStats,
                      ),
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.calendar_month,
                        color: const Color(0xFF30D158),
                        title: 'Календарь квестов',
                        subtitle: 'Когда реально закрывались квесты',
                        value: '${story.completedDays} активных дней',
                        onTap: onOpenCalendar,
                      ),
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.history,
                        color: const Color(0xFF8E8E93),
                        title: 'Журнал XP',
                        subtitle: 'Начисления, отмены и проверки',
                        value: '${state.history.length} записей',
                        onTap: onOpenHistory,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProgressHubSection(
                    isDark: isDark,
                    title: 'Трофеи и события',
                    subtitle:
                        'Трофеи, достижения и сопротивление — последствия прогресса, а не работа на сегодня.',
                    startIndex: 7,
                    cards: [
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.emoji_events,
                        color: const Color(0xFFFFCC00),
                        title: 'Достижения',
                        subtitle: 'Открытые рубежи',
                        value:
                            '$unlockedAchievements / ${state.achievements.length}',
                        onTap: onOpenAchievements,
                      ),
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.redeem,
                        color: const Color(0xFFFF9500),
                        title: 'Трофеи',
                        subtitle: 'Сундуки и эффекты после действий',
                        value: trophyValue,
                        onTap: onOpenRewards,
                      ),
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.shield,
                        color: const Color(0xFFFF2D55),
                        title: 'Сопротивление',
                        subtitle: 'События сопротивления и побед',
                        value: resistanceValue,
                        onTap: onOpenBosses,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A9EFF).withAlpha(14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF4A9EFF).withAlpha(36),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF4A9EFF),
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Прогресс здесь рассказывает историю роста. Если хочешь не анализировать, а двигаться дальше, вернись в режим “Действовать”.',
                      style: TextStyle(color: sub, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStorySnapshot {
  final int todayXp;
  final int todayQuestCount;
  final int weekXp;
  final int weekQuestCount;
  final int completedDays;
  final _ProgressSkillStory? topSkill;
  final _ProgressContinuation continuation;

  const _ProgressStorySnapshot({
    required this.todayXp,
    required this.todayQuestCount,
    required this.weekXp,
    required this.weekQuestCount,
    required this.completedDays,
    required this.topSkill,
    required this.continuation,
  });

  factory _ProgressStorySnapshot.fromState(AppState state) {
    final todayEntries = _todayEntries(state);
    final weekEntries = _currentWeekEntries(state);
    final topSkill = _topSkillStory(weekEntries);
    final lastCompletedEntry = _latestCompletedEntry(state);

    return _ProgressStorySnapshot(
      todayXp: todayEntries.fold<int>(0, (sum, entry) => sum + entry.xp),
      todayQuestCount: todayEntries.length,
      weekXp: weekEntries.fold<int>(0, (sum, entry) => sum + entry.xp),
      weekQuestCount: weekEntries.length,
      completedDays: state.completionHistoryByDate.length,
      topSkill: topSkill,
      continuation: _buildContinuation(state, topSkill, lastCompletedEntry),
    );
  }

  String get todayValue => todayQuestCount == 0
      ? 'ждёт первой победы'
      : '$todayXp XP • ${_questCount(todayQuestCount)}';

  String get weekValue => weekQuestCount == 0
      ? 'пока пусто'
      : '$weekXp XP • ${_questCount(weekQuestCount)}';

  String get topSkillValue => topSkill == null
      ? 'пока нет фокуса'
      : '${topSkill!.name} • ${topSkill!.xp} XP';

  bool get continuationPrefersWeekly => continuation.prefersWeekly;
}

class _ProgressSkillStory {
  final String skillId;
  final String name;
  final Color color;
  final IconData icon;
  final int xp;
  final int questCount;

  const _ProgressSkillStory({
    required this.skillId,
    required this.name,
    required this.color,
    required this.icon,
    required this.xp,
    required this.questCount,
  });
}

class _ProgressContinuation {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String value;
  final bool prefersWeekly;

  const _ProgressContinuation({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.prefersWeekly,
  });
}

_ProgressSkillStory? _topSkillStory(List<HistoryEntry> entries) {
  if (entries.isEmpty) return null;

  final bySkill = <String, List<HistoryEntry>>{};
  for (final entry in entries) {
    bySkill.putIfAbsent(entry.skillId, () => []).add(entry);
  }

  _ProgressSkillStory? best;
  for (final skillEntries in bySkill.values) {
    final first = skillEntries.first;
    final xp = skillEntries.fold<int>(0, (sum, entry) => sum + entry.xp);
    final story = _ProgressSkillStory(
      skillId: first.skillId,
      name: first.skillName,
      color: first.skillColor,
      icon: first.skillIcon,
      xp: xp,
      questCount: skillEntries.length,
    );
    if (best == null ||
        story.xp > best.xp ||
        (story.xp == best.xp && story.questCount > best.questCount)) {
      best = story;
    }
  }

  return best;
}

HistoryEntry? _latestCompletedEntry(AppState state) {
  final entries = state.history.where((entry) => entry.isCompletion).toList()
    ..sort((a, b) => b.at.compareTo(a.at));
  return entries.firstOrNull;
}

_ProgressContinuation _buildContinuation(
  AppState state,
  _ProgressSkillStory? topSkill,
  HistoryEntry? lastCompletedEntry,
) {
  final weeklySkill = topSkill == null
      ? null
      : state.skills.where((skill) => skill.id == topSkill.skillId).firstOrNull;

  if (topSkill != null && weeklySkill != null) {
    final activeStage = weeklySkill.treeNodes
        .where(
          (node) =>
              weeklySkill.treeNodeStatus(node) == SkillTreeNodeStatus.active,
        )
        .firstOrNull;
    final activeTasks = state
        .tasksForSkill(weeklySkill.id)
        .where((task) => !task.isDone)
        .toList();

    if (activeStage != null) {
      return _ProgressContinuation(
        icon: weeklySkill.icon,
        color: weeklySkill.color,
        title: 'Продолжить ${weeklySkill.name}',
        subtitle: 'Активный этап: ${activeStage.title}',
        value: '${topSkill.xp} XP на неделе',
        prefersWeekly: true,
      );
    }
    if (activeTasks.isNotEmpty) {
      return _ProgressContinuation(
        icon: weeklySkill.icon,
        color: weeklySkill.color,
        title: 'Продолжить ${weeklySkill.name}',
        subtitle: 'Следующий квест: ${activeTasks.first.title}',
        value: '${topSkill.questCount} квест. на неделе',
        prefersWeekly: true,
      );
    }
  }

  if (lastCompletedEntry != null) {
    return _ProgressContinuation(
      icon: lastCompletedEntry.skillIcon,
      color: lastCompletedEntry.skillColor,
      title: 'Вернуться к ${lastCompletedEntry.skillName}',
      subtitle: 'Последний квест: ${lastCompletedEntry.taskTitle}',
      value: '+${lastCompletedEntry.xp} XP последним',
      prefersWeekly: false,
    );
  }

  final firstSkill = state.skills.firstOrNull;
  if (firstSkill != null) {
    final activeStage = firstSkill.treeNodes
        .where(
          (node) =>
              firstSkill.treeNodeStatus(node) == SkillTreeNodeStatus.active,
        )
        .firstOrNull;
    return _ProgressContinuation(
      icon: firstSkill.icon,
      color: firstSkill.color,
      title: 'Начать рост: ${firstSkill.name}',
      subtitle: activeStage == null
          ? 'Сделай первый квест и получи стартовый XP.'
          : 'Первый этап: ${activeStage.title}',
      value: 'ждёт первой победы',
      prefersWeekly: false,
    );
  }

  return const _ProgressContinuation(
    icon: Icons.bolt,
    color: Color(0xFF4A9EFF),
    title: 'Рост начнётся после первого квеста',
    subtitle: 'Создай навык, закрой минимальный шаг и вернись сюда.',
    value: 'пока пусто',
    prefersWeekly: false,
  );
}

class _ProgressStoryFacts extends StatelessWidget {
  final _ProgressStorySnapshot story;
  final bool isDark;

  const _ProgressStoryFacts({required this.story, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _ProgressStoryFactChip(
          isDark: isDark,
          label: 'Сегодня',
          value: story.todayQuestCount == 0
              ? 'нет побед'
              : '${story.todayXp} XP',
          color: const Color(0xFFFF9500),
        ),
        _ProgressStoryFactChip(
          isDark: isDark,
          label: 'Неделя',
          value: story.weekQuestCount == 0 ? 'пусто' : '${story.weekXp} XP',
          color: const Color(0xFF34C759),
        ),
        _ProgressStoryFactChip(
          isDark: isDark,
          label: 'Главный навык',
          value: story.topSkillValue,
          color: story.topSkill?.color ?? const Color(0xFF4A9EFF),
        ),
      ],
    );
  }
}

class _ProgressStoryFactChip extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final Color color;

  const _ProgressStoryFactChip({
    required this.isDark,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 16 : 11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: subtext(isDark),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressContinueCard extends StatelessWidget {
  final _ProgressStorySnapshot story;
  final bool isDark;
  final VoidCallback onTap;

  const _ProgressContinueCard({
    required this.story,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final continuation = story.continuation;
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Что продолжить',
          style: TextStyle(
            color: txt,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Один мягкий ориентир из уже сделанного.',
          style: TextStyle(color: sub, fontSize: 11.5),
        ),
        const SizedBox(height: 10),
        PressFeedback(
          onTap: onTap,
          tooltip: 'Открыть подробности роста',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: continuation.color.withAlpha(isDark ? 13 : 9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: continuation.color.withAlpha(46)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: continuation.color.withAlpha(24),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    continuation.icon,
                    color: continuation.color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        continuation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: txt,
                          fontSize: 13.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        continuation.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: sub,
                          fontSize: 11.5,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        continuation.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: continuation.color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: sub.withAlpha(150), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

List<HistoryEntry> _currentWeekEntries(AppState state) {
  final now = DateTime.now();
  final today = dateOnly(now);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final completionHistoryByDate = state.completionHistoryByDate;
  final entries = <HistoryEntry>[];

  for (var i = 0; i < 7; i++) {
    final day = weekStart.add(Duration(days: i));
    entries.addAll(completionHistoryByDate[day] ?? const <HistoryEntry>[]);
  }

  return entries;
}

List<HistoryEntry> _todayEntries(AppState state) {
  final entries = List<HistoryEntry>.of(
    state.completionHistoryForDate(DateTime.now()),
  );
  entries.sort((a, b) => b.at.compareTo(a.at));
  return entries;
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

class _ProgressHubSection extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final int startIndex;
  final List<_ProgressHubCard> cards;

  const _ProgressHubSection({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.startIndex,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: txt,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(color: sub, fontSize: 11.5)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 520
                ? 1
                : constraints.maxWidth >= 980
                ? 3
                : 2;
            const spacing = 12.0;
            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var i = 0; i < cards.length; i++)
                  SizedBox(
                    width: cardWidth,
                    child: MotionListItem(
                      key: ValueKey('$title-card-$i'),
                      index: startIndex + i,
                      child: cards[i],
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

class _ProgressHubCard extends StatefulWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;

  const _ProgressHubCard({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  @override
  State<_ProgressHubCard> createState() => _ProgressHubCardState();
}

class _ProgressHubCardState extends State<_ProgressHubCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final txt = textColor(widget.isDark);
    final sub = subtext(widget.isDark);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: kMotionFast,
          curve: kMotionCurve,
          child: AnimatedContainer(
            duration: kMotionStandard,
            curve: kMotionCurve,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withAlpha(widget.isDark ? 12 : 10)
                  : widget.isDark
                  ? const Color(0xFF121219)
                  : const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered
                    ? widget.color.withAlpha(44)
                    : borderColor(widget.isDark),
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.color.withAlpha(widget.isDark ? 20 : 16),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: txt,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: sub, fontSize: 11.5),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: sub.withAlpha(150), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
