import 'package:flutter/material.dart';

import '../engines/return_context_resolver.dart';
import '../engines/momentum_resolver.dart';
import '../theme/app_typography.dart';
import 'desktop_journal_tokens.dart';
import 'mobile_journal_tokens.dart';
import 'momentum_evidence_card.dart';

class ReturnContextCard extends StatelessWidget {
  const ReturnContextCard({
    super.key,
    required this.candidate,
    this.momentum,
    required this.isDark,
    required this.desktop,
    required this.reducedMotion,
    required this.onContinue,
    required this.onAnotherAction,
    required this.onDismiss,
  });

  final ReturnContextCandidate candidate;
  final MomentumSnapshot? momentum;
  final bool isDark;
  final bool desktop;
  final bool reducedMotion;
  final VoidCallback onContinue;
  final VoidCallback onAnotherAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = _ReturnContextColors.resolve(
      isDark: isDark,
      desktop: desktop,
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    // Раньше плотная раскладка включалась только на десктопе, и телефон —
    // где места меньше всего — получал самые крупные отступы. Плотность
    // отступает только под увеличенный шрифт.
    final dense = textScale < 1.6;
    final denseColors = colors.withDense(dense);
    final semantics = <String>[
      'Продолжить путь',
      'Навык: ${candidate.skillName}',
      if (candidate.stageTitle != null) 'Текущий этап: ${candidate.stageTitle}',
      if (candidate.lastResult != null)
        'Последний результат: ${candidate.lastResult}',
      if (momentum != null) momentum!.supportingText,
      'Следующий шаг: ${candidate.reentryAction}',
    ].join('. ');

    return Semantics(
      key: const ValueKey('return-context-card'),
      container: true,
      label: semantics,
      child: AnimatedContainer(
        duration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(dense ? 12 : 18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(desktop ? 16 : 22),
          border: Border.all(color: colors.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final actionsBelow =
                !desktop || constraints.maxWidth < 760 || textScale >= 1.6;
            final content = _ReturnContextContent(
              candidate: candidate,
              momentum: momentum,
              colors: denseColors,
              dense: dense,
            );
            final actions = _ReturnContextActions(
              colors: denseColors,
              stackPrimary: !desktop && constraints.maxWidth < 350,
              onContinue: onContinue,
              onAnotherAction: onAnotherAction,
              onDismiss: onDismiss,
            );

            if (actionsBelow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content,
                  SizedBox(height: dense ? 10 : 18),
                  actions,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: content),
                const SizedBox(width: 24),
                Flexible(child: actions),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReturnContextContent extends StatelessWidget {
  const _ReturnContextContent({
    required this.candidate,
    required this.momentum,
    required this.colors,
    required this.dense,
  });

  final ReturnContextCandidate candidate;
  final MomentumSnapshot? momentum;
  final _ReturnContextColors colors;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: dense ? 32 : 44,
              height: dense ? 32 : 44,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(dense ? 10 : 13),
              ),
              child: Icon(
                Icons.route_rounded,
                color: colors.accent,
                size: dense ? 18 : 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Продолжить путь',
                    style:
                        (dense
                                ? context.appTextTheme.titleSmall
                                : context.appTextTheme.titleLarge)
                            ?.copyWith(
                              color: colors.text,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  SizedBox(height: dense ? 1 : 3),
                  Text(
                    candidate.skillName,
                    key: const ValueKey('return-context-skill'),
                    style: context.appTextTheme.bodyMedium?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: dense ? 8 : 16),
        if (candidate.stageTitle case final stage?) ...[
          _ReturnContextRow(
            key: const ValueKey('return-context-stage'),
            label: 'Текущий этап',
            value: stage,
            colors: colors,
          ),
          SizedBox(height: dense ? 5 : 9),
        ],
        if (candidate.lastResult case final result?) ...[
          _ReturnContextRow(
            key: const ValueKey('return-context-last-result'),
            label: 'Последний результат',
            value: result,
            colors: colors,
          ),
          SizedBox(height: dense ? 5 : 9),
        ],
        if (momentum != null) ...[
          MomentumEvidenceLine(
            snapshot: momentum!,
            isDark: colors.isDark,
            desktop: colors.desktop,
            compact: dense,
          ),
          SizedBox(height: dense ? 7 : 11),
        ],
        _ReturnContextRow(
          key: const ValueKey('return-context-next-action'),
          label: 'Следующий шаг',
          value: candidate.reentryAction,
          colors: colors,
          emphasize: true,
        ),
      ],
    );
  }
}

class _ReturnContextRow extends StatelessWidget {
  const _ReturnContextRow({
    super.key,
    required this.label,
    required this.value,
    required this.colors,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final _ReturnContextColors colors;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: colors.muted, fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: emphasize ? colors.text : colors.muted,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
      style: colors.dense
          ? context.appTextTheme.bodySmall
          : context.appTextTheme.bodyMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ReturnContextActions extends StatelessWidget {
  const _ReturnContextActions({
    required this.colors,
    required this.stackPrimary,
    required this.onContinue,
    required this.onAnotherAction,
    required this.onDismiss,
  });

  final _ReturnContextColors colors;
  final bool stackPrimary;
  final VoidCallback onContinue;
  final VoidCallback onAnotherAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final primary = FilledButton.icon(
      key: const ValueKey('return-context-continue'),
      onPressed: onContinue,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        padding: EdgeInsets.symmetric(horizontal: colors.dense ? 12 : 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: Icon(Icons.arrow_forward_rounded, size: colors.dense ? 17 : 19),
      label: const Text(
        'Продолжить',
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
    );
    // В плотном ряду подпись «Другой шаг» переносилась на две строки и
    // растягивала весь ряд — оставляем значок с подсказкой.
    final secondary = colors.dense
        ? SizedBox(
            width: 48,
            height: 48,
            child: OutlinedButton(
              key: const ValueKey('return-context-another'),
              onPressed: onAnotherAction,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 48),
                foregroundColor: colors.text,
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Tooltip(
                message: 'Другой шаг',
                child: Icon(Icons.swap_horiz_rounded, size: 18),
              ),
            ),
          )
        : OutlinedButton(
            key: const ValueKey('return-context-another'),
            onPressed: onAnotherAction,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: colors.text,
              side: BorderSide(color: colors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text('Другой шаг'),
          );
    final dismiss = TextButton(
      key: const ValueKey('return-context-dismiss'),
      onPressed: onDismiss,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: colors.muted,
        padding: EdgeInsets.symmetric(horizontal: colors.dense ? 8 : 12),
      ),
      child: const Text(
        'Не сейчас',
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
    );

    if (stackPrimary) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [primary, const SizedBox(height: 8), secondary, dismiss],
      );
    }
    if (colors.dense) {
      // Три кнопки в Wrap переносились на две строки и стоили карточке
      // почти 90 px. В один ряд они помещаются, если основное действие
      // забирает остаток ширины.
      return Row(
        children: [
          Expanded(child: primary),
          const SizedBox(width: 8),
          secondary,
          const SizedBox(width: 4),
          dismiss,
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [primary, secondary, dismiss],
    );
  }
}

class _ReturnContextColors {
  const _ReturnContextColors({
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.isDark,
    required this.desktop,
    this.dense = true,
  });

  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final bool isDark;
  final bool desktop;

  /// Плотная раскладка: влияет и на кегль строк «этап / результат / шаг».
  final bool dense;

  _ReturnContextColors withDense(bool value) => _ReturnContextColors(
    surface: surface,
    border: border,
    text: text,
    muted: muted,
    accent: accent,
    onAccent: onAccent,
    isDark: isDark,
    desktop: desktop,
    dense: value,
  );

  factory _ReturnContextColors.resolve({
    required bool isDark,
    required bool desktop,
  }) {
    if (desktop) {
      final tokens = DesktopJournalTokens.resolve(isDark);
      return _ReturnContextColors(
        surface: tokens.cardSurface,
        border: tokens.profilePurple.withValues(alpha: isDark ? 0.42 : 0.3),
        text: tokens.text,
        muted: tokens.mutedText,
        accent: tokens.profilePurple,
        onAccent: Colors.white,
        isDark: isDark,
        desktop: desktop,
      );
    }
    return _ReturnContextColors(
      surface: MobileJournalTokens.raised(isDark),
      border: MobileJournalTokens.violet.withValues(
        alpha: isDark ? 0.42 : 0.34,
      ),
      text: MobileJournalTokens.text(isDark),
      muted: MobileJournalTokens.muted(isDark),
      accent: MobileJournalTokens.violet,
      onAccent: Colors.white,
      isDark: isDark,
      desktop: desktop,
    );
  }
}
