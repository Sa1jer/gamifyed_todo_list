import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../engines/goal_engine.dart';
import '../feedback_service.dart';
import '../models.dart';
import '../utils.dart';
import '../app_state.dart';
import 'reward_animations.dart';
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
                    scale: 0.94,
                    tooltip: 'Закрыть достижения',
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
// HISTORY DIALOG
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Журнал XP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: txt,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Подробности закрытых квестов, XP и откатов.',
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
                    tooltip: 'Закрыть журнал',
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
                            'Журнал пока пуст',
                            style: TextStyle(color: sub, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Закрой первый квест — здесь появятся детали роста',
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
                    e.isCompletion ? 'Квест закрыт' : 'Откат квеста',
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
            e.isCompletion ? '+${e.xp} XP' : '-${e.xp} XP',
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

class _DialogChoiceChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool selected;
  final Color backgroundColor;
  final Color borderColor;
  final Color inactiveTextColor;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final FontWeight selectedWeight;

  const _DialogChoiceChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.backgroundColor,
    required this.borderColor,
    required this.inactiveTextColor,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    this.radius = 8,
    this.selectedWeight = FontWeight.w700,
  });

  @override
  State<_DialogChoiceChip> createState() => _DialogChoiceChipState();
}

class _DialogChoiceChipState extends State<_DialogChoiceChip> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final fillColor = selected
        ? widget.color.withAlpha(38)
        : (_hovered ? widget.color.withAlpha(16) : widget.backgroundColor);
    final outlineColor = selected
        ? widget.color.withAlpha(150)
        : (_hovered ? widget.color.withAlpha(70) : widget.borderColor);
    final labelColor = selected
        ? widget.color
        : (_hovered ? widget.color.withAlpha(220) : widget.inactiveTextColor);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: kMotionFast,
          curve: kMotionCurve,
          child: AnimatedContainer(
            duration: kMotionStandard,
            curve: kMotionCurve,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(color: outlineColor),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: selected ? widget.selectedWeight : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconChoiceButton extends StatefulWidget {
  final IconData icon;
  final bool selected;
  final Color color;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _IconChoiceButton({
    required this.icon,
    required this.selected,
    required this.color,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  State<_IconChoiceButton> createState() => _IconChoiceButtonState();
}

class _IconChoiceButtonState extends State<_IconChoiceButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final fillColor = selected
        ? widget.color.withAlpha(46)
        : (_hovered ? widget.color.withAlpha(14) : Colors.transparent);
    final outlineColor = selected
        ? widget.color.withAlpha(165)
        : (_hovered ? widget.color.withAlpha(60) : Colors.transparent);
    final iconColor = selected
        ? widget.color
        : (_hovered ? widget.color.withAlpha(220) : widget.inactiveColor);

    return Tooltip(
      message: 'Выбрать иконку',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: kMotionFast,
            curve: kMotionCurve,
            child: AnimatedContainer(
              duration: kMotionStandard,
              curve: kMotionCurve,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: outlineColor, width: 1.4),
              ),
              child: Icon(widget.icon, size: 18, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorChoiceButton extends StatefulWidget {
  final Color color;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ColorChoiceButton({
    required this.color,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ColorChoiceButton> createState() => _ColorChoiceButtonState();
}

class _ColorChoiceButtonState extends State<_ColorChoiceButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.selected
        ? (widget.isDark ? Colors.white : const Color(0xFF202033))
        : (_hovered ? widget.color.withAlpha(120) : Colors.transparent);
    final shadowAlpha = widget.selected ? 90 : (_hovered ? 45 : 0);

    return Tooltip(
      message: 'Выбрать цвет',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1,
            duration: kMotionFast,
            curve: kMotionCurve,
            child: AnimatedContainer(
              duration: kMotionStandard,
              curve: kMotionCurve,
              width: 28,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor,
                  width: widget.selected ? 2 : 1,
                ),
                boxShadow: shadowAlpha == 0
                    ? null
                    : [
                        BoxShadow(
                          color: widget.color.withAlpha(shadowAlpha),
                          blurRadius: widget.selected ? 10 : 7,
                        ),
                      ],
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADD SKILL DIALOG
// FIX 1.0.7: Replaced "Ещё иконки" toggle with a single scrollable grid
//            showing all icons at once (2 rows visible, scrollable vertically).
// ═══════════════════════════════════════════════════════════════════════════════

typedef SkillSaveCallback =
    void Function(
      String name,
      String goal,
      List<String> checklist,
      Color color,
      IconData icon,
      List<SkillTreeNode> initialTreeNodes,
      InitialSkillQuestDraft? initialQuest,
    );

class InitialSkillQuestDraft {
  final String title;
  final String minimumAction;
  final String? treeNodeId;

  const InitialSkillQuestDraft({
    required this.title,
    required this.minimumAction,
    required this.treeNodeId,
  });
}

class _FirstRunPathStep extends StatelessWidget {
  final String number;
  final String label;
  final Color color;

  const _FirstRunPathStep({
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(95)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$number.',
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class AddSkillDialog extends StatefulWidget {
  final bool isDark;
  final Skill? existing;
  final SkillSaveCallback onSave;
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
  final _firstStageCtrl = TextEditingController(text: 'Основа');
  final _firstQuestCtrl = TextEditingController();
  final _firstMinimumCtrl = TextEditingController();
  final List<String> _items = [];
  bool _criteriaExpanded = false;
  bool _showValidation = false;
  Color _color = const Color(0xFF4A9EFF);
  IconData _icon = Icons.fitness_center;
  static const _goalEngine = GoalEngine();

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
    _goalCtrl.addListener(_refreshGoalHints);
    if (widget.existing case final ex?) {
      _nameCtrl.text = ex.name;
      _goalCtrl.text = ex.goal;
      _items.addAll(ex.checklist);
      _criteriaExpanded = ex.checklist.isNotEmpty;
      _color = ex.color;
      _icon = ex.icon;
    }
  }

  @override
  void dispose() {
    _goalCtrl.removeListener(_refreshGoalHints);
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _checkCtrl.dispose();
    _firstStageCtrl.dispose();
    _firstQuestCtrl.dispose();
    _firstMinimumCtrl.dispose();
    super.dispose();
  }

  void _refreshGoalHints() {
    if (mounted) setState(() {});
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
              if (widget.existing == null) ...[
                _buildFirstRunPathIntro(fBg, txt, sub, bdr),
                const SizedBox(height: 14),
              ],
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
              const SizedBox(height: 8),
              _buildSmarterHint(fBg, txt, sub, bdr),
              if (widget.existing == null) ...[
                const SizedBox(height: 10),
                DlgField(
                  label: 'Первый этап',
                  ctrl: _firstStageCtrl,
                  fBg: fBg,
                  txt: txt,
                  sub: sub,
                  bdr: bdr,
                ),
                const SizedBox(height: 6),
                Text(
                  'Стартовая ступень мастерства. Квесты позже будут двигать этот этап.',
                  style: TextStyle(
                    color: sub,
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFirstActionSection(fBg, txt, sub, bdr),
              ],
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
                    return _IconChoiceButton(
                      icon: ic,
                      selected: sel,
                      color: _color,
                      inactiveColor: sub,
                      onTap: () => setState(() => _icon = ic),
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
                  return _ColorChoiceButton(
                    color: c,
                    selected: sel,
                    isDark: isDark,
                    onTap: () => setState(() => _color = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              _buildCriteriaSection(fBg, txt, sub, bdr),
              const SizedBox(height: 22),
              DlgActions(
                onCancel: () => Navigator.pop(context),
                onSave: _save,
                saveLabel: widget.existing == null ? 'Создать' : 'Сохранить',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmarterHint(Color fBg, Color txt, Color sub, Color bdr) {
    final goal = GoalSpec(text: _goalCtrl.text.trim());
    final readiness = _goalEngine.analyze(goal);
    final hints = readiness.topHints;
    final isEmpty = goal.text.isEmpty;
    final accent = readiness.isStrong ? const Color(0xFF34C759) : _color;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: fBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withAlpha(22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withAlpha(75)),
            ),
            child: Text(
              isEmpty ? 'S' : '${readiness.score}',
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmpty
                      ? 'SMARTER мягко подскажет, как сделать цель яснее.'
                      : readiness.isStrong
                      ? 'Цель звучит достаточно ясно.'
                      : 'SMARTER: ${readiness.score}/${readiness.total}',
                  style: TextStyle(
                    color: txt,
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isEmpty
                      ? 'Это не экзамен: подсказки не блокируют создание навыка.'
                      : hints.isEmpty
                      ? 'Дальше можно усилить её сроком, метрикой или review.'
                      : hints.join(' '),
                  style: TextStyle(
                    color: sub,
                    fontSize: 11.2,
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

  Widget _buildFirstRunPathIntro(Color fBg, Color txt, Color sub, Color bdr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FirstRunPathStep(number: '1', label: 'Навык', color: _color),
              Icon(Icons.chevron_right, color: sub, size: 17),
              _FirstRunPathStep(
                number: '2',
                label: 'Первый этап',
                color: _color,
              ),
              Icon(Icons.chevron_right, color: sub, size: 17),
              _FirstRunPathStep(
                number: '3',
                label: 'Первый квест',
                color: _color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте направление роста, стартовую ступень и действие, которое можно начать сегодня.',
            style: TextStyle(
              color: sub,
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstActionSection(Color fBg, Color txt, Color sub, Color bdr) {
    final warn =
        _showValidation &&
        (_firstQuestCtrl.text.trim().isEmpty ||
            _firstMinimumCtrl.text.trim().isEmpty);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: warn ? const Color(0xFFFF3B30).withAlpha(150) : bdr,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: _color, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Первое действие',
                  style: TextStyle(
                    color: txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Новый навык сразу получит квест-практику. Минимальный шаг — это то, что можно сделать сегодня.',
            style: TextStyle(
              color: sub,
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          DlgField(
            label: 'Первый квест',
            ctrl: _firstQuestCtrl,
            fBg: fBg,
            txt: txt,
            sub: sub,
            bdr: bdr,
          ),
          const SizedBox(height: 10),
          DlgField(
            label: 'Минимальный шаг',
            ctrl: _firstMinimumCtrl,
            fBg: fBg,
            txt: txt,
            sub: sub,
            bdr: bdr,
            min: 2,
          ),
          const SizedBox(height: 6),
          Text(
            'Например: открыть проект, сделать 5 минут, записать первый подход.',
            style: TextStyle(
              color: sub,
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (warn) ...[
            const SizedBox(height: 8),
            Text(
              'Заполни первый квест и минимальный шаг, чтобы навык не остался пустым.',
              style: TextStyle(
                color: const Color(0xFFFF3B30).withAlpha(220),
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCriteriaSection(Color fBg, Color txt, Color sub, Color bdr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _criteriaExpanded = !_criteriaExpanded),
            child: Row(
              children: [
                Icon(Icons.fact_check_outlined, color: _color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Критерии навыка',
                    style: TextStyle(
                      color: txt,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${_items.length}',
                  style: TextStyle(
                    color: sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _criteriaExpanded ? 0.5 : 0,
                  duration: kMotionStandard,
                  curve: kMotionCurve,
                  child: Icon(Icons.expand_more, color: sub, size: 17),
                ),
              ],
            ),
          ),
          MotionExpandable(
            expanded: _criteriaExpanded,
            expandedChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  if (_items.isEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Необязательно: критерии помогают описать, что значит “навык стал лучше”.',
                        style: TextStyle(
                          color: sub,
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ..._items.asMap().entries.map(
                    (e) => MotionListItem(
                      key: ValueKey('skill-criteria-${e.key}-${e.value}'),
                      index: e.key,
                      slide: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_box_outline_blank,
                              size: 15,
                              color: sub,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.value,
                                style: TextStyle(color: txt, fontSize: 13),
                              ),
                            ),
                            Tooltip(
                              message: 'Удалить критерий навыка',
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _items.removeAt(e.key)),
                                child: const Icon(
                                  Icons.close,
                                  size: 15,
                                  color: Color(0xFFFF3B30),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                            hintText: '+ Добавить критерий',
                            hintStyle: TextStyle(color: sub, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _addItem(),
                        ),
                      ),
                      Tooltip(
                        message: 'Добавить критерий навыка',
                        child: GestureDetector(
                          onTap: _addItem,
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFF4A9EFF),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
    final isNew = widget.existing == null;
    if (isNew &&
        (_firstQuestCtrl.text.trim().isEmpty ||
            _firstMinimumCtrl.text.trim().isEmpty)) {
      setState(() => _showValidation = true);
      return;
    }
    final initialTreeNodes = _initialTreeNodes();
    widget.onSave(
      _nameCtrl.text.trim(),
      _goalCtrl.text,
      _items,
      _color,
      _icon,
      initialTreeNodes,
      _initialQuest(initialTreeNodes),
    );
    Navigator.pop(context);
  }

  InitialSkillQuestDraft? _initialQuest(List<SkillTreeNode> initialTreeNodes) {
    if (widget.existing != null) return null;
    return InitialSkillQuestDraft(
      title: _firstQuestCtrl.text.trim(),
      minimumAction: _firstMinimumCtrl.text.trim(),
      treeNodeId: initialTreeNodes.firstOrNull?.id,
    );
  }

  List<SkillTreeNode> _initialTreeNodes() {
    if (widget.existing != null) return [];
    final title = _firstStageCtrl.text.trim().isEmpty
        ? 'Основа'
        : _firstStageCtrl.text.trim();
    return [
      SkillTreeNode(
        id: uid(),
        title: title,
        description: '',
        xpReward: 30,
        requiredQuestCompletions: 3,
      ),
    ];
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
  String? _selectedNodeId;

  Skill get _skill =>
      widget.state.skills
          .where((item) => item.id == widget.skill.id)
          .firstOrNull ??
      widget.skill;

  SkillTreeNode? _selectedNodeFor(Skill skill) {
    if (skill.treeNodes.isEmpty) return null;
    final selected = skill.treeNodes
        .where((node) => node.id == _selectedNodeId)
        .firstOrNull;
    if (selected != null) return selected;
    return skill.treeNodes
            .where(
              (node) =>
                  skill.treeNodeStatus(node) == SkillTreeNodeStatus.active,
            )
            .firstOrNull ??
        skill.treeNodes.first;
  }

  @override
  Widget build(BuildContext context) {
    final skill = _skill;
    final selectedNode = _selectedNodeFor(skill);
    final isDark = widget.state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 940,
        height: 680,
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
                      'Карта мастерства: ${skill.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: txt,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SmallBtn(
                    label: 'Новый этап',
                    icon: Icons.add,
                    color: skill.color,
                    tooltip: 'Создать первый этап карты',
                    onTap: () => _showAddNode(context, skill),
                  ),
                  const SizedBox(width: 10),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть карту мастерства',
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _SkillTreeIntro(isDark: isDark, color: skill.color),
            ),
            Expanded(
              child: MotionFadeSlideSwitcher(
                child: skill.treeNodes.isEmpty
                    ? _SkillTreeEmptyState(
                        key: const ValueKey('skill-tree-empty'),
                        isDark: isDark,
                        color: skill.color,
                        onAdd: () => _showAddNode(context, skill),
                      )
                    : Row(
                        key: const ValueKey('skill-tree-canvas'),
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 8, 14),
                              child: _MasteryTreeCanvas(
                                state: widget.state,
                                skill: skill,
                                isDark: isDark,
                                selectedNodeId: selectedNode?.id,
                                onSelect: (node) =>
                                    setState(() => _selectedNodeId = node.id),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 300,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 14, 14),
                              child: _MasteryNodeInspector(
                                state: widget.state,
                                skill: skill,
                                node: selectedNode,
                                isDark: isDark,
                                onAddChild: selectedNode == null
                                    ? null
                                    : () => _showAddNode(
                                        context,
                                        skill,
                                        parent: selectedNode,
                                      ),
                                onAddQuest: selectedNode == null
                                    ? null
                                    : () => _showAddTaskForNode(
                                        context,
                                        skill,
                                        selectedNode,
                                      ),
                                onMaster: selectedNode == null
                                    ? null
                                    : () => _masterNode(
                                        context,
                                        skill,
                                        selectedNode,
                                      ),
                                onDelete: selectedNode == null
                                    ? null
                                    : () {
                                        widget.state.removeSkillTreeNode(
                                          skill.id,
                                          selectedNode.id,
                                        );
                                        setState(() => _selectedNodeId = null);
                                      },
                              ),
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

  void _showAddNode(
    BuildContext context,
    Skill skill, {
    SkillTreeNode? parent,
  }) {
    showDialog(
      context: context,
      builder: (_) => AddSkillTreeNodeDialog(
        isDark: widget.state.isDark,
        skill: skill,
        parentNode: parent,
        onSave: (title, description, xpReward, requiredQuestCompletions) {
          widget.state.addSkillTreeNode(
            skill.id,
            SkillTreeNode(
              id: uid(),
              title: title,
              description: description,
              xpReward: xpReward,
              requiredQuestCompletions: requiredQuestCompletions,
              prerequisiteIds: parent == null ? [] : [parent.id],
            ),
          );
          setState(() {
            _selectedNodeId = skill.treeNodes.lastOrNull?.id;
          });
        },
      ),
    );
  }

  void _showAddTaskForNode(
    BuildContext context,
    Skill skill,
    SkillTreeNode node,
  ) {
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        isDark: widget.state.isDark,
        skillColor: skill.color,
        skill: skill,
        initialTreeNodeId: node.id,
        onSave:
            (
              title,
              xp,
              type,
              freq,
              customDays,
              priority,
              minimumAction,
              subtasks,
              tags,
              notificationsEnabled,
              notificationHour,
              notificationMinute,
              treeNodeId,
            ) => widget.state.addTask(
              Task(
                id: uid(),
                title: title,
                skillId: skill.id,
                xpReward: xp,
                type: type,
                repeatFrequency: freq,
                repeatCustomDays: customDays,
                priority: priority,
                minimumAction: minimumAction,
                subtasks: subtasks,
                tags: tags,
                treeNodeId: treeNodeId,
                notificationsEnabled: notificationsEnabled,
                notificationHour: notificationHour,
                notificationMinute: notificationMinute,
              ),
            ),
      ),
    ).then((_) => setState(() {}));
  }

  void _masterNode(BuildContext context, Skill skill, SkillTreeNode node) {
    final message = widget.state.masterSkillTreeNode(skill.id, node.id);
    if (message != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
    setState(() {});
  }
}

class _SkillTreeIntro extends StatelessWidget {
  final bool isDark;
  final Color color;

  const _SkillTreeIntro({required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text(
        'Этап навыка = ступень мастерства. Квесты = действия, которые двигают этап. '
        'Освоение этапа = зафиксированный milestone.',
        style: TextStyle(
          color: subtext(isDark),
          fontSize: 12,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MasteryTreeCanvas extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final bool isDark;
  final String? selectedNodeId;
  final ValueChanged<SkillTreeNode> onSelect;

  const _MasteryTreeCanvas({
    required this.state,
    required this.skill,
    required this.isDark,
    required this.selectedNodeId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bdr = borderColor(isDark);
    final bg = isDark ? const Color(0xFF0D0D12) : const Color(0xFFF7F8FC);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _buildMasteryTreeLayout(
            skill,
            Size(constraints.maxWidth, constraints.maxHeight),
          );

          return InteractiveViewer(
            minScale: 0.72,
            maxScale: 1.7,
            boundaryMargin: const EdgeInsets.all(120),
            child: SizedBox(
              width: layout.size.width,
              height: layout.size.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MasteryTreePainter(
                        skill: skill,
                        layout: layout,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  ...skill.treeNodes.map((node) {
                    final position = layout.positions[node.id];
                    if (position == null) return const SizedBox.shrink();
                    return Positioned(
                      left: position.dx - 58,
                      top: position.dy - 54,
                      width: 116,
                      height: 108,
                      child: _MasteryMapNode(
                        state: state,
                        skill: skill,
                        node: node,
                        isDark: isDark,
                        selected: node.id == selectedNodeId,
                        onTap: () => onSelect(node),
                      ),
                    );
                  }),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: _TreeLegend(isDark: isDark, color: skill.color),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  _MasteryTreeLayout _buildMasteryTreeLayout(Skill skill, Size minSize) {
    const horizontalGap = 128.0;
    const verticalGap = 118.0;
    const horizontalPadding = 120.0;
    const verticalPadding = 90.0;
    final nodes = skill.treeNodes;
    final validIds = nodes.map((node) => node.id).toSet();
    final childrenByParent = {
      for (final node in nodes) node.id: <SkillTreeNode>[],
    };
    final roots = <SkillTreeNode>[];

    for (final node in nodes) {
      final parentId = node.prerequisiteIds
          .where((id) => validIds.contains(id))
          .firstOrNull;
      if (parentId == null) {
        roots.add(node);
      } else {
        childrenByParent[parentId]?.add(node);
      }
    }

    var leafIndex = 0;
    var maxDepth = 0;
    final xById = <String, double>{};
    final depthById = <String, int>{};

    double placeNode(SkillTreeNode node, int depth) {
      maxDepth = math.max(maxDepth, depth);
      depthById[node.id] = depth;
      final children = childrenByParent[node.id] ?? const <SkillTreeNode>[];
      if (children.isEmpty) {
        final x = leafIndex * horizontalGap;
        leafIndex++;
        xById[node.id] = x;
        return x;
      }

      final childXs = children.map((child) => placeNode(child, depth + 1));
      final x = childXs.reduce((a, b) => a + b) / children.length;
      xById[node.id] = x;
      return x;
    }

    for (final root in roots) {
      placeNode(root, 0);
    }

    final minX = xById.values.isEmpty ? 0.0 : xById.values.reduce(math.min);
    final maxX = xById.values.isEmpty ? 0.0 : xById.values.reduce(math.max);
    final contentWidth = math.max(
      minSize.width,
      (maxX - minX) + horizontalPadding * 2,
    );
    final contentHeight = math.max(
      minSize.height,
      (maxDepth + 1) * verticalGap + verticalPadding * 2,
    );
    final xOffset = xById.length == 1
        ? contentWidth / 2
        : (contentWidth - (maxX - minX)) / 2 - minX;

    final positions = <String, Offset>{};
    for (final node in nodes) {
      final depth = depthById[node.id] ?? 0;
      final x = (xById[node.id] ?? 0) + xOffset;
      final y = contentHeight - verticalPadding - depth * verticalGap;
      positions[node.id] = Offset(x, y);
    }

    return _MasteryTreeLayout(
      size: Size(contentWidth, contentHeight),
      positions: positions,
    );
  }
}

class _MasteryTreeLayout {
  final Size size;
  final Map<String, Offset> positions;

  const _MasteryTreeLayout({required this.size, required this.positions});
}

class _MasteryTreePainter extends CustomPainter {
  final Skill skill;
  final _MasteryTreeLayout layout;
  final bool isDark;

  const _MasteryTreePainter({
    required this.skill,
    required this.layout,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(10)
      ..style = PaintingStyle.fill;
    for (var x = 24.0; x < size.width; x += 42) {
      for (var y = 24.0; y < size.height; y += 42) {
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }

    for (final node in skill.treeNodes) {
      final childPosition = layout.positions[node.id];
      final parentId = node.prerequisiteIds
          .where((id) => layout.positions.containsKey(id))
          .firstOrNull;
      final parentPosition = parentId == null
          ? null
          : layout.positions[parentId];
      if (childPosition == null || parentPosition == null) continue;

      final status = skill.treeNodeStatus(node);
      final color = skillTreeNodeStatusColor[status]!;
      final paint = Paint()
        ..color = color.withAlpha(
          status == SkillTreeNodeStatus.locked ? 75 : 170,
        )
        ..strokeWidth = status == SkillTreeNodeStatus.locked ? 2 : 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final middleY = (parentPosition.dy + childPosition.dy) / 2;
      final path = Path()
        ..moveTo(parentPosition.dx, parentPosition.dy - 34)
        ..cubicTo(
          parentPosition.dx,
          middleY,
          childPosition.dx,
          middleY,
          childPosition.dx,
          childPosition.dy + 34,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MasteryTreePainter oldDelegate) {
    return oldDelegate.skill != skill ||
        oldDelegate.layout != layout ||
        oldDelegate.isDark != isDark;
  }
}

class _MasteryMapNode extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final SkillTreeNode node;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  const _MasteryMapNode({
    required this.state,
    required this.skill,
    required this.node,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = skill.treeNodeStatus(node);
    final statusColor = skillTreeNodeStatusColor[status]!;
    final completed = state.completedTasksForTreeNode(skill.id, node.id);
    final target = node.questTarget;
    final diameter = switch (target) {
      <= 1 => 54.0,
      <= 3 => 62.0,
      _ => 70.0,
    };
    final nodeFill = isDark ? const Color(0xFF151923) : Colors.white;
    final icon = switch (status) {
      SkillTreeNodeStatus.locked => Icons.lock,
      SkillTreeNodeStatus.active => Icons.bolt_rounded,
      SkillTreeNodeStatus.mastered => Icons.workspace_premium,
    };

    return PressFeedback(
      scale: 0.94,
      tooltip: node.title,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: kMotionStandard,
            curve: kMotionCurve,
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status == SkillTreeNodeStatus.locked
                  ? nodeFill.withAlpha(isDark ? 150 : 210)
                  : statusColor.withAlpha(isDark ? 32 : 24),
              border: Border.all(
                color: selected ? Colors.white : statusColor,
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                if (selected || status == SkillTreeNodeStatus.active)
                  BoxShadow(
                    color: statusColor.withAlpha(selected ? 90 : 45),
                    blurRadius: selected ? 24 : 16,
                    spreadRadius: selected ? 1 : 0,
                  ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, color: statusColor, size: diameter * 0.42),
                Positioned(
                  bottom: -9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D0D12)
                          : const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      '${math.min(completed, target)}/$target',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Text(
            node.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: status == SkillTreeNodeStatus.locked
                  ? subtext(isDark)
                  : textColor(isDark),
              fontSize: 11,
              height: 1.05,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TreeLegend extends StatelessWidget {
  final bool isDark;
  final Color color;

  const _TreeLegend({required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface(isDark).withAlpha(isDark ? 220 : 235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(label: 'закрыто', color: const Color(0xFF8E8E93)),
          const SizedBox(width: 10),
          _LegendDot(label: 'активно', color: color),
          const SizedBox(width: 10),
          const _LegendDot(label: 'освоено', color: Color(0xFF34C759)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MasteryNodeInspector extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final SkillTreeNode? node;
  final bool isDark;
  final VoidCallback? onAddChild;
  final VoidCallback? onAddQuest;
  final VoidCallback? onMaster;
  final VoidCallback? onDelete;

  const _MasteryNodeInspector({
    required this.state,
    required this.skill,
    required this.node,
    required this.isDark,
    required this.onAddChild,
    required this.onAddQuest,
    required this.onMaster,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final selectedNode = node;
    final bdr = borderColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111118) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      padding: const EdgeInsets.all(14),
      child: selectedNode == null
          ? _EmptyNodeInspector(
              isDark: isDark,
              color: skill.color,
              onAddRoot: onAddChild,
            )
          : _SelectedNodeInspector(
              state: state,
              skill: skill,
              node: selectedNode,
              isDark: isDark,
              onAddChild: onAddChild,
              onAddQuest: onAddQuest,
              onMaster: onMaster,
              onDelete: onDelete,
            ),
    );
  }
}

class _EmptyNodeInspector extends StatelessWidget {
  final bool isDark;
  final Color color;
  final VoidCallback? onAddRoot;

  const _EmptyNodeInspector({
    required this.isDark,
    required this.color,
    required this.onAddRoot,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.account_tree_outlined, color: color, size: 30),
        const SizedBox(height: 12),
        Text(
          'Выберите этап',
          style: TextStyle(
            color: textColor(isDark),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Этап — это ступень навыка. Создавайте квесты для этапа, выполняйте их и фиксируйте освоение.',
          style: TextStyle(
            color: subtext(isDark),
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
        const Spacer(),
        SmallBtn(
          label: 'Первый этап',
          icon: Icons.add,
          color: color,
          onTap: onAddRoot ?? () {},
        ),
      ],
    );
  }
}

class _SelectedNodeInspector extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final SkillTreeNode node;
  final bool isDark;
  final VoidCallback? onAddChild;
  final VoidCallback? onAddQuest;
  final VoidCallback? onMaster;
  final VoidCallback? onDelete;

  const _SelectedNodeInspector({
    required this.state,
    required this.skill,
    required this.node,
    required this.isDark,
    required this.onAddChild,
    required this.onAddQuest,
    required this.onMaster,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final status = skill.treeNodeStatus(node);
    final statusColor = skillTreeNodeStatusColor[status]!;
    final linkedTasks = state.tasksForTreeNode(skill.id, node.id);
    final completed = state.completedTasksForTreeNode(skill.id, node.id);
    final target = node.questTarget;
    final ready = state.canMasterSkillTreeNode(skill.id, node.id);
    final parent = node.prerequisiteIds
        .map(
          (id) => skill.treeNodes
              .where((candidate) => candidate.id == id)
              .firstOrNull,
        )
        .whereType<SkillTreeNode>()
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(28),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor.withAlpha(120)),
              ),
              child: Icon(_statusIcon(status), color: statusColor, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: txt,
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TaskBadge(
                    label: skillTreeNodeStatusLabel[status]!,
                    color: statusColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (node.description.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            node.description,
            style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
          ),
        ],
        const SizedBox(height: 14),
        _NodeProgressPanel(
          isDark: isDark,
          color: statusColor,
          completed: completed,
          target: target,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            TaskBadge(
              icon: Icons.auto_awesome,
              label: '+${node.xpReward} XP',
              color: const Color(0xFFFFCC00),
            ),
            if (parent != null)
              TaskBadge(
                icon: Icons.lock_open,
                label: 'после: ${parent.title}',
                color: const Color(0xFF8E8E93),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Квесты этапа',
          style: TextStyle(
            color: txt,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: linkedTasks.isEmpty
              ? Center(
                  child: Text(
                    'Пока нет квестов.\nСоздайте квест, чтобы двинуть этап.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: linkedTasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (_, index) => _InspectorQuestRow(
                    task: linkedTasks[index],
                    isDark: isDark,
                    color: skill.color,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SmallBtn(
              label: 'Квест',
              icon: Icons.add_task,
              color: const Color(0xFF4A9EFF),
              onTap: onAddQuest ?? () {},
            ),
            SmallBtn(
              label: 'Следующий этап',
              icon: Icons.account_tree,
              color: skill.color,
              onTap: onAddChild ?? () {},
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MasterNodeButton(
                enabled: ready,
                mastered: node.isMastered,
                color: skill.color,
                onTap: onMaster ?? () {},
              ),
            ),
            const SizedBox(width: 10),
            PressFeedback(
              scale: 0.94,
              tooltip: 'Удалить этап',
              onTap: onDelete ?? () {},
              child: Icon(Icons.delete_outline, color: sub, size: 21),
            ),
          ],
        ),
      ],
    );
  }

  IconData _statusIcon(SkillTreeNodeStatus status) {
    return switch (status) {
      SkillTreeNodeStatus.locked => Icons.lock,
      SkillTreeNodeStatus.active => Icons.bolt_rounded,
      SkillTreeNodeStatus.mastered => Icons.workspace_premium,
    };
  }
}

class _NodeProgressPanel extends StatelessWidget {
  final bool isDark;
  final Color color;
  final int completed;
  final int target;

  const _NodeProgressPanel({
    required this.isDark,
    required this.color,
    required this.completed,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = math.min(completed, target);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Прогресс освоения',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$clamped/$target',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XPBar(
            progress: target == 0 ? 0 : (clamped / target).clamp(0.0, 1.0),
            color: color,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _InspectorQuestRow extends StatelessWidget {
  final Task task;
  final bool isDark;
  final Color color;

  const _InspectorQuestRow({
    required this.task,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        children: [
          Icon(
            task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isDone ? const Color(0xFF34C759) : color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: task.isDone ? sub : textColor(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                decoration: task.isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
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

    final button = AnimatedOpacity(
      duration: kMotionStandard,
      curve: kMotionCurve,
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
    );

    if (!enabled) return button;

    return PressFeedback(
      scale: 0.96,
      tooltip: 'Освоить этап карты мастерства',
      onTap: onTap,
      child: button,
    );
  }
}

class _SkillTreeEmptyState extends StatelessWidget {
  final bool isDark;
  final Color color;
  final VoidCallback onAdd;

  const _SkillTreeEmptyState({
    super.key,
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
            'Карта мастерства пока пустая',
            style: TextStyle(color: sub, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Начните с этапов: “Основы”, “Практика”, “Первый проект”.',
            style: TextStyle(color: sub.withAlpha(170), fontSize: 12),
          ),
          const SizedBox(height: 14),
          SmallBtn(
            label: 'Добавить этап',
            icon: Icons.add,
            color: color,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class AddSkillTreeNodeDialog extends StatefulWidget {
  final bool isDark;
  final Skill skill;
  final SkillTreeNode? parentNode;
  final Function(
    String title,
    String description,
    int xpReward,
    int requiredQuestCompletions,
  )
  onSave;

  const AddSkillTreeNodeDialog({
    super.key,
    required this.isDark,
    required this.skill,
    this.parentNode,
    required this.onSave,
  });

  @override
  State<AddSkillTreeNodeDialog> createState() => _AddSkillTreeNodeDialogState();
}

class _AddSkillTreeNodeDialogState extends State<AddSkillTreeNodeDialog> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  int _xpReward = 30;
  int _requiredQuestCompletions = 3;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
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
              DlgHeader(title: 'Новый этап карты', txtColor: txt),
              const SizedBox(height: 16),
              if (widget.parentNode != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withAlpha(45)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_tree, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Откроется после: ${widget.parentNode!.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: txt,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              DlgField(
                label: 'Название этапа',
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
                  SubLbl('XP за освоение', sub),
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
              Row(
                children: [
                  SubLbl('Размер этапа', sub),
                  const Spacer(),
                  TaskBadge(
                    icon: Icons.flag,
                    label: '$_requiredQuestCompletions квест.',
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _nodeSizeChip(
                    label: 'Малый',
                    value: 1,
                    color: color,
                    isDark: isDark,
                    sub: sub,
                    bdr: bdr,
                  ),
                  _nodeSizeChip(
                    label: 'Обычный',
                    value: 3,
                    color: color,
                    isDark: isDark,
                    sub: sub,
                    bdr: bdr,
                  ),
                  _nodeSizeChip(
                    label: 'Большой',
                    value: 5,
                    color: color,
                    isDark: isDark,
                    sub: sub,
                    bdr: bdr,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Размер определяет, сколько связанных квестов нужно завершить перед освоением этапа.',
                style: TextStyle(
                  color: sub,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              DlgActions(onCancel: () => Navigator.pop(context), onSave: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nodeSizeChip({
    required String label,
    required int value,
    required Color color,
    required bool isDark,
    required Color sub,
    required Color bdr,
  }) {
    return _DialogChoiceChip(
      label: '$label · $value',
      color: color,
      selected: _requiredQuestCompletions == value,
      backgroundColor: isDark
          ? const Color(0xFF23232D)
          : const Color(0xFFF0F0F5),
      borderColor: bdr,
      inactiveTextColor: sub,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      radius: 999,
      selectedWeight: FontWeight.w800,
      onTap: () => setState(() => _requiredQuestCompletions = value),
    );
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onSave(
      title,
      _descriptionCtrl.text.trim(),
      _xpReward,
      _requiredQuestCompletions,
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
  final Skill? skill;
  final String? initialTreeNodeId;
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
    String? treeNodeId,
  )
  onSave;
  const AddTaskDialog({
    super.key,
    required this.isDark,
    required this.skillColor,
    this.skill,
    this.initialTreeNodeId,
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
  String? _treeNodeId;
  bool _minimumActionEnabled = false;
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool _advancedExpanded = false;
  bool _qualityExpanded = false;
  bool _subtasksExpanded = false;
  bool _tagsExpanded = false;

  int get _softCap => typeSoftCap[_type]!;
  bool get _overCap => _xp > _softCap;
  bool get _hasMinimumAction =>
      _minimumActionEnabled && _minimumActionCtrl.text.trim().isNotEmpty;
  bool get _showBigQuestTools =>
      _type == TaskType.midTerm ||
      _type == TaskType.longTerm ||
      _subtasks.isNotEmpty;
  String get _advancedSummary {
    final parts = <String>[];
    if (_type != TaskType.shortTerm) parts.add(typeLabel[_type]!);
    if (_treeNodeId != null) parts.add('этап');
    if (_notificationsEnabled) parts.add('напоминание');
    if (_subtasks.isNotEmpty) parts.add('${_subtasks.length} шаг.');
    if (_tags.isNotEmpty) parts.add('${_tags.length} конт.');
    return parts.isEmpty
        ? 'Поведение, этап, контексты и баланс'
        : parts.join(' · ');
  }

  SkillTreeNode? get _initialStage {
    if (widget.existing != null) return null;
    final skill = widget.skill;
    if (skill == null || widget.initialTreeNodeId == null) return null;
    return skill.treeNodes
        .where((node) => node.id == widget.initialTreeNodeId)
        .firstOrNull;
  }

  SkillTreeNode? get _suggestedStage {
    if (widget.existing != null ||
        widget.initialTreeNodeId != null ||
        _treeNodeId != null) {
      return null;
    }
    final skill = widget.skill;
    if (skill == null) return null;
    return skill.treeNodes
        .where(
          (node) => skill.treeNodeStatus(node) == SkillTreeNodeStatus.active,
        )
        .firstOrNull;
  }

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
    return 'Хороший квест';
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
      _minimumActionEnabled = ex.minimumAction.trim().isNotEmpty;
      _xp = ex.xpReward;
      _type = ex.type;
      _freq = ex.repeatFrequency;
      _customCtrl.text = '${ex.repeatCustomDays < 1 ? 1 : ex.repeatCustomDays}';
      _priority = ex.priority;
      _subtasks.addAll(ex.subtasks);
      _tags.addAll(ex.tags);
      _treeNodeId = ex.treeNodeId;
      _notificationsEnabled = ex.notificationsEnabled;
      _advancedExpanded =
          ex.type == TaskType.repeating ||
          ex.subtasks.isNotEmpty ||
          ex.tags.isNotEmpty ||
          ex.notificationsEnabled ||
          ex.treeNodeId != null;
      _subtasksExpanded = ex.subtasks.isNotEmpty;
      _tagsExpanded = ex.tags.isNotEmpty;
      if (ex.notificationHour != null && ex.notificationMinute != null) {
        _notificationTime = TimeOfDay(
          hour: ex.notificationHour!,
          minute: ex.notificationMinute!,
        );
      }
    } else {
      _treeNodeId = widget.initialTreeNodeId;
      _minimumActionEnabled = widget.initialTreeNodeId != null;
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
                    ? 'Редактировать квест'
                    : 'Новый квест',
                txtColor: txt,
              ),
              const SizedBox(height: 16),
              if (_initialStage case final stage?) ...[
                _buildStageContextCard(stage, txt, sub, bdr, c, isDark),
                const SizedBox(height: 14),
              ] else if (_suggestedStage case final stage?) ...[
                _buildStageSuggestionCard(stage, txt, sub, bdr, c, isDark),
                const SizedBox(height: 14),
              ],
              DlgField(
                label: 'Что сделать?',
                ctrl: _titleCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
              ),
              const SizedBox(height: 16),
              _buildMinimumActionSection(fBg, txt, sub, bdr, c),
              const SizedBox(height: 16),
              _buildAdvancedSection(fBg, txt, sub, bdr, c, isDark),
              const SizedBox(height: 22),
              DlgActions(
                onCancel: () => Navigator.pop(context),
                onSave: _save,
                saveLabel: widget.existing == null ? 'Создать' : 'Сохранить',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageContextCard(
    SkillTreeNode stage,
    Color txt,
    Color sub,
    Color bdr,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 18 : 12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(58)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.account_tree, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Этап: ${stage.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: txt,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Этот квест двигает выбранный этап мастерства.',
                  style: TextStyle(
                    color: sub,
                    fontSize: 11.5,
                    height: 1.3,
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

  Widget _buildStageSuggestionCard(
    SkillTreeNode stage,
    Color txt,
    Color sub,
    Color bdr,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr.withAlpha(180)),
      ),
      child: Row(
        children: [
          Icon(Icons.route_rounded, color: color, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Есть активный этап: ${stage.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: txt,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Можно связать квест с текущей ступенью roadmap.',
                  style: TextStyle(
                    color: sub,
                    fontSize: 11.3,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SmallBtn(
            label: 'Привязать',
            icon: Icons.add_link,
            color: color,
            onTap: () {
              setState(() {
                _treeNodeId = stage.id;
                _advancedExpanded = true;
              });
            },
          ),
        ],
      ),
    );
  }

  int get _customDays {
    final parsed = int.tryParse(_customCtrl.text.trim()) ?? 1;
    return parsed < 1 ? 1 : parsed;
  }

  Widget _buildMinimumActionSection(
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.bolt_outlined, color: color, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Минимальный шаг',
                      style: TextStyle(
                        color: txt,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Лёгкий вход, если квест кажется тяжёлым',
                      style: TextStyle(color: sub, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _minimumActionEnabled,
                activeThumbColor: color,
                onChanged: (value) =>
                    setState(() => _minimumActionEnabled = value),
              ),
            ],
          ),
          MotionExpandable(
            expanded: _minimumActionEnabled,
            expandedChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: _minimumActionCtrl,
                style: TextStyle(color: txt, fontSize: 13),
                minLines: 2,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Например: открыть проект и сделать первый шаг',
                  hintStyle: TextStyle(color: sub, fontSize: 12),
                  filled: true,
                  fillColor: surface(widget.isDark),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: bdr),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: bdr),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color.withAlpha(180)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _advancedCard({
    required bool isDark,
    required Color bdr,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bdr.withAlpha(180)),
      ),
      child: child,
    );
  }

  Widget _buildXpSection(Color sub, Color bdr, Color color, bool isDark) {
    return _advancedCard(
      isDark: isDark,
      bdr: bdr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SubLbl('XP за квест', sub),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_xp XP',
                  style: TextStyle(
                    color: color,
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
            activeColor: color,
            inactiveColor: color.withAlpha(40),
            onChanged: (v) => setState(() => _xp = v.round()),
          ),
          AnimatedSize(
            duration: kMotionSlow,
            curve: kMotionCurve,
            child: _overCap
                ? Container(
                    margin: const EdgeInsets.only(top: 2),
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
        ],
      ),
    );
  }

  Widget _buildTypeSection(Color sub, Color bdr, bool isDark) {
    return _advancedCard(
      isDark: isDark,
      bdr: bdr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubLbl('Тип квеста', sub),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskType.values.map((t) {
              final sel = _type == t;
              final tc = typeColor[t]!;
              return _DialogChoiceChip(
                label: typeLabel[t]!,
                color: tc,
                selected: sel,
                backgroundColor: isDark
                    ? const Color(0xFF23232D)
                    : const Color(0xFFF0F0F5),
                borderColor: bdr,
                inactiveTextColor: sub,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                radius: 999,
                selectedWeight: FontWeight.w700,
                onTap: () => setState(() {
                  _type = t;
                  if (t == TaskType.repeating) {
                    _advancedExpanded = true;
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 7),
          Text(
            'Лёгкий tie-breaker: в “Сейчас” важнее риск привычки, минимальный шаг и активный этап.',
            style: TextStyle(color: sub, fontSize: 11.2, height: 1.25),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySection(Color sub, Color bdr, bool isDark) {
    return _advancedCard(
      isDark: isDark,
      bdr: bdr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubLbl('Ручной фокус', sub),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Priority.values.map((priority) {
              final sel = _priority == priority;
              final pc = priorityColor[priority]!;
              return _DialogChoiceChip(
                label: priorityLabel[priority]!,
                color: pc,
                selected: sel,
                backgroundColor: isDark
                    ? const Color(0xFF23232D)
                    : const Color(0xFFF0F0F5),
                borderColor: bdr,
                inactiveTextColor: sub,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                radius: 999,
                selectedWeight: FontWeight.w700,
                onTap: () => setState(() => _priority = priority),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorSection(
    Color fBg,
    Color txt,
    Color sub,
    Color bdr,
    Color color,
    bool isDark,
  ) {
    return _advancedCard(
      isDark: isDark,
      bdr: bdr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Поведение',
                      style: TextStyle(
                        color: txt,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Тип квеста, повторяемость и напоминание.',
                      style: TextStyle(color: sub, fontSize: 11.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTypeSection(sub, bdr, isDark),
          if (_type == TaskType.repeating) ...[
            const SizedBox(height: 10),
            _buildRepeatSection(fBg, txt, sub, bdr, isDark),
          ],
          const SizedBox(height: 10),
          _buildNotificationSection(fBg, txt, sub, bdr, color),
        ],
      ),
    );
  }

  Widget _buildBalanceFocusSection(
    Color sub,
    Color bdr,
    Color color,
    bool isDark,
  ) {
    return _advancedCard(
      isDark: isDark,
      bdr: bdr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Баланс и фокус',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Вторичные настройки: ручной XP и фокус.',
            style: TextStyle(color: sub, fontSize: 11.3),
          ),
          const SizedBox(height: 10),
          _buildXpSection(sub, bdr, color, isDark),
          const SizedBox(height: 10),
          _buildPrioritySection(sub, bdr, isDark),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection(
    Color fBg,
    Color txt,
    Color sub,
    Color bdr,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr),
      ),
      child: Column(
        children: [
          _sectionToggle(
            icon: Icons.tune_rounded,
            title: 'Настройки квеста',
            subtitle: _advancedSummary,
            expanded: _advancedExpanded,
            color: color,
            txt: txt,
            sub: sub,
            onTap: () => setState(() => _advancedExpanded = !_advancedExpanded),
          ),
          MotionExpandable(
            expanded: _advancedExpanded,
            expandedChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBehaviorSection(fBg, txt, sub, bdr, color, isDark),
                  const SizedBox(height: 10),
                  if (widget.skill?.treeNodes.isNotEmpty ?? false) ...[
                    _buildTreeNodeSection(fBg, txt, sub, bdr, color, isDark),
                    const SizedBox(height: 10),
                  ],
                  if (_showBigQuestTools) ...[
                    _buildTextListEditor(
                      title: 'Большой квест',
                      hint: '+ Добавить шаг',
                      items: _subtasks,
                      ctrl: _subtaskCtrl,
                      color: color,
                      txt: txt,
                      sub: sub,
                      bdr: bdr,
                      expanded: _subtasksExpanded,
                      onToggle: () => setState(
                        () => _subtasksExpanded = !_subtasksExpanded,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _buildTextListEditor(
                    title: 'Контексты',
                    hint: '+ Добавить контекст',
                    items: _tags,
                    ctrl: _tagCtrl,
                    color: color,
                    txt: txt,
                    sub: sub,
                    bdr: bdr,
                    expanded: _tagsExpanded,
                    onToggle: () =>
                        setState(() => _tagsExpanded = !_tagsExpanded),
                  ),
                  const SizedBox(height: 10),
                  _buildQualityCheck(fBg, txt, sub, bdr, color),
                  const SizedBox(height: 10),
                  _buildBalanceFocusSection(sub, bdr, color, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeNodeSection(
    Color fBg,
    Color txt,
    Color sub,
    Color bdr,
    Color color,
    bool isDark,
  ) {
    final skill = widget.skill;
    final nodes = skill?.treeNodes ?? [];
    if (nodes.isEmpty) return const SizedBox.shrink();
    final selectedNodeExists = nodes.any((node) => node.id == _treeNodeId);
    final selectedNodeId = selectedNodeExists ? _treeNodeId : null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bdr.withAlpha(180)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Этап мастерства',
                      style: TextStyle(
                        color: txt,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'К какому этапу навыка относится квест?',
                      style: TextStyle(color: sub, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _DialogChoiceChip(
                label: 'Без этапа',
                color: const Color(0xFF8E8E93),
                selected: selectedNodeId == null,
                backgroundColor: isDark
                    ? const Color(0xFF23232D)
                    : const Color(0xFFF0F0F5),
                borderColor: bdr,
                inactiveTextColor: sub,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                radius: 999,
                selectedWeight: FontWeight.w700,
                onTap: () => setState(() => _treeNodeId = null),
              ),
              ...nodes.map((node) {
                final nodeColor = node.isMastered
                    ? const Color(0xFF34C759)
                    : color;
                return _DialogChoiceChip(
                  label: node.title,
                  color: nodeColor,
                  selected: selectedNodeId == node.id,
                  backgroundColor: isDark
                      ? const Color(0xFF23232D)
                      : const Color(0xFFF0F0F5),
                  borderColor: bdr,
                  inactiveTextColor: sub,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  radius: 999,
                  selectedWeight: FontWeight.w700,
                  onTap: () => setState(() => _treeNodeId = node.id),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatSection(
    Color fBg,
    Color txt,
    Color sub,
    Color bdr,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bdr.withAlpha(180)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubLbl('Повторяемость', sub),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: RepeatFrequency.values.map((f) {
              final sel = _freq == f;
              return _DialogChoiceChip(
                label: freqLabel[f]!,
                color: const Color(0xFF4A9EFF),
                selected: sel,
                backgroundColor: isDark
                    ? const Color(0xFF23232D)
                    : const Color(0xFFF0F0F5),
                borderColor: isDark
                    ? const Color(0xFF2A2A35)
                    : const Color(0xFFE0E0E8),
                inactiveTextColor: sub,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                radius: 999,
                selectedWeight: FontWeight.w600,
                onTap: () => setState(() => _freq = f),
              );
            }).toList(),
          ),
          MotionExpandable(
            expanded: _freq == RepeatFrequency.custom,
            expandedChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Text('Каждые', style: TextStyle(color: txt, fontSize: 13)),
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
                  Text('дней', style: TextStyle(color: txt, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Обновится в 03:00 через ${freqDays(_freq, _customDays)} дн.',
            style: TextStyle(color: sub, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _sectionToggle({
    required IconData icon,
    required String title,
    required bool expanded,
    required Color color,
    required Color txt,
    required Color sub,
    required VoidCallback onTap,
    String subtitle = '',
    bool compact = false,
  }) {
    return Tooltip(
      message: expanded ? 'Скрыть раздел' : 'Показать раздел',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: color.withAlpha(220), size: compact ? 15 : 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: txt,
                  fontSize: compact ? 12.5 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              SizedBox(
                width: compact ? 28 : 188,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: sub,
                    fontSize: compact ? 11.5 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
            ],
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: kMotionStandard,
              curve: kMotionCurve,
              child: Icon(Icons.expand_more, color: sub, size: 17),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextListEditor({
    required String title,
    required String hint,
    required List<String> items,
    required TextEditingController ctrl,
    required Color color,
    required Color txt,
    required Color sub,
    required Color bdr,
    required bool expanded,
    required VoidCallback onToggle,
    String prefix = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bdr.withAlpha(160)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionToggle(
            icon: title == 'Контексты' ? Icons.sell_outlined : Icons.checklist,
            title: title,
            subtitle: '${items.length}',
            expanded: expanded,
            color: color,
            txt: txt,
            sub: sub,
            onTap: onToggle,
            compact: true,
          ),
          MotionExpandable(
            expanded: expanded,
            expandedChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (items.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: items.asMap().entries.map((entry) {
                        return MotionListItem(
                          key: ValueKey('$title-${entry.key}-${entry.value}'),
                          index: entry.key,
                          slide: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
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
                                Tooltip(
                                  message: 'Удалить элемент списка',
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => items.removeAt(entry.key),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Color(0xFFFF3B30),
                                      size: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                      Tooltip(
                        message: 'Добавить элемент списка',
                        child: GestureDetector(
                          onTap: () => _addListItem(items, ctrl),
                          child: Icon(
                            Icons.add_circle_outline,
                            color: color,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      'Хороший квест' => const Color(0xFF34C759),
      'Уточни действие' => const Color(0xFFFFCC00),
      _ => const Color(0xFFFF9500),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionToggle(
            icon: Icons.rule_folder_outlined,
            title: 'Качество квеста',
            expanded: _qualityExpanded,
            color: qualityColor,
            txt: txt,
            sub: sub,
            onTap: () => setState(() => _qualityExpanded = !_qualityExpanded),
          ),
          MotionExpandable(
            expanded: _qualityExpanded,
            expandedChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
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
                    okLabel: 'XP настроен',
                    warnLabel: 'Добавь XP для обратной связи',
                    txt: txt,
                    sub: sub,
                  ),
                  const SizedBox(height: 6),
                  _qualityRow(
                    ok: !_looksBigTask || _subtasks.isNotEmpty,
                    okLabel: 'Структура уже разбита на шаги',
                    warnLabel: 'Для большого квеста лучше добавить 2–3 шага',
                    txt: txt,
                    sub: sub,
                  ),
                  if (_looksBigTask &&
                      (!_hasMinimumAction || _subtasks.isEmpty)) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withAlpha(48)),
                      ),
                      child: Text(
                        'Квест выглядит большим. Добавь минимум или 2–3 шага, чтобы легче начать.',
                        style: TextStyle(
                          color: txt,
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
          MotionExpandable(
            expanded: _notificationsEnabled,
            expandedChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Tooltip(
                message: 'Выбрать время напоминания',
                child: GestureDetector(
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
              ),
            ),
          ),
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
      _minimumActionEnabled ? _minimumActionCtrl.text.trim() : '',
      List.of(_subtasks),
      List.of(_tags),
      _notificationsEnabled,
      _notificationsEnabled ? _notificationTime.hour : null,
      _notificationsEnabled ? _notificationTime.minute : null,
      _treeNodeId,
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
  _RewardReveal? _lastReveal;
  bool _buffsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final unopened = widget.state.unopenedRewardChests;
    final buffs = widget.state.activeBuffs;
    final size = MediaQuery.sizeOf(context);
    final availableWidth = size.width - 36;
    final availableHeight = size.height - 40;
    final dialogWidth = availableWidth < 360
        ? availableWidth
        : availableWidth.clamp(360.0, 500.0).toDouble();
    final dialogHeight = availableHeight < 500
        ? availableHeight
        : availableHeight.clamp(500.0, 620.0).toDouble();

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.redeem, color: Color(0xFFFFCC00), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Трофеи после действий',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть трофеи',
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
                            title: 'Новые сундуки',
                            value: '${unopened.length}',
                            icon: Icons.inventory_2,
                            color: const Color(0xFFFFCC00),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Пассивные эффекты',
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
                      'Трофеи появляются после заметных действий: сильного дня, рубежа серии или победы над сопротивлением.',
                      style: TextStyle(color: sub, fontSize: 12, height: 1.35),
                    ),
                    MotionExpandable(
                      expanded: _lastReveal != null,
                      collapsedChild: const SizedBox(height: 18),
                      expandedChild: _lastReveal == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _RewardRevealNotice(
                                key: ValueKey(_lastReveal!.id),
                                reveal: _lastReveal!,
                                isDark: isDark,
                              ),
                            ),
                    ),
                    Text(
                      'Новые сундуки',
                      style: TextStyle(
                        color: txt,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    MotionFadeSlideSwitcher(
                      child: unopened.isEmpty
                          ? _RewardsEmptyState(
                              key: const ValueKey('empty-chests'),
                              icon: Icons.inventory_2_outlined,
                              title: 'Пока нет сундуков',
                              subtitle:
                                  'Закрой сильный день, удержи серию или пройди событие сопротивления, чтобы получить трофей.',
                              isDark: isDark,
                            )
                          : Column(
                              key: const ValueKey('chest-list'),
                              children: unopened.asMap().entries.map((entry) {
                                final chest = entry.value;
                                return MotionListItem(
                                  key: ValueKey('chest-${chest.id}'),
                                  index: entry.key,
                                  slide: 5,
                                  child: _RewardChestCard(
                                    chest: chest,
                                    skill: chest.skillId == null
                                        ? null
                                        : widget.state.skills
                                              .where(
                                                (skill) =>
                                                    skill.id == chest.skillId,
                                              )
                                              .firstOrNull,
                                    isDark: isDark,
                                    onOpen: () => _openChest(context, chest.id),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          setState(() => _buffsExpanded = !_buffsExpanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bolt,
                              color: const Color(0xFF34C759).withAlpha(190),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Пассивные эффекты',
                                style: TextStyle(
                                  color: txt,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TaskBadge(
                              label: '${buffs.length}',
                              color: const Color(0xFF34C759),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _buffsExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: sub,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    MotionExpandable(
                      expanded: _buffsExpanded,
                      collapsedChild: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          buffs.isEmpty
                              ? 'Эффектов сейчас нет. Они появятся после открытия сундуков.'
                              : 'Эффекты применятся сами, когда подойдут к квесту.',
                          style: TextStyle(
                            color: sub,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                      expandedChild: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: MotionFadeSlideSwitcher(
                          child: buffs.isEmpty
                              ? _RewardsEmptyState(
                                  key: const ValueKey('empty-buffs'),
                                  icon: Icons.bolt_outlined,
                                  title: 'Нет пассивных эффектов',
                                  subtitle:
                                      'Открой сундук, и здесь появится временное усиление для следующих квестов.',
                                  isDark: isDark,
                                )
                              : Column(
                                  key: const ValueKey('buff-list'),
                                  children: buffs.asMap().entries.map((entry) {
                                    final buff = entry.value;
                                    return MotionListItem(
                                      key: ValueKey('buff-${buff.id}'),
                                      index: entry.key,
                                      slide: 5,
                                      child: _ActiveBuffCard(
                                        buff: buff,
                                        skill: buff.skillId == null
                                            ? null
                                            : widget.state.skills
                                                  .where(
                                                    (skill) =>
                                                        skill.id ==
                                                        buff.skillId,
                                                  )
                                                  .firstOrNull,
                                        isDark: isDark,
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
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
    final chest = widget.state.rewardChests
        .where((item) => item.id == chestId)
        .firstOrNull;
    if (chest == null) return;

    final message = widget.state.openRewardChest(chestId);
    if (message == null) return;
    AppFeedback.reward();
    final buff = widget.state.buffs
        .where((item) => item.sourceChestId == chestId)
        .firstOrNull;

    setState(
      () => _lastReveal = _RewardReveal(
        id: '${chest.id}-${buff?.id ?? chest.openedAt?.millisecondsSinceEpoch}',
        message: message,
        buffTitle: buff?.title,
        bonusPercent: buff?.bonusPercent,
        color: rewardRarityColor[chest.rarity]!,
        icon: chest.rarity == RewardRarity.epic
            ? Icons.auto_awesome
            : Icons.inventory_2,
      ),
    );
  }
}

class _RewardReveal {
  final String id;
  final String message;
  final String? buffTitle;
  final int? bonusPercent;
  final Color color;
  final IconData icon;

  const _RewardReveal({
    required this.id,
    required this.message,
    required this.color,
    required this.icon,
    this.buffTitle,
    this.bonusPercent,
  });
}

class _RewardRevealNotice extends StatefulWidget {
  final _RewardReveal reveal;
  final bool isDark;

  const _RewardRevealNotice({
    super.key,
    required this.reveal,
    required this.isDark,
  });

  @override
  State<_RewardRevealNotice> createState() => _RewardRevealNoticeState();
}

class _RewardRevealNoticeState extends State<_RewardRevealNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kMotionProgress)
      ..forward();
  }

  @override
  void didUpdateWidget(covariant _RewardRevealNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reveal.id != widget.reveal.id) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txt = textColor(widget.isDark);
    final sub = subtext(widget.isDark);
    final reveal = widget.reveal;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = kMotionCurve.transform(_controller.value);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Transform.scale(
              scale: 0.96 + value * 0.04,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -6,
            left: 44,
            child: MilestoneConfettiBurst(
              color: reveal.color,
              alignment: Alignment.topCenter,
              particles: 18,
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: reveal.color.withAlpha(widget.isDark ? 20 : 15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: reveal.color.withAlpha(78)),
              boxShadow: [
                BoxShadow(
                  color: reveal.color.withAlpha(widget.isDark ? 26 : 22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                RewardGlowIcon(
                  icon: reveal.icon,
                  color: reveal.color,
                  size: 46,
                  iconSize: 21,
                  sparkle: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Сундук открыт',
                        style: TextStyle(
                          color: reveal.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        reveal.message,
                        style: TextStyle(
                          color: txt,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (reveal.buffTitle != null ||
                          reveal.bonusPercent != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          [
                            if (reveal.buffTitle != null) reveal.buffTitle!,
                            if (reveal.bonusPercent != null)
                              '+${reveal.bonusPercent}% XP',
                          ].join(' • '),
                          style: TextStyle(color: sub, fontSize: 11.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          RewardGlowIcon(
            icon: chest.rarity == RewardRarity.epic
                ? Icons.auto_awesome
                : Icons.inventory_2,
            color: rarityColor,
            size: 42,
            iconSize: 20,
            sparkle: chest.rarity != RewardRarity.common,
            loop: chest.rarity == RewardRarity.epic,
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
            tooltip: 'Открыть сундук и получить трофей',
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
    super.key,
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
                    'События сопротивления',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть события сопротивления',
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),

            // Collapsible Explanation
            MotionExpandable(
              expanded: _expanded,
              collapsedChild: Tooltip(
                message: 'Показать объяснение событий сопротивления',
                child: GestureDetector(
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
                          'Зачем здесь сопротивление?',
                          style: TextStyle(color: sub, fontSize: 12),
                        ),
                        const Spacer(),
                        Icon(Icons.expand_more, color: sub, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              expandedChild: Container(
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
                          'События сопротивления',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: txt,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Tooltip(
                          message: 'Скрыть объяснение',
                          child: GestureDetector(
                            onTap: () => setState(() => _expanded = false),
                            child: Icon(
                              Icons.expand_less,
                              color: sub,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Сопротивление — это образ препятствия на пути навыка. Оно слабеет от выполненных квестов, лёгких стартов и общего прогресса, но не требует отдельного управления каждый день.',
                      style: TextStyle(color: sub, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTip(Icons.local_fire_department, 'Серия', sub),
                        const SizedBox(width: 16),
                        _buildTip(Icons.flag, 'Фокус', sub),
                        const SizedBox(width: 16),
                        _buildTip(Icons.play_circle_fill, 'Старт', sub),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Container(height: 1, color: bdr),
            Expanded(
              child: MotionFadeSlideSwitcher(
                child: widget.state.bosses.isEmpty
                    ? Center(
                        key: const ValueKey('bosses-empty'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, color: sub, size: 38),
                            const SizedBox(height: 12),
                            Text(
                              'Нет событий сопротивления',
                              style: TextStyle(color: sub, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Их можно добавить для навыка, где нужен образ препятствия.',
                              style: TextStyle(
                                color: sub.withAlpha(160),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        key: const ValueKey('bosses-list'),
                        padding: const EdgeInsets.all(14),
                        itemCount: widget.state.bosses.length,
                        itemBuilder: (_, i) {
                          final boss = widget.state.bosses[i];
                          return MotionListItem(
                            key: ValueKey('boss-${boss.id}'),
                            index: i,
                            child: _BossCard(
                              boss: boss,
                              snapshot: widget.state.bossSnapshot(boss),
                              skills: widget.state.skills,
                              isDark: isDark,
                              onDelete: () {
                                widget.state.removeBoss(boss.id);
                                Navigator.pop(context);
                              },
                            ),
                          );
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
                        label: 'Добавить событие',
                        icon: Icons.add,
                        color: const Color(0xFFFF2D55),
                        tooltip: 'Добавить событие сопротивления',
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
              Tooltip(
                message: 'Удалить событие сопротивления',
                child: GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline, color: sub, size: 18),
                ),
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
                  label: 'Серия',
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
                    label: 'Карта',
                    value:
                        '${snapshot.masteredTreeNodes}/${snapshot.totalTreeNodes}',
                    color: const Color(0xFF34C759),
                  ),
                if (snapshot.stalledHighPriorityTasks > 0)
                  _BossMetricChip(
                    label: 'Риск',
                    value: '${snapshot.stalledHighPriorityTasks} важн.',
                    color: const Color(0xFFFF3B30),
                  ),
                if (snapshot.urgentRepeatingTasks > 0)
                  _BossMetricChip(
                    label: 'Срок',
                    value: '${snapshot.urgentRepeatingTasks} повт.',
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
    final skills = _uniqueSkills(widget.skills);
    final selectedSkillId = skills.any((skill) => skill.id == _skillId)
        ? _skillId
        : null;

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
              DlgHeader(title: 'Новое сопротивление', txtColor: txt),
              const SizedBox(height: 16),
              DlgField(
                label: 'Название события',
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
                    value: selectedSkillId,
                    hint: Text(
                      'Выберите навык',
                      style: TextStyle(color: sub, fontSize: 14),
                    ),
                    isExpanded: true,
                    dropdownColor: surface(isDark),
                    items: skills
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
                  SubLbl('Базовый порог серии', sub),
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
                'Серия остаётся главным рычагом, но сопротивление также слабеет от важных квестов, лёгких стартов и прогресса по навыку.',
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

  List<Skill> _uniqueSkills(List<Skill> skills) {
    final seen = <String>{};
    return [
      for (final skill in skills)
        if (seen.add(skill.id)) skill,
    ];
  }

  void _save() {
    final skillId = _skillId;
    if (_titleCtrl.text.trim().isEmpty ||
        skillId == null ||
        !_uniqueSkills(widget.skills).any((skill) => skill.id == skillId)) {
      return;
    }
    widget.onSave(_titleCtrl.text.trim(), skillId, _streak);
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
