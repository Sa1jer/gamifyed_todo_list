# Logic and Readability Audit

Last updated: 2026-07-14

## Scope

The audit covered analytics reads, task CRUD/update/subtask paths, RoadMap
Stage/template/path mutations, the extracted mobile/statistics sections, and
quest-form controller lifecycle. Completion/minimum/undo and persistence were
read for boundary preservation but not refactored.

## Confirmed Fixes

1. **Analytics invalidation was incomplete during extraction.** Skill
   add/update/remove, new goal RoadMap, recurring reset, and relevant Stage
   mutations now invalidate the analytics epoch. Regression tests prove cached
   snapshots are replaced and do not retain stale names/colors, Stage progress,
   or active repeating-task counts.
2. **No-op removals scheduled work.** Missing task or Stage removals now return
   before save/notification orchestration.
3. **Inbox update could leave a stale scheduled notification.** The task
   coordinator reports when normalization disables notification state;
   `AppState` performs the existing cancellation side effect.
4. **Deleted-skill history disappeared from weekly analytics.** The immutable
   snapshot now appends historical-only skill summaries from completion entries
   without reviving them as current skills.
5. **Leading-skill ties changed behavior.** The first version sorted skill
   summaries alphabetically before selecting the leader. The builder now
   preserves AppState skill order for equal-XP current skills, then applies
   presentation sorting to the independent summary list.

## Repeated Read Work Removed

- Progress Hub no longer groups weekly history by skill on every build. The
  analytics builder computes the activity leader once with the existing XP,
  then completion-count tie-break.
- Progress Hub no longer filters and sorts the complete history to find the
  latest recorded completion. `CompletionHistoryIndex` records that reference
  during its existing indexed pass.
- Daily and weekly story totals now come from the immutable analytics snapshot
  rather than additional filtered lists and folds.

## Preserved Invariants

- Inbox tasks remain outside skill XP, Stage links, and structured analytics.
- Existing completed minimum-action text is not silently discarded by an empty
  edit value.
- Leaving repeating behavior clears streak/reset state; editing an already
  completed repeating quest recalculates its next reset.
- Deleting a Stage removes prerequisite references and clears linked task
  `treeNodeId` values with an explicit timestamp.
- Template application preserves linked extra stages and guards graph cycles.
- `AppState` remains the only owner of save scheduling and final
  `notifyListeners()` calls for extracted mutations.

## Lifecycle Ownership

`TaskFormController` exclusively owns five `TextEditingController` instances
and one `FocusNode`. It removes listeners and disposes every resource once. The
dialog owns and disposes this controller; no resource was moved into AppState or
given application lifetime.

## Ambiguous or Deferred

- Completion/minimum/undo contains many cross-domain effects. No bug was fixed
  without direct characterization.
- Reward/effect source-key and rollback sequencing remains coupled and needs a
  dedicated deterministic audit.
- Persistence save failures and startup lifecycle need real-Hive fault
  injection; this batch did not alter their semantics.
- Remaining broad `AppState` watches are a performance hypothesis until native
  profile evidence identifies expensive rebuilds.
