# Final Memory Audit

Last updated: 2026-07-18

## Static Improvements

- Analytics caches retain bounded scalar data and no AppState/live model graph.
- Selective invalidation avoids rebuilding large snapshots for profile,
  preference, selection, persistence-progress, and weekly-goal notifications.
- MainPage no longer broadly observes every AppState notification. Workspace,
  profile, tutorial, analytics and settings use separate projections, so
  persistence progress does not recreate high-cost workspace roots.
- Desktop/weekly/progress/task extraction makes heavy sibling construction and
  controller ownership visible at section boundaries.
- Root overlay `ui.Image` instances are disposed when replaced, unmounted, or
  returned from an in-flight capture after unmount.
- Profile banner/avatar decode targets are bounded by display size and device
  pixel ratio instead of always retaining full source resolution.
- Save scheduling and storage codecs keep transient payload buffers local and
  bounded; no unbounded cache was added.

## Current Evidence

The historical samples `846944 -> 846976 KB` and `22688 -> 23264 KB` were
captured with different PID/window/scenario evidence. They are not comparable
and do not demonstrate a memory improvement. At most, each is evidence against
obvious short-interval linear growth in the sampled process.

The 2026-07-18 profile pass identified one visible profile executable (PID
`6152`) and recorded `89648 -> 104272 -> 60688 KB` RSS over approximately nine
minutes. The same window was successfully activated, and the non-monotonic
samples provide evidence against an idle runaway leak in that run. Accessibility
automation and DevTools heap snapshots were unavailable, so this is not a
navigation/dialog retention test and does not demonstrate a memory reduction.

## Required Native Profile Scenario

Measure the same build before and after repeated skill switches, RoadMap
open/close, Statistics/Trophies dialogs, Inbox expansion, quest forms, and
theme changes. Capture DevTools heap snapshots after returning to idle and
compare retained controllers, decoded images, overlay images, external memory,
and route objects. Do not force GC or clear caches to manufacture a result.

Static ownership review and the idle sample cannot replace this native pass,
especially on Windows and Android.

The exact comparable measurement contract and navigation loop are documented
in `MAINPAGE_MEMORY_PROFILE.md`.
