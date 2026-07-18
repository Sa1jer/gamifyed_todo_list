# Storage Reliability Characterization and Recovery Plan

Date: 2026-07-01

Implementation status: Phase 1 (`PersistenceStatus` and recovery UX) and Phase
2 (snapshot/manifest MVP) are implemented. Detailed protocol documentation is
in `docs/STORAGE_SNAPSHOT_MANIFEST.md`.

## Scope and Baseline

The characterization batch reproduced local persistence failures. The
implementation that followed adds an independent snapshot format while keeping
the legacy schema, Hive backend, and legacy boxes intact.

Detected stack:

- Flutter `3.44.3` stable
- Dart `3.12.2`
- DevTools `2.57.0`
- Hive `2.2.3` with `hive_flutter 1.1.0`
- Application version `1.3.64+1`

## Characterized Legacy Flow

`main()` awaits `StorageService.init()`. Initialization opens eleven Hive boxes
sequentially and then runs schema migration. Box-open errors escape startup;
only macOS-style lock error `35` has a bounded retry.

`_RPGAppState.initState()` invokes `AppState.loadSavedData()` without observing
its returned future. `loadSavedData()` sequentially loads skills, tasks,
profile, history, achievements, daily stats, bosses, reward chests, buffs,
weekly goals, best streak, saved markers, UI settings, and tutorial progress.
The method applies the loaded values only after the first group of reads has
completed. A thrown read therefore leaves the initial in-memory state active,
does not set `hasLoadedSavedData`, and has no loading-error/retry UI.

Mutations schedule `_saveAll()` through a 750 ms debounce. The timer invokes
`_writeAll()` with `unawaited`. `pauseBackgroundWork()` also invokes
`flushSaves()` with `unawaited`. Explicit `flushSaves()` propagates errors to its
caller, but the background call sites do not observe them.

`_writeAllUnlocked()` writes sequentially in this order:

1. Theme, sound, tooltips, onboarding, and tutorial progress.
2. Skills and tasks.
3. Profile, history, achievements, and daily stats.
4. Bosses, reward chests, buffs, weekly goals, and best streak.

There is no transaction or commit marker across these units. A later failure
leaves all earlier writes committed.

## Persistence Units

| Unit | Current storage | Replacement behavior | Important nested data |
| --- | --- | --- | --- |
| UI/meta | `meta` box | Per-key overwrite | Theme, sound, onboarding, tutorial, best streak, saved markers |
| Skills | `skills` box | Clear then put by ID | GoalSpec, stages, milestones, completed goals/RoadMaps, list order |
| Tasks | `tasks` box | Clear then put by ID | Skill/stage links, repeat state, subtasks, notification state |
| Profile | `profile` box | Single-key overwrite | XP, avatar/banner bytes, streak protection |
| History | `history` box | Clear then put by ID | Completion history |
| Achievements | `achievements` box | Clear then put by ID | Unlock state and progress |
| Daily stats | `stats` box | Single-key overwrite | Current daily aggregate |
| Bosses | `bosses` box | Clear then put by ID | Boss progress and state |
| Reward chests | `reward_chests` box | Clear then put by ID | Chest state and rewards |
| Buffs | `buffs` box | Clear then put by ID | Active/passive effect state |
| Weekly goals | `weekly_goals` box | Clear then put by ID | Weekly progress |

Skills are the current persistence boundary for RoadMap stages, goal history,
milestones, and reorder data. Task-to-stage consistency spans the skills and
tasks boxes, so it is not atomic today.

## Confirmed Legacy Failure Modes

### Save consistency

- Skills, tasks, history, achievements, bosses, reward chests, buffs, and
  weekly goals clear their box before writing entries one by one.
- Any exception after clear can leave an empty or partial domain snapshot.
- Skills/tasks saved markers are written before destructive replacement.
- Domain methods await Hive calls and explicit flush propagates errors.
- Debounced and lifecycle flush errors can become unhandled asynchronous errors.
- There is no dirty status, retry queue, last-known-good snapshot, validation,
  or rollback.
- Sequential domain saves can commit skills while leaving tasks partial or old,
  breaking links and aggregate consistency.

### Load consistency

- One box-open failure aborts initialization; no fallback storage is selected.
- A malformed individual JSON entry is skipped without discarding valid sibling
  entries. Existing decode-depth and round-trip tests preserve this behavior.
- A partial box is accepted as the complete domain because no manifest records
  expected entry count or snapshot identity.
- One failed domain aborts `loadSavedData()` without an observable app status.
- The UI can continue with initial state after a failed asynchronous load.
- A later flush can overwrite still-recoverable persisted data with that initial
  state. The new characterization test reproduces this behavior.

### Background behavior

- `_writeAll()` serializes concurrent saves and requests one follow-up pass when
  a write arrives in flight, but it does not retain durable dirty state.
- A failed pass completes its future with an error and clears `_saveInFlight`;
  no retry is scheduled.
- A pause flush does not guarantee completion before the lifecycle transition.
- There is no user-visible distinction between loading, dirty, saving, saved,
  load failed, or save failed.

## Fault-Injection Coverage

`test/support/fault_injecting_storage.dart` provides deterministic failures at
operation entry and after N list entries. `test/storage_reliability_test.dart`
currently proves:

- A load failure propagates and `hasLoadedSavedData` remains false.
- Clear-then-write destroys the old domain snapshot before a mid-write failure.
- Skills can commit while the following tasks write remains partial.
- A failed startup load can currently be followed by a destructive flush.
- The desired write guard after failed startup load is skipped with a P1 TODO,
  because the production status/guard does not exist yet.

Next fault coverage should add real temporary Hive boxes for open failure,
write failure, process-interruption simulation, manifest validation, previous
snapshot fallback, and retry idempotency. Native disk-full behavior should be
tested on a disposable filesystem or through an injected writer, not by filling
a developer machine's disk.

## Architecture Options

| Option | Complexity | Delivery risk | Migration | Testability | Rollback | Future sync |
| --- | --- | --- | --- | --- | --- | --- |
| A. Snapshot + manifest | Medium | Medium, isolated behind repository | Add versioned snapshot storage and dual-read; no destructive conversion | High: snapshots and commit marker are deterministic | Load previous committed snapshot | Strong immutable revision boundary |
| B. Per-domain temporary boxes | Medium-high | Higher due to box lifecycle/swap semantics and cross-domain commit | New temp/previous boxes and cleanup policy | Medium; Hive rename/swap behavior is platform-sensitive | Previous box per domain, but mixed-domain commit remains awkward | Acceptable, less coherent than one revision |
| C. Journal | High | High; replay and idempotency are easy to get wrong | Journal schema and compaction | High after substantial infrastructure | Replay/rollback depends on every mutation | Strong for mutation sync, excessive now |
| D. Status + retry only | Low | Low | None | High | No data rollback; only prevents additional damage | Useful UI/repository boundary, not a sync protocol |

## Recommendation

The implemented direction uses D as the safety layer followed by A as the
recoverable storage boundary.

### Phase 1: observable persistence state (implemented)

1. Add a small `PersistenceStatus` state machine: initializing, ready, dirty,
   saving, loadFailed, and saveFailed, with the last error classified for UI.
2. Observe `loadSavedData()` at the app boundary and expose retry without
   presenting an empty state as successfully loaded.
3. Block all automatic/destructive writes after startup load failure until load
   succeeds or the user explicitly chooses a non-destructive recovery action.
4. Observe debounced and pause flush failures, keep dirty state, and provide a
   bounded explicit retry. Do not silently mark data saved.
5. Keep the existing schema and `StorageService` implementation unchanged in
   this phase except for narrow seams needed by tests.

### Phase 2: snapshot and manifest (implemented MVP)

1. Serialize one versioned application snapshot with a unique revision ID,
   timestamp, expected sections/counts, and checksum or deterministic validation.
2. Write the candidate snapshot to temporary storage and read it back for
   validation.
3. Commit by writing the manifest pointer last.
4. Retain the previous committed snapshot as last-known-good.
5. On startup, load the latest valid committed revision; fall back to previous
   on missing, corrupt, or incomplete candidate data.
6. Keep legacy box loading as a dual-read migration path. Create a snapshot only
   after a complete legacy load; never clear legacy data during rollout.

### Phase 3: operational hardening

1. Add retention and cleanup only after multiple releases prove rollback.
2. Add CI fault matrices for every commit boundary and schema version.
3. Add exportable diagnostics without task/profile text or raw private data.
4. Revisit a journal only if future sync requires mutation-level conflict
   resolution; do not combine it with the snapshot rollout.

## Migration and Rollback

- No schema migration is performed in this characterization batch.
- The snapshot batch should be additive: read committed snapshots first, then
  fall back to current boxes.
- The first snapshot must be written only after every legacy domain loads.
- A failed snapshot write must leave the manifest and previous revision intact.
- Rolling back the app must remain possible while legacy boxes are retained.
- Cleanup of legacy boxes requires a later explicit migration decision and
  telemetry/manual verification; it must never happen during recovery.

## Manual Recovery UX

On open/load failure, keep the app in a recovery screen rather than showing an
empty working state. Offer retry and a safe diagnostic/export path. Once
snapshot support exists, explain whether the latest or previous successful
snapshot was loaded. Never auto-clear boxes, delete the failed candidate, or
replace readable data merely to make startup succeed. Destructive reset, if it
is ever offered, must be a separate confirmed action with backup/export first.

## Tests Required Before Implementation

- Persistence status transitions for successful and failed load/save/retry.
- No save call after failed startup load.
- Dirty state survives a failed background and pause flush.
- Concurrent mutations during a failed/retried save are not lost.
- Candidate snapshot interruption before and after every write boundary.
- Manifest is committed last and never points to an invalid snapshot.
- Latest invalid snapshot falls back to previous committed snapshot.
- Legacy dual-read creates a snapshot only after complete successful load.
- Corrupted individual entries continue to skip only the bad entry.
- RoadMap stage IDs, task links, goal history, milestones, and ordering survive
  snapshot round-trip and rollback.
- Real Hive temporary-directory tests plus Android, iOS, macOS, and Windows
  restart smoke tests before release.

## Next Implementation Batch

Add real-Hive restart/process-interruption integration tests and a conservative
retention policy. Keep encryption, export/backup policy, and legacy cleanup as
separate reviewed decisions.
