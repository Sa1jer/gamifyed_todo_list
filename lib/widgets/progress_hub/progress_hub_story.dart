import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../utils.dart';
import '../shared.dart';

class ProgressStorySnapshot {
  final int todayXp;
  final int todayQuestCount;
  final int weekXp;
  final int weekQuestCount;
  final int completedDays;
  final ProgressSkillStory? topSkill;
  final ProgressContinuation continuation;

  const ProgressStorySnapshot({
    required this.todayXp,
    required this.todayQuestCount,
    required this.weekXp,
    required this.weekQuestCount,
    required this.completedDays,
    required this.topSkill,
    required this.continuation,
  });

  factory ProgressStorySnapshot.fromState(AppState state) {
    final analytics = state.currentAnalytics;
    final today = analytics.dayFor(DateTime.now());
    final leader = analytics.activityLeader;
    final leaderSkill = leader == null
        ? null
        : state.skills.where((skill) => skill.id == leader.skillId).firstOrNull;
    final leaderHistory = leader == null
        ? null
        : state.history
              .where((entry) => entry.skillId == leader.skillId)
              .firstOrNull;
    final topSkill = leader == null
        ? null
        : ProgressSkillStory(
            skillId: leader.skillId,
            name: leader.name,
            color:
                leaderSkill?.color ??
                leaderHistory?.skillColor ??
                Colors.blueAccent,
            icon:
                leaderSkill?.icon ??
                leaderHistory?.skillIcon ??
                Icons.auto_graph_rounded,
            xp: leader.xp,
            questCount: leader.completedTasks,
          );

    return ProgressStorySnapshot(
      todayXp: today?.xp ?? 0,
      todayQuestCount: today?.completedTasks ?? 0,
      weekXp: analytics.totalXp,
      weekQuestCount: analytics.completedTasks,
      completedDays: state.completionHistoryByDate.length,
      topSkill: topSkill,
      continuation: _buildContinuation(
        state,
        topSkill,
        state.latestRecordedCompletion,
      ),
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

class ProgressSkillStory {
  final String skillId;
  final String name;
  final Color color;
  final IconData icon;
  final int xp;
  final int questCount;

  const ProgressSkillStory({
    required this.skillId,
    required this.name,
    required this.color,
    required this.icon,
    required this.xp,
    required this.questCount,
  });
}

class ProgressContinuation {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String value;
  final bool prefersWeekly;

  const ProgressContinuation({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.prefersWeekly,
  });
}

ProgressContinuation _buildContinuation(
  AppState state,
  ProgressSkillStory? topSkill,
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
      return ProgressContinuation(
        icon: weeklySkill.icon,
        color: weeklySkill.color,
        title: 'Продолжить ${weeklySkill.name}',
        subtitle: 'Активный этап: ${activeStage.title}',
        value: '${topSkill.xp} XP на неделе',
        prefersWeekly: true,
      );
    }
    if (activeTasks.isNotEmpty) {
      return ProgressContinuation(
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
    return ProgressContinuation(
      icon: lastCompletedEntry.skillIcon,
      color: lastCompletedEntry.skillColor,
      title: 'Вернуться к ${lastCompletedEntry.skillName}',
      subtitle: 'Последний квест: ${lastCompletedEntry.taskTitle}',
      value: '+${lastCompletedEntry.xp} XP последним',
      prefersWeekly: false,
    );
  }

  final firstSkill = state.roadmapSkills.firstOrNull;
  if (firstSkill != null) {
    final activeStage = firstSkill.treeNodes
        .where(
          (node) =>
              firstSkill.treeNodeStatus(node) == SkillTreeNodeStatus.active,
        )
        .firstOrNull;
    return ProgressContinuation(
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

  return const ProgressContinuation(
    icon: Icons.bolt,
    color: Color(0xFF4A9EFF),
    title: 'Рост начнётся после первого квеста',
    subtitle: 'Создай навык, закрой минимальный шаг и вернись сюда.',
    value: 'пока пусто',
    prefersWeekly: false,
  );
}

class ProgressStoryFacts extends StatelessWidget {
  final ProgressStorySnapshot story;
  final bool isDark;

  const ProgressStoryFacts({
    super.key,
    required this.story,
    required this.isDark,
  });

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
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: TextStyle(
            color: subtext(isDark),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class ProgressContinueCard extends StatelessWidget {
  final ProgressStorySnapshot story;
  final bool isDark;
  final VoidCallback onTap;

  const ProgressContinueCard({
    super.key,
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
