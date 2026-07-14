# Target Architecture

Last updated: 2026-07-14

The target is evolutionary: keep the public `AppState` facade and persisted
models stable while narrow, tested owners replace embedded responsibilities.

## Dependency Direction

```text
widgets -> AppState facade + immutable read models
AppState -> coordinators + engines + storage/device services
coordinators -> models + pure engines/utilities
analytics/engines -> models + pure utilities
storage -> models + snapshot codecs
```

Forbidden directions include coordinators/engines importing widgets or
`AppState`, widgets writing Hive, storage invoking UI, and presentation code
reimplementing domain calculations.

## Implemented Evolutionary Boundaries

```text
AppState
├── CompletionHistoryIndex        effective completion reads/cache
├── AnalyticsReadModelCache       bounded immutable analytics snapshots
├── TaskMutationCoordinator       quest collection/entity mutation policy
├── RoadmapMutationCoordinator    Stage graph and link mutation policy
├── StorageService                unchanged snapshot/legacy persistence
└── NotificationService           unchanged local-device side effects

Presentation
├── MobileJournal                 page composition
│   └── MobileJournalSections     momentum/cards/empty state
├── DesktopStatisticsWorkspace    workspace composition
│   └── DesktopStatisticsSections summary/analytics sections
└── TaskDialog
    └── TaskFormController        text/focus lifecycle ownership
```

`AppState` acknowledges coordinator results, performs cross-domain side
effects, schedules one save, and sends one final notification. Coordinators do
not persist or notify.

## Runtime Contracts

### Immutable analytics

- Inputs are explicit skills, tasks, effective completion index, daily stats,
  total completions, and week start.
- Outputs are unmodifiable day/skill/entry collections and scalar summaries.
- Cache key is `(analytics epoch, normalized week start)` and is bounded to
  eight weeks.
- Relevant mutations advance the epoch; unrelated UI preferences do not.
- The cache references effective history entries but does not duplicate full
  task/skill collections.

### Mutation coordinators

- Mutation rules receive concrete mutable entities/collections and explicit
  `now` when timestamps are required.
- Results report whether mutation occurred and any notification/skill sync
  hints.
- `AppState` remains the compatibility facade and final side-effect owner.
- No-op results must not schedule saves or notifications.

### Presentation

- Mobile and desktop keep intentionally different compositions.
- Extracted sections receive focused inputs/callbacks rather than full mutable
  lists where practical.
- Controllers, focus nodes, timers, and animation resources have one closest
  widget/controller owner and deterministic disposal.
- Extraction uses ordinary modules, not permanent `part` fragmentation.

### Persistence and lifecycle

- Snapshot/manifest commit order, previous fallback, failed-load write block,
  and authoritative committed empty collections are unchanged.
- Save debounce, lifecycle flush, and startup recovery remain coordinated by
  `AppState` until a dedicated fault-injection batch proves a smaller owner.

## Completed Migration Sequence

1. Inventory and completion-history indexing.
2. Shared immutable analytics read model and three migrated consumers.
3. Three presentation boundaries, including independent form resource
   ownership.
4. Task and RoadMap mutation coordinators behind stable `AppState` APIs.
5. Logic/allocation hardening: complete analytics invalidation, bounded cache,
   no-op mutation suppression, and stale Inbox notification cancellation.

## Next Safe Sequence

1. Characterize reward/effect grant and undo idempotency before extracting
   decisions.
2. Decompose one coherent region of `desktop_workspace.dart` with geometry and
   pointer regression coverage.
3. Profile broad `AppState` rebuilds and retained desktop workspaces before
   adding selectors or changing keep-alive behavior.
4. Treat persistence lifecycle decomposition as a separate real-Hive
   fault-injection batch.

Do not start with completion/minimum/undo orchestration or the save pipeline.

## Exit Criteria for Later Extractions

- Public behavior and persisted data stay compatible.
- Normal, empty, stale/invalid, and relevant boundary cases are covered.
- Mutation ordering, save scheduling, and notification ownership remain
  explicit.
- Format/analyze/focused tests pass; unrelated failures are identified with
  evidence rather than hidden.
- Documentation names the actual owner and unresolved risk.
