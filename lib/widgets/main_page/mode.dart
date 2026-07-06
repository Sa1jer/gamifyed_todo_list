part of '../main_page.dart';

enum WorkspaceMode { act, mastery, rewards, stats, settings }

const _primaryWorkspaceModes = [WorkspaceMode.act, WorkspaceMode.mastery];

extension _WorkspaceModeMeta on WorkspaceMode {
  String get shortLabel => switch (this) {
    WorkspaceMode.act => 'Сейчас',
    WorkspaceMode.mastery => 'Карта',
    WorkspaceMode.rewards => 'Трофеи',
    WorkspaceMode.stats => 'Стат.',
    WorkspaceMode.settings => 'Настр.',
  };

  IconData get icon => switch (this) {
    WorkspaceMode.act => Icons.flash_on,
    WorkspaceMode.mastery => Icons.account_tree,
    WorkspaceMode.rewards => Icons.emoji_events_outlined,
    WorkspaceMode.stats => Icons.query_stats,
    WorkspaceMode.settings => Icons.settings_outlined,
  };
}
