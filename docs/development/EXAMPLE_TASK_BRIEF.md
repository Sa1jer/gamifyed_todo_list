# Example: authoritative empty snapshot recovery

> Educational example only. It does **not** assert that this defect currently
> exists in RPG To-Do.

## Problem

After a successful snapshot recovery containing committed empty history, a
derived in-memory history view could theoretically retain stale data from an
earlier session.

## Acceptance criteria

- [ ] A committed empty history snapshot clears its derived history view.
- [ ] Invalid or failed snapshots do not clear recoverable in-memory state.
- [ ] No automatic save occurs after a failed startup load.
- [ ] Existing legacy and manifest fallback behavior remains unchanged.

## Non-goals

- No Hive schema migration, snapshot format change, export feature, or AppState
  refactor.

## Plan

1. Read [docs/STORAGE_SNAPSHOT_MANIFEST.md](../STORAGE_SNAPSHOT_MANIFEST.md),
   `StorageService`, `AppState`, and storage regression tests.
2. Add a deterministic test that loads an authoritative empty snapshot after a
   populated state and observes the derived view.
3. Make the smallest invalidation fix at the existing load boundary.
4. Test failed-load write gating and legacy fallback as neighboring boundaries.
5. Run the standard validation gate and record manual restart limits.

## Review focus

- Snapshot commit marker ordering and previous-manifest fallback.
- Difference between an authoritative empty collection and a failed/unknown
  load.
- Startup/dispose or debounce save races.
- Whether the fix accidentally changes persisted payloads.

## Verification

Use [ACCEPTANCE_TEMPLATE.md](ACCEPTANCE_TEMPLATE.md), the focused storage tests,
and the normal format/analyze/test/diff gate. Native process-kill behavior is
marked `not verified` unless it is actually exercised.
