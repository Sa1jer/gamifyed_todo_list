# Final Memory Audit

Last updated: 2026-07-15

## Static Improvements

- Analytics caches retain bounded scalar snapshots, not AppState or mutable
  domain graphs.
- The weekly cache keeps at most eight weeks and clears on epoch change.
- Today Dashboard and TasksPanel prepare lists once per parent rebuild instead
  of repeatedly filtering and sorting in child sections.
- Save scheduling does not retain encoded payload buffers; codec maps and byte
  arrays remain local to a write.
- Extracted form controllers and listeners have one dialog lifecycle owner.
- Extracted coordinators hold no caches, widget contexts or long-lived
  closures over presentation state.
- The root shell selects only persistence/tooltips data instead of rebuilding
  `MaterialApp` for every AppState mutation; selector replacement and
  unrelated-notification behavior have direct widget coverage.

## What Static Review Cannot Prove

No source audit or successful build proves the absence of a native/Dart heap
leak. Flutter engine surfaces, fonts, images, plugins and Hive/native buffers
need runtime evidence.

## Measured Baseline

The macOS profile app started and exposed a VM Service. RSS measured `846944
KB` at `01:35` and `846976 KB` at `03:30`. The 32 KB short idle delta does not
show runaway idle growth, but the app could not be foregrounded by the
automation environment, so interactive route cycling and heap snapshots remain
unverified.

## Required Native Profile Pass

On macOS profile mode, record RSS and DevTools heap snapshots at idle, after
skill switching, repeated Statistics/Trophies open-close, RoadMap cycling and
return to idle. Compare retained Dart classes and external memory. Do not force
GC or clear navigation caches to manufacture a result.

The full static findings and protocol are in `MEMORY_AUDIT.md`.
