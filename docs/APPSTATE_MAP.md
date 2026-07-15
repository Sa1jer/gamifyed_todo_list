# AppState Map

Last updated: 2026-07-15

`AppState` remains the public runtime facade and final observation boundary. It
is currently 2591 lines, down from roughly 3405 at the start of the
decomposition program. Coordinators do not write storage and do not notify
widgets; the facade applies cross-domain side effects, schedules persistence,
then calls `notifyListeners()` once.

## Dependency Direction

```text
widgets
  -> AppStateProvider (InheritedNotifier)
       -> AppStateSelector for narrow shell projections
       -> AppState facade for feature-level observation
       -> coordinators / engines / read-model builders
       -> NotificationService and other device side effects
       -> SaveScheduler -> StorageService
                              -> SnapshotStore / codec / migration policy
```

Persisted model declarations live in `lib/models/`. `lib/models.dart` is the
compatibility barrel, so existing imports and Hive payloads remain valid.

## Responsibility Map

| Area | Extracted owner | AppState responsibility |
|---|---|---|
| Task CRUD and Stage links | `TaskMutationCoordinator` | Device notification, boss sync, save and final notification. |
| Completion, Minimum Action and undo | `TaskCompletionCoordinator` | Supplies current inputs, applies returned reward/device effects, saves and notifies. |
| Rewards, buffs and chests | `RewardMutationCoordinator` | Coordinates completion/undo calls and exposes stable public APIs. |
| Skill and goal lifecycle | `SkillGoalMutationCoordinator` | Applies presentation metadata, cross-domain cleanup, save and final notification. |
| RoadMap mutations | `RoadmapMutationCoordinator` | Achievement/boss side effects, analytics invalidation, save and notification. |
| Review/session state | `ReviewSessionCoordinator` | Persists durable review changes and publishes the final state. |
| Effective history | `CompletionHistoryIndex` | Owns history mutation and invalidates the index through the facade boundary. |
| Analytics | `AnalyticsReadModelCache` and weekly builder | Supplies scalar inputs and invalidates conservatively at `notifyListeners()`. |
| Save scheduling | `SaveScheduler` | Decides when a mutation requires persistence and owns startup recovery policy. |
| Snapshot storage | `StorageService` plus persistence helpers | Startup/load status, failed-load write blocking and legacy compatibility. |

## Mutation Contract

The intended public flow is:

```text
AppState method
  -> coordinator validates and mutates explicit domain collections
  -> typed result describes cleanup/side effects
  -> AppState applies device/cross-domain effects
  -> one persistence request
  -> one final notification
```

No coordinator imports widgets, calls `notifyListeners()`, or writes Hive.
`SaveScheduler` serializes debounce, single-flight and trailing writes; a
failed startup load still blocks automatic destructive saves.

## Remaining Facade Responsibilities

The facade intentionally still owns application orchestration that crosses
several domains:

- startup normalization and recovery status;
- achievements and resistance/boss side effects;
- notification service calls;
- profile, tutorial and preference mutations;
- reset/calendar orchestration;
- debug bulk normalization;
- final save/notification sequencing.

These are not permission for a wholesale rewrite. Future extraction requires
characterization coverage and must preserve the facade API.

## Known Risks

- Public mutable collections/models still allow reference aliasing outside the
  facade. Fixing ownership requires a separate compatibility plan.
- The application root observes only persistence/tooltips shell data through
  `AppStateSelector`, so ordinary domain notifications do not rebuild
  `MaterialApp`. Several feature roots still intentionally observe broad
  `AppState` changes and require profile evidence before narrower projections.
- Conservative analytics invalidation favors correctness and can rebuild a
  snapshot after an unrelated preference notification.
- Native notification and startup lifecycle side effects are not pure and need
  platform-level verification in addition to unit tests.

For current file sizes, acceptance status and remaining work, see
`docs/refactor/FINAL_ARCHITECTURE_INVENTORY.md` and
`docs/refactor/COMPLETION_MATRIX.md`.
