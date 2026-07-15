/// Owns legacy schema version decisions and the V1 -> V2 traversal policy.
///
/// Payload parsing stays injected so migration and normal reads always share
/// the same codecs.
class StorageMigrationPolicy {
  const StorageMigrationPolicy({
    this.legacyVersion = 1,
    this.currentVersion = 2,
  });

  final int legacyVersion;
  final int currentVersion;

  int storedVersion(Object? raw) => _readNullableInt(raw) ?? legacyVersion;

  int versionAfterMigration(Object? raw) {
    final version = storedVersion(raw);
    return version < currentVersion ? currentVersion : version;
  }

  Future<void> migrate({
    required Object? storedVersionValue,
    required Iterable<Object?> skillKeys,
    required String? Function(Object? key) readSkill,
    required Future<void> Function(Object? key, String payload) writeSkill,
    required Future<void> Function(int version) writeVersion,
    required String? Function(String raw) migrateSkillPayload,
  }) async {
    final version = storedVersion(storedVersionValue);
    if (version >= currentVersion) return;

    if (version < 2) {
      for (final key in skillKeys.toList(growable: false)) {
        final raw = readSkill(key);
        if (raw == null) continue;
        final migrated = migrateSkillPayload(raw);
        if (migrated == null) continue;
        await writeSkill(key, migrated);
      }
    }
    await writeVersion(currentVersion);
  }

  String? migrateSkillPayloadV1ToV2<T>({
    required String raw,
    required Map<String, dynamic>? Function(String raw) decodeMapOrNull,
    required T? Function(String raw) decodeSkillOrNull,
    required String Function(T skill) encodeSkill,
  }) {
    final data = decodeMapOrNull(raw);
    if (data == null || data.isEmpty) return null;
    final skill = decodeSkillOrNull(raw);
    if (skill == null) return null;
    return encodeSkill(skill);
  }

  int? _readNullableInt(Object? value) {
    return switch (value) {
      final int value => value,
      final double value when value.isFinite => value.toInt(),
      final String value => int.tryParse(value),
      _ => null,
    };
  }
}
