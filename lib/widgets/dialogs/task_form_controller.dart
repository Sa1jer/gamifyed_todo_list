import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models.dart';
import '../../utils.dart';

/// Owns the editable resources used by the quest form.
///
/// The controller owns the complete editable draft and all disposable input
/// resources. Navigation and the final AppState mutation remain in the dialog.
class TaskFormController extends ChangeNotifier {
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController minimumAction;
  final TextEditingController customDays;
  final TextEditingController subtask;
  final FocusNode minimumActionFocusNode;
  int xp;
  TaskType type;
  RepeatFrequency frequency;
  Priority priority;
  final List<String> subtasks;
  final List<String> tags;
  String? treeNodeId;
  bool minimumActionEnabled;
  bool notificationsEnabled;
  TimeOfDay notificationTime;
  bool advancedExpanded;
  bool subtasksExpanded;
  late final String _initialDraftSignature;

  TaskFormController({
    Task? existing,
    String? initialTitle,
    String? initialMinimumAction,
    String? initialTreeNodeId,
    bool focusMinimumAction = false,
  }) : title = TextEditingController(
         text: existing?.title ?? initialTitle?.trim() ?? '',
       ),
       description = TextEditingController(text: existing?.description ?? ''),
       minimumAction = TextEditingController(
         text: existing?.minimumAction ?? initialMinimumAction?.trim() ?? '',
       ),
       customDays = TextEditingController(
         text: '${(existing?.repeatCustomDays ?? 1).clamp(1, 9999)}',
       ),
       subtask = TextEditingController(),
       minimumActionFocusNode = FocusNode(),
       xp = existing?.xpReward ?? 20,
       type = existing?.type ?? TaskType.shortTerm,
       frequency = existing?.repeatFrequency ?? RepeatFrequency.daily,
       priority = existing?.priority ?? Priority.medium,
       subtasks = List.of(existing?.subtasks ?? const <String>[]),
       tags = List.of(existing?.tags ?? const <String>[]),
       treeNodeId = existing?.treeNodeId ?? initialTreeNodeId,
       minimumActionEnabled =
           (existing?.minimumAction.trim().isNotEmpty ?? false) ||
           (initialMinimumAction?.trim().isNotEmpty ?? false) ||
           focusMinimumAction,
       notificationsEnabled = existing?.notificationsEnabled ?? false,
       notificationTime = TimeOfDay(
         hour: existing?.notificationHour ?? 9,
         minute: existing?.notificationMinute ?? 0,
       ),
       advancedExpanded =
           (existing?.subtasks.isNotEmpty ?? false) ||
           existing?.treeNodeId != null ||
           (existing?.minimumAction.trim().isNotEmpty ?? false) ||
           (initialMinimumAction?.trim().isNotEmpty ?? false) ||
           focusMinimumAction,
       subtasksExpanded = existing?.subtasks.isNotEmpty ?? false {
    title.addListener(_notifyChanged);
    description.addListener(_notifyChanged);
    minimumAction.addListener(_notifyChanged);
    customDays.addListener(_notifyChanged);
    _initialDraftSignature = draftSignature;
  }

  String get draftSignature => jsonEncode({
    'title': title.text,
    'description': description.text,
    'minimumAction': minimumAction.text,
    'minimumEnabled': minimumActionEnabled,
    'xp': xp,
    'type': type.name,
    'frequency': frequency.name,
    'customDays': customDays.text,
    'priority': priority.name,
    'subtasks': subtasks,
    'tags': tags,
    'treeNodeId': treeNodeId,
    'notificationsEnabled': notificationsEnabled,
    'notificationHour': notificationTime.hour,
    'notificationMinute': notificationTime.minute,
  });

  bool get isDirty => draftSignature != _initialDraftSignature;

  int get softCap => typeSoftCap[type]!;

  bool get isOverSoftCap => xp > softCap;

  bool get showBigQuestTools =>
      type == TaskType.midTerm ||
      type == TaskType.longTerm ||
      subtasks.isNotEmpty;

  int get xpSelectorValue => normalizeXp(xp);

  int normalizeXp(int value) {
    final clamped = value.clamp(10, 500);
    return (((clamped + 5) ~/ 10) * 10).clamp(10, 500);
  }

  int get customDayCount {
    final parsed = int.tryParse(customDays.text.trim()) ?? 1;
    return parsed < 1 ? 1 : parsed;
  }

  void _notifyChanged() => notifyListeners();

  @override
  void dispose() {
    title.removeListener(_notifyChanged);
    description.removeListener(_notifyChanged);
    minimumAction.removeListener(_notifyChanged);
    customDays.removeListener(_notifyChanged);
    title.dispose();
    description.dispose();
    minimumAction.dispose();
    customDays.dispose();
    subtask.dispose();
    minimumActionFocusNode.dispose();
    super.dispose();
  }
}
