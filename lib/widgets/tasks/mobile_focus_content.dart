import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../feedback_service.dart';
import '../../models.dart';
import '../../utils.dart';
import '../mobile_journal_tokens.dart';
import '../shared.dart';

class SkillIcon extends StatelessWidget {
  final Skill skill;

  const SkillIcon({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: skill.color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(skill.icon, color: skill.color, size: 16),
    );
  }
}

class EmptyTasksState extends StatelessWidget {
  final bool isDark;
  final Color skillColor;
  final String skillName;
  final VoidCallback onAdd;
  final Key? createFirstQuestButtonKey;
  final bool mobileJournal;

  const EmptyTasksState({
    super.key,
    required this.isDark,
    required this.skillColor,
    required this.skillName,
    required this.onAdd,
    this.createFirstQuestButtonKey,
    this.mobileJournal = false,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = mobileJournal || constraints.maxHeight < 220;
        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 10 : 22),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.task_alt,
                  color: skillColor,
                  size: compact ? 26 : 38,
                ),
                SizedBox(height: compact ? 6 : 12),
                Text(
                  mobileJournal
                      ? 'Добавь первый квест'
                      : 'Добавь квест, чтобы начать движение',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: txt,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  mobileJournal
                      ? 'Начни с маленького действия — так легче вернуться завтра.'
                      : 'У “$skillName” пока нет активных действий. Создай небольшой квест и добавь минимальный шаг — так начать будет легче.',
                  textAlign: TextAlign.center,
                  maxLines: compact ? 2 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style: TextStyle(color: sub, fontSize: 12, height: 1.3),
                ),
                SizedBox(height: compact ? 8 : 14),
                HoverScale(
                  child: SmallBtn(
                    key: createFirstQuestButtonKey,
                    label: 'Создать квест',
                    icon: Icons.add,
                    color: skillColor,
                    tooltip: 'Создать первый квест для навыка “$skillName”',
                    onTap: onAdd,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MobileFocusEmptyState extends StatelessWidget {
  final bool isDark;
  final Color skillColor;
  final String skillName;
  final VoidCallback onAdd;
  final Key? createFirstQuestButtonKey;

  const MobileFocusEmptyState({
    super.key,
    required this.isDark,
    required this.skillColor,
    required this.skillName,
    required this.onAdd,
    this.createFirstQuestButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final txt = MobileJournalTokens.text(isDark);
    final sub = MobileJournalTokens.muted(isDark);
    return Padding(
      key: const ValueKey('tasks-empty-state'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: MobileJournalTokens.skillAccentSoft(skillColor, isDark),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.task_alt_rounded, color: skillColor, size: 25),
          ),
          const SizedBox(height: 10),
          Text(
            'Добавь первый квест',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: txt,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Начни с маленького действия — так легче вернуться завтра.',
            textAlign: TextAlign.center,
            style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          MobileAddQuestAction(
            key: createFirstQuestButtonKey,
            skillColor: skillColor,
            isDark: isDark,
            label: 'Создать квест',
            semanticsLabel: 'Создать первый квест для навыка $skillName',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class MobileAddQuestAction extends StatelessWidget {
  final Color skillColor;
  final bool isDark;
  final String label;
  final String? semanticsLabel;
  final VoidCallback onPressed;

  const MobileAddQuestAction({
    super.key,
    required this.skillColor,
    required this.isDark,
    required this.label,
    required this.onPressed,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 8),
      child: Semantics(
        button: true,
        label: semanticsLabel,
        child: DashedBorderContainer(
          key: const ValueKey('mobile-dashed-add-quest'),
          color: MobileJournalTokens.skillAccentBorder(skillColor, isDark),
          backgroundColor: MobileJournalTokens.skillAccentSoft(
            skillColor,
            isDark,
          ).withAlpha(isDark ? 11 : 8),
          borderRadius: BorderRadius.circular(16),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPressed,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 20, color: skillColor),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: skillColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MobileFocusTaskTile extends StatefulWidget {
  final Task task;
  final bool isDark;
  final Color skillColor;
  final int previewEarnedXP;
  final ValueChanged<ActionToastOrigin> onToggle;
  final ValueChanged<ActionToastOrigin> onMinimumAction;
  final VoidCallback onUncomplete;
  final VoidCallback onArchive;
  final VoidCallback onRestoreArchive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const MobileFocusTaskTile({
    super.key,
    required this.task,
    required this.isDark,
    required this.skillColor,
    required this.previewEarnedXP,
    required this.onToggle,
    required this.onMinimumAction,
    required this.onUncomplete,
    required this.onArchive,
    required this.onRestoreArchive,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<MobileFocusTaskTile> createState() => _MobileFocusTaskTileState();
}

class _MobileFocusTaskTileState extends State<MobileFocusTaskTile> {
  final _checkboxKey = GlobalKey();
  final _minimumKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final txt = MobileJournalTokens.text(widget.isDark);
    final sub = MobileJournalTokens.muted(widget.isDark);
    final canStartMinimum =
        task.hasMinimumAction && !task.isDone && !task.isMinimumActionDone;
    final rewardXp = task.isDone
        ? (task.earnedXP > 0 ? task.earnedXP : task.xpReward)
        : widget.previewEarnedXP;
    final hasDescription = task.description.trim().isNotEmpty;
    final baseRowColor = MobileJournalTokens.questRow(widget.isDark);
    final rowColor = task.isDone
        ? Color.alphaBlend(widget.skillColor.withAlpha(22), baseRowColor)
        : baseRowColor;

    final row = Container(
      key: ValueKey('mobile-focus-quest-row-${task.id}'),
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: EdgeInsets.fromLTRB(
        11,
        hasDescription ? 12 : 7,
        12,
        hasDescription ? 12 : 7,
      ),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: task.isDone
              ? widget.skillColor.withAlpha(82)
              : MobileJournalTokens.outline(widget.isDark),
        ),
      ),
      child: Row(
        crossAxisAlignment: hasDescription
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            checked: task.isDone,
            label: task.isDone
                ? 'Квест ${task.title} выполнен, вернуть в активные'
                : 'Выполнить квест ${task.title}',
            child: Tooltip(
              message: task.isDone
                  ? 'Вернуть квест в активные'
                  : 'Выполнить квест',
              child: PressFeedback(
                scale: 0.94,
                onTap: () => task.isDone
                    ? _uncomplete()
                    : _complete(_checkboxKey.currentContext ?? context),
                child: SizedBox.square(
                  dimension: 42,
                  child: Center(
                    child: AnimatedContainer(
                      key: _checkboxKey,
                      duration: kMotionStandard,
                      curve: kMotionCurve,
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isDone
                            ? widget.skillColor
                            : Colors.transparent,
                        border: Border.all(
                          color: task.isDone
                              ? widget.skillColor
                              : sub.withAlpha(145),
                          width: 2,
                        ),
                      ),
                      child: task.isDone
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stackReward =
                    constraints.maxWidth < 245 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final title = _MobileQuestCopy(
                  task: task,
                  titleColor: task.isDone ? sub : txt,
                  descriptionColor: sub,
                );
                final reward = XpRewardPill(
                  key: ValueKey('quest-xp-${task.id}'),
                  xp: rewardXp,
                  isDark: widget.isDark,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stackReward) ...[
                      title,
                      const SizedBox(height: 8),
                      reward,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: title),
                          const SizedBox(width: 8),
                          reward,
                        ],
                      ),
                    if (task.hasMinimumAction && !task.isDone) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        button: canStartMinimum,
                        label: canStartMinimum
                            ? 'Сделать минимальный шаг ${task.minimumAction}'
                            : 'Минимальный шаг выполнен',
                        child: InkWell(
                          key: _minimumKey,
                          borderRadius: BorderRadius.circular(10),
                          onTap: canStartMinimum
                              ? () => _completeMinimum(
                                  _minimumKey.currentContext ?? context,
                                )
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  task.isMinimumActionDone
                                      ? Icons.check_circle_rounded
                                      : Icons.play_circle_outline_rounded,
                                  size: 16,
                                  color: task.isMinimumActionDone
                                      ? const Color(0xFF35C76F)
                                      : widget.skillColor,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Минимум: ${task.minimumAction}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: task.isMinimumActionDone
                                          ? const Color(0xFF35C76F)
                                          : sub,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
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
              icon: task.isArchived
                  ? Icons.undo_rounded
                  : Icons.archive_outlined,
              label: task.isArchived ? 'Вернуть' : 'В Выполнено',
              borderRadius: BorderRadius.circular(16),
            )
          else ...[
            SlidableAction(
              onPressed: (actionContext) => _complete(actionContext),
              backgroundColor: const Color(0xFF35C76F),
              foregroundColor: Colors.white,
              icon: Icons.check_rounded,
              label: 'Готово',
              borderRadius: BorderRadius.circular(16),
            ),
            if (canStartMinimum)
              SlidableAction(
                onPressed: (actionContext) => _completeMinimum(actionContext),
                backgroundColor: widget.skillColor,
                foregroundColor: Colors.white,
                icon: Icons.play_arrow_rounded,
                label: 'Старт',
                borderRadius: BorderRadius.circular(16),
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
            icon: Icons.edit_rounded,
            label: 'Править',
            borderRadius: BorderRadius.circular(16),
          ),
          SlidableAction(
            onPressed: (_) => _delete(),
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: 'Удалить',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Semantics(
        hint: 'Удерживайте, чтобы редактировать',
        child: GestureDetector(
          key: ValueKey('mobile-focus-quest-long-press-${task.id}'),
          behavior: HitTestBehavior.opaque,
          onLongPress: _edit,
          child: row,
        ),
      ),
    );
  }

  ActionToastOrigin _originFor(
    BuildContext context,
    ActionToastOriginKind kind,
  ) {
    return actionToastOriginForContext(
      context,
      kind: kind,
      zone: ActionToastZone.mobileContent,
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

class _MobileQuestCopy extends StatelessWidget {
  final Task task;
  final Color titleColor;
  final Color descriptionColor;

  const _MobileQuestCopy({
    required this.task,
    required this.titleColor,
    required this.descriptionColor,
  });

  @override
  Widget build(BuildContext context) {
    final description = task.description.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: TextStyle(
            color: titleColor,
            fontSize: 15.5,
            height: 1.2,
            fontWeight: FontWeight.w800,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            decorationColor: descriptionColor,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: descriptionColor,
              fontSize: 12.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
