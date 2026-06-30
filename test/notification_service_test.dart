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
  });
}
