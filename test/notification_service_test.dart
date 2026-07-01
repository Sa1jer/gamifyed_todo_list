import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/notification_service.dart';

void main() {
  group('NotificationService permission cache', () {
    test('invalidation clears cached permission state without requesting', () {
      final service = NotificationService();
      service.debugSetPermissionCache(true);

      service.invalidatePermissionCache();

      expect(service.debugCachedPermissions, isNull);
    });

    test('cancellation before initialization is a safe no-op', () async {
      final service = NotificationService();

      await service.cancelNotification(42);
      await service.cancelAllNotifications();
    });

    test('notification operations fail soft before initialization', () async {
      final service = NotificationService();

      expect(await service.requestPermissions(), isFalse);
      await service.scheduleTaskReminder(
        id: 1,
        title: 'Напоминание',
        body: 'Текст',
        scheduledTime: DateTime(2026, 7, 1, 9),
      );
      await service.scheduleRepeatingTask(
        id: 2,
        title: 'Напоминание',
        body: 'Текст',
        scheduledTime: DateTime(2026, 7, 1, 9),
      );
      await service.showInstantNotification(
        id: 3,
        title: 'Напоминание',
        body: 'Текст',
      );
    });
  });
}
