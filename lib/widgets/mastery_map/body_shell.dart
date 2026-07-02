part of '../mastery_map_workspace.dart';

class _MasteryMapHero extends StatelessWidget {
  final bool isDark;
  final _RoadmapLayoutAxis layoutAxis;
  final ValueChanged<_RoadmapLayoutAxis> onLayoutAxisChanged;
  final VoidCallback onFullscreen;

  const _MasteryMapHero({
    required this.isDark,
    required this.layoutAxis,
    required this.onLayoutAxisChanged,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4A9EFF);
    final mobile = MediaQuery.sizeOf(context).width < 760;
    final showFullscreen = !mobile;
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 12 : 18,
        vertical: mobile ? 9 : 14,
      ),
      child: Row(
        children: [
          Container(
            width: mobile ? 34 : 42,
            height: mobile ? 34 : 42,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_tree,
              color: color,
              size: mobile ? 19 : 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Дорожная карта',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: mobile ? 16 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Карта показывает путь навыка: этапы, связи и следующий шаг мастерства. Квесты здесь — практика для этапов.',
                  maxLines: mobile ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtext(isDark),
                    fontSize: mobile ? 11 : 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (showFullscreen) ...[
            const SizedBox(width: 12),
            _RoadmapLayoutToggle(
              isDark: isDark,
              value: layoutAxis,
              onChanged: onLayoutAxisChanged,
            ),
            const SizedBox(width: 8),
            SmallBtn(
              label: 'Развернуть',
              icon: Icons.open_in_full,
              color: color,
              onTap: onFullscreen,
            ),
          ],
        ],
      ),
    );
    if (mobile) {
      return Container(
        key: const ValueKey('roadmap-mobile-hero'),
        decoration: BoxDecoration(
          color: surface(isDark),
          borderRadius: BorderRadius.circular(18),
        ),
        child: content,
      );
    }
    return AppPanel(isDark: isDark, child: content);
  }
}

class _RoadmapLayoutToggle extends StatelessWidget {
  final bool isDark;
  final _RoadmapLayoutAxis value;
  final ValueChanged<_RoadmapLayoutAxis> onChanged;

  const _RoadmapLayoutToggle({
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4A9EFF);
    return Semantics(
      label: 'Ориентация RoadMap',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor(isDark)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoadmapLayoutButton(
              key: const ValueKey('roadmap-layout-horizontal'),
              selected: value == _RoadmapLayoutAxis.horizontal,
              icon: Icons.view_stream_outlined,
              tooltip: 'Горизонтальная RoadMap',
              isDark: isDark,
              color: accent,
              onTap: () => onChanged(_RoadmapLayoutAxis.horizontal),
            ),
            _RoadmapLayoutButton(
              key: const ValueKey('roadmap-layout-vertical'),
              selected: value == _RoadmapLayoutAxis.vertical,
              icon: Icons.view_week_outlined,
              tooltip: 'Вертикальная RoadMap',
              isDark: isDark,
              color: accent,
              onTap: () => onChanged(_RoadmapLayoutAxis.vertical),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapLayoutButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;

  const _RoadmapLayoutButton({
    super.key,
    required this.selected,
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: AnimatedContainer(
            duration: kMotionFast,
            curve: kMotionCurve,
            width: 34,
            height: 32,
            decoration: BoxDecoration(
              color: selected ? color.withAlpha(isDark ? 38 : 24) : null,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 18,
              color: selected ? color : subtext(isDark),
            ),
          ),
        ),
      ),
    );
  }
}

class _MasteryMapBody extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final _MasterySelection? selection;
  final _RoadmapLayoutAxis layoutAxis;
  final bool fullscreen;
  final GlobalKey? canvasTutorialKey;
  final GlobalKey? inspectorTutorialKey;
  final GlobalKey? practiceTutorialKey;
  final ValueChanged<_MasterySelection?> onSelectionChanged;
  final ValueChanged<Skill> onAddRoot;
  final void Function(Skill skill, SkillTreeNode node) onExtendPath;
  final void Function(Skill skill, SkillTreeNode node) onRenameNode;
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
    required this.layoutAxis,
    this.canvasTutorialKey,
    this.inspectorTutorialKey,
    this.practiceTutorialKey,
    required this.onSelectionChanged,
    required this.onAddRoot,
    required this.onExtendPath,
    required this.onRenameNode,
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
          key: canvasTutorialKey,
          state: state,
          isDark: isDark,
          selection: selection,
          layoutAxis: layoutAxis,
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
          onExtendPath: onExtendPath,
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
                      onAddRoot: (skill) => closeThen(() => onAddRoot(skill)),
                      onExtendPath: (skill, node) =>
                          closeThen(() => onExtendPath(skill, node)),
                      onRenameNode: (skill, node) =>
                          closeThen(() => onRenameNode(skill, node)),
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
                      practiceTutorialKey: practiceTutorialKey,
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
                  onAddStage: onAddRoot,
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
          onAddRoot: onAddRoot,
          onExtendPath: onExtendPath,
          onRenameNode: onRenameNode,
          onAddQuest: onAddQuest,
          onToggleQuest: onToggleQuest,
          onMinimumAction: onMinimumAction,
          onEditQuest: onEditQuest,
          onDeleteQuest: onDeleteQuest,
          onMasterNode: onMasterNode,
          onDeleteNode: onDeleteNode,
          practiceTutorialKey: practiceTutorialKey,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: canvas),
            const SizedBox(width: 10),
            SizedBox(
              width: fullscreen ? 380 : 340,
              child: KeyedSubtree(key: inspectorTutorialKey, child: inspector),
            ),
          ],
        );
      },
    );
  }
}
