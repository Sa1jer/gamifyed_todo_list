import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../analytics/analytics_read_model.dart';
import '../../app_state.dart';
import '../../persistence_status.dart';

@immutable
class MainPageWorkspaceProjection {
  const MainPageWorkspaceProjection({
    required this.coreWorkspaceRevision,
    required this.selectedSkillId,
    required this.isDark,
    required this.reducedMotion,
    required this.returnContextBlocked,
  });

  factory MainPageWorkspaceProjection.fromState(AppState state) =>
      MainPageWorkspaceProjection(
        coreWorkspaceRevision: state.coreWorkspaceRevision,
        selectedSkillId: state.selectedSkillId,
        isDark: state.isDark,
        reducedMotion: state.reducedMotion,
        returnContextBlocked:
            !state.hasLoadedSavedData || state.persistenceStatus.blocksSaving,
      );

  final int coreWorkspaceRevision;
  final String? selectedSkillId;
  final bool isDark;
  final bool reducedMotion;
  final bool returnContextBlocked;

  @override
  bool operator ==(Object other) =>
      other is MainPageWorkspaceProjection &&
      other.coreWorkspaceRevision == coreWorkspaceRevision &&
      other.selectedSkillId == selectedSkillId &&
      other.isDark == isDark &&
      other.reducedMotion == reducedMotion &&
      other.returnContextBlocked == returnContextBlocked;

  @override
  int get hashCode => Object.hash(
    coreWorkspaceRevision,
    selectedSkillId,
    isDark,
    reducedMotion,
    returnContextBlocked,
  );
}

class MainPageWorkspaceBoundary extends StatelessWidget {
  const MainPageWorkspaceBoundary({
    super.key,
    required this.state,
    required this.builder,
    this.onBuildForTesting,
  });

  final AppState state;
  final Widget Function(
    BuildContext context,
    MainPageWorkspaceProjection projection,
  )
  builder;
  final VoidCallback? onBuildForTesting;

  @override
  Widget build(BuildContext context) {
    return AppStateSelector<MainPageWorkspaceProjection>(
      state: state,
      selector: MainPageWorkspaceProjection.fromState,
      builder: (context, projection, child) {
        onBuildForTesting?.call();
        return builder(context, projection);
      },
    );
  }
}

@immutable
class MainPageProfileProjection {
  const MainPageProfileProjection({
    required this.name,
    required this.initial,
    required this.level,
    required this.xp,
    required this.xpNeeded,
    required this.avatarBytes,
    required this.unopenedRewardCount,
  });

  factory MainPageProfileProjection.fromState(AppState state) {
    final profile = state.profile;
    return MainPageProfileProjection(
      name: profile.name,
      initial: profile.initial,
      level: profile.level,
      xp: profile.xp,
      xpNeeded: profile.xpNeeded,
      avatarBytes: profile.avatarBytes,
      unopenedRewardCount: state.unopenedRewardChests.length,
    );
  }

  final String name;
  final String initial;
  final int level;
  final int xp;
  final int xpNeeded;
  final Uint8List? avatarBytes;
  final int unopenedRewardCount;

  @override
  bool operator ==(Object other) =>
      other is MainPageProfileProjection &&
      other.name == name &&
      other.initial == initial &&
      other.level == level &&
      other.xp == xp &&
      other.xpNeeded == xpNeeded &&
      identical(other.avatarBytes, avatarBytes) &&
      other.unopenedRewardCount == unopenedRewardCount;

  @override
  int get hashCode => Object.hash(
    name,
    initial,
    level,
    xp,
    xpNeeded,
    identityHashCode(avatarBytes),
    unopenedRewardCount,
  );
}

class MainPageProfileBoundary extends StatelessWidget {
  const MainPageProfileBoundary({
    super.key,
    required this.state,
    required this.builder,
    this.onBuildForTesting,
  });

  final AppState state;
  final Widget Function(BuildContext context) builder;
  final VoidCallback? onBuildForTesting;

  @override
  Widget build(BuildContext context) {
    return AppStateSelector<MainPageProfileProjection>(
      state: state,
      selector: MainPageProfileProjection.fromState,
      builder: (context, projection, child) {
        onBuildForTesting?.call();
        return builder(context);
      },
    );
  }
}

@immutable
class MainPageTutorialProjection {
  const MainPageTutorialProjection({
    required this.visible,
    required this.moduleId,
    required this.stepId,
  });

  factory MainPageTutorialProjection.fromState(AppState state) =>
      MainPageTutorialProjection(
        visible: state.shouldShowFirstRunTutorial,
        moduleId: state.activeTutorialModuleId,
        stepId: state.activeTutorialStepId,
      );

  final bool visible;
  final String? moduleId;
  final String? stepId;

  @override
  bool operator ==(Object other) =>
      other is MainPageTutorialProjection &&
      other.visible == visible &&
      other.moduleId == moduleId &&
      other.stepId == stepId;

  @override
  int get hashCode => Object.hash(visible, moduleId, stepId);
}

@immutable
class MainPageAnalyticsProjection {
  const MainPageAnalyticsProjection({
    required this.analytics,
    required this.weeklyGoalCount,
    required this.latestWeeklyGoalUpdate,
  });

  factory MainPageAnalyticsProjection.fromState(AppState state) {
    final latestUpdate = state.weeklyGoals.fold<DateTime?>(
      null,
      (latest, goal) => latest == null || goal.updatedAt.isAfter(latest)
          ? goal.updatedAt
          : latest,
    );
    return MainPageAnalyticsProjection(
      analytics: state.currentAnalytics,
      weeklyGoalCount: state.weeklyGoals.length,
      latestWeeklyGoalUpdate: latestUpdate,
    );
  }

  final AnalyticsReadModel analytics;
  final int weeklyGoalCount;
  final DateTime? latestWeeklyGoalUpdate;

  @override
  bool operator ==(Object other) =>
      other is MainPageAnalyticsProjection &&
      identical(other.analytics, analytics) &&
      other.weeklyGoalCount == weeklyGoalCount &&
      other.latestWeeklyGoalUpdate == latestWeeklyGoalUpdate;

  @override
  int get hashCode => Object.hash(
    identityHashCode(analytics),
    weeklyGoalCount,
    latestWeeklyGoalUpdate,
  );
}

class MainPageAnalyticsBoundary extends StatelessWidget {
  const MainPageAnalyticsBoundary({
    super.key,
    required this.state,
    required this.builder,
  });

  final AppState state;
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return AppStateSelector<MainPageAnalyticsProjection>(
      state: state,
      selector: MainPageAnalyticsProjection.fromState,
      builder: (context, projection, child) => builder(context),
    );
  }
}

@immutable
class MainPageSettingsProjection {
  const MainPageSettingsProjection({
    required this.isDark,
    required this.sfxEnabled,
    required this.tooltipsEnabled,
    required this.reducedMotion,
    required this.persistenceStatus,
  });

  factory MainPageSettingsProjection.fromState(AppState state) =>
      MainPageSettingsProjection(
        isDark: state.isDark,
        sfxEnabled: state.sfxEnabled,
        tooltipsEnabled: state.tooltipsEnabled,
        reducedMotion: state.reducedMotion,
        persistenceStatus: state.persistenceStatus,
      );

  final bool isDark;
  final bool sfxEnabled;
  final bool tooltipsEnabled;
  final bool reducedMotion;
  final PersistenceStatus persistenceStatus;

  @override
  bool operator ==(Object other) =>
      other is MainPageSettingsProjection &&
      other.isDark == isDark &&
      other.sfxEnabled == sfxEnabled &&
      other.tooltipsEnabled == tooltipsEnabled &&
      other.reducedMotion == reducedMotion &&
      other.persistenceStatus == persistenceStatus;

  @override
  int get hashCode => Object.hash(
    isDark,
    sfxEnabled,
    tooltipsEnabled,
    reducedMotion,
    persistenceStatus,
  );
}

class MainPageSettingsBoundary extends StatelessWidget {
  const MainPageSettingsBoundary({
    super.key,
    required this.state,
    required this.builder,
  });

  final AppState state;
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return AppStateSelector<MainPageSettingsProjection>(
      state: state,
      selector: MainPageSettingsProjection.fromState,
      builder: (context, projection, child) => builder(context),
    );
  }
}
