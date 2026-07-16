part of '../dialogs.dart';

class RewardsDialog extends StatefulWidget {
  final AppState state;
  final bool showTutorialHint;
  final VoidCallback? onTutorialComplete;
  final bool fullScreen;
  const RewardsDialog({
    super.key,
    required this.state,
    this.showTutorialHint = false,
    this.onTutorialComplete,
    this.fullScreen = false,
  });

  @override
  State<RewardsDialog> createState() => _RewardsDialogState();
}

class _RewardsDialogState extends State<RewardsDialog> {
  RewardReveal? _lastReveal;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final unopened = widget.state.unopenedRewardChests;
    final buffs = widget.state.activeBuffs;
    final tutorialTargetKey = GlobalKey();
    final size = MediaQuery.sizeOf(context);
    final availableWidth = size.width - 36;
    final availableHeight = size.height - 40;
    final dialogWidth = widget.fullScreen
        ? size.width
        : availableWidth < 360
        ? availableWidth
        : availableWidth.clamp(360.0, 500.0).toDouble();
    final dialogHeight = widget.fullScreen
        ? size.height
        : availableHeight < 500
        ? availableHeight
        : availableHeight.clamp(500.0, 620.0).toDouble();

    final content = SizedBox(
      width: dialogWidth,
      height: dialogHeight,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.redeem,
                      color: Color(0xFFFFCC00),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Трофеи после действий',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: txt,
                        ),
                      ),
                    ),
                    PressFeedback(
                      scale: 0.94,
                      tooltip: 'Закрыть трофеи',
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: sub, size: 22),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: bdr),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KeyedSubtree(
                        key: tutorialTargetKey,
                        child: _buildEffectsSection(
                          isDark: isDark,
                          txt: txt,
                          sub: sub,
                          buffs: buffs,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Трофеи появляются после заметных действий: сильного дня, рубежа серии или победы над сопротивлением.',
                        style: TextStyle(
                          color: sub,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      MotionExpandable(
                        expanded: _lastReveal != null,
                        collapsedChild: const SizedBox(height: 18),
                        expandedChild: _lastReveal == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: RewardRevealNotice(
                                  key: ValueKey(_lastReveal!.id),
                                  reveal: _lastReveal!,
                                  isDark: isDark,
                                ),
                              ),
                      ),
                      Text(
                        'Новые сундуки',
                        style: TextStyle(
                          color: txt,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      MotionFadeSlideSwitcher(
                        child: unopened.isEmpty
                            ? RewardsEmptyState(
                                key: const ValueKey('empty-chests'),
                                icon: Icons.inventory_2_outlined,
                                title: 'Пока нет сундуков',
                                subtitle:
                                    'Закрой сильный день, удержи серию или пройди событие сопротивления, чтобы получить трофей.',
                                isDark: isDark,
                              )
                            : Column(
                                key: const ValueKey('chest-list'),
                                children: unopened.asMap().entries.map((entry) {
                                  final chest = entry.value;
                                  return MotionListItem(
                                    key: ValueKey('chest-${chest.id}'),
                                    index: entry.key,
                                    slide: 5,
                                    child: RewardChestCard(
                                      chest: chest,
                                      skill: chest.skillId == null
                                          ? null
                                          : widget.state.skills
                                                .where(
                                                  (skill) =>
                                                      skill.id == chest.skillId,
                                                )
                                                .firstOrNull,
                                      isDark: isDark,
                                      onOpen: () =>
                                          _openChest(context, chest.id),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.showTutorialHint && widget.onTutorialComplete != null)
            Positioned.fill(
              child: RewardsTutorialSpotlight(
                targetKey: tutorialTargetKey,
                isDark: isDark,
                onComplete: widget.onTutorialComplete!,
              ),
            ),
        ],
      ),
    );

    if (widget.fullScreen) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(child: SizedBox.expand(child: content)),
      );
    }

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: content,
    );
  }

  Widget _buildEffectsSection({
    required bool isDark,
    required Color txt,
    required Color sub,
    required List<Buff> buffs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          key: const ValueKey('rewards-effects-section'),
          children: [
            Icon(
              Icons.bolt,
              color: const Color(0xFF34C759).withAlpha(190),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Эффекты',
                style: TextStyle(
                  color: txt,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TaskBadge(label: '${buffs.length}', color: const Color(0xFF34C759)),
          ],
        ),
        const SizedBox(height: 10),
        MotionFadeSlideSwitcher(
          child: buffs.isEmpty
              ? RewardsEmptyState(
                  key: const ValueKey('empty-buffs'),
                  icon: Icons.bolt_outlined,
                  title: 'Нет эффектов',
                  subtitle:
                      'Открой сундук, и здесь появится временное усиление для следующих квестов.',
                  isDark: isDark,
                )
              : Column(
                  key: const ValueKey('buff-list'),
                  children: buffs.asMap().entries.map((entry) {
                    final buff = entry.value;
                    return MotionListItem(
                      key: ValueKey('buff-${buff.id}'),
                      index: entry.key,
                      slide: 5,
                      child: ActiveBuffCard(
                        buff: buff,
                        skill: buff.skillId == null
                            ? null
                            : widget.state.skills
                                  .where((skill) => skill.id == buff.skillId)
                                  .firstOrNull,
                        isDark: isDark,
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  void _openChest(BuildContext context, String chestId) {
    final chest = widget.state.rewardChests
        .where((item) => item.id == chestId)
        .firstOrNull;
    if (chest == null) return;

    final message = widget.state.openRewardChest(chestId);
    if (message == null) return;
    AppFeedback.reward();
    final buff = widget.state.buffs
        .where((item) => item.sourceChestId == chestId)
        .firstOrNull;

    setState(
      () => _lastReveal = RewardReveal(
        id: '${chest.id}-${buff?.id ?? chest.openedAt?.millisecondsSinceEpoch}',
        message: message,
        buffTitle: buff?.title,
        bonusPercent: buff?.bonusPercent,
        color: rewardRarityColor[chest.rarity]!,
        icon: chest.rarity == RewardRarity.epic
            ? Icons.auto_awesome
            : Icons.inventory_2,
      ),
    );
  }
}
