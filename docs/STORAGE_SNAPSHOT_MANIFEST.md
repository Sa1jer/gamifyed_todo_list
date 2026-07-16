# Storage Snapshot and Manifest

Date: 2026-07-01

## Purpose

The snapshot store makes a multi-domain save visible only after its complete
payload has been written and validated. It uses Hive through the existing
`StorageService`; no database package or cloud service was added.

## Storage Layout

Production snapshots use the `storage_snapshots` Hive box.

- `payload:<snapshot-id>` stores one immutable full-app snapshot.
- `manifest_current` points to the latest committed snapshot.
- `manifest_previous` points to the last valid rollback snapshot.
- Payloads without a manifest pointer are uncommitted staging data.

The snapshot format is versioned independently with
`kStorageSnapshotVersion`. Version 1 contains:

- Snapshot ID and UTC creation time.
- Skills, including RoadMap stages, goal history, milestones, and ordering.
- Tasks and their skill/stage links.
- Profile, history, achievements, daily stats, bosses, reward chests, buffs,
  weekly goals, and best streak.
- Theme, sound, tooltip, onboarding, and tutorial settings.
- Per-list domain counts used during validation.

Persistence status and debug-only storage are not included.

## Commit Protocol

1. AppState captures the complete in-memory state as one `StorageSnapshot`.
2. StorageService serializes and validates it in memory.
3. The payload is written to `payload:<id>` without changing either manifest.
4. The payload is read back and decoded again.
5. The current and previous manifests are inspected for the latest valid
   rollback candidate.
6. `manifest_previous` is updated to that valid candidate when one exists.
7. `manifest_current` is written last. Only this write commits the snapshot.
8. AppState clears dirty state and records `lastSuccessfulSaveAt` only after
   the manifest write succeeds.

An interrupted payload write, failed read-back, invalid payload, or manifest
failure leaves the previous committed snapshot loadable. Uncommitted payloads
are retained for now and are never selected during load.

## Load and Fallback Protocol

1. Read `manifest_current` and validate its referenced payload.
2. If current is missing or invalid, validate `manifest_previous`.
3. If either candidate is valid, hydrate AppState from it without reading
   legacy domain boxes.
4. If neither candidate is valid, load the existing legacy boxes.
5. After a complete successful legacy load, commit the first snapshot.
6. If snapshot and legacy loading both fail, enter `loadFailed`; normal editing
   and every automatic save remain blocked until retry succeeds.

Snapshot validation requires a supported version, non-empty matching snapshot
ID, valid timestamp, every required domain, matching list counts, decodable
payloads, and unique non-empty skill/task IDs. Existing model decoders retain
their current defaults and compatibility behavior.

## Legacy Migration and Rollback

Migration is additive. Existing boxes are neither cleared nor deleted. A first
snapshot is written only after all legacy domains have loaded and AppState has
completed its existing normalization.

After the first snapshot, new saves target the snapshot box. Legacy boxes are
therefore a preserved pre-migration source, not a continuously updated mirror.
Rolling back to an older app may show that older legacy state; do not remove the
snapshot box during rollback. A future export/restore tool should understand
both formats before any legacy cleanup is considered.

## Recovery UX

- Startup and box-open failures show a blocking Russian recovery card.
- Retry repeats `StorageService.init()` and the complete load flow.
- Raw exception details are hidden under “Подробнее” in debug builds only.
- Failed startup load cannot trigger a destructive flush.
- Runtime save failures keep dirty state and show a retryable banner.
- Debounced and lifecycle saves attach their error handler immediately and
  reflect failures through `PersistenceStatus` instead of leaking an unhandled
  asynchronous error.

## Security and Privacy

Snapshots remain app-private Hive data and contain the same personal content as
legacy boxes. They are not encrypted at rest. Encryption/key management,
platform backup policy, and user export are separate release decisions. Error
copy never exposes paths or raw exceptions outside debug mode. Recovery never
deletes user data.

## Known Limitations

- Snapshot payloads use structural validation and domain counts, not a
  cryptographic checksum.
- Old/uncommitted payload retention is unbounded until a later conservative
  cleanup policy is implemented.
- Native process-kill and real disk-full tests are not automated yet.
- The snapshot does not store app version/build metadata.
- No user-facing selector exists for manually choosing an older snapshot.
- Legacy boxes are retained but not dual-written after migration.

## Test Strategy

Automated tests cover payload-before-manifest ordering, interrupted staging,
manifest failure, previous fallback, invalid count rejection, legacy migration,
snapshot-first loading, commit retry, failed-load write gating, observed
background errors, initialization retry, and responsive recovery/save UI.

Native restart, process-kill, disk-full, backup/export, retention, and eventual
legacy cleanup remain separate release-hardening work.

## Implementation Ownership

`StorageService` remains the stable compatibility facade used by AppState and
tests. The closing decomposition did not change a box name, key, serialized
field, enum fallback, or snapshot version. Its collaborators now own distinct
mechanics:

- `SnapshotStore` owns current/previous manifest commit and fallback.
- `StorageSnapshotCodec` owns full-snapshot encoding and structural decoding.
- `StorageMigrationPolicy` decides snapshot-first versus legacy fallback.
- `LegacyHiveDomainStore` owns legacy entity-box reads and writes.
- `LegacyStorageCodec` owns legacy entity encoding/decoding and guarded JSON
  primitives.
- `HivePreferenceStore` owns theme, sound, tooltip, onboarding, tutorial,
  profile image and other preference keys.
- `SaveScheduler` remains the AppState-facing debounce/in-flight coordinator.

`test/storage_service_reopen_test.dart` uses a disposable real Hive directory,
closes all boxes, creates a new `StorageService`, and verifies three
process-like boundaries: legacy plus committed snapshot recovery, corrupt
current snapshot fallback to previous, and authoritative committed empty
collections despite stale legacy data. This is stronger than an in-memory
mock, but it is not a substitute for an actual OS process kill or disk-full
test.
