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
  late final TaskFormController _form;
  bool _submitting = false;
  bool _allowPop = false;
  bool _discardDialogOpen = false;
  String? _titleError;

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
        _form.treeNodeId != null) {
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

  void _refreshDraft() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _form = TaskFormController(
      existing: widget.existing,
      initialTitle: widget.initialTitle,
      initialMinimumAction: widget.initialMinimumAction,
      initialTreeNodeId: widget.initialTreeNodeId,
      focusMinimumAction: widget.focusMinimumAction,
    );
    _form.addListener(_refreshDraft);
    if (widget.focusMinimumAction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _form.minimumActionFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _form.removeListener(_refreshDraft);
    _form.dispose();
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
    final desktopDialogHeight = (MediaQuery.sizeOf(context).height - 48)
        .clamp(560.0, 780.0)
        .toDouble();

    final form = SingleChildScrollView(
      key: const ValueKey('add-task-form-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_initialStage case final stage?) ...[
            TaskStageContextCard(
              stage: stage,
              textColor: txt,
              subtextColor: sub,
              accent: c,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
          ] else if (_suggestedStage case final stage?) ...[
            TaskStageSuggestionCard(
              stage: stage,
              textColor: txt,
              subtextColor: sub,
              borderColor: bdr,
              accent: c,
              isDark: isDark,
              onLink: () => setState(() {
                _form.treeNodeId = stage.id;
                _form.advancedExpanded = true;
              }),
            ),
            const SizedBox(height: 14),
          ],
          DlgField(
            label: 'Название квеста',
            hintText: 'Создай задачу, которую хочешь реализовать.',
            ctrl: _form.title,
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
          DlgField(
            label: 'Описание · необязательно',
            hintText: 'Что важно помнить про этот квест?',
            ctrl: _form.description,
            fBg: fBg,
            txt: txt,
            sub: sub,
            bdr: bdr,
            min: widget.fullScreen ? 3 : 2,
            max: widget.fullScreen ? 8 : 6,
            fieldKey: const ValueKey('add-task-description-field'),
          ),
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
          TaskXpSection(
            xp: _form.xp,
            selectorValue: _form.xpSelectorValue,
            softCap: _form.softCap,
            taskTypeLabel: typeLabel[_form.type] ?? _form.type.name,
            overCap: _form.isOverSoftCap,
            subtextColor: sub,
            borderColor: bdr,
            isDark: isDark,
            onChanged: (value) =>
                setState(() => _form.xp = _form.normalizeXp(value)),
          ),
          const SizedBox(height: 16),
          _buildAdvancedSection(fBg, txt, sub, bdr, c, isDark),
          const SizedBox(height: 22),
        ],
      ),
    );

    if (widget.fullScreen) {
      return PopScope(
        canPop: _submitting || _allowPop || !_form.isDirty,
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
      key: const ValueKey('desktop-add-task-dialog'),
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 720,
        height: desktopDialogHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 14),
              child: DlgHeader(title: title, txtColor: txt),
            ),
            Divider(height: 1, color: bdr),
            Expanded(child: form),
            Divider(height: 1, color: bdr),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: Align(
                alignment: Alignment.centerRight,
                child: DlgActions(
                  onCancel: () => Navigator.pop(context),
                  onSave: _save,
                  saveLabel: widget.existing == null
                      ? 'Создать'
                      : 'Сохранить изменения',
                  saveColor: c,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestClose() async {
    if (!mounted) return;
    if (_submitting || _allowPop || !_form.isDirty) {
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
            expanded: _form.advancedExpanded,
            color: color,
            txt: txt,
            sub: sub,
            onTap: () => setState(
              () => _form.advancedExpanded = !_form.advancedExpanded,
            ),
          ),
          MotionExpandable(
            expanded: _form.advancedExpanded,
            expandedChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBehaviorSection(fBg, txt, sub, bdr, color, isDark),
                  const SizedBox(height: 10),
                  TaskMinimumActionSection(
                    enabled: _form.minimumActionEnabled,
                    controller: _form.minimumAction,
                    focusNode: _form.minimumActionFocusNode,
                    fieldBackground: fBg,
                    textColor: txt,
                    subtextColor: sub,
                    borderColor: bdr,
                    accent: color,
                    isDark: isDark,
                    onEnabledChanged: (value) =>
                        setState(() => _form.minimumActionEnabled = value),
                    onTextChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  if (widget.skill?.treeNodes.isNotEmpty ?? false) ...[
                    _buildTreeNodeSection(fBg, txt, sub, bdr, color, isDark),
                    const SizedBox(height: 10),
                  ],
                  if (_form.showBigQuestTools) ...[
                    _buildTextListEditor(
                      title: 'Большой квест',
                      hint: '+ Добавить шаг',
                      items: _form.subtasks,
                      ctrl: _form.subtask,
                      color: color,
                      txt: txt,
                      sub: sub,
                      bdr: bdr,
                      expanded: _form.subtasksExpanded,
                      onToggle: () => setState(
                        () => _form.subtasksExpanded = !_form.subtasksExpanded,
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
              final selected = _form.type == type;
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
                onTap: () => setState(() => _form.type = type),
              );
            }).toList(),
          ),
          MotionExpandable(
            expanded: _form.type == TaskType.repeating,
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
                          final selected = _form.frequency == freq;
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
                            onTap: () => setState(() => _form.frequency = freq),
                          );
                        })
                        .toList(),
                  ),
                  MotionExpandable(
                    expanded: _form.frequency == RepeatFrequency.custom,
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
                              controller: _form.customDays,
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
                      value: _form.notificationsEnabled,
                      activeThumbColor: color,
                      onChanged: (value) =>
                          setState(() => _form.notificationsEnabled = value),
                    ),
                  ],
                ),
                MotionExpandable(
                  expanded: _form.notificationsEnabled,
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
                              'Время: ${_formatTimeOfDay(_form.notificationTime)}',
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
    final selectedNodeExists = nodes.any((node) => node.id == _form.treeNodeId);
    final selectedNodeId = selectedNodeExists ? _form.treeNodeId : null;

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
                onTap: () => setState(() => _form.treeNodeId = null),
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
                  onTap: () => setState(() => _form.treeNodeId = node.id),
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
      initialTime: _form.notificationTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _form.notificationTime = picked);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _save() async {
    if (_submitting) return;
    if (_form.title.text.trim().isEmpty) {
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
      _form.title.text.trim(),
      _form.description.text.trim(),
      _form.xp,
      _form.type,
      _form.frequency,
      _form.customDayCount,
      _form.priority,
      _form.minimumActionEnabled ? _form.minimumAction.text.trim() : '',
      List.of(_form.subtasks),
      List.of(_form.tags),
      _form.notificationsEnabled,
      _form.notificationsEnabled ? _form.notificationTime.hour : null,
      _form.notificationsEnabled ? _form.notificationTime.minute : null,
      _form.treeNodeId,
    );
    if (mounted) Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATISTICS DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
