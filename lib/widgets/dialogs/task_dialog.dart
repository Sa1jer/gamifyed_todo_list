part of '../dialogs.dart';

class AddTaskDialog extends StatefulWidget {
  final bool isDark;
  final bool fullScreen;
  final Color skillColor;
  final Skill? skill;
  final String? initialTreeNodeId;
  final String? initialTitle;
  final String? initialMinimumAction;
  final bool focusMinimumAction;
  final bool showFirstRunHints;
  final Task? existing;
  final Function(
    String title,
    String description,
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
    this.fullScreen = false,
    required this.skillColor,
    this.skill,
    this.initialTreeNodeId,
    this.initialTitle,
    this.initialMinimumAction,
    this.focusMinimumAction = false,
    this.showFirstRunHints = false,
    this.existing,
    required this.onSave,
  });
  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _minimumActionCtrl = TextEditingController();
  final _minimumActionFocusNode = FocusNode();
  final _customCtrl = TextEditingController(text: '1');
  final _subtaskCtrl = TextEditingController();
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
  bool _subtasksExpanded = false;
  bool _submitting = false;
  bool _allowPop = false;
  bool _discardDialogOpen = false;
  String? _titleError;
  late final String _initialDraftSignature;

  String get _draftSignature => jsonEncode({
    'title': _titleCtrl.text,
    'description': _descriptionCtrl.text,
    'minimumAction': _minimumActionCtrl.text,
    'minimumEnabled': _minimumActionEnabled,
    'xp': _xp,
    'type': _type.name,
    'frequency': _freq.name,
    'customDays': _customCtrl.text,
    'priority': _priority.name,
    'subtasks': _subtasks,
    'tags': _tags,
    'treeNodeId': _treeNodeId,
    'notificationsEnabled': _notificationsEnabled,
    'notificationHour': _notificationTime.hour,
    'notificationMinute': _notificationTime.minute,
  });

  bool get _isDirty => _draftSignature != _initialDraftSignature;

  int get _softCap => typeSoftCap[_type]!;
  bool get _overCap => _xp > _softCap;
  bool get _showBigQuestTools =>
      _type == TaskType.midTerm ||
      _type == TaskType.longTerm ||
      _subtasks.isNotEmpty;

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

  int get _xpSelectorValue {
    final clamped = _xp.clamp(10, 500);
    return (((clamped + 5) ~/ 10) * 10).clamp(10, 500);
  }

  int _normalizeXp(int value) {
    final clamped = value.clamp(10, 500);
    return (((clamped + 5) ~/ 10) * 10).clamp(10, 500);
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
      _descriptionCtrl.text = ex.description;
      _minimumActionCtrl.text = ex.minimumAction;
      _minimumActionEnabled =
          ex.minimumAction.trim().isNotEmpty || widget.focusMinimumAction;
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
          ex.subtasks.isNotEmpty ||
          ex.treeNodeId != null ||
          _minimumActionEnabled;
      _subtasksExpanded = ex.subtasks.isNotEmpty;
      if (ex.notificationHour != null && ex.notificationMinute != null) {
        _notificationTime = TimeOfDay(
          hour: ex.notificationHour!,
          minute: ex.notificationMinute!,
        );
      }
    } else {
      final initialTitle = widget.initialTitle?.trim();
      final initialMinimum = widget.initialMinimumAction?.trim();
      if (initialTitle != null && initialTitle.isNotEmpty) {
        _titleCtrl.text = initialTitle;
      }
      if (initialMinimum != null && initialMinimum.isNotEmpty) {
        _minimumActionCtrl.text = initialMinimum;
      }
      _treeNodeId = widget.initialTreeNodeId;
      _minimumActionEnabled =
          _minimumActionCtrl.text.trim().isNotEmpty ||
          widget.focusMinimumAction;
      _advancedExpanded = _minimumActionEnabled;
    }
    _initialDraftSignature = _draftSignature;
    _titleCtrl.addListener(_refreshDraft);
    _descriptionCtrl.addListener(_refreshDraft);
    _minimumActionCtrl.addListener(_refreshDraft);
    _customCtrl.addListener(_refreshDraft);
    if (widget.focusMinimumAction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _minimumActionFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _minimumActionCtrl.dispose();
    _minimumActionFocusNode.dispose();
    _customCtrl.dispose();
    _subtaskCtrl.dispose();
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
    final c = widget.skillColor;
    final title = widget.existing != null
        ? 'Редактировать квест'
        : 'Новый квест';

    final form = SingleChildScrollView(
      key: const ValueKey('add-task-form-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.fullScreen) ...[
            DlgHeader(title: title, txtColor: txt),
            const SizedBox(height: 16),
          ],
          if (_initialStage case final stage?) ...[
            _buildStageContextCard(stage, txt, sub, bdr, c, isDark),
            const SizedBox(height: 14),
          ] else if (_suggestedStage case final stage?) ...[
            _buildStageSuggestionCard(stage, txt, sub, bdr, c, isDark),
            const SizedBox(height: 14),
          ],
          DlgField(
            label: 'Название квеста',
            hintText: 'Создай задачу, которую хочешь реализовать.',
            ctrl: _titleCtrl,
            fBg: fBg,
            txt: txt,
            sub: sub,
            bdr: bdr,
            fieldKey: const ValueKey('add-task-title-field'),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          if (_titleError != null) ...[
            const SizedBox(height: 6),
            Text(
              _titleError!,
              key: const ValueKey('add-task-title-error'),
              style: const TextStyle(
                color: Color(0xFFFF453A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildDescriptionSection(fBg, txt, sub, bdr),
          const SizedBox(height: 16),
          if (widget.showFirstRunHints && widget.existing == null) ...[
            FirstRunDialogHint(
              text:
                  'Квест — одно конкретное действие. Минимальный шаг можно включить вручную, если нужен лёгкий старт.',
              color: c,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ],
          _buildXpSection(sub, bdr, c, isDark),
          const SizedBox(height: 16),
          _buildAdvancedSection(fBg, txt, sub, bdr, c, isDark),
          const SizedBox(height: 22),
          if (!widget.fullScreen)
            DlgActions(
              onCancel: () => Navigator.pop(context),
              onSave: _save,
              saveLabel: widget.existing == null
                  ? 'Создать'
                  : 'Сохранить изменения',
              saveColor: c,
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
          pageKey: const ValueKey('mobile-add-task-page'),
          saveKey: const ValueKey('mobile-add-task-save'),
          title: title,
          backgroundColor: bg,
          accentColor: c,
          onSave: _submitting ? null : _save,
          saveLabel: widget.existing == null
              ? 'Создать'
              : 'Сохранить изменения',
          onCancel: () => unawaited(_requestClose()),
          child: form,
        ),
      );
    }

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(width: 460, child: form),
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
                  'Этап дорожной карты: ${stage.title}',
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
                  'Этот квест двигает выбранный этап RoadMap.',
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
                  'Можно связать квест с текущей ступенью RoadMap.',
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
                key: const ValueKey('minimum-action-toggle'),
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
                focusNode: _minimumActionFocusNode,
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
        min: 10,
        max: 500,
        color: MobileJournalTokens.rewardGoldForeground(isDark),
        isDark: isDark,
        suffix: 'XP',
      );
      if (value != null && mounted) {
        setState(() => _xp = _normalizeXp(value));
      }
    }

    final rewardColor = MobileJournalTokens.rewardGoldForeground(isDark);
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
                    color: MobileJournalTokens.rewardGoldBackground(isDark),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: MobileJournalTokens.rewardGoldBorder(isDark),
                    ),
                  ),
                  child: Text(
                    '$_xp XP',
                    style: TextStyle(
                      color: rewardColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _xpSelectorValue.toDouble(),
            min: 10,
            max: 500,
            divisions: 49,
            activeColor: rewardColor,
            inactiveColor: rewardColor.withAlpha(40),
            onChanged: (v) => setState(() => _xp = _normalizeXp(v.round())),
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

  Widget _buildDescriptionSection(Color fBg, Color txt, Color sub, Color bdr) {
    return DlgField(
      label: 'Описание · необязательно',
      hintText: 'Что важно помнить про этот квест?',
      ctrl: _descriptionCtrl,
      fBg: fBg,
      txt: txt,
      sub: sub,
      bdr: bdr,
      min: widget.fullScreen ? 3 : 2,
      max: widget.fullScreen ? 8 : 6,
      fieldKey: const ValueKey('add-task-description-field'),
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
                  _buildMinimumActionSection(fBg, txt, sub, bdr, color),
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
                ],
              ),
            ),
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
                      'Поведение квеста',
                      style: TextStyle(
                        color: txt,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Тип, ритм и напоминание',
                      style: TextStyle(color: sub, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SubLbl('Тип квеста', sub),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: TaskType.values.map((type) {
              final selected = _type == type;
              return _DialogChoiceChip(
                label: typeLabel[type]!,
                color: typeColor[type]!,
                selected: selected,
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
                onTap: () => setState(() => _type = type),
              );
            }).toList(),
          ),
          MotionExpandable(
            expanded: _type == TaskType.repeating,
            expandedChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SubLbl('Повторяемость', sub),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: RepeatFrequency.values
                        .where(
                          (freq) =>
                              widget.existing != null ||
                              freq != RepeatFrequency.every3Days,
                        )
                        .map((freq) {
                          final selected = _freq == freq;
                          return _DialogChoiceChip(
                            label: freqLabel[freq]!,
                            color: color,
                            selected: selected,
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
                            onTap: () => setState(() => _freq = freq),
                          );
                        })
                        .toList(),
                  ),
                  MotionExpandable(
                    expanded: _freq == RepeatFrequency.custom,
                    expandedChild: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Text(
                            'Каждые',
                            style: TextStyle(color: txt, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 64,
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
                                  borderSide: BorderSide(color: color),
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
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Риск сброса будет считаться по этому ритму.',
                    style: TextStyle(color: sub, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bdr.withAlpha(170)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: sub,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Напоминание',
                        style: TextStyle(
                          color: txt,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      activeThumbColor: color,
                      onChanged: (value) =>
                          setState(() => _notificationsEnabled = value),
                    ),
                  ],
                ),
                MotionExpandable(
                  expanded: _notificationsEnabled,
                  expandedChild: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: PressFeedback(
                      scale: 0.98,
                      tooltip: 'Выбрать время напоминания',
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
              ],
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
                      'Этап в дорожной карте',
                      style: TextStyle(
                        color: txt,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'К какому этапу RoadMap относится квест?',
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
            icon: Icons.checklist,
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

  Future<void> _save() async {
    if (_submitting) return;
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = 'Введите название квеста');
      return;
    }
    setState(() => _submitting = true);
    if (widget.fullScreen) {
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
    }
    widget.onSave(
      _titleCtrl.text.trim(),
      _descriptionCtrl.text.trim(),
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
    if (mounted) Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATISTICS DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
