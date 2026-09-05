import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/storage_service.dart';
import 'package:todo_list_app/widgets/shared/user_data_transfer_controls.dart';

/// Хранилище без единого документа состояния: так выглядит устройство, на
/// котором перенос данных невозможен.
class _NoSnapshotStorage extends StorageService {
  @override
  Future<void> init() async {}

  @override
  bool get supportsSnapshots => false;
}

class _SnapshotStorage extends _NoSnapshotStorage {
  @override
  bool get supportsSnapshots => true;
}

void main() {
  Widget harness(AppState state) => MaterialApp(
    home: Scaffold(body: UserDataTransferControls(state: state)),
  );

  testWidgets('both directions are offered when storage supports transfer', (
    tester,
  ) async {
    final state = AppState(storage: _SnapshotStorage(), seedDefaults: false);

    await tester.pumpWidget(harness(state));

    expect(find.byKey(const ValueKey('profile-export-data')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-import-data')), findsOneWidget);
    expect(find.text('Экспорт'), findsOneWidget);
    expect(find.text('Импорт'), findsOneWidget);

    state.dispose();
    await tester.pump();
  });

  testWidgets(
    'legacy storage explains itself instead of offering dead buttons',
    (tester) async {
      final state = AppState(
        storage: _NoSnapshotStorage(),
        seedDefaults: false,
      );

      await tester.pumpWidget(harness(state));

      expect(find.byKey(const ValueKey('profile-export-data')), findsNothing);
      expect(find.byKey(const ValueKey('profile-import-data')), findsNothing);
      expect(find.textContaining('Перенос недоступен'), findsOneWidget);

      state.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'import asks before replacing everything, and takes no for an answer',
    (tester) async {
      final state = AppState(storage: _SnapshotStorage(), seedDefaults: false);

      await tester.pumpWidget(harness(state));
      await tester.tap(find.byKey(const ValueKey('profile-import-data')));
      await tester.pumpAndSettle();

      // Импорт затирает всё и отменить его нечем, поэтому вопрос обязателен.
      expect(find.text('Заменить все данные?'), findsOneWidget);
      expect(find.textContaining('Отменить это будет нечем'), findsOneWidget);

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      // Отказ не должен открывать файловый диалог: в тестовой среде он бы и не
      // ответил, но проверяется здесь именно то, что до него не дошло.
      expect(find.text('Заменить все данные?'), findsNothing);
      expect(tester.takeException(), isNull);

      state.dispose();
      await tester.pump();
    },
  );
}
