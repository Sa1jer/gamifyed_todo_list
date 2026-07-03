import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../app_state.dart';
import '../feedback_service.dart';
import '../models.dart';
import '../utils.dart';
import 'reward_animations.dart';
import 'shared.dart';
import 'mobile_journal_tokens.dart';

part 'dialogs/achievements_history.dart';
part 'dialogs/shared_controls.dart';
part 'dialogs/skill_dialogs.dart';
part 'dialogs/skill_tree_dialogs.dart';
part 'dialogs/task_dialog.dart';
part 'dialogs/stats_calendar_dialogs.dart';
part 'dialogs/rewards_bosses_dialogs.dart';

const double kMobileFormBreakpoint = 760;

typedef AdaptiveCreationFormBuilder =
    Widget Function(BuildContext context, bool fullScreen);

Future<T?> showAdaptiveCreationForm<T>({
  required BuildContext context,
  required AdaptiveCreationFormBuilder builder,
}) {
  final useFullScreen = MobileResponsiveMetrics.isMobileWidth(
    MediaQuery.sizeOf(context).width,
  );
  if (useFullScreen) {
    return Navigator.of(context, rootNavigator: true).push<T>(
      MaterialPageRoute<T>(
        fullscreenDialog: true,
        builder: (routeContext) => builder(routeContext, true),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => builder(dialogContext, false),
  );
}
