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

enum _SkillIconCategory {
  all('Все'),
  body('Тело'),
  mind('Разум'),
  creativity('Творчество'),
  work('Работа'),
  home('Быт');

  final String label;

  const _SkillIconCategory(this.label);
}

class _SkillIconOption {
  final IconData icon;
  final String label;
  final _SkillIconCategory category;

  const _SkillIconOption(this.icon, this.label, this.category);
}

class _AddSkillDialogState extends State<AddSkillDialog> {
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _firstStageCtrl = TextEditingController();
  final List<String> _items = [];
  Color _color = const Color(0xFF4A9EFF);
  IconData _icon = Icons.fitness_center;
  bool _submitting = false;
  bool _allowPop = false;
  bool _discardDialogOpen = false;
  String? _nameError;
  late final String _initialDraftSignature;
  _SkillIconCategory _iconCategory = _SkillIconCategory.all;

  static const _curatedIconOptions = <_SkillIconOption>[
    _SkillIconOption(Icons.sports_martial_arts, 'Бой', _SkillIconCategory.body),
    _SkillIconOption(Icons.psychology, 'Разум', _SkillIconCategory.mind),
    _SkillIconOption(Icons.fitness_center, 'Тело', _SkillIconCategory.body),
    _SkillIconOption(Icons.favorite, 'Здоровье', _SkillIconCategory.body),
    _SkillIconOption(Icons.attach_money, 'Финансы', _SkillIconCategory.work),
    _SkillIconOption(Icons.business_center, 'Работа', _SkillIconCategory.work),
    _SkillIconOption(
      Icons.music_note,
      'Творчество',
      _SkillIconCategory.creativity,
    ),
    _SkillIconOption(Icons.public, 'Мир', _SkillIconCategory.mind),
    _SkillIconOption(
      Icons.favorite_border,
      'Отношения',
      _SkillIconCategory.home,
    ),
    _SkillIconOption(Icons.palette, 'Хобби', _SkillIconCategory.creativity),
    _SkillIconOption(Icons.flag_rounded, 'Цель', _SkillIconCategory.work),
    _SkillIconOption(Icons.adjust_rounded, 'Фокус', _SkillIconCategory.mind),
  ];

  static const _iconOptions = <_SkillIconOption>[
    _SkillIconOption(
      Icons.fitness_center,
      'Силовые тренировки',
      _SkillIconCategory.body,
    ),
    _SkillIconOption(Icons.code, 'Программирование', _SkillIconCategory.mind),
    _SkillIconOption(Icons.sports_esports, 'Игры', _SkillIconCategory.home),
    _SkillIconOption(Icons.menu_book, 'Чтение', _SkillIconCategory.mind),
    _SkillIconOption(Icons.music_note, 'Музыка', _SkillIconCategory.creativity),
    _SkillIconOption(Icons.palette, 'Рисование', _SkillIconCategory.creativity),
    _SkillIconOption(
      Icons.language,
      'Иностранные языки',
      _SkillIconCategory.mind,
    ),
    _SkillIconOption(Icons.science, 'Наука', _SkillIconCategory.mind),
    _SkillIconOption(Icons.directions_run, 'Бег', _SkillIconCategory.body),
    _SkillIconOption(Icons.psychology, 'Психология', _SkillIconCategory.mind),
    _SkillIconOption(Icons.attach_money, 'Финансы', _SkillIconCategory.work),
    _SkillIconOption(Icons.business_center, 'Карьера', _SkillIconCategory.work),
    _SkillIconOption(
      Icons.camera_alt,
      'Фотография',
      _SkillIconCategory.creativity,
    ),
    _SkillIconOption(Icons.school, 'Обучение', _SkillIconCategory.mind),
    _SkillIconOption(Icons.sports_soccer, 'Футбол', _SkillIconCategory.body),
    _SkillIconOption(Icons.flight, 'Путешествия', _SkillIconCategory.home),
    _SkillIconOption(Icons.favorite, 'Здоровье', _SkillIconCategory.body),
    _SkillIconOption(Icons.emoji_events, 'Достижения', _SkillIconCategory.work),
    _SkillIconOption(Icons.restaurant, 'Кулинария', _SkillIconCategory.home),
    _SkillIconOption(Icons.local_hospital, 'Медицина', _SkillIconCategory.body),
    _SkillIconOption(Icons.trending_up, 'Рост', _SkillIconCategory.work),
    _SkillIconOption(
      Icons.self_improvement,
      'Медитация',
      _SkillIconCategory.body,
    ),
    _SkillIconOption(Icons.star, 'Личное мастерство', _SkillIconCategory.work),
    _SkillIconOption(Icons.public, 'Мир и культура', _SkillIconCategory.mind),
    _SkillIconOption(Icons.home, 'Дом', _SkillIconCategory.home),
    _SkillIconOption(Icons.shopping_cart, 'Покупки', _SkillIconCategory.home),
    _SkillIconOption(Icons.pets, 'Питомцы', _SkillIconCategory.home),
    _SkillIconOption(Icons.nature, 'Природа', _SkillIconCategory.home),
    _SkillIconOption(Icons.sports_tennis, 'Теннис', _SkillIconCategory.body),
    _SkillIconOption(
      Icons.sports_basketball,
      'Баскетбол',
      _SkillIconCategory.body,
    ),
    _SkillIconOption(
      Icons.directions_bike,
      'Велоспорт',
      _SkillIconCategory.body,
    ),
    _SkillIconOption(Icons.pool, 'Плавание', _SkillIconCategory.body),
    _SkillIconOption(
      Icons.laptop_mac,
      'Компьютерная работа',
      _SkillIconCategory.work,
    ),
    _SkillIconOption(
      Icons.phone_android,
      'Мобильные технологии',
      _SkillIconCategory.work,
    ),
    _SkillIconOption(Icons.headphones, 'Аудио', _SkillIconCategory.creativity),
    _SkillIconOption(Icons.tv, 'Видео', _SkillIconCategory.creativity),
    _SkillIconOption(
      Icons.local_florist,
      'Цветоводство',
      _SkillIconCategory.home,
    ),
    _SkillIconOption(Icons.eco, 'Экология', _SkillIconCategory.home),
    _SkillIconOption(Icons.park, 'Садоводство', _SkillIconCategory.home),
    _SkillIconOption(Icons.beach_access, 'Отдых', _SkillIconCategory.home),
    _SkillIconOption(Icons.spa, 'Восстановление', _SkillIconCategory.body),
    _SkillIconOption(Icons.hiking, 'Походы', _SkillIconCategory.body),
    _SkillIconOption(Icons.bolt, 'Энергия', _SkillIconCategory.body),
    _SkillIconOption(Icons.water_drop, 'Водный режим', _SkillIconCategory.body),
    _SkillIconOption(Icons.wb_sunny, 'Дневной режим', _SkillIconCategory.home),
    _SkillIconOption(Icons.nightlight_round, 'Сон', _SkillIconCategory.body),
    _SkillIconOption(
      Icons.cloud,
      'Облачные технологии',
      _SkillIconCategory.work,
    ),
    _SkillIconOption(Icons.recycling, 'Переработка', _SkillIconCategory.home),
    _SkillIconOption(Icons.biotech, 'Биология', _SkillIconCategory.mind),
    _SkillIconOption(Icons.agriculture, 'Земледелие', _SkillIconCategory.home),
    _SkillIconOption(
      Icons.volunteer_activism,
      'Волонтёрство',
      _SkillIconCategory.home,
    ),
    _SkillIconOption(Icons.construction, 'Ремесло', _SkillIconCategory.work),
    _SkillIconOption(
      Icons.auto_fix_high,
      'Дизайн',
      _SkillIconCategory.creativity,
    ),
    _SkillIconOption(Icons.brush, 'Живопись', _SkillIconCategory.creativity),
    _SkillIconOption(Icons.calculate, 'Математика', _SkillIconCategory.mind),
    _SkillIconOption(Icons.translate, 'Перевод', _SkillIconCategory.mind),
    _SkillIconOption(Icons.history_edu, 'История', _SkillIconCategory.mind),
    _SkillIconOption(
      Icons.sports_martial_arts,
      'Боевые искусства',
      _SkillIconCategory.body,
    ),
    _SkillIconOption(Icons.sailing, 'Парусный спорт', _SkillIconCategory.body),
    _SkillIconOption(Icons.snowboarding, 'Сноуборд', _SkillIconCategory.body),
  ];
  static const _colorLabels = <String>[
    'Алый',
    'Коралловый',
    'Янтарный',
    'Золотой',
    'Лаймовый',
    'Зелёный',
    'Бирюзовый',
    'Голубой',
    'Синий',
    'Индиго',
    'Фиолетовый',
    'Серый',
  ];

  List<_SkillIconOption> get _visibleIconOptions {
    if (_iconCategory != _SkillIconCategory.all) {
      return _iconOptions
          .where((option) => option.category == _iconCategory)
          .toList(growable: false);
    }
    if (_curatedIconOptions.any((option) => option.icon == _icon)) {
      return _curatedIconOptions;
    }
    final selected = _iconOptions.where((option) => option.icon == _icon);
    if (selected.isEmpty) return _curatedIconOptions;
    return [selected.first, ..._curatedIconOptions.take(11)];
  }

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

  String get _draftSignature => jsonEncode({
    'name': _nameCtrl.text,
    'goal': _goalCtrl.text,
    'firstStage': _firstStageCtrl.text,
    'checklist': _items,
    'color': _color.toARGB32(),
    'icon': _icon.codePoint,
  });

  bool get _isDirty => _draftSignature != _initialDraftSignature;

  void _refreshDraft() {
    if (mounted) setState(() {});
  }

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
    _initialDraftSignature = _draftSignature;
    _nameCtrl.addListener(_refreshDraft);
    _goalCtrl.addListener(_refreshDraft);
    _firstStageCtrl.addListener(_refreshDraft);
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
    final bg = widget.fullScreen
        ? MobileJournalTokens.background(isDark)
        : surface(isDark);
    final fBg = widget.fullScreen
        ? MobileJournalTokens.questRow(isDark)
        : isDark
        ? const Color(0xFF13131A)
        : const Color(0xFFF5F5F7);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final title = widget.existing != null
        ? 'Редактировать навык'
        : 'Новый навык';
    final iconOptions = widget.fullScreen ? _visibleIconOptions : _iconOptions;

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
          if (widget.fullScreen)
            _MobileSkillEmblemPreview(
              icon: _icon,
              color: _color,
              name: _nameCtrl.text,
              isDark: isDark,
            )
          else
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
          if (widget.fullScreen) ...[
            _MobileSkillFormSection(
              title: 'Название навыка',
              subtitle: '',
              isDark: isDark,
            ),
            const SizedBox(height: 9),
          ],
          DlgField(
            label: 'Название навыка',
            hintText: widget.fullScreen
                ? 'Коротко назови направление, в котором хочешь расти.'
                : null,
            showLabel: !widget.fullScreen,
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
          SizedBox(height: widget.fullScreen ? 18 : 10),
          if (widget.fullScreen) ...[
            _MobileSkillFormSection(
              title: 'Цель',
              subtitle: '',
              isDark: isDark,
            ),
            const SizedBox(height: 9),
          ],
          DlgField(
            label: 'Цель',
            hintText: widget.fullScreen
                ? 'Цель поможет понять, к чему ведёт путь.'
                : null,
            showLabel: !widget.fullScreen,
            ctrl: _goalCtrl,
            fBg: fBg,
            txt: txt,
            sub: sub,
            bdr: bdr,
            min: 2,
            fieldKey: const ValueKey('add-skill-goal-field'),
          ),
          if (widget.fullScreen) ...[
            const SizedBox(height: 7),
            Text(
              'Можно уточнить цель позже — она не обязана быть идеальной с первого раза.',
              style: TextStyle(
                color: sub,
                fontSize: 11.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
          if (widget.fullScreen) ...[
            _MobileSkillFormSection(
              title: 'Внешний вид',
              subtitle: 'Цвет связывает навык с квестами и RoadMap.',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              SubLbl('Иконка', sub),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.fullScreen
                      ? '${iconOptions.length} вариантов · категории расширяют выбор'
                      : '${_iconOptions.length} иконок · прокрутите',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: sub, fontSize: 11),
                ),
              ),
            ],
          ),
          if (widget.fullScreen) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _SkillIconCategory.values.map((category) {
                  final selected = category == _iconCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      key: ValueKey('skill-icon-category-${category.name}'),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _iconCategory = category),
                      label: Text(category.label),
                      showCheckmark: false,
                      selectedColor: _color.withAlpha(isDark ? 38 : 22),
                      side: BorderSide(
                        color: selected ? _color.withAlpha(130) : bdr,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? _color : sub,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            height: widget.fullScreen ? 158 : _gridHeight,
            decoration: BoxDecoration(
              color: fBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bdr),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = widget.fullScreen ? 6 : _crossAxisCount;
                return GridView.builder(
                  key: const ValueKey('skill-icon-grid'),
                  padding: const EdgeInsets.all(_spacing),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: _spacing,
                    crossAxisSpacing: _spacing,
                    childAspectRatio: widget.fullScreen ? 0.72 : 1,
                  ),
                  itemCount: iconOptions.length,
                  itemBuilder: (_, i) {
                    final option = iconOptions[i];
                    final sel = option.icon == _icon;
                    return _IconChoiceButton(
                      icon: option.icon,
                      selected: sel,
                      color: _color,
                      inactiveColor: sub,
                      mobile: widget.fullScreen,
                      semanticsLabel: option.label,
                      displayLabel: widget.fullScreen ? option.label : null,
                      onTap: () => setState(() => _icon = option.icon),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          SubLbl('Цвет', sub),
          const SizedBox(height: 8),
          if (widget.fullScreen)
            GridView.builder(
              key: const ValueKey('skill-color-grid'),
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: kColors.length,
              itemBuilder: (context, i) {
                final color = kColors[i];
                return Center(
                  key: ValueKey('skill-color-$i'),
                  child: _ColorChoiceButton(
                    color: color,
                    selected: color == _color,
                    isDark: isDark,
                    mobile: true,
                    semanticsLabel: _colorLabels[i],
                    onTap: () => setState(() => _color = color),
                  ),
                );
              },
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kColors.asMap().entries.map((entry) {
                final i = entry.key;
                final color = entry.value;
                return KeyedSubtree(
                  key: ValueKey('skill-color-$i'),
                  child: _ColorChoiceButton(
                    color: color,
                    selected: color == _color,
                    isDark: isDark,
                    semanticsLabel: _colorLabels[i],
                    onTap: () => setState(() => _color = color),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),

          if (widget.existing == null) ...[
            if (widget.fullScreen) ...[
              const SizedBox(height: 4),
              _MobileSkillFormSection(
                title: 'Первый этап',
                subtitle:
                    'Можно оставить пустым и собрать дорожную карту позже.',
                isDark: isDark,
              ),
              const SizedBox(height: 9),
            ],
            DlgField(
              label: widget.fullScreen
                  ? 'Название первого этапа (необязательно)'
                  : 'Первый этап (опционально)',
              ctrl: _firstStageCtrl,
              fBg: fBg,
              txt: txt,
              sub: sub,
              bdr: bdr,
            ),
            const SizedBox(height: 6),
            Text(
              widget.fullScreen
                  ? 'Например: «Основа» или «Первая неделя практики».'
                  : 'Например: «Основа». Можно оставить пустым и собрать дорожную карту позже.',
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
              saveLabel: widget.existing == null
                  ? 'Создать'
                  : 'Сохранить изменения',
            ),
        ],
      ),
    );

    if (widget.fullScreen) {
      return PopScope(
        canPop: _submitting || _allowPop || !_isDirty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_requestClose());
        },
        child: MobileFormPage(
          pageKey: const ValueKey('mobile-add-skill-page'),
          saveKey: const ValueKey('mobile-add-skill-save'),
          title: title,
          backgroundColor: bg,
          accentColor: _color,
          titleStyle: MobileJournalTokens.textTheme(
            context,
            isDark,
          ).headlineSmall,
          onSave: _submitting ? null : _save,
          onCancel: () => unawaited(_requestClose()),
          showTopSaveAction: false,
          bottomAction: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              key: const ValueKey('mobile-add-skill-bottom-save'),
              onPressed: _submitting ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _color,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: Icon(
                widget.existing == null
                    ? Icons.auto_awesome_rounded
                    : Icons.save_rounded,
                size: 19,
              ),
              label: Text(
                widget.existing == null
                    ? 'Создать навык'
                    : 'Сохранить изменения',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          child: form,
        ),
      );
    }

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(width: 480, child: form),
    );
  }

  Future<void> _requestClose() async {
    if (!mounted) return;
    if (_submitting || _allowPop || !_isDirty) {
      Navigator.pop(context);
      return;
    }
    if (_discardDialogOpen) return;
    _discardDialogOpen = true;
    final discard = await showDiscardMobileFormDialog(
      context,
      isDark: widget.isDark,
    );
    _discardDialogOpen = false;
    if (!mounted || !discard) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
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

class _MobileSkillEmblemPreview extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final bool isDark;

  const _MobileSkillEmblemPreview({
    required this.icon,
    required this.color,
    required this.name,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MobileMotion.reduced(
      context,
      appReducedMotion:
          AppStateProvider.maybeOf(context)?.reducedMotion ?? false,
    );
    final displayName = name.trim().isEmpty ? 'Твой новый навык' : name.trim();

    return Center(
      child: Column(
        children: [
          AnimatedContainer(
            key: const ValueKey('skill-preview-icon'),
            duration: reduceMotion ? Duration.zero : kMotionSlow,
            curve: kMotionCurve,
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 24 : 16),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: color.withAlpha(150), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(isDark ? 46 : 30),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : kMotionStandard,
              child: Icon(
                icon,
                key: ValueKey(icon.codePoint),
                color: color,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : kMotionStandard,
            child: Text(
              displayName,
              key: ValueKey(displayName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: name.trim().isEmpty
                    ? subtext(isDark)
                    : textColor(isDark),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSkillFormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _MobileSkillFormSection({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle.isNotEmpty;
    return Column(
      key: ValueKey('mobile-skill-section-$title'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor(isDark),
            fontSize: hasSubtitle ? 14.5 : 15.5,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (hasSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: subtext(isDark),
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SKILL TREE DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
