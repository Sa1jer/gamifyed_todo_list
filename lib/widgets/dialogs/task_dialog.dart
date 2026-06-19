part of '../dialogs.dart';

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
    Future<void> editXp() async {
      final value = await showIntegerEditDialog(
        context,
        title: 'XP за квест',
        initialValue: _xp,
        min: 5,
        max: 1000,
        color: color,
        isDark: isDark,
        suffix: 'XP',
      );
      if (value != null && mounted) {
        setState(() => _xp = value);
      }
    }

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
              PressFeedback(
                scale: 0.96,
                tooltip: 'Ввести XP числом',
                onTap: editXp,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withAlpha(48)),
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
