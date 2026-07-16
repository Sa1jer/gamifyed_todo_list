import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app_state.dart';
import '../engines/progress_engine.dart';
import '../utils.dart';
import 'progress_hub/progress_hub_actions.dart';
import 'progress_hub/progress_hub_cards.dart';
import 'progress_hub/progress_hub_goal_review.dart';
import 'progress_hub/progress_hub_story.dart';
import 'progress_hub/progress_hub_tutorial.dart';
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
  final bool showTutorialHint;
  final VoidCallback? onTutorialComplete;

  const ProgressHubDialog({
    super.key,
    required this.state,
    required this.isDark,
    this.showTutorialHint = false,
    this.onTutorialComplete,
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
    var dialogWidth = availableWidth < 760
        ? availableWidth
        : (availableWidth * 0.82).clamp(760.0, 1120.0).toDouble();
    var dialogHeight = dialogWidth / 1.6;
    if (dialogHeight > availableHeight) {
      dialogHeight = availableHeight;
      dialogWidth = (dialogHeight * 1.6)
          .clamp(math.min(availableWidth, 320.0), availableWidth)
          .toDouble();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ProgressHubContent(
        state: state,
        isDark: isDark,
        width: dialogWidth,
        constraints: BoxConstraints.tightFor(height: dialogHeight),
        showCloseButton: true,
        showTutorialHint: showTutorialHint,
        subtitle: 'Что получилось, какой навык вырос и что продолжить.',
        onClose: () => Navigator.pop(context),
        onTutorialComplete: onTutorialComplete == null
            ? null
            : () {
                onTutorialComplete!.call();
                Navigator.maybePop(context);
              },
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
  final bool showTutorialHint;
  final String subtitle;
  final VoidCallback? onClose;
  final VoidCallback? onTutorialComplete;
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
    this.showTutorialHint = false,
    this.subtitle = 'Что получилось, какой навык вырос и что продолжить.',
    this.onClose,
    this.onTutorialComplete,
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
    final story = ProgressStorySnapshot.fromState(state);
    final goalProgress = const ProgressEngine().buildSnapshot(
      state.skills,
      state.history,
    );
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
    final courseNudge = visiblePrimaryCourseNudge(state);
    final tutorialTargetKey = GlobalKey();

    return Stack(
      children: [
        Container(
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
              KeyedSubtree(
                key: tutorialTargetKey,
                child: Padding(
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
                            ProgressStoryFacts(story: story, isDark: isDark),
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
              ),
              Container(height: 1, color: bdr),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProgressHubSection(
                        isDark: isDark,
                        title: 'История роста',
                        subtitle:
                            'Сначала то, что уже получилось и стало частью пути.',
                        startIndex: 0,
                        cards: [
                          ProgressHubCard(
                            isDark: isDark,
                            icon: Icons.celebration,
                            color: const Color(0xFFFF9500),
                            title: 'Победы дня',
                            subtitle: 'Итог сегодняшнего рывка',
                            value: story.todayValue,
                            onTap: onOpenDailyVictories,
                          ),
                          ProgressHubCard(
                            isDark: isDark,
                            icon: Icons.calendar_view_week,
                            color: const Color(0xFF34C759),
                            title: 'Неделя',
                            subtitle: 'XP, квесты, навыки и риск серии',
                            value: story.weekValue,
                            onTap: onOpenWeekly,
                          ),
                          ProgressHubCard(
                            isDark: isDark,
                            icon: Icons.auto_stories,
                            color: const Color(0xFFAF52DE),
                            title: 'Летопись',
                            subtitle:
                                'Уровни, сопротивление, освоение и недели',
                            value: 'Ур. ${state.profile.level}',
                            onTap: onOpenCharacterTimeline,
                          ),
                        ],
                      ),
                      if (!goalProgress.isEmpty) ...[
                        const SizedBox(height: 14),
                        GoalProgressOverview(
                          snapshot: goalProgress,
                          isDark: isDark,
                          onReviewSkill: (skill) => showProgressGoalReviewSheet(
                            context,
                            state,
                            isDark,
                            skill,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      ProgressContinueCard(
                        story: story,
                        isDark: isDark,
                        onTap: story.continuationPrefersWeekly
                            ? onOpenWeekly
                            : onOpenCharacterTimeline,
                      ),
                      if (state.roadmapSkills.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ProgressReviewBlock(
                          isDark: isDark,
                          nudge: courseNudge,
                          onApplyNudge: courseNudge == null
                              ? null
                              : () => handleCourseNudge(
                                  context,
                                  state,
                                  isDark,
                                  courseNudge,
                                ),
                          onDismissNudge: courseNudge == null
                              ? null
                              : () => state.dismissCourseNudge(courseNudge.key),
                          reviewCard: WeeklyReviewCard(
                            state: state,
                            isDark: isDark,
                            autoExpandWhenDue: true,
                            buildNudgeForSkill: (skill) =>
                                visibleCourseNudgeForSkill(state, skill),
                            onApplyNudge: (nudge) => handleCourseNudge(
                              context,
                              state,
                              isDark,
                              nudge,
                            ),
                            onDismissNudge: (nudge) =>
                                state.dismissCourseNudge(nudge.key),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      ProgressHubSection(
                        isDark: isDark,
                        title: 'Разобраться глубже',
                        subtitle:
                            'Цифры и журнал остаются рядом, но не первыми.',
                        startIndex: 4,
                        cards: [
                          ProgressHubCard(
                            isDark: isDark,
                            icon: Icons.bar_chart,
                            color: const Color(0xFF4A9EFF),
                            title: 'Срез роста',
                            subtitle: 'XP, уровни, темп дня',
                            value:
                                '${state.todayStats?.xpEarned ?? 0} XP сегодня',
                            onTap: onOpenStats,
                          ),
                          ProgressHubCard(
                            isDark: isDark,
                            icon: Icons.calendar_month,
                            color: const Color(0xFF30D158),
                            title: 'Календарь квестов',
                            subtitle: 'Когда реально закрывались квесты',
                            value: '${story.completedDays} активных дней',
                            onTap: onOpenCalendar,
                          ),
                          ProgressHubCard(
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
                      ProgressHubSection(
                        isDark: isDark,
                        title: 'Трофеи и события',
                        subtitle:
                            'Трофеи, достижения и сопротивление — последствия прогресса, а не работа на сегодня.',
                        startIndex: 7,
                        cards: [
                          ProgressHubCard(
                            isDark: isDark,
                            icon: Icons.emoji_events,
                            color: const Color(0xFFFFCC00),
                            title: 'Достижения',
                            subtitle: 'Открытые рубежи',
                            value:
                                '$unlockedAchievements / ${state.achievements.length}',
                            onTap: onOpenAchievements,
                          ),
                          ProgressHubCard(
                            isDark: isDark,
                            icon: Icons.redeem,
                            color: const Color(0xFFFF9500),
                            title: 'Трофеи',
                            subtitle: 'Сундуки и эффекты после действий',
                            value: trophyValue,
                            onTap: onOpenRewards,
                          ),
                          ProgressHubCard(
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
                          'Статистика здесь рассказывает историю роста. Если хочешь не анализировать, а двигаться дальше, вернись в режим “Действовать”.',
                          style: TextStyle(
                            color: sub,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showTutorialHint && onTutorialComplete != null)
          Positioned.fill(
            child: ProgressTutorialSpotlight(
              targetKey: tutorialTargetKey,
              isDark: isDark,
              onComplete: onTutorialComplete!,
            ),
          ),
      ],
    );
  }
}
