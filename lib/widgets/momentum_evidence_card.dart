import 'package:flutter/material.dart';

import '../engines/momentum_resolver.dart';
import '../theme/app_typography.dart';
import 'desktop_journal_tokens.dart';
import 'mobile_journal_tokens.dart';

class MomentumEvidenceCard extends StatelessWidget {
  const MomentumEvidenceCard({
    super.key,
    required this.snapshot,
    required this.isDark,
    required this.desktop,
    required this.reducedMotion,
  });

  final MomentumSnapshot snapshot;
  final bool isDark;
  final bool desktop;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final colors = _MomentumColors.resolve(isDark: isDark, desktop: desktop);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = desktop && textScale < 1.6;
    return Semantics(
      key: const ValueKey('momentum-evidence-card'),
      container: true,
      label:
          '${snapshot.headline}. ${snapshot.supportingText}. Навык: ${snapshot.skillName}',
      child: AnimatedContainer(
        duration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 11 : 13,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(desktop ? 14 : 18),
          border: Border.all(color: colors.border),
        ),
        child: AnimatedSwitcher(
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          child: MomentumEvidenceLine(
            key: ValueKey(snapshot.key),
            snapshot: snapshot,
            isDark: isDark,
            desktop: desktop,
            compact: compact,
          ),
        ),
      ),
    );
  }
}

/// Passive evidence used inside Return Context. It deliberately has no CTA.
class MomentumEvidenceLine extends StatelessWidget {
  const MomentumEvidenceLine({
    super.key,
    required this.snapshot,
    required this.isDark,
    required this.desktop,
    this.compact = false,
  });

  final MomentumSnapshot snapshot;
  final bool isDark;
  final bool desktop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _MomentumColors.resolve(isDark: isDark, desktop: desktop);
    return Row(
      key: const ValueKey('momentum-evidence-line'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 32 : 36,
          height: compact ? 32 : 36,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(compact ? 9 : 11),
          ),
          child: Icon(
            Icons.trending_up_rounded,
            color: colors.accent,
            size: compact ? 18 : 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.headline,
                style: context.appTextTheme.bodyMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                snapshot.supportingText,
                key: const ValueKey('momentum-evidence-copy'),
                style: context.appTextTheme.bodySmall?.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MomentumColors {
  const _MomentumColors({
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
  });

  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;

  factory _MomentumColors.resolve({
    required bool isDark,
    required bool desktop,
  }) {
    if (desktop) {
      final tokens = DesktopJournalTokens.resolve(isDark);
      return _MomentumColors(
        surface: tokens.semanticBlue.withValues(alpha: isDark ? 0.055 : 0.05),
        border: tokens.semanticBlue.withValues(alpha: isDark ? 0.24 : 0.2),
        text: tokens.text,
        muted: tokens.mutedText,
        accent: tokens.semanticBlue,
      );
    }
    return _MomentumColors(
      surface: MobileJournalTokens.raised(isDark),
      border: MobileJournalTokens.violet.withValues(
        alpha: isDark ? 0.28 : 0.22,
      ),
      text: MobileJournalTokens.text(isDark),
      muted: MobileJournalTokens.muted(isDark),
      accent: MobileJournalTokens.violet,
    );
  }
}
