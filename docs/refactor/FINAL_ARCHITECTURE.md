# Final Architecture

Last updated: 2026-07-15

## Runtime Shape

```text
Platform-specific widgets
        |
        v
AppStateProvider / narrow root-shell selector
        |
        v
AppState public facade and feature observation boundary
        |
        +--> immutable analytics/presentation builders
        +--> mutation coordinators and pure engines
        +--> device side effects
        +--> SaveScheduler
                 |
                 v
          StorageService
                 |
                 +--> SnapshotStore
                 +--> StorageSnapshotCodec
                 +--> StorageMigrationPolicy
```

The dependency direction is one-way. Read models do not retain `AppState` or
mutable domain graphs. Coordinators do not import widgets, notify listeners or
write storage. Persistence helpers do not know presentation state.

## Stable Compatibility Boundaries

- `AppState` remains the public API used by existing widgets.
- `lib/models.dart` remains the import barrel for persisted models.
- Hive type IDs, payload keys and snapshot/manifest behavior are unchanged.
- `StorageService` remains the startup/recovery facade.
- Desktop and mobile remain different compositions over shared domain rules.

## Cache and Invalidation Policy

Analytics snapshots are recomputable, bounded and scalar. AppState invalidates
them at the public notification boundary. This is intentionally conservative:
it prevents stale results even when a new mutation path forgets a specialized
epoch call. It may recompute after unrelated notifications, which should be
optimized only after rebuild profiling.

## Presentation Policy

Large pages should compose feature sections with explicit data and callbacks.
Heavy sorting/grouping belongs in deterministic presentation builders rather
than repeated item builds. Controllers, focus nodes, timers and subscriptions
have one lifecycle owner. Compatibility exports are temporary migration aids,
not a reason to add new catch-all components.

## Evolution Rules

1. Preserve the facade and schema while extracting one characterized domain.
2. Return simple typed mutation results for cross-domain cleanup.
3. Keep final save and notification sequencing explicit.
4. Replace `part` boundaries incrementally with ordinary modules.
5. Extend selectors beyond the root shell only after native rebuild evidence
   identifies a valuable feature boundary; do not migrate state management as
   a shortcut.
