import 'package:flutter/material.dart';
import '../models.dart';
import '../app_state.dart';
import '../utils.dart';
import 'shared.dart';
import 'dialogs.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SKILLS PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class SkillsPanel extends StatelessWidget {
  final bool planningMode;
  final ValueChanged<Skill>? onOpenRoadmap;

  const SkillsPanel({super.key, this.planningMode = false, this.onOpenRoadmap});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isDark = state.isDark;
    final sfc = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: sfc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bdr),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                Icon(
                  planningMode ? Icons.account_tree_outlined : Icons.bolt,
                  color: const Color(0xFF4A9EFF),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          planningMode ? 'Система навыков' : 'Навыки',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: txt,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${state.skills.length})',
                        style: TextStyle(color: sub, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                HoverScale(
                  child: SmallBtn(
                    label: 'Навык',
                    icon: Icons.add,
                    color: const Color(0xFF4A9EFF),
                    tooltip: 'Создать навык, который будет получать XP',
                    onTap: () => _addDialog(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                state.selectedSkillId == null
                    ? planningMode
                          ? 'Выберите направление для настройки цели, этапов и квестов'
                          : 'Выберите навык для просмотра квестов'
                    : planningMode
                    ? 'Настройка: ${state.selectedSkill?.name ?? ""}'
                    : 'Квесты: ${state.selectedSkill?.name ?? ""}',
                style: TextStyle(color: sub, fontSize: 12),
              ),
            ),
          ),
          Container(height: 1, color: bdr),
          Expanded(
            child: MotionFadeSlideSwitcher(
              child: state.skills.isEmpty
                  ? _EmptySkillsState(
                      key: const ValueKey('skills-empty-state'),
                      isDark: isDark,
                      onAdd: () => _addDialog(context),
                    )
                  : ListView.separated(
                      key: const ValueKey('skills-list'),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: state.skills.length,
                      separatorBuilder: (_, _) => Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: bdr,
                      ),
                      itemBuilder: (ctx, i) {
                        final sk = state.skills[i];
                        return MotionListItem(
                          key: ValueKey('skill-${sk.id}'),
                          index: i,
                          child: SkillCard(
                            skill: sk,
                            taskCount: state.activeTaskCountForSkill(sk.id),
                            isSelected: state.selectedSkillId == sk.id,
                            isDark: isDark,
                            onTap: () => state.selectSkill(sk.id),
                            onRoadmap: () => onOpenRoadmap?.call(sk),
                            onEdit: () => _editDialog(context, sk),
                            onDelete: () => _confirmDeleteSkill(context, sk),
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

  void _addDialog(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) {
      final state = AppStateProvider.of(ctx);
      return AddSkillDialog(
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
      );
    },
  );

  void _editDialog(BuildContext ctx, Skill sk) => showDialog(
    context: ctx,
    builder: (_) {
      final state = AppStateProvider.of(ctx);
      return AddSkillDialog(
        isDark: state.isDark,
        existing: sk,
        onSave: (name, goal, checklist, color, icon, _, _) => state.updateSkill(
          sk,
          name: name,
          goal: goal,
          checklist: checklist,
          color: color,
          icon: icon,
        ),
      );
    },
  );

  void _confirmDeleteSkill(BuildContext ctx, Skill skill) {
    final state = AppStateProvider.of(ctx);
    final isDark = state.isDark;
    final taskCount = state.tasks
        .where((task) => task.skillId == skill.id)
        .length;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    const danger = Color(0xFFFF3B30);

    showDialog<void>(
      context: ctx,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface(isDark),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: danger.withAlpha(80)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 130 : 34),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: danger.withAlpha(28),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: danger,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Удалить навык?',
                        style: TextStyle(
                          color: txt,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Навык «${skill.name}» будет удалён вместе с уровнем, XP, этапами RoadMap и всеми квестами этого навыка.',
                  style: TextStyle(
                    color: sub,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TaskBadge(
                  icon: Icons.warning_amber_rounded,
                  label: taskCount == 0
                      ? 'Квестов нет'
                      : 'Будет удалено квестов: $taskCount',
                  color: danger,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SmallBtn(
                      label: 'Отмена',
                      icon: Icons.close_rounded,
                      color: sub,
                      onTap: () => Navigator.pop(dialogContext),
                    ),
                    const SizedBox(width: 10),
                    SmallBtn(
                      label: 'Удалить',
                      icon: Icons.delete_outline,
                      color: danger,
                      onTap: () {
                        state.removeSkill(skill.id);
                        Navigator.pop(dialogContext);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptySkillsState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;

  const _EmptySkillsState({
    super.key,
    required this.isDark,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    const color = Color(0xFF4A9EFF);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, color: color.withAlpha(220), size: 36),
            const SizedBox(height: 12),
            Text(
              'Создайте первый навык',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: txt,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Навык — это направление роста. Первый этап появится сразу, а квест добавляется следующим шагом.',
              textAlign: TextAlign.center,
              style: TextStyle(color: sub, fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 14),
            HoverScale(
              child: SmallBtn(
                label: 'Первый навык',
                icon: Icons.add,
                color: color,
                tooltip: 'Создать первый навык',
                onTap: onAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skill Card ───────────────────────────────────────────────────────────────

class SkillCard extends StatefulWidget {
  final Skill skill;
  final int taskCount;
  final bool isSelected, isDark;
  final VoidCallback onTap, onRoadmap, onEdit, onDelete;
  const SkillCard({
    super.key,
    required this.skill,
    required this.taskCount,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onRoadmap,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  State<SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<SkillCard> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final sk = widget.skill;
    final isDark = widget.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    final bg = widget.isSelected
        ? sk.color.withAlpha(22)
        : _h
        ? sk.color.withAlpha(isDark ? 10 : 8)
        : Colors.transparent;
    final showActions = _h;

    // FIX: wrap in ClipRect to prevent AnimatedContainer overflow error
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedScale(
        scale: 1,
        alignment: Alignment.center,
        duration: kMotionStandard,
        curve: kMotionCurve,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            clipBehavior: Clip.hardEdge, // ← FIX overflow
            duration: kMotionStandard,
            curve: kMotionCurve,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: widget.isSelected || _h
                  ? Border.all(
                      color: sk.color.withAlpha(widget.isSelected ? 100 : 55),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: sk.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(sk.icon, color: sk.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedPadding(
                    duration: kMotionStandard,
                    curve: kMotionCurve,
                    padding: EdgeInsets.only(right: showActions ? 8 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sk.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: txt,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            LvlBadge(level: sk.level, color: sk.color),
                            if (widget.taskCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 15,
                                height: 15,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDDDDEE),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${widget.taskCount}',
                                    style: const TextStyle(
                                      color: Color(0xFF2A2A40),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final showMapProgress = constraints.maxWidth >= 190;
                            final showXpText = constraints.maxWidth >= 150;

                            return Row(
                              children: [
                                Text(
                                  'Ур.${sk.level}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: sk.color.withAlpha(220),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (showMapProgress &&
                                    sk.treeNodes.isNotEmpty) ...[
                                  Icon(
                                    Icons.account_tree,
                                    size: 11,
                                    color: sub,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${sk.masteredTreeNodeCount}/${sk.treeNodes.length}',
                                    style: TextStyle(
                                      color: sub,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: XPBar(
                                    progress: sk.progress,
                                    color: sk.color,
                                    height: 5,
                                  ),
                                ),
                                if (showXpText) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '${sk.xp}/${sk.xpNeeded}',
                                    style: TextStyle(color: sub, fontSize: 10),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: kMotionStandard,
                  curve: kMotionCurve,
                  alignment: Alignment.centerRight,
                  child: showActions
                      ? SizedBox(
                          width: 75,
                          child: AnimatedOpacity(
                            duration: kMotionFast,
                            curve: kMotionCurve,
                            opacity: 1,
                            child: Row(
                              children: [
                                MiniBtn(
                                  icon: Icons.route_rounded,
                                  color: sk.color,
                                  tooltip: 'Открыть путь навыка в RoadMap',
                                  onTap: widget.onRoadmap,
                                ),
                                MiniBtn(
                                  icon: Icons.edit,
                                  color: sub,
                                  tooltip: 'Редактировать навык',
                                  onTap: widget.onEdit,
                                ),
                                MiniBtn(
                                  icon: Icons.delete_outline,
                                  color: const Color(0xFFFF3B30),
                                  tooltip: 'Удалить навык',
                                  onTap: widget.onDelete,
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
