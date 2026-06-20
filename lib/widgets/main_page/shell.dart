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
  final List<XPBubble> _bubbles = [];
  final GlobalKey _pageStackKey = GlobalKey();
  final GlobalKey _rewardsButtonKey = GlobalKey();
  final GlobalKey _firstSkillCtaKey = GlobalKey();
  WorkspaceMode _mode = WorkspaceMode.act;
  _RewardNotice? _rewardNotice;
  Offset? _rewardNoticeAnchor;

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

  void _openRewardsDialog(AppState state) {
    AppFeedback.selection();
    setState(() => _rewardNotice = null);
    showDialog(
      context: context,
      builder: (_) => RewardsDialog(state: state),
    );
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

  void _openStatisticsDialog(AppState state) {
    AppFeedback.selection();
    showDialog(
      context: context,
      builder: (_) => ProgressHubDialog(
        state: state,
        isDark: state.isDark,
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
    );
  }

  Widget _buildStatisticsWorkspace(AppState state, bool isDark) {
    return _ProgressWorkspace(
      key: const ValueKey('stats-workspace'),
      state: state,
      isDark: isDark,
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

  void _addSkill(BuildContext context) {
    final state = AppStateProvider.of(context);
    showDialog(
      context: context,
      builder: (_) => AddSkillDialog(
        isDark: state.isDark,
        onSave:
            (
              name,
              goal,
              checklist,
              color,
              icon,
              initialTreeNodes,
              initialQuest,
            ) {
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
              if (initialQuest != null) {
                state.addTask(
                  Task(
                    id: uid(),
                    title: initialQuest.title,
                    skillId: skillId,
                    xpReward: 20,
                    type: TaskType.shortTerm,
                    priority: Priority.medium,
                    minimumAction: initialQuest.minimumAction,
                    treeNodeId: initialQuest.treeNodeId,
                  ),
                );
              }
            },
      ),
    );
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
          setState(() => _mode = mode);
        }

        void openStatistics() {
          if (mobileShell) {
            changeMode(WorkspaceMode.stats);
          } else {
            _openStatisticsDialog(s);
          }
        }

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0F0F13)
              : const Color(0xFFF0F2F8),
          body: Stack(
            key: _pageStackKey,
            children: [
              Column(
                children: [
                  TopBar(
                    isDark: isDark,
                    onToggle: widget.onToggleTheme,
                    state: s,
                    mode: displayedMode,
                    onModeChanged: changeMode,
                    onStatsTap: openStatistics,
                    rewardsKey: _rewardsButtonKey,
                    onRewardsTap: () => _openRewardsDialog(s),
                    showModeSwitch: !mobileShell,
                  ),
                  ProfileBar(isDark: isDark),
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
                            createFirstSkillButtonKey: _firstSkillCtaKey,
                          ),
                          WorkspaceMode.mastery => _MasteryWorkspace(
                            key: const ValueKey('mastery-workspace'),
                            isDark: isDark,
                            onComplete: _onComplete,
                            onMinimumAction: _onMinimumAction,
                          ),
                          WorkspaceMode.stats => _buildStatisticsWorkspace(
                            s,
                            isDark,
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
              if (s.shouldShowFirstRunTutorial)
                _FirstRunTutorialOverlay(
                  targetKey: _firstSkillCtaKey,
                  isDark: isDark,
                  onDismiss: s.dismissFirstRunTutorial,
                  onCreateFirstSkill: () {
                    s.dismissFirstRunTutorial();
                    _addSkill(context);
                  },
                ),
              ..._bubbles,
            ],
          ),
        );
      },
    );
  }
}
