import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../engines/course_nudge_engine.dart';
import '../../models.dart';
import '../../utils.dart';
import '../dialogs.dart';
import '../weekly_review_card.dart';

void showProgressGoalReviewSheet(
  BuildContext context,
  AppState state,
  bool isDark,
  Skill skill,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 14,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface(isDark),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor(isDark)),
            ),
            child: WeeklyReviewCard(
              state: state,
              isDark: isDark,
              skill: skill,
              initiallyExpanded: true,
              showSavedNudge: true,
              buildNudgeForSkill: (skill) =>
                  visibleCourseNudgeForSkill(state, skill),
              onApplyNudge: (nudge) =>
                  handleCourseNudge(context, state, isDark, nudge),
              onDismissNudge: (nudge) => state.dismissCourseNudge(nudge.key),
            ),
          ),
        ),
      );
    },
  );
}

CourseNudge? visiblePrimaryCourseNudge(AppState state) {
  final nudge = const CourseNudgeEngine().suggestPrimary(
    state.skills,
    state.tasks,
  );
  if (nudge == null || state.isCourseNudgeDismissed(nudge.key)) return null;
  return nudge;
}

CourseNudge? visibleCourseNudgeForSkill(AppState state, Skill skill) {
  final nudge = const CourseNudgeEngine().suggestForSkill(skill, state.tasks);
  if (nudge == null || state.isCourseNudgeDismissed(nudge.key)) return null;
  return nudge;
}

void handleCourseNudge(
  BuildContext context,
  AppState state,
  bool isDark,
  CourseNudge nudge,
) {
  switch (nudge.kind) {
    case CourseNudgeKind.addMinimumToTask:
      final task = nudge.task;
      if (task == null) return;
      _showTaskDialogForNudge(
        context,
        state,
        skill: nudge.skill,
        existing: task,
        focusMinimumAction: true,
      );
    case CourseNudgeKind.createStageQuest:
    case CourseNudgeKind.createFocusQuest:
      _showTaskDialogForNudge(
        context,
        state,
        skill: nudge.skill,
        initialTreeNodeId: nudge.stage?.id,
        initialTitle: nudge.initialTitle,
        initialMinimumAction: nudge.initialMinimumAction,
        focusMinimumAction: nudge.initialMinimumAction?.isNotEmpty ?? false,
      );
    case CourseNudgeKind.clarifyFocus:
      showProgressGoalReviewSheet(context, state, isDark, nudge.skill);
    case CourseNudgeKind.clarifyGoal:
      _showSkillGoalDialogForNudge(context, state, nudge.skill);
  }
}

void _showTaskDialogForNudge(
  BuildContext context,
  AppState state, {
  required Skill skill,
  Task? existing,
  String? initialTreeNodeId,
  String? initialTitle,
  String? initialMinimumAction,
  bool focusMinimumAction = false,
}) {
  Widget buildForm(bool fullScreen) => AddTaskDialog(
    isDark: state.isDark,
    fullScreen: fullScreen,
    skillColor: skill.color,
    skill: skill,
    existing: existing,
    initialTreeNodeId: initialTreeNodeId,
    initialTitle: initialTitle,
    initialMinimumAction: initialMinimumAction,
    focusMinimumAction: focusMinimumAction,
    onSave:
        (
          title,
          description,
          xp,
          type,
          freq,
          customDays,
          priority,
          minimumAction,
          subtasks,
          tags,
          notificationsEnabled,
          notificationHour,
          notificationMinute,
          treeNodeId,
        ) {
          if (existing == null) {
            state.addTask(
              Task(
                id: uid(),
                title: title,
                description: description,
                skillId: skill.id,
                xpReward: xp,
                type: type,
                repeatFrequency: freq,
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
            );
          } else {
            state.updateTask(
              existing,
              title: title,
              description: description,
              xpReward: xp,
              type: type,
              repeatFrequency: freq,
              repeatCustomDays: customDays,
              priority: priority,
              minimumAction: minimumAction,
              subtasks: subtasks,
              tags: tags,
              notificationsEnabled: notificationsEnabled,
              notificationHour: notificationHour,
              notificationMinute: notificationMinute,
              treeNodeId: treeNodeId,
            );
          }
        },
  );

  if (existing == null) {
    showAdaptiveCreationForm<void>(
      context: context,
      builder: (_, fullScreen) => buildForm(fullScreen),
    );
  } else {
    showDialog<void>(context: context, builder: (_) => buildForm(false));
  }
}

void _showSkillGoalDialogForNudge(
  BuildContext context,
  AppState state,
  Skill skill,
) {
  showDialog(
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
