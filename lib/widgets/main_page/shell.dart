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

  const MainPage({
    super.key,
    required this.state,
    required this.onToggleTheme,
    this.onWorkspaceBuildForTesting,
    this.onProfileBuildForTesting,
    this.onTutorialBuildForTesting,
    this.onEventNotificationForTesting,
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
  final GlobalKey _rewardsButtonKey = GlobalKey();
  final GlobalKey _firstSkillCtaKey = GlobalKey();
  final GlobalKey _firstQuestCtaKey = GlobalKey();
  final GlobalKey _nextQuestActionKey = GlobalKey();
  final GlobalKey _roadmapNavKey = GlobalKey();
  final GlobalKey _statsButtonKey = GlobalKey();
  final GlobalKey _roadmapCanvasKey = GlobalKey();
  final GlobalKey _roadmapInspectorKey = GlobalKey();
  final GlobalKey _roadmapPracticeKey = GlobalKey();
  final GlobalKey _profileBarKey = GlobalKey();
  final GlobalKey<_MobileActJournalState> _mobileActJournalKey = GlobalKey();
  WorkspaceMode _mode = WorkspaceMode.act;
  WorkspaceMode _lastNormalMode = WorkspaceMode.act;
  final List<_RewardNotice> _rewardNoticeQueue = [];
  GoalMilestoneEvent? _goalMilestoneNotice;
  AppState? _eventState;
  int _nextRewardNoticeId = 0;
  int _nextToastEventSeed = 1;
  int _debugAdminTapCount = 0;
  Timer? _debugAdminTapResetTimer;
  bool _firstRunDialogOpen = false;
  bool _statsTutorialActive = false;
  bool _rewardsTutorialActive = false;
  bool _mobileWorkspaceRouteOpen = false;
  String? _roadmapFocusSkillId;

  @override
  void initState() {
    super.initState();
    _bindEventState(widget.state);
  }

  @override
  void didUpdateWidget(MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.state, widget.state)) {
      _bindEventState(widget.state);
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
    final canvas = _stackRectFor(_roadmapCanvasKey);
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

    final notice = _RewardNotice(
      id: _nextRewardNoticeId++,
      chestTitles: chests.map((chest) => chest.title).toList(),
      buffTitles: buffs.map((buff) => buff.title).toList(),
      achievementTitles: achievements
          .map((achievement) => achievement.def?.name ?? 'Достижение')
          .toList(),
    );
    // Notification sources may be consumed by consecutive completion events.
    // Keep distinct rewards, but avoid showing the same recovered batch twice.
    if (_rewardNoticeQueue.any(
      (queued) => queued.signature == notice.signature,
    )) {
      return;
    }
    setState(() {
      if (_rewardNoticeQueue.length == 3) _rewardNoticeQueue.removeLast();
      _rewardNoticeQueue.add(notice);
    });
  }

  void _handleStateEvents() {
    final state = _eventState;
    if (state == null || !mounted) return;
    widget.onEventNotificationForTesting?.call();
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

  Future<void> _openMobileWorkspaceRoute(Widget Function() pageBuilder) async {
    if (!mounted || _mobileWorkspaceRouteOpen) return;
    setState(() => _mobileWorkspaceRouteOpen = true);
    try {
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => pageBuilder(),
        ),
      );
    } finally {
      if (mounted) setState(() => _mobileWorkspaceRouteOpen = false);
    }
  }

  void _openRewardsDialog(AppState state, {bool showTutorialHint = false}) {
    AppFeedback.selection();
    setState(() {
      _rewardNoticeQueue.clear();
      if (showTutorialHint) _rewardsTutorialActive = true;
    });
    if (_usesMobileWorkspaceRoutes) {
      _openMobileWorkspaceRoute(
        () => RewardsDialog(
          state: state,
          fullScreen: true,
          showTutorialHint: showTutorialHint,
          onTutorialComplete: showTutorialHint
              ? () {
                  _completeRewardsTutorial(state);
                  Navigator.of(context, rootNavigator: true).maybePop();
                  if (mounted) {
                    setState(() => _rewardsTutorialActive = false);
                  }
                }
              : null,
        ),
      ).whenComplete(() {
        if (showTutorialHint && mounted) {
          setState(() => _rewardsTutorialActive = false);
        }
      });
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => RewardsDialog(
        state: state,
        showTutorialHint: showTutorialHint,
        onTutorialComplete: showTutorialHint
            ? () {
                _completeRewardsTutorial(state);
                Navigator.of(dialogContext).maybePop();
                if (mounted) setState(() => _rewardsTutorialActive = false);
              }
            : null,
      ),
    ).whenComplete(() {
      if (showTutorialHint && mounted) {
        setState(() => _rewardsTutorialActive = false);
      }
    });
  }

  void _openDailyVictoriesDialog(AppState state) {
    if (_usesMobileWorkspaceRoutes) {
      _openMobileWorkspaceRoute(
        () => DailyVictoriesDialog(state: state, fullScreen: true),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => DailyVictoriesDialog(state: state),
    );
  }

  void _openCharacterTimelineDialog(AppState state) {
    if (_usesMobileWorkspaceRoutes) {
      _openMobileWorkspaceRoute(
        () => CharacterTimelineDialog(state: state, fullScreen: true),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => CharacterTimelineDialog(state: state),
    );
  }

  void _openWeeklyDialog(AppState state) {
    if (_usesMobileWorkspaceRoutes) {
      _openMobileWorkspaceRoute(
        () => WeeklyAnalyticsDialog(state: state, fullScreen: true),
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

  void _openStatisticsTutorial(AppState state) {
    setState(() => _statsTutorialActive = true);
    showDialog<void>(
      context: context,
      builder: (_) => ProgressHubDialog(
        state: state,
        isDark: state.isDark,
        showTutorialHint: true,
        onTutorialComplete: () {
          _completeStatisticsTutorial(state);
          if (mounted) setState(() => _statsTutorialActive = false);
        },
        onOpenDailyVictories: () => _openDailyVictoriesDialog(state),
        onOpenCharacterTimeline: () => _openCharacterTimelineDialog(state),
        onOpenWeekly: () => _openWeeklyDialog(state),
        onOpenStats: () => _openGrowthSliceDialog(state),
        onOpenCalendar: () => _openCalendarDialog(state),
        onOpenBosses: () => _openBossesDialog(state),
        onOpenAchievements: () => _openAchievementsDialog(state),
        onOpenHistory: () => _openHistoryDialog(state),
        onOpenRewards: () => _openRewardsDialog(state),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _statsTutorialActive = false);
    });
  }

  void _completeStatisticsTutorial(AppState state) {
    final moduleId = state.activeTutorialModuleId;
    final stepId =
        state.activeTutorialStepId ??
        (moduleId == TutorialModuleIds.stats
            ? TutorialStepIds.statsGrowth
            : TutorialStepIds.coreOpenStats);

    state.completeTutorialStep(stepId);

    if (moduleId == TutorialModuleIds.core &&
        stepId == TutorialStepIds.coreOpenStats) {
      final expectedState = state;
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || !identical(widget.state, expectedState)) return;
        if (expectedState.activeTutorialModuleId == null) {
          expectedState.startTutorialModule(TutorialModuleIds.trophies);
        }
      });
    }
  }

  void _completeRewardsTutorial(AppState state) {
    final moduleId = state.activeTutorialModuleId;
    final stepId =
        state.activeTutorialStepId ?? TutorialStepIds.trophiesFeedback;

    state.completeTutorialStep(stepId);

    if (moduleId == TutorialModuleIds.trophies &&
        stepId == TutorialStepIds.trophiesFeedback) {
      final expectedState = state;
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || !identical(widget.state, expectedState)) return;
        if (expectedState.activeTutorialModuleId == null) {
          expectedState.startTutorialModule(TutorialModuleIds.profile);
        }
      });
    }
  }

  Widget _buildStatisticsWorkspace(
    AppState state,
    bool isDark, {
    bool showTutorialHint = false,
  }) {
    return _ProgressWorkspace(
      key: const ValueKey('stats-workspace'),
      state: state,
      isDark: isDark,
      showTutorialHint: showTutorialHint,
      onClose: () {
        setState(() {
          _mode = _lastNormalMode;
          _statsTutorialActive = false;
        });
      },
      onTutorialComplete: showTutorialHint
          ? () {
              _completeStatisticsTutorial(state);
              setState(() => _statsTutorialActive = false);
            }
          : null,
      onOpenDailyVictories: () => _openDailyVictoriesDialog(state),
      onOpenCharacterTimeline: () => _openCharacterTimelineDialog(state),
      onOpenWeekly: () => _openWeeklyDialog(state),
      onOpenStats: () => _openGrowthSliceDialog(state),
      onOpenCalendar: () => _openCalendarDialog(state),
      onOpenBosses: () => _openBossesDialog(state),
      onOpenAchievements: () => _openAchievementsDialog(state),
      onOpenHistory: () => _openHistoryDialog(state),
      onOpenRewards: () => _openRewardsDialog(state),
    );
  }

  void _openRoadmapTutorialTarget(AppState state) {
    final selected = state.selectedSkill;
    final skill = selected?.id == kInboxSkillId
        ? state.roadmapSkills.firstOrNull
        : selected ?? state.roadmapSkills.firstOrNull;
    if (skill != null) {
      _openRoadmapForSkill(state, skill);
    } else {
      setState(() {
        _mode = WorkspaceMode.mastery;
        _lastNormalMode = WorkspaceMode.mastery;
        _statsTutorialActive = false;
      });
    }
  }

  _GuidedTutorialStep? _tutorialStepFor(
    AppState state,
    bool mobileShell,
    void Function({bool tutorial}) openStatistics,
  ) {
    if (!state.shouldShowFirstRunTutorial) return null;
    final stepId =
        state.activeTutorialStepId ?? TutorialStepIds.coreCreateSkill;

    switch (stepId) {
      case TutorialStepIds.coreCreateSkill:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _firstSkillCtaKey,
          title: 'Первый запуск',
          body:
              'Начни с одного навыка. В форме достаточно названия и цели; этап можно добавить сразу или позже.',
          primaryLabel: 'Создать навык',
          primaryIcon: Icons.add,
          onPrimaryAction: () {
            state.startTutorialModule(TutorialModuleIds.core);
            _addSkill(context, showTutorialHints: true);
          },
        );
      case TutorialStepIds.coreCreateQuest:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _firstQuestCtaKey,
          title: 'Первый квест',
          body:
              'Навык готов. Теперь добавь один маленький квест-практику. Минимальный шаг можно включить, если нужен лёгкий старт.',
          primaryLabel: 'Создать квест',
          primaryIcon: Icons.add_task_rounded,
          onPrimaryAction: () =>
              _openFirstQuestDialog(context, state, showTutorialHints: true),
        );
      case TutorialStepIds.coreCompleteQuest:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _nextQuestActionKey,
          title: 'Действовать сегодня!',
          body:
              'Здесь выполняется следующий квест или минимальный шаг. Не обязательно делать его прямо сейчас. Задача этой панели — помочь не забыть о квесте и мотивировать действовать, когда будет готово настроение и время.',
          primaryLabel: 'Понял!',
          primaryIcon: Icons.check_rounded,
          secondaryLabel: null,
          onPrimaryAction: () =>
              state.completeTutorialStep(TutorialStepIds.coreCompleteQuest),
        );
      case TutorialStepIds.coreXpFeedback:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: mobileShell ? _pageStackKey : _roadmapNavKey,
          title: 'Дорожная карта',
          body:
              'Это более продвинутый раздел для поэтапного развития навыков. Если цель серьёзная, стоит планировать её с помощью дорожной карты.',
          primaryLabel: 'Открыть Карту',
          primaryIcon: Icons.account_tree_rounded,
          onPrimaryAction: () {
            state.completeTutorialStep(TutorialStepIds.coreXpFeedback);
            _openRoadmapTutorialTarget(state);
          },
        );
      case TutorialStepIds.coreOpenRoadmap:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _roadmapCanvasKey,
          title: 'Карта',
          body:
              'Большой пузырь — сам навык и финальная цель пути. Когда ты создашь этапы (пузыри поменьше), они выстроятся как дорога к этому навыку.',
          primaryLabel: 'Круто!',
          primaryIcon: Icons.arrow_forward_rounded,
          onPrimaryAction: () {
            state.completeTutorialStep(TutorialStepIds.coreOpenRoadmap);
          },
        );
      case TutorialStepIds.coreRoadmapDetails:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _roadmapInspectorKey,
          title: 'Детали пути',
          body:
              'Справа видно выбранный навык или этап: цель пути, прогресс и практика. Квесты можно создавать здесь, а выполнять — в “Действовать”.',
          primaryLabel: 'Дальше: Статистика',
          primaryIcon: Icons.arrow_forward_rounded,
          onPrimaryAction: () {
            state.completeTutorialStep(TutorialStepIds.coreRoadmapDetails);
          },
        );
      case TutorialStepIds.coreOpenStats:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _statsButtonKey,
          title: 'Статистика',
          body:
              'Статистика — вторичный экран истории роста: что получилось, какой навык двигался и что продолжить.',
          primaryLabel: 'Открыть статистику',
          primaryIcon: Icons.query_stats_rounded,
          onPrimaryAction: () => openStatistics(tutorial: true),
        );
      case TutorialStepIds.actNextQuest:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _nextQuestActionKey,
          title: 'Сейчас',
          body:
              'Главный экран отвечает на один вопрос: какой квест сделать следующим. Если есть минимум, начинай с него.',
          primaryLabel: 'Понял',
          primaryIcon: Icons.check_rounded,
          onPrimaryAction: () =>
              state.completeTutorialStep(TutorialStepIds.actNextQuest),
        );
      case TutorialStepIds.actMinimum:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _nextQuestActionKey,
          title: 'Минимальный шаг',
          body:
              'Минимум — безопасный вход в действие. Он даёт часть XP и помогает не ждать идеального момента.',
          primaryLabel: 'Понял, круто!',
          primaryIcon: Icons.check_rounded,
          onPrimaryAction: () =>
              state.completeTutorialStep(TutorialStepIds.actMinimum),
        );
      case TutorialStepIds.roadmapPath:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _roadmapCanvasKey,
          title: 'Дорожная карта навыка',
          body:
              'Большой пузырь — навык, маленькие пузыри — этапы дороги. В дорожной карте можно детально планировать развитие навыка',
          primaryLabel: _mode == WorkspaceMode.mastery
              ? 'Понял'
              : 'Открыть дорожную карту',
          primaryIcon: _mode == WorkspaceMode.mastery
              ? Icons.check_rounded
              : Icons.account_tree_rounded,
          onPrimaryAction: () {
            state.completeTutorialStep(TutorialStepIds.roadmapPath);
            if (_mode != WorkspaceMode.mastery) {
              _openRoadmapTutorialTarget(state);
            }
          },
        );
      case TutorialStepIds.roadmapPractice:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _roadmapPracticeKey,
          title: 'Практика этапа',
          body:
              'Практика — это квесты, которые доказывают освоение этапа. Закрывать их удобнее в “Сейчас”.',
          primaryLabel: 'Завершить тему',
          primaryIcon: Icons.check_rounded,
          onPrimaryAction: () =>
              state.completeTutorialStep(TutorialStepIds.roadmapPractice),
        );
      case TutorialStepIds.statsGrowth:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _statsButtonKey,
          title: 'История роста',
          body:
              'Здесь видно, что получилось за день и неделю. Review помогает сделать одну следующую корректировку.',
          primaryLabel: 'Открыть статистику',
          primaryIcon: Icons.query_stats_rounded,
          onPrimaryAction: () => openStatistics(tutorial: true),
        );
      case TutorialStepIds.trophiesFeedback:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _rewardsButtonKey,
          title: 'Трофеи и эффекты',
          body:
              'Трофеи, эффекты и сопротивление — это отклик после действий. Их не нужно обслуживать каждый день.',
          primaryLabel: 'Открыть трофеи',
          primaryIcon: Icons.redeem_rounded,
          onPrimaryAction: () =>
              _openRewardsDialog(state, showTutorialHint: true),
        );
      case TutorialStepIds.profileReplay:
        return _GuidedTutorialStep(
          id: stepId,
          targetKey: _profileBarKey,
          title: 'Профиль и подсказки',
          body:
              'В профиле можно повторить обучение, выключить hover-подсказки, звук и настроить внешний вид.',
          primaryLabel: 'Завершить обучение',
          primaryIcon: Icons.check_rounded,
          onPrimaryAction: () =>
              state.completeTutorialStep(TutorialStepIds.profileReplay),
        );
    }
    return null;
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
      _mode = WorkspaceMode.mastery;
      _lastNormalMode = WorkspaceMode.mastery;
      _statsTutorialActive = false;
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

    if (_roadmapFocusSkillId == validSkillId) return;
    setState(() => _roadmapFocusSkillId = validSkillId);
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
              if (showTutorialHints ||
                  state.activeTutorialModuleId == TutorialModuleIds.core) {
                state.completeTutorialStep(TutorialStepIds.coreCreateQuest);
              }
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
          final validRoadmapFocusSkillId =
              _roadmapFocusSkillId != null &&
                  s.roadmapSkills.any(
                    (skill) => skill.id == _roadmapFocusSkillId,
                  )
              ? _roadmapFocusSkillId
              : null;

          void changeMode(WorkspaceMode mode) {
            if (_mode == mode) {
              if (mode == WorkspaceMode.act || mode == WorkspaceMode.mastery) {
                return;
              }
              setState(() {
                _mode = _lastNormalMode;
                _statsTutorialActive = false;
              });
              return;
            }
            setState(() {
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
              }
              if (mode != WorkspaceMode.stats) {
                _statsTutorialActive = false;
              }
            });
          }

          void openStatistics({bool tutorial = false}) {
            if (mobileShell) {
              changeMode(WorkspaceMode.stats);
              if (tutorial && mounted) {
                setState(() => _statsTutorialActive = true);
              }
            } else if (tutorial) {
              _openStatisticsTutorial(s);
            } else {
              changeMode(WorkspaceMode.stats);
            }
          }

          void openProfile() {
            final capturedState = s;
            if (mobileShell) {
              _openMobileWorkspaceRoute(
                () => AppStateProvider(
                  state: capturedState,
                  child: const ProfileDialog(fullScreen: true),
                ),
              );
              return;
            }
            showDialog<void>(
              context: context,
              builder: (_) => AppStateProvider(
                state: capturedState,
                child: const ProfileDialog(),
              ),
            );
          }

          return Scaffold(
            backgroundColor: mobileShell
                ? _MobileJournalTokens.background(isDark)
                : isDark
                ? const Color(0xFF0F0F13)
                : const Color(0xFFF0F2F8),
            body: Stack(
              key: _pageStackKey,
              children: [
                if (desktopShell)
                  DesktopWorkspaceShell(
                    state: s,
                    mode: displayedMode,
                    metrics: desktopMetrics,
                    onModeChanged: changeMode,
                    onAddSkill: () => _addSkill(context),
                    onOpenRewards: () => changeMode(WorkspaceMode.rewards),
                    onOpenStatistics: openStatistics,
                    onOpenSettings: () => changeMode(WorkspaceMode.settings),
                    onOpenProfile: openProfile,
                    onDebugAppTap: !kReleaseMode
                        ? () => _handleDebugAdminTap(s)
                        : null,
                    onOpenRoadmap: (skill) => _openRoadmapForSkill(s, skill),
                    onComplete: _onComplete,
                    onMinimumAction: _onMinimumAction,
                    contextualToastHostKey: _desktopContextualToastHostKey,
                    rightRailKey: _desktopRightRailKey,
                    profileKey: _profileBarKey,
                    rewardsKey: _rewardsButtonKey,
                    roadmapKey: _roadmapNavKey,
                    statsKey: _statsButtonKey,
                    alternateWorkspace: switch (displayedMode) {
                      WorkspaceMode.mastery => _MasteryWorkspace(
                        key: const ValueKey('mastery-workspace'),
                        isDark: isDark,
                        focusSkillId: validRoadmapFocusSkillId,
                        canvasTutorialKey: _roadmapCanvasKey,
                        inspectorTutorialKey: _roadmapInspectorKey,
                        practiceTutorialKey: _roadmapPracticeKey,
                        onFocusSkillChanged: (skillId) =>
                            _syncRoadmapFocusSkill(s, skillId),
                        onComplete: _onComplete,
                        onMinimumAction: _onMinimumAction,
                      ),
                      WorkspaceMode.rewards => _DesktopRewardsWorkspace(
                        key: const ValueKey('desktop-rewards-workspace'),
                        state: s,
                        tokens: DesktopJournalTokens.resolve(isDark),
                      ),
                      WorkspaceMode.stats => MainPageAnalyticsBoundary(
                        state: s,
                        builder: (context) => _DesktopStatisticsWorkspace(
                          key: const ValueKey('desktop-statistics-workspace'),
                          state: s,
                          tokens: DesktopJournalTokens.resolve(isDark),
                        ),
                      ),
                      WorkspaceMode.settings => MainPageSettingsBoundary(
                        state: s,
                        builder: (context) => _DesktopSettingsWorkspace(
                          key: const ValueKey('desktop-settings-workspace'),
                          state: s,
                          tokens: DesktopJournalTokens.resolve(isDark),
                          onOpenProfile: openProfile,
                          onToggleTheme: widget.onToggleTheme,
                        ),
                      ),
                      WorkspaceMode.act => null,
                    },
                  )
                else
                  Column(
                    children: [
                      MainPageProfileBoundary(
                        key: _profileBarKey,
                        state: s,
                        onBuildForTesting: widget.onProfileBuildForTesting,
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
                          onProfileTap: openProfile,
                          rewardsKey: _rewardsButtonKey,
                          statsKey: _statsButtonKey,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: MotionFadeSlideSwitcher(
                            child: switch (displayedMode) {
                              WorkspaceMode.act => _ActWorkspace(
                                key: const ValueKey('act-workspace'),
                                onComplete: _onComplete,
                                onMinimumAction: _onMinimumAction,
                                onCreateFirstSkill: () => _addSkill(context),
                                onOpenRoadmap: (skill) =>
                                    _openRoadmapForSkill(s, skill),
                                createFirstSkillButtonKey: _firstSkillCtaKey,
                                createFirstQuestButtonKey: _firstQuestCtaKey,
                                nextQuestActionKey: _nextQuestActionKey,
                                mobileJournalKey: _mobileActJournalKey,
                              ),
                              WorkspaceMode.mastery => _MasteryWorkspace(
                                key: const ValueKey('mastery-workspace'),
                                isDark: isDark,
                                focusSkillId: validRoadmapFocusSkillId,
                                canvasTutorialKey: _roadmapCanvasKey,
                                inspectorTutorialKey: _roadmapInspectorKey,
                                practiceTutorialKey: _roadmapPracticeKey,
                                onFocusSkillChanged: (skillId) =>
                                    _syncRoadmapFocusSkill(s, skillId),
                                onComplete: _onComplete,
                                onMinimumAction: _onMinimumAction,
                              ),
                              WorkspaceMode.stats => MainPageAnalyticsBoundary(
                                state: s,
                                builder: (context) => _buildStatisticsWorkspace(
                                  s,
                                  isDark,
                                  showTutorialHint: _statsTutorialActive,
                                ),
                              ),
                              WorkspaceMode.rewards => const SizedBox.shrink(),
                              WorkspaceMode.settings => const SizedBox.shrink(),
                            },
                          ),
                        ),
                      ),
                      _MobileWorkspaceNav(
                        mode: displayedMode,
                        isDark: isDark,
                        reducedMotion: workspace.reducedMotion,
                        onChanged: changeMode,
                        onReselectCurrent: displayedMode == WorkspaceMode.act
                            ? _mobileActJournalKey.currentState?.collapseInbox
                            : null,
                        roadmapKey: _roadmapNavKey,
                      ),
                    ],
                  ),
                if (_rewardNoticeQueue.isNotEmpty)
                  _RewardNoticePopover(
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
                    key: ValueKey('goal-milestone-${_goalMilestoneNotice!.id}'),
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
                _MainPageTutorialBoundary(
                  state: s,
                  blocked:
                      _firstRunDialogOpen ||
                      _statsTutorialActive ||
                      _rewardsTutorialActive,
                  isDark: isDark,
                  resolveStep: () =>
                      _tutorialStepFor(s, mobileShell, openStatistics),
                  onBuildForTesting: widget.onTutorialBuildForTesting,
                ),
                ..._bubbles,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MainPageTutorialBoundary extends StatefulWidget {
  const _MainPageTutorialBoundary({
    required this.state,
    required this.blocked,
    required this.isDark,
    required this.resolveStep,
    this.onBuildForTesting,
  });

  final AppState state;
  final bool blocked;
  final bool isDark;
  final _GuidedTutorialStep? Function() resolveStep;
  final VoidCallback? onBuildForTesting;

  @override
  State<_MainPageTutorialBoundary> createState() =>
      _MainPageTutorialBoundaryState();
}

class _MainPageTutorialBoundaryState extends State<_MainPageTutorialBoundary> {
  bool _stepPaused = false;
  String? _lastStepId;
  String? _pendingStepId;
  Timer? _stepDelayTimer;

  @override
  void didUpdateWidget(_MainPageTutorialBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.state, widget.state)) {
      _resetStepDelay();
    }
  }

  @override
  void dispose() {
    _stepDelayTimer?.cancel();
    super.dispose();
  }

  void _resetStepDelay() {
    _stepDelayTimer?.cancel();
    _stepDelayTimer = null;
    _lastStepId = null;
    _pendingStepId = null;
    _stepPaused = false;
  }

  bool _shouldShow(String? stepId) {
    if (stepId == null) {
      _resetStepDelay();
      return false;
    }

    if (_lastStepId == null) {
      _lastStepId = stepId;
      return !widget.blocked;
    }

    if (stepId == _lastStepId) {
      return !widget.blocked && !_stepPaused;
    }

    if (widget.blocked) {
      _stepDelayTimer?.cancel();
      _stepDelayTimer = null;
      _pendingStepId = stepId;
      _stepPaused = true;
      return false;
    }

    if (_pendingStepId != stepId || !_stepPaused || _stepDelayTimer == null) {
      _pendingStepId = stepId;
      _stepPaused = true;
      _stepDelayTimer?.cancel();
      _stepDelayTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted || _pendingStepId != stepId) return;
        setState(() {
          _lastStepId = stepId;
          _pendingStepId = null;
          _stepPaused = false;
          _stepDelayTimer = null;
        });
      });
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AppStateSelector<MainPageTutorialProjection>(
      state: widget.state,
      selector: MainPageTutorialProjection.fromState,
      builder: (context, projection, child) {
        widget.onBuildForTesting?.call();
        final step = projection.visible ? widget.resolveStep() : null;
        if (step == null) {
          _shouldShow(null);
          return const SizedBox.shrink();
        }
        return _FirstRunTutorialOverlay(
          stepId: step.id,
          visible: _shouldShow(step.id),
          targetKey: step.targetKey,
          isDark: widget.isDark,
          title: step.title,
          body: step.body,
          primaryLabel: step.primaryLabel,
          primaryIcon: step.primaryIcon,
          secondaryLabel: step.secondaryLabel,
          onDismiss: widget.state.dismissActiveTutorial,
          onPrimaryAction: step.onPrimaryAction,
        );
      },
    );
  }
}
