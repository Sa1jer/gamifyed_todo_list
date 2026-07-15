import '../storage_snapshot.dart';

abstract class SnapshotBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

typedef SnapshotEncoder = String Function(StorageSnapshot snapshot);
typedef SnapshotDecoder = StorageSnapshot Function(String raw);

/// Owns the snapshot staging and manifest commit protocol.
///
/// Payload encoding remains outside this class so legacy codecs and schema
/// compatibility stay under StorageService ownership.
class SnapshotStore {
  static const String currentManifestKey = 'manifest_current';
  static const String previousManifestKey = 'manifest_previous';
  static const String payloadPrefix = 'payload:';

  const SnapshotStore({
    required this.backend,
    required this.encode,
    required this.decode,
  });

  final SnapshotBackend backend;
  final SnapshotEncoder encode;
  final SnapshotDecoder decode;

  Future<CommittedSnapshot?> loadLatest() async {
    final currentId = await backend.read(currentManifestKey);
    final previousId = await backend.read(previousManifestKey);
    final candidates = <(String?, SnapshotLoadSource)>[
      (currentId, SnapshotLoadSource.current),
      (previousId, SnapshotLoadSource.previous),
    ];
    final visited = <String>{};

    for (final candidate in candidates) {
      final id = candidate.$1;
      if (id == null || id.isEmpty || !visited.add(id)) continue;
      final raw = await backend.read('$payloadPrefix$id');
      if (raw == null) continue;
      try {
        final snapshot = decode(raw);
        if (snapshot.id != id) continue;
        return CommittedSnapshot(snapshot: snapshot, source: candidate.$2);
      } catch (_) {
        // A corrupt current candidate falls back to previous, then legacy.
      }
    }
    return null;
  }

  Future<void> save(StorageSnapshot snapshot) async {
    final raw = encode(snapshot);
    decode(raw);
    final payloadKey = '$payloadPrefix${snapshot.id}';

    await backend.write(payloadKey, raw);
    final staged = await backend.read(payloadKey);
    if (staged == null) {
      throw StateError('Snapshot staging payload is unavailable.');
    }
    final validated = decode(staged);
    if (validated.id != snapshot.id) {
      throw StateError('Snapshot staging id does not match.');
    }

    final currentId = await backend.read(currentManifestKey);
    final previousId = await backend.read(previousManifestKey);
    final rollbackId = await _firstValidSnapshotId([currentId, previousId]);
    if (rollbackId != null) {
      await backend.write(previousManifestKey, rollbackId);
    }
    await backend.write(currentManifestKey, snapshot.id);
  }

  Future<String?> _firstValidSnapshotId(List<String?> ids) async {
    for (final id in ids) {
      if (id == null || id.isEmpty) continue;
      final raw = await backend.read('$payloadPrefix$id');
      if (raw == null) continue;
      try {
        if (decode(raw).id == id) return id;
      } catch (_) {
        // Keep looking for a valid rollback candidate.
      }
    }
    return null;
  }
}
