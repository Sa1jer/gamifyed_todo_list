import 'package:flutter/material.dart';

import '../app_state.dart';
import 'mobile_journal_tokens.dart';
import 'mobile_secondary_page.dart';
import 'progress_workspace.dart';

class MobileStatisticsPage extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final Key? summaryTutorialKey;
  final ProgressWorkspaceDestinations destinations;

  const MobileStatisticsPage({
    super.key,
    required this.state,
    required this.isDark,
    this.summaryTutorialKey,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      state: state,
      child: Builder(
        builder: (routeContext) => MobileSecondaryPage(
          routeName: 'Статистика',
          backgroundColor: MobileJournalTokens.background(isDark),
          child: ProgressWorkspace(
            key: const ValueKey('stats-workspace'),
            state: state,
            isDark: isDark,
            summaryTutorialKey: summaryTutorialKey,
            onClose: () => Navigator.of(routeContext).maybePop(),
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
