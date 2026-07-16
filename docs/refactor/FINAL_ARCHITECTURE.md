# Final Architecture

Last updated: 2026-07-16

## Runtime Dependency Direction

```text
platform composition
  -> AppStateProvider / focused AppStateSelector
  -> AppState compatibility facade
       -> immutable read-data builders
       -> pure engines / mutation coordinators
       -> device side effects
       -> SaveScheduler
            -> StorageService compatibility facade
                 -> snapshot, migration, legacy-domain and preference owners
```

Widgets do not import persistence. Analytics, coordinators, engines, and
persistence helpers use narrow model-module imports. Coordinators never notify
widgets or write storage; AppState applies cross-domain side effects and owns
the final save/notification boundary.

## Observation And Cache Policy

`AppStateProvider` remains the compatibility notifier. High-cost Tasks, Today,
and RoadMap feature roots select `coreWorkspaceRevision` plus the small local
values they render, then use `AppStateProvider.read` for callbacks. The revision
advances for task, skill, completion, and RoadMap mutations, not for profile,
preference, persistence-status, weekly-goal, or selection-only changes.

Analytics invalidation follows the same mutation boundary but is independent
from presentation selection. `_commitMutation` defaults to conservative
analytics invalidation; explicitly characterized unrelated mutations opt out.
This keeps new domain paths safe by default without discarding snapshots for
every listener notification.

## Persistence Boundary

`StorageService` owns box lifecycle and compatibility orchestration. Payload
encoding, legacy domain access, local preferences, committed snapshot storage,
migration policy, and save scheduling have focused owners. No helper knows
AppState or widgets, and no helper independently notifies presentation.

## Compatibility Rules

- Keep AppState as the public facade until a separately characterized API
  migration exists.
- Keep `models.dart` as a presentation/legacy compatibility barrel; low-level
  code imports concrete model modules.
- Do not change Hive keys, type IDs, snapshot semantics, or authoritative-empty
  behavior during structural refactors.
- Desktop and mobile remain platform-appropriate compositions over shared
  domain rules.
- Add an audit rule before declaring a new extraction boundary complete.
