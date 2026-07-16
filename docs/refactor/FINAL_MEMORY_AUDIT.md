# Final Memory Audit

Last updated: 2026-07-16

## Static Improvements

- Analytics caches retain bounded scalar data and no AppState/live model graph.
- Selective invalidation avoids rebuilding large snapshots for profile,
  preference, selection, persistence-progress, and weekly-goal notifications.
- Tasks, Today, and RoadMap roots no longer broadly observe every AppState
  notification; callbacks use non-observing reads.
- Desktop/weekly/progress/task extraction makes heavy sibling construction and
  controller ownership visible at section boundaries.
- Root overlay `ui.Image` instances are disposed when replaced or unmounted.
- Profile banner/avatar decode targets are bounded by display size and device
  pixel ratio instead of always retaining full source resolution.
- Save scheduling and storage codecs keep transient payload buffers local and
  bounded; no unbounded cache was added.

## Current Evidence

The previous macOS profile idle sample was approximately `846944 KB -> 846976
KB` over two minutes. It ruled out an obvious short idle runaway but did not
prove an improvement or the absence of interaction leaks.

On 2026-07-16 the closing batch launched the current application with
`flutter run -d macos --profile`. The main process remained alive and its RSS
was sampled at `22688 KB` and `23264 KB`, a `576 KB` increase over the control
interval. This is evidence against an immediate idle runaway in that run, not
a before/after memory improvement claim. Flutter reported `open returned 1`,
so the application could not be foregrounded from the execution environment;
interactive route cycling and DevTools heap snapshots were not performed.

## Required Native Profile Scenario

Measure the same build before and after repeated skill switches, RoadMap
open/close, Statistics/Trophies dialogs, Inbox expansion, quest forms, and
theme changes. Capture DevTools heap snapshots after returning to idle and
compare retained controllers, decoded images, overlay images, external memory,
and route objects. Do not force GC or clear caches to manufacture a result.

Static ownership review and the idle sample cannot replace this native pass,
especially on Windows and Android.
