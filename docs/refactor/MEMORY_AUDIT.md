# Memory and Allocation Audit

Last updated: 2026-07-14

This is a static ownership/allocation audit. No process-memory improvement is
claimed without a native before/after profile.

## Improvements Made

- Three statistics surfaces no longer independently filter, group, normalize,
  and sort the same weekly history/task data during build.
- `AnalyticsReadModel` uses one seven-day completion pass and one task pass.
  Its outputs are immutable and reusable by desktop and mobile/report dialogs.
- `AnalyticsReadModelCache` stores at most eight normalized weeks and clears on
  an explicit analytics epoch change. It cannot grow with unbounded calendar
  browsing.
- Skill lookup is backed by an unmodifiable map pointing at the same summary
  instances already held by the immutable list; it does not duplicate models.
- Snapshot data retains effective `HistoryEntry` references for the selected
  weeks, not copied task/skill object graphs.
- Extracted presentation sections receive prepared summaries and avoid repeated
  local list construction.
- Progress Hub no longer creates a grouped map of weekly entries, per-skill
  entry lists, a filtered today list, or a sorted full-history copy during
  build. Its leader and latest-completion reads reuse bounded snapshots.
- Quest form text/focus resources have one bounded lifecycle owner.

## Staleness and Retention Policy

Relevant task, skill, RoadMap, recurring reset, daily-stat, and history
mutations advance the AppState analytics epoch. Resolution with a new epoch
clears every cached week before rebuilding. Loads and committed empty history
also invalidate the completion and analytics indexes, so a prior snapshot
cannot survive authoritative empty state.

## Remaining Risks

- `AppState` is still broadly watched by several large desktop/mobile surfaces;
  unrelated mutations can rebuild more UI than necessary.
- `desktop_workspace.dart`, RoadMap inspector, and reporting dialogs remain
  large and may retain sizeable widget trees while visible.
- Snapshot serialization and Hive buffers were not changed or measured.
- The observed macOS process size near 1 GB may include Flutter engine, native
  surfaces, image/font caches, and retained routes; static source inspection
  cannot attribute it reliably.
- The unrelated toast geometry change in `shared.dart` was preserved and not
  included in this audit's allocation claims.

## Required Native Profiling

Use a macOS profile build and DevTools Memory view. Record heap snapshots after
startup, repeated Statistics open/close, repeated RoadMap switching, 20+ skill
selection changes, and a return to idle. Compare retained Dart objects and
external memory, then use allocation tracing only for a confirmed growing type.
Do not force GC, clear caches on navigation, or disable keep-alive without this
evidence.
