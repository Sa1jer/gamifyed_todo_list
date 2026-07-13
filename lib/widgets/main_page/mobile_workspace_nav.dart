part of '../main_page.dart';

class _MobileWorkspaceNav extends StatelessWidget {
  final WorkspaceMode mode;
  final bool isDark;
  final bool reducedMotion;
  final ValueChanged<WorkspaceMode> onChanged;
  final VoidCallback? onReselectCurrent;
  final Key? roadmapKey;

  const _MobileWorkspaceNav({
    required this.mode,
    required this.isDark,
    required this.reducedMotion,
    required this.onChanged,
    this.onReselectCurrent,
    this.roadmapKey,
  });

  @override
  Widget build(BuildContext context) {
    final bdr = _MobileJournalTokens.outline(isDark);
    final sub = _MobileJournalTokens.muted(isDark);
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('mobile-workspace-nav'),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: _MobileJournalTokens.surfaceColor(isDark),
          border: Border(top: BorderSide(color: bdr)),
        ),
        child: Row(
          children: [
            for (final item in _primaryWorkspaceModes)
              Expanded(
                child: KeyedSubtree(
                  key: item == WorkspaceMode.mastery ? roadmapKey : null,
                  child: Semantics(
                    button: true,
                    selected: item == mode,
                    label: 'Раздел ${item.shortLabel}',
                    child: PressFeedback(
                      scale: 0.96,
                      onTap: () {
                        if (item == mode) {
                          onReselectCurrent?.call();
                          return;
                        }
                        onChanged(item);
                      },
                      child: Center(
                        child: AnimatedContainer(
                          duration: MobileMotion.duration(
                            context,
                            appReducedMotion: reducedMotion,
                          ),
                          curve: _MobileJournalTokens.curve,
                          constraints: const BoxConstraints(
                            minWidth: 112,
                            minHeight: 54,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: item == mode
                                ? (item == WorkspaceMode.act
                                          ? _MobileJournalTokens.amber
                                          : _MobileJournalTokens.violet)
                                      .withAlpha(isDark ? 40 : 28)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                color: item == mode
                                    ? item == WorkspaceMode.act
                                          ? _MobileJournalTokens.amber
                                          : _MobileJournalTokens.violet
                                    : sub,
                                size: 19,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.shortLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: item == mode
                                      ? item == WorkspaceMode.act
                                            ? _MobileJournalTokens.amber
                                            : _MobileJournalTokens.violet
                                      : sub,
                                  fontSize: 11,
                                  fontWeight: item == mode
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
