import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import '../widgets/shared.dart';
import 'debug_admin_controller.dart';
import 'debug_scenarios.dart';
import 'debug_service.dart';

@visibleForTesting
DebugService? debugServiceOverride;

Future<void> showDebugAdminPanel(
  BuildContext context, {
  required AppState state,
}) {
  if (!kDebugMode) {
    throw StateError('Debug Admin must not be used outside debug mode.');
  }
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
    final controller = DebugAdminController(
      state: widget.state,
      debugService: widget.debugService,
    );
    await controller.clearDebugDraftState();
    if (!mounted) return;
    setState(() {
      _draftFuture = _loadDraft();
    });
  }

  Future<void> _confirmApplyScenario(DebugScenarioDef scenario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = widget.state.isDark;
        final txt = textColor(isDark);
        final sub = subtext(isDark);
        final isOverwrite =
            scenario.dangerLevel == DebugScenarioDanger.overwrite;
        return AlertDialog(
          backgroundColor: surface(isDark),
          title: Text(
            'Применить сценарий?',
            style: TextStyle(color: txt, fontWeight: FontWeight.w900),
          ),
          content: Text(
            isOverwrite
                ? '«${scenario.title}» перезапишет часть текущего состояния приложения. Это debug-only действие.'
                : '«${scenario.title}» добавит или изменит тестовое состояние приложения. Это debug-only действие.',
            style: TextStyle(color: sub, fontWeight: FontWeight.w700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Применить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final controller = DebugAdminController(
      state: widget.state,
      debugService: widget.debugService,
    );
    await controller.applyScenario(scenario);
    if (!mounted) return;
    setState(() {
      _draftFuture = _loadDraft();
    });
  }

  Future<void> _confirmSetAllAchievements(bool unlocked) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = widget.state.isDark;
        final txt = textColor(isDark);
        final sub = subtext(isDark);
        return AlertDialog(
          backgroundColor: surface(isDark),
          title: Text(
            unlocked ? 'Unlock all achievements?' : 'Lock all achievements?',
            style: TextStyle(color: txt, fontWeight: FontWeight.w900),
          ),
          content: Text(
            unlocked
                ? 'Все достижения будут открыты в текущем debug-состоянии приложения.'
                : 'Все достижения будут закрыты в текущем debug-состоянии приложения.',
            style: TextStyle(color: sub, fontWeight: FontWeight.w700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(unlocked ? 'Unlock all' : 'Lock all'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final controller = DebugAdminController(
      state: widget.state,
      debugService: widget.debugService,
    );
    await controller.setAllAchievementsUnlocked(unlocked);
    if (!mounted) return;
    setState(() {
      _draftFuture = _loadDraft();
    });
  }

  Future<void> _setAchievementUnlocked(String id, bool unlocked) async {
    final controller = DebugAdminController(
      state: widget.state,
      debugService: widget.debugService,
    );
    await controller.setAchievementUnlocked(id, unlocked);
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
                          'State Simulator',
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
                        'Debug only. Сценарии ниже меняют состояние приложения только в debug-сборке.',
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
                    _DebugScenariosSection(
                      isDark: isDark,
                      scenarios: debugScenarios,
                      onApplyScenario: _confirmApplyScenario,
                    ),
                    _DebugAchievementsSection(
                      isDark: isDark,
                      achievements: widget.state.achievements,
                      onSetAll: _confirmSetAllAchievements,
                      onToggleAchievement: _setAchievementUnlocked,
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
                'State simulator in 1.3.42 · debug-only mutations',
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

class _DebugScenariosSection extends StatelessWidget {
  final bool isDark;
  final List<DebugScenarioDef> scenarios;
  final ValueChanged<DebugScenarioDef> onApplyScenario;

  const _DebugScenariosSection({
    required this.isDark,
    required this.scenarios,
    required this.onApplyScenario,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15151D) : const Color(0xFFF4F5FA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_outlined, color: sub, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Сценарии',
                  style: TextStyle(
                    color: txt,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${scenarios.length}',
                style: TextStyle(
                  color: sub,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Быстро собрать состояние для QA. Каждое применение требует подтверждения.',
            style: TextStyle(
              color: sub,
              fontSize: 11.2,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final scenario in scenarios)
            _DebugScenarioCard(
              isDark: isDark,
              scenario: scenario,
              onTap: () => onApplyScenario(scenario),
            ),
        ],
      ),
    );
  }
}

class _DebugScenarioCard extends StatelessWidget {
  final bool isDark;
  final DebugScenarioDef scenario;
  final VoidCallback onTap;

  const _DebugScenarioCard({
    required this.isDark,
    required this.scenario,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final isOverwrite = scenario.dangerLevel == DebugScenarioDanger.overwrite;
    final accent = isOverwrite
        ? const Color(0xFFFF9500)
        : const Color(0xFF4A9EFF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressFeedback(
        scale: 0.985,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: accent.withAlpha(isDark ? 18 : 12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withAlpha(isDark ? 56 : 48)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isOverwrite
                    ? Icons.warning_amber_rounded
                    : Icons.play_circle_outline,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.title,
                      style: TextStyle(
                        color: txt,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scenario.description,
                      style: TextStyle(
                        color: sub,
                        fontSize: 10.9,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOverwrite ? 'overwrite' : 'add',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugAchievementsSection extends StatelessWidget {
  final bool isDark;
  final List<Achievement> achievements;
  final ValueChanged<bool> onSetAll;
  final void Function(String id, bool unlocked) onToggleAchievement;

  const _DebugAchievementsSection({
    required this.isDark,
    required this.achievements,
    required this.onSetAll,
    required this.onToggleAchievement,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final unlockedCount = achievementDefinitions.where(_isUnlocked).length;
    final totalCount = achievementDefinitions.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15151D) : const Color(0xFFF4F5FA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: sub, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Достижения',
                  style: TextStyle(
                    color: txt,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$unlockedCount / $totalCount',
                style: TextStyle(
                  color: const Color(0xFFFF9500),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Открыть, закрыть или проверить отдельные achievement states.',
            style: TextStyle(
              color: sub,
              fontSize: 11.2,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('debug-achievements-unlock-all'),
                  onPressed: () => onSetAll(true),
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: const Text('Unlock all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('debug-achievements-lock-all'),
                  onPressed: () => onSetAll(false),
                  icon: const Icon(Icons.lock_outline_rounded, size: 16),
                  label: const Text('Lock all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final definition in achievementDefinitions)
            _DebugAchievementRow(
              isDark: isDark,
              definition: definition,
              isUnlocked: _isUnlocked(definition),
              onChanged: (value) => onToggleAchievement(definition.id, value),
            ),
        ],
      ),
    );
  }

  bool _isUnlocked(AchievementDef definition) {
    for (final achievement in achievements) {
      if (achievement.id == definition.id) return achievement.isUnlocked;
    }
    return false;
  }
}

class _DebugAchievementRow extends StatelessWidget {
  final bool isDark;
  final AchievementDef definition;
  final bool isUnlocked;
  final ValueChanged<bool> onChanged;

  const _DebugAchievementRow({
    required this.isDark,
    required this.definition,
    required this.isUnlocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final txt = textColor(isDark);
    final sub = subtext(isDark);
    final accent = isUnlocked
        ? const Color(0xFF34C759)
        : const Color(0xFF8E8E93);

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 16 : 10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(isDark ? 52 : 42)),
      ),
      child: Row(
        children: [
          Icon(definition.icon, color: definition.color, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: txt,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${definition.id} · ${isUnlocked ? 'unlocked' : 'locked'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sub,
                    fontSize: 10.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            key: ValueKey('debug-achievement-toggle-${definition.id}'),
            value: isUnlocked,
            activeThumbColor: const Color(0xFF34C759),
            onChanged: onChanged,
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
