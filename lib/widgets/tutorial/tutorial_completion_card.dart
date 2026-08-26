import 'package:flutter/material.dart';

import '../../utils.dart';
import '../shared/motion_controls.dart';

/// Session-only acknowledgement shown after the short Core tutorial.
///
/// It deliberately owns no progression state and grants no rewards. Existing
/// installs with an already-completed Core module never see it because the
/// parent boundary only shows it after an observed active Core action step.
class TutorialCompletionCard extends StatelessWidget {
  const TutorialCompletionCard({
    super.key,
    required this.isDark,
    required this.reducedMotion,
    required this.onContinue,
  });

  final bool isDark;
  final bool reducedMotion;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final duration = reducedMotion || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : kMotionSlow;
    final foreground = textColor(isDark);
    final secondary = subtext(isDark);

    return Positioned.fill(
      key: const ValueKey('tutorial-core-completion'),
      child: Material(
        color: Colors.black.withAlpha(isDark ? 170 : 104),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  label: 'Основное обучение завершено',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF181820)
                            : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withAlpha(26)
                              : Colors.black.withAlpha(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 130 : 34),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9500).withAlpha(30),
                                borderRadius: BorderRadius.circular(17),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFFFF9500),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Готово. Основу ты знаешь.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: foreground,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Остальные темы можно открыть отдельно в профиле, когда они понадобятся.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: secondary,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                key: const ValueKey(
                                  'tutorial-core-completion-continue',
                                ),
                                onPressed: onContinue,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: const Text('Продолжить'),
                              ),
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
        ),
      ),
    );
  }
}
