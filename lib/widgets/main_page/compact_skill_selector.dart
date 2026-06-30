part of '../main_page.dart';

class _CompactSkillSelector extends StatelessWidget {
  const _CompactSkillSelector();

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isDark = state.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final selectedSkill = state.selectedSkill;
    final expanded = selectedSkill == null;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedContainer(
      key: ValueKey(
        expanded ? 'mobile-skill-panel-expanded' : 'mobile-skill-panel-compact',
      ),
      duration: reduceMotion ? Duration.zero : kMotionStandard,
      curve: kMotionCurve,
      height: expanded ? 214 : 98,
      child: AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, color: const Color(0xFF4A9EFF), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      selectedSkill == null
                          ? 'Навыки'
                          : 'Фокус: ${selectedSkill.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: txt,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SmallBtn(
                    key: const ValueKey('mobile-add-skill-open'),
                    label: 'Навык',
                    icon: Icons.add,
                    color: const Color(0xFF4A9EFF),
                    tooltip: 'Создать навык и первый квест',
                    onTap: () => _addSkill(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: state.skills.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Создайте навык — приложение сразу добавит первый этап.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: sub,
                            fontSize: 11.5,
                            height: 1.2,
                          ),
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : kMotionStandard,
                        switchInCurve: kMotionCurve,
                        switchOutCurve: kMotionCurve,
                        child: KeyedSubtree(
                          key: ValueKey(
                            expanded
                                ? 'mobile-skill-list-expanded'
                                : 'mobile-skill-list-compact',
                          ),
                          child: ReorderableListView.builder(
                            key: const ValueKey('compact-skill-list'),
                            scrollDirection: Axis.horizontal,
                            itemCount: state.skills.length,
                            buildDefaultDragHandles: false,
                            onReorderItem: state.reorderSkills,
                            itemBuilder: (_, index) {
                              final skill = state.skills[index];
                              final selected =
                                  state.selectedSkillId == skill.id;
                              final canReorder = skill.id != kInboxSkillId;
                              final taskCount = state
                                  .tasksForSkill(skill.id)
                                  .where((task) => !task.isDone)
                                  .length;
                              final item = expanded
                                  ? _ExpandedMobileSkillCard(
                                      skill: skill,
                                      isDark: isDark,
                                      taskCount: taskCount,
                                      onTap: () => state.selectSkill(skill.id),
                                    )
                                  : _CompactSkillChip(
                                      skill: skill,
                                      selected: selected,
                                      isDark: isDark,
                                      taskCount: taskCount,
                                      canReorder: canReorder,
                                      onTap: () => state.selectSkill(skill.id),
                                    );
                              return Padding(
                                key: ValueKey(
                                  'compact-skill-reorder-item-${skill.id}',
                                ),
                                padding: EdgeInsets.only(
                                  right: index == state.skills.length - 1
                                      ? 0
                                      : 7,
                                ),
                                child: canReorder
                                    ? ReorderableDelayedDragStartListener(
                                        key: ValueKey(
                                          'compact-skill-reorder-${skill.id}',
                                        ),
                                        index: index,
                                        child: item,
                                      )
                                    : item,
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSkill(BuildContext context) {
    final state = AppStateProvider.of(context);
    showAdaptiveCreationForm<void>(
      context: context,
      builder: (_, fullScreen) => AddSkillDialog(
        isDark: state.isDark,
        fullScreen: fullScreen,
        onSave: (name, goal, checklist, color, icon, initialTreeNodes, _) {
          final skillId = uid();
          state.addSkill(
            Skill(
              id: skillId,
              name: name,
              goal: goal,
              color: color,
              icon: icon,
              checklist: checklist,
              treeNodes: initialTreeNodes,
            ),
          );
          state.selectSkill(skillId);
        },
      ),
    );
  }
}

class _ExpandedMobileSkillCard extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final int taskCount;
  final VoidCallback onTap;

  const _ExpandedMobileSkillCard({
    required this.skill,
    required this.isDark,
    required this.taskCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final color = skill.color;
    final isInbox = skill.id == kInboxSkillId;
    final progress = const GoalProgressEngine().snapshotForSkill(skill);
    final questLabel =
        '$taskCount ${_countLabel(taskCount, 'квест', 'квеста', 'квестов')}';
    final inboxLabel = _countLabel(
      taskCount,
      'быстрая задача',
      'быстрые задачи',
      'быстрых задач',
    );

    return Semantics(
      button: true,
      label: isInbox
          ? '${skill.name}, $taskCount $inboxLabel'
          : '${skill.name}, уровень ${skill.level}, $questLabel, '
                '${progress.isEmpty ? "этапы не добавлены" : progress.percentLabel}',
      child: PressFeedback(
        scale: 0.98,
        onTap: onTap,
        child: Container(
          key: ValueKey('mobile-expanded-skill-${skill.id}'),
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 22 : 13),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withAlpha(isDark ? 58 : 42)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withAlpha(isDark ? 38 : 26),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(skill.icon, color: color, size: 21),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      skill.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: txt,
                        fontSize: 14,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: sub, size: 17),
                ],
              ),
              const Spacer(),
              if (isInbox)
                Text(
                  '$taskCount $inboxLabel',
                  key: const ValueKey('mobile-inbox-task-count'),
                  style: TextStyle(
                    color: sub,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else ...[
                Row(
                  children: [
                    _MobileSkillMetric(
                      key: ValueKey('mobile-skill-level-${skill.id}'),
                      icon: Icons.bolt_rounded,
                      label: 'Ур. ${skill.level}',
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    _MobileSkillMetric(
                      key: ValueKey('mobile-skill-quests-${skill.id}'),
                      icon: Icons.checklist_rounded,
                      label: questLabel,
                      color: sub,
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progress.isEmpty
                            ? 'Этапы не добавлены'
                            : 'Прогресс цели',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: sub,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!progress.isEmpty)
                      Text(
                        progress.percentLabel,
                        key: ValueKey('mobile-skill-progress-${skill.id}'),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.isEmpty ? 0 : progress.value,
                    minHeight: 5,
                    backgroundColor: color.withAlpha(28),
                    valueColor: AlwaysStoppedAnimation(
                      progress.isEmpty ? sub.withAlpha(90) : color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _countLabel(int count, String one, String few, String many) {
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return many;
    return switch (count % 10) {
      1 => one,
      2 || 3 || 4 => few,
      _ => many,
    };
  }
}

class _MobileSkillMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MobileSkillMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CompactSkillChip extends StatefulWidget {
  final Skill skill;
  final bool selected;
  final bool isDark;
  final int taskCount;
  final bool canReorder;
  final VoidCallback onTap;

  const _CompactSkillChip({
    required this.skill,
    required this.selected,
    required this.isDark,
    required this.taskCount,
    required this.canReorder,
    required this.onTap,
  });

  @override
  State<_CompactSkillChip> createState() => _CompactSkillChipState();
}

class _CompactSkillChipState extends State<_CompactSkillChip> {
  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final sub = subtext(widget.isDark);
    final color = skill.color;

    return PressFeedback(
      scale: 0.97,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: kMotionStandard,
        curve: kMotionCurve,
        constraints: const BoxConstraints(minWidth: 118, maxWidth: 190),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: widget.selected
              ? color.withAlpha(widget.isDark ? 30 : 20)
              : color.withAlpha(widget.isDark ? 12 : 8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: widget.selected ? color.withAlpha(90) : color.withAlpha(34),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(skill.icon, color: color, size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                skill.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.selected ? color : textColor(widget.isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.taskCount}',
              style: TextStyle(
                color: widget.selected ? color : sub,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (widget.canReorder) ...[
              const SizedBox(width: 2),
              Icon(Icons.drag_indicator_rounded, color: sub, size: 13),
            ],
          ],
        ),
      ),
    );
  }
}
