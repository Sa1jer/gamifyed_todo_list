import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils.dart';
import '../shared.dart';

class RewardsTutorialSpotlight extends StatefulWidget {
  final GlobalKey targetKey;
  final bool isDark;
  final VoidCallback onComplete;

  const RewardsTutorialSpotlight({
    super.key,
    required this.targetKey,
    required this.isDark,
    required this.onComplete,
  });

  @override
  State<RewardsTutorialSpotlight> createState() =>
      _RewardsTutorialSpotlightState();
}

class _RewardsTutorialSpotlightState extends State<RewardsTutorialSpotlight> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
  }

  void _updateTargetRect() {
    if (!mounted) return;
    final overlayBox = context.findRenderObject() as RenderBox?;
    final targetContext = widget.targetKey.currentContext;
    final targetBox = targetContext?.findRenderObject() as RenderBox?;
    if (overlayBox == null || targetBox == null || !targetBox.attached) {
      setState(() => _targetRect = null);
      return;
    }
    final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    setState(() => _targetRect = topLeft & targetBox.size);
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF9500);
    final size = MediaQuery.of(context).size;
    final txt = textColor(widget.isDark);
    final sub = subtext(widget.isDark);
    final panelWidth = math.min(size.width - 32, 420.0);
    final rect = _targetRect;
    final top = rect == null
        ? (size.height - 250) / 2
        : (rect.bottom + 18).clamp(18.0, size.height - 250.0).toDouble();
    final left = rect == null
        ? (size.width - panelWidth) / 2
        : (rect.center.dx - panelWidth / 2)
              .clamp(16.0, math.max(16.0, size.width - panelWidth - 16))
              .toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: kMotionSlow,
      curve: kMotionCurve,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RewardsTutorialSpotlightPainter(
                    targetRect: rect,
                    color: color,
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: top,
                width: panelWidth,
                child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface(widget.isDark),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor(widget.isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withAlpha(34),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.redeem, color: color, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Трофеи и эффекты',
                    style: TextStyle(
                      color: txt,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Это обратная связь после действий: сундуки, пассивные эффекты и сопротивление. Их не нужно обслуживать каждый день.',
              style: TextStyle(
                color: sub,
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: SmallBtn(
                label: 'Дальше: профиль',
                icon: Icons.arrow_forward_rounded,
                color: color,
                onTap: widget.onComplete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsTutorialSpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color color;

  const _RewardsTutorialSpotlightPainter({
    required this.targetRect,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withAlpha(184);
    final base = Path()..addRect(Offset.zero & size);
    final rect = targetRect?.inflate(10);
    if (rect == null) {
      canvas.drawRect(Offset.zero & size, overlay);
      return;
    }
    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(22)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, base, cutout),
      overlay,
    );
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withAlpha(210);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _RewardsTutorialSpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.color != color;
  }
}
