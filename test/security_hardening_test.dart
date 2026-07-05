import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

Iterable<File> _dartFilesIn(String path) {
  final entity = Directory(path);
  if (!entity.existsSync()) return const [];
  return entity
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

Map<String, String> _readDartFilesIn(String path) {
  return {
    for (final file in _dartFilesIn(path)) file.path: file.readAsStringSync(),
  };
}

String _relativePath(String path) {
  return path.replaceAll('${Directory.current.path}/', '');
}

bool _isLibDebugPath(String path) {
  return _relativePath(path).startsWith('lib/debug/');
}

void main() {
  group('release hardening static checks', () {
    test('Android release signing does not use debug keys', () {
      final gradle = _read('android/app/build.gradle.kts');

      expect(
        gradle,
        isNot(contains('signingConfig = signingConfigs.getByName("debug")')),
      );
      expect(gradle, contains('Release signing is not configured'));
      expect(gradle, contains('key.properties'));
    });

    test('Android production manifest disables app backup', () {
      final manifest = _read('android/app/src/main/AndroidManifest.xml');

      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:fullBackupContent="false"'));
    });

    test('debug admin entrypoint has runtime guard, not only assert', () {
      final panel = _read('lib/debug/debug_admin_panel.dart');

      expect(panel, contains('Future<void> showDebugAdminPanel'));
      expect(panel, contains('if (kReleaseMode)'));
      expect(
        panel,
        contains("throw StateError('Debug Admin must not be used in release"),
      );
      expect(panel, contains('assert(!kReleaseMode'));
    });

    test('debug admin controller actions have runtime guards', () {
      final controller = _read('lib/debug/debug_admin_controller.dart');

      expect(controller, contains('Future<void> applyScenario'));
      expect(controller, contains('Future<void> clearDebugDraftState'));
      expect(
        'if (kReleaseMode)'.allMatches(controller),
        hasLength(greaterThanOrEqualTo(2)),
      );
      expect(
        controller,
        contains("throw StateError('Debug scenarios must not run in release"),
      );
      expect(
        controller,
        contains("throw StateError('Debug tools must not run in release"),
      );
      expect(
        'assert(!kReleaseMode'.allMatches(controller),
        hasLength(greaterThanOrEqualTo(2)),
      );
    });

    test('debug service opens debug box only behind runtime guard', () {
      final service = _read('lib/debug/debug_service.dart');

      expect(service, contains("static const boxName = '__debug__'"));
      expect(service, contains('Future<void> init() async'));
      expect(service, contains('if (kReleaseMode)'));
      expect(
        service,
        contains("throw StateError('DebugService must not be used in release"),
      );
      expect(service, contains('assert(!kReleaseMode'));
      expect(service, contains('Hive.openBox<String>(boxName)'));
    });

    test('production storage and AppState do not reference debug storage', () {
      final productionStateFiles = {
        'lib/app_state.dart': _read('lib/app_state.dart'),
        ..._readDartFilesIn('lib/app_state'),
      };
      final storage = _read('lib/storage_service.dart');
      final forbidden = [
        'DebugService',
        'DebugAdmin',
        '__debug__',
        'debug_service.dart',
        'debug_admin',
      ];

      for (final token in forbidden) {
        expect(
          storage,
          isNot(contains(token)),
          reason: 'StorageService must not know about $token.',
        );
        for (final entry in productionStateFiles.entries) {
          expect(
            entry.value,
            isNot(contains(token)),
            reason: '${entry.key} must not know about $token.',
          );
        }
      }
    });

    test('debug admin has one gated hidden-entry callsite', () {
      final shell = _read('lib/widgets/main_page/shell.dart');
      final mainPage = _read('lib/widgets/main_page.dart');
      final nonDebugLibFiles = _readDartFilesIn('lib')
        ..removeWhere((path, _) => _isLibDebugPath(path));
      final showPanelCallsites = nonDebugLibFiles.entries
          .where((entry) => entry.value.contains('showDebugAdminPanel'))
          .map((entry) => _relativePath(entry.key))
          .toList();

      expect(mainPage, contains("import '../debug/debug_admin_panel.dart';"));
      expect(showPanelCallsites, ['lib/widgets/main_page/shell.dart']);
      expect(shell, contains('void _handleDebugAdminTap(AppState state)'));
      expect(shell, contains('if (kReleaseMode) return;'));
      expect(shell, contains('showDebugAdminPanel(context, state: state)'));
      expect(shell, contains('onAppIconTap: !kReleaseMode'));
      expect(shell, contains('? () => _handleDebugAdminTap(s)'));
      expect(shell, contains(': null'));
    });

    test('debug internals are not imported outside the debug boundary', () {
      final allowedDebugImports = {
        'lib/widgets/main_page.dart': [
          "import '../debug/debug_admin_panel.dart';",
        ],
      };
      final nonDebugLibFiles = _readDartFilesIn('lib')
        ..removeWhere((path, _) => _isLibDebugPath(path));
      final forbiddenDebugImports = [
        'debug_admin_controller.dart',
        'debug_scenarios.dart',
        'debug_service.dart',
        'debug/debug_admin_controller',
        'debug/debug_scenarios',
        'debug/debug_service',
      ];

      for (final entry in nonDebugLibFiles.entries) {
        final relativePath = _relativePath(entry.key);
        final allowed = allowedDebugImports[relativePath] ?? const <String>[];
        for (final token in forbiddenDebugImports) {
          expect(
            entry.value,
            isNot(contains(token)),
            reason: '$relativePath must not import debug internals: $token.',
          );
        }
        if (entry.value.contains('debug_admin_panel.dart')) {
          expect(
            allowed.any(entry.value.contains),
            isTrue,
            reason: '$relativePath has an unexpected debug panel import.',
          );
        }
      }
    });

    test('debug UI does not print potentially sensitive state', () {
      final debugFiles = _readDartFilesIn('lib/debug');

      for (final entry in debugFiles.entries) {
        expect(
          entry.value,
          isNot(contains('debugPrint(')),
          reason: '${entry.key} should not log debug scenario/user state.',
        );
        expect(
          entry.value,
          isNot(contains('print(')),
          reason: '${entry.key} should not log debug scenario/user state.',
        );
      }
    });

    test('notification diagnostics do not log quest titles', () {
      final source = _read('lib/notification_service.dart');
      final debugPrintBlocks = RegExp(
        r'debugPrint\(([\s\S]*?)\);',
      ).allMatches(source).map((match) => match.group(0)!).join('\n');

      expect(debugPrintBlocks, isNot(contains('title')));
      expect(debugPrintBlocks, isNot(contains(r'"$title"')));
      expect(source, contains('repeat mode'));
    });

    test(
      'notification scheduling revalidates state and hides quest titles',
      () {
        final state = _read('lib/app_state.dart');

        expect(state, contains('_scheduleTaskNotificationIfCurrent'));
        expect(state, contains('final task = _taskById(taskId);'));
        expect(state, contains('!task.notificationsEnabled'));
        expect(state, isNot(contains("title: 'Напоминание: \${task.title}'")));
        expect(state, contains("title: 'Напоминание о квесте'"));
      },
    );

    test('Gitleaks config exists and uses default rules', () {
      final config = _read('.gitleaks.toml');

      expect(config, contains('useDefault = true'));
      expect(config, contains('Generated Flutter artifacts'));
    });
  });
}
