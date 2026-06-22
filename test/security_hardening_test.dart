import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('release hardening static checks', () {
    test('Android release signing does not use debug keys', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();

      expect(
        gradle,
        isNot(contains('signingConfig = signingConfigs.getByName("debug")')),
      );
      expect(gradle, contains('Release signing is not configured'));
      expect(gradle, contains('key.properties'));
    });

    test('Android production manifest disables app backup', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:fullBackupContent="false"'));
    });

    test('debug-only tools have runtime guards, not only asserts', () {
      final debugFiles = [
        File('lib/debug/debug_admin_panel.dart'),
        File('lib/debug/debug_admin_controller.dart'),
        File('lib/debug/debug_service.dart'),
      ].map((file) => file.readAsStringSync()).join('\n');

      expect(debugFiles, contains('if (!kDebugMode)'));
      expect(debugFiles, contains('StateError'));
      expect(debugFiles, contains('assert(kDebugMode'));
    });

    test('notification diagnostics do not log quest titles', () {
      final source = File('lib/notification_service.dart').readAsStringSync();
      final debugPrintBlocks = RegExp(
        r'debugPrint\(([\s\S]*?)\);',
      ).allMatches(source).map((match) => match.group(0)!).join('\n');

      expect(debugPrintBlocks, isNot(contains('title')));
      expect(debugPrintBlocks, isNot(contains(r'"$title"')));
      expect(source, contains('repeat mode'));
    });

    test('Gitleaks config exists and uses default rules', () {
      final config = File('.gitleaks.toml').readAsStringSync();

      expect(config, contains('useDefault = true'));
      expect(config, contains('Generated Flutter artifacts'));
    });
  });
}
