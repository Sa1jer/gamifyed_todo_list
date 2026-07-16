import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../utils.dart';
import '../shared.dart';

class SkillTreeNodeInspector extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final SkillTreeNode? node;
  final bool isDark;
  final VoidCallback? onAddChild;
  final VoidCallback? onAddQuest;
  final VoidCallback? onMaster;
  final VoidCallback? onDelete;

  const SkillTreeNodeInspector({
    super.key,
    required this.state,
    required this.skill,
    required this.node,
    required this.isDark,
    required this.onAddChild,
    required this.onAddQuest,
    required this.onMaster,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final selectedNode = node;
    final bdr = borderColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111118) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      padding: const EdgeInsets.all(14),
      child: selectedNode == null
          ? _EmptyNodeInspector(
              isDark: isDark,
              color: skill.color,
              onAddRoot: onAddChild,
            )
          : _SelectedNodeInspector(
              state: state,
              skill: skill,
              node: selectedNode,
              isDark: isDark,
              onAddChild: onAddChild,
              onAddQuest: onAddQuest,
              onMaster: onMaster,
              onDelete: onDelete,
            ),
    );
  }
}

class _EmptyNodeInspector extends StatelessWidget {
  final bool isDark;
  final Color color;
  final VoidCallback? onAddRoot;

  const _EmptyNodeInspector({
    required this.isDark,
    required this.color,
    required this.onAddRoot,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.account_tree_outlined, color: color, size: 30),
        const SizedBox(height: 12),
        Text(
          'Выберите этап',
          style: TextStyle(
            color: textColor(isDark),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Этап — это ступень навыка. Создавайте квесты для этапа, выполняйте их и фиксируйте освоение.',
          style: TextStyle(
            color: subtext(isDark),
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
        const Spacer(),
        SmallBtn(
          label: 'Первый этап',
          icon: Icons.add,
          color: color,
          onTap: onAddRoot ?? () {},
        ),
      ],
    );
  }
}

class _SelectedNodeInspector extends StatelessWidget {
  final AppState state;
  final Skill skill;
  final SkillTreeNode node;
  final bool isDark;
  final VoidCallback? onAddChild;
  final VoidCallback? onAddQuest;
  final VoidCallback? onMaster;
  final VoidCallback? onDelete;

  const _SelectedNodeInspector({
    required this.state,
    required this.skill,
    required this.node,
    required this.isDark,
    required this.onAddChild,
    required this.onAddQuest,
    required this.onMaster,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final status = skill.treeNodeStatus(node);
    final statusColor = skillTreeNodeStatusColor[status]!;
    final linkedTasks = state.tasksForTreeNode(skill.id, node.id);
    final completed = state.completedTasksForTreeNode(skill.id, node.id);
    final target = node.questTarget;
    final ready = state.canMasterSkillTreeNode(skill.id, node.id);
    final parent = node.prerequisiteIds
        .map(
          (id) => skill.treeNodes
              .where((candidate) => candidate.id == id)
              .firstOrNull,
        )
        .whereType<SkillTreeNode>()
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(28),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor.withAlpha(120)),
              ),
              child: Icon(_statusIcon(status), color: statusColor, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: txt,
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TaskBadge(
                    label: skillTreeNodeStatusLabel[status]!,
                    color: statusColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (node.description.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            node.description,
            style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
          ),
        ],
        const SizedBox(height: 14),
        _NodeProgressPanel(
          isDark: isDark,
          color: statusColor,
          completed: completed,
          target: target,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            TaskBadge(
              icon: Icons.auto_awesome,
              label: '+${node.xpReward} XP',
              color: const Color(0xFFFFCC00),
            ),
            if (parent != null)
              TaskBadge(
                icon: Icons.lock_open,
                label: 'после: ${parent.title}',
                color: const Color(0xFF8E8E93),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Квесты этапа',
          style: TextStyle(
            color: txt,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: linkedTasks.isEmpty
              ? Center(
                  child: Text(
                    'Пока нет квестов.\nСоздайте квест, чтобы двинуть этап.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: linkedTasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (_, index) => _InspectorQuestRow(
                    task: linkedTasks[index],
                    isDark: isDark,
                    color: skill.color,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SmallBtn(
              label: 'Квест',
              icon: Icons.add_task,
              color: const Color(0xFF4A9EFF),
              onTap: onAddQuest ?? () {},
            ),
            SmallBtn(
              label: 'Следующий этап',
              icon: Icons.account_tree,
              color: skill.color,
              onTap: onAddChild ?? () {},
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MasterNodeButton(
                enabled: ready,
                mastered: node.isMastered,
                color: skill.color,
                onTap: onMaster ?? () {},
              ),
            ),
            const SizedBox(width: 10),
            PressFeedback(
              scale: 0.94,
              tooltip: 'Удалить этап',
              onTap: onDelete ?? () {},
              child: Icon(Icons.delete_outline, color: sub, size: 21),
            ),
          ],
        ),
      ],
    );
  }

  IconData _statusIcon(SkillTreeNodeStatus status) {
    return switch (status) {
      SkillTreeNodeStatus.locked => Icons.lock,
      SkillTreeNodeStatus.active => Icons.bolt_rounded,
      SkillTreeNodeStatus.mastered => Icons.workspace_premium,
    };
  }
}

class _NodeProgressPanel extends StatelessWidget {
  final bool isDark;
  final Color color;
  final int completed;
  final int target;

  const _NodeProgressPanel({
    required this.isDark,
    required this.color,
    required this.completed,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = math.min(completed, target);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Прогресс освоения',
                  style: TextStyle(
                    color: textColor(isDark),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$clamped/$target',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XPBar(
            progress: target == 0 ? 0 : (clamped / target).clamp(0.0, 1.0),
            color: color,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _InspectorQuestRow extends StatelessWidget {
  final Task task;
  final bool isDark;
  final Color color;

  const _InspectorQuestRow({
    required this.task,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        children: [
          Icon(
            task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isDone ? const Color(0xFF34C759) : color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: task.isDone ? sub : textColor(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                decoration: task.isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterNodeButton extends StatelessWidget {
  final bool enabled;
  final bool mastered;
  final Color color;
  final VoidCallback onTap;

  const _MasterNodeButton({
    required this.enabled,
    required this.mastered,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mastered) {
      return TaskBadge(
        icon: Icons.check_circle,
        label: 'Готово',
        color: const Color(0xFF34C759),
      );
    }

    final button = AnimatedOpacity(
      duration: kMotionStandard,
      curve: kMotionCurve,
      opacity: enabled ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Освоить',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    if (!enabled) return button;

    return PressFeedback(
      scale: 0.96,
      tooltip: 'Освоить этап карты мастерства',
      onTap: onTap,
      child: button,
    );
  }
}

class SkillTreeEmptyState extends StatelessWidget {
  final bool isDark;
  final Color color;
  final VoidCallback onAdd;

  const SkillTreeEmptyState({
    super.key,
    required this.isDark,
    required this.color,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtext(isDark);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined, color: sub, size: 42),
          const SizedBox(height: 12),
          Text(
            'Карта мастерства пока пустая',
            style: TextStyle(color: sub, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Начните с этапов: “Основы”, “Практика”, “Первый проект”.',
            style: TextStyle(color: sub.withAlpha(170), fontSize: 12),
          ),
          const SizedBox(height: 14),
          SmallBtn(
            label: 'Добавить этап',
            icon: Icons.add,
            color: color,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}
