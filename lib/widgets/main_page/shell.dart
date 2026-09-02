part of '../main_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class MainPage extends StatefulWidget {
  final AppState state;
  final VoidCallback onToggleTheme;
  final VoidCallback? onWorkspaceBuildForTesting;
  final VoidCallback? onProfileBuildForTesting;
  final VoidCallback? onTutorialBuildForTesting;
  final VoidCallback? onEventNotificationForTesting;
  final DateTime Function()? nowForTesting;

  const MainPage({
    super.key,
    required this.state,
    required this.onToggleTheme,
    this.onWorkspaceBuildForTesting,
    this.onProfileBuildForTesting,
    this.onTutorialBuildForTesting,
    this.onEventNotificationForTesting,
    this.nowForTesting,
  });
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const _debugAdminTapWindow = Duration(seconds: 4);
  static const _debugAdminRequiredTaps = 5;

  final List<XPBubble> _bubbles = [];
  final GlobalKey _pageStackKey = GlobalKey();
  final GlobalKey _desktopContextualToastHostKey = GlobalKey();
  final GlobalKey _desktopRightRailKey = GlobalKey();
  final GlobalKey _roadmapInspectorKey = GlobalKey();
  late final GuidedTourAppCoordinator _guidedTour;
  final GuidedTourSurfaceController _guidedTourSurfaces =
      GuidedTourSurfaceController();
  final GlobalKey<_MobileActJournalState> _mobileActJournalKey = GlobalKey();
  final ReturnContextController _returnContextController =
      ReturnContextController();
  WorkspaceMode _mode = WorkspaceMode.act;
  WorkspaceMode _lastNormalMode = WorkspaceMode.act;
  final List<RewardNoticeData> _rewardNoticeQueue = [];
  GoalMilestoneEvent? _goalMilestoneNotice;
  AppState? _eventState;
  int _nextRewardNoticeId = 0;
  int _nextToastEventSeed = 1;
  int _debugAdminTapCount = 0;
  Timer? _debugAdminTapResetTimer;
  bool _firstRunDialogOpen = false;
  final MobileSecondaryNavigator _mobileSecondaryNavigator =
      MobileSecondaryNavigator();
  String? _roadmapFocusSkillId;
  String? _roadmapFocusNodeId;

  @override
  void initState() {
    super.initState();
    _guidedTour = GuidedTourAppCoordinator(
      currentDestination: _currentGuidedTourDestination,
      openDestination: _openGuidedTourDestination,
      waitForDestination: _guidedTourSurfaces.waitFor,
      isMounted: () => mounted,
      hasMinimumAction: () => _hasTutorialMinimumAction(widget.state),
      hasRoadmapPractice: () => _hasTutorialRoadmapPractice(widget.state),
      onCreateSkill: () => _addSkill(context, showTutorialHints: true),
      onCreateQuest: () =>
          _openFirstQuestDialog(context, widget.state, showTutorialHints: true),
      onAcknowledgeNextAction: () =>
          widget.state.completeTutorialStep(TutorialStepIds.coreCompleteQuest),
      onDismissFirstRun: () => widget.state.dismissActiveTutorial(),
      onCompleteModule: (moduleId) =>
          widget.state.completeTutorialModule(moduleId),
      onTutorialChanged: widget.onTutorialBuildForTesting,
    );
    _bindEventState(widget.state);
    _syncGuidedTourFromState(widget.state);
  }

  @override
  void didUpdateWidget(MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.state, widget.state)) {
      _returnContextController.reset();
      _bindEventState(widget.state);
      _syncGuidedTourFromState(widget.state);
    }
  }

  void _bindEventState(AppState state) {
    if (identical(_eventState, state)) return;
    _eventState?.removeListener(_handleStateEvents);
    _eventState = state;
    state.addListener(_handleStateEvents);
  }

  @override
  void dispose() {
    _eventState?.removeListener(_handleStateEvents);
    _debugAdminTapResetTimer?.cancel();
    _guidedTour.dispose();
    _guidedTourSurfaces.dispose();
    super.dispose();
  }

  void _handleDebugAdminTap(AppState state) {
    if (kReleaseMode) return;
    _debugAdminTapResetTimer?.cancel();
    _debugAdminTapCount++;

    if (_debugAdminTapCount < _debugAdminRequiredTaps) {
      _debugAdminTapResetTimer = Timer(_debugAdminTapWindow, () {
        _debugAdminTapCount = 0;
        _debugAdminTapResetTimer = null;
      });
      return;
    }

    _debugAdminTapCount = 0;
    _debugAdminTapResetTimer = null;
    AppFeedback.selection();
    showDebugAdminPanel(context, state: state);
  }

  void _showBubble(
    String message,
    ActionToastOrigin origin, {
    required CompletionToastColors colors,
  }) {
    final isMilestone = AppFeedback.isMilestoneMessage(message);
    final toastRegion = _resolveActionToastSafeRegion(origin);
    final stackSize = _pageStackSize;
    final available = toastRegion ?? (Offset.zero & stackSize);
    final sourceRect = _sourceRectInStack(origin, available);
    final seededOrigin = origin.withEventSeed(_nextToastEventSeed++);
    final placement = ActionToastPlacement.resolve(
      sourceRect: sourceRect,
      kind: seededOrigin.kind,
      zone: seededOrigin.zone,
      viewport: stackSize,
      safeRegion: toastRegion,
      jitter: ActionToastPlacement.stableJitter(
        seededOrigin.eventSeed,
        seededOrigin.kind,
        seededOrigin.zone,
      ),
      bottomReserved:
          seededOrigin.zone == ActionToastZone.mobileContent ||
              seededOrigin.zone == ActionToastZone.mobileBottomContextual
          ? 96
          : 0,
    );
    setState(() {
      _bubbles.add(
        XPBubble(
          key: UniqueKey(),
          message: message,
          placement: placement,
          colors: colors,
          showConfetti: true,
          confettiBuilder: (color) => MilestoneConfettiBurst(
            color: color,
            intensity: isMilestone
                ? RewardConfettiIntensity.milestone
                : RewardConfettiIntensity.subtle,
            particles: isMilestone ? 22 : 8,
          ),
          reducedMotion: _eventState?.reducedMotion ?? false,
          onDone: (k) =>
              setState(() => _bubbles.removeWhere((b) => b.key == k)),
        ),
      );
    });
  }

  Size get _pageStackSize {
    final renderObject = _pageStackKey.currentContext?.findRenderObject();
    return renderObject is RenderBox && renderObject.hasSize
        ? renderObject.size
        : MediaQuery.sizeOf(context);
  }

  Rect? _stackRectFor(GlobalKey key) {
    final stack = _pageStackKey.currentContext?.findRenderObject();
    final source = key.currentContext?.findRenderObject();
    if (stack is! RenderBox ||
        source is! RenderBox ||
        !stack.hasSize ||
        !source.hasSize) {
      return null;
    }
    return Rect.fromPoints(
      stack.globalToLocal(source.localToGlobal(Offset.zero)),
      stack.globalToLocal(
        source.localToGlobal(source.size.bottomRight(Offset.zero)),
      ),
    );
  }

  Rect _sourceRectInStack(ActionToastOrigin origin, Rect fallbackRegion) {
    final stack = _pageStackKey.currentContext?.findRenderObject();
    if (stack is RenderBox && stack.hasSize && origin.hasSourceRect) {
      return Rect.fromPoints(
        stack.globalToLocal(origin.globalSourceRect.topLeft),
        stack.globalToLocal(origin.globalSourceRect.bottomRight),
      );
    }
    // Only keyboard/fallback actions should reach this branch. Pointer-driven
    // completion paths capture their concrete control rect before mutation.
    return Rect.fromCenter(center: fallbackRegion.center, width: 1, height: 1);
  }

  Rect? _resolveActionToastSafeRegion(ActionToastOrigin origin) {
    final pageBounds = Offset.zero & _pageStackSize;
    final main = _stackRectFor(_desktopContextualToastHostKey);
    final rightRail = _stackRectFor(_desktopRightRailKey);
    final canvas = _stackRectFor(
      _guidedTour.anchors.keyFor(TutorialAnchorId.roadmapCanvas),
    );
    final inspector = _stackRectFor(_roadmapInspectorKey);
    return switch (origin.zone) {
      ActionToastZone.rightRail => rightRail ?? main ?? pageBounds,
      ActionToastZone.roadmapInspector => inspector ?? main ?? pageBounds,
      ActionToastZone.roadmapCanvas => canvas ?? main ?? pageBounds,
      ActionToastZone.mainWorkspace => main ?? pageBounds,
      ActionToastZone.mobileContent ||
      ActionToastZone.mobileBottomContextual => pageBounds,
      ActionToastZone.fallback => main ?? pageBounds,
    };
  }

  void _showRewardNotifications(AppState state) {
    final chests = state.consumeRewardChestNotifications();
    final buffs = state.consumeBuffNotifications();
    final achievements = state.consumeAchievementNotifications();
    if ((chests.isEmpty && buffs.isEmpty && achievements.isEmpty) || !mounted) {
      return;
    }
    if (achievements.isNotEmpty) {
      AppFeedback.milestone();
    } else if (chests.isNotEmpty) {
      AppFeedback.reward();
    }

    final notice = RewardNoticeData(
      id: _nextRewardNoticeId++,
      chestTitles: chests.map((chest) => chest.title).toList(),
      buffTitles: buffs.map((buff) => buff.title).toList(),
      achievementTitles: achievements
          .map((achievement) => achievement.def?.name ?? 'Достижение')
          .toList(),
    );
    // Avoid replaying the same recovered reward batch.
    if (_rewardNoticeQueue.any(
      (queued) => queued.signature == notice.signature,
    )) {
      return;
    }
    setState(() => _rewardNoticeQueue.add(notice));
  }

  void _handleStateEvents() {
    final state = _eventState;
    if (state == null || !mounted) return;
    widget.onEventNotificationForTesting?.call();
    _syncGuidedTourFromState(state);
    _showGoalMilestoneNotifications(state);
  }

  void _showGoalMilestoneNotifications(AppState state) {
    final events = state.consumeGoalMilestoneNotifications();
    if (events.isEmpty || !mounted) return;
    setState(() => _goalMilestoneNotice = events.last);
  }

  void _openMilestoneRoadmap(AppState state, GoalMilestoneEvent event) {
    final skill = state.roadmapSkills
        .where((item) => item.id == event.skillId)
        .firstOrNull;
    if (skill == null) return;
    _openRoadmapForSkill(state, skill);
  }

  bool get _usesMobileWorkspaceRoutes =>
      MobileResponsiveMetrics.isMobileWidth(MediaQuery.sizeOf(context).width);

  Future<void> _openMobileWorkspaceRoute(
    WidgetBuilder pageBuilder, {
    bool allowNested = false,
  }) => _mobileSecondaryNavigator.push(
    context,
    pageBuilder,
    allowNested: allowNested,
  );

  void _openRewardsDialog(AppState state, {bool nestedMobileRoute = false}) {
    AppFeedback.selection();
    setState(() => _rewardNoticeQueue.clear());
    if (_usesMobileWorkspaceRoutes) {
      _openMobileWorkspaceRoute(
        (_) => RewardsDialog(state: state, fullScreen: true),
        allowNested: nestedMobileRoute,
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => RewardsDialog(state: state),
    );
  }

  void _openDailyVictoriesDialog(
    AppState state, {
    bool nestedMobileRoute = false,
  }) {
    if (_usesMobileWorkspaceRoutes) {
      _openMobileWorkspaceRoute(
        (_) => DailyVictoriesDialog(state: state, fullScreen: true),
        allowNested: nestedMobileRoute,
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => DailyVictoriesDialog(state: state),
    );
  }

  void _openCharacterTimelineDialog(
    AppState state, {
    bool nestedMobileRoute = false,
  }) {
    if (_usesMobileWorkspaceRoutes) {
      _openMobileWorkspaceRoute(
        (_) => CharacterTimelineDialog(state: state, fullScreen: true),
        allowNested: nestedMobileRoute,
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => CharacterTimelineDialog(state: state),
    );
  }

  void _openWeeklyDialog(AppState state, {bool nestedMobileRoute = false}) {
    if (_usesMobileWorkspaceRoutes) {
      _openMobileWorkspaceRoute(
        (_) => WeeklyAnalyticsDialog(state: state, fullScreen: true),
        allowNested: nestedMobileRoute,
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => WeeklyAnalyticsDialog(state: state),
    );
  }

  void _openGrowthSliceDialog(AppState state) {
    showDialog(
      context: context,
      builder: (_) => StatsDialog(state: state),
    );
  }

  void _openCalendarDialog(AppState state) {
    showDialog(
      context: context,
      builder: (_) => CalendarDialog(state: state),
    );
  }

  void _openBossesDialog(AppState state) {
    showDialog(
      context: context,
      builder: (_) => BossesDialog(state: state),
    );
  }

  void _openAchievementsDialog(AppState state) {
    showDialog(
      context: context,
      builder: (_) => AchievementsDialog(
        achievements: state.achievements,
        isDark: state.isDark,
      ),
    );
  }

  void _openHistoryDialog(AppState state) {
    showDialog(
      context: context,
      builder: (_) =>
          HistoryDialog(history: state.history, isDark: state.isDark),
    );
  }

  Widget _buildStatisticsWorkspace(
    AppState state,
    bool isDark, {
    Key? summaryTutorialKey,
  }) {
    return ProgressWorkspace(
      key: const ValueKey('stats-workspace'),
      state: state,
      isDark: isDark,
      summaryTutorialKey: summaryTutorialKey,
      onClose: () => setState(() => _mode = _lastNormalMode),
      destinations: _progressDestinations(state),
    );
  }

  ProgressWorkspaceDestinations _progressDestinations(
    AppState state, {
    bool nestedMobileRoutes = false,
  }) {
    return ProgressWorkspaceDestinations(
      onOpenDailyVictories: () => _openDailyVictoriesDialog(
        state,
        nestedMobileRoute: nestedMobileRoutes,
      ),
      onOpenCharacterTimeline: () => _openCharacterTimelineDialog(
        state,
        nestedMobileRoute: nestedMobileRoutes,
      ),
      onOpenWeekly: () =>
          _openWeeklyDialog(state, nestedMobileRoute: nestedMobileRoutes),
      onOpenStats: () => _openGrowthSliceDialog(state),
      onOpenCalendar: () => _openCalendarDialog(state),
      onOpenBosses: () => _openBossesDialog(state),
      onOpenAchievements: () => _openAchievementsDialog(state),
      onOpenHistory: () => _openHistoryDialog(state),
      onOpenRewards: () =>
          _openRewardsDialog(state, nestedMobileRoute: nestedMobileRoutes),
    );
  }

  Widget _buildMobileStatisticsPage(
    AppState state,
    bool isDark, {
    Key? summaryTutorialKey,
  }) {
    return MobileStatisticsPage(
      state: state,
      isDark: isDark,
      summaryTutorialKey: summaryTutorialKey,
      destinations: _progressDestinations(state, nestedMobileRoutes: true),
    );
  }

  bool _hasTutorialMinimumAction(AppState state) => state.tasks.any(
    (task) =>
        !task.isDone &&
        !task.isMinimumActionDone &&
        task.minimumAction.trim().isNotEmpty,
  );

  bool _hasTutorialRoadmapPractice(AppState state) =>
      state.roadmapSkills.any((skill) => skill.treeNodes.isNotEmpty);

  void _syncGuidedTourFromState(AppState state) =>
      _guidedTour.syncPersistedState(
        shouldShowFirstRun: state.shouldShowFirstRunTutorial,
        activeModuleId: state.activeTutorialModuleId,
        activeStepId: state.activeTutorialStepId,
        coreCompleted: state.tutorialProgress.isModuleCompleted(
          TutorialModuleIds.core,
        ),
      );

  GuidedTourDestination _currentGuidedTourDestination() {
    final rootDestination = switch (_mode) {
      WorkspaceMode.mastery => GuidedTourDestination.roadmap,
      WorkspaceMode.stats => GuidedTourDestination.statistics,
      WorkspaceMode.rewards => GuidedTourDestination.trophies,
      _ => GuidedTourDestination.act,
    };
    return _guidedTourSurfaces.currentDestination(rootDestination);
  }

  Future<void> _openGuidedTourDestination(
    GuidedTourDestination destination,
  ) async {
    final state = widget.state;
    switch (destination) {
      case GuidedTourDestination.act:
        await _closeGuidedTourSurface();
        if (!mounted) return;
        setState(() {
          _mode = WorkspaceMode.act;
          _lastNormalMode = WorkspaceMode.act;
        });
        return;
      case GuidedTourDestination.roadmap:
        await _closeGuidedTourSurface();
        if (!mounted) return;
        _guidedTourSurfaces.beginRoadmapReadiness();
        final selected = state.selectedSkill;
        final skill = selected?.id == kInboxSkillId
            ? state.roadmapSkills.firstOrNull
            : selected ?? state.roadmapSkills.firstOrNull;
        final nodeId =
            _guidedTour.controller.session?.plan.steps.any(
                  (step) => step.anchorId == TutorialAnchorId.roadmapPractice,
                ) ==
                true
            ? skill?.treeNodes.firstOrNull?.id
            : null;
        setState(() {
          _roadmapFocusSkillId = skill?.id;
          _roadmapFocusNodeId = nodeId;
          _mode = WorkspaceMode.mastery;
          _lastNormalMode = WorkspaceMode.mastery;
        });
        return;
      case GuidedTourDestination.statistics:
        await _closeGuidedTourSurface();
        if (!mounted) return;
        if (_usesMobileWorkspaceRoutes) {
          _openGuidedTourMobileStatistics(state);
        } else {
          setState(() => _mode = WorkspaceMode.stats);
        }
        return;
      case GuidedTourDestination.trophies:
        await _closeGuidedTourSurface();
        if (!mounted) return;
        if (_usesMobileWorkspaceRoutes) {
          _openGuidedTourMobileTrophies(state);
        } else {
          setState(() => _mode = WorkspaceMode.rewards);
        }
        return;
      case GuidedTourDestination.profile:
        await _closeGuidedTourSurface();
        if (!mounted) return;
        _openProfileSurface(state, guidedTour: true);
        return;
    }
  }

  int _prepareGuidedTourSurface(GuidedTourSurface surface) {
    final generation = _guidedTourSurfaces.prepare(surface);
    setState(() {});
    return generation;
  }

  void _registerGuidedTourSurfaceContext(BuildContext routeContext) {
    _guidedTourSurfaces.registerRouteContext(routeContext);
  }

  void _openGuidedTourMobileStatistics(AppState state) {
    final generation = _prepareGuidedTourSurface(GuidedTourSurface.statistics);
    unawaited(
      _openMobileWorkspaceRoute((routeContext) {
        _registerGuidedTourSurfaceContext(routeContext);
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildMobileStatisticsPage(
              state,
              state.isDark,
              summaryTutorialKey: _guidedTour.anchors.keyFor(
                TutorialAnchorId.statisticsSummary,
              ),
            ),
            _buildGuidedTourOverlay(
              state: state,
              mobile: true,
              surface: GuidedTourSurface.statistics,
            ),
          ],
        );
      }).whenComplete(
        () => _handleGuidedTourSurfaceClosed(
          GuidedTourSurface.statistics,
          generation,
        ),
      ),
    );
  }

  void _openGuidedTourMobileTrophies(AppState state) {
    final generation = _prepareGuidedTourSurface(GuidedTourSurface.trophies);
    unawaited(
      _openMobileWorkspaceRoute((routeContext) {
        _registerGuidedTourSurfaceContext(routeContext);
        return Stack(
          fit: StackFit.expand,
          children: [
            RewardsDialog(
              state: state,
              fullScreen: true,
              summaryTutorialKey: _guidedTour.anchors.keyFor(
                TutorialAnchorId.trophiesSummary,
              ),
            ),
            _buildGuidedTourOverlay(
              state: state,
              mobile: true,
              surface: GuidedTourSurface.trophies,
            ),
          ],
        );
      }).whenComplete(
        () => _handleGuidedTourSurfaceClosed(
          GuidedTourSurface.trophies,
          generation,
        ),
      ),
    );
  }

  void _openProfileSurface(AppState state, {bool guidedTour = false}) {
    final mobile = _usesMobileWorkspaceRoutes;
    var generation = _guidedTourSurfaces.generation;
    if (guidedTour) {
      generation = _prepareGuidedTourSurface(GuidedTourSurface.profile);
    }

    Widget buildProfile(BuildContext routeContext, {required bool fullScreen}) {
      if (guidedTour) _registerGuidedTourSurfaceContext(routeContext);
      return AppStateProvider(
        state: state,
        child: ProfileDialog(
          fullScreen: fullScreen,
          onToggleTheme: widget.onToggleTheme,
          tutorialSession: _guidedTour.controller.snapshot,
          onTutorialSelection: _guidedTour.handleTrainingSelection,
          tutorialTrainingKey: _guidedTour.anchors.keyFor(
            TutorialAnchorId.profileTraining,
          ),
          tutorialOverlay: guidedTour
              ? _buildGuidedTourOverlay(
                  state: state,
                  mobile: mobile,
                  surface: GuidedTourSurface.profile,
                )
              : null,
        ),
      );
    }

    final route = mobile
        ? _openMobileWorkspaceRoute(
            (routeContext) => buildProfile(routeContext, fullScreen: true),
          )
        : showDialog<void>(
            context: context,
            builder: (dialogContext) =>
                buildProfile(dialogContext, fullScreen: false),
          );
    if (guidedTour) {
      unawaited(
        route.whenComplete(
          () => _handleGuidedTourSurfaceClosed(
            GuidedTourSurface.profile,
            generation,
          ),
        ),
      );
    }
  }

  Future<void> _closeGuidedTourSurface() async {
    final changed = await _guidedTourSurfaces.close();
    if (changed && mounted) setState(() {});
  }

  void _handleGuidedTourSurfaceClosed(
    GuidedTourSurface surface,
    int generation,
  ) {
    if (!mounted) return;
    final interrupted = _guidedTourSurfaces.handleRouteClosed(
      surface,
      generation,
    );
    setState(() {});
    if (interrupted && _guidedTour.controller.hasActiveSession) {
      _guidedTour.controller.pause();
    }
  }

  Widget _buildGuidedTourOverlay({
    required AppState state,
    required bool mobile,
    required GuidedTourSurface surface,
  }) {
    if (!_guidedTourSurfaces.matches(surface)) {
      return const SizedBox.shrink();
    }
    final rightRail = mobile ? null : _stackRectFor(_desktopRightRailKey);
    final reserved = <Rect>[?rightRail];
    return Stack(
      fit: StackFit.expand,
      children: [
        GuidedTourHost(
          controller: _guidedTour.controller,
          anchors: _guidedTour.anchors,
          isDark: state.isDark,
          reducedMotion: state.reducedMotion,
          mobile: mobile,
          blocked: _firstRunDialogOpen,
          reservedRegions: reserved,
          onPrimary: _guidedTour.primary,
          onSkip: (_) => _guidedTour.skipAbandonedStep(),
          onDismiss: _guidedTour.dismiss,
          onPrevious: _guidedTour.previous,
        ),
        if (surface == GuidedTourSurface.root)
          ListenableBuilder(
            listenable: _guidedTour.controller,
            builder: (context, child) =>
                _guidedTour.controller.showCoreCompletion
                ? TutorialCompletionCard(
                    isDark: state.isDark,
                    reducedMotion: state.reducedMotion,
                    onShowRest: _guidedTour.showRestOfTour,
                    onStartUsing: _guidedTour.startUsingAfterCore,
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  void _onComplete(String taskId, ActionToastOrigin origin) {
    final s = widget.state;
    final colors = _completionToastColors(s, taskId);
    final msg = s.completeTask(taskId);
    if (msg == null) return;
    AppFeedback.questResult(msg);
    _showBubble(msg, origin, colors: colors);
    _showRewardNotifications(s);
  }

  void _onMinimumAction(String taskId, ActionToastOrigin origin) {
    final s = widget.state;
    final colors = _completionToastColors(s, taskId);
    final msg = s.completeMinimumAction(taskId);
    if (msg == null) return;
    AppFeedback.questResult(msg, isMinimum: true);
    _showBubble(msg, origin, colors: colors);
    _showRewardNotifications(s);
  }

  CompletionToastColors _completionToastColors(AppState state, String taskId) {
    Task? sourceTask;
    for (final task in state.tasks) {
      if (task.id == taskId) {
        sourceTask = task;
        break;
      }
    }
    return completionToastColorsForTask(task: sourceTask, skills: state.skills);
  }

  void _setFirstRunDialogOpen(bool value) {
    if (!mounted || _firstRunDialogOpen == value) return;
    setState(() => _firstRunDialogOpen = value);
  }

  void _openRoadmapForSkill(AppState state, Skill skill) {
    AppFeedback.selection();
    state.selectSkill(skill.id);
    setState(() {
      _roadmapFocusSkillId = skill.id;
      _roadmapFocusNodeId = null;
      _mode = WorkspaceMode.mastery;
      _lastNormalMode = WorkspaceMode.mastery;
    });
  }

  void _syncRoadmapFocusSkill(AppState state, String? skillId) {
    final validSkillId =
        skillId != null &&
            state.roadmapSkills.any((skill) => skill.id == skillId)
        ? skillId
        : null;
    final selected = state.selectedSkill;

    if (validSkillId == null) {
      if (selected != null && selected.id != kInboxSkillId) {
        state.clearSkillSelection();
      }
    } else if (state.selectedSkillId != validSkillId) {
      state.selectSkill(validSkillId);
    }

    if (_roadmapFocusSkillId == validSkillId && _roadmapFocusNodeId == null) {
      return;
    }
    setState(() {
      _roadmapFocusSkillId = validSkillId;
      _roadmapFocusNodeId = null;
    });
  }

  void _addSkill(BuildContext context, {bool showTutorialHints = false}) {
    final state = widget.state;
    if (showTutorialHints) {
      _setFirstRunDialogOpen(true);
    }
    showAdaptiveCreationForm<void>(
      context: context,
      builder: (_, fullScreen) => AddSkillDialog(
        isDark: state.isDark,
        fullScreen: fullScreen,
        showFirstRunHints: showTutorialHints,
        onSave: (name, goal, checklist, color, icon, initialTreeNodes, _) {
          final skillId = uid();
          state.addSkill(
            Skill(
              id: skillId,
              name: name,
              goal: goal,
              color: color,
              icon: icon,
              checklist: checklist,
              treeNodes: initialTreeNodes,
            ),
          );
          state.selectSkill(skillId);
          if (showTutorialHints ||
              state.activeTutorialModuleId == TutorialModuleIds.core) {
            state.completeTutorialStep(TutorialStepIds.coreCreateSkill);
          }
        },
      ),
    ).whenComplete(() {
      if (showTutorialHints) {
        _setFirstRunDialogOpen(false);
      }
    });
  }

  void _openFirstQuestDialog(
    BuildContext context,
    AppState state, {
    bool showTutorialHints = false,
  }) {
    final selected = state.selectedSkill;
    final skill = selected?.id == kInboxSkillId
        ? state.roadmapSkills.firstOrNull
        : selected ?? state.roadmapSkills.firstOrNull;
    if (skill == null) return;
    if (state.selectedSkillId != skill.id) {
      state.selectSkill(skill.id);
    }

    if (showTutorialHints) {
      _setFirstRunDialogOpen(true);
    }
    showAdaptiveCreationForm<void>(
      context: context,
      builder: (_, fullScreen) => AddTaskDialog(
        isDark: state.isDark,
        fullScreen: fullScreen,
        skillColor: skill.color,
        skill: skill,
        initialTreeNodeId: skill.treeNodes.firstOrNull?.id,
        showFirstRunHints: showTutorialHints,
        onSave:
            (
              title,
              description,
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
              state.addTask(
                Task(
                  id: uid(),
                  title: title,
                  description: description,
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
            },
      ),
    ).whenComplete(() {
      if (showTutorialHints) {
        _setFirstRunDialogOpen(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainPageWorkspaceBoundary(
      state: widget.state,
      onBuildForTesting: widget.onWorkspaceBuildForTesting,
      builder: (context, workspace) => LayoutBuilder(
        builder: (context, constraints) {
          final s = widget.state;
          final isDark = workspace.isDark;
          final desktopShell = DesktopResponsiveMetrics.isDesktopWidth(
            constraints.maxWidth,
          );
          final mobileShell = !desktopShell;
          final desktopMetrics = DesktopResponsiveMetrics.forWidth(
            constraints.maxWidth,
          );
          final displayedMode = _mode;
          final now = widget.nowForTesting?.call() ?? DateTime.now();
          final returnContextBinding = _returnContextController.bind(
            state: s,
            now: now,
            pauseThreshold: defaultReturnContextPauseThreshold,
            blocked: workspace.returnContextBlocked,
            onVisibilityChanged: () {
              if (mounted) setState(() {});
            },
            onDesktopSkillSelected: s.selectSkill,
            onMobileSkillSelected: (skillId) {
              final journal = _mobileActJournalKey.currentState;
              if (journal == null) return s.selectSkill(skillId);
              unawaited(journal.openSkillById(s, skillId));
            },
          );
          final returnContext = returnContextBinding?.candidate;
          final momentum = displayedMode == WorkspaceMode.act
              ? buildMomentumViewData(s, now, returnContext)
              : null;
          final roadmapFocusId = _validRoadmapSkillId(s, _roadmapFocusSkillId);
          void changeMode(WorkspaceMode mode) {
            if (_mode == mode) {
              if (mode == WorkspaceMode.act || mode == WorkspaceMode.mastery) {
                return;
              }
              setState(() {
                _rewardNoticeQueue.clear();
                _mode = _lastNormalMode;
              });
              return;
            }
            setState(() {
              _rewardNoticeQueue.clear();
              if (mode == WorkspaceMode.act || mode == WorkspaceMode.mastery) {
                _lastNormalMode = mode;
              } else if (_mode == WorkspaceMode.act ||
                  _mode == WorkspaceMode.mastery) {
                _lastNormalMode = _mode;
              }
              _mode = mode;
              if (mode == WorkspaceMode.mastery) {
                final selected = s.selectedSkill;
                _roadmapFocusSkillId =
                    selected == null || selected.id == kInboxSkillId
                    ? null
                    : selected.id;
                _roadmapFocusNodeId = null;
              }
            });
          }

          void openStatistics() {
            if (mobileShell) {
              final capturedState = s;
              _openMobileWorkspaceRoute(
                (_) => _buildMobileStatisticsPage(capturedState, isDark),
              );
            } else {
              changeMode(WorkspaceMode.stats);
            }
          }

          void openProfile() => _openProfileSurface(s);

          return Scaffold(
            backgroundColor: mobileShell
                ? _MobileJournalTokens.background(isDark)
                : isDark
                ? const Color(0xFF0F0F13)
                : const Color(0xFFF0F2F8),
            body: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                _guidedTour.anchors.notifyAnchorChanged();
                return false;
              },
              child: Stack(
                key: _pageStackKey,
                children: [
                  ValueListenableBuilder<TutorialAnchorId?>(
                    valueListenable: _guidedTour.controller.activeAnchor,
                    builder: (context, activeAnchor, child) {
                      GlobalKey? activeTutorialKey(TutorialAnchorId id) =>
                          activeAnchor == id
                          ? _guidedTour.anchors.keyFor(id)
                          : null;
                      return desktopShell
                          ? DesktopWorkspaceShell(
                              state: s,
                              mode: displayedMode,
                              metrics: desktopMetrics,
                              onModeChanged: changeMode,
                              onAddSkill: () => _addSkill(context),
                              onOpenRewards: () =>
                                  changeMode(WorkspaceMode.rewards),
                              onOpenStatistics: openStatistics,
                              onOpenSettings: () =>
                                  changeMode(WorkspaceMode.settings),
                              onOpenProfile: openProfile,
                              onDebugAppTap: !kReleaseMode
                                  ? () => _handleDebugAdminTap(s)
                                  : null,
                              onOpenRoadmap: (skill) =>
                                  _openRoadmapForSkill(s, skill),
                              onComplete: _onComplete,
                              onMinimumAction: _onMinimumAction,
                              returnContext: returnContext,
                              momentum: momentum,
                              onContinueReturnContext:
                                  returnContextBinding?.continueOnDesktop,
                              onAnotherReturnContext:
                                  returnContextBinding?.dismiss,
                              onDismissReturnContext:
                                  returnContextBinding?.dismiss,
                              contextualToastHostKey:
                                  _desktopContextualToastHostKey,
                              rightRailKey: _desktopRightRailKey,
                              profileKey: _guidedTour.anchors.keyFor(
                                TutorialAnchorId.profileEntry,
                              ),
                              skillCreateKey: _guidedTour.anchors.keyFor(
                                TutorialAnchorId.skillCreate,
                              ),
                              questCreateKey: activeTutorialKey(
                                TutorialAnchorId.questCreate,
                              ),
                              nextActionKey: activeTutorialKey(
                                TutorialAnchorId.actNextAction,
                              ),
                              rewardsKey: _guidedTour.anchors.keyFor(
                                TutorialAnchorId.navTrophies,
                              ),
                              roadmapKey: _guidedTour.anchors.keyFor(
                                TutorialAnchorId.navRoadmap,
                              ),
                              statsKey: _guidedTour.anchors.keyFor(
                                TutorialAnchorId.navStatistics,
                              ),
                              inboxKey: _guidedTour.anchors.keyFor(
                                TutorialAnchorId.actInbox,
                              ),
                              minimumActionTutorialKey: activeTutorialKey(
                                TutorialAnchorId.actMinimumAction,
                              ),
                              alternateWorkspace: switch (displayedMode) {
                                WorkspaceMode.mastery => _MasteryWorkspace(
                                  key: const ValueKey('mastery-workspace'),
                                  isDark: isDark,
                                  focusSkillId: roadmapFocusId,
                                  focusNodeId: _roadmapFocusNodeId,
                                  canvasTutorialKey: _guidedTour.anchors.keyFor(
                                    TutorialAnchorId.roadmapCanvas,
                                  ),
                                  inspectorTutorialKey: _roadmapInspectorKey,
                                  practiceTutorialKey: _guidedTour.anchors
                                      .keyFor(TutorialAnchorId.roadmapPractice),
                                  onInitialViewReady:
                                      _guidedTourSurfaces.reportRoadmapReady,
                                  onFocusSkillChanged: (skillId) =>
                                      _syncRoadmapFocusSkill(s, skillId),
                                  onComplete: _onComplete,
                                  onMinimumAction: _onMinimumAction,
                                ),
                                WorkspaceMode.rewards =>
                                  _DesktopRewardsWorkspace(
                                    key: const ValueKey(
                                      'desktop-rewards-workspace',
                                    ),
                                    state: s,
                                    tokens: DesktopJournalTokens.resolve(
                                      isDark,
                                    ),
                                    summaryTutorialKey: _guidedTour.anchors
                                        .keyFor(
                                          TutorialAnchorId.trophiesSummary,
                                        ),
                                  ),
                                WorkspaceMode.stats =>
                                  MainPageAnalyticsBoundary(
                                    state: s,
                                    builder: (context) =>
                                        _DesktopStatisticsWorkspace(
                                          key: const ValueKey(
                                            'desktop-statistics-workspace',
                                          ),
                                          state: s,
                                          tokens: DesktopJournalTokens.resolve(
                                            isDark,
                                          ),
                                          summaryTutorialKey: _guidedTour
                                              .anchors
                                              .keyFor(
                                                TutorialAnchorId
                                                    .statisticsSummary,
                                              ),
                                        ),
                                  ),
                                WorkspaceMode.settings =>
                                  MainPageSettingsBoundary(
                                    state: s,
                                    builder: (context) =>
                                        _DesktopSettingsWorkspace(
                                          key: const ValueKey(
                                            'desktop-settings-workspace',
                                          ),
                                          state: s,
                                          tokens: DesktopJournalTokens.resolve(
                                            isDark,
                                          ),
                                          onOpenProfile: openProfile,
                                          onToggleTheme: widget.onToggleTheme,
                                        ),
                                  ),
                                WorkspaceMode.act => null,
                              },
                            )
                          : Column(
                              children: [
                                MainPageProfileBoundary(
                                  key: _guidedTour.anchors.keyFor(
                                    TutorialAnchorId.profileEntry,
                                  ),
                                  state: s,
                                  onBuildForTesting:
                                      widget.onProfileBuildForTesting,
                                  builder: (context) => ProfileBar(
                                    isDark: isDark,
                                    mobile: true,
                                    state: s,
                                    onToggleTheme: widget.onToggleTheme,
                                    onRewardsTap: () => _openRewardsDialog(s),
                                    onStatsTap: openStatistics,
                                    onAppIconTap: !kReleaseMode
                                        ? () => _handleDebugAdminTap(s)
                                        : null,
                                    onProfileTap: () => openProfile(),
                                    rewardsKey: _guidedTour.anchors.keyFor(
                                      TutorialAnchorId.navTrophies,
                                    ),
                                    statsKey: _guidedTour.anchors.keyFor(
                                      TutorialAnchorId.navStatistics,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      0,
                                    ),
                                    child: MotionFadeSlideSwitcher(
                                      child: switch (displayedMode) {
                                        WorkspaceMode.act => _ActWorkspace(
                                          key: const ValueKey('act-workspace'),
                                          onComplete: _onComplete,
                                          onMinimumAction: _onMinimumAction,
                                          onCreateFirstSkill: () =>
                                              _addSkill(context),
                                          onOpenRoadmap: (skill) =>
                                              _openRoadmapForSkill(s, skill),
                                          createFirstSkillButtonKey: _guidedTour
                                              .anchors
                                              .keyFor(
                                                TutorialAnchorId.skillCreate,
                                              ),
                                          createFirstQuestButtonKey:
                                              activeTutorialKey(
                                                TutorialAnchorId.questCreate,
                                              ),
                                          nextQuestActionKey: activeTutorialKey(
                                            TutorialAnchorId.actNextAction,
                                          ),
                                          minimumActionTutorialKey:
                                              activeTutorialKey(
                                                TutorialAnchorId
                                                    .actMinimumAction,
                                              ),
                                          inboxTutorialKey: _guidedTour.anchors
                                              .keyFor(
                                                TutorialAnchorId.actInbox,
                                              ),
                                          mobileJournalKey:
                                              _mobileActJournalKey,
                                          returnContext: returnContext,
                                          momentum: momentum,
                                          onContinueReturnContext:
                                              returnContextBinding
                                                  ?.continueOnMobile,
                                          onAnotherReturnContext:
                                              returnContextBinding?.dismiss,
                                          onDismissReturnContext:
                                              returnContextBinding?.dismiss,
                                        ),
                                        WorkspaceMode.mastery =>
                                          _MasteryWorkspace(
                                            key: const ValueKey(
                                              'mastery-workspace',
                                            ),
                                            isDark: isDark,
                                            focusSkillId: roadmapFocusId,
                                            focusNodeId: _roadmapFocusNodeId,
                                            canvasTutorialKey: _guidedTour
                                                .anchors
                                                .keyFor(
                                                  TutorialAnchorId
                                                      .roadmapCanvas,
                                                ),
                                            inspectorTutorialKey:
                                                _roadmapInspectorKey,
                                            practiceTutorialKey: _guidedTour
                                                .anchors
                                                .keyFor(
                                                  TutorialAnchorId
                                                      .roadmapPractice,
                                                ),
                                            onInitialViewReady:
                                                _guidedTourSurfaces
                                                    .reportRoadmapReady,
                                            onFocusSkillChanged: (skillId) =>
                                                _syncRoadmapFocusSkill(
                                                  s,
                                                  skillId,
                                                ),
                                            onComplete: _onComplete,
                                            onMinimumAction: _onMinimumAction,
                                          ),
                                        WorkspaceMode.stats =>
                                          MainPageAnalyticsBoundary(
                                            state: s,
                                            builder: (context) =>
                                                _buildStatisticsWorkspace(
                                                  s,
                                                  isDark,
                                                  summaryTutorialKey: _guidedTour
                                                      .anchors
                                                      .keyFor(
                                                        TutorialAnchorId
                                                            .statisticsSummary,
                                                      ),
                                                ),
                                          ),
                                        WorkspaceMode.rewards =>
                                          const SizedBox.shrink(),
                                        WorkspaceMode.settings =>
                                          const SizedBox.shrink(),
                                      },
                                    ),
                                  ),
                                ),
                                _MobileWorkspaceNav(
                                  mode: displayedMode,
                                  isDark: isDark,
                                  reducedMotion: workspace.reducedMotion,
                                  onChanged: changeMode,
                                  onReselectCurrent:
                                      displayedMode == WorkspaceMode.act
                                      ? _mobileActJournalKey
                                            .currentState
                                            ?.collapseInbox
                                      : null,
                                  roadmapKey: _guidedTour.anchors.keyFor(
                                    TutorialAnchorId.navRoadmap,
                                  ),
                                ),
                              ],
                            );
                    },
                  ),
                  if (_rewardNoticeQueue.isNotEmpty)
                    RewardNoticePopover(
                      notice: _rewardNoticeQueue.first,
                      isDark: isDark,
                      desktop: desktopShell,
                      desktopMetrics: desktopMetrics,
                      reducedMotion: workspace.reducedMotion,
                      queuedCount: _rewardNoticeQueue.length,
                      onShow: () => _openRewardsDialog(s),
                      onHide: () {
                        if (!mounted || _rewardNoticeQueue.isEmpty) return;
                        setState(() => _rewardNoticeQueue.removeAt(0));
                      },
                    ),
                  if (_goalMilestoneNotice != null)
                    GoalMilestoneBanner(
                      key: ValueKey(
                        'goal-milestone-${_goalMilestoneNotice!.id}',
                      ),
                      event: _goalMilestoneNotice!,
                      isDark: isDark,
                      onDismiss: () =>
                          setState(() => _goalMilestoneNotice = null),
                      onOpenRoadmap:
                          _goalMilestoneNotice!.milestone ==
                              GoalMilestone.complete
                          ? () {
                              final event = _goalMilestoneNotice;
                              if (event == null) return;
                              setState(() => _goalMilestoneNotice = null);
                              _openMilestoneRoadmap(s, event);
                            }
                          : null,
                    ),
                  _buildGuidedTourOverlay(
                    state: s,
                    mobile: mobileShell,
                    surface: GuidedTourSurface.root,
                  ),
                  ..._bubbles,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
