import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../persistence_status.dart';

class PersistenceGate extends StatelessWidget {
  const PersistenceGate({
    super.key,
    required this.state,
    required this.child,
    this.onRetryLoad,
  });

  final AppState state;
  final Widget child;
  final Future<void> Function()? onRetryLoad;

  @override
  Widget build(BuildContext context) {
    final status = state.persistenceStatus;
    if (!state.hasLoadedSavedData) {
      if (status.phase == PersistencePhase.loadFailed) {
        return _LoadRecoveryScreen(
          state: state,
          onRetryLoad: onRetryLoad ?? state.retryLoadSavedData,
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Stack(
      children: [
        child,
        if (status.phase == PersistencePhase.saveFailed)
          _SaveFailureBanner(state: state),
      ],
    );
  }
}

class _LoadRecoveryScreen extends StatelessWidget {
  const _LoadRecoveryScreen({required this.state, required this.onRetryLoad});

  final AppState state;
  final Future<void> Function() onRetryLoad;

  @override
  Widget build(BuildContext context) {
    final status = state.persistenceStatus;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restore_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Не удалось загрузить данные',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Мы не будем перезаписывать ваши сохранённые данные, '
                        'пока загрузка не восстановится.',
                        textAlign: TextAlign.center,
                      ),
                      if (kDebugMode && status.debugDetails != null) ...[
                        const SizedBox(height: 8),
                        ExpansionTile(
                          key: const Key('persistence-debug-details'),
                          title: const Text('Подробнее'),
                          children: [
                            SelectableText(
                              status.debugDetails!,
                              textAlign: TextAlign.left,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const Key('persistence-retry-load'),
                        onPressed: status.phase == PersistencePhase.recovering
                            ? null
                            : () => unawaited(onRetryLoad()),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveFailureBanner extends StatelessWidget {
  const _SaveFailureBanner({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Material(
              key: const Key('persistence-save-failure'),
              elevation: 8,
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const message = Text(
                    'Не удалось сохранить изменения. '
                    'Они останутся в памяти до повторной попытки.',
                  );
                  final retry = TextButton(
                    key: const Key('persistence-retry-save'),
                    onPressed: () => unawaited(state.retrySave()),
                    child: Text(
                      constraints.maxWidth < 500
                          ? 'Повторить'
                          : 'Повторить сохранение',
                    ),
                  );
                  if (constraints.maxWidth < 500) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.cloud_off_rounded),
                              SizedBox(width: 12),
                              Expanded(child: message),
                            ],
                          ),
                          Align(alignment: Alignment.centerRight, child: retry),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded),
                        const SizedBox(width: 12),
                        const Flexible(child: message),
                        const SizedBox(width: 12),
                        retry,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
