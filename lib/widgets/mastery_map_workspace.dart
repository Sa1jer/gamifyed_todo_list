// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../engines/roadmap_engine.dart';
import '../engines/goal_progress_engine.dart';
import '../feedback_service.dart';
import '../models.dart';
import '../presentation/mobile_roadmap_ascent_layout.dart';
import '../presentation/roadmap_vertical_geometry.dart';
import '../theme/app_typography.dart';
import '../utils.dart';
import 'desktop_journal_tokens.dart';
import 'dialogs.dart';
import 'shared.dart';
import 'skill_goal_progress.dart';
import 'mobile_journal_tokens.dart';
import 'mastery_map/quest_practice_section.dart';
import 'mastery_map/visual_tokens.dart';

part 'mastery_map/selection_models.dart';
part 'mastery_map/workspace_shell.dart';
part 'mastery_map/body_shell.dart';
part 'mastery_map/canvas.dart';
part 'mastery_map/canvas_geometry.dart';
part 'mastery_map/painters.dart';
part 'mastery_map/orbs.dart';
part 'mastery_map/template_panel.dart';
part 'mastery_map/mobile_panels.dart';
part 'mastery_map/mobile_path_view.dart';
part 'mastery_map/inspector.dart';
part 'mastery_map/structure_editor.dart';

@visibleForTesting
Map<String, Offset> debugRoadmapConnectorNodePositions(CustomPainter? painter) {
  if (painter is! _OrbMasteryMapPainter) return const {};
  return Map.unmodifiable(painter.layout.nodePositions);
}

@visibleForTesting
Offset? debugRoadmapConnectorSkillPosition(CustomPainter? painter) {
  if (painter is! _OrbMasteryMapPainter) return null;
  final skill = painter.layout.selectedSkill;
  return skill == null ? null : painter.layout.skillPositions[skill];
}
