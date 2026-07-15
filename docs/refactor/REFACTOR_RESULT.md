# Application Decomposition Program Result

Last updated: 2026-07-15

This result covers the consecutive decomposition commits plus the corrective
completion batch. It does not claim that every large file has disappeared.

## Phase 1 - Analytics and Read Models

- Extracted completion-history indexing and bounded base analytics snapshots.
- Replaced Weekly Analytics' live `AppState`/model graph with explicit scalar
  `WeeklyAnalyticsViewData`.
- Migrated Statistics, Weekly Analytics, Progress Hub, Today Dashboard and
  TasksPanel calculations to shared or feature read data.
- Added direct equivalence, immutability, tie-break and stale-cache coverage.

## Phase 2 - Presentation Decomposition

- Extracted mobile journal and desktop statistics sections.
- Extracted desktop selected-skill header and right rail as ordinary modules.
- Extracted Weekly Analytics shared sections and weekly-goal editor.
- Extracted Today Dashboard sections/view data and TasksPanel partition data.
- Extracted task form controller/sections and RoadMap/boss/task tiles in the
  preceding batch.
- Split shared surfaces, buttons, progress/badges, dashed border, form and
  motion controls while retaining compatibility exports.

The remaining desktop and Weekly Analytics shells are explicitly listed as P1
follow-ups; this batch did not hide them behind more `part` files.

## Phase 3 - AppState Domain Decomposition

- Extracted task, RoadMap, completion, reward, skill/goal and review/session
  mutation coordinators behind stable AppState APIs.
- Kept final notification, device side effects and persistence request ordering
  in AppState.
- Reduced AppState from 3405 to 2592 lines across the program (2759 to 2592 in
  the corrective completion batch).
- Added direct coordinator tests for completion/reward plus existing task and
  RoadMap coordinator suites.

## Phase 4 - Persistence, Models and Hardening

- Split model declarations into cohesive files under `lib/models/`; retained
  `lib/models.dart` as an eight-line compatibility barrel. No serialized shape
  changed.
- Extracted save scheduling, snapshot store access, codec and migration policy
  from `StorageService`/AppState without changing recovery semantics.
- Added scheduler single-flight/trailing/failure tests and snapshot/migration
  fault tests.
- Removed live mutable references from analytics outputs, made ordering
  deterministic, and corrected the stale toast safe-region test.
- Narrowed application-root observation with `AppStateSelector` while keeping
  existing feature notification behavior through `InheritedNotifier`.
- Added `tool/architecture_audit.dart` and made it part of the cross-platform
  verify gate.

## Quantitative Result

| Metric | Result |
|---|---:|
| AppState lines | 3405 -> 2592 |
| Substantial coordinators/indexes/read owners | 11 |
| Persistence owners extracted | 4 |
| Model declaration modules | 8 |
| Presentation monoliths materially decomposed | 9 |
| Direct new coordinator/persistence/read-data test files | 11 |
| Storage schema changes | 0 |
| New dependencies | 0 |

Current large-file measurements and the acceptance status are in
`FINAL_ARCHITECTURE_INVENTORY.md` and `COMPLETION_MATRIX.md`.
