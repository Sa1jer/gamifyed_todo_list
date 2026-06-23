part of '../dialogs.dart';

class StatsDialog extends StatelessWidget {
  final AppState state;
  const StatsDialog({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 560,
        height: 680,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.bar_chart,
                    color: Color(0xFF4A9EFF),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Срез роста',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть срез роста',
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildGrowthSnapshot(state, isDark, txt, sub),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Выполнено квестов',
                            value: '${state.totalTasksCompleted}',
                            icon: Icons.check_circle,
                            color: const Color(0xFF34C759),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Лучшая серия',
                            value: '${state.bestStreak} дн.',
                            icon: Icons.local_fire_department,
                            color: const Color(0xFFFF9500),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Уровень профиля',
                            value: 'Ур. ${state.profile.level}',
                            icon: Icons.trending_up,
                            color: const Color(0xFF4A9EFF),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Всего XP',
                            value: '${state.profile.totalXpEarned}',
                            icon: Icons.star,
                            color: const Color(0xFFFFCC00),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildXpTrendChart(state, isDark, txt, sub),
                    const SizedBox(height: 20),
                    _buildSkillProgressChart(state, isDark, txt, sub),
                    const SizedBox(height: 20),
                    _buildSkillStats(state, isDark, txt, sub),
                    const SizedBox(height: 20),
                    _buildTodayStats(state, isDark, txt, sub),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthSnapshot(AppState s, bool isDark, Color txt, Color sub) {
    final summary =
        'Закрыто ${s.totalTasksCompleted} квестов · лучшая серия ${s.bestStreak} дн. · ур. ${s.profile.level} · ${s.profile.totalXpEarned} XP';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4A9EFF).withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4A9EFF).withAlpha(38)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF4A9EFF).withAlpha(isDark ? 28 : 22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_stories,
              color: Color(0xFF4A9EFF),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Коротко о росте',
                  style: TextStyle(
                    color: txt,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: TextStyle(
                    color: sub,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillStats(AppState s, bool isDark, Color txt, Color sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Навыки и квесты',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: txt,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        ...s.skills.map((sk) {
          final skillTasks = s.tasks.where((t) => t.skillId == sk.id).toList();
          final completed = skillTasks.where((t) => t.isDone).length;
          final total = skillTasks.length;
          final percent = total > 0 ? (completed / total * 100).round() : 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sk.color.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sk.color.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(sk.icon, color: sk.color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${sk.name} • Ур. ${sk.level}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: txt,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '$completed/$total',
                      style: TextStyle(color: sub, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 6,
                          backgroundColor: sk.color.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation(sk.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: sk.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildXpTrendChart(AppState s, bool isDark, Color txt, Color sub) {
    final points = _dailyXpPoints(s);
    final maxXp = points.fold<int>(0, (max, point) => math.max(max, point.xp));
    final maxY = math.max(40, (maxXp * 1.25).ceil()).toDouble();
    final chartColor = const Color(0xFF4A9EFF);

    return _ChartPanel(
      title: 'Ритм XP',
      subtitle: maxXp == 0
          ? 'Пока тихая неделя. Первый квест сразу оживит график.'
          : 'Ритм недели виден по дням, а не только по общему числу.',
      icon: Icons.show_chart,
      color: chartColor,
      isDark: isDark,
      child: SizedBox(
        height: 170,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 6,
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 2,
              getDrawingHorizontalLine: (_) => FlLine(
                color: borderColor(isDark).withAlpha(130),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  interval: maxY / 2,
                  getTitlesWidget: (value, _) {
                    if (value == 0 || value >= maxY) {
                      return Text(
                        value.round().toString(),
                        style: TextStyle(color: sub, fontSize: 10),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 24,
                  getTitlesWidget: (value, _) {
                    final index = value.round();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      points[index].label,
                      style: TextStyle(color: sub, fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble(), points[i].xp.toDouble()),
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                barWidth: 3,
                isStrokeCapRound: true,
                color: chartColor,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: chartColor.withAlpha(24),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  Widget _buildSkillProgressChart(
    AppState s,
    bool isDark,
    Color txt,
    Color sub,
  ) {
    final points = _skillProgressPoints(s);
    final chartColor = const Color(0xFFFF9500);

    if (points.isEmpty) {
      return _ChartPanel(
        title: 'Навыки ближе к уровню',
        subtitle: 'Добавьте навык, чтобы здесь появился RPG-срез развития.',
        icon: Icons.auto_graph,
        color: chartColor,
        isDark: isDark,
        child: _EmptyChartHint(text: 'Нет навыков для графика', color: sub),
      );
    }

    return _ChartPanel(
      title: 'Навыки ближе к уровню',
      subtitle: 'Быстрый срез: какие навыки ближе всего к следующему уровню.',
      icon: Icons.auto_graph,
      color: chartColor,
      isDark: isDark,
      child: SizedBox(
        height: 185,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: 100,
            alignment: BarChartAlignment.spaceAround,
            groupsSpace: 14,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 50,
              getDrawingHorizontalLine: (_) => FlLine(
                color: borderColor(isDark).withAlpha(120),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => surface(isDark),
                getTooltipItem: (group, _, rod, _) {
                  final point = points[group.x];
                  return BarTooltipItem(
                    '${point.name}\n${rod.toY.round()}% до ур. ${point.level + 1}',
                    TextStyle(
                      color: txt,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: 50,
                  getTitlesWidget: (value, _) => Text(
                    '${value.round()}%',
                    style: TextStyle(color: sub, fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 30,
                  getTitlesWidget: (value, _) {
                    final index = value.round();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        points[index].shortName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: points[index].color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < points.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: points[i].progressPercent,
                      color: points[i].color,
                      width: 18,
                      borderRadius: BorderRadius.circular(8),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 100,
                        color: points[i].color.withAlpha(26),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  Widget _buildTodayStats(AppState s, bool isDark, Color txt, Color sub) {
    final stats = s.todayStats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сегодня',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: txt,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF4A9EFF).withAlpha(12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4A9EFF).withAlpha(40)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TodayStatItem(
                label: 'Квестов',
                value: '${stats?.tasksCompleted ?? 0}',
                color: const Color(0xFF4A9EFF),
              ),
              Container(width: 1, height: 30, color: borderColor(isDark)),
              _TodayStatItem(
                label: 'XP',
                value: '${stats?.xpEarned ?? 0}',
                color: const Color(0xFFFFCC00),
              ),
              Container(width: 1, height: 30, color: borderColor(isDark)),
              _TodayStatItem(
                label: 'Навыков',
                value: '${stats?.skillsImproved ?? 0}',
                color: const Color(0xFF34C759),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_DailyXpPoint> _dailyXpPoints(AppState s) {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final today = dateOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 6));
    return [
      for (var i = 0; i < 7; i++)
        () {
          final day = start.add(Duration(days: i));
          final xp = (s.completionHistoryByDate[day] ?? const <HistoryEntry>[])
              .fold<int>(0, (sum, entry) => sum + math.max(0, entry.xp));
          return _DailyXpPoint(label: labels[day.weekday - 1], xp: xp);
        }(),
    ];
  }

  List<_SkillProgressPoint> _skillProgressPoints(AppState s) {
    final sorted = List<Skill>.of(s.skills)
      ..sort((a, b) => b.progress.compareTo(a.progress));
    return sorted.take(6).map((skill) {
      return _SkillProgressPoint(
        name: skill.name,
        shortName: skill.name.length <= 7
            ? skill.name
            : '${skill.name.substring(0, 6)}…',
        color: skill.color,
        level: skill.level,
        progressPercent: (skill.progress * 100).clamp(0, 100),
      );
    }).toList();
  }
}

class _ChartPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Widget child;

  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(36)),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: sub, fontSize: 12)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EmptyChartHint extends StatelessWidget {
  final String text;
  final Color color;

  const _EmptyChartHint({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _DailyXpPoint {
  final String label;
  final int xp;

  const _DailyXpPoint({required this.label, required this.xp});
}

class _SkillProgressPoint {
  final String name;
  final String shortName;
  final Color color;
  final int level;
  final double progressPercent;

  const _SkillProgressPoint({
    required this.name,
    required this.shortName,
    required this.color,
    required this.level,
    required this.progressPercent,
  });
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: sub, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: txt,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayStatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _TodayStatItem({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: color.withAlpha(180), fontSize: 11),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REWARDS DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class CalendarDialog extends StatefulWidget {
  final AppState state;
  const CalendarDialog({super.key, required this.state});
  @override
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  late DateTime _selectedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final completionHistoryByDate = widget.state.completionHistoryByDate;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 440,
        height: 580,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: Color(0xFF4A9EFF),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Календарь квестов',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: txt,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Дни реальных действий и закрытых квестов.',
                          style: TextStyle(
                            color: sub,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть календарь квестов',
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),
            _buildMonthNav(txt, sub),
            _buildWeekdayHeaders(sub),
            Expanded(
              child: _buildCalendarGrid(
                isDark,
                txt,
                sub,
                completionHistoryByDate,
              ),
            ),
            MotionExpandable(
              expanded: _selectedDate != null,
              expandedChild: _selectedDate == null
                  ? const SizedBox.shrink()
                  : _buildSelectedDateTasks(
                      isDark,
                      txt,
                      sub,
                      bdr,
                      completionHistoryByDate,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNav(Color txt, Color sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Tooltip(
            message: 'Предыдущий месяц',
            child: GestureDetector(
              onTap: () =>
                  _selectMonth(_selectedMonth.year, _selectedMonth.month - 1),
              child: Icon(Icons.chevron_left, color: sub),
            ),
          ),
          Text(
            '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: txt,
              fontSize: 16,
            ),
          ),
          Tooltip(
            message: 'Следующий месяц',
            child: GestureDetector(
              onTap: () =>
                  _selectMonth(_selectedMonth.year, _selectedMonth.month + 1),
              child: Icon(Icons.chevron_right, color: sub),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(Color sub) {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays
            .map(
              (d) => SizedBox(
                width: 40,
                child: Text(
                  d,
                  style: TextStyle(
                    color: sub,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(
    bool isDark,
    Color txt,
    Color sub,
    Map<DateTime, List<HistoryEntry>> completionHistoryByDate,
  ) {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    final cells = <Widget>[];

    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox(width: 40, height: 40));
    }

    final today = DateTime.now();
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isToday = isSameDate(date, today);
      final isSelected =
          _selectedDate != null && isSameDate(date, _selectedDate!);
      final completionCount =
          completionHistoryByDate[dateOnly(date)]?.length ?? 0;

      cells.add(
        _buildDayCell(
          day,
          date,
          isToday,
          isSelected,
          completionCount,
          isDark,
          txt,
          sub,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(spacing: 4, runSpacing: 4, children: cells),
    );
  }

  Widget _buildDayCell(
    int day,
    DateTime date,
    bool isToday,
    bool isSelected,
    int completionCount,
    bool isDark,
    Color txt,
    Color sub,
  ) {
    return GestureDetector(
      onTap: () => setState(
        () => _selectedDate =
            _selectedDate != null && isSameDate(_selectedDate!, date)
            ? null
            : date,
      ),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? const Color(0xFF4A9EFF)
              : (isToday ? const Color(0xFF4A9EFF).withAlpha(30) : null),
          border: isToday && !isSelected
              ? Border.all(color: const Color(0xFF4A9EFF))
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isSelected ? Colors.white : txt,
                fontWeight: isToday || isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (completionCount > 0 && !isSelected)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34C759),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateTasks(
    bool isDark,
    Color txt,
    Color sub,
    Color bdr,
    Map<DateTime, List<HistoryEntry>> completionHistoryByDate,
  ) {
    final selectedDate = _selectedDate!;
    final selectedEntries =
        completionHistoryByDate[dateOnly(selectedDate)] ??
        const <HistoryEntry>[];

    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: surface(isDark),
        border: Border(top: BorderSide(color: bdr)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Text(
                  formatShortDate(selectedDate),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: txt,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  _calendarQuestCount(selectedEntries.length),
                  style: TextStyle(color: sub, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: MotionFadeSlideSwitcher(
              child: selectedEntries.isEmpty
                  ? Center(
                      key: const ValueKey('calendar-empty-day'),
                      child: Text(
                        'В этот день квесты не закрывались',
                        style: TextStyle(color: sub, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      key: const ValueKey('calendar-entry-list'),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: selectedEntries.length,
                      itemBuilder: (_, i) {
                        final entry = selectedEntries[i];
                        return MotionListItem(
                          key: ValueKey(
                            'calendar-entry-${entry.taskId}-${entry.at.millisecondsSinceEpoch}',
                          ),
                          index: i,
                          slide: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: entry.skillColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.taskTitle,
                                        style: TextStyle(
                                          color: txt,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${entry.skillName} • ${formatTime(entry.at)}',
                                        style: TextStyle(
                                          color: sub,
                                          fontSize: 10,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+${entry.xp}',
                                  style: const TextStyle(
                                    color: Color(0xFF34C759),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _calendarQuestCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return '$count квест';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$count квеста';
    }
    return '$count квестов';
  }

  void _selectMonth(int year, int month) {
    setState(() {
      _selectedMonth = DateTime(year, month);
      _selectedDate = null;
    });
  }

  String _monthName(int month) {
    const months = [
      '',
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return months[month];
  }
}
