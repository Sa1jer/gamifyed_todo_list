import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../utils.dart';
import '../shared.dart';
import 'boss_card.dart';

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
                            child: BossResistanceCard(
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
  void dispose() {
    _titleCtrl.dispose();
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
