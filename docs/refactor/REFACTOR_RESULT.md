# Application Decomposition Program Result

Last updated: 2026-07-16

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

- Replaced the desktop Act `part` monolith with ordinary shell, sidebar,
  workspace, quest-row and support modules.
- Reduced Weekly Analytics and Progress Hub to composition shells over focused
  ordinary modules; split Tasks mobile focus, skill-tree and reward/boss
  sections at cohesive boundaries.

## Phase 3 - AppState Domain Decomposition

- Extracted task, RoadMap, completion, reward, skill/goal and review/session
  mutation coordinators behind stable AppState APIs.
- Kept final notification, device side effects and persistence request ordering
  in AppState.
- Reduced AppState from 3405 to 2579 lines across the program (2759 to 2579 in
  the corrective completion batch).
- Added direct coordinator tests for completion, reward, Skill/Goal and
  Review/session plus existing Task and RoadMap suites.

## Phase 4 - Persistence, Models and Hardening

- Split model declarations into cohesive files under `lib/models/`; retained
  `lib/models.dart` as an eight-line compatibility barrel. No serialized shape
  changed.
- Extracted save scheduling, snapshot store access, migration, legacy domain,
  codec and preference ownership from `StorageService`/AppState without
  changing recovery semantics.
- Added scheduler single-flight/trailing/failure tests and snapshot/migration
  fault tests.
- Removed live mutable references from analytics outputs, made ordering
  deterministic, and corrected the stale toast safe-region test.
- Narrowed application-root observation and the high-cost Tasks, Today and
  RoadMap roots with stable selector records/revisions.
- Added `tool/architecture_audit.dart` and made it part of the cross-platform
  verify gate.

## Quantitative Result

| Metric | Result |
|---|---:|
| AppState lines | 3405 -> 2579 |
| Substantial coordinators/indexes/read owners | 11 |
| Persistence owners extracted | 7 |
| Model declaration modules | 8 |
| Presentation monoliths materially decomposed | 14 |
| Direct new coordinator/persistence/read-data test files | 14 |
| Storage schema changes | 0 |
| New dependencies | 0 |

Current large-file measurements and the acceptance status are in
`FINAL_ARCHITECTURE_INVENTORY.md` and `COMPLETION_MATRIX.md`.
