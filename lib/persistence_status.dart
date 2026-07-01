enum PersistencePhase {
  idle,
  loading,
  ready,
  loadFailed,
  saving,
  saveFailed,
  recovering,
}

class PersistenceStatus {
  const PersistenceStatus({
    this.phase = PersistencePhase.idle,
    this.message,
    this.errorType,
    this.debugDetails,
    this.lastSuccessfulLoadAt,
    this.lastSuccessfulSaveAt,
    this.lastFailureAt,
    this.canRetry = false,
    this.isDirty = false,
    this.blocksSaving = false,
  });

  final PersistencePhase phase;
  final String? message;
  final String? errorType;
  final String? debugDetails;
  final DateTime? lastSuccessfulLoadAt;
  final DateTime? lastSuccessfulSaveAt;
  final DateTime? lastFailureAt;
  final bool canRetry;
  final bool isDirty;
  final bool blocksSaving;

  bool get hasError =>
      phase == PersistencePhase.loadFailed ||
      phase == PersistencePhase.saveFailed;

  PersistenceStatus copyWith({
    PersistencePhase? phase,
    String? message,
    String? errorType,
    String? debugDetails,
    bool clearError = false,
    DateTime? lastSuccessfulLoadAt,
    DateTime? lastSuccessfulSaveAt,
    DateTime? lastFailureAt,
    bool? canRetry,
    bool? isDirty,
    bool? blocksSaving,
  }) {
    return PersistenceStatus(
      phase: phase ?? this.phase,
      message: clearError ? null : message ?? this.message,
      errorType: clearError ? null : errorType ?? this.errorType,
      debugDetails: clearError ? null : debugDetails ?? this.debugDetails,
      lastSuccessfulLoadAt: lastSuccessfulLoadAt ?? this.lastSuccessfulLoadAt,
      lastSuccessfulSaveAt: lastSuccessfulSaveAt ?? this.lastSuccessfulSaveAt,
      lastFailureAt: lastFailureAt ?? this.lastFailureAt,
      canRetry: canRetry ?? this.canRetry,
      isDirty: isDirty ?? this.isDirty,
      blocksSaving: blocksSaving ?? this.blocksSaving,
    );
  }
}
