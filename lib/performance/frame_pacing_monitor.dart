import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Opt-in frame timing diagnostics for profile/debug performance sessions.
///
/// Enable with `--dart-define=RPG_FRAME_TIMINGS=true`. The monitor is inert in
/// release builds and does not schedule frames of its own.
class FramePacingMonitor {
  static const _enabled = bool.fromEnvironment('RPG_FRAME_TIMINGS');
  static const _sampleSize = 120;

  final List<int> _buildMicros = <int>[];
  final List<int> _rasterMicros = <int>[];
  final List<int> _totalMicros = <int>[];
  final Stopwatch _sampleClock = Stopwatch();
  bool _installed = false;

  void install() {
    if (_installed || !_enabled || kReleaseMode) return;
    _installed = true;
    _sampleClock.start();
    SchedulerBinding.instance.addTimingsCallback(_record);
  }

  void _record(List<FrameTiming> timings) {
    for (final timing in timings) {
      if (_totalMicros.length >= _sampleSize) break;
      _buildMicros.add(timing.buildDuration.inMicroseconds);
      _rasterMicros.add(timing.rasterDuration.inMicroseconds);
      _totalMicros.add(timing.totalSpan.inMicroseconds);
    }
    if (_totalMicros.length < _sampleSize) return;

    SchedulerBinding.instance.removeTimingsCallback(_record);
    _sampleClock.stop();

    final views = PlatformDispatcher.instance.views;
    final refreshRate = views.isEmpty ? null : views.first.display.refreshRate;
    final frameBudgetMicros = refreshRate == null || refreshRate <= 0
        ? null
        : (Duration.microsecondsPerSecond / refreshRate).round();
    final missedFrames = frameBudgetMicros == null
        ? null
        : _totalMicros.where((value) => value > frameBudgetMicros).length;

    developer.log(
      [
        'frames=${_totalMicros.length}',
        'sample=${_sampleClock.elapsedMilliseconds}ms',
        if (refreshRate != null) 'display=${refreshRate.toStringAsFixed(1)}Hz',
        _summary('build', _buildMicros),
        _summary('raster', _rasterMicros),
        _summary('total', _totalMicros),
        if (missedFrames != null) 'over-budget=$missedFrames',
      ].join(' | '),
      name: 'rpg.frame_pacing',
    );
  }

  String _summary(String label, List<int> samples) {
    final sorted = List<int>.of(samples)..sort();
    final average = samples.reduce((a, b) => a + b) / samples.length;
    return '$label avg=${_milliseconds(average)} '
        'p90=${_milliseconds(_percentile(sorted, 0.90))} '
        'p95=${_milliseconds(_percentile(sorted, 0.95))} '
        'p99=${_milliseconds(_percentile(sorted, 0.99))}';
  }

  num _percentile(List<int> sorted, double percentile) {
    final index = ((sorted.length - 1) * percentile).round();
    return sorted[index];
  }

  String _milliseconds(num microseconds) =>
      '${(microseconds / Duration.microsecondsPerMillisecond).toStringAsFixed(2)}ms';
}

final framePacingMonitor = FramePacingMonitor();
