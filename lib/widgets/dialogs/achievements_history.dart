part of '../dialogs.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENTS DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class AchievementsDialog extends StatelessWidget {
  final List<Achievement> achievements;
  final bool isDark;
  const AchievementsDialog({
    super.key,
    required this.achievements,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        height: 560,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Color(0xFFFFCC00),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Достижения',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: txt,
                    ),
                  ),
                  const Spacer(),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть достижения',
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: achievements.length,
                itemBuilder: (_, i) => _AchievementCard(
                  achievement: achievements[i],
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isDark;
  const _AchievementCard({required this.achievement, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final def = achievement.def;
    if (def == null) return const SizedBox.shrink();

    final unlocked = achievement.isUnlocked;
    final sub = subtext(isDark);
    final txt = textColor(isDark);

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: unlocked
              ? def.color.withAlpha(18)
              : (isDark ? const Color(0xFF13131A) : const Color(0xFFF5F5F7)),
          borderRadius: BorderRadius.circular(12),
          border: unlocked
              ? Border.all(color: def.color.withAlpha(60))
              : Border.all(color: borderColor(isDark)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unlocked
                        ? def.color.withAlpha(30)
                        : sub.withAlpha(20),
                  ),
                  child: Icon(
                    def.icon,
                    color: unlocked ? def.color : sub.withAlpha(100),
                    size: 24,
                  ),
                ),
                if (!unlocked)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withAlpha(60),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              def.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: unlocked ? txt : sub.withAlpha(100),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (unlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                _formatDate(achievement.unlockedAt!),
                style: TextStyle(fontSize: 9, color: sub.withAlpha(150)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final def = achievement.def;
    if (def == null) return;

    final unlocked = achievement.isUnlocked;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (unlocked
                              ? def.color
                              : subtext(AppStateProvider.of(ctx).isDark))
                          .withAlpha(30),
                ),
                child: Icon(
                  def.icon,
                  color: unlocked
                      ? def.color
                      : subtext(AppStateProvider.of(ctx).isDark),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                def.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor(AppStateProvider.of(ctx).isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                def.description,
                style: TextStyle(
                  color: subtext(AppStateProvider.of(ctx).isDark),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: unlocked
                      ? const Color(0xFF34C759).withAlpha(25)
                      : const Color(0xFF8E8E93).withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  unlocked ? 'Разблокировано!' : 'Заблокировано',
                  style: TextStyle(
                    color: unlocked
                        ? const Color(0xFF34C759)
                        : const Color(0xFF8E8E93),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// HISTORY DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class HistoryDialog extends StatelessWidget {
  final List<HistoryEntry> history;
  final bool isDark;
  const HistoryDialog({super.key, required this.history, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final bdr = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        height: 560,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Журнал XP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: txt,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Подробности закрытых квестов, XP и откатов.',
                          style: TextStyle(
                            color: sub,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PressFeedback(
                    scale: 0.94,
                    tooltip: 'Закрыть журнал',
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: bdr),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book, color: sub, size: 38),
                          const SizedBox(height: 12),
                          Text(
                            'Журнал пока пуст',
                            style: TextStyle(color: sub, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Закрой первый квест — здесь появятся детали роста',
                            style: TextStyle(
                              color: sub.withAlpha(160),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      itemCount: history.length,
                      itemBuilder: (_, i) =>
                          _HistoryCard(entry: history[i], isDark: isDark),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final bool isDark;
  const _HistoryCard({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final c = e.skillColor;
    final sub = subtext(isDark);
    final txt = textColor(isDark);
    final accentBg = e.isCompletion
        ? c.withAlpha(22)
        : const Color(0xFFFF3B30).withAlpha(18);
    final accentBorder = e.isCompletion
        ? c.withAlpha(80)
        : const Color(0xFFFF3B30).withAlpha(60);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  e.taskTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: txt,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    e.isCompletion ? 'Квест закрыт' : 'Откат квеста',
                    style: TextStyle(
                      color: sub,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(e.at),
                    style: TextStyle(color: sub, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(e.skillIcon, color: c, size: 13),
              const SizedBox(width: 5),
              Text('Навык: ', style: TextStyle(color: sub, fontSize: 12)),
              Text(
                e.skillName,
                style: TextStyle(
                  color: c,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            e.isCompletion ? '+${e.xp} XP' : '-${e.xp} XP',
            style: TextStyle(
              color: e.isCompletion ? c : const Color(0xFFFF3B30),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
