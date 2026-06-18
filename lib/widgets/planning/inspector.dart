part of '../planning_workspace.dart';

class _PlanningInspector extends StatelessWidget {
  final AppState state;
  final Skill? skill;
  final bool isDark;
  final VoidCallback? onAddTask;
  final VoidCallback? onEditSkill;
  final ValueChanged<Task>? onEditTask;
  final VoidCallback? onAddNode;
  final ValueChanged<SkillTreeNode>? onAddQuestToNode;
  final VoidCallback? onOpenMasteryMap;
  final VoidCallback? onDeleteSkill;

  const _PlanningInspector({
    required this.state,
    required this.skill,
    required this.isDark,
    required this.onAddTask,
    required this.onEditSkill,
    required this.onEditTask,
    required this.onAddNode,
    required this.onAddQuestToNode,
    required this.onOpenMasteryMap,
    required this.onDeleteSkill,
  });

  @override
  Widget build(BuildContext context) {
    final selected = skill;
    final sub = subtext(isDark);

    if (selected == null) {
      return AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SectionTitle(
                isDark: isDark,
                icon: Icons.manage_search,
                title: 'Инспектор',
                subtitle: 'Выберите навык, чтобы увидеть ближайшую настройку.',
              ),
              const SizedBox(height: 32),
              EmptyStateMessage(
                isDark: isDark,
                icon: Icons.construction,
                title: 'Мастерская системы',
                subtitle:
                    'Выберите навык, чтобы увидеть настройку, которая облегчит следующий квест.',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    final diagnostics = _buildPlanningDiagnostics(state, selected);
    final reminders = diagnostics.activeTasks
        .where((task) => task.notificationsEnabled)
        .length;
    final primaryIssue = diagnostics.primaryIssue;
    final quickQuestNode =
        diagnostics.emptyNodes.firstOrNull ??
        selected.treeNodes
            .where(
              (node) =>
                  selected.treeNodeStatus(node) == SkillTreeNodeStatus.active,
            )
            .firstOrNull ??
        selected.treeNodes.firstOrNull;

    return AppPanel(
      isDark: isDark,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              isDark: isDark,
              icon: Icons.manage_search,
              title: 'Инспектор планирования',
              subtitle: 'Что можно улучшить прямо сейчас.',
            ),
            const SizedBox(height: 8),
            _ReadinessMiniCard(diagnostics: diagnostics, isDark: isDark),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.55,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _PlanningMetric(
                  isDark: isDark,
                  icon: Icons.playlist_add_check,
                  label: 'Активно',
                  value: '${diagnostics.activeTasks.length}',
                  color: const Color(0xFF4A9EFF),
                ),
                _PlanningMetric(
                  isDark: isDark,
                  icon: Icons.inventory_2_outlined,
                  label: 'Архив',
                  value: '${diagnostics.completedTasks.length}',
                  color: const Color(0xFF8E8E93),
                ),
                _PlanningMetric(
                  isDark: isDark,
                  icon: Icons.repeat,
                  label: 'Повторы',
                  value: '${diagnostics.repeatingTasks.length}',
                  color: const Color(0xFF34C759),
                ),
                _PlanningMetric(
                  isDark: isDark,
                  icon: Icons.notifications_active,
                  label: 'Напомин.',
                  value: '$reminders',
                  color: const Color(0xFFAF52DE),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MasteryMapPlanningCard(
              diagnostics: diagnostics,
              isDark: isDark,
              onAddNode: onAddNode,
              onOpenMasteryMap: onOpenMasteryMap,
              onAddQuestToNode:
                  onAddQuestToNode == null || quickQuestNode == null
                  ? null
                  : () => onAddQuestToNode?.call(quickQuestNode),
            ),
            const SizedBox(height: 12),
            _SectionTitle(
              isDark: isDark,
              icon: Icons.tips_and_updates_outlined,
              title: 'Следующее улучшение',
              subtitle: 'Одна настройка, которая сильнее всего поможет завтра.',
              dense: true,
            ),
            const SizedBox(height: 8),
            if (primaryIssue == null)
              _InspectorHint(
                isDark: isDark,
                icon: Icons.check_circle,
                color: const Color(0xFF34C759),
                title: 'Структура выглядит устойчиво',
                subtitle: 'Можно добавить следующий квест или этап.',
              )
            else
              _PrimaryPlanningIssueCard(
                issue: primaryIssue,
                isDark: isDark,
                onTap: _actionFor(primaryIssue),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onAddTask != null)
                  _OutlineActionButton(
                    label: 'Квест',
                    icon: Icons.add_task,
                    color: const Color(0xFF4A9EFF),
                    isDark: isDark,
                    onTap: onAddTask!,
                  ),
                if (onAddNode != null)
                  _OutlineActionButton(
                    label: 'Этап',
                    icon: Icons.account_tree,
                    color: const Color(0xFF4A9EFF),
                    isDark: isDark,
                    onTap: onAddNode!,
                  ),
                if (onOpenMasteryMap != null)
                  _OutlineActionButton(
                    label: 'Карта',
                    icon: Icons.map_outlined,
                    color: const Color(0xFF8E8E93),
                    isDark: isDark,
                    onTap: onOpenMasteryMap!,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: borderColor(isDark)),
            const SizedBox(height: 6),
            Text(
              'Опасная зона',
              style: TextStyle(
                color: sub,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (onDeleteSkill != null)
              _OutlineActionButton(
                label: 'Удалить навык',
                icon: Icons.delete_outline,
                color: const Color(0xFFFF3B30),
                isDark: isDark,
                onTap: onDeleteSkill!,
              ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _actionFor(_PlanningIssue issue) {
    if (issue.task != null && onEditTask != null) {
      return () => onEditTask!(issue.task!);
    }
    if (issue.node != null && onAddQuestToNode != null) {
      return () => onAddQuestToNode!(issue.node!);
    }
    return switch (issue.kind) {
      _PlanningIssueKind.missingGoal => onEditSkill,
      _PlanningIssueKind.noActiveQuests => onAddTask,
      _ => null,
    };
  }
}

class _ReadinessMiniCard extends StatelessWidget {
  final _PlanningDiagnostics diagnostics;
  final bool isDark;

  const _ReadinessMiniCard({required this.diagnostics, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _readinessColor(diagnostics.readinessPercent);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 13 : 9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: color, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Готовность системы',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${diagnostics.readinessPercent}%',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XPBar(
            progress: diagnostics.readinessPercent / 100,
            color: color,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _MasteryMapPlanningCard extends StatelessWidget {
  final _PlanningDiagnostics diagnostics;
  final bool isDark;
  final VoidCallback? onAddNode;
  final VoidCallback? onOpenMasteryMap;
  final VoidCallback? onAddQuestToNode;

  const _MasteryMapPlanningCard({
    required this.diagnostics,
    required this.isDark,
    required this.onAddNode,
    required this.onOpenMasteryMap,
    required this.onAddQuestToNode,
  });

  @override
  Widget build(BuildContext context) {
    final skill = diagnostics.skill;
    final total = skill.treeNodes.length;
    final mastered = diagnostics.masteredNodeCount;
    final active = diagnostics.activeNodeCount;
    final locked = diagnostics.lockedNodeCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A9EFF).withAlpha(isDark ? 12 : 8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A9EFF).withAlpha(42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            isDark: isDark,
            icon: Icons.account_tree,
            title: 'Карта мастерства',
            subtitle: total == 0
                ? 'У навыка пока нет этапов.'
                : '$total этап. · $mastered освоено · $active активно · $locked закрыто',
            dense: true,
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SoftPill(
                label: '${diagnostics.emptyNodes.length} без практики',
                color: diagnostics.emptyNodes.isEmpty
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF9500),
                isDark: isDark,
              ),
              _SoftPill(
                label: '${diagnostics.unlinkedTasks.length} квест. без этапа',
                color: diagnostics.unlinkedTasks.isEmpty
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF9500),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (onAddNode != null)
                _OutlineActionButton(
                  label: 'Этап',
                  icon: Icons.add,
                  color: const Color(0xFF4A9EFF),
                  isDark: isDark,
                  onTap: onAddNode!,
                ),
              if (onAddQuestToNode != null)
                _OutlineActionButton(
                  label: 'Создать квест',
                  icon: Icons.add_task,
                  color: const Color(0xFFFF9500),
                  isDark: isDark,
                  onTap: onAddQuestToNode!,
                ),
              if (onOpenMasteryMap != null)
                _OutlineActionButton(
                  label: 'Открыть карту',
                  icon: Icons.map_outlined,
                  color: const Color(0xFF8E8E93),
                  isDark: isDark,
                  onTap: onOpenMasteryMap!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanningMetric extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PlanningMetric({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 15 : 10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 17),
          Text(
            value,
            style: TextStyle(
              color: textColor(isDark),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subtext(isDark),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
