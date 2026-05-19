import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import 'shared.dart';

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
        subtitle:
            'Вторичные RPG-разделы собраны здесь, чтобы главный экран оставался про действие.',
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
    this.subtitle =
        'Статистика, календарь, боссы и трофеи собраны отдельно от режима действия.',
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
    final unlockedAchievements = state.achievements
        .where((achievement) => achievement.isUnlocked)
        .length;
    final completedDays = state.completionHistoryByDate.length;
    final todayEntries = _todayEntries(state);
    final todayXp = todayEntries.fold<int>(0, (sum, entry) => sum + entry.xp);
    final currentWeekEntries = _currentWeekEntries(state);
    final currentWeekXp = currentWeekEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.xp,
    );

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
                    Icons.dashboard_customize,
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
                        'Центр прогресса',
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
                    ],
                  ),
                ),
                if (showCloseButton && onClose != null)
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть центр прогресса',
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
                    title: 'Сначала итоги',
                    subtitle:
                        'Быстрый ответ: что получилось и куда растёт персонаж.',
                    startIndex: 0,
                    cards: [
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.celebration,
                        color: const Color(0xFFFF9500),
                        title: 'Победы дня',
                        subtitle: 'Итог сегодняшнего рывка',
                        value: todayEntries.isEmpty
                            ? 'ждёт первой победы'
                            : '$todayXp XP • ${_questCount(todayEntries.length)}',
                        onTap: onOpenDailyVictories,
                      ),
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.calendar_view_week,
                        color: const Color(0xFF34C759),
                        title: 'Неделя',
                        subtitle: 'XP, квесты, навыки и риск серии',
                        value: currentWeekEntries.isEmpty
                            ? 'пока пусто'
                            : '$currentWeekXp XP • ${_questCount(currentWeekEntries.length)}',
                        onTap: onOpenWeekly,
                      ),
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.auto_stories,
                        color: const Color(0xFFAF52DE),
                        title: 'Летопись',
                        subtitle: 'Уровни, боссы, освоение и недели',
                        value: 'Ур. ${state.profile.level}',
                        onTap: onOpenCharacterTimeline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProgressHubSection(
                    isDark: isDark,
                    title: 'Понять прогресс',
                    subtitle:
                        'Цифры и журнал, когда хочется разобраться глубже.',
                    startIndex: 3,
                    cards: [
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.bar_chart,
                        color: const Color(0xFF4A9EFF),
                        title: 'Статистика',
                        subtitle: 'XP, уровни, темп дня',
                        value: '${state.todayStats?.xpEarned ?? 0} XP сегодня',
                        onTap: onOpenStats,
                      ),
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.calendar_month,
                        color: const Color(0xFF30D158),
                        title: 'Календарь',
                        subtitle: 'Когда реально закрывались квесты',
                        value: '$completedDays активных дней',
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
                    title: 'Игровые системы',
                    subtitle:
                        'Игровые механики, которые поддерживают мотивацию.',
                    startIndex: 6,
                    cards: [
                      _ProgressHubCard(
                        isDark: isDark,
                        icon: Icons.shield,
                        color: const Color(0xFFFF2D55),
                        title: 'Боссы',
                        subtitle: 'Плохие привычки и сопротивление',
                        value: state.activeBossThreatCount > 0
                            ? '${state.activeBossThreatCount} атакуют'
                            : '${state.activeBosses.length} активных',
                        onTap: onOpenBosses,
                      ),
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
                        title: 'Награды',
                        subtitle: 'Сундуки и активные баффы',
                        value:
                            '${state.unopenedRewardChests.length} сундуков • ${state.activeBuffs.length} баффов',
                        onTap: onOpenRewards,
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
                      'Принцип интерфейса: сначала действие, потом анализ. Если хочешь просто двигаться дальше, вернись в режим “Действовать”.',
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
