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

    return SizedBox(
      height: 98,
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
                          ? 'Выберите навык'
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
                    : ReorderableListView.builder(
                        key: const ValueKey('compact-skill-list'),
                        scrollDirection: Axis.horizontal,
                        itemCount: state.skills.length,
                        buildDefaultDragHandles: false,
                        onReorderItem: state.reorderSkills,
                        itemBuilder: (_, index) {
                          final skill = state.skills[index];
                          final selected = state.selectedSkillId == skill.id;
                          return Padding(
                            key: ValueKey(
                              'compact-skill-reorder-item-${skill.id}',
                            ),
                            padding: EdgeInsets.only(
                              right: index == state.skills.length - 1 ? 0 : 7,
                            ),
                            child: ReorderableDelayedDragStartListener(
                              key: ValueKey(
                                'compact-skill-reorder-${skill.id}',
                              ),
                              index: index,
                              child: _CompactSkillChip(
                                skill: skill,
                                selected: selected,
                                isDark: isDark,
                                taskCount: state.activeTaskCountForSkill(
                                  skill.id,
                                ),
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
      ),
    );
  }

  void _addSkill(BuildContext context) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => AddSkillDialog(
        isDark: state.isDark,
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
  final VoidCallback onTap;

  const _CompactSkillChip({
    required this.skill,
    required this.selected,
    required this.isDark,
    required this.taskCount,
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
            const SizedBox(width: 2),
            Icon(Icons.drag_indicator_rounded, color: sub, size: 13),
          ],
        ),
      ),
    );
  }
}
