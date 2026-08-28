import 'package:flutter/material.dart';

import '../../models/tutorial_progress.dart';
import '../../tutorial/guided_tour_plan.dart';
import '../../tutorial/guided_tour_session.dart';
import '../../tutorial/tutorial_catalog.dart';

enum TutorialTrainingAction { startFullTour, continueTour, restartTour, module }

class TutorialTrainingSelection {
  const TutorialTrainingSelection(this.action, {this.moduleId});

  final TutorialTrainingAction action;
  final String? moduleId;
}

Future<TutorialTrainingSelection?> showTutorialTrainingCenter({
  required BuildContext context,
  required TutorialProgress progress,
  required GuidedTourSessionSnapshot? session,
}) {
  return showDialog<TutorialTrainingSelection>(
    context: context,
    builder: (dialogContext) => TutorialTrainingCenter(
      progress: progress,
      session: session,
      onSelected: (selection) => Navigator.pop(dialogContext, selection),
      onClose: () => Navigator.pop(dialogContext),
    ),
  );
}

class TutorialTrainingCenter extends StatelessWidget {
  const TutorialTrainingCenter({
    super.key,
    required this.progress,
    required this.session,
    required this.onSelected,
    required this.onClose,
  });

  final TutorialProgress progress;
  final GuidedTourSessionSnapshot? session;
  final ValueChanged<TutorialTrainingSelection> onSelected;
  final VoidCallback onClose;

  bool get _hasResumableTour {
    final current = session;
    return current != null &&
        !current.isComplete &&
        current.isPaused &&
        current.mode == GuidedTourMode.fullProductTour;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Dialog(
      key: const ValueKey('tutorial-training-center'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height - 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 10, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFFF9500),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Обучение',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('tutorial-training-close'),
                    tooltip: 'Закрыть обучение',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FullTourCard(
                      session: session,
                      resumable: _hasResumableTour,
                      onSelected: onSelected,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Отдельные темы',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Пройденные темы можно повторять в любом порядке.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final module in TutorialCatalog.modules) ...[
                      _TutorialTopicTile(
                        module: module,
                        completed: progress.isModuleCompleted(module.id),
                        onTap: () => onSelected(
                          TutorialTrainingSelection(
                            TutorialTrainingAction.module,
                            moduleId: module.id,
                          ),
                        ),
                      ),
                      if (module != TutorialCatalog.modules.last)
                        const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullTourCard extends StatelessWidget {
  const _FullTourCard({
    required this.session,
    required this.resumable,
    required this.onSelected,
  });

  final GuidedTourSessionSnapshot? session;
  final bool resumable;
  final ValueChanged<TutorialTrainingSelection> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFFFF9500);
    final stepText = resumable && session != null
        ? 'Шаг ${session!.displayIndex} из ${session!.totalSteps}'
        : '~3–5 минут · данные не изменятся';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withAlpha(18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withAlpha(90)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resumable ? 'Продолжить обучение' : 'Весь продукт за один тур',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stepText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: ValueKey(
                    resumable
                        ? 'tutorial-continue-full-tour'
                        : 'tutorial-start-full-tour',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => onSelected(
                    TutorialTrainingSelection(
                      resumable
                          ? TutorialTrainingAction.continueTour
                          : TutorialTrainingAction.startFullTour,
                    ),
                  ),
                  icon: Icon(
                    resumable ? Icons.play_arrow_rounded : Icons.route_rounded,
                  ),
                  label: Text(
                    resumable
                        ? 'Продолжить обучение'
                        : 'Пройти всё обучение заново',
                  ),
                ),
                if (resumable)
                  TextButton(
                    key: const ValueKey('tutorial-restart-full-tour'),
                    onPressed: () => onSelected(
                      const TutorialTrainingSelection(
                        TutorialTrainingAction.restartTour,
                      ),
                    ),
                    child: const Text('Начать заново'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialTopicTile extends StatelessWidget {
  const _TutorialTopicTile({
    required this.module,
    required this.completed,
    required this.onTap,
  });

  final TutorialModuleDefinition module;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _moduleColor(module.id);
    return ListTile(
      key: ValueKey('tutorial-topic-${module.id}'),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_moduleIcon(module.id), color: color, size: 21),
      ),
      title: Text(
        module.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        completed ? 'Пройдено · можно повторить' : module.subtitle,
      ),
      trailing: const Icon(Icons.play_arrow_rounded),
    );
  }
}

IconData _moduleIcon(String moduleId) => switch (moduleId) {
  TutorialModuleIds.core => Icons.auto_awesome_rounded,
  TutorialModuleIds.act => Icons.bolt_rounded,
  TutorialModuleIds.roadmap => Icons.account_tree_rounded,
  TutorialModuleIds.stats => Icons.query_stats_rounded,
  TutorialModuleIds.trophies => Icons.redeem_rounded,
  TutorialModuleIds.profile => Icons.person_rounded,
  _ => Icons.play_arrow_rounded,
};

Color _moduleColor(String moduleId) => switch (moduleId) {
  TutorialModuleIds.core || TutorialModuleIds.act => const Color(0xFFFF9500),
  TutorialModuleIds.roadmap => const Color(0xFF4A9EFF),
  TutorialModuleIds.stats => const Color(0xFF34C759),
  TutorialModuleIds.trophies => const Color(0xFFFFCC00),
  TutorialModuleIds.profile => const Color(0xFFAF52DE),
  _ => const Color(0xFF4A9EFF),
};
