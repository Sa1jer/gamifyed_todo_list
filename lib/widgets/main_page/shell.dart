part of '../main_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class MainPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const MainPage({super.key, required this.onToggleTheme});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const _debugAdminTapWindow = Duration(seconds: 2);
  static const _debugAdminRequiredTaps = 5;

  final List<XPBubble> _bubbles = [];
  final GlobalKey _pageStackKey = GlobalKey();
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
  WorkspaceMode _mode = WorkspaceMode.act;
  _RewardNotice? _rewardNotice;
  GoalMilestoneEvent? _goalMilestoneNotice;
  AppState? _eventState;
  Offset? _rewardNoticeAnchor;
  int _debugAdminTapCount = 0;
  DateTime? _lastDebugAdminTapAt;
  bool _firstRunDialogOpen = false;
  bool _statsTutorialActive = false;
  bool _rewardsTutorialActive = false;
  bool _tutorialStepPaused = false;
  String? _lastTutorialStepId;
  String? _pendingTutorialStepId;
  Timer? _tutorialStepDelayTimer;
  String? _roadmapFocusSkillId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateProvider.of(context);
    if (_eventState == state) return;
    _eventState?.removeListener(_handleStateEvents);
    _eventState = state;
    _eventState?.addListener(_handleStateEvents);
  }

  @override
  void dispose() {
    _eventState?.removeListener(_handleStateEvents);
    _tutorialStepDelayTimer?.cancel();
    super.dispose();
  }

  void _handleDebugAdminTap(AppState state) {
    if (!kDebugMode) return;

    final now = DateTime.now();
    final lastTap = _lastDebugAdminTapAt;
    if (lastTap == null || now.difference(lastTap) > _debugAdminTapWindow) {
      _debugAdminTapCount = 0;
    }

    _lastDebugAdminTapAt = now;
    _debugAdminTapCount++;

    if (_debugAdminTapCount < _debugAdminRequiredTaps) return;

    _debugAdminTapCount = 0;
    _lastDebugAdminTapAt = null;
    AppFeedback.selection();
    showDebugAdminPanel(context, state: state);
  }

  void _showBubble(String message, Offset pos) {
    final isMilestone = AppFeedback.isMilestoneMessage(message);
    setState(() {
      _bubbles.add(
        XPBubble(
          key: UniqueKey(),
          message: message,
          position: pos,
          showMilestoneConfetti: isMilestone,
          confettiBuilder: (color) =>
              MilestoneConfettiBurst(color: color, particles: 14),
          onDone: (k) =>
              setState(() => _bubbles.removeWhere((b) => b.key == k)),
        ),
      );
    });
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

    setState(() {
      _rewardNotice = _RewardNotice(
        chestTitles: chests.map((chest) => chest.title).toList(),
        buffTitles: buffs.map((buff) => buff.title).toList(),
        achievementTitles: achievements
            .map((achievement) => achievement.def?.name ?? 'Достижение')
            .toList(),
      );
      _rewardNoticeAnchor = _resolveRewardsButtonAnchor();
    });
  }

  void _handleStateEvents() {
    final state = _eventState;
    if (state == null || !mounted) return;
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

  Offset? _resolveRewardsButtonAnchor() {
    final buttonContext = _rewardsButtonKey.currentContext;
    final stackContext = _pageStackKey.currentContext;
    if (buttonContext == null || stackContext == null) return null;

    final buttonBox = buttonContext.findRenderObject();
    final stackBox = stackContext.findRenderObject();
    if (buttonBox is! RenderBox || stackBox is! RenderBox) return null;

    final buttonTopLeft = buttonBox.localToGlobal(Offset.zero);
    final localTopLeft = stackBox.globalToLocal(buttonTopLeft);
    return Offset(
      localTopLeft.dx + buttonBox.size.width / 2,
      localTopLeft.dy + buttonBox.size.height,
    );
  }

  void _openRewardsDialog(AppState state, {bool showTutorialHint = false}) {
    AppFeedback.selection();
    setState(() {
      _rewardNotice = null;
      if (showTutorialHint) _rewardsTutorialActive = true;
    });
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
    showDialog(
      context: context,
      builder: (_) => DailyVictoriesDialog(state: state),
    );
  }

  void _openCharacterTimelineDialog(AppState state) {
    showDialog(
      context: context,
      builder: (_) => CharacterTimelineDialog(state: state),
    );
  }

  void _openWeeklyDialog(AppState state) {
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

  void _openStatisticsDialog(AppState state, {bool showTutorialHint = false}) {
    AppFeedback.selection();
    if (showTutorialHint) {
      setState(() => _statsTutorialActive = true);
    }
    showDialog(
      context: context,
      builder: (_) => ProgressHubDialog(
        state: state,
        isDark: state.isDark,
        showTutorialHint: showTutorialHint,
        onTutorialComplete: showTutorialHint
            ? () {
                _completeStatisticsTutorial(state);
                if (mounted) setState(() => _statsTutorialActive = false);
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
      ),
    ).whenComplete(() {
      if (showTutorialHint && mounted) {
        setState(() => _statsTutorialActive = false);
      }
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
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        final latest = AppStateProvider.of(context);
        if (latest.activeTutorialModuleId == null) {
          latest.startTutorialModule(TutorialModuleIds.trophies);
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
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        final latest = AppStateProvider.of(context);
        if (latest.activeTutorialModuleId == null) {
          latest.startTutorialModule(TutorialModuleIds.profile);
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

  void _onComplete(String taskId, Offset pos) {
    final s = AppStateProvider.of(context);
    final msg = s.completeTask(taskId);
    if (msg == null) return;
    AppFeedback.questResult(msg);
    _showBubble(msg, pos);
    _showRewardNotifications(s);
  }

  void _onMinimumAction(String taskId, Offset pos) {
    final s = AppStateProvider.of(context);
    final msg = s.completeMinimumAction(taskId);
    if (msg == null) return;
    AppFeedback.questResult(msg, isMinimum: true);
    _showBubble(msg, pos);
    _showRewardNotifications(s);
  }

  void _setFirstRunDialogOpen(bool value) {
    if (!mounted || _firstRunDialogOpen == value) return;
    setState(() => _firstRunDialogOpen = value);
  }

  bool _shouldShowTutorialOverlay(String? stepId, {required bool blocked}) {
    if (stepId == null) {
      _tutorialStepDelayTimer?.cancel();
      _tutorialStepDelayTimer = null;
      _lastTutorialStepId = null;
      _pendingTutorialStepId = null;
      _tutorialStepPaused = false;
      return false;
    }

    if (_lastTutorialStepId == null) {
      _lastTutorialStepId = stepId;
      return !blocked;
    }

    if (stepId == _lastTutorialStepId) {
      return !blocked && !_tutorialStepPaused;
    }

    if (blocked) {
      _tutorialStepDelayTimer?.cancel();
      _tutorialStepDelayTimer = null;
      _pendingTutorialStepId = stepId;
      _tutorialStepPaused = true;
      return false;
    }

    if (_pendingTutorialStepId != stepId ||
        !_tutorialStepPaused ||
        _tutorialStepDelayTimer == null) {
      _pendingTutorialStepId = stepId;
      _tutorialStepPaused = true;
      _tutorialStepDelayTimer?.cancel();
      _tutorialStepDelayTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted || _pendingTutorialStepId != stepId) return;
        setState(() {
          _lastTutorialStepId = stepId;
          _pendingTutorialStepId = null;
          _tutorialStepPaused = false;
          _tutorialStepDelayTimer = null;
        });
      });
    }

    return false;
  }

  void _openRoadmapForSkill(AppState state, Skill skill) {
    AppFeedback.selection();
    state.selectSkill(skill.id);
    setState(() {
      _roadmapFocusSkillId = skill.id;
      _mode = WorkspaceMode.mastery;
      _statsTutorialActive = false;
    });
  }

  void _addSkill(BuildContext context, {bool showTutorialHints = false}) {
    final state = AppStateProvider.of(context);
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
    final s = AppStateProvider.of(context);
    final isDark = s.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobileShell = constraints.maxWidth < 760;
        final displayedMode = !mobileShell && _mode == WorkspaceMode.stats
            ? WorkspaceMode.act
            : _mode;

        void changeMode(WorkspaceMode mode) {
          if (_mode == mode) return;
          setState(() {
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
            setState(() {
              _mode = WorkspaceMode.stats;
              _statsTutorialActive = tutorial;
            });
          } else {
            _openStatisticsDialog(s, showTutorialHint: tutorial);
          }
        }

        final tutorialStep = _tutorialStepFor(s, mobileShell, openStatistics);
        final tutorialVisible = _shouldShowTutorialOverlay(
          tutorialStep?.id,
          blocked:
              _firstRunDialogOpen ||
              _statsTutorialActive ||
              _rewardsTutorialActive,
        );

        return Scaffold(
          backgroundColor: mobileShell
              ? _MobileJournalTokens.background(isDark)
              : isDark
              ? const Color(0xFF0F0F13)
              : const Color(0xFFF0F2F8),
          body: Stack(
            key: _pageStackKey,
            children: [
              Column(
                children: [
                  if (!mobileShell)
                    TopBar(
                      isDark: isDark,
                      onToggle: widget.onToggleTheme,
                      state: s,
                      mode: displayedMode,
                      onModeChanged: changeMode,
                      onStatsTap: openStatistics,
                      rewardsKey: _rewardsButtonKey,
                      roadmapKey: _roadmapNavKey,
                      statsKey: _statsButtonKey,
                      onRewardsTap: () => _openRewardsDialog(s),
                      onAppIconTap: kDebugMode
                          ? () => _handleDebugAdminTap(s)
                          : null,
                    ),
                  ProfileBar(
                    key: _profileBarKey,
                    isDark: isDark,
                    mobile: mobileShell,
                    state: s,
                    onToggleTheme: widget.onToggleTheme,
                    onRewardsTap: () => _openRewardsDialog(s),
                    onStatsTap: openStatistics,
                    onAppIconTap: kDebugMode
                        ? () => _handleDebugAdminTap(s)
                        : null,
                    rewardsKey: mobileShell ? _rewardsButtonKey : null,
                    statsKey: mobileShell ? _statsButtonKey : null,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                          ),
                          WorkspaceMode.mastery => _MasteryWorkspace(
                            key: const ValueKey('mastery-workspace'),
                            isDark: isDark,
                            focusSkillId: _roadmapFocusSkillId,
                            canvasTutorialKey: _roadmapCanvasKey,
                            inspectorTutorialKey: _roadmapInspectorKey,
                            practiceTutorialKey: _roadmapPracticeKey,
                            onComplete: _onComplete,
                            onMinimumAction: _onMinimumAction,
                          ),
                          WorkspaceMode.stats => _buildStatisticsWorkspace(
                            s,
                            isDark,
                            showTutorialHint: _statsTutorialActive,
                          ),
                        },
                      ),
                    ),
                  ),
                  if (mobileShell)
                    _MobileWorkspaceNav(
                      mode: displayedMode,
                      isDark: isDark,
                      onChanged: changeMode,
                      roadmapKey: _roadmapNavKey,
                    ),
                ],
              ),
              if (_rewardNotice != null)
                _RewardNoticePopover(
                  notice: _rewardNotice!,
                  anchor: _rewardNoticeAnchor,
                  isDark: isDark,
                  onShow: () => _openRewardsDialog(s),
                  onHide: () => setState(() => _rewardNotice = null),
                ),
              if (_goalMilestoneNotice != null)
                GoalMilestoneBanner(
                  key: ValueKey('goal-milestone-${_goalMilestoneNotice!.id}'),
                  event: _goalMilestoneNotice!,
                  isDark: isDark,
                  onDismiss: () => setState(() => _goalMilestoneNotice = null),
                  onOpenRoadmap:
                      _goalMilestoneNotice!.milestone == GoalMilestone.complete
                      ? () {
                          final event = _goalMilestoneNotice;
                          if (event == null) return;
                          setState(() => _goalMilestoneNotice = null);
                          _openMilestoneRoadmap(s, event);
                        }
                      : null,
                ),
              if (tutorialStep != null)
                _FirstRunTutorialOverlay(
                  stepId: tutorialStep.id,
                  visible: tutorialVisible,
                  targetKey: tutorialStep.targetKey,
                  isDark: isDark,
                  title: tutorialStep.title,
                  body: tutorialStep.body,
                  primaryLabel: tutorialStep.primaryLabel,
                  primaryIcon: tutorialStep.primaryIcon,
                  secondaryLabel: tutorialStep.secondaryLabel,
                  onDismiss: s.dismissActiveTutorial,
                  onPrimaryAction: tutorialStep.onPrimaryAction,
                ),
              ..._bubbles,
            ],
          ),
        );
      },
    );
  }
}
