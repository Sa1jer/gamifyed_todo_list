import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

typedef FrameTimingsCallback = void Function(List<FrameTiming> timings);

@immutable
class FramePacingMetricSummary {
  final double averageMilliseconds;
  final double p90Milliseconds;
  final double p95Milliseconds;
  final double p99Milliseconds;
  final double worstMilliseconds;

  const FramePacingMetricSummary({
    required this.averageMilliseconds,
    required this.p90Milliseconds,
    required this.p95Milliseconds,
    required this.p99Milliseconds,
    required this.worstMilliseconds,
  });
}

@immutable
class FramePacingCaptureReport {
  final String label;
  final int frameCount;
  final Duration sampleDuration;
  final double? displayRefreshRate;
  final double? frameBudgetMilliseconds;
  final FramePacingMetricSummary build;
  final FramePacingMetricSummary raster;
  final FramePacingMetricSummary total;
  final int overBudgetFrames;
  final double? overBudgetPercent;
  final String bottleneck;

  const FramePacingCaptureReport({
    required this.label,
    required this.frameCount,
    required this.sampleDuration,
    required this.displayRefreshRate,
    required this.frameBudgetMilliseconds,
    required this.build,
    required this.raster,
    required this.total,
    required this.overBudgetFrames,
    required this.overBudgetPercent,
    required this.bottleneck,
  });

  String toLogLine() {
    return [
      'label=$label',
      'frames=$frameCount',
      'sample=${sampleDuration.inMilliseconds}ms',
      if (displayRefreshRate != null)
        'display=${displayRefreshRate!.toStringAsFixed(1)}Hz',
      if (frameBudgetMilliseconds != null)
        'budget=${frameBudgetMilliseconds!.toStringAsFixed(2)}ms',
      _formatMetric('build', build),
      _formatMetric('raster', raster),
      _formatMetric('total', total),
      'over-budget=$overBudgetFrames'
          '${overBudgetPercent == null ? '' : ' (${overBudgetPercent!.toStringAsFixed(1)}%)'}',
      'bottleneck=$bottleneck',
    ].join(' | ');
  }

  String _formatMetric(String label, FramePacingMetricSummary metric) {
    return '$label avg=${metric.averageMilliseconds.toStringAsFixed(2)}ms '
        'p90=${metric.p90Milliseconds.toStringAsFixed(2)}ms '
        'p95=${metric.p95Milliseconds.toStringAsFixed(2)}ms '
        'p99=${metric.p99Milliseconds.toStringAsFixed(2)}ms '
        'worst=${metric.worstMilliseconds.toStringAsFixed(2)}ms';
  }
}

/// Opt-in frame timing diagnostics for focused debug/profile measurements.
///
/// Enable with `--dart-define=RPG_FRAME_TIMINGS=true`, open Debug Admin, choose
/// a scenario, and then perform that interaction. A capture subscribes only to
/// future frame timings and detaches automatically when its sample is complete.
class FramePacingMonitor {
  static const _compileTimeEnabled = bool.fromEnvironment('RPG_FRAME_TIMINGS');

  final bool _enabled;
  final void Function(FrameTimingsCallback callback) _addTimingsCallback;
  final void Function(FrameTimingsCallback callback) _removeTimingsCallback;
  final double? Function() _refreshRateProvider;
  final void Function(FramePacingCaptureReport report) _reporter;
  final Stopwatch Function() _stopwatchFactory;

  final List<int> _buildMicros = <int>[];
  final List<int> _rasterMicros = <int>[];
  final List<int> _totalMicros = <int>[];

  FrameTimingsCallback? _activeCallback;
  Stopwatch? _sampleClock;
  String? _label;
  int _targetFrameCount = 0;

  FramePacingMonitor({
    bool? enabled,
    void Function(FrameTimingsCallback callback)? addTimingsCallback,
    void Function(FrameTimingsCallback callback)? removeTimingsCallback,
    double? Function()? refreshRateProvider,
    void Function(FramePacingCaptureReport report)? reporter,
    Stopwatch Function()? stopwatchFactory,
  }) : _enabled = enabled ?? (_compileTimeEnabled && !kReleaseMode),
       _addTimingsCallback = addTimingsCallback ?? _addDefaultTimingsCallback,
       _removeTimingsCallback =
           removeTimingsCallback ?? _removeDefaultTimingsCallback,
       _refreshRateProvider = refreshRateProvider ?? _defaultDisplayRefreshRate,
       _reporter = reporter ?? _logReport,
       _stopwatchFactory = stopwatchFactory ?? Stopwatch.new;

  bool get isAvailable => _enabled;
  bool get isCapturing => _activeCallback != null;

  /// Starts a fresh capture and cancels any unfinished capture first.
  ///
  /// Returns false without touching the scheduler when diagnostics are not
  /// compiled in. Invalid arguments are rejected only for enabled diagnostics.
  bool startCapture({required String label, int frameCount = 120}) {
    if (!_enabled) return false;
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }
    if (frameCount <= 0) {
      throw ArgumentError.value(frameCount, 'frameCount', 'must be positive');
    }

    cancelCapture();
    _buildMicros.clear();
    _rasterMicros.clear();
    _totalMicros.clear();
    _label = normalizedLabel;
    _targetFrameCount = frameCount;
    _sampleClock = _stopwatchFactory()..start();

    final callback = _record;
    _activeCallback = callback;
    _addTimingsCallback(callback);
    return true;
  }

  /// Stops an unfinished capture without producing a partial report.
  void cancelCapture() {
    final callback = _activeCallback;
    if (callback != null) {
      _removeTimingsCallback(callback);
    }
    _activeCallback = null;
    _sampleClock?.stop();
    _sampleClock = null;
    _label = null;
    _targetFrameCount = 0;
    _buildMicros.clear();
    _rasterMicros.clear();
    _totalMicros.clear();
  }

  void _record(List<FrameTiming> timings) {
    if (_activeCallback == null) return;
    for (final timing in timings) {
      if (_totalMicros.length >= _targetFrameCount) break;
      _buildMicros.add(timing.buildDuration.inMicroseconds);
      _rasterMicros.add(timing.rasterDuration.inMicroseconds);
      _totalMicros.add(timing.totalSpan.inMicroseconds);
    }
    if (_totalMicros.length < _targetFrameCount) return;

    final callback = _activeCallback!;
    _removeTimingsCallback(callback);
    _activeCallback = null;
    final clock = _sampleClock!..stop();
    final refreshRate = _refreshRateProvider();
    final budgetMicros = refreshRate == null || refreshRate <= 0
        ? null
        : Duration.microsecondsPerSecond / refreshRate;
    final overBudgetFrames = budgetMicros == null
        ? 0
        : _totalMicros.where((value) => value > budgetMicros).length;
    final build = _summarize(_buildMicros);
    final raster = _summarize(_rasterMicros);

    final report = FramePacingCaptureReport(
      label: _label!,
      frameCount: _totalMicros.length,
      sampleDuration: clock.elapsed,
      displayRefreshRate: refreshRate,
      frameBudgetMilliseconds: budgetMicros == null
          ? null
          : _toMilliseconds(budgetMicros),
      build: build,
      raster: raster,
      total: _summarize(_totalMicros),
      overBudgetFrames: overBudgetFrames,
      overBudgetPercent: budgetMicros == null
          ? null
          : overBudgetFrames * 100 / _totalMicros.length,
      bottleneck: build.averageMilliseconds >= raster.averageMilliseconds
          ? 'build'
          : 'raster',
    );

    _sampleClock = null;
    _label = null;
    _targetFrameCount = 0;
    _buildMicros.clear();
    _rasterMicros.clear();
    _totalMicros.clear();
    _reporter(report);
  }

  static FramePacingMetricSummary _summarize(List<int> samples) {
    final sorted = List<int>.of(samples)..sort();
    final average = samples.reduce((a, b) => a + b) / samples.length;
    return FramePacingMetricSummary(
      averageMilliseconds: _toMilliseconds(average),
      p90Milliseconds: _toMilliseconds(_percentile(sorted, 0.90)),
      p95Milliseconds: _toMilliseconds(_percentile(sorted, 0.95)),
      p99Milliseconds: _toMilliseconds(_percentile(sorted, 0.99)),
      worstMilliseconds: _toMilliseconds(sorted.last),
    );
  }

  static num _percentile(List<int> sorted, double percentile) {
    final index = ((sorted.length - 1) * percentile).round();
    return sorted[index];
  }

  static double _toMilliseconds(num microseconds) =>
      microseconds / Duration.microsecondsPerMillisecond;

  static double? _defaultDisplayRefreshRate() {
    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) return null;
    final refreshRate = views.first.display.refreshRate;
    return refreshRate > 0 ? refreshRate : null;
  }

  static void _addDefaultTimingsCallback(FrameTimingsCallback callback) {
    SchedulerBinding.instance.addTimingsCallback(callback);
  }

  static void _removeDefaultTimingsCallback(FrameTimingsCallback callback) {
    SchedulerBinding.instance.removeTimingsCallback(callback);
  }

  static void _logReport(FramePacingCaptureReport report) {
    developer.log(report.toLogLine(), name: 'rpg.frame_pacing');
  }
}

final framePacingMonitor = FramePacingMonitor();
