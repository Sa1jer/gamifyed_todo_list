import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import 'shared.dart';

enum RewardConfettiIntensity { subtle, reward, milestone }

class MilestoneConfettiBurst extends StatefulWidget {
  final Color color;
  final Alignment alignment;
  final int particles;
  final RewardConfettiIntensity intensity;

  const MilestoneConfettiBurst({
    super.key,
    required this.color,
    this.alignment = Alignment.topCenter,
    this.particles = 16,
    this.intensity = RewardConfettiIntensity.milestone,
  });

  @override
  State<MilestoneConfettiBurst> createState() => _MilestoneConfettiBurstState();
}

class _MilestoneConfettiBurstState extends State<MilestoneConfettiBurst> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    final duration = switch (widget.intensity) {
      RewardConfettiIntensity.subtle => const Duration(milliseconds: 420),
      RewardConfettiIntensity.reward => const Duration(milliseconds: 650),
      RewardConfettiIntensity.milestone => const Duration(milliseconds: 900),
    };
    _controller = ConfettiController(duration: duration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion) return const SizedBox.shrink();
    final settings = switch (widget.intensity) {
      RewardConfettiIntensity.subtle => (
        count: 8,
        minForce: 3.0,
        maxForce: 8.0,
        gravity: 0.22,
      ),
      RewardConfettiIntensity.reward => (
        count: 14,
        minForce: 5.0,
        maxForce: 13.0,
        gravity: 0.20,
      ),
      RewardConfettiIntensity.milestone => (
        count: widget.particles,
        minForce: 6.0,
        maxForce: 18.0,
        gravity: 0.18,
      ),
    };
    return IgnorePointer(
      child: Align(
        alignment: widget.alignment,
        child: ConfettiWidget(
          confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.05,
          numberOfParticles: settings.count,
          minBlastForce: settings.minForce,
          maxBlastForce: settings.maxForce,
          gravity: settings.gravity,
          colors: [
            widget.color,
            const Color(0xFFFFCC00),
            const Color(0xFF4A9EFF),
            const Color(0xFFFFFFFF),
          ],
        ),
      ),
    );
  }
}

class RewardSparkleBurst extends StatefulWidget {
  final Color color;
  final double size;
  final int sparkleCount;
  final bool loop;

  const RewardSparkleBurst({
    super.key,
    required this.color,
    this.size = 86,
    this.sparkleCount = 14,
    this.loop = false,
  });

  @override
  State<RewardSparkleBurst> createState() => _RewardSparkleBurstState();
}

class _RewardSparkleBurstState extends State<RewardSparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kMotionProgress);
    if (widget.loop) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant RewardSparkleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loop != widget.loop) {
      if (widget.loop) {
        _controller.repeat();
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _RewardSparklePainter(
              progress: _controller.value,
              color: widget.color,
              sparkleCount: widget.sparkleCount,
              loop: widget.loop,
            ),
          ),
        ),
      ),
    );
  }
}

class RewardGlowIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final bool sparkle;
  final bool loop;

  const RewardGlowIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
    this.iconSize = 20,
    this.sparkle = false,
    this.loop = false,
  });

  @override
  State<RewardGlowIcon> createState() => _RewardGlowIconState();
}

class _RewardGlowIconState extends State<RewardGlowIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kMotionProgress);
    if (widget.loop) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant RewardGlowIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loop != widget.loop) {
      if (widget.loop) {
        _controller.repeat(reverse: true);
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = kMotionCurve.transform(_controller.value);
          final scale = widget.loop ? 1 + value * 0.035 : 0.88 + value * 0.12;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (widget.sparkle)
                RewardSparkleBurst(
                  color: widget.color,
                  size: widget.size * 1.72,
                  sparkleCount: widget.loop ? 10 : 16,
                  loop: widget.loop,
                ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(widget.size * 0.28),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withAlpha(
                          widget.loop ? 20 + (value * 22).round() : 34,
                        ),
                        blurRadius: widget.loop ? 13 + value * 8 : 18,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: widget.iconSize,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RewardSparklePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int sparkleCount;
  final bool loop;

  const _RewardSparklePainter({
    required this.progress,
    required this.color,
    required this.sparkleCount,
    required this.loop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.42;

    for (var i = 0; i < sparkleCount; i++) {
      final phase = loop ? (progress + i * 0.137) % 1.0 : progress;
      final curved = kMotionCurve.transform(phase);
      final opacity = math.sin(phase * math.pi).clamp(0.0, 1.0);
      final angle = (math.pi * 2 * i / sparkleCount) + math.sin(i) * 0.28;
      final distance = size.shortestSide * 0.12 + maxRadius * curved;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final radius = 1.2 + opacity * (i.isEven ? 2.1 : 1.4);
      final paint = Paint()
        ..color = color.withAlpha((opacity * 185).round().clamp(0, 185))
        ..style = PaintingStyle.fill;

      if (i % 3 == 0) {
        final arm = radius * 2.1;
        canvas.drawLine(
          point.translate(-arm, 0),
          point.translate(arm, 0),
          paint..strokeWidth = 1.1,
        );
        canvas.drawLine(
          point.translate(0, -arm),
          point.translate(0, arm),
          paint,
        );
      } else {
        canvas.drawCircle(point, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RewardSparklePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.sparkleCount != sparkleCount ||
        oldDelegate.loop != loop;
  }
}
