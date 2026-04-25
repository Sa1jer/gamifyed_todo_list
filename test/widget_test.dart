import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/main.dart';
import 'package:todo_list_app/storage_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final storage = StorageService();
    await storage.init();
    await tester.pumpWidget(RPGApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('RPG To-Do List'), findsOneWidget);
  });
}