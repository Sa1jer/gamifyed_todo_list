part of '../dialogs.dart';

enum NextRoadmapChoice { keepCurrent, createNew, addStage }

class NextRoadmapPromptDialog extends StatelessWidget {
  final bool isDark;
  final Color color;

  const NextRoadmapPromptDialog({
    super.key,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = textColor(isDark);
    final secondary = subtext(isDark);

    return Dialog(
      backgroundColor: surface(isDark),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Следующая цель задана',
                      style: TextStyle(
                        color: text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8E8E93),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Начать новую карту? Старая карта не будет удалена. Что сделать дальше?',
                style: TextStyle(
                  color: secondary,
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 18 : 12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withAlpha(42)),
                ),
                child: Text(
                  '“Создать новую карту” сохранит текущие этапы в архив RoadMap и очистит активную карту для следующей цели.',
                  style: TextStyle(
                    color: text,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, NextRoadmapChoice.keepCurrent),
                    child: const Text('Оставить текущую карту'),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, NextRoadmapChoice.createNew),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_road, size: 18),
                    label: const Text('Создать новую карту'),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, NextRoadmapChoice.addStage),
                    style: FilledButton.styleFrom(
                      backgroundColor: color.withAlpha(isDark ? 80 : 36),
                      foregroundColor: isDark ? Colors.white : color,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Добавить этап'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NextGoalDialog extends StatefulWidget {
  final bool isDark;
  final Color color;
  final String currentGoal;

  const NextGoalDialog({
    super.key,
    required this.isDark,
    required this.color,
    required this.currentGoal,
  });

  @override
  State<NextGoalDialog> createState() => _NextGoalDialogState();
}

class _NextGoalDialogState extends State<NextGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final background = surface(isDark);
    final fieldBackground = isDark
        ? const Color(0xFF13131A)
        : const Color(0xFFF5F5F7);
    final text = textColor(isDark);
    final secondary = subtext(isDark);
    final border = borderColor(isDark);

    return Dialog(
      backgroundColor: background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Следующая цель',
                        style: TextStyle(
                          color: text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Закрыть',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF8E8E93),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Текущая цель',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.currentGoal.trim().isEmpty
                      ? 'Цель не была описана'
                      : widget.currentGoal,
                  key: const ValueKey('current-goal-copy'),
                  style: TextStyle(
                    color: text,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('next-goal-field'),
                  controller: _goalController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(color: text, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Новая цель',
                    labelStyle: TextStyle(color: secondary),
                    filled: true,
                    fillColor: fieldBackground,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.color, width: 1.4),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFF453A)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFF453A)),
                    ),
                  ),
                  validator: (value) {
                    final normalized = value?.trim() ?? '';
                    if (normalized.isEmpty) return 'Введите следующую цель';
                    if (normalized == widget.currentGoal.trim()) {
                      return 'Новая цель должна отличаться от текущей';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 10),
                Text(
                  'Текущая цель сохранится в истории. Этапы и квесты не будут удалены.',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Задать цель'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _submitting = true;
    Navigator.pop(context, _goalController.text.trim());
  }
}

class AddSkillDialog extends StatefulWidget {
  final bool isDark;
  final bool fullScreen;
  final Skill? existing;
  final bool showFirstRunHints;
  final SkillSaveCallback onSave;
  const AddSkillDialog({
    super.key,
    required this.isDark,
    this.fullScreen = false,
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
  bool _submitting = false;
  String? _nameError;

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
    final title = widget.existing != null
        ? 'Редактировать навык'
        : 'Новый навык';

    final form = SingleChildScrollView(
      key: const ValueKey('add-skill-form-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.fullScreen) ...[
            DlgHeader(title: title, txtColor: txt),
            const SizedBox(height: 16),
          ],
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
            fieldKey: const ValueKey('add-skill-name-field'),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          if (_nameError != null) ...[
            const SizedBox(height: 6),
            Text(
              _nameError!,
              key: const ValueKey('add-skill-name-error'),
              style: const TextStyle(
                color: Color(0xFFFF453A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          DlgField(
            label: 'Цель',
            ctrl: _goalCtrl,
            fBg: fBg,
            txt: txt,
            sub: sub,
            bdr: bdr,
            min: 2,
            fieldKey: const ValueKey('add-skill-goal-field'),
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
          if (!widget.fullScreen)
            DlgActions(
              onCancel: () => Navigator.pop(context),
              onSave: _save,
              saveLabel: widget.existing == null ? 'Создать' : 'Сохранить',
            ),
        ],
      ),
    );

    if (widget.fullScreen) {
      return MobileFormPage(
        pageKey: const ValueKey('mobile-add-skill-page'),
        saveKey: const ValueKey('mobile-add-skill-save'),
        title: title,
        backgroundColor: bg,
        accentColor: _color,
        onSave: _submitting ? null : _save,
        child: form,
      );
    }

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(width: 480, child: form),
    );
  }

  Future<void> _save() async {
    if (_submitting) return;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _nameError = 'Введите название навыка');
      return;
    }
    setState(() => _submitting = true);
    if (widget.fullScreen) {
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
    }
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
    if (mounted) Navigator.pop(context);
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
