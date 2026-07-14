# Architecture Inventory

Last updated: 2026-07-14

This is a measured inventory for incremental decomposition. It does not
authorize product, persistence, state-management, or visual changes. The
supported baseline is Flutter `3.44.3` with Dart `3.12.2`.

## Layer Map

| Layer | Current owners |
|---|---|
| Startup/runtime facade | `lib/main.dart`, `lib/app_state.dart`, `lib/app_state/provider.dart` |
| Mutation policy | `lib/coordinators/task_mutation_coordinator.dart`, `lib/coordinators/roadmap_mutation_coordinator.dart` |
| Models and rules | `lib/models.dart`, `lib/engines/` |
| Derived analytics | `lib/analytics/analytics_read_model.dart` |
| Persistence | `lib/storage_service.dart`, `lib/storage_snapshot.dart`, `lib/persistence_status.dart` |
| Device side effects | `lib/notification_service.dart`, `lib/sfx_service.dart`, `lib/feedback_service.dart` |
| Presentation | `lib/widgets/`, `lib/presentation/`, `lib/theme/` |
| Regression suite | `test/` |

`AppState` remains the public mutation facade. Coordinators mutate explicitly
provided collections/entities and return simple results; `AppState` retains
notification, persistence, reward, achievement, and final `notifyListeners()`
ordering.

## Batch 2 Baseline

The Batch 2 baseline already contained the uncommitted
`CompletionHistoryIndex` extraction from the preceding safe phase. The largest
15 Dart files were:

| Lines | File |
|---:|---|
| 3405 | `lib/app_state.dart` |
| 3199 | `lib/widgets/main_page/desktop_workspace.dart` |
| 2454 | `lib/widgets/weekly_analytics_dialog.dart` |
| 2096 | `lib/widgets/shared.dart` |
| 1942 | `lib/widgets/tasks_panel.dart` |
| 1809 | `lib/widgets/progress_hub_dialog.dart` |
| 1786 | `lib/widgets/today_dashboard.dart` |
| 1730 | `lib/widgets/mastery_map/inspector.dart` |
| 1565 | `lib/widgets/dialogs/rewards_bosses_dialogs.dart` |
| 1514 | `lib/storage_service.dart` |
| 1473 | `lib/widgets/dialogs/skill_tree_dialogs.dart` |
| 1377 | `lib/widgets/dialogs/task_dialog.dart` |
| 1305 | `lib/widgets/main_page/desktop_statistics_workspace.dart` |
| 1289 | `lib/widgets/main_page/mobile_journal.dart` |
| 1214 | `lib/widgets/main_page/shell.dart` |

`lib/widgets/shared.dart` has an unrelated user-owned toast geometry diff. It
was measured but not edited by this refactor.

## Current Largest Files

| Lines | File |
|---:|---|
| 3199 | `lib/widgets/main_page/desktop_workspace.dart` |
| 3138 | `lib/app_state.dart` |
| 2383 | `lib/widgets/weekly_analytics_dialog.dart` |
| 2096 | `lib/widgets/shared.dart` |
| 1942 | `lib/widgets/tasks_panel.dart` |
| 1763 | `lib/widgets/progress_hub_dialog.dart` |
| 1786 | `lib/widgets/today_dashboard.dart` |
| 1730 | `lib/widgets/mastery_map/inspector.dart` |
| 1565 | `lib/widgets/dialogs/rewards_bosses_dialogs.dart` |
| 1514 | `lib/storage_service.dart` |
| 1473 | `lib/widgets/dialogs/skill_tree_dialogs.dart` |
| 1367 | `lib/widgets/dialogs/task_dialog.dart` |
| 1219 | `lib/widgets/dialogs/skill_dialogs.dart` |
| 1214 | `lib/widgets/main_page/shell.dart` |
| 1205 | `lib/widgets/statistics_calendar_dialog.dart` |

File size remains a signal, not a defect. The batch removed responsibility
from three overloaded presentation files rather than selecting trivial files
to satisfy a count.

## Implemented Boundaries

### Completion and analytics reads

- `CompletionHistoryIndex` owns effective completion indexing and bounded
  immutable history caches.
- `AnalyticsReadModel` performs one weekly history pass and one task pass,
  builds immutable day/skill summaries, and offers O(1) skill lookup.
- `AnalyticsReadModelCache` is bounded to eight weeks. `AppState` advances its
  analytics epoch for task, skill, RoadMap, recurring-reset, daily-stat, and
  completion-history mutations. Theme/profile-only changes do not invalidate
  it.
- Desktop Statistics, Weekly Analytics, and Progress Hub consume the shared
  snapshot instead of maintaining duplicate grouping/filtering code.
- Progress Hub reads its daily summary, activity leader, and latest recorded
  completion from the shared indexes; it no longer groups weekly entries or
  sorts all history during `build()`.

### Presentation ownership

- `mobile_journal_sections.dart` owns momentum, skill overview cards, goal
  rings, and empty skills presentation.
- `desktop_statistics_sections.dart` owns the summary strip and analytics
  panel.
- `TaskFormController` is the single owner of quest-form text controllers and
  the minimum-action focus node.

These are normal public/private Dart modules, not permanent `part` fragments.

### Mutation policy

- `TaskMutationCoordinator` owns add/update/remove/subtask policy, recurrence
  reset rules, Inbox isolation, Stage-ID normalization, and typed side-effect
  hints.
- `RoadmapMutationCoordinator` owns Stage graph mutation, path reorder,
  template merge, stage insertion/removal, prerequisite cleanup, and task link
  cleanup.
- `AppState` retains orchestration, notification scheduling/cancellation,
  analytics invalidation, boss/reward/achievement effects, save scheduling,
  and the single final notification.

## Remaining High-Risk Ownership

| Priority | Area | Reason |
|---|---|---|
| P1 | Completion/minimum/undo | XP, history, stats, effects, rewards, bosses, achievements, tutorial, notification, and undo ordering remain coupled. |
| P1 | Reward/effect decisions | Idempotent source keys and undo rollback need characterization before extraction. |
| P1 | Persistence lifecycle | Startup recovery, authoritative empty snapshots, debounce, flush, and failed-load write blocking require fault injection. |
| P1 | Native memory/rebuild evidence | Static allocation improvements are implemented, but broad `AppState` watches and large retained desktop screens still need profile evidence. |
| P2 | Remaining presentation monoliths | `desktop_workspace.dart`, `weekly_analytics_dialog.dart`, `tasks_panel.dart`, and RoadMap inspector need feature-scoped decomposition, not cosmetic file splitting. |

## Explicit Non-Goals

- No Hive/schema/snapshot, XP, Goal, recurring, RoadMap, reward, or completion
  semantic changes.
- No state-management/DI migration, package upgrade, visual redesign, or bulk
  folder move.
- No deletion of legacy or apparently unreachable code without caller and
  runtime evidence.
