import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/engines/task_ordering.dart';
import 'package:todo_list_app/models.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  group('shared scheduling rules', () {
    test('startOfWeek always returns local Monday at midnight', () {
      expect(startOfWeek(DateTime(2026, 7, 5, 23, 59)), DateTime(2026, 6, 29));
      expect(startOfWeek(DateTime(2026, 7, 6, 12)), DateTime(2026, 7, 6));
    });

    test('priority rank preserves high to low ordering', () {
      expect(
        prioritySortRank(Priority.high),
        lessThan(prioritySortRank(Priority.medium)),
      );
      expect(
        prioritySortRank(Priority.medium),
        lessThan(prioritySortRank(Priority.low)),
      );
    });

    test('recurring reset catches up years of missed periods in one step', () {
      final result = advanceRecurringReset(
        nextResetAt: DateTime(2016, 7, 6, 3),
        now: DateTime(2026, 7, 6, 12),
        frequency: RepeatFrequency.daily,
        customDays: 1,
      );

      expect(result.elapsedPeriods, 3653);
      expect(result.nextResetAt, DateTime(2026, 7, 7, 3));
    });

    test('recurring reset leaves future schedules unchanged', () {
      final scheduled = DateTime(2026, 7, 7, 3);
      final result = advanceRecurringReset(
        nextResetAt: scheduled,
        now: DateTime(2026, 7, 6, 12),
        frequency: RepeatFrequency.every3Days,
        customDays: 1,
      );

      expect(result.elapsedPeriods, 0);
      expect(result.nextResetAt, scheduled);
    });
  });
}
