part of '../main_page.dart';

enum _DesktopStatisticsDetail {
  daily,
  weekly,
  timeline,
  growth,
  calendar,
  xpLog,
  achievements,
  resistance,
}

class _DesktopStatisticsWorkspace extends StatefulWidget {
  final AppState state;
  final DesktopJournalTokens tokens;

  const _DesktopStatisticsWorkspace({
    super.key,
    required this.state,
    required this.tokens,
  });

  @override
  State<_DesktopStatisticsWorkspace> createState() =>
      _DesktopStatisticsWorkspaceState();
}

class _DesktopStatisticsWorkspaceState
    extends State<_DesktopStatisticsWorkspace> {
  _DesktopStatisticsDetail? _detail;

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    if (detail != null) {
      return _DesktopStatisticsDetailPage(
        key: ValueKey('desktop-statistics-detail-${detail.name}'),
        state: widget.state,
        tokens: widget.tokens,
        detail: detail,
        onBack: () => setState(() => _detail = null),
      );
    }
    return _DesktopStatisticsOverview(
      state: widget.state,
      tokens: widget.tokens,
      onOpen: (next) => setState(() => _detail = next),
    );
  }
}

class _DesktopStatisticsOverview extends StatelessWidget {
  final AppState state;
  final DesktopJournalTokens tokens;
  final ValueChanged<_DesktopStatisticsDetail> onOpen;

  const _DesktopStatisticsOverview({
    required this.state,
    required this.tokens,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final week = state.currentAnalytics;
    final mainSkill = week.leadingSkill;
    final mainSkillIdentity = mainSkill == null
        ? null
        : state.skills
              .where((skill) => skill.id == mainSkill.skillId)
              .firstOrNull;
    return _DesktopPageScaffold(
      tokens: tokens,
      icon: Icons.auto_stories_rounded,
      color: tokens.profilePurple,
      title: 'История роста',
      subtitle: 'Что получилось, какой навык вырос и что продолжить.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesktopStatisticsSummaryStrip(
            tokens: tokens,
            todayXp: state.todayStats?.xpEarned ?? 0,
            weekXp: week.totalXp,
            mainSkill: mainSkill,
            mainSkillIdentity: mainSkillIdentity,
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final showRail = constraints.maxWidth >= 940;
              final main = _DesktopStatisticsMainContent(
                state: state,
                tokens: tokens,
                week: week,
                onOpen: onOpen,
              );
              if (!showRail) {
                return Column(
                  children: [
                    main,
                    const SizedBox(height: 18),
                    _DesktopStatisticsRail(
                      state: state,
                      tokens: tokens,
                      week: week,
                      onOpen: onOpen,
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: main),
                  const SizedBox(width: 22),
                  SizedBox(
                    width: 280,
                    child: _DesktopStatisticsRail(
                      state: state,
                      tokens: tokens,
                      week: week,
                      onOpen: onOpen,
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

class _DesktopStatisticsMainContent extends StatelessWidget {
  final AppState state;
  final DesktopJournalTokens tokens;
  final AnalyticsReadModel week;
  final ValueChanged<_DesktopStatisticsDetail> onOpen;

  const _DesktopStatisticsMainContent({
    required this.state,
    required this.tokens,
    required this.week,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final courseNudge = visiblePrimaryCourseNudge(state);
    final continuation =
        state.roadmapSkills
            .where((skill) => skill.treeNodes.isNotEmpty)
            .toList()
          ..sort((a, b) {
            final xpCompare = (week.skillById(b.id)?.weeklyXp ?? 0).compareTo(
              week.skillById(a.id)?.weeklyXp ?? 0,
            );
            return xpCompare != 0 ? xpCompare : a.name.compareTo(b.name);
          });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DesktopSectionLabel(
          tokens: tokens,
          title: 'История роста',
          subtitle: 'Сначала то, что уже получилось и стало частью пути.',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            key: const ValueKey('desktop-statistics-growth-history'),
            crossAxisCount: constraints.maxWidth >= 760 ? 3 : 1,
            childAspectRatio: constraints.maxWidth >= 760 ? 2.45 : 4.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _DesktopStatisticsLinkCard(
                tokens: tokens,
                color: tokens.streakAmber,
                icon: Icons.celebration_outlined,
                title: 'Победы дня',
                subtitle:
                    '${state.todayStats?.xpEarned ?? 0} XP · ${state.todayStats?.tasksCompleted ?? 0} квестов',
                onTap: () => onOpen(_DesktopStatisticsDetail.daily),
              ),
              _DesktopStatisticsLinkCard(
                tokens: tokens,
                color: tokens.successGreen,
                icon: Icons.calendar_view_week_outlined,
                title: 'Неделя',
                subtitle: '${week.totalXp} XP · ${week.completedTasks} квестов',
                onTap: () => onOpen(_DesktopStatisticsDetail.weekly),
              ),
              _DesktopStatisticsLinkCard(
                tokens: tokens,
                color: const Color(0xFFB84DFF),
                icon: Icons.auto_stories_outlined,
                title: 'Летопись',
                subtitle:
                    '${state.totalTasksCompleted} побед · ур. ${state.profile.level}',
                onTap: () => onOpen(_DesktopStatisticsDetail.timeline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _DesktopSectionLabel(
          tokens: tokens,
          title: 'Цели и путь',
          subtitle: 'Где ты сейчас по навыкам и какой этап двигается дальше.',
        ),
        const SizedBox(height: 10),
        _DesktopSectionCard(
          tokens: tokens,
          child: Column(
            children: state.roadmapSkills.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: _DesktopEmptyMessage(
                        tokens: tokens,
                        icon: Icons.route_outlined,
                        title: 'Пути пока нет',
                        subtitle:
                            'Создай навык и этапы RoadMap, чтобы увидеть движение.',
                      ),
                    ),
                  ]
                : state.roadmapSkills
                      .map(
                        (skill) => _DesktopStatisticsSkillProgress(
                          skill: skill,
                          tokens: tokens,
                        ),
                      )
                      .toList(),
          ),
        ),
        const SizedBox(height: 24),
        _DesktopSectionLabel(
          tokens: tokens,
          title: 'Что продолжить',
          subtitle: 'Один мягкий ориентир из уже сделанного.',
        ),
        const SizedBox(height: 10),
        if (courseNudge != null)
          _DesktopCourseNudgeCard(
            nudge: courseNudge,
            tokens: tokens,
            onPrimary: () =>
                handleCourseNudge(context, state, state.isDark, courseNudge),
            onDismiss: () => state.dismissCourseNudge(courseNudge.key),
          )
        else if (continuation.isEmpty)
          _DesktopSectionCard(
            tokens: tokens,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Закрой первый квест, чтобы история начала подсказывать следующий шаг.',
                style: TextStyle(color: tokens.mutedText),
              ),
            ),
          )
        else
          _DesktopContinuationCard(
            skill: continuation.first,
            weekXp: week.skillById(continuation.first.id)?.weeklyXp ?? 0,
            tokens: tokens,
          ),
      ],
    );
  }
}

class _DesktopCourseNudgeCard extends StatelessWidget {
  final CourseNudge nudge;
  final DesktopJournalTokens tokens;
  final VoidCallback onPrimary;
  final VoidCallback onDismiss;

  const _DesktopCourseNudgeCard({
    required this.nudge,
    required this.tokens,
    required this.onPrimary,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => _DesktopSectionCard(
    tokens: tokens,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: nudge.skill.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assistant_direction_rounded,
              color: nudge.skill.color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Следующая корректировка',
                  style: TextStyle(
                    color: nudge.skill.color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  nudge.title,
                  style: TextStyle(
                    color: tokens.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  nudge.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.mutedText,
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DesktopCompactButton(
            label: nudge.actionLabel,
            icon: Icons.arrow_forward_rounded,
            color: nudge.skill.color,
            onTap: onPrimary,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Скрыть рекомендацию',
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, color: tokens.mutedText, size: 18),
          ),
        ],
      ),
    ),
  );
}

class _DesktopStatisticsRail extends StatelessWidget {
  final AppState state;
  final DesktopJournalTokens tokens;
  final AnalyticsReadModel week;
  final ValueChanged<_DesktopStatisticsDetail> onOpen;

  const _DesktopStatisticsRail({
    required this.state,
    required this.tokens,
    required this.week,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('desktop-statistics-right-rail'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DesktopStatisticsAnalyticsPanel(
        tokens: tokens,
        week: week,
        skills: state.roadmapSkills,
      ),
      const SizedBox(height: 16),
      _DesktopSectionLabel(
        tokens: tokens,
        title: 'Разобраться глубже',
        subtitle: 'Детали и журналы.',
      ),
      const SizedBox(height: 8),
      _DesktopRailLink(
        tokens: tokens,
        title: 'Срез роста',
        icon: Icons.trending_up,
        color: tokens.semanticBlue,
        onTap: () => onOpen(_DesktopStatisticsDetail.growth),
      ),
      _DesktopRailLink(
        tokens: tokens,
        title: 'Календарь квестов',
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFFB84DFF),
        onTap: () => onOpen(_DesktopStatisticsDetail.calendar),
      ),
      _DesktopRailLink(
        tokens: tokens,
        title: 'Журнал XP',
        icon: Icons.receipt_long_outlined,
        color: tokens.successGreen,
        onTap: () => onOpen(_DesktopStatisticsDetail.xpLog),
      ),
      const SizedBox(height: 14),
      _DesktopSectionLabel(
        tokens: tokens,
        title: 'Трофеи и события',
        subtitle: 'Рубежи и сопротивление.',
      ),
      const SizedBox(height: 8),
      _DesktopRailLink(
        tokens: tokens,
        title: 'Достижения',
        icon: Icons.workspace_premium_outlined,
        color: tokens.rewardGold,
        onTap: () => onOpen(_DesktopStatisticsDetail.achievements),
      ),
      _DesktopRailLink(
        tokens: tokens,
        title: 'Сопротивление',
        icon: Icons.shield_outlined,
        color: tokens.danger,
        onTap: () => onOpen(_DesktopStatisticsDetail.resistance),
      ),
    ],
  );
}

class _DesktopStatisticsDetailPage extends StatelessWidget {
  final AppState state;
  final DesktopJournalTokens tokens;
  final _DesktopStatisticsDetail detail;
  final VoidCallback onBack;

  const _DesktopStatisticsDetailPage({
    super.key,
    required this.state,
    required this.tokens,
    required this.detail,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final meta = switch (detail) {
      _DesktopStatisticsDetail.daily => (
        'Победы дня',
        Icons.celebration_outlined,
        tokens.streakAmber,
      ),
      _DesktopStatisticsDetail.weekly => (
        'Неделя',
        Icons.calendar_view_week,
        tokens.successGreen,
      ),
      _DesktopStatisticsDetail.timeline => (
        'Летопись',
        Icons.auto_stories_outlined,
        const Color(0xFFB84DFF),
      ),
      _DesktopStatisticsDetail.growth => (
        'Срез роста',
        Icons.trending_up,
        tokens.semanticBlue,
      ),
      _DesktopStatisticsDetail.calendar => (
        'Календарь квестов',
        Icons.calendar_month_outlined,
        const Color(0xFFB84DFF),
      ),
      _DesktopStatisticsDetail.xpLog => (
        'Журнал XP',
        Icons.receipt_long_outlined,
        tokens.successGreen,
      ),
      _DesktopStatisticsDetail.achievements => (
        'Достижения',
        Icons.workspace_premium_outlined,
        tokens.rewardGold,
      ),
      _DesktopStatisticsDetail.resistance => (
        'Сопротивление',
        Icons.shield_outlined,
        tokens.danger,
      ),
    };
    return _DesktopPageScaffold(
      tokens: tokens,
      icon: meta.$2,
      color: meta.$3,
      title: meta.$1,
      subtitle: 'Детальный разбор внутри единого desktop workspace.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            key: const ValueKey('desktop-statistics-detail-back'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Назад к статистике'),
          ),
          const SizedBox(height: 12),
          _buildDetail(meta.$3),
        ],
      ),
    );
  }

  Widget _buildDetail(Color color) {
    final week = state.currentAnalytics;
    final historyById = {for (final entry in state.history) entry.id: entry};
    final List<HistoryEntry> entries = switch (detail) {
      _DesktopStatisticsDetail.daily => state.completionHistoryForDate(
        DateTime.now(),
      ),
      _DesktopStatisticsDetail.weekly =>
        week.entries
            .map((entry) => historyById[entry.id])
            .whereType<HistoryEntry>()
            .toList(growable: false),
      _ => state.history.where((entry) => entry.isCompletion).toList(),
    };
    if (detail == _DesktopStatisticsDetail.achievements) {
      return _DesktopDetailGrid(
        children: state.achievements.map((achievement) {
          final def = achievement.def;
          return _DesktopDetailCard(
            tokens: tokens,
            color: def?.color ?? color,
            icon: def?.icon ?? Icons.workspace_premium_outlined,
            title: def?.name ?? achievement.id,
            subtitle: def?.description ?? 'Достижение',
            value: achievement.isUnlocked ? 'Открыто' : 'В процессе',
          );
        }).toList(),
      );
    }
    if (detail == _DesktopStatisticsDetail.resistance) {
      final bosses = state.activeBosses;
      if (bosses.isEmpty) {
        return _DesktopSectionCard(
          tokens: tokens,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _DesktopEmptyMessage(
              tokens: tokens,
              icon: Icons.shield_outlined,
              title: 'Активного сопротивления нет',
              subtitle:
                  'События появятся здесь, когда путь потребует отдельного усилия.',
            ),
          ),
        );
      }
      return _DesktopDetailGrid(
        children: bosses.map((boss) {
          final snapshot = state.bossSnapshot(boss);
          return _DesktopDetailCard(
            tokens: tokens,
            color: color,
            icon: Icons.shield_outlined,
            title: boss.title,
            subtitle: snapshot.recommendation,
            value: '${snapshot.impactPercent}%',
          );
        }).toList(),
      );
    }
    if (detail == _DesktopStatisticsDetail.growth) {
      return _DesktopDetailGrid(
        children: state.roadmapSkills
            .map(
              (skill) => _DesktopDetailCard(
                tokens: tokens,
                color: skill.color,
                icon: skill.icon,
                title: skill.name,
                subtitle:
                    'Ур. ${skill.level} · ${skill.masteredTreeNodeCount}/${skill.treeNodes.length} этапов',
                value: '${skill.xp}/${skill.xpNeeded} XP',
              ),
            )
            .toList(),
      );
    }
    if (detail == _DesktopStatisticsDetail.calendar) {
      final days = state.completionHistoryByDate.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));
      return _DesktopDetailGrid(
        children: days
            .take(35)
            .map(
              (day) => _DesktopDetailCard(
                tokens: tokens,
                color: day.value.isEmpty ? tokens.mutedText : color,
                icon: Icons.calendar_today_outlined,
                title:
                    '${day.key.day.toString().padLeft(2, '0')}.${day.key.month.toString().padLeft(2, '0')}.${day.key.year}',
                subtitle: 'Закрытые квесты',
                value: '${day.value.length}',
              ),
            )
            .toList(),
      );
    }
    if (entries.isEmpty) {
      return _DesktopSectionCard(
        tokens: tokens,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _DesktopEmptyMessage(
            tokens: tokens,
            icon: Icons.history_rounded,
            title: 'Записей пока нет',
            subtitle:
                'Закрытые квесты появятся здесь без искусственных данных.',
          ),
        ),
      );
    }
    return _DesktopSectionCard(
      tokens: tokens,
      child: Column(
        children: entries
            .take(80)
            .map(
              (entry) => ListTile(
                leading: Icon(entry.skillIcon, color: entry.skillColor),
                title: Text(
                  entry.taskTitle,
                  style: TextStyle(
                    color: tokens.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  entry.skillName,
                  style: TextStyle(color: tokens.mutedText),
                ),
                trailing: Text(
                  '+${entry.xp} XP',
                  style: TextStyle(
                    color: tokens.rewardGold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DesktopSectionLabel extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final String title;
  final String subtitle;

  const _DesktopSectionLabel({
    required this.tokens,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: tokens.text,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: TextStyle(
          color: tokens.mutedText,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _DesktopStatisticsLinkCard extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DesktopStatisticsLinkCard({
    required this.tokens,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => DesktopInteractiveSurface(
    baseColor: tokens.cardSurface,
    hoverColor: color.withValues(alpha: 0.07),
    borderColor: color.withValues(alpha: 0.18),
    borderRadius: 14,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.mutedText, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: tokens.mutedText),
        ],
      ),
    ),
  );
}

class _DesktopStatisticsSkillProgress extends StatelessWidget {
  final Skill skill;
  final DesktopJournalTokens tokens;

  const _DesktopStatisticsSkillProgress({
    required this.skill,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: skill.color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(skill.icon, color: skill.color, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      skill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${(skill.treeProgress * 100).round()}%',
                    style: TextStyle(
                      color: skill.color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              DesktopProgressBar(
                value: skill.treeProgress,
                color: skill.color,
                background: skill.color.withValues(alpha: 0.12),
                height: 6,
              ),
              if (skill.goal.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  skill.goal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.mutedText, fontSize: 10.5),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _DesktopContinuationCard extends StatelessWidget {
  final Skill skill;
  final int weekXp;
  final DesktopJournalTokens tokens;

  const _DesktopContinuationCard({
    required this.skill,
    required this.weekXp,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final stage = skill.treeNodes
        .where(
          (node) => skill.treeNodeStatus(node) == SkillTreeNodeStatus.active,
        )
        .firstOrNull;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: skill.color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: skill.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: skill.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(skill.icon, color: skill.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Продолжить ${skill.name}',
                  style: TextStyle(
                    color: tokens.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stage == null
                      ? 'Добавь этап пути'
                      : 'Активный этап: ${stage.title}',
                  style: TextStyle(color: tokens.mutedText),
                ),
                const SizedBox(height: 5),
                Text(
                  '$weekXp XP на неделе',
                  style: TextStyle(
                    color: skill.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopRailLink extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DesktopRailLink({
    required this.tokens,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DesktopInteractiveSurface(
      baseColor: tokens.cardSurface,
      hoverColor: color.withValues(alpha: 0.07),
      borderColor: color.withValues(alpha: 0.16),
      borderRadius: 12,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.text,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: tokens.mutedText, size: 17),
          ],
        ),
      ),
    ),
  );
}

class _DesktopDetailGrid extends StatelessWidget {
  final List<Widget> children;
  const _DesktopDetailGrid({required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GridView.count(
      crossAxisCount: constraints.maxWidth >= 900
          ? 3
          : constraints.maxWidth >= 560
          ? 2
          : 1,
      childAspectRatio: 2.6,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    ),
  );
}

class _DesktopDetailCard extends StatelessWidget {
  final DesktopJournalTokens tokens;
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  const _DesktopDetailCard({
    required this.tokens,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: tokens.cardSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.mutedText, fontSize: 10.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}
