import 'package:flutter/material.dart';

import '../../utils.dart';
import '../shared.dart';
import 'weekly_presentation_data.dart';

class WeeklyHeader extends StatelessWidget {
  final bool isDark;
  final DateTime weekStart;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onClose;

  const WeeklyHeader({
    super.key,
    required this.isDark,
    required this.weekStart,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = const Color(0xFF34C759);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withAlpha(26),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.calendar_view_week,
              color: Color(0xFF34C759),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Обзор недели',
                  style: TextStyle(
                    color: txt,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatWeeklyDayMonth(weekStart)} — ${formatWeeklyDayMonth(weekStart.add(const Duration(days: 6)))} · что получилось, какой навык рос и что мягко продолжить',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: sub, fontSize: 12.5, height: 1.25),
                ),
              ],
            ),
          ),
          _WeekNavButton(
            tooltip: 'Предыдущая неделя',
            icon: Icons.chevron_left,
            color: sub,
            onTap: onPrevious,
          ),
          const SizedBox(width: 6),
          _WeekNavButton(
            tooltip: canGoNext ? 'Следующая неделя' : 'Это текущая неделя',
            icon: Icons.chevron_right,
            color: sub,
            onTap: onNext,
          ),
          const SizedBox(width: 10),
          PressFeedback(
            scale: 0.94,
            tooltip: 'Закрыть обзор недели',
            onTap: onClose,
            child: Icon(Icons.close, color: sub, size: 22),
          ),
        ],
      ),
    );
  }
}

class _WeekNavButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _WeekNavButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withAlpha(onTap == null ? 10 : 18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color.withAlpha(onTap == null ? 90 : 230)),
    );

    if (onTap == null) {
      return Tooltip(message: tooltip, child: button);
    }

    return PressFeedback(
      scale: 0.94,
      tooltip: tooltip,
      onTap: onTap!,
      child: button,
    );
  }
}
