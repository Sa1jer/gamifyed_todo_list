import '../models.dart';
import '../utils.dart';

enum RoadmapStageRole { completed, current, next, locked }

enum RoadmapTemplate { linear, branching, extended, custom }

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

  List<SkillTreeNode> buildTemplate(RoadmapTemplate template) {
    switch (template) {
      case RoadmapTemplate.linear:
        return _linearTemplate([
          'Основа',
          'Первый результат',
          'Уверенная практика',
          'Сильный уровень',
          'Цель достигнута',
        ]);
      case RoadmapTemplate.branching:
        final root = _stage('Основа');
        final practice = _stage('Практика', prerequisites: [root.id]);
        final technique = _stage('Техника', prerequisites: [root.id]);
        final result = _stage(
          'Сборка результата',
          prerequisites: [practice.id, technique.id],
        );
        return [root, practice, technique, result];
      case RoadmapTemplate.extended:
        return _linearTemplate([
          'Основа',
          'Первый ритм',
          'Практика',
          'Стабильность',
          'Сложный навык',
          'Сильный результат',
          'Мастерство',
        ]);
      case RoadmapTemplate.custom:
        return [];
    }
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

  List<SkillTreeNode> _linearTemplate(List<String> titles) {
    final nodes = <SkillTreeNode>[];
    String? previousId;
    for (final title in titles) {
      final node = _stage(
        title,
        prerequisites: previousId == null ? const [] : [previousId],
      );
      nodes.add(node);
      previousId = node.id;
    }
    return nodes;
  }

  SkillTreeNode _stage(String title, {List<String> prerequisites = const []}) {
    return SkillTreeNode(
      id: uid(),
      title: title,
      xpReward: 30,
      requiredQuestCompletions: 3,
      prerequisiteIds: prerequisites,
    );
  }
}
