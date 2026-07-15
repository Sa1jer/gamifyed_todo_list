import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models.dart';
import 'mobile_journal_tokens.dart';
import 'shared/motion_controls.dart';

export 'shared/form_controls.dart';
export 'shared/motion_controls.dart';
export 'shared/surfaces.dart';
export 'shared/buttons.dart';
export 'shared/progress_badges.dart';
export 'shared/dashed_border.dart';

class MotionFadeSlideSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Offset offset;
  final Alignment alignment;

  const MotionFadeSlideSwitcher({
    super.key,
    required this.child,
    this.duration = kMotionSlow,
    this.offset = const Offset(0, 0.025),
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: kMotionStandard,
      switchInCurve: kMotionCurve,
      switchOutCurve: kMotionExitCurve,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: alignment,
          children: [...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: kMotionCurve,
          reverseCurve: kMotionExitCurve,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: offset,
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class MotionExpandable extends StatelessWidget {
  final bool expanded;
  final Widget expandedChild;
  final Widget collapsedChild;
  final Duration duration;

  const MotionExpandable({
    super.key,
    required this.expanded,
    required this.expandedChild,
    this.collapsedChild = const SizedBox.shrink(),
    this.duration = kMotionSlow,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: kMotionCurve,
      alignment: Alignment.topCenter,
      child: MotionFadeSlideSwitcher(
        duration: duration,
        child: KeyedSubtree(
          key: ValueKey(expanded),
          child: expanded ? expandedChild : collapsedChild,
        ),
      ),
    );
  }
}

class MotionListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final bool enabled;
  final double slide;
  final Duration duration;
  final Duration staggerStep;
  final int maxStaggerIndex;

  const MotionListItem({
    super.key,
    required this.child,
    required this.index,
    this.enabled = true,
    this.slide = 8,
    this.duration = kMotionSlow,
    this.staggerStep = kMotionListStaggerStep,
    this.maxStaggerIndex = kMotionListStaggerMaxIndex,
  });

  @override
  State<MotionListItem> createState() => _MotionListItemState();
}

class _MotionListItemState extends State<MotionListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.enabled ? 0 : 1,
    );
    _animation = CurvedAnimation(parent: _controller, curve: kMotionCurve);
    if (widget.enabled) {
      final maxIndex = widget.maxStaggerIndex < 0 ? 0 : widget.maxStaggerIndex;
      final staggerIndex = widget.index.clamp(0, maxIndex).toInt();
      final delayMs = staggerIndex * widget.staggerStep.inMilliseconds;
      if (delayMs == 0) {
        _controller.forward();
      } else {
        _delayTimer = Timer(Duration(milliseconds: delayMs), () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant MotionListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.enabled != widget.enabled) {
      _delayTimer?.cancel();
      if (widget.enabled) {
        _controller.forward(from: 0);
      } else {
        _controller.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final value = widget.enabled ? _animation.value : 1.0;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, widget.slide * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED XP BAR
// ═══════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════════
// FLOATING XP BUBBLE
// ═══════════════════════════════════════════════════════════════════════════════

CompletionToastColors completionToastColorsForTask({
  required Task? task,
  required Iterable<Skill> skills,
}) {
  if (task == null) return const CompletionToastColors.fallback();
  if (task.isInbox) return CompletionToastColors.resolve(isInbox: true);
  for (final skill in skills) {
    if (skill.id == task.skillId) {
      return CompletionToastColors.resolve(skillColor: skill.color);
    }
  }
  return const CompletionToastColors.fallback();
}

enum ActionToastOriginKind {
  /// Used only when no actionable control exists, such as keyboard fallback.
  questRow,
  questCheckbox,
  minimumAction,
  focusTask,
  roadmapInspectorTask,
  roadmapCanvasNode,
  inboxTask,
  fallback,
}

enum ActionToastZone {
  mainWorkspace,
  rightRail,
  roadmapCanvas,
  roadmapInspector,
  mobileContent,
  mobileBottomContextual,
  fallback,
}

/// Presentation-only completion source. It intentionally stores the action
/// control's global bounds instead of a pointer coordinate: keyboard and mouse
/// activation therefore share a stable visual origin.
@immutable
class ActionToastOrigin {
  final Rect globalSourceRect;
  final ActionToastOriginKind kind;
  final ActionToastZone zone;
  final String? sourceId;
  final int eventSeed;

  const ActionToastOrigin({
    required this.globalSourceRect,
    required this.kind,
    required this.zone,
    this.sourceId,
    this.eventSeed = 0,
  });

  bool get hasSourceRect => !globalSourceRect.isEmpty;

  ActionToastOrigin withEventSeed(int seed) => ActionToastOrigin(
    globalSourceRect: globalSourceRect,
    kind: kind,
    zone: zone,
    sourceId: sourceId,
    eventSeed: seed,
  );
}

ActionToastOrigin actionToastOriginForContext(
  BuildContext context, {
  required ActionToastOriginKind kind,
  required ActionToastZone zone,
  String? sourceId,
}) {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox &&
      renderObject.hasSize &&
      renderObject.attached) {
    return ActionToastOrigin(
      globalSourceRect:
          renderObject.localToGlobal(Offset.zero) & renderObject.size,
      kind: kind,
      zone: zone,
      sourceId: sourceId,
    );
  }
  return ActionToastOrigin(
    globalSourceRect: Rect.zero,
    kind: ActionToastOriginKind.fallback,
    zone: ActionToastZone.fallback,
    sourceId: sourceId,
  );
}

/// Transitional adapter for legacy leaf widgets that still expose a global
/// interaction position. New controls must create origins from their own
/// [BuildContext] so the placement resolver can use real action bounds.
ActionToastOrigin legacyActionToastOrigin(
  Offset globalPosition, {
  required ActionToastZone zone,
  ActionToastOriginKind kind = ActionToastOriginKind.fallback,
  String? sourceId,
}) {
  return ActionToastOrigin(
    globalSourceRect: Rect.fromCenter(
      center: globalPosition,
      width: 1,
      height: 1,
    ),
    kind: kind,
    zone: zone,
    sourceId: sourceId,
  );
}

@immutable
class ActionToastPlacement {
  static const double edgeInset = 12;
  static const double estimatedWidth = 300;
  static const double estimatedHeight = 20;

  final Offset topLeft;
  final double maxWidth;

  const ActionToastPlacement(this.topLeft, {this.maxWidth = estimatedWidth});

  /// Local visual envelope around the control that started the completion.
  /// The envelope is deliberately based on the control type, never on the
  /// containing task row or workspace.
  static ActionToastSpawnPolicy policyFor(
    ActionToastOriginKind kind,
    ActionToastZone zone,
  ) {
    switch (zone) {
      case ActionToastZone.rightRail:
      case ActionToastZone.roadmapInspector:
        return const ActionToastSpawnPolicy(
          preferredDistance: 150,
          hardDistance: 190,
          jitterX: 10,
          jitterY: 8,
        );
      case ActionToastZone.roadmapCanvas:
        return const ActionToastSpawnPolicy(
          preferredDistance: 170,
          hardDistance: 230,
          jitterX: 14,
          jitterY: 10,
        );
      case ActionToastZone.mobileContent:
      case ActionToastZone.mobileBottomContextual:
        return const ActionToastSpawnPolicy(
          preferredDistance: 140,
          hardDistance: 190,
          jitterX: 8,
          jitterY: 6,
        );
      case ActionToastZone.mainWorkspace:
      case ActionToastZone.fallback:
        return const ActionToastSpawnPolicy(
          preferredDistance: 160,
          hardDistance: 210,
          jitterX: 12,
          jitterY: 9,
        );
    }
  }

  /// Resolves once, when the completion event is received. `XPBubble` only
  /// consumes the result, so rebuilds cannot move the toast or re-roll jitter.
  factory ActionToastPlacement.resolve({
    required Rect sourceRect,
    required ActionToastOriginKind kind,
    required ActionToastZone zone,
    required Size viewport,
    Rect? safeRegion,
    Offset jitter = Offset.zero,
    double bottomReserved = 0,
  }) {
    final viewportBounds = Offset.zero & viewport;
    final requestedRegion = safeRegion ?? viewportBounds;
    final boundedRegion = requestedRegion.intersect(viewportBounds);
    final available =
        boundedRegion.width > edgeInset * 2 &&
            boundedRegion.height > edgeInset * 2
        ? boundedRegion.deflate(edgeInset)
        : viewportBounds.deflate(edgeInset);
    final toastWidth = math.min(estimatedWidth, available.width);
    final maxLeft = math.max(available.left, available.right - toastWidth);
    final maxTop = math.max(
      available.top,
      available.bottom - bottomReserved - estimatedHeight,
    );
    const gap = 14.0;
    // A source-less event is a keyboard/fallback interaction. It is the only
    // case allowed to use the local safe-region centre; pointer paths always
    // provide the concrete action-control rect before mutating AppState.
    final source = sourceRect.isEmpty
        ? Rect.fromCenter(center: available.center, width: 1, height: 1)
        : sourceRect;
    final policy = policyFor(kind, zone);
    final prefersBelow =
        kind == ActionToastOriginKind.minimumAction ||
        kind == ActionToastOriginKind.roadmapCanvasNode;
    final aboveRight = Offset(
      source.right + gap,
      source.top - estimatedHeight - gap,
    );
    final aboveLeft = Offset(
      source.left - toastWidth - gap,
      source.top - estimatedHeight - gap,
    );
    final belowRight = Offset(source.right + gap, source.bottom + gap);
    final belowLeft = Offset(
      source.left - toastWidth - gap,
      source.bottom + gap,
    );
    final candidates = <Offset>[
      if (prefersBelow) belowRight else aboveRight,
      if (prefersBelow) belowLeft else aboveLeft,
      if (prefersBelow) aboveRight else belowRight,
      if (prefersBelow) aboveLeft else belowLeft,
    ].map((candidate) => candidate + jitter).toList();

    bool fits(Offset topLeft) {
      final rect = topLeft & Size(toastWidth, estimatedHeight);
      final isInside =
          rect.left >= available.left &&
          rect.right <= available.right &&
          rect.top >= available.top &&
          rect.bottom <= available.bottom - bottomReserved;
      return isInside &&
          !rect.overlaps(source) &&
          (rect.center - source.center).distance <= policy.hardDistance;
    }

    for (final candidate in candidates) {
      if (fits(candidate)) {
        return ActionToastPlacement(candidate, maxWidth: toastWidth);
      }
    }

    // Clamp each local candidate and choose the closest valid local outcome.
    // This never falls back to the centre of the workspace for a pointer event.
    final clamped = candidates
        .map(
          (candidate) => Offset(
            candidate.dx.clamp(available.left, maxLeft),
            candidate.dy.clamp(available.top, maxTop),
          ),
        )
        .map((topLeft) => topLeft & Size(toastWidth, estimatedHeight))
        .where((rect) => !rect.overlaps(source))
        .where(
          (rect) =>
              (rect.center - source.center).distance <= policy.hardDistance,
        )
        .toList();
    if (clamped.isNotEmpty) {
      clamped.sort((a, b) {
        final aDistance = (a.center - source.center).distance;
        final bDistance = (b.center - source.center).distance;
        final aScore = (aDistance - policy.preferredDistance).abs();
        final bScore = (bDistance - policy.preferredDistance).abs();
        return aScore == bScore
            ? aDistance.compareTo(bDistance)
            : aScore.compareTo(bScore);
      });
      return ActionToastPlacement(clamped.first.topLeft, maxWidth: toastWidth);
    }

    // Extremely constrained regions can leave no non-overlapping candidate.
    // Stay adjacent to the actual control rather than jumping to a broad zone.
    final fallback = candidates.first;
    return ActionToastPlacement(
      Offset(
        fallback.dx.clamp(available.left, maxLeft),
        fallback.dy.clamp(available.top, maxTop),
      ),
      maxWidth: toastWidth,
    );
  }

  static Offset stableJitter(
    int seed,
    ActionToastOriginKind kind,
    ActionToastZone zone,
  ) {
    // Deterministic, bounded event variation. It is intentionally calculated
    // outside widget build and stays small on constrained regions.
    final policy = policyFor(kind, zone);
    final x = ((seed * 37) % 25) - 12;
    final y = ((seed * 19) % 19) - 9;
    return Offset(
      x.clamp(-policy.jitterX, policy.jitterX).toDouble(),
      y.clamp(-policy.jitterY, policy.jitterY).toDouble(),
    );
  }
}

@immutable
class ActionToastSpawnPolicy {
  final double preferredDistance;
  final double hardDistance;
  final double jitterX;
  final double jitterY;

  const ActionToastSpawnPolicy({
    required this.preferredDistance,
    required this.hardDistance,
    required this.jitterX,
    required this.jitterY,
  });
}

@immutable
class CompletionToastContent {
  final IconData icon;
  final String title;
  final String? skillName;
  final int? baseXp;
  final int? bonusXp;
  final String? detail;
  final String? nextLevelHint;

  const CompletionToastContent({
    required this.icon,
    required this.title,
    this.skillName,
    this.baseXp,
    this.bonusXp,
    this.detail,
    this.nextLevelHint,
  });

  factory CompletionToastContent.fromMessage(String message) {
    final cleaned = message
        .replaceAll('🎉', '')
        .replaceAll('🏅', '')
        .replaceAll('⬆️', '')
        .trim();
    final lower = cleaned.toLowerCase();
    final lines = cleaned
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final raw = lines.length > 1 ? lines.skip(1).join(' ') : cleaned;
    final parts = raw
        .split('•')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final bonusMatch = RegExp(
      r'эффект\s*\+(\d+)\s*XP',
      caseSensitive: false,
    ).firstMatch(raw);
    final totalMatch = RegExp(r'\+(\d+)\s*XP').firstMatch(raw);
    final totalXp = totalMatch == null
        ? null
        : int.tryParse(totalMatch.group(1)!);
    final bonusXp = bonusMatch == null
        ? null
        : int.tryParse(bonusMatch.group(1)!);
    final baseXp = totalXp == null
        ? null
        : math.max(0, totalXp - (bonusXp ?? 0));
    final remainingMatch = RegExp(
      r'до\s+ур\.?\s*\d+\s+(\d+)\s*XP',
      caseSensitive: false,
    ).firstMatch(raw);
    final remaining = remainingMatch == null
        ? null
        : int.tryParse(remainingMatch.group(1)!);
    final nextLevelHint = remaining != null && remaining > 0 && remaining < 100
        ? 'До следующего уровня $remaining XP'
        : null;

    final isQuickAction = lower.contains('быстрое действие');
    final isSkillGrowth =
        lower.contains('навык окреп') ||
        lower.contains('навык вырос') ||
        lower.contains('окреп до ур');
    final isLevelUp = lower.contains('новый уровень') && !isSkillGrowth;
    String? skillName;
    if (isSkillGrowth || isLevelUp) {
      final candidate = parts.firstWhere(
        (part) =>
            part.toLowerCase().contains('окреп') ||
            (part.contains('+') && !part.toLowerCase().contains('эффект')),
        orElse: () => '',
      );
      final name = candidate
          .replaceFirst(
            RegExp(r'\s+окреп\s+до\s+ур\.?\s*\d+.*$', caseSensitive: false),
            '',
          )
          .replaceFirst(RegExp(r'\+\d+\s*XP.*$', caseSensitive: false), '')
          .replaceFirst(
            RegExp(r'окреп\s+до\s+ур\.?\s*\d+', caseSensitive: false),
            '',
          )
          .trim();
      skillName = name.isEmpty ? null : name;
    }

    return CompletionToastContent(
      icon: isLevelUp
          ? Icons.workspace_premium
          : isSkillGrowth
          ? Icons.trending_up
          : isQuickAction
          ? Icons.auto_awesome
          : lower.contains('сопротивлен')
          ? Icons.shield
          : Icons.auto_awesome,
      title: isLevelUp
          ? 'Новый уровень'
          : isSkillGrowth
          ? 'Навык окреп'
          : isQuickAction
          ? 'Опыт получен'
          : lines.length > 1
          ? lines.first
          : 'Опыт получен',
      skillName: skillName,
      baseXp: baseXp,
      bonusXp: bonusXp,
      detail: isQuickAction ? 'Быстрое действие' : null,
      nextLevelHint: nextLevelHint,
    );
  }

  String get semanticsLabel {
    final values = <String>[title];
    if (skillName != null) values.add(skillName!);
    if (baseXp != null) values.add('плюс $baseXp XP');
    if (bonusXp != null) values.add('эффект плюс $bonusXp XP');
    if (nextLevelHint != null) values.add(nextLevelHint!);
    return values.join(', ');
  }
}

class XPBubble extends StatefulWidget {
  final String message;
  final ActionToastPlacement placement;
  final CompletionToastColors colors;
  final bool showConfetti;
  final Widget Function(Color color)? confettiBuilder;
  final bool reducedMotion;
  final Function(Key?) onDone;
  const XPBubble({
    super.key,
    required this.message,
    required this.placement,
    this.colors = const CompletionToastColors.fallback(),
    this.showConfetti = false,
    this.confettiBuilder,
    this.reducedMotion = false,
    required this.onDone,
  });
  @override
  State<XPBubble> createState() => _XPBubbleState();
}

class _XPBubbleState extends State<XPBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _opacity, _scale;
  late CompletionToastContent _content;

  @override
  void initState() {
    super.initState();
    _content = CompletionToastContent.fromMessage(widget.message);
    _c = AnimationController(
      vsync: this,
      duration: widget.reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 1800),
    );
    final curved = CurvedAnimation(parent: _c, curve: kMotionCurve);
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 14),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 58),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 28),
    ]).animate(_c);
    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.04),
        weight: 18,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.04, end: 1), weight: 22),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 60),
    ]).animate(curved);
    _c.forward().then((_) {
      if (mounted) widget.onDone(widget.key);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? const Color(0xFF15151D) : Colors.white;
    final bg = widget.colors.surfaceTint(baseBg, isDark: isDark);
    final txt = isDark ? const Color(0xFFF4F4F8) : const Color(0xFF1B1B22);
    final sub = isDark ? const Color(0xFF9A9AA6) : const Color(0xFF5F6370);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        return Positioned(
          left: widget.placement.topLeft.dx,
          top: widget.placement.topLeft.dy,
          child: IgnorePointer(
            child: Semantics(
              liveRegion: true,
              label: _content.semanticsLabel,
              child: Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  alignment: Alignment.topLeft,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.placement.maxWidth),
            child: Container(
              key: const ValueKey('xp-bubble-surface'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.colors.borderColor(isDark: isDark),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 95 : 24),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: widget.colors.glowColor(isDark: isDark),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.colors.rewardSoft(isDark: isDark),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _content.icon,
                      key: const ValueKey('xp-bubble-reward-icon'),
                      color: widget.colors.rewardColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _content.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: txt,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            height: 1,
                          ),
                        ),
                        if (_content.skillName != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            _content.skillName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: sub,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 3),
                        _XPBubbleRewardLine(
                          content: _content,
                          textColor: sub,
                          rewardColor: widget.colors.rewardColor,
                          bonusColor: MobileJournalTokens.inbox,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showConfetti && widget.confettiBuilder != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 230,
                    height: 104,
                    child: widget.confettiBuilder!(
                      widget.colors.sourceAccentColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _XPBubbleRewardLine extends StatelessWidget {
  final CompletionToastContent content;
  final Color textColor;
  final Color rewardColor;
  final Color bonusColor;

  const _XPBubbleRewardLine({
    required this.content,
    required this.textColor,
    required this.rewardColor,
    required this.bonusColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1,
    );
    final spans = <InlineSpan>[];
    if (content.baseXp != null) {
      spans.add(
        TextSpan(
          text: '+${content.baseXp} XP',
          style: style.copyWith(
            color: rewardColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
    if (content.bonusXp != null) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' · '));
      spans.add(
        TextSpan(
          text: 'эффект +${content.bonusXp} XP',
          style: style.copyWith(color: bonusColor, fontWeight: FontWeight.w900),
        ),
      );
    }
    if (content.detail != null) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' · '));
      spans.add(TextSpan(text: content.detail));
    }
    if (content.nextLevelHint != null) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' · '));
      spans.add(TextSpan(text: content.nextLevelHint));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: 'Действие засчитано'));

    return Text.rich(
      TextSpan(style: style, children: spans),
      key: const ValueKey('xp-bubble-reward-line'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
