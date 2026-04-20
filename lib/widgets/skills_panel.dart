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
  final AppState state;
  const SkillsPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final activeTaskCounts = state.activeTaskCountsBySkill;

    return AppPanel(
      isDark: isDark,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFF4A9EFF), size: 20),
                const SizedBox(width: 6),
                Text(
                  'Навыки',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: txt,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${state.skills.length})',
                  style: TextStyle(color: sub, fontSize: 13),
                ),
                const Spacer(),
                SmallBtn(
                  label: 'Добавить',
                  icon: Icons.add,
                  color: const Color(0xFF4A9EFF),
                  onTap: () => _addDialog(context),
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
                    ? 'Выберите навык для просмотра задач'
                    : 'Задачи: ${state.selectedSkill?.name ?? ""}',
                style: TextStyle(color: sub, fontSize: 12),
              ),
            ),
          ),
          PanelDivider(isDark: isDark),
          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: state.skills.length,
              separatorBuilder: (_, separator) => Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: borderColor(isDark),
              ),
              itemBuilder: (ctx, i) {
                final sk = state.skills[i];
                return SkillCard(
                  skill: sk,
                  taskCount: activeTaskCounts[sk.id] ?? 0,
                  isSelected: state.selectedSkillId == sk.id,
                  isDark: isDark,
                  onTap: () => state.selectSkill(sk.id),
                  onEdit: () => _editDialog(context, sk),
                  onDelete: () => state.removeSkill(sk.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addDialog(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AddSkillDialog(
      isDark: state.isDark,
      onSave: (name, goal, checklist, color, icon) => state.addSkill(
        Skill(
          id: uid(),
          name: name,
          goal: goal,
          color: color,
          icon: icon,
          checklist: checklist,
        ),
      ),
    ),
  );

  void _editDialog(BuildContext ctx, Skill sk) => showDialog(
    context: ctx,
    builder: (_) => AddSkillDialog(
      isDark: state.isDark,
      existing: sk,
      onSave: (name, goal, checklist, color, icon) {
        sk.name = name;
        sk.goal = goal;
        sk.checklist = checklist;
        sk.color = color;
        sk.icon = icon;
        sk.syncChecklistDone();
        state.refresh();
      },
    ),
  );
}

// ─── Skill Card ───────────────────────────────────────────────────────────────

class SkillCard extends StatefulWidget {
  final Skill skill;
  final int taskCount;
  final bool isSelected, isDark;
  final VoidCallback onTap, onEdit, onDelete;
  const SkillCard({
    super.key,
    required this.skill,
    required this.taskCount,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
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

    Color bg = Colors.transparent;
    if (widget.isSelected) {
      bg = sk.color.withAlpha(22);
    } else if (_h) {
      bg = isDark ? const Color(0xFF22222E) : const Color(0xFFF0F0F8);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: widget.isSelected
                ? Border.all(color: sk.color.withAlpha(100))
                : null,
          ),
          child: Row(
            children: [
              // Icon badge
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
                          const SizedBox(width: 4),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: sk.color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.taskCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: XPBar(
                            progress: sk.progress,
                            color: sk.color,
                            height: 5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${sk.xp}/${sk.xpNeeded}',
                          style: TextStyle(color: sub, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Hover actions
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: (_h || widget.isSelected) ? 48 : 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 48,
                    child: Row(
                      children: [
                        MiniBtn(
                          icon: Icons.edit,
                          color: sub,
                          onTap: widget.onEdit,
                        ),
                        MiniBtn(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFFF3B30),
                          onTap: widget.onDelete,
                        ),
                      ],
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
}
