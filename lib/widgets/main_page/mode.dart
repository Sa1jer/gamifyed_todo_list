part of '../main_page.dart';

enum WorkspaceMode { act, plan, mastery, stats }

const _primaryWorkspaceModes = [
  WorkspaceMode.act,
  WorkspaceMode.plan,
  WorkspaceMode.mastery,
];

extension _WorkspaceModeMeta on WorkspaceMode {
  String get label => switch (this) {
    WorkspaceMode.act => 'Действовать',
    WorkspaceMode.plan => 'Планировать',
    WorkspaceMode.mastery => 'Карта',
    WorkspaceMode.stats => 'Статистика',
  };

  String get shortLabel => switch (this) {
    WorkspaceMode.act => 'Сейчас',
    WorkspaceMode.plan => 'План',
    WorkspaceMode.mastery => 'Карта',
    WorkspaceMode.stats => 'Стат.',
  };

  IconData get icon => switch (this) {
    WorkspaceMode.act => Icons.flash_on,
    WorkspaceMode.plan => Icons.edit_note,
    WorkspaceMode.mastery => Icons.account_tree,
    WorkspaceMode.stats => Icons.query_stats,
  };

  Color get color => switch (this) {
    WorkspaceMode.act => const Color(0xFFFF9500),
    WorkspaceMode.plan => const Color(0xFF4A9EFF),
    WorkspaceMode.mastery => const Color(0xFF4A9EFF),
    WorkspaceMode.stats => const Color(0xFF34C759),
  };
}
