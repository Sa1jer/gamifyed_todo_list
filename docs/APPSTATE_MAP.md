# AppState Map

Last updated: 2026-07-14

This document maps the current responsibilities and mutation boundaries inside
`AppState`. The app remains local-first; no cloud/Firebase implementation is
introduced by these internal boundaries.

## Current Shape

- `lib/app_state.dart` is the main runtime facade: roughly 3138 lines.
- `StorageService` owns Hive/local persistence and schema migration.
- Pure engines/read models cover evaluation, layout, effective completion
  indexing, and shared analytics. Task and RoadMap coordinators own cohesive
  mutation policy while remaining unaware of widgets, storage, and listeners.
- `AppState` still orchestrates mutations, persistence, notifications,
  history, rewards/effects, achievements, tutorial state and reset timers.

## Responsibility Map

| Area | Current AppState role | Current boundary |
|---|---|---|
| Storage lifecycle | Loads all boxes through `StorageService`, normalizes loaded data, debounces full saves through `_saveAll` / `flushSaves`. | `StorageService` is separated from UI, but `AppState` decides when every domain is saved. |
| UI settings | Owns theme, sound, tooltip setting, profile setting mutations. | Low-risk, mostly direct meta saves and `notifyListeners`. |
| Tutorial/session | Owns `TutorialProgress`, onboarding fallback, active tutorial step/module selection and course-nudge session dismiss. | Persisted in meta except course-nudge dismiss, which is runtime-only. |
| Skills/goals | Owns skill CRUD, selected skill, goal review writes and checklist compatibility. | Goal quality is mostly evaluated outside AppState, but mutations live inside AppState. |
| RoadMap/stages | Delegates Stage CRUD, template application, path extension/insertion, reorder and link cleanup, then applies cross-domain side effects. | `RoadmapMutationCoordinator` owns graph mutation policy; AppState retains achievements, bosses, analytics invalidation, save and notify ordering. |
| Tasks | Delegates task CRUD/update/subtask normalization and applies notification/boss/persistence side effects. | `TaskMutationCoordinator` owns entity/collection policy; AppState remains the public observation boundary. |
| Completion/minimum/undo | Owns XP, streaks, daily stats, history, buffs, rewards, bosses, achievements, tutorial progression and notifications. | Highest-risk orchestration zone. Do not extract before characterization tests. |
| History/stats | Owns history insertion, undo entries, daily stats and explicit cache invalidation. | `CompletionHistoryIndex` owns effective-completion indexing; `AnalyticsReadModelCache` owns bounded weekly snapshots used by three reporting consumers. |
| Achievements | Owns hardcoded unlock checks, definition compatibility and pending achievement notifications. | Best first extraction candidate because evaluation can be pure. |
| Rewards/effects | Owns chest unlocks, buff creation/consumption/restoration, source-key idempotency and undo rollback. | Medium/high risk because it is coupled to completion and history. |
| Resistance | Uses `BossEngine` for sync but owns reward/achievement side effects after boss defeat. | Engine boundary exists; side effects remain in AppState. |
| Notifications | Owns task notification scheduling/canceling through `NotificationService`. | Local-device side effect; future sync should not depend on notification state. |
| Debug bulk normalization | `normalizeAfterBulkStateChange` repairs state after debug scenarios and saves. | Debug code calls AppState, but production AppState does not import debug code. |

Selection now rejects unknown skill IDs and exposes an explicit
`clearSkillSelection()` path while retaining the legacy toggle behavior of
`selectSkill`. `activeSkillCount` excludes the permanent Inbox skill.

## Mutation Boundary Map

| Method group | Main mutations | Side effects and boundaries |
|---|---|---|
| `loadSavedData` | Replaces all in-memory lists/settings from storage, ensures definitions, syncs bosses/notifications. | Invalidates history caches, may immediate-save normalized state, then notifies. |
| `_saveAll` / `_writeAllUnlocked` | Writes every persisted domain. | Debounced full-write pipeline; no per-entity save boundary yet. |
| UI settings toggles | Theme, sound, tooltips. | Direct meta save + notify. Sound also updates `SfxService`. |
| Tutorial methods | `TutorialProgress`, `onboardingSeen`, replay flags. | Persist tutorial progress/meta and notify. Uses `DateTime.now()` for `updatedAt`. |
| `checkResets` / `_resetExpiredTasks` | Repeating task reset state, streak protection, daily stats. | Can notify/save from background timer. Missed periods use bounded calendar arithmetic rather than one loop per period. |
| Weekly goals | `weeklyGoals`, key result completion timestamps. | Updates `updatedAt`, saves, notifies. |
| `completeTask` | Task completion, XP/profile/skill, streaks, daily stats, history, buffs, rewards, bosses, achievements, tutorial. | Syncs notification, notifies, full save. High-risk extraction zone. |
| `completeMinimumAction` | Minimum progress, optional repeating completion, XP/profile/skill, stats/history for repeating tasks, bosses/achievements/tutorial. | Syncs notification, notifies, full save. High-risk extraction zone. |
| `uncompleteTask` | Reverts task/profile/skill XP, history rollback entry, buffs, rewards, bosses, notification. | Uses history and reward rollback helpers. High-risk extraction zone. |
| Skill CRUD | `skills`, selected skill, linked tasks on delete. | Checks achievements, syncs bosses, notifies/saves. |
| RoadMap/stage CRUD | Coordinator mutates `Skill.treeNodes`, prerequisites/checklists and task `treeNodeId` cleanup. | AppState syncs bosses, invalidates analytics, checks achievements on mastery, then notifies/saves once. |
| Task CRUD | Coordinator mutates tasks, timestamps, recurrence and Stage links. | AppState syncs/cancels device notification, bosses and analytics, then notifies/saves once. |
| Rewards/effects | `rewardChests`, `buffs`, pending notifications. | Uses `sourceKey` for idempotency; creates time-limited effects. |
| `normalizeAfterBulkStateChange` | Repairs achievements, bosses, stats, best streak, history cache after debug scenarios. | Saves and notifies; keep as debug/support boundary for now. |

## Future Cloud Boundary Notes

The future sync boundary should be planned without implementing Firebase/cloud.

### Syncable entities

- `Skill`, including `GoalSpec`, goal reviews and RoadMap `SkillTreeNode`s.
- `Task`, including completion state, repeat settings, minimum progress,
  description and RoadMap link.
- `HistoryEntry`, daily stats and weekly goals.
- `Achievement` state, reward chests, buffs and bosses.
- `UserProfile`.
- User preferences/tutorial state can remain per-device at first, unless a
  future account system explicitly wants preference sync.

### Current strengths

- Most persisted domain entities have stable `id` values.
- `Task`, `GoalSpec` and `WeeklyGoal` have `updatedAt`.
- `RewardChest.sourceKey` and `Buff.sourceKey` already protect some reward
  idempotency.
- Debug state is isolated in a separate `__debug__` box and production storage
  does not know about it.
- Storage is already centralized in `StorageService`; widgets do not write Hive.

### Current gaps to keep visible

- `Skill` and `SkillTreeNode` do not have entity-level `updatedAt`; nested
  RoadMap changes are currently observed only through full skill save.
- `Achievement`, `RewardChest`, `Buff`, `Boss` and `HistoryEntry` do not all
  expose uniform `createdAt/updatedAt` conflict metadata.
- `DateTime.now()` is used directly in many mutation paths. This is acceptable
  local-first, but future sync/conflict resolution should introduce an
  injectable clock/snapshot at extraction boundaries.
- `_saveAll` persists whole domains, not individual changed entities. Future
  sync can still observe AppState mutations, but per-entity dirty tracking does
  not exist yet.
- Notification scheduling is a local-device side effect and should remain
  outside any future shared cloud state.
- Snapshot loads treat an empty history as authoritative and invalidate derived
  history caches, preventing stale analytics after recovery/reload.

## Extraction Risk Map

### Low Risk

- `AchievementEngine`: completed in `1.3.45` as pure evaluation from a snapshot
  to achievement ids. AppState keeps mutation and pending-notification behavior.
- `CompletionHistoryIndex`: extracted as a read-only effective-completion index.
  AppState still owns history mutation and explicit invalidation after loads,
  history writes and bulk normalization.
- `AnalyticsReadModel`: immutable weekly/day/skill summaries with an explicit,
  bounded epoch cache and three migrated consumers.
- `TaskMutationCoordinator` and `RoadmapMutationCoordinator`: explicit mutation
  policy behind the stable AppState facade; they do not persist or notify.

### Medium Risk

- `RewardEngine`: chest/buff decisions, `sourceKey` idempotency and buff
  previews. Needs careful undo tests before mutation extraction.
- Further skill lifecycle extraction: deletion and selection cleanup still span
  tasks, notifications, achievements, bosses and persistence.
- `StorageMigrationEngine`: useful later, but migration changes require
  compatibility tests.

### High Risk

- `TaskCompletionEngine`: completion, minimum and undo touch XP, skills,
  profile, history, stats, buffs, rewards, bosses, achievements, tutorial and
  notifications.
- Save pipeline decomposition: `_saveAll` is central and should not be changed
  without a storage boundary plan.
- Debug scenario mutation extraction: scenarios intentionally mutate many
  domains and should stay debug-only.

## Recommended Next Batch

Characterize `RewardEngine` decisions without extracting mutation yet. See
[`refactor/ARCHITECTURE_INVENTORY.md`](refactor/ARCHITECTURE_INVENTORY.md) and
[`refactor/TARGET_ARCHITECTURE.md`](refactor/TARGET_ARCHITECTURE.md).

Implementation direction:

- First add characterization tests around chest creation, effect grants,
  `sourceKey` idempotency, undo rollback and pending reward/effect
  notifications.
- Extract pure reward decisions only where AppState can keep mutation, history
  and notification side effects.
- Keep task completion, minimum action and undo orchestration in AppState until
  stronger coverage exists.

Do not start with task completion orchestration or save pipeline extraction.
