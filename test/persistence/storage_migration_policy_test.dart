import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/persistence/storage_migration_policy.dart';

void main() {
  const policy = StorageMigrationPolicy();

  test('normalizes absent and legacy versions to current version', () {
    expect(policy.storedVersion(null), 1);
    expect(policy.versionAfterMigration('1'), 2);
    expect(policy.versionAfterMigration(3), 3);
  });

  test(
    'migrates each valid V1 skill before committing schema version',
    () async {
      final payloads = <Object?, String?>{1: 'one', 2: null, 3: 'three'};
      final operations = <String>[];

      await policy.migrate(
        storedVersionValue: '1',
        skillKeys: payloads.keys,
        readSkill: (key) => payloads[key],
        writeSkill: (key, payload) async {
          operations.add('skill:$key:$payload');
        },
        writeVersion: (version) async {
          operations.add('version:$version');
        },
        migrateSkillPayload: (raw) => 'v2:$raw',
      );

      expect(operations, <String>[
        'skill:1:v2:one',
        'skill:3:v2:three',
        'version:2',
      ]);
    },
  );

  test('current schema performs no traversal or writes', () async {
    var touched = false;

    await policy.migrate(
      storedVersionValue: 2,
      skillKeys: const <Object>[1],
      readSkill: (_) {
        touched = true;
        return 'old';
      },
      writeSkill: (_, _) async => touched = true,
      writeVersion: (_) async => touched = true,
      migrateSkillPayload: (raw) => raw,
    );

    expect(touched, isFalse);
  });
}
