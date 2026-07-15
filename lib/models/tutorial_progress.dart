class TutorialModuleIds {
  static const core = 'core';
  static const act = 'act';
  static const roadmap = 'roadmap';
  static const stats = 'stats';
  static const trophies = 'trophies';
  static const profile = 'profile';

  static const all = [core, act, roadmap, stats, trophies, profile];
}

class TutorialStepIds {
  static const coreCreateSkill = 'core.createSkill';
  static const coreCreateQuest = 'core.createQuest';
  static const coreCompleteQuest = 'core.completeQuest';
  static const coreXpFeedback = 'core.xpFeedback';
  static const coreOpenRoadmap = 'core.openRoadmap';
  static const coreRoadmapDetails = 'core.roadmapDetails';
  static const coreOpenStats = 'core.openStats';

  static const actNextQuest = 'act.nextQuest';
  static const actMinimum = 'act.minimum';
  static const roadmapPath = 'roadmap.path';
  static const roadmapPractice = 'roadmap.practice';
  static const statsGrowth = 'stats.growth';
  static const trophiesFeedback = 'trophies.feedback';
  static const profileReplay = 'profile.replay';
}

class TutorialProgress {
  final Set<String> completedModuleIds;
  final Set<String> completedStepIds;
  final Set<String> dismissedModuleIds;
  final String? activeModuleId;
  final String? activeStepId;
  final DateTime? updatedAt;

  const TutorialProgress({
    this.completedModuleIds = const {},
    this.completedStepIds = const {},
    this.dismissedModuleIds = const {},
    this.activeModuleId,
    this.activeStepId,
    this.updatedAt,
  });

  const TutorialProgress.empty()
    : completedModuleIds = const {},
      completedStepIds = const {},
      dismissedModuleIds = const {},
      activeModuleId = null,
      activeStepId = null,
      updatedAt = null;

  bool get hasActiveModule => activeModuleId != null;

  bool isModuleCompleted(String id) => completedModuleIds.contains(id);

  bool isStepCompleted(String id) => completedStepIds.contains(id);

  TutorialProgress copyWith({
    Set<String>? completedModuleIds,
    Set<String>? completedStepIds,
    Set<String>? dismissedModuleIds,
    String? activeModuleId,
    String? activeStepId,
    bool clearActive = false,
    DateTime? updatedAt,
  }) {
    return TutorialProgress(
      completedModuleIds: completedModuleIds ?? this.completedModuleIds,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      dismissedModuleIds: dismissedModuleIds ?? this.dismissedModuleIds,
      activeModuleId: clearActive
          ? null
          : activeModuleId ?? this.activeModuleId,
      activeStepId: clearActive ? null : activeStepId ?? this.activeStepId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedModuleIds': completedModuleIds.toList()..sort(),
      'completedStepIds': completedStepIds.toList()..sort(),
      'dismissedModuleIds': dismissedModuleIds.toList()..sort(),
      'activeModuleId': activeModuleId,
      'activeStepId': activeStepId,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static TutorialProgress fromJson(Map<String, dynamic> json) {
    return TutorialProgress(
      completedModuleIds: _stringSet(json['completedModuleIds']),
      completedStepIds: _stringSet(json['completedStepIds']),
      dismissedModuleIds: _stringSet(json['dismissedModuleIds']),
      activeModuleId: _stringOrNull(json['activeModuleId']),
      activeStepId: _stringOrNull(json['activeStepId']),
      updatedAt: DateTime.tryParse(_stringOrNull(json['updatedAt']) ?? ''),
    );
  }

  static Set<String> _stringSet(Object? raw) {
    if (raw is! Iterable) return {};
    return {
      for (final value in raw)
        if (value is String && value.trim().isNotEmpty) value,
    };
  }

  static String? _stringOrNull(Object? raw) {
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return null;
  }
}
