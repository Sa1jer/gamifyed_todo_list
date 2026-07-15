import 'dart:async';

typedef SaveFailureCallback =
    void Function(Object error, StackTrace stackTrace);

/// Owns debounce and single-flight sequencing for application persistence.
///
/// The scheduler does not know what is being saved and never mutates domain
/// state. A request arriving during a write produces one additional full write
/// after the current one, so the latest in-memory state is not lost.
class SaveScheduler {
  SaveScheduler({
    required Future<void> Function() writer,
    required bool Function() isBlocked,
    required void Function() onSaving,
    required void Function(DateTime savedAt) onSaved,
    required SaveFailureCallback onFailure,
    this.debounce = const Duration(milliseconds: 750),
    DateTime Function()? clock,
  }) : _writer = writer,
       _isBlocked = isBlocked,
       _onSaving = onSaving,
       _onSaved = onSaved,
       _onFailure = onFailure,
       _clock = clock ?? DateTime.now;

  final Duration debounce;
  final Future<void> Function() _writer;
  final bool Function() _isBlocked;
  final void Function() _onSaving;
  final void Function(DateTime savedAt) _onSaved;
  final SaveFailureCallback _onFailure;
  final DateTime Function() _clock;

  Timer? _debounceTimer;
  Future<void>? _inFlight;
  bool _writeAgainAfterInFlight = false;
  bool _disposed = false;

  bool get hasPendingDebounce => _debounceTimer != null;
  bool get isWriting => _inFlight != null;

  Future<void> request({bool immediate = false}) {
    if (_disposed || _isBlocked()) return Future.value();
    if (_inFlight != null) {
      _writeAgainAfterInFlight = true;
      return Future.value();
    }
    if (immediate) return flush();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      _debounceTimer = null;
      unawaited(runObserved());
    });
    return Future.value();
  }

  Future<void> flush() {
    cancelPending();
    if (_disposed || _isBlocked()) return Future.value();
    return _writeAll();
  }

  Future<void> runObserved() async {
    try {
      await flush();
    } catch (_) {
      // The failure callback records the error before this future completes.
    }
  }

  void cancelPending() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<void> _writeAll() {
    final inFlight = _inFlight;
    if (inFlight != null) {
      _writeAgainAfterInFlight = true;
      return inFlight;
    }

    final completer = Completer<void>();
    _inFlight = completer.future;
    _onSaving();

    () async {
      try {
        do {
          _writeAgainAfterInFlight = false;
          await _writer();
        } while (_writeAgainAfterInFlight);
        _onSaved(_clock());
        completer.complete();
      } catch (error, stackTrace) {
        _onFailure(error, stackTrace);
        completer.completeError(error, stackTrace);
      } finally {
        _inFlight = null;
      }
    }();

    return completer.future;
  }

  void dispose() {
    _disposed = true;
    cancelPending();
  }
}
