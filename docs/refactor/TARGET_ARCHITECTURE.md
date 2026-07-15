# Target Architecture

Last updated: 2026-07-15

The target is evolutionary: keep `AppState` and persisted payloads compatible
while giving expensive reads, mutation policy, persistence mechanics and
presentation sections explicit owners.

## Dependency Direction

```text
widgets -> AppState facade + presentation/read data
AppState -> coordinators + engines + persistence + device services
coordinators -> models + pure engines/utilities
analytics -> explicit domain inputs -> scalar immutable outputs
persistence facade -> scheduler + store + codec + migration policy
```

The architecture audit rejects analytics outputs that retain live mutable
models, coordinators/persistence importing Flutter UI or AppState, and model
declarations returning to the compatibility barrel.

## Current Runtime Shape

```text
AppState facade
├── CompletionHistoryIndex
├── AnalyticsReadModelCache
├── TaskMutationCoordinator
├── RoadmapMutationCoordinator
├── TaskCompletionCoordinator
├── RewardMutationCoordinator
├── SkillGoalMutationCoordinator
├── ReviewSessionCoordinator
├── SaveScheduler
├── StorageService
└── Notification/SFX/feedback services
```

For a mutation, the preferred flow is:

```text
AppState public method
  -> coordinator with explicit inputs
  -> typed/no-op result
  -> cross-domain/device side effects
  -> one save request
  -> one final notification
```

Coordinators do not call `notifyListeners()` and do not write storage.

## Read Contracts

- Analytics outputs are deeply projected scalar records with unmodifiable
  collections. Builders may read model inputs transiently but outputs do not
  retain them.
- Cache keys are normalized week plus AppState analytics epoch. Cache size is
  bounded and an epoch change clears retained weeks.
- Widget-specific filtering/sorting belongs in a presentation data builder,
  not in repeated list-item builds.
- Time-sensitive builders receive `now` explicitly where deterministic tests
  are required.

## Persistence Contracts

- `SaveScheduler` serializes writes and preserves a trailing request that
  arrives during an in-flight write.
- Flush waits for the full trailing sequence; failures remain observable and
  keep dirty state.
- `SnapshotStore`/codec/migration helpers are internal to `StorageService`.
- Commit marker last, current/previous fallback, authoritative committed empty
  collections and startup failed-load write blocking remain mandatory.
- No coordinator performs independent full-snapshot writes.

## Presentation Contracts

- Mobile and desktop retain different compositions.
- Large shells compose ordinary modules with focused inputs/callbacks where a
  safe boundary exists.
- `shared.dart` is compatibility only; new reusable controls go to the closest
  cohesive module under `widgets/shared/`.
- Controller/listener resources have one lifecycle owner and deterministic
  disposal.
- Remaining `part` migration is incremental and must not be replaced by new
  giant `part` files.

## Next Evolutionary Steps

1. Profile broad feature-level rebuilds and retained routes before extending
   selector use beyond the completed root-shell boundary.
2. Extract desktop sidebar/main composition and the remaining Weekly Analytics
   groups using explicit view data and callbacks.
3. Add real-Hive interrupted-write/restart coverage around the new persistence
   mechanics.
4. Consider moving Flutter visual metadata out of domain models only with a
   separate compatibility/schema plan.

These are follow-ups, not evidence that the completed boundaries are wrappers:
the current coordinators own policy, the persistence helpers own scheduling and
encoding mechanics, and analytics outputs are independent snapshots.
