part of '../main_page.dart';

enum WorkspaceMode { act, mastery, stats }

const _primaryWorkspaceModes = [WorkspaceMode.act, WorkspaceMode.mastery];

extension _WorkspaceModeMeta on WorkspaceMode {
  String get label => switch (this) {
    WorkspaceMode.act => 'Действовать',
    WorkspaceMode.mastery => 'Карта',
    WorkspaceMode.stats => 'Статистика',
  };

  String get shortLabel => switch (this) {
    WorkspaceMode.act => 'Сейчас',
    WorkspaceMode.mastery => 'Карта',
    WorkspaceMode.stats => 'Стат.',
  };

  IconData get icon => switch (this) {
    WorkspaceMode.act => Icons.flash_on,
    WorkspaceMode.mastery => Icons.account_tree,
    WorkspaceMode.stats => Icons.query_stats,
  };

  Color get color => switch (this) {
    WorkspaceMode.act => const Color(0xFFFF9500),
    WorkspaceMode.mastery => const Color(0xFF4A9EFF),
    WorkspaceMode.stats => const Color(0xFF34C759),
  };
}
