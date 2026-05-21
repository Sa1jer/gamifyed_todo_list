// ignore_for_file: library_private_types_in_public_api

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../feedback_service.dart';
import '../models.dart';
import '../utils.dart';
import 'dialogs.dart';
import 'shared.dart';

enum _MasterySelectionType { skill, node, quest }

class _MasterySelection {
  final _MasterySelectionType type;
  final String skillId;
  final String? nodeId;
  final String? taskId;

  const _MasterySelection.skill(this.skillId)
    : type = _MasterySelectionType.skill,
      nodeId = null,
      taskId = null;

  const _MasterySelection.node(this.skillId, this.nodeId)
    : type = _MasterySelectionType.node,
      taskId = null;

  const _MasterySelection.quest(this.skillId, this.nodeId, this.taskId)
    : type = _MasterySelectionType.quest;
}

List<Task> _sortedActiveQuests(Iterable<Task> tasks) {
  final list = tasks.toList();
  list.sort((a, b) {
    final priority = a.priority.index.compareTo(b.priority.index);
    if (priority != 0) return priority;
    return b.updatedAt.compareTo(a.updatedAt);
  });
  return list;
}

List<Task> _sortedCompletedQuests(Iterable<Task> tasks) {
  final list = tasks.toList();
  list.sort((a, b) => _questSortDate(b).compareTo(_questSortDate(a)));
  return list;
}

DateTime _questSortDate(Task task) => task.lastCompletedAt ?? task.updatedAt;

double _adaptiveSkillLabelFontSize(String text, bool selected) {
  final length = text.trim().length;
  final base = selected ? 14.5 : 13.5;
  if (length <= 10) return base;
  if (length <= 16) return base - 1.0;
  if (length <= 24) return base - 2.1;
  return base - 3.0;
}

double _adaptiveQuestTitleFontSize(String text) {
  final length = text.trim().length;
  if (length <= 24) return 13.2;
  if (length <= 42) return 12.6;
  return 12.0;
}

double _adaptiveInspectorTitleFontSize(String text) {
  final length = text.trim().length;
  if (length <= 18) return 17.0;
  if (length <= 32) return 15.8;
  return 14.8;
}

double _adaptiveNodeLabelFontSize(String text) {
  final length = text.trim().length;
  if (length <= 10) return 12.0;
  if (length <= 18) return 11.2;
  if (length <= 26) return 10.5;
  return 10.0;
}

List<Task> _freeQuestsForSkill(Skill skill, Iterable<Task> tasks) {
  final validNodeIds = skill.treeNodes.map((node) => node.id).toSet();
  return tasks
      .where(
        (task) =>
            task.treeNodeId == null || !validNodeIds.contains(task.treeNodeId),
      )
      .toList();
}

class MasteryMapWorkspace extends StatefulWidget {
  final bool isDark;
  final void Function(String taskId, Offset position) onCompleteTask;

  const MasteryMapWorkspace({
    super.key,
    required this.isDark,
    required this.onCompleteTask,
  });

  @override
  State<MasteryMapWorkspace> createState() => _MasteryMapWorkspaceState();
}

class _MasteryMapWorkspaceState extends State<MasteryMapWorkspace> {
  _MasterySelection? _selection;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final selection = _validSelection(state);
    final isDark = widget.isDark;

    if (state.skills.isEmpty) {
      return AppPanel(
        isDark: isDark,
        child: EmptyStateMessage(
          isDark: isDark,
          icon: Icons.account_tree_outlined,
          title: 'Карта мастерства пока пустая',
          subtitle: 'Создайте навык, а затем добавьте первые узлы мастерства.',
        ),
      );
    }

    return Column(
      children: [
        _MasteryMapHero(
          isDark: isDark,
          onFullscreen: () => _openFullscreen(context, selection),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _MasteryMapBody(
            state: state,
            isDark: isDark,
            selection: selection,
            onSelectionChanged: (next) => setState(() => _selection = next),
            onAddRoot: (skill) => _addNode(context, skill),
            onAddChild: (skill, node) =>
                _addNode(context, skill, parentNode: node),
            onAddQuest: (skill, node) => _addQuest(context, skill, node: node),
            onEditQuest: (skill, task) => _editQuest(context, skill, task),
            onDeleteQuest: (task) {
              state.removeTask(task.id);
              setState(() => _selection = null);
            },
            onCompleteQuest: widget.onCompleteTask,
            onMasterNode: (skill, node) =>
                state.masterSkillTreeNode(skill.id, node.id),
            onDeleteNode: (skill, node) {
              state.removeSkillTreeNode(skill.id, node.id);
              setState(() => _selection = _MasterySelection.skill(skill.id));
            },
          ),
        ),
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
      state.skills.where((skill) => skill.id == id).firstOrNull;

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
          setState(() => _selection = nextSelection);
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
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        isDark: state.isDark,
        skillColor: skill.color,
        skill: skill,
        initialTreeNodeId: node?.id,
        onSave:
            (
              title,
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
                  : _MasterySelection.quest(skill.id, treeNodeId, taskId);
              setState(() => _selection = nextSelection);
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
              setState(() => _selection = nextSelection);
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
              setState(() => _selection = next);
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
                                  'Карта мастерства',
                                  style: TextStyle(
                                    color: textColor(isDark),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
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
                              fullscreen: true,
                              onSelectionChanged: updateSelection,
                              onAddRoot: (skill) => _addNode(
                                dialogContext,
                                skill,
                                onCreated: updateSelection,
                              ),
                              onAddChild: (skill, node) => _addNode(
                                dialogContext,
                                skill,
                                parentNode: node,
                                onCreated: updateSelection,
                              ),
                              onAddQuest: (skill, node) => _addQuest(
                                dialogContext,
                                skill,
                                node: node,
                                onCreated: updateSelection,
                              ),
                              onEditQuest: (skill, task) => _editQuest(
                                dialogContext,
                                skill,
                                task,
                                onSaved: updateSelection,
                              ),
                              onDeleteQuest: (task) {
                                state.removeTask(task.id);
                                updateSelection(null);
                              },
                              onCompleteQuest: widget.onCompleteTask,
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

class _MasteryMapHero extends StatelessWidget {
  final bool isDark;
  final VoidCallback onFullscreen;

  const _MasteryMapHero({required this.isDark, required this.onFullscreen});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4A9EFF);
    return AppPanel(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_tree, color: color, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Карта мастерства',
                    style: TextStyle(
                      color: textColor(isDark),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Навыки раскрываются в карту мастерства. Квесты выбранного узла живут справа — canvas остаётся чистым.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtext(isDark),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SmallBtn(
              label: 'Развернуть',
              icon: Icons.open_in_full,
              color: color,
              onTap: onFullscreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryMapBody extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final _MasterySelection? selection;
  final bool fullscreen;
  final ValueChanged<_MasterySelection?> onSelectionChanged;
  final ValueChanged<Skill> onAddRoot;
  final void Function(Skill skill, SkillTreeNode node) onAddChild;
  final void Function(Skill skill, SkillTreeNode? node) onAddQuest;
  final void Function(Skill skill, Task task) onEditQuest;
  final ValueChanged<Task> onDeleteQuest;
  final void Function(String taskId, Offset position) onCompleteQuest;
  final void Function(Skill skill, SkillTreeNode node) onMasterNode;
  final void Function(Skill skill, SkillTreeNode node) onDeleteNode;

  const _MasteryMapBody({
    required this.state,
    required this.isDark,
    required this.selection,
    required this.onSelectionChanged,
    required this.onAddRoot,
    required this.onAddChild,
    required this.onAddQuest,
    required this.onEditQuest,
    required this.onDeleteQuest,
    required this.onCompleteQuest,
    required this.onMasterNode,
    required this.onDeleteNode,
    this.fullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 980;
        final canvas = _OrbMasteryMapCanvas(
          state: state,
          isDark: isDark,
          selection: selection,
          onSelectSkill: (skill) {
            if (selection?.skillId == skill.id) {
              onSelectionChanged(null);
              return;
            }
            onSelectionChanged(_MasterySelection.skill(skill.id));
          },
          onCollapse: () => onSelectionChanged(null),
          onSelectNode: (skill, node) =>
              onSelectionChanged(_MasterySelection.node(skill.id, node.id)),
        );
        final inspector = _MasteryMapInspector(
          state: state,
          isDark: isDark,
          selection: selection,
          onSelectSkill: (skill) =>
              onSelectionChanged(_MasterySelection.skill(skill.id)),
          onSelectQuest: (skill, task) => onSelectionChanged(
            _MasterySelection.quest(skill.id, task.treeNodeId, task.id),
          ),
          onAddRoot: onAddRoot,
          onAddChild: onAddChild,
          onAddQuest: onAddQuest,
          onEditQuest: onEditQuest,
          onDeleteQuest: onDeleteQuest,
          onCompleteQuest: onCompleteQuest,
          onMasterNode: onMasterNode,
          onDeleteNode: onDeleteNode,
        );

        if (narrow) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: fullscreen ? 640 : 520, child: canvas),
                const SizedBox(height: 10),
                inspector,
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: canvas),
            const SizedBox(width: 10),
            SizedBox(width: fullscreen ? 380 : 340, child: inspector),
          ],
        );
      },
    );
  }
}

class _OrbMasteryMapCanvas extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final _MasterySelection? selection;
  final ValueChanged<Skill> onSelectSkill;
  final VoidCallback onCollapse;
  final void Function(Skill skill, SkillTreeNode node) onSelectNode;

  const _OrbMasteryMapCanvas({
    required this.state,
    required this.isDark,
    required this.selection,
    required this.onSelectSkill,
    required this.onCollapse,
    required this.onSelectNode,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0D0D12) : const Color(0xFFF7F8FC);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor(isDark)),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _buildOrbLayout(
            state,
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          final selectedSkill = layout.selectedSkill;

          return Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.48,
                  maxScale: 1.85,
                  boundaryMargin: const EdgeInsets.all(220),
                  constrained: false,
                  child: SizedBox(
                    width: layout.size.width,
                    height: layout.size.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _OrbMasteryMapPainter(
                              layout: layout,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        ...layout.skillPositions.entries.map((entry) {
                          final skill = entry.key;
                          final position = entry.value;
                          final selected = selection?.skillId == skill.id;
                          return AnimatedPositioned(
                            key: ValueKey('map-skill-orb-${skill.id}'),
                            duration: kMotionSlow,
                            curve: kMotionCurve,
                            left: position.dx - 90,
                            top: position.dy - 70,
                            width: 180,
                            height: 156,
                            child: _SkillOrbButton(
                              skill: skill,
                              isDark: isDark,
                              selected: selected,
                              dimmed: selectedSkill != null && !selected,
                              onTap: () => onSelectSkill(skill),
                            ),
                          );
                        }),
                        if (selectedSkill != null)
                          ...selectedSkill.treeNodes.map((node) {
                            final position = layout.nodePositions[node.id];
                            if (position == null) {
                              return const SizedBox.shrink();
                            }
                            return AnimatedPositioned(
                              key: ValueKey(
                                'map-node-${selectedSkill.id}-${node.id}',
                              ),
                              duration: kMotionSlow,
                              curve: kMotionCurve,
                              left: position.dx - 56,
                              top: position.dy - 54,
                              width: 112,
                              height: 108,
                              child: AnimatedSwitcher(
                                duration: kMotionSlow,
                                switchInCurve: kMotionCurve,
                                switchOutCurve: kMotionExitCurve,
                                child: _MapNodeButton(
                                  key: ValueKey(
                                    'node-button-${selectedSkill.id}-${node.id}',
                                  ),
                                  state: state,
                                  skill: selectedSkill,
                                  node: node,
                                  isDark: isDark,
                                  selected:
                                      selection?.nodeId == node.id &&
                                      selection?.type !=
                                          _MasterySelectionType.skill,
                                  onTap: () =>
                                      onSelectNode(selectedSkill, node),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              if (selectedSkill == null)
                Positioned(
                  left: 14,
                  top: 14,
                  width: 214,
                  child: _SelectSkillHint(isDark: isDark),
                ),
              if (selectedSkill != null)
                Positioned(
                  right: 14,
                  top: 14,
                  child: _MapCanvasAction(
                    isDark: isDark,
                    label: 'Свернуть',
                    icon: Icons.close_fullscreen,
                    onTap: onCollapse,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  _OrbCanvasLayout _buildOrbLayout(AppState state, Size minSize) {
    final selectedSkill = selection == null
        ? null
        : state.skills
              .where((skill) => skill.id == selection!.skillId)
              .firstOrNull;
    final selectedShape = selectedSkill == null
        ? const _TreeShape(xById: {}, depthById: {}, maxDepth: 0)
        : _buildSingleSkillTree(selectedSkill);
    final treeReach = selectedSkill == null
        ? 0.0
        : 470.0 + selectedShape.maxDepth * 170.0;
    final dockBottom = selectedSkill != null && minSize.width < 760;
    final double width = math
        .max(
          minSize.width,
          selectedSkill == null
              ? 720
              : dockBottom
              ? math.max(980, state.skills.length * 132 + 240)
              : 980,
        )
        .toDouble();
    final double height = math
        .max(
          minSize.height,
          selectedSkill == null
              ? 620
              : dockBottom
              ? 860
              : math.max(760, state.skills.length * 118 + 190),
        )
        .toDouble();
    final center = Offset(width / 2, height / 2);
    final selectedCenter = selectedSkill == null
        ? null
        : Offset(
            dockBottom ? width / 2 : math.max(360.0, width * 0.42),
            dockBottom ? math.max(290.0, height * 0.42) : height * 0.56,
          );
    final skillPositions = <Skill, Offset>{};

    for (var index = 0; index < state.skills.length; index++) {
      final skill = state.skills[index];
      skillPositions[skill] = selectedSkill == null
          ? _clusterSkillOrbPosition(center, index, state.skills.length)
          : skill.id == selectedSkill.id
          ? selectedCenter!
          : _dockSkillOrbPosition(Size(width, height), index, dockBottom);
    }

    final nodePositions = selectedSkill == null || selectedCenter == null
        ? <String, Offset>{}
        : _placeSelectedSkillNodes(
            selectedSkill,
            selectedShape,
            selectedCenter,
            dockBottom ? -math.pi / 2 : 0,
          );

    return _OrbCanvasLayout(
      size: Size(
        math
            .max(width, selectedSkill == null ? width : treeReach + 420)
            .toDouble(),
        math
            .max(height, selectedSkill == null ? height : treeReach + 220)
            .toDouble(),
      ),
      center: center,
      selectedSkill: selectedSkill,
      skillPositions: skillPositions,
      nodePositions: nodePositions,
    );
  }

  Offset _clusterSkillOrbPosition(Offset center, int index, int count) {
    if (index == 0) return center;
    var remaining = index - 1;
    var ring = 0;
    var capacity = 6;
    while (remaining >= capacity) {
      remaining -= capacity;
      ring++;
      capacity += 6;
    }
    final radius = 150.0 + ring * 128.0;
    final angle =
        (remaining / capacity) * math.pi * 2 +
        (count.isEven ? math.pi / capacity : 0) -
        math.pi / 2;
    return center + Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  Offset _dockSkillOrbPosition(
    Size viewport,
    int originalIndex,
    bool bottomDock,
  ) {
    if (bottomDock) {
      final x = 112.0 + originalIndex * 132.0;
      return Offset(x, math.max(520.0, viewport.height - 84.0));
    }
    final y = 105.0 + originalIndex * 118.0;
    return Offset(86, y);
  }

  _TreeShape _buildSingleSkillTree(Skill skill) {
    final nodes = skill.treeNodes;
    final validIds = nodes.map((node) => node.id).toSet();
    final childrenByParent = {
      for (final node in nodes) node.id: <SkillTreeNode>[],
    };
    final roots = <SkillTreeNode>[];

    for (final node in nodes) {
      final parentId = node.prerequisiteIds
          .where((id) => validIds.contains(id))
          .firstOrNull;
      if (parentId == null) {
        roots.add(node);
      } else {
        childrenByParent[parentId]?.add(node);
      }
    }

    var maxDepth = 0;
    final depthById = <String, int>{};
    final angleById = <String, double>{};

    void visit(SkillTreeNode node, int depth, double angle) {
      maxDepth = math.max(maxDepth, depth);
      depthById[node.id] = depth;
      angleById[node.id] = angle;
      final children = childrenByParent[node.id] ?? const <SkillTreeNode>[];
      if (children.isEmpty) return;
      final spread = math.min(0.95, math.max(0.32, children.length * 0.22));
      for (var i = 0; i < children.length; i++) {
        final childAngle =
            angle +
            (children.length == 1
                ? 0
                : (i - (children.length - 1) / 2) *
                      (spread / (children.length - 1)));
        visit(children[i], depth + 1, childAngle);
      }
    }

    final rootCount = roots.length;
    for (var i = 0; i < rootCount; i++) {
      final angle = rootCount == 1
          ? -math.pi / 2
          : -math.pi / 2 +
                (i - (rootCount - 1) / 2) *
                    (math.min(math.pi * 1.55, rootCount * 0.56) /
                        (rootCount - 1));
      visit(roots[i], 0, angle);
    }

    return _TreeShape(
      xById: angleById,
      depthById: depthById,
      maxDepth: maxDepth,
    );
  }

  Map<String, Offset> _placeSelectedSkillNodes(
    Skill skill,
    _TreeShape shape,
    Offset skillCenter,
    double growAngle,
  ) {
    if (skill.treeNodes.isEmpty) return {};
    final positions = <String, Offset>{};
    for (final node in skill.treeNodes) {
      final depth = shape.depthById[node.id] ?? 0;
      final localAngle = shape.xById[node.id] ?? -math.pi / 2;
      final angle = growAngle + (localAngle + math.pi / 2) * 0.68;
      final radius = 165.0 + depth * 154.0;
      positions[node.id] =
          skillCenter + Offset(math.cos(angle), math.sin(angle)) * radius;
    }
    return positions;
  }
}

class _OrbCanvasLayout {
  final Size size;
  final Offset center;
  final Skill? selectedSkill;
  final Map<Skill, Offset> skillPositions;
  final Map<String, Offset> nodePositions;

  const _OrbCanvasLayout({
    required this.size,
    required this.center,
    required this.selectedSkill,
    required this.skillPositions,
    required this.nodePositions,
  });
}

class _OrbMasteryMapPainter extends CustomPainter {
  final _OrbCanvasLayout layout;
  final bool isDark;

  const _OrbMasteryMapPainter({required this.layout, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(7)
      ..style = PaintingStyle.fill;
    for (var x = 24.0; x < size.width; x += 42) {
      for (var y = 24.0; y < size.height; y += 42) {
        canvas.drawCircle(Offset(x, y), 1.05, dotPaint);
      }
    }

    final selectedSkill = layout.selectedSkill;
    final selectedCenter = selectedSkill == null
        ? null
        : layout.skillPositions[selectedSkill];
    if (selectedSkill == null || selectedCenter == null) return;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          selectedSkill.color.withAlpha(isDark ? 38 : 30),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: selectedCenter, radius: 300));
    canvas.drawCircle(selectedCenter, 300, glowPaint);

    for (final node in selectedSkill.treeNodes) {
      final childPosition = layout.nodePositions[node.id];
      if (childPosition == null) continue;
      final parentId = node.prerequisiteIds
          .where((id) => layout.nodePositions.containsKey(id))
          .firstOrNull;
      final parentNode = parentId == null
          ? null
          : selectedSkill.treeNodes
                .where((candidate) => candidate.id == parentId)
                .firstOrNull;
      final parentPosition = parentId == null
          ? selectedCenter
          : layout.nodePositions[parentId];
      if (parentPosition == null) continue;
      final start = _edgePoint(
        parentPosition,
        childPosition,
        parentNode == null ? _skillOrbRadius : _nodeOrbRadius(parentNode),
      );
      final end = _edgePoint(
        childPosition,
        parentPosition,
        _nodeOrbRadius(node),
      );

      final status = selectedSkill.treeNodeStatus(node);
      final color = status == SkillTreeNodeStatus.active
          ? selectedSkill.color
          : skillTreeNodeStatusColor[status]!;
      final alpha = switch (status) {
        SkillTreeNodeStatus.locked => 46,
        SkillTreeNodeStatus.active => 135,
        SkillTreeNodeStatus.mastered => 112,
      };
      final width = switch (status) {
        SkillTreeNodeStatus.locked => 1.5,
        SkillTreeNodeStatus.active => 2.6,
        SkillTreeNodeStatus.mastered => 2.2,
      };
      final path = _organicConnectionPath(
        start,
        end,
        bend: status == SkillTreeNodeStatus.active ? 0.18 : 0.14,
      );
      final glowPaint = Paint()
        ..color = color.withAlpha(
          status == SkillTreeNodeStatus.active ? 24 : 14,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  double get _skillOrbRadius => 49;

  double _nodeOrbRadius(SkillTreeNode node) {
    final target = node.questTarget;
    return switch (target) {
      <= 1 => 27.0,
      <= 3 => 32.0,
      _ => 37.0,
    };
  }

  Offset _edgePoint(Offset from, Offset to, double radius) {
    final delta = to - from;
    final distance = delta.distance;
    if (distance == 0) return from;
    return from + delta / distance * radius;
  }

  Path _organicConnectionPath(
    Offset start,
    Offset end, {
    double bend = 0.22,
    double sag = 0.0,
  }) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) {
      return Path()..moveTo(start.dx, start.dy);
    }

    final direction = delta / distance;
    final normal = Offset(-direction.dy, direction.dx);
    final curvature = math.min(90.0, math.max(26.0, distance * bend));
    final c1 = start + direction * (distance * 0.35) + normal * curvature;
    final c2 =
        start +
        direction * (distance * 0.72) -
        normal * (curvature * 0.45) +
        Offset(0, sag);

    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
  }

  @override
  bool shouldRepaint(covariant _OrbMasteryMapPainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.isDark != isDark;
  }
}

class _SkillOrbButton extends StatelessWidget {
  final Skill skill;
  final bool isDark;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  const _SkillOrbButton({
    required this.skill,
    required this.isDark,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: kMotionStandard,
      curve: kMotionCurve,
      opacity: dimmed ? 0.48 : 1,
      child: PressFeedback(
        scale: 0.95,
        tooltip: 'Открыть ветку навыка “${skill.name}”',
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: skill.progress),
              duration: kMotionProgress,
              curve: kMotionCurve,
              builder: (context, progress, child) {
                return CustomPaint(
                  painter: _SkillOrbProgressPainter(
                    color: skill.color,
                    progress: progress,
                    isDark: isDark,
                  ),
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: kMotionSlow,
                curve: kMotionCurve,
                width: selected ? 82 : 74,
                height: selected ? 82 : 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skill.color.withAlpha(isDark ? 36 : 28),
                  border: Border.all(
                    color: selected ? Colors.white : skill.color,
                    width: selected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: skill.color.withAlpha(selected ? 105 : 48),
                      blurRadius: selected ? 30 : 18,
                      spreadRadius: selected ? 1 : 0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -5),
                      child: Icon(
                        skill.icon,
                        color: skill.color.withAlpha(selected ? 245 : 220),
                        size: selected ? 31 : 27,
                      ),
                    ),
                    Positioned(
                      bottom: 7,
                      child: Text(
                        '${skill.level}',
                        style: TextStyle(
                          color: skill.color.withAlpha(selected ? 255 : 255),
                          fontSize: selected ? 18 : 16,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha(isDark ? 200 : 80),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 9),
            _AdaptiveOrbLabel(
              text: skill.name,
              isDark: isDark,
              selected: selected,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveOrbLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final bool selected;

  const _AdaptiveOrbLabel({
    required this.text,
    required this.isDark,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: selected ? 190 : 160,
      height: 46,
      child: Center(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? textColor(isDark) : subtext(isDark),
            fontSize: _adaptiveSkillLabelFontSize(text, selected),
            height: 1.05,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SkillOrbProgressPainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool isDark;

  const _SkillOrbProgressPainter({
    required this.color,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 + 6;
    final base = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _SkillOrbProgressPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark;
  }
}

class _SelectSkillHint extends StatelessWidget {
  final bool isDark;

  const _SelectSkillHint({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface(isDark).withAlpha(isDark ? 105 : 145),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(isDark).withAlpha(105)),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, color: subtext(isDark), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Выберите навык',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Мастерство на карте, квесты — справа.',
                  style: TextStyle(color: subtext(isDark), fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreeShape {
  final Map<String, double> xById;
  final Map<String, int> depthById;
  final int maxDepth;

  const _TreeShape({
    required this.xById,
    required this.depthById,
    required this.maxDepth,
  });
}

class _MapNodeButton extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final SkillTreeNode node;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  const _MapNodeButton({
    super.key,
    required this.state,
    required this.skill,
    required this.node,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = skill.treeNodeStatus(node);
    final statusColor = status == SkillTreeNodeStatus.active
        ? skill.color
        : skillTreeNodeStatusColor[status]!;
    final completed = state.completedTasksForTreeNode(skill.id, node.id);
    final target = node.questTarget;
    final diameter = switch (target) {
      <= 1 => 52.0,
      <= 3 => 62.0,
      _ => 72.0,
    };
    final icon = switch (status) {
      SkillTreeNodeStatus.locked => Icons.lock,
      SkillTreeNodeStatus.active => Icons.bolt_rounded,
      SkillTreeNodeStatus.mastered => Icons.workspace_premium,
    };

    return PressFeedback(
      scale: 0.94,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: kMotionStandard,
            curve: kMotionCurve,
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              color: status == SkillTreeNodeStatus.locked
                  ? surface(isDark).withAlpha(isDark ? 180 : 230)
                  : statusColor.withAlpha(isDark ? 34 : 24),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : statusColor,
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                if (selected || status == SkillTreeNodeStatus.active)
                  BoxShadow(
                    color: statusColor.withAlpha(selected ? 105 : 50),
                    blurRadius: selected ? 26 : 18,
                  ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, color: statusColor, size: diameter * 0.42),
                Positioned(
                  bottom: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D0D12)
                          : const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      '${math.min(completed, target)}/$target',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child: _AdaptiveNodeLabel(
              text: node.title,
              color: status == SkillTreeNodeStatus.locked
                  ? subtext(isDark)
                  : textColor(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveNodeLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _AdaptiveNodeLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 30,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: _adaptiveNodeLabelFontSize(text),
          height: 1.05,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MapCanvasAction extends StatelessWidget {
  final bool isDark;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MapCanvasAction({
    required this.isDark,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4A9EFF);
    return PressFeedback(
      scale: 0.96,
      tooltip: label,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: surface(isDark).withAlpha(isDark ? 225 : 238),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(100)),
          boxShadow: [
            BoxShadow(color: color.withAlpha(isDark ? 25 : 18), blurRadius: 14),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryMapInspector extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final _MasterySelection? selection;
  final ValueChanged<Skill> onSelectSkill;
  final void Function(Skill skill, Task task) onSelectQuest;
  final ValueChanged<Skill> onAddRoot;
  final void Function(Skill skill, SkillTreeNode node) onAddChild;
  final void Function(Skill skill, SkillTreeNode? node) onAddQuest;
  final void Function(Skill skill, Task task) onEditQuest;
  final ValueChanged<Task> onDeleteQuest;
  final void Function(String taskId, Offset position) onCompleteQuest;
  final void Function(Skill skill, SkillTreeNode node) onMasterNode;
  final void Function(Skill skill, SkillTreeNode node) onDeleteNode;

  const _MasteryMapInspector({
    required this.state,
    required this.isDark,
    required this.selection,
    required this.onSelectSkill,
    required this.onSelectQuest,
    required this.onAddRoot,
    required this.onAddChild,
    required this.onAddQuest,
    required this.onEditQuest,
    required this.onDeleteQuest,
    required this.onCompleteQuest,
    required this.onMasterNode,
    required this.onDeleteNode,
  });

  @override
  Widget build(BuildContext context) {
    final currentSelection = selection;
    if (currentSelection == null) {
      return AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _EmptyMapInspector(
            state: state,
            isDark: isDark,
            onSelectSkill: onSelectSkill,
          ),
        ),
      );
    }

    final skill = state.skills
        .where((candidate) => candidate.id == currentSelection.skillId)
        .firstOrNull;
    if (skill == null) {
      return AppPanel(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _EmptyMapInspector(
            state: state,
            isDark: isDark,
            onSelectSkill: onSelectSkill,
          ),
        ),
      );
    }

    final node = skill.treeNodes
        .where((candidate) => candidate.id == currentSelection.nodeId)
        .firstOrNull;
    final task = state.tasks
        .where((candidate) => candidate.id == currentSelection.taskId)
        .firstOrNull;

    return AppPanel(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: switch (currentSelection.type) {
          _MasterySelectionType.quest when task != null => _QuestInspector(
            state: state,
            isDark: isDark,
            skill: skill,
            task: task,
            node: node,
            onEdit: () => onEditQuest(skill, task),
            onDelete: () => onDeleteQuest(task),
            onComplete: onCompleteQuest,
          ),
          _MasterySelectionType.node when node != null => _NodeInspector(
            state: state,
            isDark: isDark,
            skill: skill,
            node: node,
            onAddChild: () => onAddChild(skill, node),
            onAddQuest: () => onAddQuest(skill, node),
            onSelectQuest: (task) => onSelectQuest(skill, task),
            onEditQuest: (task) => onEditQuest(skill, task),
            onCompleteQuest: onCompleteQuest,
            onMaster: () => onMasterNode(skill, node),
            onDelete: () => onDeleteNode(skill, node),
          ),
          _ => _SkillInspector(
            state: state,
            isDark: isDark,
            skill: skill,
            onAddRoot: () => onAddRoot(skill),
            onAddQuest: () => onAddQuest(skill, null),
            onSelectQuest: (task) => onSelectQuest(skill, task),
            onEditQuest: (task) => onEditQuest(skill, task),
            onCompleteQuest: onCompleteQuest,
          ),
        },
      ),
    );
  }
}

class _EmptyMapInspector extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final ValueChanged<Skill> onSelectSkill;

  const _EmptyMapInspector({
    required this.state,
    required this.isDark,
    required this.onSelectSkill,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorTitle(
          icon: Icons.touch_app_outlined,
          color: const Color(0xFF4A9EFF),
          title: 'Выберите навык',
          subtitle: 'шар раскроет свою ветку мастерства',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Text(
          'Карта показывает все навыки как сферы. Нажмите на любую сферу, чтобы увидеть её узлы, связанные квесты и следующий шаг освоения.',
          style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: state.skills.length,
            separatorBuilder: (_, _) => const SizedBox(height: 7),
            itemBuilder: (context, index) {
              final skill = state.skills[index];
              return PressFeedback(
                scale: 0.98,
                onTap: () => onSelectSkill(skill),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF14141C)
                        : const Color(0xFFF4F5FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor(isDark)),
                  ),
                  child: Row(
                    children: [
                      Icon(skill.icon, color: skill.color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          skill.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor(isDark),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${skill.masteredTreeNodeCount}/${skill.treeNodes.length}',
                        style: TextStyle(
                          color: skill.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SkillInspector extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final Skill skill;
  final VoidCallback onAddRoot;
  final VoidCallback onAddQuest;
  final ValueChanged<Task> onSelectQuest;
  final ValueChanged<Task> onEditQuest;
  final void Function(String taskId, Offset position) onCompleteQuest;

  const _SkillInspector({
    required this.state,
    required this.isDark,
    required this.skill,
    required this.onAddRoot,
    required this.onAddQuest,
    required this.onSelectQuest,
    required this.onEditQuest,
    required this.onCompleteQuest,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = state.tasksForSkill(skill.id);
    final activeTasks = tasks.where((task) => !task.isDone).length;
    final doneTasks = tasks.length - activeTasks;
    final freeTasks = _freeQuestsForSkill(skill, tasks);
    final freeTaskIds = freeTasks.map((task) => task.id).toSet();
    final linkedActiveTasks = _sortedActiveQuests(
      tasks.where((task) => !task.isDone && !freeTaskIds.contains(task.id)),
    );
    final freeActiveTasks = _sortedActiveQuests(
      freeTasks.where((task) => !task.isDone),
    );
    final completedTasks = _sortedCompletedQuests(
      tasks.where((task) => task.isDone),
    );
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorTitle(
          icon: skill.icon,
          color: skill.color,
          title: skill.name,
          subtitle: 'шар навыка',
          isDark: isDark,
        ),
        if (skill.goal.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            skill.goal,
            style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
          ),
        ],
        const SizedBox(height: 14),
        _MetricCard(
          isDark: isDark,
          color: skill.color,
          title: 'Прогресс навыка',
          value: '${skill.xp} / ${skill.xpNeeded} XP',
          progress: skill.progress,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            TaskBadge(
              label: '${skill.treeNodes.length} узл.',
              color: skill.color,
            ),
            TaskBadge(
              label: '${skill.masteredTreeNodeCount} освоено',
              color: const Color(0xFF34C759),
            ),
            TaskBadge(
              label: '$activeTasks активн.',
              color: const Color(0xFF4A9EFF),
            ),
            TaskBadge(
              label: '$doneTasks выполн.',
              color: const Color(0xFF8E8E93),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Квесты навыка',
          style: TextStyle(
            color: txt,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _InspectorQuestList(
            state: state,
            isDark: isDark,
            color: skill.color,
            sections: [
              _QuestListSection(
                title: 'Активные',
                tasks: linkedActiveTasks,
                emptyText: 'Привязанных активных квестов пока нет.',
              ),
              _QuestListSection(
                title: 'Свободные без узла',
                tasks: freeActiveTasks,
                emptyText: 'Все активные квесты уже привязаны к узлам.',
              ),
              _QuestListSection(
                title: 'Выполненные',
                tasks: completedTasks,
                emptyText: 'Завершённых квестов пока нет.',
                muted: true,
              ),
            ],
            onSelectQuest: onSelectQuest,
            onEditQuest: onEditQuest,
            onCompleteQuest: onCompleteQuest,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SmallBtn(
              label: 'Новый корень',
              icon: Icons.add,
              color: skill.color,
              onTap: onAddRoot,
            ),
            SmallBtn(
              label: 'Квест',
              icon: Icons.add_task,
              color: const Color(0xFF4A9EFF),
              onTap: onAddQuest,
            ),
          ],
        ),
      ],
    );
  }
}

class _NodeInspector extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final Skill skill;
  final SkillTreeNode node;
  final VoidCallback onAddChild;
  final VoidCallback onAddQuest;
  final ValueChanged<Task> onSelectQuest;
  final ValueChanged<Task> onEditQuest;
  final void Function(String taskId, Offset position) onCompleteQuest;
  final VoidCallback onMaster;
  final VoidCallback onDelete;

  const _NodeInspector({
    required this.state,
    required this.isDark,
    required this.skill,
    required this.node,
    required this.onAddChild,
    required this.onAddQuest,
    required this.onSelectQuest,
    required this.onEditQuest,
    required this.onCompleteQuest,
    required this.onMaster,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = skill.treeNodeStatus(node);
    final statusColor = status == SkillTreeNodeStatus.active
        ? skill.color
        : skillTreeNodeStatusColor[status]!;
    final completed = state.completedTasksForTreeNode(skill.id, node.id);
    final target = node.questTarget;
    final linkedTasks = state.tasksForTreeNode(skill.id, node.id);
    final activeNodeTasks = _sortedActiveQuests(
      linkedTasks.where((task) => !task.isDone),
    );
    final completedNodeTasks = _sortedCompletedQuests(
      linkedTasks.where((task) => task.isDone),
    );
    final ready = state.canMasterSkillTreeNode(skill.id, node.id);
    final sub = subtext(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InspectorTitle(
          icon: switch (status) {
            SkillTreeNodeStatus.locked => Icons.lock,
            SkillTreeNodeStatus.active => Icons.bolt_rounded,
            SkillTreeNodeStatus.mastered => Icons.workspace_premium,
          },
          color: statusColor,
          title: node.title,
          subtitle: skillTreeNodeStatusLabel[status]!,
          isDark: isDark,
        ),
        if (node.description.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            node.description,
            style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
          ),
        ],
        const SizedBox(height: 14),
        _MetricCard(
          isDark: isDark,
          color: statusColor,
          title: 'Квесты для освоения',
          value: '${math.min(completed, target)} / $target',
          progress: (completed / target).clamp(0.0, 1.0),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            TaskBadge(
              icon: Icons.auto_awesome,
              label: '+${node.xpReward} XP',
              color: const Color(0xFFFFCC00),
            ),
            TaskBadge(
              label:
                  '${linkedTasks.where((task) => !task.isDone).length} активн.',
              color: const Color(0xFF4A9EFF),
            ),
            TaskBadge(
              label: '$completed выполн.',
              color: const Color(0xFF34C759),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Квесты узла',
          style: TextStyle(
            color: textColor(isDark),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _InspectorQuestList(
            state: state,
            isDark: isDark,
            color: skill.color,
            sections: [
              _QuestListSection(
                title: 'Активные квесты узла',
                tasks: activeNodeTasks,
                emptyText: 'Создайте практику для этого этапа.',
              ),
              _QuestListSection(
                title: 'Выполненные квесты узла',
                tasks: completedNodeTasks,
                emptyText: 'Выполненных квестов узла пока нет.',
                muted: true,
              ),
            ],
            onSelectQuest: onSelectQuest,
            onEditQuest: onEditQuest,
            onCompleteQuest: onCompleteQuest,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SmallBtn(
              label: 'Квест',
              icon: Icons.add_task,
              color: const Color(0xFF4A9EFF),
              onTap: onAddQuest,
            ),
            SmallBtn(
              label: 'Дочерний узел',
              icon: Icons.account_tree,
              color: skill.color,
              onTap: onAddChild,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MasterNodeAction(
                enabled: ready,
                mastered: node.isMastered,
                color: skill.color,
                onTap: onMaster,
              ),
            ),
            const SizedBox(width: 10),
            PressFeedback(
              scale: 0.94,
              tooltip: 'Удалить узел',
              onTap: onDelete,
              child: Icon(Icons.delete_outline, color: sub, size: 21),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuestInspector extends StatefulWidget {
  final AppState state;
  final bool isDark;
  final Skill skill;
  final Task task;
  final SkillTreeNode? node;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(String taskId, Offset position) onComplete;

  const _QuestInspector({
    required this.state,
    required this.isDark,
    required this.skill,
    required this.task,
    required this.node,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
  });

  @override
  State<_QuestInspector> createState() => _QuestInspectorState();
}

class _QuestInspectorState extends State<_QuestInspector> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _minimumCtrl;
  late int _xpReward;
  late TaskType _type;
  late Priority _priority;
  late bool _minimumEnabled;
  String? _treeNodeId;
  bool _dirty = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _minimumCtrl = TextEditingController();
    _syncFromTask();
    _titleCtrl.addListener(_onTextChanged);
    _minimumCtrl.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _QuestInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _syncFromTask();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _minimumCtrl.dispose();
    super.dispose();
  }

  void _syncFromTask() {
    _syncing = true;
    final task = widget.task;
    _titleCtrl.text = task.title;
    _minimumCtrl.text = task.minimumAction;
    _xpReward = task.xpReward;
    _type = task.type;
    _priority = task.priority;
    _minimumEnabled = task.hasMinimumAction;
    _treeNodeId = task.treeNodeId;
    _dirty = false;
    _syncing = false;
  }

  void _onTextChanged() {
    if (_syncing || _dirty) return;
    setState(() => _dirty = true);
  }

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
      _dirty = true;
    });
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.state.updateTask(
      widget.task,
      title: title,
      xpReward: _xpReward,
      type: _type,
      repeatFrequency: widget.task.repeatFrequency,
      repeatCustomDays: widget.task.repeatCustomDays,
      priority: _priority,
      minimumAction: _minimumEnabled ? _minimumCtrl.text.trim() : '',
      subtasks: List.of(widget.task.subtasks),
      tags: List.of(widget.task.tags),
      notificationsEnabled: widget.task.notificationsEnabled,
      notificationHour: widget.task.notificationHour,
      notificationMinute: widget.task.notificationMinute,
      treeNodeId: _treeNodeId,
    );
    AppFeedback.selection();
    if (mounted) {
      setState(() => _dirty = false);
    }
  }

  void _toggleCompletion(BuildContext buttonContext) {
    if (widget.task.isDone) {
      AppFeedback.selection();
      widget.state.uncompleteTask(widget.task.id);
      return;
    }

    final box = buttonContext.findRenderObject() as RenderBox?;
    widget.onComplete(
      widget.task.id,
      box?.localToGlobal(Offset.zero) ?? Offset.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final skill = widget.skill;
    final task = widget.task;
    final node = widget.node;
    final sub = subtext(isDark);
    final nodes = skill.treeNodes;
    final selectedNodeExists = nodes.any(
      (candidate) => candidate.id == _treeNodeId,
    );
    final selectedNodeId = selectedNodeExists ? _treeNodeId : null;

    return ListView(
      children: [
        _InspectorTitle(
          icon: task.isDone ? Icons.check_circle : Icons.flag,
          color: task.isDone ? const Color(0xFF34C759) : skill.color,
          title: task.title,
          subtitle: task.isDone ? 'завершённый квест' : 'квест на ветке',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            TaskBadge(
              label: typeLabel[task.type]!,
              color: typeColor[task.type]!,
            ),
            TaskBadge(
              label: priorityLabel[task.priority]!,
              color: priorityColor[task.priority]!,
            ),
            TaskBadge(label: '+${task.xpReward} XP', color: skill.color),
          ],
        ),
        const SizedBox(height: 14),
        _InspectorTextField(
          label: 'Название',
          controller: _titleCtrl,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _XpInlineEditor(
          isDark: isDark,
          color: skill.color,
          xpReward: _xpReward,
          onChanged: (value) => _markDirty(() => _xpReward = value),
        ),
        const SizedBox(height: 14),
        _InspectorChoiceSection<TaskType>(
          isDark: isDark,
          title: 'Тип',
          values: TaskType.values,
          value: _type,
          labelOf: (value) => typeLabel[value]!,
          colorOf: (value) => typeColor[value]!,
          onChanged: (value) => _markDirty(() => _type = value),
        ),
        const SizedBox(height: 12),
        _InspectorChoiceSection<Priority>(
          isDark: isDark,
          title: 'Приоритет',
          values: Priority.values,
          value: _priority,
          labelOf: (value) => priorityLabel[value]!,
          colorOf: (value) => priorityColor[value]!,
          onChanged: (value) => _markDirty(() => _priority = value),
        ),
        const SizedBox(height: 14),
        _MinimumInlineEditor(
          isDark: isDark,
          enabled: _minimumEnabled,
          controller: _minimumCtrl,
          onEnabledChanged: (value) =>
              _markDirty(() => _minimumEnabled = value),
        ),
        if (nodes.isNotEmpty) ...[
          const SizedBox(height: 14),
          _NodeLinkInlineEditor(
            isDark: isDark,
            skill: skill,
            selectedNodeId: selectedNodeId,
            onChanged: (value) => _markDirty(() => _treeNodeId = value),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          task.isDone
              ? 'Завершено: ${task.lastCompletedAt == null ? 'дата не сохранена' : formatShortDate(task.lastCompletedAt!)}'
              : node == null
              ? 'Этот квест находится на свободной ветке навыка.'
              : 'Этот квест продолжает ветку выбранного узла.',
          style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (buttonContext) => SmallBtn(
            label: task.isDone ? 'Вернуть в активные' : 'Завершить квест',
            icon: task.isDone ? Icons.undo : Icons.check,
            color: task.isDone ? sub : const Color(0xFF34C759),
            onTap: () => _toggleCompletion(buttonContext),
          ),
        ),
        const SizedBox(height: 10),
        SmallBtn(
          label: _dirty ? 'Сохранить изменения' : 'Сохранено',
          icon: _dirty ? Icons.save : Icons.check_circle_outline,
          color: _dirty ? const Color(0xFF4A9EFF) : sub,
          onTap: _save,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SmallBtn(
                label: 'Расширенные поля',
                icon: Icons.tune,
                color: sub,
                onTap: widget.onEdit,
              ),
            ),
            const SizedBox(width: 10),
            PressFeedback(
              scale: 0.94,
              tooltip: 'Удалить квест',
              onTap: () {
                AppFeedback.destructive();
                widget.onDelete();
              },
              child: Icon(Icons.delete_outline, color: sub, size: 22),
            ),
          ],
        ),
      ],
    );
  }
}

class _InspectorTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;

  const _InspectorTextField({
    required this.label,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subtext(isDark),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor(isDark)),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: textColor(isDark),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            ),
          ),
        ),
      ],
    );
  }
}

class _XpInlineEditor extends StatelessWidget {
  final bool isDark;
  final Color color;
  final int xpReward;
  final ValueChanged<int> onChanged;

  const _XpInlineEditor({
    required this.isDark,
    required this.color,
    required this.xpReward,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'XP-награда',
            style: TextStyle(
              color: subtext(isDark),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _RoundMiniButton(
          isDark: isDark,
          icon: Icons.remove,
          color: color,
          onTap: () => onChanged(math.max(5, xpReward - 5)),
        ),
        const SizedBox(width: 8),
        Container(
          width: 72,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: color.withAlpha(28),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(70)),
          ),
          child: Text(
            '$xpReward XP',
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _RoundMiniButton(
          isDark: isDark,
          icon: Icons.add,
          color: color,
          onTap: () => onChanged(math.min(1000, xpReward + 5)),
        ),
      ],
    );
  }
}

class _RoundMiniButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoundMiniButton({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      scale: 0.92,
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: surface(isDark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _InspectorChoiceSection<T> extends StatelessWidget {
  final bool isDark;
  final String title;
  final List<T> values;
  final T value;
  final String Function(T value) labelOf;
  final Color Function(T value) colorOf;
  final ValueChanged<T> onChanged;

  const _InspectorChoiceSection({
    required this.isDark,
    required this.title,
    required this.values,
    required this.value,
    required this.labelOf,
    required this.colorOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: subtext(isDark),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final item in values)
              _InspectorChoiceChip(
                label: labelOf(item),
                color: colorOf(item),
                selected: item == value,
                onTap: () => onChanged(item),
              ),
          ],
        ),
      ],
    );
  }
}

class _InspectorChoiceChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _InspectorChoiceChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      scale: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: kMotionStandard,
        curve: kMotionCurve,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(selected ? 36 : 16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(selected ? 150 : 45)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : color.withAlpha(185),
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MinimumInlineEditor extends StatelessWidget {
  final bool isDark;
  final bool enabled;
  final TextEditingController controller;
  final ValueChanged<bool> onEnabledChanged;

  const _MinimumInlineEditor({
    required this.isDark,
    required this.enabled,
    required this.controller,
    required this.onEnabledChanged,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF9500);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface(isDark).withAlpha(isDark ? 130 : 205),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Минимальное действие',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: color,
                onChanged: onEnabledChanged,
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _InspectorTextField(
                label: 'Лёгкий старт',
                controller: controller,
                isDark: isDark,
              ),
            ),
            crossFadeState: enabled
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: kMotionStandard,
            sizeCurve: kMotionCurve,
          ),
        ],
      ),
    );
  }
}

class _NodeLinkInlineEditor extends StatelessWidget {
  final bool isDark;
  final Skill skill;
  final String? selectedNodeId;
  final ValueChanged<String?> onChanged;

  const _NodeLinkInlineEditor({
    required this.isDark,
    required this.skill,
    required this.selectedNodeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ветка карты',
          style: TextStyle(
            color: subtext(isDark),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _InspectorChoiceChip(
              label: 'Свободная',
              color: const Color(0xFFFF9500),
              selected: selectedNodeId == null,
              onTap: () => onChanged(null),
            ),
            for (final node in skill.treeNodes)
              _InspectorChoiceChip(
                label: node.title,
                color: skill.color,
                selected: selectedNodeId == node.id,
                onTap: () => onChanged(node.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _InspectorTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;

  const _InspectorTitle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final titleFontSize = _adaptiveInspectorTitleFontSize(title);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor(isDark),
                  fontSize: titleFontSize,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtext(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final bool isDark;
  final Color color;
  final String title;
  final String value;
  final double progress;

  const _MetricCard({
    required this.isDark,
    required this.color,
    required this.title,
    required this.value,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XPBar(progress: progress.clamp(0.0, 1.0), color: color, height: 6),
        ],
      ),
    );
  }
}

class _QuestListSection {
  final String title;
  final List<Task> tasks;
  final String emptyText;
  final bool muted;

  const _QuestListSection({
    required this.title,
    required this.tasks,
    required this.emptyText,
    this.muted = false,
  });
}

class _InspectorQuestList extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final Color color;
  final List<_QuestListSection> sections;
  final ValueChanged<Task> onSelectQuest;
  final ValueChanged<Task> onEditQuest;
  final void Function(String taskId, Offset position) onCompleteQuest;

  const _InspectorQuestList({
    required this.state,
    required this.isDark,
    required this.color,
    required this.sections,
    required this.onSelectQuest,
    required this.onEditQuest,
    required this.onCompleteQuest,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    final hasTasks = sections.any((section) => section.tasks.isNotEmpty);

    if (!hasTasks) {
      return Center(
        child: Text(
          sections.firstOrNull?.emptyText ?? 'Квестов пока нет.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: sub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    return ListView(
      children: [
        for (final section in sections) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${section.title} (${section.tasks.length})',
                    style: TextStyle(
                      color: section.muted ? sub : textColor(isDark),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (section.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                section.emptyText,
                style: TextStyle(
                  color: sub,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          for (final task in section.tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _InspectorQuestRow(
                state: state,
                task: task,
                isDark: isDark,
                color: color,
                muted: section.muted,
                onSelect: () => onSelectQuest(task),
                onEdit: () => onEditQuest(task),
                onComplete: onCompleteQuest,
              ),
            ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _InspectorQuestRow extends StatelessWidget {
  final AppState state;
  final Task task;
  final bool isDark;
  final Color color;
  final bool muted;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final void Function(String taskId, Offset position) onComplete;

  const _InspectorQuestRow({
    required this.state,
    required this.task,
    required this.isDark,
    required this.color,
    required this.muted,
    required this.onSelect,
    required this.onEdit,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;
    final sub = subtext(isDark);
    final rowColor = done ? const Color(0xFF34C759) : color;
    final metadata = [
      typeLabel[task.type]!,
      priorityLabel[task.priority]!,
      if (task.hasMinimumAction) 'минимум есть',
    ].join(' · ');
    final titleFontSize = _adaptiveQuestTitleFontSize(task.title);

    return PressFeedback(
      scale: 0.985,
      onTap: onSelect,
      child: AnimatedContainer(
        duration: kMotionStandard,
        curve: kMotionCurve,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: muted || done
              ? surface(isDark).withAlpha(isDark ? 112 : 176)
              : (isDark ? const Color(0xFF14141C) : const Color(0xFFF4F5FA)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: done ? rowColor.withAlpha(42) : borderColor(isDark),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (buttonContext) => PressFeedback(
                scale: 0.9,
                tooltip: done ? 'Вернуть в активные' : 'Завершить квест',
                onTap: () {
                  if (done) {
                    AppFeedback.selection();
                    state.uncompleteTask(task.id);
                    return;
                  }
                  final box = buttonContext.findRenderObject() as RenderBox?;
                  onComplete(
                    task.id,
                    box?.localToGlobal(Offset.zero) ?? Offset.zero,
                  );
                },
                child: Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done ? const Color(0xFF34C759) : rowColor,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: TextStyle(
                      color: done ? sub : textColor(isDark),
                      fontSize: titleFontSize,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    done ? 'Завершено' : metadata,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: sub,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${task.xpReward} XP',
                  style: TextStyle(
                    color: done ? sub : rowColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                PressFeedback(
                  scale: 0.9,
                  tooltip: 'Редактировать',
                  onTap: onEdit,
                  child: Icon(Icons.edit_outlined, color: sub, size: 17),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterNodeAction extends StatelessWidget {
  final bool enabled;
  final bool mastered;
  final Color color;
  final VoidCallback onTap;

  const _MasterNodeAction({
    required this.enabled,
    required this.mastered,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mastered) {
      return TaskBadge(
        icon: Icons.check_circle,
        label: 'Освоено',
        color: const Color(0xFF34C759),
      );
    }

    final child = AnimatedOpacity(
      duration: kMotionStandard,
      curve: kMotionCurve,
      opacity: enabled ? 1 : 0.45,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Освоить',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );

    if (!enabled) return child;
    return PressFeedback(scale: 0.96, onTap: onTap, child: child);
  }
}
