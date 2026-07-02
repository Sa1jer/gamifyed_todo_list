part of '../main_page.dart';

class _CompactSkillSelector extends StatelessWidget {
  const _CompactSkillSelector();

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isDark = state.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final skills = state.roadmapSkills;
    final inboxActiveCount = state.inboxTasks
        .where((task) => !task.isDone)
        .length;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedContainer(
      key: const ValueKey('mobile-skill-panel-compact'),
      duration: reduceMotion ? Duration.zero : kMotionStandard,
      curve: kMotionCurve,
      height: 126,
      decoration: BoxDecoration(
        color: surface(isDark),
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Навыки',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: txt,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _MobileInboxShortcut(
                  selected: state.selectedSkillId == kInboxSkillId,
                  count: inboxActiveCount,
                  isDark: isDark,
                  onTap: () => state.selectSkill(kInboxSkillId),
                ),
                const SizedBox(width: 5),
                IconButton.filled(
                  key: const ValueKey('mobile-add-skill-open'),
                  tooltip: 'Создать навык',
                  onPressed: () => _addSkill(context),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(44),
                    maximumSize: const Size.square(44),
                    backgroundColor: const Color(0xFF4A9EFF),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Expanded(
              child: skills.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Создай первый навык, чтобы начать свой путь.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: sub,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      key: const ValueKey('compact-skill-list'),
                      scrollDirection: Axis.horizontal,
                      itemCount: skills.length,
                      buildDefaultDragHandles: false,
                      onReorderItem: state.reorderSkills,
                      itemBuilder: (_, index) {
                        final skill = skills[index];
                        final selected = state.selectedSkillId == skill.id;
                        final taskCount = state
                            .tasksForSkill(skill.id)
                            .where((task) => !task.isDone)
                            .length;
                        return Padding(
                          key: ValueKey(
                            'compact-skill-reorder-item-${skill.id}',
                          ),
                          padding: EdgeInsets.only(
                            right: index == skills.length - 1 ? 0 : 7,
                          ),
                          child: ReorderableDelayedDragStartListener(
                            key: ValueKey('compact-skill-reorder-${skill.id}'),
                            index: index,
                            child: _CompactSkillChip(
                              skill: skill,
                              selected: selected,
                              isDark: isDark,
                              taskCount: taskCount,
                              canReorder: true,
                              onTap: () => state.selectSkill(skill.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
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
    final color = skill.color;

    return Semantics(
      button: true,
      selected: widget.selected,
      label:
          '${skill.name}, уровень ${skill.level}, активных квестов ${widget.taskCount}. Удерживайте, чтобы изменить порядок.',
      child: PressFeedback(
        scale: 0.97,
        onTap: widget.onTap,
        child: AnimatedContainer(
          key: ValueKey('mobile-skill-chip-${skill.id}'),
          duration: kMotionStandard,
          curve: kMotionCurve,
          constraints: const BoxConstraints(minWidth: 132, maxWidth: 184),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? color.withAlpha(widget.isDark ? 30 : 18)
                : widget.isDark
                ? Colors.white.withAlpha(5)
                : Colors.black.withAlpha(3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selected
                  ? color.withAlpha(105)
                  : color.withAlpha(22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withAlpha(widget.isDark ? 25 : 16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(skill.icon, color: color, size: 16),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.selected
                            ? color
                            : textColor(widget.isDark),
                        fontSize: 11.5,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ур. ${skill.level} · ${widget.taskCount} квестов',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtext(widget.isDark),
                        fontSize: 9.5,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileInboxShortcut extends StatelessWidget {
  final bool selected;
  final int count;
  final bool isDark;
  final VoidCallback onTap;

  const _MobileInboxShortcut({
    required this.selected,
    required this.count,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF34C759);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Быстрые задачи, активных $count',
      child: PressFeedback(
        scale: 0.96,
        onTap: onTap,
        child: AnimatedContainer(
          key: const ValueKey('mobile-inbox-shortcut'),
          duration: kMotionStandard,
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.fromLTRB(9, 6, 7, 6),
          decoration: BoxDecoration(
            color: selected
                ? color.withAlpha(isDark ? 27 : 18)
                : isDark
                ? Colors.white.withAlpha(5)
                : Colors.black.withAlpha(3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_rounded, color: color, size: 15),
              const SizedBox(width: 5),
              Text(
                'Быстрые',
                style: TextStyle(
                  color: selected ? color : textColor(isDark),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              InboxTaskCountBubble(
                key: const ValueKey('mobile-inbox-shortcut-count'),
                count: count,
                color: color,
                isDark: isDark,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
