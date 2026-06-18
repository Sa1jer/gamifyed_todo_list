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
  });
}
