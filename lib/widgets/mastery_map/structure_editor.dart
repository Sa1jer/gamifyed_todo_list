part of '../mastery_map_workspace.dart';

Future<void> _showRoadmapStageOrderDialog(
  BuildContext context, {
  required AppState state,
  required Skill skill,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => _RoadmapStageOrderDialog(
      state: state,
      skill: skill,
      onClose: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
    ),
  );
}

class _RoadmapStageOrderDialog extends StatefulWidget {
  final AppState state;
  final Skill skill;
  final VoidCallback onClose;

  const _RoadmapStageOrderDialog({
    required this.state,
    required this.skill,
    required this.onClose,
  });

  @override
  State<_RoadmapStageOrderDialog> createState() =>
      _RoadmapStageOrderDialogState();
}

class _RoadmapStageOrderDialogState extends State<_RoadmapStageOrderDialog> {
  late List<List<String>> _paths;

  @override
  void initState() {
    super.initState();
    _refreshPaths();
  }

  void _refreshPaths() {
    _paths = const RoadmapEngine()
        .buildPathLayout(widget.skill)
        .paths
        .map((path) => path.nodes.map((node) => node.id).toList())
        .toList();
  }

  void _move(int pathIndex, int oldIndex, int newIndex) {
    final next = List<String>.from(_paths[pathIndex]);
    final nodeId = next.removeAt(oldIndex);
    next.insert(newIndex, nodeId);
    if (!widget.state.reorderRoadmapPath(widget.skill.id, next)) return;
    setState(_refreshPaths);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDark;
    final color = widget.skill.color;
    final nodesById = {
      for (final node in widget.skill.treeNodes) node.id: node,
    };
    final width = MediaQuery.sizeOf(context).width;

    return Dialog(
      backgroundColor: surface(isDark),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: width < 760 ? 680 : 720,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DlgHeader(title: 'Порядок этапов', txtColor: textColor(isDark)),
              const SizedBox(height: 6),
              Text(
                'Меняйте порядок только внутри одной дороги. Связанные задачи, прогресс и XP сохранятся.',
                style: TextStyle(
                  color: subtext(isDark),
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _paths.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, pathIndex) {
                    final path = _paths[pathIndex];
                    final editable = widget.state.canReorderRoadmapPath(
                      widget.skill.id,
                      path,
                    );
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withAlpha(isDark ? 14 : 9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor(isDark)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Дорога ${pathIndex + 1}',
                            style: TextStyle(
                              color: textColor(isDark),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (!editable) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Разветвлённую или общую структуру пока нельзя переставлять безопасно.',
                              style: TextStyle(
                                color: subtext(isDark),
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          for (var index = 0; index < path.length; index++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _RoadmapStageOrderRow(
                                key: ValueKey('stage-order-${path[index]}'),
                                title: nodesById[path[index]]?.title ?? 'Этап',
                                index: index,
                                count: path.length,
                                enabled: editable,
                                isDark: isDark,
                                color: color,
                                onUp: () => _move(pathIndex, index, index - 1),
                                onDown: () =>
                                    _move(pathIndex, index, index + 1),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: SmallBtn(
                  label: 'Готово',
                  icon: Icons.check,
                  color: color,
                  onTap: widget.onClose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoadmapStageOrderRow extends StatelessWidget {
  final String title;
  final int index;
  final int count;
  final bool enabled;
  final bool isDark;
  final Color color;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const _RoadmapStageOrderRow({
    super.key,
    required this.title,
    required this.index,
    required this.count,
    required this.enabled,
    required this.isDark,
    required this.color,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
      decoration: BoxDecoration(
        color: surface(isDark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor(isDark),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Поднять этап',
            visualDensity: VisualDensity.compact,
            onPressed: enabled && index > 0 ? onUp : null,
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            tooltip: 'Опустить этап',
            visualDensity: VisualDensity.compact,
            onPressed: enabled && index < count - 1 ? onDown : null,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
        ],
      ),
    );
  }
}
