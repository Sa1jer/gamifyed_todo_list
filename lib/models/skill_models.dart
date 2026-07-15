import 'package:flutter/material.dart';

import 'xp_owner.dart';

enum SkillTreeNodeStatus { locked, active, mastered }

const skillTreeNodeStatusLabel = {
  SkillTreeNodeStatus.locked: 'Закрыто',
  SkillTreeNodeStatus.active: 'Активно',
  SkillTreeNodeStatus.mastered: 'Освоено',
};

const skillTreeNodeStatusColor = {
  SkillTreeNodeStatus.locked: Color(0xFF8E8E93),
  SkillTreeNodeStatus.active: Color(0xFF4A9EFF),
  SkillTreeNodeStatus.mastered: Color(0xFF34C759),
};

class SkillTreeNode {
  final String id;
  String title;
  String description;
  int xpReward;
  int requiredQuestCompletions;
  List<String> prerequisiteIds;
  List<String> checklist;
  List<bool> checklistDone;
  bool isMastered;
  DateTime? masteredAt;

  SkillTreeNode({
    required this.id,
    required this.title,
    this.description = '',
    this.xpReward = 20,
    this.requiredQuestCompletions = 3,
    List<String>? prerequisiteIds,
    List<String>? checklist,
    List<bool>? checklistDone,
    this.isMastered = false,
    this.masteredAt,
  }) : prerequisiteIds = List.of(prerequisiteIds ?? const <String>[]),
       checklist = List.of(checklist ?? const <String>[]),
       checklistDone = List.of(
         checklistDone ?? List.filled((checklist ?? []).length, false),
       );

  int get checklistCompletedCount => checklistDone.where((done) => done).length;

  int get questTarget =>
      requiredQuestCompletions < 1 ? 1 : requiredQuestCompletions;

  bool get isChecklistReady =>
      checklist.isEmpty || checklistDone.every((done) => done);

  double get progress {
    if (checklist.isEmpty) return isMastered ? 1.0 : 0.0;
    return (checklistCompletedCount / checklist.length).clamp(0.0, 1.0);
  }

  void syncChecklistDone() {
    while (checklistDone.length < checklist.length) {
      checklistDone.add(false);
    }
    while (checklistDone.length > checklist.length) {
      checklistDone.removeLast();
    }
  }
}

// ─── Skill ────────────────────────────────────────────────────────────────────

class GoalReviewEntry {
  final String id;
  DateTime createdAt;
  String wins;
  String blockers;
  String adjustment;
  String nextFocus;
  bool updatedPlan;

  GoalReviewEntry({
    required this.id,
    DateTime? createdAt,
    this.wins = '',
    this.blockers = '',
    this.adjustment = '',
    this.nextFocus = '',
    this.updatedPlan = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

class GoalSpec {
  String text;
  DateTime? deadline;
  String? metric;
  double? targetValue;
  double? currentValue;
  List<GoalReviewEntry> reviews;
  DateTime updatedAt;

  GoalSpec({
    required this.text,
    this.deadline,
    this.metric,
    this.targetValue,
    this.currentValue,
    List<GoalReviewEntry>? reviews,
    DateTime? updatedAt,
  }) : reviews = List.of(reviews ?? const <GoalReviewEntry>[]),
       updatedAt = updatedAt ?? DateTime.now();

  GoalSpec copyWith({
    String? text,
    DateTime? deadline,
    String? metric,
    double? targetValue,
    double? currentValue,
    List<GoalReviewEntry>? reviews,
    DateTime? updatedAt,
    bool clearDeadline = false,
    bool clearMetric = false,
    bool clearTargetValue = false,
    bool clearCurrentValue = false,
  }) {
    return GoalSpec(
      text: text ?? this.text,
      deadline: clearDeadline ? null : deadline ?? this.deadline,
      metric: clearMetric ? null : metric ?? this.metric,
      targetValue: clearTargetValue ? null : targetValue ?? this.targetValue,
      currentValue: clearCurrentValue
          ? null
          : currentValue ?? this.currentValue,
      reviews: reviews ?? this.reviews,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CompletedGoal {
  final String id;
  final String skillId;
  final String goalText;
  final DateTime completedAt;
  final double progressAtCompletion;
  final int completedStages;
  final int totalStages;

  const CompletedGoal({
    required this.id,
    required this.skillId,
    required this.goalText,
    required this.completedAt,
    required this.progressAtCompletion,
    required this.completedStages,
    required this.totalStages,
  });
}

enum GoalMilestone {
  quarter(25, 0.25),
  half(50, 0.50),
  complete(100, 1.0);

  final int percent;
  final double threshold;

  const GoalMilestone(this.percent, this.threshold);
}

class RoadmapStageSnapshot {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final int requiredQuestCompletions;
  final List<String> prerequisiteIds;
  final List<String> checklist;
  final List<bool> checklistDone;
  final bool isMastered;
  final DateTime? masteredAt;

  RoadmapStageSnapshot({
    required this.id,
    required this.title,
    this.description = '',
    this.xpReward = 20,
    this.requiredQuestCompletions = 3,
    Iterable<String> prerequisiteIds = const [],
    Iterable<String> checklist = const [],
    Iterable<bool> checklistDone = const [],
    this.isMastered = false,
    this.masteredAt,
  }) : prerequisiteIds = List.unmodifiable(prerequisiteIds),
       checklist = List.unmodifiable(checklist),
       checklistDone = List.unmodifiable(checklistDone);

  factory RoadmapStageSnapshot.fromNode(SkillTreeNode node) {
    return RoadmapStageSnapshot(
      id: node.id,
      title: node.title,
      description: node.description,
      xpReward: node.xpReward,
      requiredQuestCompletions: node.requiredQuestCompletions,
      prerequisiteIds: node.prerequisiteIds,
      checklist: node.checklist,
      checklistDone: node.checklistDone,
      isMastered: node.isMastered,
      masteredAt: node.masteredAt,
    );
  }
}

class CompletedRoadmap {
  final String id;
  final String skillId;
  final String? completedGoalId;
  final String goalText;
  final DateTime completedAt;
  final double progressAtCompletion;
  final int completedStages;
  final int totalStages;
  final List<RoadmapStageSnapshot> stages;

  CompletedRoadmap({
    required this.id,
    required this.skillId,
    this.completedGoalId,
    required this.goalText,
    required this.completedAt,
    required this.progressAtCompletion,
    required this.completedStages,
    required this.totalStages,
    Iterable<RoadmapStageSnapshot> stages = const [],
  }) : stages = List.unmodifiable(stages);
}

class Skill with XPOwner {
  final String id;
  String name;
  GoalSpec goalSpec;
  List<String> checklist;
  List<bool> checklistDone;
  List<SkillTreeNode> treeNodes;
  final List<CompletedGoal> completedGoals;
  final List<CompletedRoadmap> completedRoadmaps;
  final List<int> triggeredGoalMilestones;
  Color color;
  IconData icon;
  @override
  int level, xp;

  Skill({
    required this.id,
    required this.name,
    required String goal,
    GoalSpec? goalSpec,
    required this.color,
    required this.icon,
    List<String>? checklist,
    List<bool>? checklistDone,
    List<SkillTreeNode>? treeNodes,
    List<CompletedGoal>? completedGoals,
    List<CompletedRoadmap>? completedRoadmaps,
    List<int>? triggeredGoalMilestones,
    this.level = 1,
    this.xp = 0,
  }) : goalSpec = goalSpec ?? GoalSpec(text: goal),
       checklist = List.of(checklist ?? const <String>[]),
       treeNodes = List.of(treeNodes ?? const <SkillTreeNode>[]),
       completedGoals = List.of(completedGoals ?? const <CompletedGoal>[]),
       completedRoadmaps = List.of(
         completedRoadmaps ?? const <CompletedRoadmap>[],
       ),
       triggeredGoalMilestones = List.of(
         triggeredGoalMilestones ?? const <int>[],
       ),
       checklistDone = List.of(
         checklistDone ?? List.filled((checklist ?? []).length, false),
       );

  String get goal => goalSpec.text;

  set goal(String value) {
    goalSpec = goalSpec.copyWith(text: value, updatedAt: DateTime.now());
  }

  String get initial => name.isNotEmpty ? name[0] : '?';

  void syncChecklistDone() {
    while (checklistDone.length < checklist.length) {
      checklistDone.add(false);
    }
    while (checklistDone.length > checklist.length) {
      checklistDone.removeLast();
    }
  }

  int get checklistCompletedCount => checklistDone.where((v) => v).length;

  int get masteredTreeNodeCount => treeNodes.where((n) => n.isMastered).length;

  int get activeTreeNodeCount => treeNodes
      .where((node) => treeNodeStatus(node) == SkillTreeNodeStatus.active)
      .length;

  double get treeProgress {
    if (treeNodes.isEmpty) return 0.0;
    return (masteredTreeNodeCount / treeNodes.length).clamp(0.0, 1.0);
  }

  SkillTreeNodeStatus treeNodeStatus(SkillTreeNode node) {
    if (node.isMastered) return SkillTreeNodeStatus.mastered;
    final masteredIds = treeNodes
        .where((candidate) => candidate.isMastered)
        .map((candidate) => candidate.id)
        .toSet();
    final unlocked = node.prerequisiteIds.every(masteredIds.contains);
    return unlocked ? SkillTreeNodeStatus.active : SkillTreeNodeStatus.locked;
  }

  void syncTreeNodes() {
    final validIds = treeNodes.map((node) => node.id).toSet();
    for (final node in treeNodes) {
      node.syncChecklistDone();
      node.prerequisiteIds.removeWhere((id) => !validIds.contains(id));
    }
  }
}
