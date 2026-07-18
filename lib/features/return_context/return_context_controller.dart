import '../../app_state.dart';
import '../../engines/return_context_resolver.dart';
import 'return_context_session.dart';
import 'return_context_view_data.dart';

typedef ReturnContextVisibilityChanged = void Function();
typedef ReturnContextSkillSelected = void Function(String skillId);

/// Binds the detached Return Context resolver to one running UI session.
///
/// Navigation stays with the owning shell. This controller only owns candidate
/// projection, session dismissal, and click-time revalidation.
class ReturnContextController {
  ReturnContextController({
    ReturnContextViewDataBuilder builder = const ReturnContextViewDataBuilder(),
    ReturnContextSession? session,
  }) : _builder = builder,
       _session = session ?? ReturnContextSession();

  final ReturnContextViewDataBuilder _builder;
  final ReturnContextSession _session;

  ReturnContextBinding? bind({
    required AppState state,
    required DateTime now,
    required Duration pauseThreshold,
    required bool blocked,
    required ReturnContextVisibilityChanged onVisibilityChanged,
    required ReturnContextSkillSelected onDesktopSkillSelected,
    required ReturnContextSkillSelected onMobileSkillSelected,
  }) {
    final resolved = blocked
        ? null
        : _builder.build(
            state: state,
            now: now,
            pauseThreshold: pauseThreshold,
          );
    final candidate = _session.visibleCandidate(resolved);
    if (candidate == null) return null;

    void dismiss() {
      if (_session.dismiss(candidate)) onVisibilityChanged();
    }

    void continueFor(bool mobile) {
      final target = _builder.revalidate(state: state, rendered: candidate);
      dismiss();
      if (target == null) return;
      (mobile ? onMobileSkillSelected : onDesktopSkillSelected)(target.skillId);
    }

    return ReturnContextBinding(
      candidate: candidate,
      onDismiss: dismiss,
      onContinue: continueFor,
    );
  }

  void reset() => _session.reset();
}

class ReturnContextBinding {
  const ReturnContextBinding({
    required this.candidate,
    required void Function() onDismiss,
    required void Function(bool mobile) onContinue,
  }) : _onDismiss = onDismiss,
       _onContinue = onContinue;

  final ReturnContextCandidate candidate;
  final void Function() _onDismiss;
  final void Function(bool mobile) _onContinue;

  void dismiss() => _onDismiss();

  void continueOnDesktop() => _onContinue(false);

  void continueOnMobile() => _onContinue(true);
}
