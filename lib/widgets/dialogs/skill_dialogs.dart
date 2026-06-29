part of '../dialogs.dart';

class AddSkillDialog extends StatefulWidget {
  final bool isDark;
  final Skill? existing;
  final bool showFirstRunHints;
  final SkillSaveCallback onSave;
  const AddSkillDialog({
    super.key,
    required this.isDark,
    this.existing,
    this.showFirstRunHints = false,
    required this.onSave,
  });
  @override
  State<AddSkillDialog> createState() => _AddSkillDialogState();
}

class _AddSkillDialogState extends State<AddSkillDialog> {
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _firstStageCtrl = TextEditingController();
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
      (_visibleRows * _itemSize +
          (_visibleRows - 1) * _spacing +
          _spacing * 2) *
      1.08;

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
    _firstStageCtrl.dispose();
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 18 : 24,
          ),
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
              Center(
                child: Container(
                  key: const ValueKey('skill-preview-icon'),
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
              if (widget.showFirstRunHints && widget.existing == null) ...[
                FirstRunDialogHint(
                  text:
                      'Достаточно названия и цели. Этап можно добавить сейчас или позже.',
                  color: _color,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  SubLbl('Иконка', sub),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_allIcons.length} иконок · прокрутите',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: sub, fontSize: 11),
                    ),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth < 390
                        ? 7
                        : _crossAxisCount;
                    return GridView.builder(
                      key: const ValueKey('skill-icon-grid'),
                      padding: const EdgeInsets.all(_spacing),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              SubLbl('Цвет', sub),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kColors.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  final sel = c == _color;
                  return KeyedSubtree(
                    key: ValueKey('skill-color-$i'),
                    child: _ColorChoiceButton(
                      color: c,
                      selected: sel,
                      isDark: isDark,
                      onTap: () => setState(() => _color = c),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              if (widget.existing == null) ...[
                DlgField(
                  label: 'Первый этап (опционально)',
                  ctrl: _firstStageCtrl,
                  fBg: fBg,
                  txt: txt,
                  sub: sub,
                  bdr: bdr,
                ),
                const SizedBox(height: 6),
                Text(
                  'Например: «Основа». Можно оставить пустым и собрать дорожную карту позже.',
                  style: TextStyle(
                    color: sub,
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              const SizedBox(height: 8),
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

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final initialTreeNodes = _initialTreeNodes();
    widget.onSave(
      _nameCtrl.text.trim(),
      _goalCtrl.text,
      _items,
      _color,
      _icon,
      initialTreeNodes,
      null,
    );
    Navigator.pop(context);
  }

  List<SkillTreeNode> _initialTreeNodes() {
    if (widget.existing != null) return [];
    final title = _firstStageCtrl.text.trim();
    if (title.isEmpty) return [];
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
