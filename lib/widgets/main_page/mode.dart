part of '../main_page.dart';

enum WorkspaceMode { act, plan, mastery, progress }

extension _WorkspaceModeMeta on WorkspaceMode {
  String get label => switch (this) {
    WorkspaceMode.act => 'Действовать',
    WorkspaceMode.plan => 'Планировать',
    WorkspaceMode.mastery => 'Карта',
    WorkspaceMode.progress => 'Прогресс',
  };

  String get shortLabel => switch (this) {
    WorkspaceMode.act => 'Сейчас',
    WorkspaceMode.plan => 'План',
    WorkspaceMode.mastery => 'Карта',
    WorkspaceMode.progress => 'Рост',
  };

  IconData get icon => switch (this) {
    WorkspaceMode.act => Icons.flash_on,
    WorkspaceMode.plan => Icons.edit_note,
    WorkspaceMode.mastery => Icons.account_tree,
    WorkspaceMode.progress => Icons.dashboard_customize,
  };

  Color get color => switch (this) {
    WorkspaceMode.act => const Color(0xFFFF9500),
    WorkspaceMode.plan => const Color(0xFF4A9EFF),
    WorkspaceMode.mastery => const Color(0xFF4A9EFF),
    WorkspaceMode.progress => const Color(0xFF34C759),
  };
}
