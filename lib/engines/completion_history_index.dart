import '../models.dart';
import '../utils.dart';

class CompletionHistorySnapshot {
  final Map<DateTime, List<HistoryEntry>> byDate;
  final int totalCompletions;
  final HistoryEntry? latestRecordedCompletion;

  const CompletionHistorySnapshot({
    required this.byDate,
    required this.totalCompletions,
    required this.latestRecordedCompletion,
  });
}

/// Builds the effective completion view after completion/undo pairs.
///
/// [AppState] remains responsible for mutating history and explicitly
/// invalidating this index. Keeping the index state here prevents read-only
/// statistics caches from becoming another AppState responsibility.
class CompletionHistoryIndex {
  CompletionHistorySnapshot? _cachedSnapshot;
  int? _historyFingerprint;

  CompletionHistorySnapshot resolve(List<HistoryEntry> history) {
    assert(_isFreshForDebug(history));
    final cached = _cachedSnapshot;
    if (cached != null) return cached;

    final snapshot = _build(history);
    _cachedSnapshot = snapshot;
    _historyFingerprint = _fingerprint(history);
    return snapshot;
  }

  List<HistoryEntry> forDate(List<HistoryEntry> history, DateTime date) {
    final entries = resolve(history).byDate[dateOnly(date)];
    return entries ?? const <HistoryEntry>[];
  }

  bool hasCompletionOnDate(List<HistoryEntry> history, DateTime date) {
    return resolve(history).byDate.containsKey(dateOnly(date));
  }

  void invalidate() {
    _cachedSnapshot = null;
    _historyFingerprint = null;
  }

  CompletionHistorySnapshot _build(List<HistoryEntry> history) {
    // History stores newest entries first. For equal timestamps, the larger
    // source index was inserted earlier and must be processed first so an undo
    // cannot precede its matching completion.
    final indexedHistory =
        List<MapEntry<int, HistoryEntry>>.generate(
          history.length,
          (index) => MapEntry(index, history[index]),
        )..sort((a, b) {
          final byTime = a.value.at.compareTo(b.value.at);
          if (byTime != 0) return byTime;
          return b.key.compareTo(a.key);
        });
    final effectiveCompletionsByTask = <String, List<HistoryEntry>>{};
    HistoryEntry? latestRecordedCompletion;

    for (final indexedEntry in indexedHistory) {
      final entry = indexedEntry.value;
      final taskCompletions = effectiveCompletionsByTask.putIfAbsent(
        _taskKey(entry),
        () => <HistoryEntry>[],
      );

      if (entry.isCompletion) {
        taskCompletions.add(entry);
        if (latestRecordedCompletion == null ||
            entry.at.isAfter(latestRecordedCompletion.at)) {
          latestRecordedCompletion = entry;
        }
      } else if (taskCompletions.isNotEmpty) {
        taskCompletions.removeLast();
      }
    }

    final completionsByDate = <DateTime, List<HistoryEntry>>{};
    for (final taskCompletions in effectiveCompletionsByTask.values) {
      for (final completion in taskCompletions) {
        completionsByDate
            .putIfAbsent(dateOnly(completion.at), () => <HistoryEntry>[])
            .add(completion);
      }
    }

    final stableCompletionsByDate = <DateTime, List<HistoryEntry>>{};
    var totalCompletions = 0;
    for (final entry in completionsByDate.entries) {
      entry.value.sort((a, b) => a.at.compareTo(b.at));
      totalCompletions += entry.value.length;
      stableCompletionsByDate[entry.key] = List.unmodifiable(entry.value);
    }

    return CompletionHistorySnapshot(
      byDate: Map.unmodifiable(stableCompletionsByDate),
      totalCompletions: totalCompletions,
      latestRecordedCompletion: latestRecordedCompletion,
    );
  }

  bool _isFreshForDebug(List<HistoryEntry> history) {
    if (_cachedSnapshot == null) return true;
    return _historyFingerprint == _fingerprint(history);
  }

  int _fingerprint(List<HistoryEntry> history) {
    return Object.hashAll(
      history.map(
        (entry) => Object.hash(
          entry.id,
          entry.taskId,
          entry.skillId,
          entry.xp,
          entry.isCompletion,
          entry.at.millisecondsSinceEpoch,
        ),
      ),
    );
  }

  String _taskKey(HistoryEntry entry) {
    return entry.taskId ?? '${entry.skillId}::${entry.taskTitle}';
  }
}
