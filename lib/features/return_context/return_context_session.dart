import '../../engines/return_context_resolver.dart';

/// Owns Return Context interaction state for one running MainPage session.
///
/// This class deliberately has no persistence or AppState dependency.
class ReturnContextSession {
  String? _dismissedCandidateKey;

  String? get dismissedCandidateKey => _dismissedCandidateKey;

  ReturnContextCandidate? visibleCandidate(ReturnContextCandidate? candidate) {
    if (candidate == null || candidate.key == _dismissedCandidateKey) {
      return null;
    }
    return candidate;
  }

  bool dismiss(ReturnContextCandidate candidate) {
    if (_dismissedCandidateKey == candidate.key) return false;
    _dismissedCandidateKey = candidate.key;
    return true;
  }

  void reset() => _dismissedCandidateKey = null;
}
