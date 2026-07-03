import 'package:flutter/material.dart';

import '../app_state.dart';
import '../feedback_service.dart';
import '../models.dart';
import '../utils.dart';
import 'shared.dart';

class InboxPanel extends StatefulWidget {
  final void Function(String taskId, Offset position) onComplete;
  final bool embedded;

  const InboxPanel({
    super.key,
    required this.onComplete,
    this.embedded = false,
  });

  @override
  State<InboxPanel> createState() => _InboxPanelState();
}

class _InboxPanelState extends State<InboxPanel> {
  final _titleCtrl = TextEditingController();
  final _fieldKey = GlobalKey();

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _addInboxTask(AppState state) {
    final created = state.addInboxTask(_titleCtrl.text);
    if (!created) return;
    _titleCtrl.clear();
    AppFeedback.selection();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isDark = state.isDark;
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = const Color(0xFF34C759);
    final active = state.inboxTasks.where((task) => !task.isDone).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final done = state.inboxTasks.where((task) => task.isDone).toList()
      ..sort(_compareInboxDoneNewestFirst);
    final compact = MediaQuery.sizeOf(context).width < 560;

    Widget quickAddField({required bool dense}) {
      return TextField(
        key: _fieldKey,
        controller: _titleCtrl,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _addInboxTask(state),
        style: TextStyle(color: txt, fontSize: 13, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Быстрая задача...',
          hintStyle: TextStyle(color: sub.withAlpha(170)),
          filled: true,
          fillColor: isDark
              ? Colors.white.withAlpha(8)
              : Colors.black.withAlpha(4),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: dense ? 8 : 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor(isDark)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor(isDark)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent.withAlpha(170)),
          ),
        ),
      );
    }

    final content = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 120) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(
                  Icons.inbox_rounded,
                  color: Color(0xFF34C759),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: quickAddField(dense: true)),
                const SizedBox(width: 6),
                IconButton.filled(
                  tooltip: 'Добавить в Задачник',
                  onPressed: () => _addInboxTask(state),
                  style: IconButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                ),
                const SizedBox(width: 4),
                InboxTaskCountBubble(
                  key: const ValueKey('inbox-active-count'),
                  count: active.length,
                  color: accent,
                  isDark: isDark,
                  size: 24,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(12, compact ? 10 : 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withAlpha(isDark ? 28 : 20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withAlpha(70)),
                    ),
                    child: const Icon(
                      Icons.inbox_rounded,
                      color: Color(0xFF34C759),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Задачник',
                          style: TextStyle(
                            color: txt,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Быстрые действия · +${AppState.inboxTaskXp} XP · без RoadMap',
                          style: TextStyle(
                            color: sub,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InboxTaskCountBubble(
                    key: const ValueKey('inbox-active-count'),
                    count: active.length,
                    color: accent,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: quickAddField(dense: false)),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _addInboxTask(state),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: Text(compact ? 'OK' : 'Быстрая задача'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: MotionFadeSlideSwitcher(
                  child: active.isEmpty && done.isEmpty
                      ? Align(
                          key: const ValueKey('inbox-empty'),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Сюда можно бросить бытовые To-do, не смешивая их с навыками.',
                            style: TextStyle(color: sub, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : ListView(
                          key: const ValueKey('inbox-list'),
                          padding: EdgeInsets.zero,
                          children: [
                            ...active.map(
                              (task) => _InboxTaskRow(
                                key: ValueKey('inbox-active-${task.id}'),
                                task: task,
                                isDark: isDark,
                                color: accent,
                                onComplete: widget.onComplete,
                                onUndo: () => state.uncompleteTask(task.id),
                                onDelete: () => state.removeTask(task.id),
                              ),
                            ),
                            if (done.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 2,
                                ),
                                child: Text(
                                  'Готово (${done.length})',
                                  style: TextStyle(
                                    color: sub,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ...done.map(
                              (task) => _InboxTaskRow(
                                key: ValueKey('inbox-done-${task.id}'),
                                task: task,
                                isDark: isDark,
                                color: accent,
                                onComplete: widget.onComplete,
                                onUndo: () => state.uncompleteTask(task.id),
                                onDelete: () => state.removeTask(task.id),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (widget.embedded) {
      return Container(
        key: const ValueKey('mobile-inbox-focus'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withAlpha(isDark ? 17 : 10), surface(isDark)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: content,
      );
    }
    return AppPanel(isDark: isDark, child: content);
  }
}

class _InboxTaskRow extends StatelessWidget {
  final Task task;
  final bool isDark;
  final Color color;
  final void Function(String taskId, Offset position) onComplete;
  final VoidCallback onUndo;
  final VoidCallback onDelete;

  const _InboxTaskRow({
    super.key,
    required this.task,
    required this.isDark,
    required this.color,
    required this.onComplete,
    required this.onUndo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(7) : Colors.black.withAlpha(3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor(isDark).withAlpha(160)),
      ),
      child: Row(
        children: [
          PressFeedback(
            scale: 0.94,
            tooltip: task.isDone ? 'Вернуть в Задачник' : 'Закрыть задачу',
            onTap: () {
              if (task.isDone) {
                onUndo();
              } else {
                final box = context.findRenderObject();
                final pos = box is RenderBox
                    ? box.localToGlobal(box.size.center(Offset.zero))
                    : Offset.zero;
                onComplete(task.id, pos);
              }
            },
            child: AnimatedContainer(
              duration: kMotionStandard,
              curve: kMotionCurve,
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isDone ? color : Colors.transparent,
                border: Border.all(
                  color: task.isDone ? color : sub.withAlpha(150),
                  width: 2,
                ),
              ),
              child: task.isDone
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                color: task.isDone ? sub : txt,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                decorationColor: sub,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          XpRewardPill(
            key: ValueKey('inbox-xp-${task.id}'),
            xp: AppState.inboxTaskXp,
            isDark: isDark,
          ),
          IconButton(
            tooltip: 'Удалить из Задачника',
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, color: sub, size: 17),
          ),
        ],
      ),
    );
  }
}

int _compareInboxDoneNewestFirst(Task a, Task b) {
  final aDate = a.lastCompletedAt ?? a.updatedAt;
  final bDate = b.lastCompletedAt ?? b.updatedAt;
  final byDone = bDate.compareTo(aDate);
  if (byDone != 0) return byDone;
  return b.createdAt.compareTo(a.createdAt);
}
