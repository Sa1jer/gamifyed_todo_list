import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../feedback_service.dart';
import '../../models.dart';
import '../../utils.dart';
import '../shared.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final bool isDark;
  final Color skillColor;
  final int previewEarnedXP;
  final int previewBuffBonus;
  final ValueChanged<ActionToastOrigin> onToggle;
  final ValueChanged<ActionToastOrigin> onMinimumAction;
  final VoidCallback onUncomplete;
  final VoidCallback onArchive;
  final VoidCallback onRestoreArchive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskTile({
    super.key,
    required this.task,
    required this.isDark,
    required this.skillColor,
    required this.previewEarnedXP,
    required this.previewBuffBonus,
    required this.onToggle,
    required this.onMinimumAction,
    required this.onUncomplete,
    required this.onArchive,
    required this.onRestoreArchive,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  final _checkboxKey = GlobalKey();
  final _minimumActionKey = GlobalKey();
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDark = widget.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final tileBg = isDark ? const Color(0xFF13131A) : const Color(0xFFF8F8FA);
    final bdr = borderColor(isDark);
    final previewMultiplier = task.xpReward == 0
        ? 1
        : (widget.previewEarnedXP / task.xpReward).round();
    final canStartMinimum =
        task.hasMinimumAction && !task.isDone && !task.isMinimumActionDone;
    final showStartedBadge = task.isMinimumActionDone && !task.isDone;
    final compact = MediaQuery.sizeOf(context).width < 760;

    Widget minimumControl() {
      if (canStartMinimum) {
        return Tooltip(
          message: 'Сделать лёгкий старт: ${task.minimumAction}',
          child: PressFeedback(
            scale: 0.96,
            onTap: () =>
                _completeMinimum(_minimumActionKey.currentContext ?? context),
            child: Container(
              key: _minimumActionKey,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 9,
                vertical: compact ? 5 : 6,
              ),
              decoration: BoxDecoration(
                color: widget.skillColor.withAlpha(10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: widget.skillColor.withAlpha(46)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: widget.skillColor.withAlpha(210),
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Минимум',
                    style: TextStyle(
                      color: widget.skillColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Tooltip(
        message: 'Лёгкий старт уже сделан',
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 9,
            vertical: compact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF34C759).withAlpha(16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF34C759).withAlpha(76)),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Color(0xFF34C759),
            size: 14,
          ),
        ),
      );
    }

    final tile = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: 1,
        alignment: Alignment.center,
        duration: kMotionStandard,
        curve: kMotionCurve,
        child: AnimatedContainer(
          duration: kMotionStandard,
          curve: kMotionCurve,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered
                ? (isDark ? const Color(0xFF181820) : const Color(0xFFF1F2FA))
                : tileBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? widget.skillColor.withAlpha(55) : bdr,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 9 : 11,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Tooltip(
                  message: task.isDone
                      ? 'Вернуть квест в активные и откатить XP'
                      : 'Выполнить квест и начислить XP',
                  child: PressFeedback(
                    scale: 0.94,
                    onTap: () {
                      if (task.isDone) {
                        _uncomplete();
                      } else {
                        _complete(_checkboxKey.currentContext ?? context);
                      }
                    },
                    child: AnimatedContainer(
                      key: _checkboxKey,
                      duration: kMotionStandard,
                      curve: kMotionCurve,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.isDone
                              ? widget.skillColor
                              : _hovered
                              ? widget.skillColor
                              : sub.withAlpha(145),
                          width: 2,
                        ),
                        color: task.isDone
                            ? widget.skillColor
                            : _hovered
                            ? widget.skillColor.withAlpha(18)
                            : Colors.transparent,
                      ),
                      child: task.isDone
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
                if (task.hasMinimumAction && !compact) ...[
                  const SizedBox(width: 8),
                  minimumControl(),
                ],
                SizedBox(width: compact ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TaskTitleWithDescription(
                        task: task,
                        titleStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: task.isDone ? sub : txt,
                        ),
                        descriptionColor: sub,
                        titleDecoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: sub,
                      ),
                      if (task.hasMinimumAction) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Минимум: ${task.minimumAction}',
                          style: TextStyle(
                            color: showStartedBadge
                                ? widget.skillColor
                                : sub.withAlpha(220),
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (compact) ...[
                          const SizedBox(height: 6),
                          minimumControl(),
                        ],
                      ],
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          XpRewardPill(
                            key: ValueKey('quest-xp-${task.id}'),
                            xp: task.isDone
                                ? task.earnedXP
                                : widget.previewEarnedXP,
                            isDark: isDark,
                            isReversal: task.isDone,
                          ),
                          if (!compact &&
                              !task.isDone &&
                              widget.previewBuffBonus > 0)
                            TaskBadge(
                              icon: Icons.bolt,
                              label: 'эффект +${widget.previewBuffBonus}',
                              color: const Color(0xFF34C759),
                            ),
                          if (!compact && task.isDone && task.bonusXpEarned > 0)
                            TaskBadge(
                              icon: Icons.bolt,
                              label: '+${task.bonusXpEarned} бонус',
                              color: const Color(0xFF34C759),
                            ),
                          if (showStartedBadge)
                            const TaskBadge(
                              icon: Icons.play_circle_fill,
                              label: 'Старт сделан',
                              color: Color(0xFF34C759),
                            ),
                          if (showStartedBadge)
                            TaskBadge(
                              icon: Icons.bolt,
                              label: '+${task.minimumActionEarnedXP} XP',
                              color: widget.skillColor,
                            ),
                          if (task.type == TaskType.repeating) ...[
                            TaskBadge(
                              icon: Icons.repeat,
                              label: freqLabel[task.repeatFrequency]!,
                              color: const Color(0xFF4A9EFF),
                            ),
                            if (!task.isDone && previewMultiplier > 1)
                              TaskBadge(
                                icon: Icons.local_fire_department,
                                label: '×$previewMultiplier',
                                color: const Color(0xFFFF9500),
                              ),
                            if (task.streak > 0)
                              Text(
                                '${task.streak} д.',
                                style: TextStyle(color: sub, fontSize: 11),
                              ),
                            if (task.isDone && task.nextResetAt != null)
                              Text(
                                formatResetLabel(task.nextResetAt),
                                style: TextStyle(color: sub, fontSize: 11),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!compact)
                  SizedBox(
                    width: 50,
                    child: AnimatedOpacity(
                      duration: kMotionStandard,
                      curve: kMotionCurve,
                      opacity: _hovered ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_hovered,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MiniBtn(
                              icon: Icons.edit,
                              color: sub,
                              tooltip: 'Редактировать квест',
                              onTap: _edit,
                            ),
                            MiniBtn(
                              icon: Icons.delete_outline,
                              color: const Color(0xFFFF3B30),
                              tooltip: 'Удалить квест',
                              onTap: _delete,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Slidable(
      key: ValueKey('slidable-${task.id}-${task.isDone}'),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: canStartMinimum && !task.isDone ? 0.46 : 0.28,
        children: [
          if (task.isDone)
            SlidableAction(
              onPressed: (_) =>
                  task.isArchived ? _restoreArchive() : _archive(),
              backgroundColor: const Color(0xFF8E8E93),
              foregroundColor: Colors.white,
              icon: task.isArchived ? Icons.undo : Icons.archive_outlined,
              label: task.isArchived ? 'Вернуть' : 'В Выполнено',
              borderRadius: BorderRadius.circular(10),
            )
          else ...[
            SlidableAction(
              onPressed: (actionContext) => _complete(actionContext),
              backgroundColor: const Color(0xFF34C759),
              foregroundColor: Colors.white,
              icon: Icons.check,
              label: 'Готово',
              borderRadius: BorderRadius.circular(10),
            ),
            if (canStartMinimum)
              SlidableAction(
                onPressed: (actionContext) => _completeMinimum(actionContext),
                backgroundColor: widget.skillColor,
                foregroundColor: Colors.white,
                icon: Icons.play_arrow_rounded,
                label: 'Старт',
                borderRadius: BorderRadius.circular(10),
              ),
          ],
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.42,
        children: [
          SlidableAction(
            onPressed: (_) => _edit(),
            backgroundColor: const Color(0xFF4A9EFF),
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Править',
            borderRadius: BorderRadius.circular(10),
          ),
          SlidableAction(
            onPressed: (_) => _delete(),
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Удалить',
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
      child: tile,
    );
  }

  ActionToastOrigin _originFor(
    BuildContext context,
    ActionToastOriginKind kind,
  ) {
    return actionToastOriginForContext(
      context,
      kind: kind,
      zone: ActionToastZone.mainWorkspace,
      sourceId: widget.task.id,
    );
  }

  void _complete(BuildContext context) {
    widget.onToggle(_originFor(context, ActionToastOriginKind.questCheckbox));
  }

  void _completeMinimum(BuildContext context) {
    widget.onMinimumAction(
      _originFor(context, ActionToastOriginKind.minimumAction),
    );
  }

  void _uncomplete() {
    AppFeedback.selection();
    widget.onUncomplete();
  }

  void _archive() {
    AppFeedback.selection();
    widget.onArchive();
  }

  void _restoreArchive() {
    AppFeedback.selection();
    widget.onRestoreArchive();
  }

  void _edit() {
    AppFeedback.selection();
    widget.onEdit();
  }

  void _delete() {
    AppFeedback.destructive();
    widget.onDelete();
  }
}
