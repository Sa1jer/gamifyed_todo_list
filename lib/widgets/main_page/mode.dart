part of '../main_page.dart';

enum WorkspaceMode { act, mastery, rewards, stats, settings }

const _primaryWorkspaceModes = [WorkspaceMode.act, WorkspaceMode.mastery];

extension _WorkspaceModeMeta on WorkspaceMode {
  String get label => switch (this) {
    WorkspaceMode.act => 'Действовать',
    WorkspaceMode.mastery => 'Карта',
    WorkspaceMode.rewards => 'Трофеи',
    WorkspaceMode.stats => 'Статистика',
    WorkspaceMode.settings => 'Настройки',
  };

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

  Color get color => switch (this) {
    WorkspaceMode.act => const Color(0xFFFF9500),
    WorkspaceMode.mastery => const Color(0xFF4A9EFF),
    WorkspaceMode.rewards => const Color(0xFFFFCC00),
    WorkspaceMode.stats => const Color(0xFF34C759),
    WorkspaceMode.settings => const Color(0xFF8E8E93),
  };
}
