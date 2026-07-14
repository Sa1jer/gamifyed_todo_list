part of '../mastery_map_workspace.dart';

Future<NextRoadmapChoice?> _showNextGoalFlow(
  BuildContext context, {
  required AppState state,
  required Skill skill,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final nextGoal = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (_) => NextGoalDialog(
      isDark: state.isDark,
      color: skill.color,
      currentGoal: skill.goal,
    ),
  );
  if (nextGoal == null) return null;

  final result = state.setNextSkillGoal(skill.id, nextGoal);
  if (result != NextGoalUpdateResult.updated || !context.mounted) return null;
  final choice = await showDialog<NextRoadmapChoice>(
    context: context,
    useRootNavigator: true,
    builder: (_) =>
        NextRoadmapPromptDialog(isDark: state.isDark, color: skill.color),
  );
  if (!context.mounted) return choice;
  final message = switch (choice) {
    NextRoadmapChoice.createNew =>
      state.startNewRoadmapForNextGoal(skill.id) ==
              StartNewRoadmapResult.created
          ? 'Новая RoadMap создана. Старая карта сохранена в архиве.'
          : 'Не удалось создать новую RoadMap. Текущая карта не изменена.',
    NextRoadmapChoice.addStage => 'Добавьте первый этап для следующей цели.',
    NextRoadmapChoice.keepCurrent => 'Текущая RoadMap сохранена без изменений.',
    null => 'Текущая RoadMap сохранена без изменений.',
  };
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  return choice;
}

class MasteryMapWorkspace extends StatefulWidget {
  final bool isDark;
  final String? focusSkillId;
  final GlobalKey? canvasTutorialKey;
  final GlobalKey? inspectorTutorialKey;
  final GlobalKey? practiceTutorialKey;
  final ValueChanged<String?>? onFocusSkillChanged;
  final void Function(String taskId, ActionToastOrigin origin) onCompleteTask;
  final void Function(String taskId, ActionToastOrigin origin) onMinimumAction;

  const MasteryMapWorkspace({
    super.key,
    required this.isDark,
    this.focusSkillId,
    this.canvasTutorialKey,
    this.inspectorTutorialKey,
    this.practiceTutorialKey,
    this.onFocusSkillChanged,
    required this.onCompleteTask,
    required this.onMinimumAction,
  });

  @override
  State<MasteryMapWorkspace> createState() => _MasteryMapWorkspaceState();
}

class _MasteryMapWorkspaceState extends State<MasteryMapWorkspace> {
  _MasterySelection? _selection;
  _RoadmapLayoutAxis _desktopLayoutAxis = _RoadmapLayoutAxis.horizontal;
  String? _lastAppliedFocusSkillId;
  final GlobalKey<_OrbMasteryMapCanvasState> _desktopCanvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _applyExternalFocus(widget.focusSkillId);
  }

  @override
  void didUpdateWidget(covariant MasteryMapWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusSkillId != oldWidget.focusSkillId) {
      _applyExternalFocus(widget.focusSkillId);
    }
  }

  void _applyExternalFocus(String? skillId) {
    if (skillId == null) {
      _lastAppliedFocusSkillId = null;
      _selection = null;
      return;
    }
    if (skillId == _lastAppliedFocusSkillId || skillId == _selection?.skillId) {
      _lastAppliedFocusSkillId = skillId;
      return;
    }
    _lastAppliedFocusSkillId = skillId;
    _selection = _MasterySelection.skill(skillId);
  }

  void _setSelection(_MasterySelection? next) {
    final current = _selection;
    final unchanged =
        current?.type == next?.type &&
        current?.skillId == next?.skillId &&
        current?.nodeId == next?.nodeId &&
        current?.taskId == next?.taskId;
    if (unchanged) return;

    final skillChanged = current?.skillId != next?.skillId;
    setState(() {
      _selection = next;
      _lastAppliedFocusSkillId = next?.skillId;
    });
    if (skillChanged) {
      widget.onFocusSkillChanged?.call(next?.skillId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final selection = _validSelection(state);
    final isDark = widget.isDark;
    final mobile = MobileResponsiveMetrics.isMobileWidth(
      MediaQuery.sizeOf(context).width,
    );
    final layoutAxis = mobile
        ? _RoadmapLayoutAxis.vertical
        : _desktopLayoutAxis;

    if (state.roadmapSkills.isEmpty) {
      return AppPanel(
        isDark: isDark,
        child: _AdaptiveRoadmapEmptyState(isDark: isDark),
      );
    }

    Widget buildMapBody() => _MasteryMapBody(
      state: state,
      isDark: isDark,
      selection: selection,
      layoutAxis: layoutAxis,
      canvasControlKey: mobile ? null : _desktopCanvasKey,
      canvasTutorialKey: widget.canvasTutorialKey,
      inspectorTutorialKey: widget.inspectorTutorialKey,
      practiceTutorialKey: widget.practiceTutorialKey,
      onSelectionChanged: _setSelection,
      onAddRoot: (skill) => _addNode(context, skill),
      onExtendPath: (skill, node) => _extendPath(context, skill, node),
      onRenameNode: (skill, node) => _renameNode(context, skill, node),
      onInsertStageAfter: (skill, leftNode, rightNode) =>
          _insertStageAfter(context, skill, leftNode, rightNode),
      onAddQuest: (skill, node) => _addQuest(context, skill, node: node),
      onApplyRoadmapTemplate: (skill, config) {
        state.applyRoadmapTemplate(skill.id, config);
        _setSelection(_MasterySelection.skill(skill.id));
      },
      onToggleQuest: _toggleQuestFromMap,
      onMinimumAction: _minimumActionFromMap,
      onEditQuest: (skill, task) => _editQuest(context, skill, task),
      onDeleteQuest: (task) {
        final skillId = task.skillId;
        state.removeTask(task.id);
        _setSelection(_MasterySelection.skill(skillId));
      },
      onMasterNode: (skill, node) =>
          state.masterSkillTreeNode(skill.id, node.id),
      onDeleteNode: (skill, node) {
        state.removeSkillTreeNode(skill.id, node.id);
        _setSelection(_MasterySelection.skill(skill.id));
      },
    );

    if (mobile) {
      return _MobileRoadmapJournal(
        state: state,
        isDark: isDark,
        selection: selection,
        practiceTutorialKey: widget.practiceTutorialKey,
        onSelectionChanged: _setSelection,
        onAddRoot: (skill) => _addNode(context, skill),
        onExtendPath: (skill, node) => _extendPath(context, skill, node),
        onRenameNode: (skill, node) => _renameNode(context, skill, node),
        onAddQuest: (skill, node) => _addQuest(context, skill, node: node),
        onApplyRoadmapTemplate: (skill, config) {
          state.applyRoadmapTemplate(skill.id, config);
          _setSelection(_MasterySelection.skill(skill.id));
        },
        onToggleQuest: _toggleQuestFromMap,
        onMinimumAction: _minimumActionFromMap,
        onEditQuest: (skill, task) => _editQuest(context, skill, task),
        onDeleteQuest: (task) {
          final skillId = task.skillId;
          state.removeTask(task.id);
          _setSelection(_MasterySelection.skill(skillId));
        },
        onMasterNode: (skill, node) =>
            state.masterSkillTreeNode(skill.id, node.id),
        onDeleteNode: (skill, node) {
          state.removeSkillTreeNode(skill.id, node.id);
          _setSelection(_MasterySelection.skill(skill.id));
        },
      );
    }

    final selectedSkill = selection == null
        ? null
        : state.roadmapSkills
              .where((skill) => skill.id == selection.skillId)
              .firstOrNull;
    return Column(
      children: [
        _MasteryMapHero(
          isDark: isDark,
          selectedSkill: selectedSkill,
          layoutAxis: layoutAxis,
          onLayoutAxisChanged: (next) {
            if (mobile || next == _desktopLayoutAxis) return;
            setState(() => _desktopLayoutAxis = next);
          },
          onCenter: () => _desktopCanvasKey.currentState?.centerContent(),
          onTemplates: selectedSkill == null
              ? null
              : () => _desktopCanvasKey.currentState?.showTemplates(),
          onFullscreen: () => _openFullscreen(context, selection),
        ),
        const SizedBox(height: 10),
        Expanded(child: buildMapBody()),
      ],
    );
  }

  _MasterySelection? _validSelection(AppState state) {
    final current = _selection;
    if (current == null) return null;
    final skill = _skillById(state, current.skillId);
    if (skill == null) return null;

    if (current.type == _MasterySelectionType.node) {
      final nodeExists = skill.treeNodes.any(
        (node) => node.id == current.nodeId,
      );
      if (!nodeExists) return _MasterySelection.skill(skill.id);
    }

    if (current.type == _MasterySelectionType.quest) {
      final task = state.tasks
          .where((candidate) => candidate.id == current.taskId)
          .firstOrNull;
      if (task == null) return _MasterySelection.skill(skill.id);
      if (current.nodeId == null || task.treeNodeId == null) {
        return _MasterySelection.quest(skill.id, null, task.id);
      }
      final nodeExists = skill.treeNodes.any(
        (node) => node.id == task.treeNodeId,
      );
      if (!nodeExists) return _MasterySelection.skill(skill.id);
      return _MasterySelection.quest(skill.id, task.treeNodeId, task.id);
    }

    return current;
  }

  Skill? _skillById(AppState state, String id) =>
      state.roadmapSkills.where((skill) => skill.id == id).firstOrNull;

  void _toggleQuestFromMap(Task task, ActionToastOrigin origin) {
    if (task.isDone) {
      AppFeedback.selection();
      AppStateProvider.of(context).uncompleteTask(task.id);
      return;
    }
    widget.onCompleteTask(task.id, origin);
  }

  void _minimumActionFromMap(Task task, ActionToastOrigin origin) {
    widget.onMinimumAction(task.id, origin);
  }

  void _addNode(
    BuildContext context,
    Skill skill, {
    SkillTreeNode? parentNode,
    ValueChanged<_MasterySelection>? onCreated,
  }) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => AddSkillTreeNodeDialog(
        isDark: state.isDark,
        skill: skill,
        parentNode: parentNode,
        onSave: (title, description, xpReward, requiredQuestCompletions) {
          final nodeId = uid();
          state.addSkillTreeNode(
            skill.id,
            SkillTreeNode(
              id: nodeId,
              title: title,
              description: description,
              xpReward: xpReward,
              requiredQuestCompletions: requiredQuestCompletions,
              prerequisiteIds: parentNode == null ? [] : [parentNode.id],
            ),
          );
          final nextSelection = _MasterySelection.node(skill.id, nodeId);
          _setSelection(nextSelection);
          onCreated?.call(nextSelection);
        },
      ),
    );
  }

  void _extendPath(
    BuildContext context,
    Skill skill,
    SkillTreeNode node, {
    ValueChanged<_MasterySelection>? onCreated,
  }) {
    final state = AppStateProvider.of(context);
    final terminalNode =
        _roadmapEngine.terminalStageForNode(skill, node.id) ?? node;
    showDialog(
      context: context,
      builder: (_) => AddSkillTreeNodeDialog(
        isDark: state.isDark,
        skill: skill,
        parentNode: terminalNode,
        onSave: (title, description, xpReward, requiredQuestCompletions) {
          final created = state.extendRoadmapPath(
            skill.id,
            terminalNode.id,
            title: title,
            description: description,
            xpReward: xpReward,
            requiredQuestCompletions: requiredQuestCompletions,
          );
          if (created == null) return;
          final nextSelection = _MasterySelection.node(skill.id, created.id);
          _setSelection(nextSelection);
          onCreated?.call(nextSelection);
        },
      ),
    );
  }

  void _renameNode(
    BuildContext context,
    Skill skill,
    SkillTreeNode node, {
    ValueChanged<_MasterySelection>? onSaved,
  }) {
    final state = AppStateProvider.of(context);
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => _RenameRoadmapStageDialog(
        isDark: state.isDark,
        initialTitle: node.title,
        onCancel: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
        onSave: (nextTitle) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            state.renameSkillTreeNode(skill.id, node.id, nextTitle);
            final nextSelection = _MasterySelection.node(skill.id, node.id);
            if (mounted) {
              _setSelection(nextSelection);
            }
            onSaved?.call(nextSelection);
          });
        },
      ),
    );
  }

  void _insertStageAfter(
    BuildContext context,
    Skill skill,
    SkillTreeNode leftNode,
    SkillTreeNode rightNode, {
    ValueChanged<_MasterySelection>? onCreated,
  }) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => AddSkillTreeNodeDialog(
        isDark: state.isDark,
        skill: skill,
        parentNode: leftNode,
        onSave: (title, description, xpReward, requiredQuestCompletions) {
          final created = state.insertRoadmapStageAfter(
            skill.id,
            leftNode.id,
            beforeNodeId: rightNode.id,
            title: title,
            description: description,
            xpReward: xpReward,
            requiredQuestCompletions: requiredQuestCompletions,
          );
          if (created == null) return;
          final nextSelection = _MasterySelection.node(skill.id, created.id);
          _setSelection(nextSelection);
          onCreated?.call(nextSelection);
        },
      ),
    );
  }

  void _addQuest(
    BuildContext context,
    Skill skill, {
    SkillTreeNode? node,
    ValueChanged<_MasterySelection?>? onCreated,
  }) {
    final state = AppStateProvider.of(context);
    showAdaptiveCreationForm<void>(
      context: context,
      builder: (_, fullScreen) => AddTaskDialog(
        isDark: state.isDark,
        fullScreen: fullScreen,
        skillColor: skill.color,
        skill: skill,
        initialTreeNodeId: node?.id,
        onSave:
            (
              title,
              description,
              xp,
              type,
              freq,
              customDays,
              priority,
              minimumAction,
              subtasks,
              tags,
              notificationsEnabled,
              notificationHour,
              notificationMinute,
              treeNodeId,
            ) {
              final taskId = uid();
              state.addTask(
                Task(
                  id: taskId,
                  title: title,
                  description: description,
                  skillId: skill.id,
                  xpReward: xp,
                  type: type,
                  repeatFrequency: freq,
                  repeatCustomDays: customDays,
                  priority: priority,
                  minimumAction: minimumAction,
                  subtasks: subtasks,
                  tags: tags,
                  treeNodeId: treeNodeId,
                  notificationsEnabled: notificationsEnabled,
                  notificationHour: notificationHour,
                  notificationMinute: notificationMinute,
                ),
              );
              final nextSelection = treeNodeId == null
                  ? _MasterySelection.skill(skill.id)
                  : _MasterySelection.node(skill.id, treeNodeId);
              _setSelection(nextSelection);
              onCreated?.call(nextSelection);
            },
      ),
    );
  }

  void _editQuest(
    BuildContext context,
    Skill skill,
    Task task, {
    ValueChanged<_MasterySelection?>? onSaved,
  }) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        isDark: state.isDark,
        skillColor: skill.color,
        skill: skill,
        existing: task,
        onSave:
            (
              title,
              description,
              xp,
              type,
              freq,
              customDays,
              priority,
              minimumAction,
              subtasks,
              tags,
              notificationsEnabled,
              notificationHour,
              notificationMinute,
              treeNodeId,
            ) {
              state.updateTask(
                task,
                title: title,
                description: description,
                xpReward: xp,
                type: type,
                repeatFrequency: freq,
                repeatCustomDays: customDays,
                priority: priority,
                minimumAction: minimumAction,
                subtasks: subtasks,
                tags: tags,
                notificationsEnabled: notificationsEnabled,
                notificationHour: notificationHour,
                notificationMinute: notificationMinute,
                treeNodeId: treeNodeId,
              );
              final nextSelection = treeNodeId == null
                  ? _MasterySelection.skill(skill.id)
                  : _MasterySelection.quest(skill.id, treeNodeId, task.id);
              _setSelection(nextSelection);
              onSaved?.call(nextSelection);
            },
      ),
    );
  }

  void _openFullscreen(BuildContext context, _MasterySelection? selection) {
    final state = AppStateProvider.of(context);
    var fullscreenSelection = selection;
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AppStateProvider(
        state: state,
        child: StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void updateSelection(_MasterySelection? next) {
              setDialogState(() => fullscreenSelection = next);
              _setSelection(next);
            }

            void updateLayoutAxis(_RoadmapLayoutAxis next) {
              if (next == _desktopLayoutAxis) return;
              setState(() => _desktopLayoutAxis = next);
              setDialogState(() {});
            }

            return AnimatedBuilder(
              animation: state,
              builder: (context, _) {
                final isDark = state.isDark;
                return Dialog.fullscreen(
                  backgroundColor: isDark
                      ? const Color(0xFF0F0F13)
                      : const Color(0xFFF0F2F8),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.account_tree,
                                color: Color(0xFF4A9EFF),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'RoadMap',
                                  style: TextStyle(
                                    color: textColor(isDark),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              _RoadmapLayoutToggle(
                                isDark: isDark,
                                accent:
                                    state.roadmapSkills
                                        .where(
                                          (skill) =>
                                              skill.id ==
                                              fullscreenSelection?.skillId,
                                        )
                                        .firstOrNull
                                        ?.color ??
                                    const Color(0xFF765BFF),
                                value: _desktopLayoutAxis,
                                onChanged: updateLayoutAxis,
                              ),
                              const SizedBox(width: 8),
                              HoverIconBtn(
                                icon: Icons.close,
                                color: subtext(isDark),
                                tooltip: 'Закрыть полноэкранную карту',
                                onTap: () => Navigator.pop(dialogContext),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _MasteryMapBody(
                              state: state,
                              isDark: isDark,
                              selection: fullscreenSelection,
                              layoutAxis: _desktopLayoutAxis,
                              fullscreen: true,
                              canvasTutorialKey: null,
                              inspectorTutorialKey: null,
                              practiceTutorialKey: null,
                              onSelectionChanged: updateSelection,
                              onAddRoot: (skill) => _addNode(
                                dialogContext,
                                skill,
                                onCreated: updateSelection,
                              ),
                              onExtendPath: (skill, node) => _extendPath(
                                dialogContext,
                                skill,
                                node,
                                onCreated: updateSelection,
                              ),
                              onRenameNode: (skill, node) => _renameNode(
                                dialogContext,
                                skill,
                                node,
                                onSaved: updateSelection,
                              ),
                              onInsertStageAfter:
                                  (skill, leftNode, rightNode) =>
                                      _insertStageAfter(
                                        dialogContext,
                                        skill,
                                        leftNode,
                                        rightNode,
                                        onCreated: updateSelection,
                                      ),
                              onAddQuest: (skill, node) => _addQuest(
                                dialogContext,
                                skill,
                                node: node,
                                onCreated: updateSelection,
                              ),
                              onApplyRoadmapTemplate: (skill, config) {
                                state.applyRoadmapTemplate(skill.id, config);
                                updateSelection(
                                  _MasterySelection.skill(skill.id),
                                );
                              },
                              onToggleQuest: _toggleQuestFromMap,
                              onMinimumAction: _minimumActionFromMap,
                              onEditQuest: (skill, task) => _editQuest(
                                dialogContext,
                                skill,
                                task,
                                onSaved: updateSelection,
                              ),
                              onDeleteQuest: (task) {
                                final skillId = task.skillId;
                                state.removeTask(task.id);
                                updateSelection(
                                  _MasterySelection.skill(skillId),
                                );
                              },
                              onMasterNode: (skill, node) =>
                                  state.masterSkillTreeNode(skill.id, node.id),
                              onDeleteNode: (skill, node) {
                                state.removeSkillTreeNode(skill.id, node.id);
                                updateSelection(
                                  _MasterySelection.skill(skill.id),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Makes an empty map feel intentional without changing the canvas renderer.
class _AdaptiveRoadmapEmptyState extends StatelessWidget {
  final bool isDark;

  const _AdaptiveRoadmapEmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final large =
            constraints.maxWidth >= 980 && constraints.maxHeight >= 600;
        final compact =
            constraints.maxHeight < 520 || constraints.maxWidth < 520;
        final iconSize = large
            ? 48.0
            : compact
            ? 28.0
            : 38.0;
        final iconBox = large
            ? 92.0
            : compact
            ? 54.0
            : 72.0;
        final variant = large
            ? 'large'
            : compact
            ? 'compact'
            : 'normal';

        return Semantics(
          label: 'RoadMap пока пустой. Сначала создайте первый навык в Сейчас.',
          child: SizedBox.expand(
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: large ? 560 : 420),
                child: Container(
                  key: ValueKey('roadmap-empty-$variant'),
                  padding: EdgeInsets.symmetric(
                    horizontal: large ? 28 : 18,
                    vertical: large ? 26 : 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF765BFF,
                    ).withValues(alpha: isDark ? 0.055 : 0.04),
                    borderRadius: BorderRadius.circular(large ? 22 : 18),
                    border: Border.all(
                      color: const Color(
                        0xFF765BFF,
                      ).withValues(alpha: isDark ? 0.24 : 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: iconBox,
                        height: iconBox,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF765BFF,
                          ).withValues(alpha: isDark ? 0.14 : 0.1),
                          borderRadius: BorderRadius.circular(iconBox * 0.3),
                        ),
                        child: Icon(
                          Icons.account_tree_outlined,
                          color: const Color(0xFF765BFF),
                          size: iconSize,
                        ),
                      ),
                      SizedBox(height: large ? 16 : 12),
                      Text(
                        'RoadMap пока пустой',
                        textAlign: TextAlign.center,
                        style: context.appTextTheme.titleLarge?.copyWith(
                          color: textColor(isDark),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Сначала создай первый навык в «Сейчас»: карта покажет этапы, когда появится путь.',
                        textAlign: TextAlign.center,
                        style: context.appTextTheme.bodyMedium?.copyWith(
                          color: subtext(isDark),
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RenameRoadmapStageDialog extends StatefulWidget {
  final bool isDark;
  final String initialTitle;
  final VoidCallback onCancel;
  final ValueChanged<String> onSave;

  const _RenameRoadmapStageDialog({
    required this.isDark,
    required this.initialTitle,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<_RenameRoadmapStageDialog> createState() =>
      _RenameRoadmapStageDialogState();
}

class _RenameRoadmapStageDialogState extends State<_RenameRoadmapStageDialog> {
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final nextTitle = _titleCtrl.text.trim();
    if (nextTitle.isEmpty) return;
    widget.onSave(nextTitle);
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
        width: 410,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DlgHeader(title: 'Переименовать этап', txtColor: txt),
              const SizedBox(height: 14),
              DlgField(
                label: 'Название этапа',
                ctrl: _titleCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
              ),
              const SizedBox(height: 18),
              DlgActions(onCancel: widget.onCancel, onSave: _save),
            ],
          ),
        ),
      ),
    );
  }
}
