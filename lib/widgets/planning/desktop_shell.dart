part of '../planning_workspace.dart';

class _PlanningHero extends StatelessWidget {
  final bool isDark;

  const _PlanningHero({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4A9EFF);
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return AppPanel(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_note, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Планировать систему',
                    style: TextStyle(
                      color: txt,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Навыки, цели и квесты живут здесь. Это режим спокойной настройки, без давления “сделай сейчас”.',
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
          ],
        ),
      ),
    );
  }
}

class _PlanningSkillRail extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final VoidCallback onAddSkill;

  const _PlanningSkillRail({
    required this.state,
    required this.isDark,
    required this.onAddSkill,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return AppPanel(
      isDark: isDark,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.view_list_rounded, color: Color(0xFF4A9EFF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Навыки системы',
                    style: TextStyle(
                      color: txt,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SmallBtn(
                  label: 'Навык',
                  icon: Icons.add,
                  color: const Color(0xFF4A9EFF),
                  onTap: onAddSkill,
                  tooltip: 'Добавить навык',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                state.selectedSkill == null
                    ? 'Выберите навык для настройки'
                    : 'Настройка: ${state.selectedSkill!.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: sub,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          PanelDivider(isDark: isDark),
          Expanded(
            child: state.roadmapSkills.isEmpty
                ? EmptyStateMessage(
                    isDark: isDark,
                    icon: Icons.bolt,
                    title: 'Навыков пока нет',
                    subtitle:
                        'Сначала создай первый навык в “Сейчас”: здесь позже появится одна ближайшая настройка.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.skills.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final skill = state.skills[index];
                      final taskCount = state.tasksForSkill(skill.id).length;
                      return MotionListItem(
                        key: ValueKey('planning-skill-${skill.id}'),
                        index: index,
                        child: _PlanningSkillTile(
                          skill: skill,
                          isDark: isDark,
                          taskCount: taskCount,
                          selected: state.selectedSkillId == skill.id,
                          onTap: () => state.selectSkill(skill.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlanningSkillTile extends StatefulWidget {
  final Skill skill;
  final bool isDark;
  final int taskCount;
  final bool selected;
  final VoidCallback onTap;

  const _PlanningSkillTile({
    required this.skill,
    required this.isDark,
    required this.taskCount,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PlanningSkillTile> createState() => _PlanningSkillTileState();
}

class _PlanningSkillTileState extends State<_PlanningSkillTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final isDark = widget.isDark;
    final color = skill.color;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final selected = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: kMotionStandard,
          curve: kMotionCurve,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? color.withAlpha(isDark ? 22 : 18)
                : _hovered
                ? color.withAlpha(isDark ? 12 : 10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color.withAlpha(140) : borderColor(isDark),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 34 : 24),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(skill.icon, color: color, size: 20),
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
                              color: txt,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _SoftPill(
                          label: 'Ур. ${skill.level}',
                          color: color,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          'Квесты',
                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.route, color: sub.withAlpha(150), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '${widget.taskCount}',
                          style: TextStyle(
                            color: sub,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: XPBar(
                            progress: skill.progress,
                            color: color,
                            height: 5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${skill.xp}/${skill.xpNeeded}',
                          style: TextStyle(color: sub, fontSize: 11),
                        ),
                      ],
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
