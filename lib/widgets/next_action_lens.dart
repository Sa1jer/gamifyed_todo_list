import 'package:flutter/material.dart';

import '../engines/next_action_resolver.dart';
import '../models.dart';
import '../persistence_status.dart';
import 'mobile_journal_tokens.dart';

class NextActionLens extends StatefulWidget {
  const NextActionLens({
    super.key,
    required this.resolution,
    required this.persistenceStatus,
    required this.isDark,
    required this.onOpenTask,
    required this.onChooseTask,
    required this.onOpenEmptySkill,
    required this.onCreateSkill,
  });

  final NextActionResolution resolution;
  final PersistenceStatus persistenceStatus;
  final bool isDark;
  final ValueChanged<NextActionCandidate> onOpenTask;
  final ValueChanged<String> onChooseTask;
  final ValueChanged<Skill> onOpenEmptySkill;
  final VoidCallback onCreateSkill;

  @override
  State<NextActionLens> createState() => _NextActionLensState();
}

class _NextActionLensState extends State<NextActionLens> {
  BootEntryPlan? _bootEntry;
  String? _completedBootTaskId;
  final Set<int> _checkedBootSteps = <int>{};

  @override
  void didUpdateWidget(covariant NextActionLens oldWidget) {
    super.didUpdateWidget(oldWidget);
    final taskId = widget.resolution.candidate?.task.id;
    if (taskId != oldWidget.resolution.candidate?.task.id) {
      _bootEntry = null;
      _completedBootTaskId = null;
      _checkedBootSteps.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked =
        widget.persistenceStatus.blocksSaving ||
        widget.persistenceStatus.phase == PersistencePhase.loading ||
        widget.persistenceStatus.phase == PersistencePhase.recovering;
    if (blocked) return _RecoveryLensCard(isDark: widget.isDark);

    final candidate = widget.resolution.candidate;
    if (candidate == null) {
      return _EmptyNextActionLens(
        resolution: widget.resolution,
        isDark: widget.isDark,
        onCreateSkill: widget.onCreateSkill,
        onOpenSkill: () {
          final skill = widget.resolution.suggestedSkill;
          if (skill == null) return;
          widget.onOpenEmptySkill(skill);
        },
      );
    }

    final activeBoot = _bootEntry;
    if (activeBoot != null) {
      return _BootEntryActiveCard(
        plan: activeBoot,
        isDark: widget.isDark,
        checkedSteps: _checkedBootSteps,
        onToggleStep: (index) => setState(() {
          if (!_checkedBootSteps.add(index)) _checkedBootSteps.remove(index);
        }),
        onEdit: () => _editBootEntry(candidate, activeBoot),
        onDismiss: () => setState(() {
          _bootEntry = null;
          _checkedBootSteps.clear();
        }),
        onComplete: () => setState(() {
          _completedBootTaskId = candidate.task.id;
          _bootEntry = null;
          _checkedBootSteps.clear();
        }),
      );
    }

    if (_completedBootTaskId == candidate.task.id) {
      return _BootEntryCompleteCard(
        candidate: candidate,
        isDark: widget.isDark,
        onOpenTask: () => widget.onOpenTask(candidate),
        onCreateAnother: () =>
            _editBootEntry(candidate, BootEntryPlan.suggest(candidate.task)),
      );
    }

    return _NextActionCard(
      candidate: candidate,
      isDark: widget.isDark,
      onOpenTask: () => widget.onOpenTask(candidate),
      onChooseTask: () => _pickTask(candidate),
      onBootEntry: () =>
          _editBootEntry(candidate, BootEntryPlan.suggest(candidate.task)),
    );
  }

  Future<void> _pickTask(NextActionCandidate current) async {
    final choice = await showModalBottomSheet<NextActionCandidate>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _NextActionPickerSheet(
        current: current,
        candidates: widget.resolution.alternatives,
        isDark: widget.isDark,
      ),
    );
    if (!mounted || choice == null) return;
    widget.onChooseTask(choice.task.id);
  }

  Future<void> _editBootEntry(
    NextActionCandidate candidate,
    BootEntryPlan initialPlan,
  ) async {
    final plan = await showModalBottomSheet<BootEntryPlan>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BootEntryEditorSheet(
        candidate: candidate,
        initialPlan: initialPlan,
        isDark: widget.isDark,
      ),
    );
    if (!mounted || plan == null) return;
    setState(() {
      _bootEntry = plan;
      _completedBootTaskId = null;
      _checkedBootSteps.clear();
    });
  }
}

class _NextActionCard extends StatelessWidget {
  const _NextActionCard({
    required this.candidate,
    required this.isDark,
    required this.onOpenTask,
    required this.onChooseTask,
    required this.onBootEntry,
  });

  final NextActionCandidate candidate;
  final bool isDark;
  final VoidCallback onOpenTask;
  final VoidCallback onChooseTask;
  final VoidCallback onBootEntry;

  @override
  Widget build(BuildContext context) {
    final accent = MobileJournalTokens.readableAccent(
      candidate.skill.color,
      isDark,
    );
    final text = MobileJournalTokens.text(isDark);
    final muted = MobileJournalTokens.muted(isDark);
    return Semantics(
      container: true,
      label:
          'Следующее действие: ${candidate.actionText}. ${candidate.skill.name}',
      child: Container(
        key: const ValueKey('next-action-lens'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            candidate.skill.color.withAlpha(isDark ? 18 : 14),
            MobileJournalTokens.raised(isDark),
          ),
          borderRadius: BorderRadius.circular(MobileJournalTokens.radiusMedium),
          border: Border.all(
            color: MobileJournalTokens.skillAccentBorder(
              candidate.skill.color,
              isDark,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  color: accent,
                  size: 21,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Следующее действие',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _ReasonChip(
              reason: candidate.reason,
              color: accent,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            Text(
              candidate.actionText,
              key: const ValueKey('next-action-title'),
              style: TextStyle(
                color: text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              candidate.usesMinimumAction
                  ? 'Минимальный шаг к квесту «${candidate.task.title}»'
                  : candidate.skill.name,
              style: TextStyle(color: muted, fontSize: 13, height: 1.25),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 355;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('next-action-open-task'),
                      onPressed: onOpenTask,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Открыть квест'),
                      style: FilledButton.styleFrom(
                        minimumSize: Size(compact ? 0 : 164, 44),
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('next-action-choose-another'),
                      onPressed: onChooseTask,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Другое'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withAlpha(160)),
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('next-action-boot-entry'),
                      onPressed: onBootEntry,
                      icon: const Icon(Icons.low_priority_rounded, size: 18),
                      label: const Text('Трудно начать?'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        foregroundColor: muted,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({
    required this.reason,
    required this.color,
    required this.isDark,
  });

  final NextActionReason reason;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final label = switch (reason) {
      NextActionReason.explicitOverride => 'Выбрано тобой',
      NextActionReason.selectedSkillActiveStage => 'Текущий этап',
      NextActionReason.selectedSkill => 'Текущий навык',
      NextActionReason.activeStage => 'Активный этап',
      NextActionReason.availableTask => 'Открытый квест',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 24 : 20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyNextActionLens extends StatelessWidget {
  const _EmptyNextActionLens({
    required this.resolution,
    required this.isDark,
    required this.onCreateSkill,
    required this.onOpenSkill,
  });

  final NextActionResolution resolution;
  final bool isDark;
  final VoidCallback onCreateSkill;
  final VoidCallback onOpenSkill;

  @override
  Widget build(BuildContext context) {
    final noSkills = resolution.emptyState == NextActionEmptyState.noSkills;
    final text = MobileJournalTokens.text(isDark);
    final muted = MobileJournalTokens.muted(isDark);
    return KeyedSubtree(
      key: const ValueKey('next-action-lens'),
      child: Container(
        key: const ValueKey('next-action-empty'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MobileJournalTokens.raised(isDark),
          borderRadius: BorderRadius.circular(MobileJournalTokens.radiusMedium),
          border: Border.all(color: MobileJournalTokens.outline(isDark)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.playlist_add_rounded,
              color: MobileJournalTokens.violet,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пока нет следующего действия',
                    style: TextStyle(color: text, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    noSkills
                        ? 'Создай один навык, чтобы начать путь.'
                        : 'Открой навык и добавь один конкретный квест.',
                    style: TextStyle(color: muted, fontSize: 12, height: 1.25),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              key: const ValueKey('next-action-empty-cta'),
              onPressed: noSkills ? onCreateSkill : onOpenSkill,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: Text(noSkills ? 'Навык' : 'Открыть'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryLensCard extends StatelessWidget {
  const _RecoveryLensCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('next-action-recovery'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: MobileJournalTokens.raised(isDark),
      borderRadius: BorderRadius.circular(MobileJournalTokens.radiusMedium),
      border: Border.all(color: MobileJournalTokens.outline(isDark)),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Проверяем сохранённые данные. Следующее действие появится после восстановления.',
            style: TextStyle(
              color: MobileJournalTokens.muted(isDark),
              height: 1.25,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BootEntryActiveCard extends StatelessWidget {
  const _BootEntryActiveCard({
    required this.plan,
    required this.isDark,
    required this.checkedSteps,
    required this.onToggleStep,
    required this.onEdit,
    required this.onDismiss,
    required this.onComplete,
  });

  final BootEntryPlan plan;
  final bool isDark;
  final Set<int> checkedSteps;
  final ValueChanged<int> onToggleStep;
  final VoidCallback onEdit;
  final VoidCallback onDismiss;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final steps = [plan.openContext, plan.smallChange, plan.inspectResult];
    final text = MobileJournalTokens.text(isDark);
    final muted = MobileJournalTokens.muted(isDark);
    final ready = checkedSteps.length == steps.length;
    return Container(
      key: const ValueKey('boot-entry-active'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          MobileJournalTokens.violet.withAlpha(isDark ? 19 : 13),
          MobileJournalTokens.raised(isDark),
        ),
        borderRadius: BorderRadius.circular(MobileJournalTokens.radiusMedium),
        border: Border.all(color: MobileJournalTokens.violet.withAlpha(125)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                color: MobileJournalTokens.violet,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Вход в квест',
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Изменить вход',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          Text(
            plan.parentTaskTitle,
            style: TextStyle(color: muted, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ...List.generate(steps.length, (index) {
            return Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: checkedSteps.contains(index),
                onChanged: (_) => onToggleStep(index),
                title: Text(
                  steps[index],
                  style: TextStyle(color: text, fontSize: 14, height: 1.2),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const ValueKey('boot-entry-complete'),
                onPressed: ready ? onComplete : null,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Завершить вход'),
                style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
              ),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                child: const Text('Вернуться позже'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BootEntryCompleteCard extends StatelessWidget {
  const _BootEntryCompleteCard({
    required this.candidate,
    required this.isDark,
    required this.onOpenTask,
    required this.onCreateAnother,
  });

  final NextActionCandidate candidate;
  final bool isDark;
  final VoidCallback onOpenTask;
  final VoidCallback onCreateAnother;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('boot-entry-complete'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: MobileJournalTokens.raised(isDark),
      borderRadius: BorderRadius.circular(MobileJournalTokens.radiusMedium),
      border: Border.all(color: MobileJournalTokens.inbox.withAlpha(120)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: MobileJournalTokens.inbox,
            ),
            const SizedBox(width: 8),
            Text(
              'Вход завершён',
              style: TextStyle(
                color: MobileJournalTokens.text(isDark),
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Квест не отмечен выполненным и XP не начислен. Продолжи, когда будет удобно.',
          style: TextStyle(
            color: MobileJournalTokens.muted(isDark),
            fontSize: 12,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onOpenTask,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Вернуться к квесту'),
              style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
            ),
            TextButton(
              onPressed: onCreateAnother,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: const Text('Изменить вход'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NextActionPickerSheet extends StatelessWidget {
  const _NextActionPickerSheet({
    required this.current,
    required this.candidates,
    required this.isDark,
  });

  final NextActionCandidate current;
  final List<NextActionCandidate> candidates;
  final bool isDark;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: MobileJournalTokens.surface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: MobileJournalTokens.outline(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Выбрать другое действие',
            style: TextStyle(
              color: MobileJournalTokens.text(isDark),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Показываем только открытые квесты навыков.',
            style: TextStyle(
              color: MobileJournalTokens.muted(isDark),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: candidates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                final selected = candidate.task.id == current.task.id;
                return ListTile(
                  key: ValueKey('next-action-choice-${candidate.task.id}'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: selected
                      ? candidate.skill.color.withAlpha(isDark ? 28 : 18)
                      : MobileJournalTokens.raised(isDark),
                  leading: Icon(
                    candidate.skill.icon,
                    color: candidate.skill.color,
                  ),
                  title: Text(
                    candidate.actionText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: MobileJournalTokens.text(isDark),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    candidate.skill.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: selected ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.of(context).pop(candidate),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _BootEntryEditorSheet extends StatefulWidget {
  const _BootEntryEditorSheet({
    required this.candidate,
    required this.initialPlan,
    required this.isDark,
  });

  final NextActionCandidate candidate;
  final BootEntryPlan initialPlan;
  final bool isDark;

  @override
  State<_BootEntryEditorSheet> createState() => _BootEntryEditorSheetState();
}

class _BootEntryEditorSheetState extends State<_BootEntryEditorSheet> {
  late final TextEditingController _openController;
  late final TextEditingController _changeController;
  late final TextEditingController _inspectController;

  @override
  void initState() {
    super.initState();
    _openController = TextEditingController(
      text: widget.initialPlan.openContext,
    );
    _changeController = TextEditingController(
      text: widget.initialPlan.smallChange,
    )..addListener(_onChanged);
    _inspectController = TextEditingController(
      text: widget.initialPlan.inspectResult,
    );
  }

  @override
  void dispose() {
    _openController.dispose();
    _changeController.dispose();
    _inspectController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final text = MobileJournalTokens.text(widget.isDark);
    final muted = MobileJournalTokens.muted(widget.isDark);
    final outline = MobileJournalTokens.outline(widget.isDark);
    final ready = _changeController.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: MobileJournalTokens.surface(widget.isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'С чего начать',
                  style: TextStyle(
                    color: text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.candidate.task.title,
                  style: TextStyle(color: muted, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                _BootField(
                  label: '1. Открой контекст',
                  controller: _openController,
                  hint: 'Что открыть или подготовить?',
                  isDark: widget.isDark,
                ),
                const SizedBox(height: 10),
                _BootField(
                  label: '2. Сделай один небольшой шаг',
                  controller: _changeController,
                  hint: 'Напиши конкретное действие',
                  isDark: widget.isDark,
                  required: true,
                ),
                const SizedBox(height: 10),
                _BootField(
                  label: '3. Проверь результат',
                  controller: _inspectController,
                  hint: 'Как заметишь, что что-то изменилось?',
                  isDark: widget.isDark,
                ),
                const SizedBox(height: 12),
                Text(
                  'Это вход в работу, а не завершение квеста. XP пока не начисляется.',
                  style: TextStyle(color: muted, fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('boot-entry-start'),
                    onPressed: ready
                        ? () => Navigator.of(context).pop(
                            widget.initialPlan.copyWith(
                              openContext: _openController.text.trim(),
                              smallChange: _changeController.text.trim(),
                              inspectResult: _inspectController.text.trim(),
                            ),
                          )
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Начать вход'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootField extends StatelessWidget {
  const _BootField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.isDark,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final bool required;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label${required ? ' *' : ''}',
        style: TextStyle(
          color: MobileJournalTokens.text(isDark),
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        minLines: 1,
        maxLines: 3,
        textInputAction: TextInputAction.next,
        style: TextStyle(color: MobileJournalTokens.text(isDark)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: MobileJournalTokens.muted(isDark)),
          filled: true,
          fillColor: MobileJournalTokens.raised(isDark),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ],
  );
}
