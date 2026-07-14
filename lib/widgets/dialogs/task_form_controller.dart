import 'package:flutter/material.dart';

/// Owns the editable resources used by the quest form.
///
/// Product state and save orchestration intentionally remain in the dialog;
/// this controller gives every text/focus resource one lifecycle owner.
class TaskFormController extends ChangeNotifier {
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController minimumAction;
  final TextEditingController customDays;
  final TextEditingController subtask;
  final FocusNode minimumActionFocusNode;

  TaskFormController({
    String titleText = '',
    String descriptionText = '',
    String minimumActionText = '',
    String customDaysText = '1',
  }) : title = TextEditingController(text: titleText),
       description = TextEditingController(text: descriptionText),
       minimumAction = TextEditingController(text: minimumActionText),
       customDays = TextEditingController(text: customDaysText),
       subtask = TextEditingController(),
       minimumActionFocusNode = FocusNode() {
    title.addListener(_notifyChanged);
    description.addListener(_notifyChanged);
    minimumAction.addListener(_notifyChanged);
    customDays.addListener(_notifyChanged);
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
