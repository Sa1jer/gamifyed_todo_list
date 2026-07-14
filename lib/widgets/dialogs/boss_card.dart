import 'package:flutter/material.dart';

import '../../models.dart';
import '../../utils.dart';

/// Presentation for one resistance event. Mutation ownership stays with the
/// dialog/AppState boundary through [onDelete].
class BossResistanceCard extends StatelessWidget {
  final Boss boss;
  final BossSnapshot snapshot;
  final List<Skill> skills;
  final bool isDark;
  final VoidCallback onDelete;

  const BossResistanceCard({
    super.key,
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
    final accent = skill?.color ?? const Color(0xFFFF2D55);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: boss.isDefeated
            ? const Color(0xFF34C759).withAlpha(15)
            : accent.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: boss.isDefeated
              ? const Color(0xFF34C759).withAlpha(60)
              : accent.withAlpha(60),
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
                      : accent.withAlpha(30),
                ),
                child: Icon(
                  boss.isDefeated ? Icons.check : Icons.shield,
                  color: boss.isDefeated ? const Color(0xFF34C759) : accent,
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
              _BossPhaseBadge(boss: boss, snapshot: snapshot, accent: accent),
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
                      backgroundColor: accent.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${boss.hp} HP  •  ${snapshot.impactPercent}%',
                  style: TextStyle(
                    color: accent,
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

class _BossPhaseBadge extends StatelessWidget {
  final Boss boss;
  final BossSnapshot snapshot;
  final Color accent;

  const _BossPhaseBadge({
    required this.boss,
    required this.snapshot,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final defeated = boss.isDefeated;
    final color = defeated
        ? const Color(0xFF34C759)
        : snapshot.isUnderAttack
        ? const Color(0xFFFF3B30)
        : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        defeated ? 'Побеждён' : snapshot.phaseLabel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
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
