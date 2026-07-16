import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../utils.dart';
import '../desktop_journal_tokens.dart';
import '../dialogs.dart';

class DesktopCompactButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DesktopCompactButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(40, 34),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: 0.35)),
        ),
      ),
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class DesktopInteractiveSurface extends StatefulWidget {
  final double borderRadius;
  final Color baseColor;
  final Color hoverColor;
  final Color borderColor;
  final VoidCallback onTap;
  final Widget child;

  const DesktopInteractiveSurface({
    super.key,
    required this.borderRadius,
    required this.baseColor,
    required this.hoverColor,
    required this.borderColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<DesktopInteractiveSurface> createState() =>
      _DesktopInteractiveSurfaceState();
}

class _DesktopInteractiveSurfaceState extends State<DesktopInteractiveSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: AnimatedContainer(
            duration: DesktopJournalTokens.fastMotion,
            curve: DesktopJournalTokens.motionCurve,
            decoration: BoxDecoration(
              color: _hovered ? widget.hoverColor : widget.baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: widget.borderColor),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

void showDesktopAddTask(BuildContext context, AppState state, Skill skill) {
  showAdaptiveCreationForm<void>(
    context: context,
    builder: (_, fullScreen) => AddTaskDialog(
      isDark: state.isDark,
      fullScreen: fullScreen,
      skillColor: skill.color,
      skill: skill,
      onSave:
          (
            title,
            description,
            xp,
            type,
            frequency,
            customDays,
            priority,
            minimumAction,
            subtasks,
            tags,
            notificationsEnabled,
            notificationHour,
            notificationMinute,
            treeNodeId,
          ) => state.addTask(
            Task(
              id: uid(),
              title: title,
              description: description,
              skillId: skill.id,
              xpReward: xp,
              type: type,
              repeatFrequency: frequency,
              repeatCustomDays: customDays,
              priority: priority,
              minimumAction: minimumAction,
              subtasks: subtasks,
              tags: tags,
              treeNodeId: treeNodeId,
              notificationsEnabled: notificationsEnabled,
              notificationHour: notificationHour,
              notificationMinute: notificationMinute,
            ),
          ),
    ),
  );
}

void showDesktopEditTask(
  BuildContext context,
  AppState state,
  Skill skill,
  Task task,
) {
  showAdaptiveCreationForm<void>(
    context: context,
    builder: (_, fullScreen) => AddTaskDialog(
      isDark: state.isDark,
      fullScreen: fullScreen,
      skillColor: skill.color,
      skill: skill,
      existing: task,
      onSave:
          (
            title,
            description,
            xp,
            type,
            frequency,
            customDays,
            priority,
            minimumAction,
            subtasks,
            tags,
            notificationsEnabled,
            notificationHour,
            notificationMinute,
            treeNodeId,
          ) => state.updateTask(
            task,
            title: title,
            description: description,
            xpReward: xp,
            type: type,
            repeatFrequency: frequency,
            repeatCustomDays: customDays,
            priority: priority,
            minimumAction: minimumAction,
            subtasks: subtasks,
            tags: tags,
            notificationsEnabled: notificationsEnabled,
            notificationHour: notificationHour,
            notificationMinute: notificationMinute,
            treeNodeId: treeNodeId,
          ),
    ),
  );
}

void showDesktopEditSkill(BuildContext context, AppState state, Skill skill) {
  showDialog<void>(
    context: context,
    builder: (_) => AddSkillDialog(
      isDark: state.isDark,
      existing: skill,
      onSave: (name, goal, checklist, color, icon, _, _) => state.updateSkill(
        skill,
        name: name,
        goal: goal,
        checklist: checklist,
        color: color,
        icon: icon,
      ),
    ),
  );
}

void showDesktopDeleteSkill(BuildContext context, AppState state, Skill skill) {
  final tokens = DesktopJournalTokens.resolve(state.isDark);
  final taskCount = state.tasksForSkill(skill.id).length;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: tokens.raisedSurface,
      title: Text('Удалить навык?', style: TextStyle(color: tokens.text)),
      content: Text(
        '«${skill.name}» и $taskCount связанных квестов будут удалены.',
        style: TextStyle(color: tokens.mutedText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            state.removeSkill(skill.id);
            Navigator.pop(dialogContext);
          },
          style: TextButton.styleFrom(foregroundColor: tokens.danger),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
}
