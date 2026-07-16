import 'package:flutter/material.dart';

import '../../models.dart';
import '../../utils.dart';
import '../reward_animations.dart';
import '../shared.dart';

class RewardReveal {
  final String id;
  final String message;
  final String? buffTitle;
  final int? bonusPercent;
  final Color color;
  final IconData icon;

  const RewardReveal({
    required this.id,
    required this.message,
    required this.color,
    required this.icon,
    this.buffTitle,
    this.bonusPercent,
  });
}

class RewardRevealNotice extends StatefulWidget {
  final RewardReveal reveal;
  final bool isDark;

  const RewardRevealNotice({
    super.key,
    required this.reveal,
    required this.isDark,
  });

  @override
  State<RewardRevealNotice> createState() => _RewardRevealNoticeState();
}

class _RewardRevealNoticeState extends State<RewardRevealNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kMotionProgress)
      ..forward();
  }

  @override
  void didUpdateWidget(covariant RewardRevealNotice oldWidget) {
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

class RewardChestCard extends StatelessWidget {
  final RewardChest chest;
  final Skill? skill;
  final bool isDark;
  final VoidCallback onOpen;

  const RewardChestCard({
    super.key,
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

class ActiveBuffCard extends StatelessWidget {
  final Buff buff;
  final Skill? skill;
  final bool isDark;

  const ActiveBuffCard({
    super.key,
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

class RewardsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const RewardsEmptyState({
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
