part of '../dialogs.dart';

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
