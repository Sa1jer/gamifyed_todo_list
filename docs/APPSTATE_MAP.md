# AppState Map

Last updated: 2026-07-18

`AppState` is the stable runtime facade and final mutation/observation boundary.
It is 2579 lines, down from roughly 3405 at the start of the decomposition
program. Structural owners remain framework-free and do not persist or notify
independently.

## Dependency Direction

```text
widgets
  -> explicit root AppState handoff
  -> projected AppStateSelector boundaries
  -> AppState facade
       -> analytics and prepared read data
       -> coordinators and pure engines
       -> notification/audio/native side effects
       -> SaveScheduler
            -> StorageService
                 -> snapshot / migration / legacy-domain / preference stores
```

## Responsibility Map

| Area | Extracted owner | Facade responsibility |
|---|---|---|
| Task CRUD and Stage links | `TaskMutationCoordinator` | Notifications, boss sync, final commit. |
| Completion, Minimum Action, Inbox and undo | `TaskCompletionCoordinator` | Reward/device effects, history, final commit. |
| Rewards, buffs and chests | `RewardMutationCoordinator` | Cross-domain orchestration and public API. |
| Skill and goal lifecycle | `SkillGoalMutationCoordinator` | Metadata, cleanup side effects, final commit. |
| RoadMap mutations | `RoadmapMutationCoordinator` | Achievements/bosses and final commit. |
| Review/session decisions | `ReviewSessionCoordinator` | Durable review save and publication. |
| Effective completion history | `CompletionHistoryIndex` | History mutation and explicit invalidation. |
| Analytics | `AnalyticsReadModelCache` / weekly builder | Supplies inputs and mutation-aware invalidation. |
| Core feature observation | `coreWorkspaceRevision` | Advances after task/skill/RoadMap mutations. |
| Main shell observation | `MainPage*Projection` boundaries | Separates workspace, profile, tutorial, analytics and settings publications. |
| Save sequencing | `SaveScheduler` | Decides when domain state is dirty. |
| Persistence | `StorageService` plus focused stores/codecs | Startup/recovery and legacy compatibility. |

## Mutation Contract

```text
public AppState method
  -> coordinator validates/mutates explicit collections
  -> AppState applies cross-domain/device effects
  -> _commitMutation classifies analytics/workspace impact
  -> one listener publication
  -> one scheduled persistence request
```

`_commitMutation` invalidates analytics and advances the core workspace signal
by default. Characterized profile, preference, persistence, weekly-goal, and
selection-only paths opt out. Legacy `refresh()` stays conservative because
callers may mutate public model instances before invoking it.

Persistence status can publish `dirty`, `saving`, and `saved` after the domain
publication. MainPage's workspace projection deliberately ignores those
signals; recovery/settings UI observes them separately. The root event listener
is attached directly to the explicit AppState and does not create a rendering
dependency.

## Remaining Facade Work

AppState intentionally still owns startup recovery, achievement/boss/device
side effects, profile/tutorial preferences, calendar resets, debug bulk
normalization, and final save/notification sequencing. These are not permission
for a wholesale rewrite; any extraction needs direct invariants and tests.
