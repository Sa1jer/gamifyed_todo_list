import 'dart:math' as math;

import '../engines/roadmap_engine.dart';
import '../models.dart';
import '../utils.dart';

/// Owns RoadMap graph mutations while AppState retains save/notify orchestration.
class RoadmapMutationCoordinator {
  const RoadmapMutationCoordinator({this.engine = const RoadmapEngine()});

  final RoadmapEngine engine;

  bool addStage(Skill skill, SkillTreeNode node) {
    if (node.requiredQuestCompletions < 1) {
      node.requiredQuestCompletions = 1;
    }
    node.syncChecklistDone();
    skill.treeNodes.add(node);
    skill.syncTreeNodes();
    return true;
  }

  bool canReorderPath(Skill skill, Iterable<String> nodeIds) =>
      _validatedLinearPath(skill, nodeIds) != null;

  bool reorderPath(Skill skill, List<String> orderedNodeIds) {
    if (orderedNodeIds.length < 2) return false;
    final currentPath = _validatedLinearPath(skill, orderedNodeIds);
    if (currentPath == null) return false;

    final nodesById = {for (final node in currentPath) node.id: node};
    final reordered = orderedNodeIds.map((id) => nodesById[id]!).toList();
    for (var index = 0; index < reordered.length; index++) {
      reordered[index].prerequisiteIds = index == 0
          ? <String>[]
          : <String>[reordered[index - 1].id];
    }

    final pathIds = orderedNodeIds.toSet();
    final insertionIndex = skill.treeNodes
        .asMap()
        .entries
        .where((entry) => pathIds.contains(entry.value.id))
        .map((entry) => entry.key)
        .reduce(math.min);
    skill.treeNodes.removeWhere((node) => pathIds.contains(node.id));
    skill.treeNodes.insertAll(insertionIndex, reordered);
    skill.syncTreeNodes();
    return true;
  }

  bool applyTemplate(
    Skill skill,
    Iterable<Task> tasks,
    RoadmapTemplateConfig config,
  ) {
    final templatePaths = engine.buildTemplatePaths(config);
    if (templatePaths.isEmpty) return false;

    final linkedNodeIds = tasks
        .where(
          (task) =>
              task.isSkillTask &&
              task.skillId == skill.id &&
              task.treeNodeId != null,
        )
        .map((task) => task.treeNodeId!)
        .toSet();
    final orderedExisting = engine.orderedUniqueStages(skill);
    final originalPrerequisitesByNodeId = <String, List<String>>{
      for (final node in orderedExisting)
        node.id: List<String>.from(node.prerequisiteIds),
    };
    final selectedNodes = <SkillTreeNode>[];
    final selectedIds = <String>{};
    final reusedNodeIds = <String>{};
    final requiredPrerequisiteByNodeId = <String, String?>{};
    var cursor = 0;

    for (final path in templatePaths) {
      String? previousId;
      for (final templateNode in path.nodes) {
        final reused = cursor < orderedExisting.length;
        final node = reused ? orderedExisting[cursor++] : templateNode;
        if (reused) reusedNodeIds.add(node.id);
        if (selectedIds.add(node.id)) selectedNodes.add(node);
        requiredPrerequisiteByNodeId[node.id] = previousId;
        if (node.requiredQuestCompletions < 1) {
          node.requiredQuestCompletions = 1;
        }
        node.syncChecklistDone();
        previousId = node.id;
      }
    }

    final preservedExtraNodes = orderedExisting
        .skip(cursor)
        .where(
          (node) =>
              !selectedIds.contains(node.id) &&
              _shouldPreserveStage(node, linkedNodeIds),
        )
        .toList(growable: false);
    final finalNodes = [...selectedNodes, ...preservedExtraNodes];
    final finalNodeIds = finalNodes.map((node) => node.id).toSet();
    final prerequisitesByNodeId = <String, List<String>>{
      for (final node in finalNodes)
        node.id: List<String>.from(node.prerequisiteIds),
    };
    final templateNodeIds = requiredPrerequisiteByNodeId.keys.toSet();
    final preservedExtraIds = preservedExtraNodes
        .map((node) => node.id)
        .toSet();

    for (final node in finalNodes) {
      final isTemplateNode = requiredPrerequisiteByNodeId.containsKey(node.id);
      final requiredPrerequisite = requiredPrerequisiteByNodeId[node.id];
      final isTemplateRoot = isTemplateNode && requiredPrerequisite == null;
      final isPreservedExtra = preservedExtraIds.contains(node.id);
      // Reused roots must not keep a parent from their previous path.
      final shouldMergeExistingPrerequisites =
          !isTemplateRoot &&
          (reusedNodeIds.contains(node.id) || isPreservedExtra);
      final originalPrerequisites =
          originalPrerequisitesByNodeId[node.id] ?? const <String>[];
      final existingPrerequisites = shouldMergeExistingPrerequisites
          ? _prerequisitesToPreserve(
              originalPrerequisites: originalPrerequisites,
              requiredPrerequisiteId: requiredPrerequisite,
              templateNodeIds: templateNodeIds,
              isPreservedExtraNode: isPreservedExtra,
            )
          : const <String>[];
      final mergedPrerequisites = _mergePrerequisites(
        nodeId: node.id,
        requiredPrerequisiteId: requiredPrerequisite,
        existingPrerequisiteIds: existingPrerequisites,
        finalNodeIds: finalNodeIds,
        prerequisitesByNodeId: prerequisitesByNodeId,
      );
      node.prerequisiteIds = mergedPrerequisites;
      prerequisitesByNodeId[node.id] = mergedPrerequisites;
    }

    skill.treeNodes
      ..clear()
      ..addAll(finalNodes);
    skill.syncTreeNodes();
    return true;
  }

  SkillTreeNode? extendPath(
    Skill skill,
    String pathNodeId, {
    String title = 'Новый этап',
    String description = '',
    int xpReward = 30,
    int requiredQuestCompletions = 3,
  }) {
    final terminalNode =
        engine.terminalStageForNode(skill, pathNodeId) ??
        skill.treeNodes
            .where((candidate) => candidate.id == pathNodeId)
            .firstOrNull;
    if (terminalNode == null) return null;

    final node = SkillTreeNode(
      id: uid(),
      title: _safeTitle(title),
      description: description,
      xpReward: xpReward,
      requiredQuestCompletions: math.max(1, requiredQuestCompletions),
      prerequisiteIds: [terminalNode.id],
    )..syncChecklistDone();
    skill.treeNodes.add(node);
    skill.syncTreeNodes();
    return node;
  }

  SkillTreeNode? insertStageAfter(
    Skill skill,
    String leftNodeId, {
    required String beforeNodeId,
    String title = 'Новый этап',
    String description = '',
    int xpReward = 30,
    int requiredQuestCompletions = 3,
  }) {
    final leftNodeIndex = skill.treeNodes.indexWhere(
      (candidate) => candidate.id == leftNodeId,
    );
    final rightNodeIndex = skill.treeNodes.indexWhere(
      (candidate) => candidate.id == beforeNodeId,
    );
    if (leftNodeIndex == -1 || rightNodeIndex == -1) return null;

    final rightNode = skill.treeNodes[rightNodeIndex];
    if (!rightNode.prerequisiteIds.contains(leftNodeId)) return null;

    final node = SkillTreeNode(
      id: uid(),
      title: _safeTitle(title),
      description: description,
      xpReward: xpReward,
      requiredQuestCompletions: math.max(1, requiredQuestCompletions),
      prerequisiteIds: [leftNodeId],
    )..syncChecklistDone();
    rightNode.prerequisiteIds = rightNode.prerequisiteIds
        .map((id) => id == leftNodeId ? node.id : id)
        .toList(growable: true);
    skill.treeNodes.insert(rightNodeIndex, node);
    skill.syncTreeNodes();
    return node;
  }

  bool updatePracticeTarget(
    Skill skill,
    String nodeId,
    int requiredQuestCompletions, {
    int? xpReward,
  }) {
    final node = _nodeById(skill, nodeId);
    if (node == null) return false;
    node.requiredQuestCompletions = math.max(1, requiredQuestCompletions);
    if (xpReward != null) node.xpReward = math.max(0, xpReward);
    skill.syncTreeNodes();
    return true;
  }

  bool renameStage(Skill skill, String nodeId, String title) {
    final node = _nodeById(skill, nodeId);
    final safeTitle = title.trim();
    if (node == null || safeTitle.isEmpty || node.title == safeTitle) {
      return false;
    }
    node.title = safeTitle;
    skill.syncTreeNodes();
    return true;
  }

  bool removeStage(
    Skill skill,
    Iterable<Task> tasks,
    String nodeId, {
    required DateTime now,
  }) {
    final hadNode = skill.treeNodes.any((node) => node.id == nodeId);
    if (!hadNode) return false;
    skill.treeNodes.removeWhere((node) => node.id == nodeId);
    for (final node in skill.treeNodes) {
      node.prerequisiteIds.remove(nodeId);
    }
    for (final task in tasks.where(
      (task) =>
          task.isSkillTask &&
          task.skillId == skill.id &&
          task.treeNodeId == nodeId,
    )) {
      task.treeNodeId = null;
      task.updatedAt = now;
    }
    skill.syncTreeNodes();
    return true;
  }

  bool toggleChecklist(Skill skill, String nodeId, int index) {
    final node = _nodeById(skill, nodeId);
    if (node == null ||
        index < 0 ||
        index >= node.checklistDone.length ||
        node.isMastered) {
      return false;
    }
    node.checklistDone[index] = !node.checklistDone[index];
    return true;
  }

  List<SkillTreeNode>? _validatedLinearPath(
    Skill skill,
    Iterable<String> requestedNodeIds,
  ) {
    final requested = requestedNodeIds.toList(growable: false);
    final requestedIds = requested.toSet();
    if (requested.length < 2 || requestedIds.length != requested.length) {
      return null;
    }

    final layout = engine.buildPathLayout(skill);
    final matchingPaths = layout.paths
        .where((path) {
          final ids = path.nodes.map((node) => node.id).toSet();
          return ids.length == requestedIds.length &&
              ids.containsAll(requestedIds);
        })
        .toList(growable: false);
    if (matchingPaths.length != 1) return null;
    final path = matchingPaths.single.nodes;

    for (final node in path) {
      final appearances = layout.paths
          .where(
            (candidate) => candidate.nodes.any((item) => item.id == node.id),
          )
          .length;
      if (appearances != 1) return null;
    }

    final skillNodeIds = skill.treeNodes.map((node) => node.id).toSet();
    for (var index = 0; index < path.length; index++) {
      final validPrerequisites = path[index].prerequisiteIds
          .where(skillNodeIds.contains)
          .toList(growable: false);
      if (index == 0) {
        if (validPrerequisites.isNotEmpty) return null;
      } else if (validPrerequisites.length != 1 ||
          validPrerequisites.single != path[index - 1].id) {
        return null;
      }
    }

    final hasExternalDependent = skill.treeNodes.any(
      (node) =>
          !requestedIds.contains(node.id) &&
          node.prerequisiteIds.any(requestedIds.contains),
    );
    return hasExternalDependent ? null : path;
  }

  List<String> _prerequisitesToPreserve({
    required Iterable<String> originalPrerequisites,
    required String? requiredPrerequisiteId,
    required Set<String> templateNodeIds,
    required bool isPreservedExtraNode,
  }) {
    if (isPreservedExtraNode) return List<String>.from(originalPrerequisites);
    return originalPrerequisites
        .where(
          (id) => id == requiredPrerequisiteId || !templateNodeIds.contains(id),
        )
        .toList(growable: false);
  }

  List<String> _mergePrerequisites({
    required String nodeId,
    required String? requiredPrerequisiteId,
    required Iterable<String> existingPrerequisiteIds,
    required Set<String> finalNodeIds,
    required Map<String, List<String>> prerequisitesByNodeId,
  }) {
    final merged = <String>[];

    void tryAdd(String? prerequisiteId) {
      if (prerequisiteId == null ||
          prerequisiteId == nodeId ||
          !finalNodeIds.contains(prerequisiteId) ||
          merged.contains(prerequisiteId)) {
        return;
      }
      final candidateMap = <String, List<String>>{
        for (final entry in prerequisitesByNodeId.entries)
          entry.key: List<String>.from(entry.value),
      };
      candidateMap[nodeId] = [...merged, prerequisiteId];
      if (_createsCycle(nodeId, candidateMap)) return;
      merged.add(prerequisiteId);
    }

    tryAdd(requiredPrerequisiteId);
    for (final prerequisiteId in existingPrerequisiteIds) {
      tryAdd(prerequisiteId);
    }
    return merged;
  }

  bool _createsCycle(
    String nodeId,
    Map<String, List<String>> prerequisitesByNodeId,
  ) {
    bool visit(String currentId, Set<String> seen) {
      final prerequisites = prerequisitesByNodeId[currentId];
      if (prerequisites == null) return false;
      for (final prerequisiteId in prerequisites) {
        if (prerequisiteId == nodeId) return true;
        if (!seen.add(prerequisiteId)) continue;
        if (visit(prerequisiteId, seen)) return true;
      }
      return false;
    }

    return visit(nodeId, <String>{});
  }

  bool _shouldPreserveStage(SkillTreeNode node, Set<String> linkedNodeIds) =>
      linkedNodeIds.contains(node.id) ||
      node.isMastered ||
      node.masteredAt != null ||
      node.description.trim().isNotEmpty ||
      node.checklist.isNotEmpty;

  SkillTreeNode? _nodeById(Skill skill, String nodeId) =>
      skill.treeNodes.where((candidate) => candidate.id == nodeId).firstOrNull;

  String _safeTitle(String title) =>
      title.trim().isEmpty ? 'Новый этап' : title.trim();
}
