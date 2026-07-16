# Logic and Readability Audit

Last updated: 2026-07-16

## Scope

The audit covers analytics projections, task/skill/goal/RoadMap/review
mutations, completion/minimum/undo, rewards/buffs/chests, persistence
scheduling/snapshot helpers, task-form lifecycle and the decomposed
presentation paths.

## Confirmed Fixes

1. Weekly analytics formerly retained `AppState`, `Task`, `Skill` and
   `WeeklyGoal`. It now returns scalar immutable records built from explicit
   inputs.
2. Analytics history entries formerly retained mutable `HistoryEntry`
   references. `AnalyticsHistoryRecord` now copies the fields used by readers.
3. `isCurrentSkill` actually meant “the skill still exists”; it is now
   `isExistingSkill`. Full activity-leader ties have an explicit stable ID
   tie-break.
4. Analytics invalidation is classified at the central mutation boundary.
   Relevant domain mutations invalidate by default; characterized profile,
   preference, persistence, selection and weekly-goal-only paths opt out.
5. Completion and reward extraction preserves quick-task isolation, consumed
   buff IDs, source-key idempotency and undo restoration in typed results.
6. Skill deletion still clears linked tasks, rewards, buffs, bosses,
   notification IDs and a stale selected skill through explicit result data.
7. Save debounce/single-flight/trailing-write state moved from AppState to one
   scheduler. Flush waits for trailing work and errors are not swallowed.
8. A stale toast test asserted a hard-coded old widget height. It now checks
   the actual safe-region invariant using the production estimated height; the
   user-owned toast geometry itself was not reverted.
9. TasksPanel no longer repeats partition/sort logic in build. Completed and
   archived ordering has a deterministic task-ID tie-break.
10. Missing boss removal is a true no-op, and startup reset changes use the
    same single commit/save/notification path as other mutations.
11. Skill/Goal and Review/session coordinators now have direct no-op,
    normalization and cleanup coverage.

## Preserved Invariants

- Inbox completion grants its existing isolated reward and does not update
  skill XP, RoadMap or goal progress.
- Completion/undo mutations remain idempotent at the AppState facade and keep
  persistence/notification order.
- Stage removal cleans prerequisites and linked task IDs.
- Unknown selections are rejected; deletion cannot leave the removed skill
  active.
- Committed empty snapshot collections remain authoritative.
- A failed startup load continues to block destructive automatic saves.
- Storage schema and serialized field names are unchanged.

## Lifecycle Ownership

- `TaskFormController` owns text controllers, focus nodes, form selections and
  their listeners; the dialog disposes the controller once.
- `SaveScheduler` owns its debounce timer and in-flight/trailing state and is
  disposed by AppState.
- Extracted presentation widgets do not acquire application-lifetime
  controllers or timers.

## Ambiguous Findings

- Public mutable model/list ownership still permits callers holding references
  after coordinator insertion. Changing that requires a larger API and storage
  compatibility plan.
- Lower-priority feature observers remain broad by design until native rebuild
  traces demonstrate a useful selector boundary.
- Skill and achievement models still contain Flutter visual metadata. That is
  a known layering compromise, not a new regression.
- Existing RoadMap/secondary-workspace `part` libraries are bounded
  compatibility areas; no new giant `part` shell was introduced.
