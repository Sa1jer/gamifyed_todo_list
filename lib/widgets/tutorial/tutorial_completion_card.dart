import 'dart:async';

import 'package:flutter/material.dart';

import '../../utils.dart';
import '../shared/motion_controls.dart';

/// Session-only acknowledgement shown after the short Core tutorial.
///
/// It deliberately owns no progression state and grants no rewards. Existing
/// installs with an already-completed Core module never see it because the
/// parent boundary only shows it after an observed active Core action step.
class TutorialCompletionCard extends StatefulWidget {
  const TutorialCompletionCard({
    super.key,
    required this.isDark,
    required this.reducedMotion,
    required this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
  });

  final bool isDark;
  final bool reducedMotion;
  final VoidCallback onDismiss;
  final Duration displayDuration;

  @override
  State<TutorialCompletionCard> createState() => _TutorialCompletionCardState();
}

class _TutorialCompletionCardState extends State<TutorialCompletionCard> {
  Timer? _dismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _scheduleDismiss();
  }

  @override
  void didUpdateWidget(covariant TutorialCompletionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.displayDuration != widget.displayDuration) {
      _scheduleDismiss();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _scheduleDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(widget.displayDuration, _dismiss);
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _dismissTimer?.cancel();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final duration =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : kMotionSlow;
    final foreground = textColor(widget.isDark);
    final secondary = subtext(widget.isDark);

    return Positioned(
      key: const ValueKey('tutorial-core-completion'),
      left: 16,
      right: 16,
      bottom: 16,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: duration,
              curve: kMotionCurve,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              ),
              child: Material(
                color: widget.isDark
                    ? const Color(0xFF181820)
                    : const Color(0xFFFFFFFF),
                elevation: 12,
                shadowColor: Colors.black.withAlpha(widget.isDark ? 130 : 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withAlpha(26)
                        : Colors.black.withAlpha(18),
                  ),
                ),
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: 'Основное обучение завершено',
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9500).withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFFFF9500),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Основу ты знаешь.',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: foreground,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Остальные темы доступны в профиле.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: secondary,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: const ValueKey(
                            'tutorial-core-completion-dismiss',
                          ),
                          tooltip: 'Закрыть',
                          onPressed: _dismiss,
                          icon: Icon(Icons.close_rounded, color: secondary),
                        ),
                      ],
                    ),
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
