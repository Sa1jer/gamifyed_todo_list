import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../utils.dart';
import '../widgets/shared.dart';
import 'debug_service.dart';

@visibleForTesting
DebugService? debugServiceOverride;

Future<void> showDebugAdminPanel(
  BuildContext context, {
  required AppState state,
}) {
  assert(kDebugMode, 'Debug Admin must not be used outside debug mode');
  final debugService = debugServiceOverride ?? DebugService();
  return showDialog<void>(
    context: context,
    builder: (_) => _DebugAdminPanel(state: state, debugService: debugService),
  );
}

class _DebugAdminPanel extends StatefulWidget {
  final AppState state;
  final DebugService debugService;

  const _DebugAdminPanel({required this.state, required this.debugService});

  @override
  State<_DebugAdminPanel> createState() => _DebugAdminPanelState();
}

class _DebugAdminPanelState extends State<_DebugAdminPanel> {
  late Future<DebugAdminDraftState> _draftFuture;

  @override
  void initState() {
    super.initState();
    _draftFuture = _loadDraft();
  }

  Future<DebugAdminDraftState> _loadDraft() async {
    await widget.debugService.init();
    return widget.debugService.loadDraftState();
  }

  Future<void> _confirmClearDebugState() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = widget.state.isDark;
        final txt = textColor(isDark);
        final sub = subtext(isDark);
        return AlertDialog(
          backgroundColor: surface(isDark),
          title: Text(
            'Очистить debug state?',
            style: TextStyle(color: txt, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Будет очищен только box ${DebugService.boxName}. Данные приложения и AppState не изменятся.',
            style: TextStyle(color: sub, fontWeight: FontWeight.w700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await widget.debugService.clear();
    if (!mounted) return;
    setState(() {
      _draftFuture = _loadDraft();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDark;
    final bg = surface(isDark);
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final border = borderColor(isDark);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withAlpha(22),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: const Color(0xFFFF9500).withAlpha(62),
                      ),
                    ),
                    child: const Icon(
                      Icons.bug_report_outlined,
                      color: Color(0xFFFF9500),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEBUG ADMIN',
                          style: TextStyle(
                            color: txt,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'State Simulator shell',
                          style: TextStyle(
                            color: sub,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PressFeedback(
                    scale: 0.92,
                    tooltip: 'Закрыть Debug Admin',
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: sub, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withAlpha(13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF9500).withAlpha(45),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF9500),
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Debug only. Инструменты симуляции состояния появятся в следующих фазах.',
                        style: TextStyle(
                          color: txt,
                          fontSize: 12.2,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FutureBuilder<DebugAdminDraftState>(
                future: _draftFuture,
                builder: (context, snapshot) {
                  final draft =
                      snapshot.data ?? const DebugAdminDraftState.empty();
                  return _DebugStorageStatusCard(
                    isDark: isDark,
                    isLoading: snapshot.connectionState != ConnectionState.done,
                    isInitialized: widget.debugService.isInitialized,
                    draft: draft,
                    onClear: _confirmClearDebugState,
                  );
                },
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _DebugAdminSection(
                      isDark: isDark,
                      icon: Icons.auto_fix_high_outlined,
                      title: 'Сценарии',
                      description:
                          'Fresh user, streak, trophies and load states.',
                    ),
                    _DebugAdminSection(
                      isDark: isDark,
                      icon: Icons.emoji_events_outlined,
                      title: 'Достижения',
                      description:
                          'Unlock, lock and inspect achievement state.',
                    ),
                    _DebugAdminSection(
                      isDark: isDark,
                      icon: Icons.person_outline,
                      title: 'Профиль',
                      description: 'Level, XP and profile test values.',
                    ),
                    _DebugAdminSection(
                      isDark: isDark,
                      icon: Icons.inventory_2_outlined,
                      title: 'Сундуки и эффекты',
                      description: 'Pending chests and active passive effects.',
                    ),
                    _DebugAdminSection(
                      isDark: isDark,
                      icon: Icons.shield_outlined,
                      title: 'Сопротивление',
                      description:
                          'Sample resistance events and defeated states.',
                    ),
                    _DebugAdminSection(
                      isDark: isDark,
                      icon: Icons.delete_outline,
                      title: 'Reset tools',
                      description:
                          'Dangerous reset actions will require confirmation.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: border),
              const SizedBox(height: 10),
              Text(
                'Debug persistence in 1.3.41 · no AppState mutations',
                style: TextStyle(
                  color: sub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugStorageStatusCard extends StatelessWidget {
  final bool isDark;
  final bool isLoading;
  final bool isInitialized;
  final DebugAdminDraftState draft;
  final VoidCallback onClear;

  const _DebugStorageStatusCard({
    required this.isDark,
    required this.isLoading,
    required this.isInitialized,
    required this.draft,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = const Color(0xFFFF9500);
    final updated = draft.updatedAt;
    final updatedLabel = updated == null
        ? 'черновик пуст'
        : 'обновлено ${formatDateTime(updated)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15151D) : const Color(0xFFF7F3EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withAlpha(isDark ? 58 : 72)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLoading ? Icons.hourglass_empty : Icons.storage_outlined,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug storage',
                  style: TextStyle(
                    color: txt,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${isInitialized ? 'box ${DebugService.boxName} подключён' : 'подключаем box ${DebugService.boxName}'} · ${draft.overrideCount} draft values · $updatedLabel',
                  style: TextStyle(
                    color: sub,
                    fontSize: 11.2,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: isLoading || draft.isEmpty ? null : onClear,
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}

class _DebugAdminSection extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String description;

  const _DebugAdminSection({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15151D) : const Color(0xFFF4F5FA),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Row(
        children: [
          Icon(icon, color: sub, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: sub,
                    fontSize: 11.2,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'скоро',
            style: TextStyle(
              color: sub,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
