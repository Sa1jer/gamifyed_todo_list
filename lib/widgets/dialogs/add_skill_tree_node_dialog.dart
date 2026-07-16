import 'package:flutter/material.dart';

import '../../models.dart';
import '../../utils.dart';
import '../shared.dart';
import 'dialog_choice_chip.dart';

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
                  PressFeedback(
                    scale: 0.96,
                    tooltip: 'Ввести XP числом',
                    onTap: () async {
                      final value = await showIntegerEditDialog(
                        context,
                        title: 'XP за освоение',
                        initialValue: _xpReward,
                        min: 10,
                        max: 200,
                        color: color,
                        isDark: isDark,
                        suffix: 'XP',
                      );
                      if (value != null && mounted) {
                        setState(() => _xpReward = value);
                      }
                    },
                    child: TaskBadge(
                      icon: Icons.auto_awesome,
                      label: '$_xpReward XP',
                      color: color,
                    ),
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
    return DialogChoiceChip(
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
