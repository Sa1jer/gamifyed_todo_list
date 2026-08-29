import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../theme/app_typography.dart';
import '../../utils.dart';
import '../desktop_journal_tokens.dart';
import '../shared.dart';

enum _DesktopTaskMenuAction { edit, archive, restore, delete }

class DesktopQuestRow extends StatefulWidget {
  final AppState state;
  final Task task;
  final Skill skill;
  final DesktopJournalTokens tokens;
  final void Function(String taskId, ActionToastOrigin origin) onComplete;
  final void Function(String taskId, ActionToastOrigin origin) onMinimumAction;
  final GlobalKey? minimumActionTutorialKey;
  final GlobalKey? completionTutorialKey;
  final VoidCallback onEdit;

  const DesktopQuestRow({
    super.key,
    required this.state,
    required this.task,
    required this.skill,
    required this.tokens,
    required this.onComplete,
    required this.onMinimumAction,
    this.minimumActionTutorialKey,
    this.completionTutorialKey,
    required this.onEdit,
  });

  @override
  State<DesktopQuestRow> createState() => _DesktopQuestRowState();
}

class _DesktopQuestRowState extends State<DesktopQuestRow> {
  bool _hovered = false;
  bool _focused = false;
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final tokens = widget.tokens;
    final done = task.isDone;
    final reward = done
        ? math.max(task.earnedXP, task.xpReward)
        : widget.state.previewEarnedXP(task);
    final type = typeLabel[task.type] ?? 'Квест';
    final badgeColor = typeColor[task.type] ?? widget.skill.color;
    final actionsVisible = _hovered || _focused || _menuOpen;
    return Semantics(
      button: true,
      label:
          '${task.title}, ${done ? 'выполненный' : 'активный'} квест, награда $reward XP',
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: DesktopJournalTokens.fastMotion,
            curve: DesktopJournalTokens.motionCurve,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: done
                  ? tokens.successGreenGraphic.withValues(alpha: 0.045)
                  : _hovered
                  ? tokens.raisedSurface
                  : tokens.cardSurface,
              borderRadius: BorderRadius.circular(
                DesktopJournalTokens.taskRadius,
              ),
              border: Border.all(
                color: done
                    ? tokens.successGreenGraphic.withValues(alpha: 0.18)
                    : _hovered
                    ? widget.skill.color.withValues(alpha: 0.22)
                    : tokens.outline,
              ),
              boxShadow: done
                  ? null
                  : [
                      BoxShadow(
                        color: widget.skill.color.withValues(alpha: 0.022),
                        blurRadius: 12,
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                KeyedSubtree(
                  key: widget.completionTutorialKey,
                  child: _DesktopQuestCheck(
                    done: done,
                    color: done
                        ? tokens.successGreenGraphic
                        : widget.skill.color,
                    onTap: (origin) {
                      if (done) {
                        widget.state.uncompleteTask(task.id);
                      } else {
                        widget.onComplete(task.id, origin);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: done ? tokens.mutedText : tokens.text,
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tokens.mutedText,
                            fontSize: 11.5,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _DesktopTypeBadge(label: type, color: badgeColor),
                          if (!done &&
                              task.hasMinimumAction &&
                              !task.isMinimumActionDone)
                            _DesktopMiniAction(
                              label: 'Минимальный шаг',
                              color: widget.skill.color,
                              tutorialKey: widget.minimumActionTutorialKey,
                              onTap: (origin) =>
                                  widget.onMinimumAction(task.id, origin),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _DesktopRewardPill(value: reward, tokens: tokens),
                const SizedBox(width: 4),
                AnimatedOpacity(
                  key: ValueKey('desktop-task-overflow-${task.id}'),
                  duration: DesktopJournalTokens.fastMotion,
                  opacity: actionsVisible ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !actionsVisible,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: PopupMenuButton<_DesktopTaskMenuAction>(
                        tooltip: 'Действия с квестом ${task.title}',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: tokens.mutedText,
                          size: 19,
                        ),
                        color: tokens.raisedSurface,
                        onOpened: () => setState(() => _menuOpen = true),
                        onCanceled: () => setState(() => _menuOpen = false),
                        onSelected: (action) {
                          setState(() => _menuOpen = false);
                          switch (action) {
                            case _DesktopTaskMenuAction.edit:
                              widget.onEdit();
                            case _DesktopTaskMenuAction.archive:
                              widget.state.archiveCompletedTask(task.id);
                            case _DesktopTaskMenuAction.restore:
                              widget.state.restoreArchivedTask(task.id);
                            case _DesktopTaskMenuAction.delete:
                              widget.state.removeTask(task.id);
                          }
                        },
                        itemBuilder: (_) => [
                          if (!done)
                            PopupMenuItem(
                              value: _DesktopTaskMenuAction.edit,
                              child: Text(
                                'Редактировать',
                                style: TextStyle(color: tokens.text),
                              ),
                            ),
                          if (done && !task.isArchived)
                            PopupMenuItem(
                              value: _DesktopTaskMenuAction.archive,
                              child: Text(
                                'Архивировать',
                                style: TextStyle(color: tokens.text),
                              ),
                            ),
                          if (done && task.isArchived)
                            PopupMenuItem(
                              value: _DesktopTaskMenuAction.restore,
                              child: Text(
                                'Вернуть из архива',
                                style: TextStyle(color: tokens.text),
                              ),
                            ),
                          PopupMenuItem(
                            value: _DesktopTaskMenuAction.delete,
                            child: Text(
                              'Удалить',
                              style: TextStyle(color: tokens.danger),
                            ),
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
  }
}

class _DesktopQuestCheck extends StatefulWidget {
  final bool done;
  final Color color;
  final ValueChanged<ActionToastOrigin> onTap;

  const _DesktopQuestCheck({
    required this.done,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DesktopQuestCheck> createState() => _DesktopQuestCheckState();
}

class _DesktopQuestCheckState extends State<_DesktopQuestCheck> {
  ActionToastOrigin? _origin;
  final GlobalKey _checkKey = GlobalKey();

  void _completeTap() {
    final origin =
        _origin ??
        actionToastOriginForContext(
          _checkKey.currentContext ?? context,
          kind: ActionToastOriginKind.questCheckbox,
          zone: ActionToastZone.mainWorkspace,
        );
    _origin = null;
    widget.onTap(origin);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: widget.done,
      label: widget.done ? 'Вернуть квест' : 'Выполнить квест',
      child: Tooltip(
        message: widget.done ? 'Вернуть квест' : 'Выполнить квест',
        child: InkResponse(
          key: _checkKey,
          onTapDown: (_) => _origin = actionToastOriginForContext(
            _checkKey.currentContext ?? context,
            kind: ActionToastOriginKind.questCheckbox,
            zone: ActionToastZone.mainWorkspace,
          ),
          onTapCancel: () => _origin = null,
          onTap: _completeTap,
          radius: 24,
          child: AnimatedContainer(
            duration: DesktopJournalTokens.fastMotion,
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: widget.done ? 1 : 0),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.75),
                width: 2,
              ),
            ),
            child: widget.done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        ),
      ),
    );
  }
}

class _DesktopTypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DesktopTypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DesktopMiniAction extends StatefulWidget {
  final String label;
  final Color color;
  final GlobalKey? tutorialKey;
  final ValueChanged<ActionToastOrigin> onTap;

  const _DesktopMiniAction({
    required this.label,
    required this.color,
    this.tutorialKey,
    required this.onTap,
  });

  @override
  State<_DesktopMiniAction> createState() => _DesktopMiniActionState();
}

class _DesktopMiniActionState extends State<_DesktopMiniAction> {
  ActionToastOrigin? _origin;
  final GlobalKey _actionKey = GlobalKey();
  GlobalKey get _anchorKey => widget.tutorialKey ?? _actionKey;

  void _completeTap() {
    final origin =
        _origin ??
        actionToastOriginForContext(
          _anchorKey.currentContext ?? context,
          kind: ActionToastOriginKind.minimumAction,
          zone: ActionToastZone.mainWorkspace,
        );
    _origin = null;
    widget.onTap(origin);
  }

  @override
  Widget build(BuildContext context) {
    final anchorKey = _anchorKey;
    return InkWell(
      key: anchorKey,
      onTapDown: (_) => _origin = actionToastOriginForContext(
        anchorKey.currentContext ?? context,
        kind: ActionToastOriginKind.minimumAction,
        zone: ActionToastZone.mainWorkspace,
      ),
      onTapCancel: () => _origin = null,
      onTap: _completeTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.color,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DesktopRewardPill extends StatelessWidget {
  final int value;
  final DesktopJournalTokens tokens;

  const _DesktopRewardPill({required this.value, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Награда $value XP',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.rewardGoldGraphic.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: tokens.rewardGoldGraphic.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: tokens.rewardGoldGraphic, size: 13),
            const SizedBox(width: 4),
            Text(
              '+$value XP',
              style: context.appTextRoles.reward.copyWith(
                color: tokens.rewardGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
