# Application Decomposition Batch 2 Result

Last updated: 2026-07-14

## Phase 1 — Analytics Read Models

- Added `AnalyticsReadModel` and bounded `AnalyticsReadModelCache`.
- Moved weekly completion grouping, XP aggregation, task counts, Stage
  progress, sorting, and skill lookup out of widgets/AppState getters.
- Migrated Desktop Statistics, Weekly Analytics, and Progress Hub.
- Preserved existing history, Goal progress, Inbox exclusion, and date/week
  semantics.
- Added direct analytics equivalence/cache tests.

## Phase 2 — Presentation Decomposition

- Extracted mobile journal momentum, skill overview, goal ring, and empty state
  into `mobile_journal_sections.dart` (`mobile_journal.dart`: 1289 -> 872).
- Extracted desktop statistics summary and analytics panel into
  `desktop_statistics_sections.dart`
  (`desktop_statistics_workspace.dart`: 1305 -> 1051).
- Extracted quest form text/focus lifecycle to `TaskFormController`
  (`task_dialog.dart`: 1377 -> 1367).
- Preserved visual composition, callbacks, navigation, and responsive behavior.

## Phase 3 — AppState Domain Decomposition

- Added `TaskMutationCoordinator` for quest normalization, CRUD, subtask,
  recurrence, Inbox, and Stage-link policy.
- Added `RoadmapMutationCoordinator` for Stage graph CRUD, path reorder,
  template merge, prerequisite and linked-task cleanup.
- Kept the public AppState API and centralized notification/save/listener
  ordering.
- `app_state.dart`: approximately 3405 -> 3138 lines in Batch 2 (about 3510 ->
  3138 across the two consecutive decomposition batches).

## Phase 4 — Logic, Readability, Rebuild, and Memory Hardening

- Completed analytics invalidation for skill, RoadMap, recurring reset,
  daily-stat, and history mutations.
- Avoided save/notify work after no-op task/Stage removal.
- Preserved cancellation of stale Inbox notifications after normalization.
- Added O(1) snapshot skill lookup without duplicate model copies.
- Removed Progress Hub's per-build weekly grouping, today filtering, and
  full-history sorting by extending the immutable analytics/history reads.
- Verified controller/listener ownership and documented remaining profile-only
  memory questions.

## Quantitative Result

- Substantial coordinators/engines extracted across the program: 4
  (`CompletionHistoryIndex`, analytics read model/cache, task coordinator,
  RoadMap coordinator).
- Presentation monoliths decomposed in Batch 2: 3.
- New focused presentation components: 5 public section/card components plus
  private focused subcomponents.
- Large form lifecycle owners separated: 1.
- Duplicate analytics implementations removed: 3 consumer paths now share one
  model.
- Confirmed logic issues fixed: 5.
- Persisted schema/model changes: 0.
- New dependencies: 0.

## Validation and Known Failure

The final focused analytics/coordinator/AppState run passed 101/101 tests and
`flutter analyze` reported no issues. The complete suite passed 389 tests and
retained one known failure: the `mobile_journal_tokens_test.dart` bottom bound
expected `<= 588` while the current toast resolves to `672`. That failure
predates Batch 2 and is associated with a separate uncommitted toast-size
change in `lib/widgets/shared.dart`; this refactor deliberately does not modify
it. Consequently `dart run tool/verify.dart` exits with code 1 at that same
test after its format and analyze stages pass. The macOS release build
completed successfully at 52.4 MB.

Independent review found two analytics-equivalence defects before acceptance:
historical entries for a deleted skill were omitted from weekly summaries, and
the leading-skill tie-break had changed from AppState skill order to alphabetic
order. The builder now retains historical-only summaries and computes the
current leading skill before presentation sorting; direct regression tests
cover both cases.

See `ARCHITECTURE_INVENTORY.md`, `LOGIC_AND_READABILITY_AUDIT.md`, and
`MEMORY_AUDIT.md` for remaining risks and evidence limits.
