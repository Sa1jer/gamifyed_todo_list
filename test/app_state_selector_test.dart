import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/app_state.dart';
import 'package:todo_list_app/storage_service.dart';

void main() {
  testWidgets('AppStateSelector ignores unrelated notifications', (
    WidgetTester tester,
  ) async {
    final state = AppState(storage: StorageService(), seedDefaults: false);
    var builds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateProvider(
          state: state,
          child: AppStateSelector<bool>(
            selector: (state) => state.tooltipsEnabled,
            builder: (context, tooltipsEnabled, child) {
              builds++;
              return Text(tooltipsEnabled ? 'enabled' : 'disabled');
            },
          ),
        ),
      ),
    );

    expect(builds, 1);
    expect(find.text('enabled'), findsOneWidget);

    state.toggleSfxEnabled();
    await tester.pump();
    expect(builds, 1);

    state.toggleTooltipsEnabled();
    await tester.pump();
    expect(builds, 2);
    expect(find.text('disabled'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets('AppStateSelector rebinds when provider state changes', (
    WidgetTester tester,
  ) async {
    final first = AppState(storage: StorageService(), seedDefaults: false);
    final second = AppState(storage: StorageService(), seedDefaults: false)
      ..toggleTooltipsEnabled();
    final providerState = ValueNotifier<AppState>(first);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<AppState>(
          valueListenable: providerState,
          builder: (context, state, child) => AppStateProvider(
            state: state,
            child: AppStateSelector<bool>(
              selector: (state) => state.tooltipsEnabled,
              builder: (context, enabled, child) => Text('$enabled'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('true'), findsOneWidget);

    providerState.value = second;
    await tester.pump();
    expect(find.text('false'), findsOneWidget);

    first.toggleTooltipsEnabled();
    await tester.pump();
    expect(find.text('false'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    providerState.dispose();
    first.dispose();
    second.dispose();
  });
}
