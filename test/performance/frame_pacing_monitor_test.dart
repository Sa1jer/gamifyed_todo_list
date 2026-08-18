import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/performance/frame_pacing_monitor.dart';

void main() {
  group('FramePacingMonitor', () {
    test('disabled monitor is completely inert', () {
      final scheduler = _FakeFrameScheduler();
      final reports = <FramePacingCaptureReport>[];
      final monitor = FramePacingMonitor(
        enabled: false,
        addTimingsCallback: scheduler.add,
        removeTimingsCallback: scheduler.remove,
        refreshRateProvider: () => 120,
        reporter: reports.add,
      );

      expect(monitor.startCapture(label: 'disabled', frameCount: 1), isFalse);
      expect(monitor.isCapturing, isFalse);
      expect(scheduler.addCount, 0);
      expect(scheduler.removeCount, 0);
      expect(scheduler.callbacks, isEmpty);
      expect(reports, isEmpty);
    });

    test('capture reports metrics and automatically detaches', () {
      final scheduler = _FakeFrameScheduler();
      final reports = <FramePacingCaptureReport>[];
      final monitor = FramePacingMonitor(
        enabled: true,
        addTimingsCallback: scheduler.add,
        removeTimingsCallback: scheduler.remove,
        refreshRateProvider: () => 100,
        reporter: reports.add,
      );

      expect(
        monitor.startCapture(label: 'roadmap-orientation', frameCount: 3),
        isTrue,
      );
      expect(monitor.isCapturing, isTrue);
      expect(scheduler.callbacks, hasLength(1));

      scheduler.emit([
        _timing(buildMicros: 1000, rasterMicros: 4000, totalMicros: 8000),
        _timing(buildMicros: 2000, rasterMicros: 5000, totalMicros: 12000),
        _timing(buildMicros: 3000, rasterMicros: 6000, totalMicros: 20000),
      ]);

      expect(monitor.isCapturing, isFalse);
      expect(scheduler.addCount, 1);
      expect(scheduler.removeCount, 1);
      expect(scheduler.callbacks, isEmpty);
      expect(reports, hasLength(1));
      final report = reports.single;
      expect(report.label, 'roadmap-orientation');
      expect(report.frameCount, 3);
      expect(report.displayRefreshRate, 100);
      expect(report.frameBudgetMilliseconds, 10);
      expect(report.build.averageMilliseconds, 2);
      expect(report.build.p90Milliseconds, 3);
      expect(report.raster.averageMilliseconds, 5);
      expect(report.total.p95Milliseconds, 20);
      expect(report.total.p99Milliseconds, 20);
      expect(report.total.worstMilliseconds, 20);
      expect(report.overBudgetFrames, 2);
      expect(report.overBudgetPercent, closeTo(66.67, 0.01));
      expect(report.bottleneck, 'raster');
      expect(report.toLogLine(), contains('label=roadmap-orientation'));
      expect(report.toLogLine(), contains('over-budget=2 (66.7%)'));
    });

    test('another capture can run after the first completes', () {
      final scheduler = _FakeFrameScheduler();
      final reports = <FramePacingCaptureReport>[];
      final monitor = FramePacingMonitor(
        enabled: true,
        addTimingsCallback: scheduler.add,
        removeTimingsCallback: scheduler.remove,
        refreshRateProvider: () => null,
        reporter: reports.add,
      );

      monitor.startCapture(label: 'first', frameCount: 1);
      scheduler.emit([_timing(totalMicros: 9000)]);
      monitor.startCapture(label: 'second', frameCount: 1);
      scheduler.emit([_timing(totalMicros: 11000)]);

      expect(reports.map((report) => report.label), ['first', 'second']);
      expect(reports.last.frameBudgetMilliseconds, isNull);
      expect(reports.last.overBudgetPercent, isNull);
      expect(scheduler.addCount, 2);
      expect(scheduler.removeCount, 2);
      expect(scheduler.callbacks, isEmpty);
    });

    test('restart and cancellation never leave more than one listener', () {
      final scheduler = _FakeFrameScheduler();
      final reports = <FramePacingCaptureReport>[];
      final monitor = FramePacingMonitor(
        enabled: true,
        addTimingsCallback: scheduler.add,
        removeTimingsCallback: scheduler.remove,
        refreshRateProvider: () => 60,
        reporter: reports.add,
      );

      monitor.startCapture(label: 'superseded', frameCount: 10);
      expect(scheduler.callbacks, hasLength(1));
      monitor.startCapture(label: 'replacement', frameCount: 10);
      expect(scheduler.callbacks, hasLength(1));
      expect(scheduler.addCount, 2);
      expect(scheduler.removeCount, 1);

      monitor.cancelCapture();
      expect(monitor.isCapturing, isFalse);
      expect(scheduler.callbacks, isEmpty);
      expect(scheduler.removeCount, 2);
      expect(reports, isEmpty);
    });
  });
}

FrameTiming _timing({
  int buildMicros = 1000,
  int rasterMicros = 2000,
  required int totalMicros,
}) {
  final rasterStart = totalMicros - rasterMicros;
  return FrameTiming(
    vsyncStart: 0,
    buildStart: 0,
    buildFinish: buildMicros,
    rasterStart: rasterStart,
    rasterFinish: totalMicros,
    rasterFinishWallTime: totalMicros,
  );
}

class _FakeFrameScheduler {
  final Set<FrameTimingsCallback> callbacks = <FrameTimingsCallback>{};
  int addCount = 0;
  int removeCount = 0;

  void add(FrameTimingsCallback callback) {
    addCount += 1;
    callbacks.add(callback);
  }

  void remove(FrameTimingsCallback callback) {
    removeCount += 1;
    callbacks.remove(callback);
  }

  void emit(List<FrameTiming> timings) {
    for (final callback in List<FrameTimingsCallback>.of(callbacks)) {
      callback(timings);
    }
  }
}
