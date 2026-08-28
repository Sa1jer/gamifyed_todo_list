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
    required this.onShowRest,
    required this.onStartUsing,
  });

  final bool isDark;
  final bool reducedMotion;
  final VoidCallback onShowRest;
  final VoidCallback onStartUsing;

  @override
  State<TutorialCompletionCard> createState() => _TutorialCompletionCardState();
}

class _TutorialCompletionCardState extends State<TutorialCompletionCard> {
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: foreground,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Можно посмотреть остальные разделы или сразу начать пользоваться приложением.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: secondary,
                                          height: 1.35,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              key: const ValueKey('tutorial-core-show-rest'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9500),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: widget.onShowRest,
                              child: const Text('Показать остальное'),
                            ),
                            TextButton(
                              key: const ValueKey('tutorial-core-start-using'),
                              onPressed: widget.onStartUsing,
                              child: const Text('Начать пользоваться'),
                            ),
                          ],
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
