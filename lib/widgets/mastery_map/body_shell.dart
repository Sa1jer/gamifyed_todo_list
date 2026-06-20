part of '../mastery_map_workspace.dart';

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
                    'Карта показывает путь навыка: этапы, связи и следующий шаг мастерства. Квесты здесь — практика для этапов.',
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
  final void Function(Skill skill, SkillTreeNode node) onExtendPath;
  final void Function(
    Skill skill,
    SkillTreeNode leftNode,
    SkillTreeNode rightNode,
  )
  onInsertStageAfter;
  final void Function(Skill skill, SkillTreeNode? node) onAddQuest;
  final void Function(Skill skill, RoadmapTemplateConfig config)
  onApplyRoadmapTemplate;
  final void Function(Task task, Offset position) onToggleQuest;
  final void Function(Task task, Offset position) onMinimumAction;
  final void Function(Skill skill, Task task) onEditQuest;
  final ValueChanged<Task> onDeleteQuest;
  final void Function(Skill skill, SkillTreeNode node) onMasterNode;
  final void Function(Skill skill, SkillTreeNode node) onDeleteNode;

  const _MasteryMapBody({
    required this.state,
    required this.isDark,
    required this.selection,
    required this.onSelectionChanged,
    required this.onAddRoot,
    required this.onExtendPath,
    required this.onInsertStageAfter,
    required this.onAddQuest,
    required this.onApplyRoadmapTemplate,
    required this.onToggleQuest,
    required this.onMinimumAction,
    required this.onEditQuest,
    required this.onDeleteQuest,
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
            if (selection?.type == _MasterySelectionType.skill &&
                selection?.skillId == skill.id) {
              onSelectionChanged(null);
              return;
            }
            onSelectionChanged(_MasterySelection.skill(skill.id));
          },
          onCollapse: () => onSelectionChanged(null),
          onApplyRoadmapTemplate: onApplyRoadmapTemplate,
          onInsertStageAfter: onInsertStageAfter,
          onSelectNode: (skill, node) {
            if (selection?.type == _MasterySelectionType.node &&
                selection?.skillId == skill.id &&
                selection?.nodeId == node.id) {
              onSelectionChanged(_MasterySelection.skill(skill.id));
              return;
            }
            onSelectionChanged(_MasterySelection.node(skill.id, node.id));
          },
        );
        if (narrow) {
          final canvasHeight = fullscreen
              ? (constraints.maxHeight * 0.68).clamp(420.0, 680.0).toDouble()
              : (constraints.maxHeight * 0.58).clamp(340.0, 500.0).toDouble();

          void openDetails() {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (sheetContext) {
                void closeThen(VoidCallback action) {
                  Navigator.pop(sheetContext);
                  action();
                }

                return SafeArea(
                  top: false,
                  child: FractionallySizedBox(
                    heightFactor: 0.86,
                    child: _MobileMasterySelectionPanel(
                      state: state,
                      isDark: isDark,
                      selection: selection,
                      onSelectSkill: (skill) {
                        Navigator.pop(sheetContext);
                        onSelectionChanged(_MasterySelection.skill(skill.id));
                      },
                      onSelectQuest: (skill, task) {
                        Navigator.pop(sheetContext);
                        onSelectionChanged(
                          _MasterySelection.quest(
                            skill.id,
                            task.treeNodeId,
                            task.id,
                          ),
                        );
                      },
                      onAddRoot: (skill) => closeThen(() => onAddRoot(skill)),
                      onExtendPath: (skill, node) =>
                          closeThen(() => onExtendPath(skill, node)),
                      onAddQuest: (skill, node) =>
                          closeThen(() => onAddQuest(skill, node)),
                      onToggleQuest: onToggleQuest,
                      onMinimumAction: onMinimumAction,
                      onEditQuest: (skill, task) =>
                          closeThen(() => onEditQuest(skill, task)),
                      onDeleteQuest: (task) =>
                          closeThen(() => onDeleteQuest(task)),
                      onMasterNode: (skill, node) =>
                          closeThen(() => onMasterNode(skill, node)),
                      onDeleteNode: (skill, node) =>
                          closeThen(() => onDeleteNode(skill, node)),
                    ),
                  ),
                );
              },
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: canvasHeight, child: canvas),
                const SizedBox(height: 10),
                _MasteryMobileSelectionSummary(
                  state: state,
                  isDark: isDark,
                  selection: selection,
                  onSelectSkill: (skill) =>
                      onSelectionChanged(_MasterySelection.skill(skill.id)),
                  onOpenDetails: selection == null ? null : openDetails,
                ),
              ],
            ),
          );
        }

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
          onExtendPath: onExtendPath,
          onAddQuest: onAddQuest,
          onToggleQuest: onToggleQuest,
          onMinimumAction: onMinimumAction,
          onEditQuest: onEditQuest,
          onDeleteQuest: onDeleteQuest,
          onMasterNode: onMasterNode,
          onDeleteNode: onDeleteNode,
        );

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
