part of '../planning_workspace.dart';

class _SkillBlueprintPanel extends StatelessWidget {
  final AppState state;
  final Skill? skill;
  final bool isDark;
  final bool archiveExpanded;
  final bool internalScroll;
  final VoidCallback onArchiveToggle;
  final VoidCallback? onEditSkill;
  final VoidCallback? onAddTask;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<Task> onDeleteTask;
  final ValueChanged<SkillTreeNode>? onAddQuestToNode;

  const _SkillBlueprintPanel({
    required this.state,
    required this.skill,
    required this.isDark,
    required this.archiveExpanded,
    required this.internalScroll,
    required this.onArchiveToggle,
    required this.onEditSkill,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onAddQuestToNode,
  });

  @override
  Widget build(BuildContext context) {
    final selected = skill;
    if (selected == null) {
      return AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyStateMessage(
            isDark: isDark,
            icon: Icons.keyboard_backspace,
            title: 'Выберите навык',
            subtitle:
                'Если навыков ещё нет, начни в “Сейчас”: первый этап и квест появятся сразу.',
          ),
        ),
      );
    }

    final tasks = state.tasksForSkill(selected.id);
    final diagnostics = _buildPlanningDiagnostics(
      state,
      selected,
      tasks: tasks,
    );
    final children = <Widget>[
      _SkillPassportHeader(
        skill: selected,
        isDark: isDark,
        activeCount: diagnostics.activeTasks.length,
        doneCount: diagnostics.completedTasks.length,
        onEditSkill: onEditSkill!,
        onAddTask: onAddTask!,
      ),
      PanelDivider(isDark: isDark),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: _SectionTitle(
          isDark: isDark,
          icon: Icons.format_list_bulleted,
          title: 'Активные квесты',
          subtitle: 'Сначала рабочий план, подсказки ниже.',
        ),
      ),
      _QuestPlanList(
        skill: selected,
        diagnostics: diagnostics,
        isDark: isDark,
        archiveExpanded: archiveExpanded,
        onArchiveToggle: onArchiveToggle,
        onEditTask: onEditTask,
        onDeleteTask: onDeleteTask,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: _SetupBacklogSection(
          diagnostics: diagnostics,
          isDark: isDark,
          onEditSkill: onEditSkill!,
          onAddTask: onAddTask!,
          onEditTask: onEditTask,
          onAddQuestToNode: onAddQuestToNode,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _SystemStateCard(diagnostics: diagnostics, isDark: isDark),
      ),
    ];

    final content = internalScroll
        ? ListView(
            key: PageStorageKey('planning-blueprint-${selected.id}'),
            padding: EdgeInsets.zero,
            children: children,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );

    return AppPanel(isDark: isDark, child: content);
  }
}

class _SystemStateCard extends StatelessWidget {
  final _PlanningDiagnostics diagnostics;
  final bool isDark;

  const _SystemStateCard({required this.diagnostics, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _readinessColor(diagnostics.readinessPercent);
    final skill = diagnostics.skill;
    final rows = [
      _SystemCheckData(
        ok: skill.goal.trim().isNotEmpty,
        label: skill.goal.trim().isNotEmpty
            ? 'Цель описана'
            : 'Нет цели навыка',
        warning: 'Опишите, зачем прокачивать навык.',
      ),
      _SystemCheckData(
        ok: diagnostics.activeTasks.isNotEmpty,
        label: diagnostics.activeTasks.isNotEmpty
            ? 'Есть активные квесты'
            : 'Нет активных квестов',
        warning: 'Добавьте хотя бы один следующий шаг.',
      ),
      _SystemCheckData(
        ok: diagnostics.missingMinimumTasks.isEmpty,
        label: diagnostics.missingMinimumTasks.isEmpty
            ? 'Лёгкие старты настроены'
            : '${diagnostics.missingMinimumTasks.length} без минимума',
        warning: 'Добавьте минимальный шаг.',
      ),
      _SystemCheckData(
        ok: diagnostics.unlinkedTasks.isEmpty,
        label: diagnostics.unlinkedTasks.isEmpty
            ? 'Квесты связаны с этапами'
            : '${diagnostics.unlinkedTasks.length} без этапа',
        warning: 'Привяжите квесты к этапам мастерства.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 13 : 9),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rule_folder_outlined, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Готовность системы',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${diagnostics.readinessPercent}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XPBar(
            progress: diagnostics.readinessPercent / 100,
            color: color,
            height: 5,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: rows
                .map((row) => _SystemCheckChip(data: row, isDark: isDark))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SystemCheckData {
  final bool ok;
  final String label;
  final String warning;

  const _SystemCheckData({
    required this.ok,
    required this.label,
    required this.warning,
  });
}

class _SystemCheckChip extends StatelessWidget {
  final _SystemCheckData data;
  final bool isDark;

  const _SystemCheckChip({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = data.ok ? const Color(0xFF34C759) : const Color(0xFFFF9500);
    return Tooltip(
      message: data.ok ? data.label : data.warning,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 14 : 10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              data.ok ? Icons.check_circle : Icons.warning_amber_rounded,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              data.label,
              style: TextStyle(
                color: data.ok ? textColor(isDark) : color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupBacklogSection extends StatefulWidget {
  final _PlanningDiagnostics diagnostics;
  final bool isDark;
  final VoidCallback onEditSkill;
  final VoidCallback onAddTask;
  final ValueChanged<Task> onEditTask;
  final ValueChanged<SkillTreeNode>? onAddQuestToNode;

  const _SetupBacklogSection({
    required this.diagnostics,
    required this.isDark,
    required this.onEditSkill,
    required this.onAddTask,
    required this.onEditTask,
    required this.onAddQuestToNode,
  });

  @override
  State<_SetupBacklogSection> createState() => _SetupBacklogSectionState();
}

class _SetupBacklogSectionState extends State<_SetupBacklogSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final diagnostics = widget.diagnostics;
    final isDark = widget.isDark;
    final primaryIssue = diagnostics.primaryIssue;
    final secondaryIssues = diagnostics.secondaryIssues;
    final accent = primaryIssue?.color ?? const Color(0xFF34C759);
    final action = primaryIssue == null ? null : _actionFor(primaryIssue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 12 : 8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withAlpha(44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                primaryIssue == null
                    ? Icons.check_circle
                    : Icons.tips_and_updates_outlined,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Что улучшить первым',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (secondaryIssues.isNotEmpty)
                PressFeedback(
                  onTap: () => setState(() => _expanded = !_expanded),
                  tooltip: _expanded
                      ? 'Скрыть дополнительные подсказки'
                      : 'Показать ещё',
                  child: Row(
                    children: [
                      Text(
                        'Ещё ${secondaryIssues.length}',
                        style: TextStyle(
                          color: subtext(isDark),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: subtext(isDark),
                        size: 18,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          if (primaryIssue == null)
            _InspectorHint(
              isDark: isDark,
              icon: Icons.check_circle,
              color: const Color(0xFF34C759),
              title: 'Система собрана',
              subtitle: 'Можно планировать следующий квест или новый этап.',
            )
          else
            _PrimaryPlanningIssueCard(
              issue: primaryIssue,
              isDark: isDark,
              onTap: action,
            ),
          MotionExpandable(
            expanded: _expanded && secondaryIssues.isNotEmpty,
            expandedChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Дополнительные подсказки',
                  style: TextStyle(
                    color: subtext(isDark),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                ...secondaryIssues.map(
                  (issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _SetupIssueRow(
                      issue: issue,
                      isDark: isDark,
                      onTap: _actionFor(issue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _actionFor(_PlanningIssue issue) {
    if (issue.task != null) return () => widget.onEditTask(issue.task!);
    if (issue.node != null && widget.onAddQuestToNode != null) {
      return () => widget.onAddQuestToNode!(issue.node!);
    }
    return switch (issue.kind) {
      _PlanningIssueKind.missingGoal => widget.onEditSkill,
      _PlanningIssueKind.noActiveQuests => widget.onAddTask,
      _ => null,
    };
  }
}

class _PrimaryPlanningIssueCard extends StatelessWidget {
  final _PlanningIssue issue;
  final bool isDark;
  final VoidCallback? onTap;

  const _PrimaryPlanningIssueCard({
    required this.issue,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final guidance = _planningIssueGuidance(issue);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withAlpha(
          isDark ? 30 : 150,
        ),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: issue.color.withAlpha(38)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(issue.icon, color: issue.color, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  guidance,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtext(isDark),
                    fontSize: 11.6,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            PressFeedback(
              onTap: onTap!,
              tooltip: issue.actionLabel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: issue.color.withAlpha(isDark ? 20 : 13),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: issue.color.withAlpha(58)),
                ),
                child: Text(
                  issue.actionLabel,
                  style: TextStyle(
                    color: issue.color,
                    fontSize: 11.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _planningIssueGuidance(_PlanningIssue issue) {
  return switch (issue.kind) {
    _PlanningIssueKind.missingGoal =>
      'Опиши смысл навыка, чтобы квесты не ощущались случайным списком.',
    _PlanningIssueKind.noActiveQuests =>
      'Создай первый практический шаг, который можно сделать уже завтра.',
    _PlanningIssueKind.missingMinimum =>
      'Добавь лёгкий старт: маленькое действие снижает сопротивление.',
    _PlanningIssueKind.missingNode =>
      'Свяжи квест с этапом, чтобы карта мастерства показывала путь.',
    _PlanningIssueKind.emptyNode =>
      'Создай квест-практику: этап должен двигаться реальными действиями.',
    _PlanningIssueKind.longTermWithoutSteps =>
      'Разбей большой квест на шаги, чтобы он перестал быть туманной целью.',
    _PlanningIssueKind.shortTitle =>
      'Уточни формулировку, чтобы сразу было понятно следующее действие.',
    _PlanningIssueKind.repeatingWithoutReminder =>
      'Настрой напоминание, если привычка легко теряется в течение дня.',
    _PlanningIssueKind.heavyArchive =>
      'Архив уже большой: держи фокус на активных квестах, а не на прошлом.',
  };
}

class _SetupIssueRow extends StatelessWidget {
  final _PlanningIssue issue;
  final bool isDark;
  final VoidCallback? onTap;

  const _SetupIssueRow({
    required this.issue,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: issue.color.withAlpha(isDark ? 12 : 8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: issue.color.withAlpha(38)),
      ),
      child: Row(
        children: [
          Icon(issue.icon, color: issue.color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  issue.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtext(isDark),
                    fontSize: 11.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            PressFeedback(
              onTap: onTap!,
              tooltip: issue.actionLabel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: issue.color.withAlpha(isDark ? 18 : 12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: issue.color.withAlpha(55)),
                ),
                child: Text(
                  issue.actionLabel,
                  style: TextStyle(
                    color: issue.color,
                    fontSize: 11.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkillPassportHeader extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final int activeCount;
  final int doneCount;
  final VoidCallback onEditSkill;
  final VoidCallback onAddTask;

  const _SkillPassportHeader({
    required this.skill,
    required this.isDark,
    required this.activeCount,
    required this.doneCount,
    required this.onEditSkill,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: skill.color.withAlpha(isDark ? 34 : 25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(skill.icon, color: skill.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: txt,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      skill.goal.isEmpty ? 'Цель пока не описана' : skill.goal,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: sub,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  _OutlineActionButton(
                    label: 'Редактировать',
                    icon: Icons.edit,
                    color: const Color(0xFF8E8E93),
                    isDark: isDark,
                    onTap: onEditSkill,
                  ),
                  SmallBtn(
                    label: 'Квест',
                    icon: Icons.add,
                    color: const Color(0xFF4A9EFF),
                    onTap: onAddTask,
                    tooltip: 'Создать квест',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              LvlBadge(level: skill.level, color: skill.color),
              _SoftPill(
                label: '$activeCount активных',
                color: const Color(0xFF4A9EFF),
                isDark: isDark,
              ),
              _SoftPill(
                label: '$doneCount в архиве',
                color: const Color(0xFF8E8E93),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: XPBar(
                  progress: skill.progress,
                  color: skill.color,
                  height: 7,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${skill.xp} / ${skill.xpNeeded} XP',
                style: TextStyle(
                  color: sub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
