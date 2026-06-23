part of '../dialogs.dart';

class RewardsDialog extends StatefulWidget {
  final AppState state;
  final bool showTutorialHint;
  final VoidCallback? onTutorialComplete;
  const RewardsDialog({
    super.key,
    required this.state,
    this.showTutorialHint = false,
    this.onTutorialComplete,
  });

  @override
  State<RewardsDialog> createState() => _RewardsDialogState();
}

class _RewardsDialogState extends State<RewardsDialog> {
  _RewardReveal? _lastReveal;
  bool _buffsExpanded = false;

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
    final dialogWidth = availableWidth < 360
        ? availableWidth
        : availableWidth.clamp(360.0, 500.0).toDouble();
    final dialogHeight = availableHeight < 500
        ? availableHeight
        : availableHeight.clamp(500.0, 620.0).toDouble();

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
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
                      Text(
                        'Трофеи после действий',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: txt,
                        ),
                      ),
                      const Spacer(),
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
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Новые сундуки',
                                  value: '${unopened.length}',
                                  icon: Icons.inventory_2,
                                  color: const Color(0xFFFFCC00),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Пассивные эффекты',
                                  value: '${buffs.length}',
                                  icon: Icons.bolt,
                                  color: const Color(0xFF34C759),
                                  isDark: isDark,
                                ),
                              ),
                            ],
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
                                  child: _RewardRevealNotice(
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
                              ? _RewardsEmptyState(
                                  key: const ValueKey('empty-chests'),
                                  icon: Icons.inventory_2_outlined,
                                  title: 'Пока нет сундуков',
                                  subtitle:
                                      'Закрой сильный день, удержи серию или пройди событие сопротивления, чтобы получить трофей.',
                                  isDark: isDark,
                                )
                              : Column(
                                  key: const ValueKey('chest-list'),
                                  children: unopened.asMap().entries.map((
                                    entry,
                                  ) {
                                    final chest = entry.value;
                                    return MotionListItem(
                                      key: ValueKey('chest-${chest.id}'),
                                      index: entry.key,
                                      slide: 5,
                                      child: _RewardChestCard(
                                        chest: chest,
                                        skill: chest.skillId == null
                                            ? null
                                            : widget.state.skills
                                                  .where(
                                                    (skill) =>
                                                        skill.id ==
                                                        chest.skillId,
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
                        const SizedBox(height: 18),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              setState(() => _buffsExpanded = !_buffsExpanded),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bolt,
                                  color: const Color(0xFF34C759).withAlpha(190),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Пассивные эффекты',
                                    style: TextStyle(
                                      color: txt,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TaskBadge(
                                  label: '${buffs.length}',
                                  color: const Color(0xFF34C759),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _buffsExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: sub,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        MotionExpandable(
                          expanded: _buffsExpanded,
                          collapsedChild: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              buffs.isEmpty
                                  ? 'Эффектов сейчас нет. Они появятся после открытия сундуков.'
                                  : 'Эффекты применятся сами, когда подойдут к квесту.',
                              style: TextStyle(
                                color: sub,
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                          expandedChild: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: MotionFadeSlideSwitcher(
                              child: buffs.isEmpty
                                  ? _RewardsEmptyState(
                                      key: const ValueKey('empty-buffs'),
                                      icon: Icons.bolt_outlined,
                                      title: 'Нет пассивных эффектов',
                                      subtitle:
                                          'Открой сундук, и здесь появится временное усиление для следующих квестов.',
                                      isDark: isDark,
                                    )
                                  : Column(
                                      key: const ValueKey('buff-list'),
                                      children: buffs.asMap().entries.map((
                                        entry,
                                      ) {
                                        final buff = entry.value;
                                        return MotionListItem(
                                          key: ValueKey('buff-${buff.id}'),
                                          index: entry.key,
                                          slide: 5,
                                          child: _ActiveBuffCard(
                                            buff: buff,
                                            skill: buff.skillId == null
                                                ? null
                                                : widget.state.skills
                                                      .where(
                                                        (skill) =>
                                                            skill.id ==
                                                            buff.skillId,
                                                      )
                                                      .firstOrNull,
                                            isDark: isDark,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
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
                child: _RewardsTutorialSpotlight(
                  targetKey: tutorialTargetKey,
                  isDark: isDark,
                  onComplete: widget.onTutorialComplete!,
                ),
              ),
          ],
        ),
      ),
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
      () => _lastReveal = _RewardReveal(
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

class _RewardsTutorialSpotlight extends StatefulWidget {
  final GlobalKey targetKey;
  final bool isDark;
  final VoidCallback onComplete;

  const _RewardsTutorialSpotlight({
    required this.targetKey,
    required this.isDark,
    required this.onComplete,
  });

  @override
  State<_RewardsTutorialSpotlight> createState() =>
      _RewardsTutorialSpotlightState();
}

class _RewardsTutorialSpotlightState extends State<_RewardsTutorialSpotlight> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
  }

  void _updateTargetRect() {
    if (!mounted) return;
    final overlayBox = context.findRenderObject() as RenderBox?;
    final targetContext = widget.targetKey.currentContext;
    final targetBox = targetContext?.findRenderObject() as RenderBox?;
    if (overlayBox == null || targetBox == null || !targetBox.attached) {
      setState(() => _targetRect = null);
      return;
    }
    final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    setState(() => _targetRect = topLeft & targetBox.size);
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF9500);
    final size = MediaQuery.of(context).size;
    final txt = textColor(widget.isDark);
    final sub = subtext(widget.isDark);
    final panelWidth = math.min(size.width - 32, 420.0);
    final rect = _targetRect;
    final top = rect == null
        ? (size.height - 250) / 2
        : (rect.bottom + 18).clamp(18.0, size.height - 250.0).toDouble();
    final left = rect == null
        ? (size.width - panelWidth) / 2
        : (rect.center.dx - panelWidth / 2)
              .clamp(16.0, math.max(16.0, size.width - panelWidth - 16))
              .toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: kMotionSlow,
      curve: kMotionCurve,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RewardsTutorialSpotlightPainter(
                    targetRect: rect,
                    color: color,
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: top,
                width: panelWidth,
                child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface(widget.isDark),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor(widget.isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withAlpha(34),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.redeem, color: color, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Трофеи и эффекты',
                    style: TextStyle(
                      color: txt,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Это обратная связь после действий: сундуки, пассивные эффекты и сопротивление. Их не нужно обслуживать каждый день.',
              style: TextStyle(
                color: sub,
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: SmallBtn(
                label: 'Дальше: профиль',
                icon: Icons.arrow_forward_rounded,
                color: color,
                onTap: widget.onComplete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsTutorialSpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color color;

  const _RewardsTutorialSpotlightPainter({
    required this.targetRect,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withAlpha(184);
    final base = Path()..addRect(Offset.zero & size);
    final rect = targetRect?.inflate(10);
    if (rect == null) {
      canvas.drawRect(Offset.zero & size, overlay);
      return;
    }
    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(22)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, base, cutout),
      overlay,
    );
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withAlpha(210);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _RewardsTutorialSpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.color != color;
  }
}

class _RewardReveal {
  final String id;
  final String message;
  final String? buffTitle;
  final int? bonusPercent;
  final Color color;
  final IconData icon;

  const _RewardReveal({
    required this.id,
    required this.message,
    required this.color,
    required this.icon,
    this.buffTitle,
    this.bonusPercent,
  });
}

class _RewardRevealNotice extends StatefulWidget {
  final _RewardReveal reveal;
  final bool isDark;

  const _RewardRevealNotice({
    super.key,
    required this.reveal,
    required this.isDark,
  });

  @override
  State<_RewardRevealNotice> createState() => _RewardRevealNoticeState();
}

class _RewardRevealNoticeState extends State<_RewardRevealNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kMotionProgress)
      ..forward();
  }

  @override
  void didUpdateWidget(covariant _RewardRevealNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reveal.id != widget.reveal.id) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txt = textColor(widget.isDark);
    final sub = subtext(widget.isDark);
    final reveal = widget.reveal;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = kMotionCurve.transform(_controller.value);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Transform.scale(
              scale: 0.96 + value * 0.04,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -6,
            left: 44,
            child: MilestoneConfettiBurst(
              color: reveal.color,
              alignment: Alignment.topCenter,
              particles: 18,
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: reveal.color.withAlpha(widget.isDark ? 20 : 15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: reveal.color.withAlpha(78)),
              boxShadow: [
                BoxShadow(
                  color: reveal.color.withAlpha(widget.isDark ? 26 : 22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                RewardGlowIcon(
                  icon: reveal.icon,
                  color: reveal.color,
                  size: 46,
                  iconSize: 21,
                  sparkle: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Сундук открыт',
                        style: TextStyle(
                          color: reveal.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        reveal.message,
                        style: TextStyle(
                          color: txt,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (reveal.buffTitle != null ||
                          reveal.bonusPercent != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          [
                            if (reveal.buffTitle != null) reveal.buffTitle!,
                            if (reveal.bonusPercent != null)
                              '+${reveal.bonusPercent}% XP',
                          ].join(' • '),
                          style: TextStyle(color: sub, fontSize: 11.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChestCard extends StatelessWidget {
  final RewardChest chest;
  final Skill? skill;
  final bool isDark;
  final VoidCallback onOpen;

  const _RewardChestCard({
    required this.chest,
    required this.skill,
    required this.isDark,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final rarityColor = rewardRarityColor[chest.rarity]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: rarityColor.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rarityColor.withAlpha(55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RewardGlowIcon(
            icon: chest.rarity == RewardRarity.epic
                ? Icons.auto_awesome
                : Icons.inventory_2,
            color: rarityColor,
            size: 42,
            iconSize: 20,
            sparkle: chest.rarity != RewardRarity.common,
            loop: chest.rarity == RewardRarity.epic,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chest.title,
                        style: TextStyle(
                          color: txt,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TaskBadge(
                      label: rewardRarityLabel[chest.rarity]!,
                      color: rarityColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  chest.description,
                  style: TextStyle(color: sub, fontSize: 11.5, height: 1.3),
                ),
                if (skill != null) ...[
                  const SizedBox(height: 6),
                  TaskBadge(
                    icon: skill!.icon,
                    label: skill!.name,
                    color: skill!.color,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          SmallBtn(
            label: 'Открыть',
            icon: Icons.auto_awesome,
            color: rarityColor,
            tooltip: 'Открыть сундук и получить трофей',
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

class _ActiveBuffCard extends StatelessWidget {
  final Buff buff;
  final Skill? skill;
  final bool isDark;

  const _ActiveBuffCard({
    required this.buff,
    required this.skill,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = skill?.color ?? const Color(0xFF34C759);
    final expiresAt = buff.expiresAt;
    final expiryLabel = expiresAt == null
        ? null
        : 'до ${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withAlpha(24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bolt, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buff.title,
                      style: TextStyle(
                        color: txt,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      buff.description,
                      style: TextStyle(color: sub, fontSize: 11),
                    ),
                  ],
                ),
              ),
              TaskBadge(
                icon: Icons.auto_awesome,
                label: '+${buff.bonusPercent}%',
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TaskBadge(
                icon: Icons.flash_on,
                label: '${buff.charges} заряд',
                color: accent,
              ),
              TaskBadge(
                icon: Icons.tune,
                label: buffTypeLabel[buff.type]!,
                color: const Color(0xFF4A9EFF),
              ),
              if (expiryLabel != null)
                TaskBadge(
                  icon: Icons.schedule,
                  label: expiryLabel,
                  color: const Color(0xFFFF9500),
                ),
              if (skill != null)
                TaskBadge(
                  icon: skill!.icon,
                  label: skill!.name,
                  color: skill!.color,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _RewardsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Column(
        children: [
          Icon(icon, color: sub, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: sub,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: sub.withAlpha(170), fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOSSES DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class BossesDialog extends StatefulWidget {
  final AppState state;
  const BossesDialog({super.key, required this.state});

  @override
  State<BossesDialog> createState() => _BossesDialogState();
}

class _BossesDialogState extends State<BossesDialog> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Color(0xFFFF2D55), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'События сопротивления',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть события сопротивления',
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),

            // Collapsible Explanation
            MotionExpandable(
              expanded: _expanded,
              collapsedChild: Tooltip(
                message: 'Показать объяснение событий сопротивления',
                child: GestureDetector(
                  onTap: () => setState(() => _expanded = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: sub, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Зачем здесь сопротивление?',
                          style: TextStyle(color: sub, fontSize: 12),
                        ),
                        const Spacer(),
                        Icon(Icons.expand_more, color: sub, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              expandedChild: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: fBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF2D55).withAlpha(50),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shield,
                          color: Color(0xFFFF2D55),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'События сопротивления',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: txt,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Tooltip(
                          message: 'Скрыть объяснение',
                          child: GestureDetector(
                            onTap: () => setState(() => _expanded = false),
                            child: Icon(
                              Icons.expand_less,
                              color: sub,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Сопротивление — это образ препятствия на пути навыка. Оно слабеет от выполненных квестов, лёгких стартов и общего прогресса, но не требует отдельного управления каждый день.',
                      style: TextStyle(color: sub, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTip(Icons.local_fire_department, 'Серия', sub),
                        const SizedBox(width: 16),
                        _buildTip(Icons.flag, 'Фокус', sub),
                        const SizedBox(width: 16),
                        _buildTip(Icons.play_circle_fill, 'Старт', sub),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Container(height: 1, color: bdr),
            Expanded(
              child: MotionFadeSlideSwitcher(
                child: widget.state.bosses.isEmpty
                    ? Center(
                        key: const ValueKey('bosses-empty'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, color: sub, size: 38),
                            const SizedBox(height: 12),
                            Text(
                              'Нет событий сопротивления',
                              style: TextStyle(color: sub, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Их можно добавить для навыка, где нужен образ препятствия.',
                              style: TextStyle(
                                color: sub.withAlpha(160),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        key: const ValueKey('bosses-list'),
                        padding: const EdgeInsets.all(14),
                        itemCount: widget.state.bosses.length,
                        itemBuilder: (_, i) {
                          final boss = widget.state.bosses[i];
                          return MotionListItem(
                            key: ValueKey('boss-${boss.id}'),
                            index: i,
                            child: _BossCard(
                              boss: boss,
                              snapshot: widget.state.bossSnapshot(boss),
                              skills: widget.state.skills,
                              isDark: isDark,
                              onDelete: () {
                                widget.state.removeBoss(boss.id);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
            Container(height: 1, color: bdr),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: HoverScale(
                      child: SmallBtn(
                        label: 'Добавить событие',
                        icon: Icons.add,
                        color: const Color(0xFFFF2D55),
                        tooltip: 'Добавить событие сопротивления',
                        onTap: () => _showAddBoss(context, widget.state),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String label, Color sub) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFF2D55), size: 12),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: sub, fontSize: 10)),
      ],
    );
  }

  void _showAddBoss(BuildContext ctx, AppState s) {
    showDialog(
      context: ctx,
      builder: (context) => _AddBossDialog(
        isDark: s.isDark,
        skills: s.skills
            .where(
              (sk) => !s.bosses.any(
                (boss) => boss.skillId == sk.id && !boss.isDefeated,
              ),
            )
            .toList(),
        onSave: (title, skillId, targetStreak) => s.addBoss(
          Boss(
            id: uid(),
            title: title,
            skillId: skillId,
            targetStreak: targetStreak,
            maxHp: 100,
            hp: 100,
          ),
        ),
      ),
    );
  }
}

class _BossCard extends StatelessWidget {
  final Boss boss;
  final BossSnapshot snapshot;
  final List<Skill> skills;
  final bool isDark;
  final VoidCallback onDelete;
  const _BossCard({
    required this.boss,
    required this.snapshot,
    required this.skills,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final skill = skills.where((s) => s.id == boss.skillId).firstOrNull;
    final c = skill?.color ?? const Color(0xFFFF2D55);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: boss.isDefeated
            ? const Color(0xFF34C759).withAlpha(15)
            : c.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: boss.isDefeated
              ? const Color(0xFF34C759).withAlpha(60)
              : c.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: boss.isDefeated
                      ? const Color(0xFF34C759).withAlpha(30)
                      : c.withAlpha(30),
                ),
                child: Icon(
                  boss.isDefeated ? Icons.check : Icons.shield,
                  color: boss.isDefeated ? const Color(0xFF34C759) : c,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boss.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: txt,
                        fontSize: 14,
                      ),
                    ),
                    if (skill != null)
                      Text(
                        'Навык: ${skill.name}',
                        style: TextStyle(color: sub, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (!boss.isDefeated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: snapshot.isUnderAttack
                        ? const Color(0xFFFF3B30).withAlpha(25)
                        : c.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    snapshot.phaseLabel,
                    style: TextStyle(
                      color: snapshot.isUnderAttack
                          ? const Color(0xFFFF3B30)
                          : c,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Побеждён',
                    style: TextStyle(
                      color: Color(0xFF34C759),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Удалить событие сопротивления',
                child: GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline, color: sub, size: 18),
                ),
              ),
            ],
          ),
          if (!boss.isDefeated) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: boss.hpPercent,
                      minHeight: 8,
                      backgroundColor: c.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation(c),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${boss.hp} HP  •  ${snapshot.impactPercent}%',
                  style: TextStyle(
                    color: c,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _BossMetricChip(
                  label: 'Серия',
                  value: '${snapshot.currentStreak}/${snapshot.targetStreak}',
                  color: const Color(0xFFFF9500),
                ),
                _BossMetricChip(
                  label: 'Фокус',
                  value: '${snapshot.priorityPercent}%',
                  color: const Color(0xFFFF2D55),
                ),
                _BossMetricChip(
                  label: 'Старт',
                  value: '${snapshot.startPercent}%',
                  color: const Color(0xFF4A9EFF),
                ),
                if (snapshot.totalTreeNodes > 0)
                  _BossMetricChip(
                    label: 'Карта',
                    value:
                        '${snapshot.masteredTreeNodes}/${snapshot.totalTreeNodes}',
                    color: const Color(0xFF34C759),
                  ),
                if (snapshot.stalledHighPriorityTasks > 0)
                  _BossMetricChip(
                    label: 'Риск',
                    value: '${snapshot.stalledHighPriorityTasks} важн.',
                    color: const Color(0xFFFF3B30),
                  ),
                if (snapshot.urgentRepeatingTasks > 0)
                  _BossMetricChip(
                    label: 'Срок',
                    value: '${snapshot.urgentRepeatingTasks} повт.',
                    color: const Color(0xFFFF3B30),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              snapshot.recommendation,
              style: TextStyle(color: sub, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _BossMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BossMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AddBossDialog extends StatefulWidget {
  final bool isDark;
  final List<Skill> skills;
  final Function(String title, String skillId, int targetStreak) onSave;
  const _AddBossDialog({
    required this.isDark,
    required this.skills,
    required this.onSave,
  });
  @override
  State<_AddBossDialog> createState() => _AddBossDialogState();
}

class _AddBossDialogState extends State<_AddBossDialog> {
  final _titleCtrl = TextEditingController();
  String? _skillId;
  int _streak = 7;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = surface(isDark);
    final fBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);
    final skills = _uniqueSkills(widget.skills);
    final selectedSkillId = skills.any((skill) => skill.id == _skillId)
        ? _skillId
        : null;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DlgHeader(title: 'Новое сопротивление', txtColor: txt),
              const SizedBox(height: 16),
              DlgField(
                label: 'Название события',
                ctrl: _titleCtrl,
                fBg: fBg,
                txt: txt,
                sub: sub,
                bdr: bdr,
              ),
              const SizedBox(height: 14),
              SubLbl('Навык', sub),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: fBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: bdr),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSkillId,
                    hint: Text(
                      'Выберите навык',
                      style: TextStyle(color: sub, fontSize: 14),
                    ),
                    isExpanded: true,
                    dropdownColor: surface(isDark),
                    items: skills
                        .map(
                          (sk) => DropdownMenuItem(
                            value: sk.id,
                            child: Row(
                              children: [
                                Icon(sk.icon, color: sk.color, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  sk.name,
                                  style: TextStyle(color: txt, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _skillId = v),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SubLbl('Базовый порог серии', sub),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2D55).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_streak дней',
                      style: const TextStyle(
                        color: Color(0xFFFF2D55),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _streak.toDouble(),
                min: 3,
                max: 30,
                divisions: 27,
                activeColor: const Color(0xFFFF2D55),
                inactiveColor: const Color(0xFFFF2D55).withAlpha(40),
                onChanged: (v) => setState(() => _streak = v.round()),
              ),
              Text(
                'Серия остаётся главным рычагом, но сопротивление также слабеет от важных квестов, лёгких стартов и прогресса по навыку.',
                style: TextStyle(color: sub, fontSize: 11, height: 1.3),
              ),
              const SizedBox(height: 16),
              DlgActions(onCancel: () => Navigator.pop(context), onSave: _save),
            ],
          ),
        ),
      ),
    );
  }

  List<Skill> _uniqueSkills(List<Skill> skills) {
    final seen = <String>{};
    return [
      for (final skill in skills)
        if (seen.add(skill.id)) skill,
    ];
  }

  void _save() {
    final skillId = _skillId;
    if (_titleCtrl.text.trim().isEmpty ||
        skillId == null ||
        !_uniqueSkills(widget.skills).any((skill) => skill.id == skillId)) {
      return;
    }
    widget.onSave(_titleCtrl.text.trim(), skillId, _streak);
    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CALENDAR VIEW DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
