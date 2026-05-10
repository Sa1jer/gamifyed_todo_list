import 'package:flutter/material.dart';
import '../models.dart';
import '../utils.dart';
import '../app_state.dart';
import 'shared.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENTS DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class AchievementsDialog extends StatelessWidget {
  final List<Achievement> achievements;
  final bool isDark;
  const AchievementsDialog({
    super.key,
    required this.achievements,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        height: 560,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Color(0xFFFFCC00),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Достижения',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.85,
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: achievements.length,
                itemBuilder: (_, i) => _AchievementCard(
                  achievement: achievements[i],
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isDark;
  const _AchievementCard({required this.achievement, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final def = achievement.def;
    if (def == null) return const SizedBox.shrink();

    final unlocked = achievement.isUnlocked;
    final sub = subtext(isDark);
    final txt = textColor(isDark);

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: unlocked
              ? def.color.withAlpha(18)
              : (isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7)),
          borderRadius: BorderRadius.circular(12),
          border: unlocked
              ? Border.all(color: def.color.withAlpha(60))
              : Border.all(color: borderColor(isDark)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unlocked
                        ? def.color.withAlpha(30)
                        : sub.withAlpha(20),
                  ),
                  child: Icon(
                    def.icon,
                    color: unlocked ? def.color : sub.withAlpha(100),
                    size: 24,
                  ),
                ),
                if (!unlocked)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withAlpha(60),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              def.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: unlocked ? txt : sub.withAlpha(100),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (unlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                _formatDate(achievement.unlockedAt!),
                style: TextStyle(fontSize: 9, color: sub.withAlpha(150)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final def = achievement.def;
    if (def == null) return;

    final unlocked = achievement.isUnlocked;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (unlocked
                              ? def.color
                              : subtext(AppStateProvider.of(ctx).isDark))
                          .withAlpha(30),
                ),
                child: Icon(
                  def.icon,
                  color: unlocked
                      ? def.color
                      : subtext(AppStateProvider.of(ctx).isDark),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                def.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor(AppStateProvider.of(ctx).isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                def.description,
                style: TextStyle(
                  color: subtext(AppStateProvider.of(ctx).isDark),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: unlocked
                      ? const Color(0xFF34C759).withAlpha(25)
                      : const Color(0xFF8E8E93).withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  unlocked ? 'Разблокировано!' : 'Заблокировано',
                  style: TextStyle(
                    color: unlocked
                        ? const Color(0xFF34C759)
                        : const Color(0xFF8E8E93),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// HISTORY DIALOG  (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

class HistoryDialog extends StatelessWidget {
  final List<HistoryEntry> history;
  final bool isDark;
  const HistoryDialog({super.key, required this.history, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        height: 560,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  Text(
                    'История персонажа',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.85,
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book, color: sub, size: 38),
                          const SizedBox(height: 12),
                          Text(
                            'История пуста',
                            style: TextStyle(color: sub, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Выполни задачу — она появится здесь',
                            style: TextStyle(
                              color: sub.withAlpha(160),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      itemCount: history.length,
                      itemBuilder: (_, i) =>
                          _HistoryCard(entry: history[i], isDark: isDark),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final bool isDark;
  const _HistoryCard({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final c = e.skillColor;
    final sub = subtext(isDark);
    final txt = textColor(isDark);
    final accentBg = e.isCompletion
        ? c.withAlpha(22)
        : const Color(0xFFFF3B30).withAlpha(18);
    final accentBorder = e.isCompletion
        ? c.withAlpha(80)
        : const Color(0xFFFF3B30).withAlpha(60);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  e.taskTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: txt,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    e.isCompletion ? 'Цель выполнена' : 'Выполнение отменено',
                    style: TextStyle(
                      color: sub,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(e.at),
                    style: TextStyle(color: sub, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(e.skillIcon, color: c, size: 13),
              const SizedBox(width: 5),
              Text('Навык: ', style: TextStyle(color: sub, fontSize: 12)),
              Text(
                e.skillName,
                style: TextStyle(
                  color: c,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            e.isCompletion ? '+${e.xp} опыта' : '-${e.xp} опыта',
            style: TextStyle(
              color: e.isCompletion ? c : const Color(0xFFFF3B30),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADD SKILL DIALOG
// FIX 1.0.7: Replaced "Ещё иконки" toggle with a single scrollable grid
//            showing all icons at once (2 rows visible, scrollable vertically).
// ═══════════════════════════════════════════════════════════════════════════════

class AddSkillDialog extends StatefulWidget {
  final bool isDark;
  final Skill? existing;
  final Function(
    String name,
    String goal,
    List<String> checklist,
    Color color,
    IconData icon,
  )
  onSave;
  const AddSkillDialog({
    super.key,
    required this.isDark,
    this.existing,
    required this.onSave,
  });
  @override
  State<AddSkillDialog> createState() => _AddSkillDialogState();
}

class _AddSkillDialogState extends State<AddSkillDialog> {
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _checkCtrl = TextEditingController();
  final List<String> _items = [];
  Color _color = const Color(0xFF4A9EFF);
  IconData _icon = Icons.fitness_center;

  // All icons in a single flat list
  static final _allIcons = [...kIconsPrimary, ...kIconsExtra];

  // Grid geometry
  static const _crossAxisCount = 9;
  static const _itemSize = 38.0;
  static const _spacing = 6.0;
  static const _visibleRows = 2;
  // Height shows exactly 2 rows + gaps
  static const _gridHeight =
      _visibleRows * _itemSize + (_visibleRows - 1) * _spacing + _spacing * 2;

  @override
  void initState() {
    super.initState();
    if (widget.existing case final ex?) {
      _nameCtrl.text = ex.name;
      _goalCtrl.text = ex.goal;
      _items.addAll(ex.checklist);
      _color = ex.color;
      _icon = ex.icon;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = surface(isDark);
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DlgHeader(
                title: widget.existing != null
                    ? 'Редактировать навык'
                    : 'Новый навык',
                txtColor: txt,
              ),
              const SizedBox(height: 16),
              // Preview
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _color.withAlpha(35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_icon, color: _color, size: 30),
                ),
              ),
              const SizedBox(height: 16),
              DlgField(
                label: 'Название навыка',
                ctrl: _nameCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
              ),
              const SizedBox(height: 10),
              DlgField(
                label: 'Цель',
                ctrl: _goalCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
                min: 2,
              ),
              const SizedBox(height: 14),

              // ── Icon grid (scrollable, 2 rows visible) ──────────────────────────
              Row(
                children: [
                  SubLbl('Иконка', sub),
                  const Spacer(),
                  Text(
                    '${_allIcons.length} иконок · прокрутите',
                    style: TextStyle(color: sub, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: _gridHeight,
                decoration: BoxDecoration(
                  color: fBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: bdr),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(_spacing),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    mainAxisSpacing: _spacing,
                    crossAxisSpacing: _spacing,
                    childAspectRatio: 1,
                  ),
                  itemCount: _allIcons.length,
                  itemBuilder: (_, i) {
                    final ic = _allIcons[i];
                    final sel = ic == _icon;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = ic),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          color: sel
                              ? _color.withAlpha(50)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: sel
                              ? Border.all(color: _color, width: 2)
                              : null,
                        ),
                        child: Icon(ic, size: 18, color: sel ? _color : sub),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ── Color picker ────────────────────────────────────────────────────
              SubLbl('Цвет', sub),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kColors.map((c) {
                  final sel = c == _color;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: sel
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: c.withAlpha(130),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // ── Checklist ────────────────────────────────────────────────────────
              SubLbl('Чек-лист', sub),
              const SizedBox(height: 8),
              ..._items.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_box_outline_blank, size: 15, color: sub),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(color: txt, fontSize: 13),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _items.removeAt(e.key)),
                        child: const Icon(
                          Icons.close,
                          size: 15,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _checkCtrl,
                      style: TextStyle(color: txt, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '+ Добавить пункт',
                        hintStyle: TextStyle(color: sub, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addItem,
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF4A9EFF),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              DlgActions(onCancel: () => Navigator.pop(context), onSave: _save),
            ],
          ),
        ),
      ),
    );
  }

  void _addItem() {
    final t = _checkCtrl.text.trim();
    if (t.isNotEmpty) {
      setState(() {
        _items.add(t);
        _checkCtrl.clear();
      });
    }
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    widget.onSave(_nameCtrl.text.trim(), _goalCtrl.text, _items, _color, _icon);
    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SKILL TREE DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class SkillTreeDialog extends StatefulWidget {
  final AppState state;
  final Skill skill;

  const SkillTreeDialog({super.key, required this.state, required this.skill});

  @override
  State<SkillTreeDialog> createState() => _SkillTreeDialogState();
}

class _SkillTreeDialogState extends State<SkillTreeDialog> {
  Skill get _skill =>
      widget.state.skills
          .where((item) => item.id == widget.skill.id)
          .firstOrNull ??
      widget.skill;

  @override
  Widget build(BuildContext context) {
    final skill = _skill;
    final isDark = widget.state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 560,
        height: 640,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.account_tree, color: skill.color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Дерево: ${skill.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: txt,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SmallBtn(
                    label: 'Узел',
                    icon: Icons.add,
                    color: skill.color,
                    onTap: () => _showAddNode(context, skill),
                  ),
                  const SizedBox(width: 10),
                  PressFeedback(
                    scale: 0.85,
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _SkillTreeSummary(skill: skill, isDark: isDark),
            ),
            Expanded(
              child: skill.treeNodes.isEmpty
                  ? _SkillTreeEmptyState(
                      isDark: isDark,
                      color: skill.color,
                      onAdd: () => _showAddNode(context, skill),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      itemCount: skill.treeNodes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final node = skill.treeNodes[index];
                        return _SkillTreeNodeCard(
                          skill: skill,
                          node: node,
                          state: widget.state,
                          isDark: isDark,
                          onChanged: () => setState(() {}),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNode(BuildContext context, Skill skill) {
    showDialog(
      context: context,
      builder: (_) => _AddSkillTreeNodeDialog(
        isDark: widget.state.isDark,
        skill: skill,
        onSave: (title, description, xpReward, prerequisiteId, checklist) {
          widget.state.addSkillTreeNode(
            skill.id,
            SkillTreeNode(
              id: uid(),
              title: title,
              description: description,
              xpReward: xpReward,
              prerequisiteIds: prerequisiteId == null ? [] : [prerequisiteId],
              checklist: checklist,
            ),
          );
          setState(() {});
        },
      ),
    );
  }
}

class _SkillTreeSummary extends StatelessWidget {
  final Skill skill;
  final bool isDark;

  const _SkillTreeSummary({required this.skill, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skill.color.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: skill.color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(skill.icon, color: skill.color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${skill.masteredTreeNodeCount}/${skill.treeNodes.length} узлов освоено',
                  style: TextStyle(
                    color: txt,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              TaskBadge(
                icon: Icons.lock_open,
                label: '${skill.activeTreeNodeCount} активно',
                color: skill.color,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: XPBar(
                  progress: skill.treeProgress,
                  color: skill.color,
                  height: 7,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(skill.treeProgress * 100).round()}%',
                style: TextStyle(color: sub, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillTreeNodeCard extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final SkillTreeNode node;
  final bool isDark;
  final VoidCallback onChanged;

  const _SkillTreeNodeCard({
    required this.state,
    required this.skill,
    required this.node,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final status = skill.treeNodeStatus(node);
    final statusColor = skillTreeNodeStatusColor[status]!;
    final canMaster = state.canMasterSkillTreeNode(skill.id, node.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(
          status == SkillTreeNodeStatus.locked ? 8 : 14,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_statusIcon(status), color: statusColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.title,
                      style: TextStyle(
                        color: txt,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (node.description.trim().isNotEmpty)
                      Text(
                        node.description,
                        style: TextStyle(color: sub, fontSize: 11.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              TaskBadge(
                label: skillTreeNodeStatusLabel[status]!,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  state.removeSkillTreeNode(skill.id, node.id);
                  onChanged();
                },
                child: Icon(Icons.delete_outline, color: sub, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TaskBadge(
                icon: Icons.auto_awesome,
                label: '+${node.xpReward} XP',
                color: const Color(0xFFFFCC00),
              ),
              if (node.prerequisiteIds.isNotEmpty)
                TaskBadge(
                  icon: Icons.lock,
                  label: _prereqLabel(skill, node),
                  color: const Color(0xFF8E8E93),
                ),
              if (node.checklist.isNotEmpty)
                TaskBadge(
                  icon: Icons.checklist,
                  label:
                      '${node.checklistCompletedCount}/${node.checklist.length}',
                  color: skill.color,
                ),
            ],
          ),
          if (node.checklist.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...node.checklist.asMap().entries.map((entry) {
              final index = entry.key;
              final done = node.checklistDone[index];
              return GestureDetector(
                onTap: node.isMastered
                    ? null
                    : () {
                        state.toggleSkillTreeNodeChecklist(
                          skill.id,
                          node.id,
                          index,
                        );
                        onChanged();
                      },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Icon(
                        done ? Icons.check_box : Icons.check_box_outline_blank,
                        color: done ? skill.color : sub,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: done ? txt : sub,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: XPBar(
                  progress: node.isMastered ? 1.0 : node.progress,
                  color: statusColor,
                  height: 6,
                ),
              ),
              const SizedBox(width: 10),
              _MasterNodeButton(
                enabled: canMaster,
                mastered: node.isMastered,
                color: skill.color,
                onTap: () {
                  final message = state.masterSkillTreeNode(skill.id, node.id);
                  if (message != null) {
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(
                        content: Text(message),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(SkillTreeNodeStatus status) {
    return switch (status) {
      SkillTreeNodeStatus.locked => Icons.lock,
      SkillTreeNodeStatus.active => Icons.play_arrow_rounded,
      SkillTreeNodeStatus.mastered => Icons.workspace_premium,
    };
  }

  String _prereqLabel(Skill skill, SkillTreeNode node) {
    final names = node.prerequisiteIds
        .map(
          (id) => skill.treeNodes
              .where((candidate) => candidate.id == id)
              .firstOrNull,
        )
        .whereType<SkillTreeNode>()
        .map((item) => item.title)
        .toList();
    if (names.isEmpty) return 'Есть условие';
    if (names.length == 1) return names.first;
    return '${names.length} условий';
  }
}

class _MasterNodeButton extends StatelessWidget {
  final bool enabled;
  final bool mastered;
  final Color color;
  final VoidCallback onTap;

  const _MasterNodeButton({
    required this.enabled,
    required this.mastered,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mastered) {
      return TaskBadge(
        icon: Icons.check_circle,
        label: 'Готово',
        color: const Color(0xFF34C759),
      );
    }

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                'Освоить',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillTreeEmptyState extends StatelessWidget {
  final bool isDark;
  final Color color;
  final VoidCallback onAdd;

  const _SkillTreeEmptyState({
    required this.isDark,
    required this.color,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined, color: sub, size: 42),
          const SizedBox(height: 12),
          Text(
            'Дерево пока пустое',
            style: TextStyle(color: sub, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Добавьте первый узел мастерства.',
            style: TextStyle(color: sub.withAlpha(170), fontSize: 12),
          ),
          const SizedBox(height: 14),
          SmallBtn(
            label: 'Добавить узел',
            icon: Icons.add,
            color: color,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _AddSkillTreeNodeDialog extends StatefulWidget {
  final bool isDark;
  final Skill skill;
  final Function(
    String title,
    String description,
    int xpReward,
    String? prerequisiteId,
    List<String> checklist,
  )
  onSave;

  const _AddSkillTreeNodeDialog({
    required this.isDark,
    required this.skill,
    required this.onSave,
  });

  @override
  State<_AddSkillTreeNodeDialog> createState() =>
      _AddSkillTreeNodeDialogState();
}

class _AddSkillTreeNodeDialogState extends State<_AddSkillTreeNodeDialog> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _checkCtrl = TextEditingController();
  final List<String> _checklist = [];
  String? _prerequisiteId;
  int _xpReward = 30;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = surface(isDark);
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final color = widget.skill.color;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DlgHeader(title: 'Новый узел дерева', txtColor: txt),
              const SizedBox(height: 16),
              DlgField(
                label: 'Название узла',
                ctrl: _titleCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
              ),
              const SizedBox(height: 12),
              DlgField(
                label: 'Описание',
                ctrl: _descriptionCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
                min: 2,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SubLbl('Награда', sub),
                  const Spacer(),
                  TaskBadge(
                    icon: Icons.auto_awesome,
                    label: '$_xpReward XP',
                    color: color,
                  ),
                ],
              ),
              Slider(
                value: _xpReward.toDouble(),
                min: 10,
                max: 200,
                divisions: 19,
                activeColor: color,
                inactiveColor: color.withAlpha(40),
                onChanged: (value) => setState(() => _xpReward = value.round()),
              ),
              SubLbl('Требует узел', sub),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: fBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: bdr),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _prerequisiteId,
                    isExpanded: true,
                    dropdownColor: surface(isDark),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Без условия',
                          style: TextStyle(color: sub, fontSize: 13),
                        ),
                      ),
                      ...widget.skill.treeNodes.map(
                        (node) => DropdownMenuItem<String?>(
                          value: node.id,
                          child: Text(
                            node.title,
                            style: TextStyle(color: txt, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _prerequisiteId = value),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SubLbl('Чеклист узла', sub),
              const SizedBox(height: 8),
              ..._checklist.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_box_outline_blank, color: sub, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(color: txt, fontSize: 13),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _checklist.removeAt(entry.key)),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFFFF3B30),
                          size: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _checkCtrl,
                      style: TextStyle(color: txt, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '+ Добавить пункт',
                        hintStyle: TextStyle(color: sub, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _addChecklistItem(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addChecklistItem,
                    child: Icon(
                      Icons.add_circle_outline,
                      color: color,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DlgActions(onCancel: () => Navigator.pop(context), onSave: _save),
            ],
          ),
        ),
      ),
    );
  }

  void _addChecklistItem() {
    final value = _checkCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _checklist.add(value);
      _checkCtrl.clear();
    });
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onSave(
      title,
      _descriptionCtrl.text.trim(),
      _xpReward,
      _prerequisiteId,
      List.of(_checklist),
    );
    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADD TASK DIALOG  (unchanged from uploaded version)
// ═══════════════════════════════════════════════════════════════════════════════

class AddTaskDialog extends StatefulWidget {
  final bool isDark;
  final Color skillColor;
  final Task? existing;
  final Function(
    String title,
    int xp,
    TaskType type,
    RepeatFrequency freq,
    int customDays,
    Priority priority,
    String minimumAction,
    List<String> subtasks,
    List<String> tags,
    bool notificationsEnabled,
    int? notificationHour,
    int? notificationMinute,
  )
  onSave;
  const AddTaskDialog({
    super.key,
    required this.isDark,
    required this.skillColor,
    this.existing,
    required this.onSave,
  });
  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleCtrl = TextEditingController();
  final _minimumActionCtrl = TextEditingController();
  final _customCtrl = TextEditingController(text: '1');
  final _subtaskCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  int _xp = 20;
  TaskType _type = TaskType.shortTerm;
  RepeatFrequency _freq = RepeatFrequency.daily;
  Priority _priority = Priority.medium;
  final List<String> _subtasks = [];
  final List<String> _tags = [];
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);

  int get _softCap => typeSoftCap[_type]!;
  bool get _overCap => _xp > _softCap;
  bool get _hasMinimumAction => _minimumActionCtrl.text.trim().isNotEmpty;
  bool get _looksBigTask =>
      _type == TaskType.midTerm ||
      _type == TaskType.longTerm ||
      _xp >= 80 ||
      _titleCtrl.text.trim().length >= 28;
  bool get _hasSpecificTitle {
    final title = _titleCtrl.text.trim();
    if (title.length < 8) return false;
    final words = title.split(RegExp(r'\s+'));
    if (words.length < 2) return false;
    final generic = {
      'сделать',
      'улучшить',
      'заняться',
      'поработать',
      'прокачать',
    };
    return !generic.contains(title.toLowerCase());
  }

  String get _qualityStatus {
    if (_looksBigTask && !_hasMinimumAction && _subtasks.isEmpty) {
      return 'Сложно начать';
    }
    if (_looksBigTask && (!_hasMinimumAction || _subtasks.isEmpty)) {
      return 'Лучше разбить';
    }
    if (!_hasSpecificTitle) return 'Уточни действие';
    return 'Хорошая задача';
  }

  void _refreshDraft() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.existing case final ex?) {
      _titleCtrl.text = ex.title;
      _minimumActionCtrl.text = ex.minimumAction;
      _xp = ex.xpReward;
      _type = ex.type;
      _freq = ex.repeatFrequency;
      _customCtrl.text = '${ex.repeatCustomDays < 1 ? 1 : ex.repeatCustomDays}';
      _priority = ex.priority;
      _subtasks.addAll(ex.subtasks);
      _tags.addAll(ex.tags);
      _notificationsEnabled = ex.notificationsEnabled;
      if (ex.notificationHour != null && ex.notificationMinute != null) {
        _notificationTime = TimeOfDay(
          hour: ex.notificationHour!,
          minute: ex.notificationMinute!,
        );
      }
    }
    _titleCtrl.addListener(_refreshDraft);
    _minimumActionCtrl.addListener(_refreshDraft);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _minimumActionCtrl.dispose();
    _customCtrl.dispose();
    _subtaskCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = surface(isDark);
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final c = widget.skillColor;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DlgHeader(
                title: widget.existing != null
                    ? 'Редактировать задачу'
                    : 'Новая задача',
                txtColor: txt,
              ),
              const SizedBox(height: 16),
              DlgField(
                label: 'Название задачи',
                ctrl: _titleCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
              ),
              const SizedBox(height: 16),
              DlgField(
                label: 'Минимальное действие',
                ctrl: _minimumActionCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
                min: 2,
              ),
              const SizedBox(height: 6),
              Text(
                'Например: открыть проект и сделать первый endpoint.',
                style: TextStyle(color: sub, fontSize: 11),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SubLbl('Награда XP', sub),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_xp XP',
                      style: TextStyle(
                        color: c,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _xp.toDouble(),
                min: 5,
                max: 1000,
                divisions: 199,
                activeColor: c,
                inactiveColor: c.withAlpha(40),
                onChanged: (v) => setState(() => _xp = v.round()),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _overCap
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9500).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF9500).withAlpha(80),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFFF9500),
                              size: 15,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'Не рекомендуется: лимит для «${typeLabel[_type]}» — $_softCap XP.',
                                style: const TextStyle(
                                  color: Color(0xFFFF9500),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              SubLbl('Тип задачи', sub),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskType.values.map((t) {
                  final sel = _type == t;
                  final tc = typeColor[t]!;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? tc.withAlpha(40) : fBg,
                        borderRadius: BorderRadius.circular(8),
                        border: sel
                            ? Border.all(color: tc)
                            : Border.all(color: bdr),
                      ),
                      child: Text(
                        typeLabel[t]!,
                        style: TextStyle(
                          color: sel ? tc : sub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SubLbl('Приоритет', sub),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Priority.values.map((priority) {
                  final sel = _priority == priority;
                  final pc = priorityColor[priority]!;
                  return GestureDetector(
                    onTap: () => setState(() => _priority = priority),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? pc.withAlpha(38) : fBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sel ? pc : bdr),
                      ),
                      child: Text(
                        priorityLabel[priority]!,
                        style: TextStyle(
                          color: sel ? pc : sub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_type == TaskType.repeating) ...[
                const SizedBox(height: 16),
                SubLbl('Частота выполнения', sub),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: fBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: bdr),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: RepeatFrequency.values.map((f) {
                          final sel = _freq == f;
                          return GestureDetector(
                            onTap: () => setState(() => _freq = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? const Color(0xFF4A9EFF).withAlpha(40)
                                    : (isDark
                                          ? const Color(0xFF2A2A35)
                                          : const Color(0xFFEAEAF0)),
                                borderRadius: BorderRadius.circular(20),
                                border: sel
                                    ? Border.all(color: const Color(0xFF4A9EFF))
                                    : null,
                              ),
                              child: Text(
                                freqLabel[f]!,
                                style: TextStyle(
                                  color: sel ? const Color(0xFF4A9EFF) : sub,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_freq == RepeatFrequency.custom) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Каждые',
                              style: TextStyle(color: txt, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: _customCtrl,
                                style: TextStyle(color: txt, fontSize: 13),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: bdr),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF4A9EFF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'дней',
                              style: TextStyle(color: txt, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Задача обновится в 03:00 через ${freqDays(_freq, _customDays)} дн.',
                        style: TextStyle(color: sub, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildTextListEditor(
                title: 'Подзадачи',
                hint: '+ Добавить подзадачу',
                items: _subtasks,
                ctrl: _subtaskCtrl,
                color: c,
                txt: txt,
                sub: sub,
              ),
              const SizedBox(height: 16),
              _buildQualityCheck(fBg, txt, sub, bdr, c),
              const SizedBox(height: 16),
              _buildTextListEditor(
                title: 'Теги',
                hint: '+ Добавить тег',
                items: _tags,
                ctrl: _tagCtrl,
                color: c,
                txt: txt,
                sub: sub,
                prefix: '#',
              ),
              const SizedBox(height: 16),
              _buildNotificationSection(fBg, txt, sub, bdr, c),
              const SizedBox(height: 22),
              DlgActions(onCancel: () => Navigator.pop(context), onSave: _save),
            ],
          ),
        ),
      ),
    );
  }

  int get _customDays {
    final parsed = int.tryParse(_customCtrl.text.trim()) ?? 1;
    return parsed < 1 ? 1 : parsed;
  }

  Widget _buildTextListEditor({
    required String title,
    required String hint,
    required List<String> items,
    required TextEditingController ctrl,
    required Color color,
    required Color txt,
    required Color sub,
    String prefix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubLbl(title, sub),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.asMap().entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$prefix${entry.value}',
                      style: TextStyle(color: txt, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => items.removeAt(entry.key)),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFFFF3B30),
                        size: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (items.isNotEmpty) const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                style: TextStyle(color: txt, fontSize: 13),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: sub, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _addListItem(items, ctrl),
              ),
            ),
            GestureDetector(
              onTap: () => _addListItem(items, ctrl),
              child: Icon(Icons.add_circle_outline, color: color, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQualityCheck(
    Color fBg,
    Color txt,
    Color sub,
    Color bdr,
    Color color,
  ) {
    final qualityColor = switch (_qualityStatus) {
      'Хорошая задача' => const Color(0xFF34C759),
      'Уточни действие' => const Color(0xFFFFCC00),
      _ => const Color(0xFFFF9500),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rule_folder_outlined, color: qualityColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Качество задачи',
                  style: TextStyle(
                    color: txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: qualityColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: qualityColor.withAlpha(70)),
                ),
                child: Text(
                  _qualityStatus,
                  style: TextStyle(
                    color: qualityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _qualityRow(
            ok: _hasSpecificTitle,
            okLabel: 'Есть понятное действие',
            warnLabel: 'Название слишком общее',
            txt: txt,
            sub: sub,
          ),
          const SizedBox(height: 6),
          _qualityRow(
            ok: _hasMinimumAction,
            okLabel: 'Есть минимальный старт',
            warnLabel: 'Добавь лёгкий старт',
            txt: txt,
            sub: sub,
          ),
          const SizedBox(height: 6),
          _qualityRow(
            ok: _xp > 0,
            okLabel: 'Есть XP-награда',
            warnLabel: 'Нужна XP-награда',
            txt: txt,
            sub: sub,
          ),
          const SizedBox(height: 6),
          _qualityRow(
            ok: !_looksBigTask || _subtasks.isNotEmpty,
            okLabel: 'Структура уже разбита на шаги',
            warnLabel: 'Для большой задачи лучше добавить 2–3 шага',
            txt: txt,
            sub: sub,
          ),
          if (_looksBigTask && (!_hasMinimumAction || _subtasks.isEmpty)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha(16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withAlpha(48)),
              ),
              child: Text(
                'Эта задача выглядит большой. Разбей её на 2–3 шага, чтобы легче начать.',
                style: TextStyle(color: txt, fontSize: 11.5, height: 1.25),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _qualityRow({
    required bool ok,
    required String okLabel,
    required String warnLabel,
    required Color txt,
    required Color sub,
  }) {
    final rowColor = ok ? const Color(0xFF34C759) : const Color(0xFFFF9500);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.error_outline,
          color: rowColor,
          size: 15,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ok ? okLabel : warnLabel,
            style: TextStyle(
              color: ok ? txt : sub,
              fontSize: 11.5,
              fontWeight: ok ? FontWeight.w500 : FontWeight.w400,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(
    Color fBg,
    Color txt,
    Color sub,
    Color bdr,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bdr),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: sub, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Напоминание',
                  style: TextStyle(
                    color: txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                activeThumbColor: color,
                onChanged: (value) => setState(() {
                  _notificationsEnabled = value;
                }),
              ),
            ],
          ),
          if (_notificationsEnabled) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickNotificationTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withAlpha(70)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: color, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Время: ${_formatTimeOfDay(_notificationTime)}',
                      style: TextStyle(color: color, fontSize: 13),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_outlined, color: color, size: 15),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addListItem(List<String> items, TextEditingController ctrl) {
    final value = ctrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      items.add(value.replaceAll(RegExp(r'^#+'), ''));
      ctrl.clear();
    });
  }

  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _notificationTime = picked);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    widget.onSave(
      _titleCtrl.text.trim(),
      _xp,
      _type,
      _freq,
      _customDays,
      _priority,
      _minimumActionCtrl.text.trim(),
      List.of(_subtasks),
      List.of(_tags),
      _notificationsEnabled,
      _notificationsEnabled ? _notificationTime.hour : null,
      _notificationsEnabled ? _notificationTime.minute : null,
    );
    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATISTICS DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

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
        width: 480,
        height: 580,
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
                    'Статистика',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.85,
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
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Выполнено задач',
                            value: '${state.totalTasksCompleted}',
                            icon: Icons.check_circle,
                            color: const Color(0xFF34C759),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Лучший стрик',
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
                            title: 'Ранг профиля',
                            value: profileRankForLevel(
                              state.profile.level,
                            ).label,
                            icon: Icons.trending_up,
                            color: profileRankForLevel(
                              state.profile.level,
                            ).color,
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

  Widget _buildSkillStats(AppState s, bool isDark, Color txt, Color sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'По навыкам',
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
          final skillRank = skillRankForLevel(sk.level);
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
                        '${sk.name} • ${skillRank.label}',
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
                label: 'Задач',
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
              Text(title, style: TextStyle(color: sub, fontSize: 11)),
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

class RewardsDialog extends StatefulWidget {
  final AppState state;
  const RewardsDialog({super.key, required this.state});

  @override
  State<RewardsDialog> createState() => _RewardsDialogState();
}

class _RewardsDialogState extends State<RewardsDialog> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final unopened = widget.state.unopenedRewardChests;
    final buffs = widget.state.activeBuffs;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        height: 620,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.redeem, color: Color(0xFFFFCC00), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Награды и баффы',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.85,
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Неоткрыто',
                            value: '${unopened.length}',
                            icon: Icons.inventory_2,
                            color: const Color(0xFFFFCC00),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Активные баффы',
                            value: '${buffs.length}',
                            icon: Icons.bolt,
                            color: const Color(0xFF34C759),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Сундуки открываются за боевые рывки: сейчас это 5 квестов за день и победы над боссами.',
                      style: TextStyle(color: sub, fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Сундуки',
                      style: TextStyle(
                        color: txt,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (unopened.isEmpty)
                      _RewardsEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Пока нет сундуков',
                        subtitle:
                            'Сделай 5 квестов за день или победи босса, чтобы получить награду.',
                        isDark: isDark,
                      )
                    else
                      ...unopened.map(
                        (chest) => _RewardChestCard(
                          chest: chest,
                          skill: chest.skillId == null
                              ? null
                              : widget.state.skills
                                    .where((skill) => skill.id == chest.skillId)
                                    .firstOrNull,
                          isDark: isDark,
                          onOpen: () => _openChest(context, chest.id),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Text(
                      'Активные баффы',
                      style: TextStyle(
                        color: txt,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (buffs.isEmpty)
                      _RewardsEmptyState(
                        icon: Icons.bolt_outlined,
                        title: 'Нет активных баффов',
                        subtitle:
                            'Открой сундук, чтобы получить временное усиление на XP.',
                        isDark: isDark,
                      )
                    else
                      ...buffs.map(
                        (buff) => _ActiveBuffCard(
                          buff: buff,
                          skill: buff.skillId == null
                              ? null
                              : widget.state.skills
                                    .where((skill) => skill.id == buff.skillId)
                                    .firstOrNull,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChest(BuildContext context, String chestId) {
    final message = widget.state.openRewardChest(chestId);
    if (message == null) return;
    setState(() {});
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

class _RewardChestCard extends StatelessWidget {
  final RewardChest chest;
  final Skill? skill;
  final bool isDark;
  final VoidCallback onOpen;

  const _RewardChestCard({
    required this.chest,
    required this.skill,
    required this.isDark,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final rarityColor = rewardRarityColor[chest.rarity]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: rarityColor.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rarityColor.withAlpha(55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: rarityColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2, color: rarityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chest.title,
                        style: TextStyle(
                          color: txt,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TaskBadge(
                      label: rewardRarityLabel[chest.rarity]!,
                      color: rarityColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  chest.description,
                  style: TextStyle(color: sub, fontSize: 11.5, height: 1.3),
                ),
                if (skill != null) ...[
                  const SizedBox(height: 6),
                  TaskBadge(
                    icon: skill!.icon,
                    label: skill!.name,
                    color: skill!.color,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          SmallBtn(
            label: 'Открыть',
            icon: Icons.auto_awesome,
            color: rarityColor,
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

class _ActiveBuffCard extends StatelessWidget {
  final Buff buff;
  final Skill? skill;
  final bool isDark;

  const _ActiveBuffCard({
    required this.buff,
    required this.skill,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = skill?.color ?? const Color(0xFF34C759);
    final expiresAt = buff.expiresAt;
    final expiryLabel = expiresAt == null
        ? null
        : 'до ${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withAlpha(24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bolt, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buff.title,
                      style: TextStyle(
                        color: txt,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      buff.description,
                      style: TextStyle(color: sub, fontSize: 11),
                    ),
                  ],
                ),
              ),
              TaskBadge(
                icon: Icons.auto_awesome,
                label: '+${buff.bonusPercent}%',
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TaskBadge(
                icon: Icons.flash_on,
                label: '${buff.charges} заряд',
                color: accent,
              ),
              TaskBadge(
                icon: Icons.tune,
                label: buffTypeLabel[buff.type]!,
                color: const Color(0xFF4A9EFF),
              ),
              if (expiryLabel != null)
                TaskBadge(
                  icon: Icons.schedule,
                  label: expiryLabel,
                  color: const Color(0xFFFF9500),
                ),
              if (skill != null)
                TaskBadge(
                  icon: skill!.icon,
                  label: skill!.name,
                  color: skill!.color,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _RewardsEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Column(
        children: [
          Icon(icon, color: sub, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: sub,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: sub.withAlpha(170), fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOSSES DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class BossesDialog extends StatefulWidget {
  final AppState state;
  const BossesDialog({super.key, required this.state});

  @override
  State<BossesDialog> createState() => _BossesDialogState();
}

class _BossesDialogState extends State<BossesDialog> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Color(0xFFFF2D55), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Боссы',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.85,
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),

            // Collapsible Explanation
            if (!_expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: sub, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Что такое боссы?',
                        style: TextStyle(color: sub, fontSize: 12),
                      ),
                      const Spacer(),
                      Icon(Icons.expand_more, color: sub, size: 18),
                    ],
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: fBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF2D55).withAlpha(50),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shield,
                          color: Color(0xFFFF2D55),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Что такое боссы?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: txt,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _expanded = false),
                          child: Icon(Icons.expand_less, color: sub, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Босс — это плохая привычка или негативная черта. Теперь он слабеет не только от стрика, но и от high-priority задач, лёгких стартов и общего прогресса по навыку.',
                      style: TextStyle(color: sub, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTip(Icons.local_fire_department, 'Стрик', sub),
                        const SizedBox(width: 16),
                        _buildTip(Icons.flag, 'Фокус', sub),
                        const SizedBox(width: 16),
                        _buildTip(Icons.play_circle_fill, 'Старт', sub),
                      ],
                    ),
                  ],
                ),
              ),

            Container(height: 1, color: bdr),
            Expanded(
              child: widget.state.bosses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, color: sub, size: 38),
                          const SizedBox(height: 12),
                          Text(
                            'Нет активных боссов',
                            style: TextStyle(color: sub, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Создайте босса для навыка',
                            style: TextStyle(
                              color: sub.withAlpha(160),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: widget.state.bosses.length,
                      itemBuilder: (_, i) => _BossCard(
                        boss: widget.state.bosses[i],
                        snapshot: widget.state.bossSnapshot(
                          widget.state.bosses[i],
                        ),
                        skills: widget.state.skills,
                        isDark: isDark,
                        onDelete: () {
                          widget.state.removeBoss(widget.state.bosses[i].id);
                          Navigator.pop(context);
                        },
                      ),
                    ),
            ),
            Container(height: 1, color: bdr),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: HoverScale(
                      child: SmallBtn(
                        label: 'Добавить босса',
                        icon: Icons.add,
                        color: const Color(0xFFFF2D55),
                        onTap: () => _showAddBoss(context, widget.state),
                      ),
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

  Widget _buildTip(IconData icon, String label, Color sub) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFF2D55), size: 12),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: sub, fontSize: 10)),
      ],
    );
  }

  void _showAddBoss(BuildContext ctx, AppState s) {
    showDialog(
      context: ctx,
      builder: (context) => _AddBossDialog(
        isDark: s.isDark,
        skills: s.skills
            .where(
              (sk) => !s.bosses.any(
                (boss) => boss.skillId == sk.id && !boss.isDefeated,
              ),
            )
            .toList(),
        onSave: (title, skillId, targetStreak) => s.addBoss(
          Boss(
            id: uid(),
            title: title,
            skillId: skillId,
            targetStreak: targetStreak,
            maxHp: 100,
            hp: 100,
          ),
        ),
      ),
    );
  }
}

class _BossCard extends StatelessWidget {
  final Boss boss;
  final BossSnapshot snapshot;
  final List<Skill> skills;
  final bool isDark;
  final VoidCallback onDelete;
  const _BossCard({
    required this.boss,
    required this.snapshot,
    required this.skills,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final skill = skills.where((s) => s.id == boss.skillId).firstOrNull;
    final c = skill?.color ?? const Color(0xFFFF2D55);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: boss.isDefeated
            ? const Color(0xFF34C759).withAlpha(15)
            : c.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: boss.isDefeated
              ? const Color(0xFF34C759).withAlpha(60)
              : c.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: boss.isDefeated
                      ? const Color(0xFF34C759).withAlpha(30)
                      : c.withAlpha(30),
                ),
                child: Icon(
                  boss.isDefeated ? Icons.check : Icons.shield,
                  color: boss.isDefeated ? const Color(0xFF34C759) : c,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boss.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: txt,
                        fontSize: 14,
                      ),
                    ),
                    if (skill != null)
                      Text(
                        'Навык: ${skill.name}',
                        style: TextStyle(color: sub, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (!boss.isDefeated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: snapshot.isUnderAttack
                        ? const Color(0xFFFF3B30).withAlpha(25)
                        : c.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    snapshot.phaseLabel,
                    style: TextStyle(
                      color: snapshot.isUnderAttack
                          ? const Color(0xFFFF3B30)
                          : c,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Побеждён',
                    style: TextStyle(
                      color: Color(0xFF34C759),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline, color: sub, size: 18),
              ),
            ],
          ),
          if (!boss.isDefeated) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: boss.hpPercent,
                      minHeight: 8,
                      backgroundColor: c.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation(c),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${boss.hp} HP  •  ${snapshot.impactPercent}%',
                  style: TextStyle(
                    color: c,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _BossMetricChip(
                  label: 'Стрик',
                  value: '${snapshot.currentStreak}/${snapshot.targetStreak}',
                  color: const Color(0xFFFF9500),
                ),
                _BossMetricChip(
                  label: 'Фокус',
                  value: '${snapshot.priorityPercent}%',
                  color: const Color(0xFFFF2D55),
                ),
                _BossMetricChip(
                  label: 'Старт',
                  value: '${snapshot.startPercent}%',
                  color: const Color(0xFF4A9EFF),
                ),
                if (snapshot.totalTreeNodes > 0)
                  _BossMetricChip(
                    label: 'Дерево',
                    value:
                        '${snapshot.masteredTreeNodes}/${snapshot.totalTreeNodes}',
                    color: const Color(0xFF34C759),
                  ),
                if (snapshot.stalledHighPriorityTasks > 0)
                  _BossMetricChip(
                    label: 'Риск',
                    value: '${snapshot.stalledHighPriorityTasks} high',
                    color: const Color(0xFFFF3B30),
                  ),
                if (snapshot.urgentRepeatingTasks > 0)
                  _BossMetricChip(
                    label: 'Срок',
                    value: '${snapshot.urgentRepeatingTasks} daily',
                    color: const Color(0xFFFF3B30),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              snapshot.recommendation,
              style: TextStyle(color: sub, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _BossMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BossMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AddBossDialog extends StatefulWidget {
  final bool isDark;
  final List<Skill> skills;
  final Function(String title, String skillId, int targetStreak) onSave;
  const _AddBossDialog({
    required this.isDark,
    required this.skills,
    required this.onSave,
  });
  @override
  State<_AddBossDialog> createState() => _AddBossDialogState();
}

class _AddBossDialogState extends State<_AddBossDialog> {
  final _titleCtrl = TextEditingController();
  String? _skillId;
  int _streak = 7;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = surface(isDark);
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DlgHeader(title: 'Новый босс', txtColor: txt),
              const SizedBox(height: 16),
              DlgField(
                label: 'Название босса',
                ctrl: _titleCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
              ),
              const SizedBox(height: 14),
              SubLbl('Навык', sub),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: fBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: bdr),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _skillId,
                    hint: Text(
                      'Выберите навык',
                      style: TextStyle(color: sub, fontSize: 14),
                    ),
                    isExpanded: true,
                    dropdownColor: surface(isDark),
                    items: widget.skills
                        .map(
                          (sk) => DropdownMenuItem(
                            value: sk.id,
                            child: Row(
                              children: [
                                Icon(sk.icon, color: sk.color, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  sk.name,
                                  style: TextStyle(color: txt, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _skillId = v),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SubLbl('Базовый порог стрика', sub),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2D55).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_streak дней',
                      style: const TextStyle(
                        color: Color(0xFFFF2D55),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _streak.toDouble(),
                min: 3,
                max: 30,
                divisions: 27,
                activeColor: const Color(0xFFFF2D55),
                inactiveColor: const Color(0xFFFF2D55).withAlpha(40),
                onChanged: (v) => setState(() => _streak = v.round()),
              ),
              Text(
                'Стрик остаётся главным рычагом, но босс также слабеет от high-priority задач, лёгких стартов и прогресса по навыку.',
                style: TextStyle(color: sub, fontSize: 11, height: 1.3),
              ),
              const SizedBox(height: 16),
              DlgActions(onCancel: () => Navigator.pop(context), onSave: _save),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty || _skillId == null) return;
    widget.onSave(_titleCtrl.text.trim(), _skillId!, _streak);
    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CALENDAR VIEW DIALOG
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
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: Color(0xFF4A9EFF),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Календарь',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.85,
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
            if (_selectedDate != null)
              _buildSelectedDateTasks(
                isDark,
                txt,
                sub,
                bdr,
                completionHistoryByDate,
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
          GestureDetector(
            onTap: () =>
                _selectMonth(_selectedMonth.year, _selectedMonth.month - 1),
            child: Icon(Icons.chevron_left, color: sub),
          ),
          Text(
            '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: txt,
              fontSize: 16,
            ),
          ),
          GestureDetector(
            onTap: () =>
                _selectMonth(_selectedMonth.year, _selectedMonth.month + 1),
            child: Icon(Icons.chevron_right, color: sub),
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
                  '${selectedEntries.length} выполн.',
                  style: TextStyle(color: sub, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedEntries.isEmpty
                ? Center(
                    child: Text(
                      'Нет выполненных задач',
                      style: TextStyle(color: sub, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: selectedEntries.length,
                    itemBuilder: (_, i) {
                      final entry = selectedEntries[i];
                      return Container(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.taskTitle,
                                    style: TextStyle(color: txt, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${entry.skillName} • ${formatTime(entry.at)}',
                                    style: TextStyle(color: sub, fontSize: 10),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
