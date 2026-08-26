import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tutorial/welcome_copy.dart';
import 'mobile_journal_tokens.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.isDark,
    required this.reducedMotion,
    required this.onBegin,
    this.headerAction,
    this.secondaryAction,
  });

  final bool isDark;
  final bool reducedMotion;
  final VoidCallback onBegin;

  /// Reserved for a future locale affordance once localization is real.
  final Widget? headerAction;

  /// Reserved for a future account action. No inactive control is shown now.
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final animationsDisabled = reducedMotion || media.disableAnimations;
    final Color background = MobileJournalTokens.background(isDark);
    final Color text = MobileJournalTokens.text(isDark);
    final Color muted = MobileJournalTokens.muted(isDark);
    final Color surface = MobileJournalTokens.surface(isDark);
    final Color outline = MobileJournalTokens.outline(isDark);

    return Scaffold(
      key: const ValueKey('welcome-page'),
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final contentWidth = math.min(
              constraints.maxWidth - (compact ? 32 : 64),
              760.0,
            );
            return Stack(
              children: [
                const Positioned.fill(
                  child: ExcludeSemantics(child: _WelcomeAtmosphere()),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 32,
                    vertical: compact ? 20 : 32,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(
                        0,
                        constraints.maxHeight - (compact ? 40 : 64),
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: Semantics(
                          namesRoute: true,
                          label: WelcomeCopy.routeLabel,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: animationsDisabled
                                ? Duration.zero
                                : MobileJournalTokens.motion,
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 12),
                                child: child,
                              ),
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: surface.withValues(
                                  alpha: isDark ? 0.94 : 0.97,
                                ),
                                borderRadius: BorderRadius.circular(
                                  compact ? 28 : 36,
                                ),
                                border: Border.all(color: outline),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.32 : 0.08,
                                    ),
                                    blurRadius: 36,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  compact ? 24 : 54,
                                  compact ? 24 : 42,
                                  compact ? 24 : 54,
                                  compact ? 26 : 46,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (headerAction != null)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: headerAction,
                                      ),
                                    const ExcludeSemantics(
                                      child: _WelcomePathMark(),
                                    ),
                                    SizedBox(height: compact ? 24 : 30),
                                    Text(
                                      WelcomeCopy.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: text,
                                        fontSize: compact ? 32 : 44,
                                        height: 1.05,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      WelcomeCopy.subtitle,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: text,
                                        fontSize: compact ? 20 : 25,
                                        height: 1.2,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: compact ? 22 : 28),
                                    _WelcomeLoop(isDark: isDark),
                                    SizedBox(height: compact ? 22 : 28),
                                    Text(
                                      WelcomeCopy.body,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: compact ? 15 : 17,
                                        height: 1.45,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: compact ? 28 : 34),
                                    Semantics(
                                      button: true,
                                      label: WelcomeCopy.beginSemantics,
                                      child: SizedBox(
                                        width: compact ? double.infinity : 280,
                                        height: 54,
                                        child: FilledButton.icon(
                                          key: const ValueKey(
                                            'welcome-begin-action',
                                          ),
                                          onPressed: onBegin,
                                          icon: const Icon(
                                            Icons.arrow_forward_rounded,
                                          ),
                                          label: const Text(
                                            WelcomeCopy.beginLabel,
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                MobileJournalTokens.violet,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (secondaryAction != null) ...[
                                      const SizedBox(height: 12),
                                      secondaryAction!,
                                    ],
                                    const SizedBox(height: 18),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.smartphone_rounded,
                                          size: 16,
                                          color: muted,
                                        ),
                                        const SizedBox(width: 7),
                                        Flexible(
                                          child: Text(
                                            WelcomeCopy.localDataNote,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: muted,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WelcomePathMark extends StatelessWidget {
  const _WelcomePathMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 82,
      child: CustomPaint(painter: _WelcomePathPainter()),
    );
  }
}

class _WelcomePathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = MobileJournalTokens.violet.withValues(alpha: 0.42)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(18, size.height - 16)
      ..cubicTo(
        size.width * 0.30,
        size.height + 4,
        size.width * 0.55,
        2,
        size.width - 18,
        17,
      );
    canvas.drawPath(path, pathPaint);

    final nodes = [
      const Offset(18, 66),
      Offset(size.width * 0.50, size.height * 0.48),
      Offset(size.width - 18, 17),
    ];
    for (var index = 0; index < nodes.length; index++) {
      canvas.drawCircle(
        nodes[index],
        index == nodes.length - 1 ? 10 : 7,
        Paint()
          ..color = index == nodes.length - 1
              ? MobileJournalTokens.amber
              : MobileJournalTokens.violet,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WelcomeLoop extends StatelessWidget {
  const _WelcomeLoop({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color muted = MobileJournalTokens.muted(isDark);
    final labels = const ['Навык', 'Путь', 'Следующий шаг'];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Text(
            labels[index],
            style: TextStyle(
              color: index == labels.length - 1
                  ? MobileJournalTokens.amber
                  : muted,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (index < labels.length - 1)
            Icon(Icons.arrow_forward_rounded, size: 16, color: muted),
        ],
      ],
    );
  }
}

class _WelcomeAtmosphere extends StatelessWidget {
  const _WelcomeAtmosphere();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.72, -0.62),
          radius: 1.15,
          colors: [
            MobileJournalTokens.violet.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
