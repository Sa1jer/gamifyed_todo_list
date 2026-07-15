# Memory and Allocation Audit

Last updated: 2026-07-15

Static ownership findings and runtime measurements are deliberately separated.
No leak claim is made from source inspection alone.

## Allocation Improvements

- Analytics consumers share bounded immutable snapshots rather than repeatedly
  filtering/grouping/sorting full history and task collections.
- Analytics outputs contain scalar copies and no longer retain `AppState` or
  mutable `Task`, `Skill`, `WeeklyGoal`, or `HistoryEntry` graphs.
- The weekly cache is bounded to eight weeks and clears on epoch change.
- Today Dashboard and TasksPanel construct one prepared view-data object per
  parent rebuild instead of multiple intermediate lists in repeated children.
- Completion/reward coordinators return compact result data and do not cache
  models or closures.
- `SaveScheduler` retains one writer callback, one timer, one in-flight future
  and boolean trailing state; it does not retain snapshot byte buffers.
- Snapshot codec payload maps/bytes are local variables, not service fields.
- Form controllers and listeners have one bounded dialog lifecycle.

## Rebuild Findings

- Local hover/right-rail state has a focused widget boundary and does not call
  broad AppState notifications.
- Expensive weekly analytics construction is outside section/list-item builds.
- The root no longer listens broadly or recreates `MaterialApp` for every
  mutation. `AppStateProvider` propagates feature updates, while
  `AppStateSelector` rebuilds the persistence/tooltips shell only when its
  selected record changes.
- `TasksPanel`, Today, RoadMap and parts of the desktop composition still
  observe the broad AppState facade. Further selector work requires native
  frame/rebuild evidence to avoid speculative state-management churn.
- Hidden responsive branches are selected conditionally; the touched code does
  not eagerly build both mobile and desktop trees.

## Retention Risks Still Open

- Large desktop shells and routes can retain sizeable widget trees while
  visible.
- Flutter engine, native surfaces, fonts/images and Hive buffers are outside
  the Dart object-graph evidence in this audit.
- Public mutable collections mean external code can retain domain references;
  coordinators do not solve ownership at the model API boundary.
- Native route cycling and RoadMap/Statistics open-close scenarios need heap
  snapshots before asserting stable memory.

## Runtime Profiling Protocol

Use a macOS profile build. Record RSS plus DevTools heap snapshots after:

1. idle startup;
2. 20 skill switches;
3. repeated Statistics and Trophies open/close;
4. repeated RoadMap entry/orientation changes;
5. return to idle.

A bounded idle RSS sample proves only that the profile app starts; it does not
prove absence of a leak. Compare retained Dart types and external memory before
changing keep-alive, caches or route ownership. Never force GC or clear caches
on navigation as a substitute for evidence.

## Current Runtime Baseline

On 2026-07-15 the final macOS profile process started successfully and exposed
a VM Service. RSS was `846944 KB` at process age `01:35` and `846976 KB` at
`03:30`, a 32 KB change during the short idle interval. The automation environment could
not foreground the app (`open returned 1`), so route cycling, DevTools heap
snapshots and frame/rebuild traces were not performed. This is an idle baseline,
not a leak verdict.
