import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum TutorialCardSide { right, left, bottom, top, dockedBottom, dockedTop }

class TutorialCardPlacement {
  const TutorialCardPlacement({required this.offset, required this.side});

  final Offset offset;
  final TutorialCardSide side;

  static TutorialCardPlacement resolve({
    required Size viewport,
    required Size cardSize,
    required EdgeInsets safeInsets,
    Rect? target,
    List<Rect> reservedRegions = const [],
    bool mobile = false,
    double gap = 18,
    double mobileBottomReserved = 76,
  }) {
    final safe = Rect.fromLTRB(
      safeInsets.left + 12,
      safeInsets.top + 12,
      viewport.width - safeInsets.right - 12,
      viewport.height -
          safeInsets.bottom -
          12 -
          (mobile ? mobileBottomReserved : 0),
    );
    if (mobile || target == null) {
      return TutorialCardPlacement(
        offset: Offset(
          (safe.center.dx - cardSize.width / 2).clamp(
            safe.left,
            math.max(safe.left, safe.right - cardSize.width),
          ),
          math.max(safe.top, safe.bottom - cardSize.height),
        ),
        side: TutorialCardSide.dockedBottom,
      );
    }

    final candidates = <(TutorialCardSide, Offset)>[
      (
        TutorialCardSide.right,
        Offset(target.right + gap, target.center.dy - cardSize.height / 2),
      ),
      (
        TutorialCardSide.left,
        Offset(
          target.left - gap - cardSize.width,
          target.center.dy - cardSize.height / 2,
        ),
      ),
      (
        TutorialCardSide.bottom,
        Offset(target.center.dx - cardSize.width / 2, target.bottom + gap),
      ),
      (
        TutorialCardSide.top,
        Offset(
          target.center.dx - cardSize.width / 2,
          target.top - gap - cardSize.height,
        ),
      ),
    ];

    TutorialCardPlacement? best;
    double bestScore = double.infinity;
    double bestPenalty = double.infinity;
    for (var index = 0; index < candidates.length; index++) {
      final candidate = candidates[index];
      final rect = candidate.$2 & cardSize;
      final outsideArea = rect.area - rect.intersect(safe).area;
      final targetOverlap = rect.overlaps(target.inflate(8))
          ? rect.intersect(target.inflate(8)).area
          : 0;
      final reservedOverlap = reservedRegions.fold<double>(0, (sum, reserved) {
        return sum +
            (rect.overlaps(reserved) ? rect.intersect(reserved).area : 0);
      });
      final penalty =
          outsideArea * 1000 + targetOverlap * 500 + reservedOverlap * 25;
      final score = penalty + index * 0.0001;
      if (score < bestScore) {
        bestScore = score;
        bestPenalty = penalty;
        best = TutorialCardPlacement(offset: candidate.$2, side: candidate.$1);
      }
    }

    if (best != null && bestPenalty == 0) return best;

    final dockBottom = Offset(
      (safe.center.dx - cardSize.width / 2).clamp(
        safe.left,
        math.max(safe.left, safe.right - cardSize.width),
      ),
      math.max(safe.top, safe.bottom - cardSize.height),
    );
    final dockTop = Offset(dockBottom.dx, safe.top);
    final dockBottomRect = dockBottom & cardSize;
    final dockTopRect = dockTop & cardSize;
    double dockPenalty(Rect rect) {
      final targetPenalty = rect.overlaps(target.inflate(8))
          ? rect.intersect(target.inflate(8)).area * 500
          : 0;
      final reservedPenalty = reservedRegions.fold<double>(0, (sum, reserved) {
        return sum +
            (rect.overlaps(reserved) ? rect.intersect(reserved).area * 25 : 0);
      });
      return targetPenalty + reservedPenalty;
    }

    if (dockPenalty(dockBottomRect) <= dockPenalty(dockTopRect)) {
      return TutorialCardPlacement(
        offset: dockBottom,
        side: TutorialCardSide.dockedBottom,
      );
    }
    return TutorialCardPlacement(
      offset: dockTop,
      side: TutorialCardSide.dockedTop,
    );
  }
}

extension on Rect {
  double get area => math.max(0, width) * math.max(0, height);
}
