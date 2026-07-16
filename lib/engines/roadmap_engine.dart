import '../models/skill_models.dart';
import '../utils.dart';

enum RoadmapStageRole { completed, current, next, locked }

enum RoadmapTemplate { simple, normal, hard, custom }

class RoadmapTemplateConfig {
  final RoadmapTemplate template;
  final int stagesPerPath;
  final int? customPathCount;

  const RoadmapTemplateConfig({
    required this.template,
    this.stagesPerPath = 3,
    this.customPathCount,
  });

  int get pathCount {
    final count = switch (template) {
      RoadmapTemplate.simple => 1,
      RoadmapTemplate.normal => 2,
      RoadmapTemplate.hard => 3,
      RoadmapTemplate.custom => customPathCount ?? 1,
    };
    return count.clamp(1, 99).toInt();
  }

  int get safeStagesPerPath => stagesPerPath.clamp(1, 30).toInt();

  bool get canOverloadFocus => pathCount > 5;
}

class RoadmapPath {
  final int index;
  final List<SkillTreeNode> nodes;

  const RoadmapPath({required this.index, required this.nodes});

  SkillTreeNode? get terminalStage => nodes.isEmpty ? null : nodes.last;
}

class RoadmapPathLayout {
  final List<RoadmapPath> paths;

  const RoadmapPathLayout({required this.paths});

  int get maxStagesInPath => paths.fold(
    0,
    (maxStages, path) =>
        path.nodes.length > maxStages ? path.nodes.length : maxStages,
  );

  bool get isEmpty => paths.every((path) => path.nodes.isEmpty);

  RoadmapPath? pathContaining(String nodeId) {
    for (final path in paths) {
      if (path.nodes.any((node) => node.id == nodeId)) return path;
    }
    return null;
  }

  SkillTreeNode? terminalStageFor(String nodeId) {
    return pathContaining(nodeId)?.terminalStage;
  }
}

class RoadmapStageInfo {
  final SkillTreeNode node;
  final SkillTreeNodeStatus status;
  final RoadmapStageRole role;
  final double progress;
  final int depth;
  final int completedLinkedQuests;
  final int questTarget;

  const RoadmapStageInfo({
    required this.node,
    required this.status,
    required this.role,
    required this.progress,
    required this.depth,
    required this.completedLinkedQuests,
    required this.questTarget,
  });

  bool get isCurrent => role == RoadmapStageRole.current;

  bool get isNext => role == RoadmapStageRole.next;
}

class RoadmapSnapshot {
  final Skill skill;
  final List<RoadmapStageInfo> stages;
  final RoadmapStageInfo? currentStage;
  final RoadmapStageInfo? nextStage;
  final double overallProgress;

  const RoadmapSnapshot({
    required this.skill,
    required this.stages,
    required this.currentStage,
    required this.nextStage,
    required this.overallProgress,
  });

  List<RoadmapStageInfo> get path => stages;

  bool get isEmpty => stages.isEmpty;
}

class RoadmapEngine {
  const RoadmapEngine();

  RoadmapSnapshot buildSnapshot(
    Skill skill, {
    Map<String, int> completedQuestCountsByNodeId = const {},
  }) {
    final orderedNodes = _orderedNodes(skill);
    final currentNode = _pickCurrentNode(skill, orderedNodes);
    final nextNode = _pickNextNode(skill, orderedNodes, currentNode);
    final masteredCount = orderedNodes.where((node) => node.isMastered).length;

    final stages = orderedNodes.map((node) {
      final status = skill.treeNodeStatus(node);
      final completed = completedQuestCountsByNodeId[node.id] ?? 0;
      final questProgress = (completed / node.questTarget).clamp(0.0, 1.0);
      final progress = status == SkillTreeNodeStatus.mastered
          ? 1.0
          : completedQuestCountsByNodeId.containsKey(node.id)
          ? questProgress
          : node.progress;

      return RoadmapStageInfo(
        node: node,
        status: status,
        role: _roleFor(node, currentNode, nextNode, status),
        progress: progress,
        depth: _stageDepth(skill, node),
        completedLinkedQuests: completed,
        questTarget: node.questTarget,
      );
    }).toList();

    return RoadmapSnapshot(
      skill: skill,
      stages: stages,
      currentStage: stages.where((stage) => stage.isCurrent).firstOrNull,
      nextStage: stages.where((stage) => stage.isNext).firstOrNull,
      overallProgress: orderedNodes.isEmpty
          ? 0.0
          : (masteredCount / orderedNodes.length).clamp(0.0, 1.0),
    );
  }

  List<SkillTreeNode> buildTemplate(RoadmapTemplateConfig config) {
    return buildTemplatePaths(
      config,
    ).expand((path) => path.nodes).toList(growable: false);
  }

  List<RoadmapPath> buildTemplatePaths(RoadmapTemplateConfig config) {
    final pathCount = config.pathCount;
    final stageCount = config.safeStagesPerPath;
    return List.generate(pathCount, (pathIndex) {
      final nodes = <SkillTreeNode>[];
      String? previousId;
      for (var stageIndex = 0; stageIndex < stageCount; stageIndex++) {
        final node = _stage(
          _templateStageTitle(pathIndex, stageIndex, pathCount),
          prerequisites: previousId == null ? const [] : [previousId],
        );
        nodes.add(node);
        previousId = node.id;
      }
      return RoadmapPath(index: pathIndex, nodes: nodes);
    });
  }

  RoadmapPathLayout buildPathLayout(Skill skill) {
    final nodes = skill.treeNodes;
    if (nodes.isEmpty) return const RoadmapPathLayout(paths: []);

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

    final paths = <RoadmapPath>[];

    void walk(SkillTreeNode node, List<SkillTreeNode> prefix) {
      final nextPrefix = [...prefix, node];
      final children = childrenByParent[node.id] ?? const <SkillTreeNode>[];
      if (children.isEmpty) {
        paths.add(RoadmapPath(index: paths.length, nodes: nextPrefix));
        return;
      }
      for (final child in children) {
        walk(child, nextPrefix);
      }
    }

    for (final root in roots) {
      walk(root, const []);
    }

    return RoadmapPathLayout(paths: paths);
  }

  SkillTreeNode? terminalStageForNode(Skill skill, String nodeId) {
    return buildPathLayout(skill).terminalStageFor(nodeId);
  }

  List<SkillTreeNode> orderedUniqueStages(Skill skill) {
    final ordered = <SkillTreeNode>[];
    final seen = <String>{};
    final layout = buildPathLayout(skill);

    for (final path in layout.paths) {
      for (final node in path.nodes) {
        if (seen.add(node.id)) ordered.add(node);
      }
    }

    for (final node in skill.treeNodes) {
      if (seen.add(node.id)) ordered.add(node);
    }

    return ordered;
  }

  List<SkillTreeNode> _orderedNodes(Skill skill) {
    final nodes = [...skill.treeNodes];
    nodes.sort((a, b) {
      final depth = _stageDepth(skill, a).compareTo(_stageDepth(skill, b));
      if (depth != 0) return depth;
      return skill.treeNodes.indexOf(a).compareTo(skill.treeNodes.indexOf(b));
    });
    return nodes;
  }

  SkillTreeNode? _pickCurrentNode(Skill skill, List<SkillTreeNode> nodes) {
    for (final node in nodes) {
      if (skill.treeNodeStatus(node) == SkillTreeNodeStatus.active) {
        return node;
      }
    }
    return null;
  }

  SkillTreeNode? _pickNextNode(
    Skill skill,
    List<SkillTreeNode> nodes,
    SkillTreeNode? currentNode,
  ) {
    if (currentNode != null) {
      for (final node in nodes) {
        if (skill.treeNodeStatus(node) == SkillTreeNodeStatus.locked &&
            node.prerequisiteIds.contains(currentNode.id)) {
          return node;
        }
      }
    }

    for (final node in nodes) {
      if (skill.treeNodeStatus(node) == SkillTreeNodeStatus.locked) {
        return node;
      }
    }
    return null;
  }

  RoadmapStageRole _roleFor(
    SkillTreeNode node,
    SkillTreeNode? currentNode,
    SkillTreeNode? nextNode,
    SkillTreeNodeStatus status,
  ) {
    if (status == SkillTreeNodeStatus.mastered) {
      return RoadmapStageRole.completed;
    }
    if (node.id == currentNode?.id) return RoadmapStageRole.current;
    if (node.id == nextNode?.id) return RoadmapStageRole.next;
    return RoadmapStageRole.locked;
  }

  int _stageDepth(Skill skill, SkillTreeNode node, [Set<String>? visiting]) {
    if (node.prerequisiteIds.isEmpty) return 0;
    final guard = visiting ?? <String>{};
    if (!guard.add(node.id)) return 0;

    var depth = 0;
    for (final prerequisiteId in node.prerequisiteIds) {
      final prerequisite = skill.treeNodes
          .where((candidate) => candidate.id == prerequisiteId)
          .firstOrNull;
      if (prerequisite == null) continue;
      final prerequisiteDepth =
          _stageDepth(skill, prerequisite, {...guard}) + 1;
      if (prerequisiteDepth > depth) depth = prerequisiteDepth;
    }
    return depth;
  }

  SkillTreeNode _stage(String title, {List<String> prerequisites = const []}) {
    return SkillTreeNode(
      id: uid(),
      title: title,
      xpReward: 30,
      requiredQuestCompletions: 3,
      prerequisiteIds: List<String>.from(prerequisites),
    );
  }

  String _templateStageTitle(int pathIndex, int stageIndex, int pathCount) {
    const baseTitles = [
      'Основа',
      'Практика',
      'Результат',
      'Усиление',
      'Стабильность',
      'Мастерство',
    ];
    final title = stageIndex < baseTitles.length
        ? baseTitles[stageIndex]
        : 'Этап ${stageIndex + 1}';
    if (pathCount == 1) return title;
    return 'Путь ${pathIndex + 1} · $title';
  }
}
