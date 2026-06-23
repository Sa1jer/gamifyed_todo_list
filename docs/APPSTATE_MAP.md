# AppState Map

Last updated: 2026-06-23

This document maps the current responsibilities and mutation boundaries inside
`AppState`. It is a planning artifact for safe decomposition, not a refactor
commit. The app remains local-first; no cloud/Firebase implementation is
introduced by this document.

## Current Shape

- `lib/app_state.dart` is the main runtime facade: roughly 2700 lines.
- `StorageService` owns Hive/local persistence and schema migration.
- Existing pure engines already cover some evaluation/layout concerns:
  `BossEngine`, `CourseNudgeEngine`, `GoalEngine`, `ProgressEngine`,
  `RecurringEngine`, `ReviewEngine`, `RoadmapEngine`.
- `AppState` still orchestrates mutations, persistence, notifications,
  history, rewards/effects, achievements, tutorial state and reset timers.

## Responsibility Map

| Area | Current AppState role | Current boundary |
|---|---|---|
| Storage lifecycle | Loads all boxes through `StorageService`, normalizes loaded data, debounces full saves through `_saveAll` / `flushSaves`. | `StorageService` is separated from UI, but `AppState` decides when every domain is saved. |
| UI settings | Owns theme, sound, tooltip setting, profile setting mutations. | Low-risk, mostly direct meta saves and `notifyListeners`. |
| Tutorial/session | Owns `TutorialProgress`, onboarding fallback, active tutorial step/module selection and course-nudge session dismiss. | Persisted in meta except course-nudge dismiss, which is runtime-only. |
| Skills/goals | Owns skill CRUD, selected skill, goal review writes and checklist compatibility. | Goal quality is mostly evaluated outside AppState, but mutations live inside AppState. |
| RoadMap/stages | Owns stage CRUD, template application, path extension/insertion, mastery, task unlinking on stage deletion. | `RoadmapEngine` already handles template/layout helpers; AppState still mutates graph data. |
| Tasks | Owns task CRUD, task update, subtask toggles, tree node normalization and notification sync. | Central mutation point; good future sync observation boundary. |
| Completion/minimum/undo | Owns XP, streaks, daily stats, history, buffs, rewards, bosses, achievements, tutorial progression and notifications. | Highest-risk orchestration zone. Do not extract before characterization tests. |
| History/stats | Owns history insertion, undo entries, daily stats, cached completion maps and cache invalidation. | History mutation points are narrow: load, `_addHistory`, debug bulk normalization. |
| Achievements | Owns hardcoded unlock checks, definition compatibility and pending achievement notifications. | Best first extraction candidate because evaluation can be pure. |
| Rewards/effects | Owns chest unlocks, buff creation/consumption/restoration, source-key idempotency and undo rollback. | Medium/high risk because it is coupled to completion and history. |
| Resistance | Uses `BossEngine` for sync but owns reward/achievement side effects after boss defeat. | Engine boundary exists; side effects remain in AppState. |
| Notifications | Owns task notification scheduling/canceling through `NotificationService`. | Local-device side effect; future sync should not depend on notification state. |
| Debug bulk normalization | `normalizeAfterBulkStateChange` repairs state after debug scenarios and saves. | Debug code calls AppState, but production AppState does not import debug code. |

## Mutation Boundary Map

| Method group | Main mutations | Side effects and boundaries |
|---|---|---|
| `loadSavedData` | Replaces all in-memory lists/settings from storage, ensures definitions, syncs bosses/notifications. | Invalidates history caches, may immediate-save normalized state, then notifies. |
| `_saveAll` / `_writeAllUnlocked` | Writes every persisted domain. | Debounced full-write pipeline; no per-entity save boundary yet. |
| UI settings toggles | Theme, sound, tooltips. | Direct meta save + notify. Sound also updates `SfxService`. |
| Tutorial methods | `TutorialProgress`, `onboardingSeen`, replay flags. | Persist tutorial progress/meta and notify. Uses `DateTime.now()` for `updatedAt`. |
| `checkResets` / `_resetExpiredTasks` | Repeating task reset state, streak protection, daily stats. | Can notify/save from background timer. Time-sensitive. |
| Weekly goals | `weeklyGoals`, key result completion timestamps. | Updates `updatedAt`, saves, notifies. |
| `completeTask` | Task completion, XP/profile/skill, streaks, daily stats, history, buffs, rewards, bosses, achievements, tutorial. | Syncs notification, notifies, full save. High-risk extraction zone. |
| `completeMinimumAction` | Minimum progress, optional repeating completion, XP/profile/skill, stats/history for repeating tasks, bosses/achievements/tutorial. | Syncs notification, notifies, full save. High-risk extraction zone. |
| `uncompleteTask` | Reverts task/profile/skill XP, history rollback entry, buffs, rewards, bosses, notification. | Uses history and reward rollback helpers. High-risk extraction zone. |
| Skill CRUD | `skills`, selected skill, linked tasks on delete. | Checks achievements, syncs bosses, notifies/saves. |
| RoadMap/stage CRUD | `Skill.treeNodes`, stage prerequisites/checklists/mastery, task `treeNodeId` cleanup. | Syncs bosses, checks achievements on mastery, notifies/saves. |
| Task CRUD | `tasks`, task timestamps, repeat resets, notifications. | Syncs task notification, notifies/saves. |
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

## Extraction Risk Map

### Low Risk

- `AchievementEngine`: pure evaluation from a snapshot to achievement ids.
  AppState can keep mutation and pending-notification behavior.
- Additional read-only progress/review evaluators, following the existing
  engine pattern.

### Medium Risk

- `RewardEngine`: chest/buff decisions, `sourceKey` idempotency and buff
  previews. Needs careful undo tests before mutation extraction.
- RoadMap mutation helper: template merge/prerequisite validation can become a
  pure helper, but AppState should still own actual skill mutation at first.
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

Start with `AchievementEngine`.

Implementation direction:

- Add an `AchievementEngineSnapshot` with only the data needed for evaluation:
  total completed tasks, best streak, profile level, skill count, fully
  completed checklist signal and defeated resistance signal.
- Add a pure engine method that returns achievement ids to unlock.
- Keep `_unlockAchievement` and pending notification mutation in `AppState`.
- Replace hardcoded `_checkAchievements` conditions with snapshot + engine
  output.
- Add characterization tests before replacement so achievement behavior stays
  unchanged.

Do not start with task completion, rewards or save pipeline extraction.
