# Final Refactor Result

Last updated: 2026-07-18

This closing batch completes the corrective architecture scope that followed
commits `acce9a1`, `dcce010`, and `76891a8`. It preserves product rules, the
AppState public facade, persisted payloads, and the existing state-management
approach.

## Completed Areas

- Desktop Act is now composed from ordinary modules for the shell, sidebar,
  main workspace, selected-skill header, quest rows, right rail, and support
  data. The active desktop workspace entry is a 152-line module rather than a
  2200-line `part`.
- Weekly Analytics is a 293-line shell over detached scalar read data and
  ordinary header, overview, chart, insight, goal, and section modules.
- Progress Hub, Tasks, skill-tree dialogs, and reward/boss dialogs were split at
  cohesive presentation and lifecycle boundaries.
- `StorageService` is a 401-line compatibility facade over snapshot storage,
  migration policy, save scheduling, legacy codecs/domain access, and local
  preferences. Hive keys and payloads are unchanged.
- Analytics invalidation is mutation-aware. Profile, preference, selection,
  persistence-status, and weekly-goal notifications retain the cached core
  analytics snapshot; relevant task, skill, RoadMap, history, and completion
  mutations replace it.
- `MainPage` now receives its `AppState` explicitly and composes workspace,
  profile, tutorial, analytics, and settings through immutable narrow
  projections. Persistence/profile/tutorial notifications no longer rebuild
  the workspace, and event callbacks use the explicit non-observing state.
- Low-level analytics, coordinators, engines, and persistence helpers use
  explicit model-module imports rather than the compatibility barrel.
- Direct Skill/Goal and Review/session coordinator tests and a real-Hive reopen
  test complement the existing completion, reward, snapshot, scheduler, and
  migration coverage.
- Native decoded profile images are bounded to display size, and the root
  overlay disposes replaced `ui.Image` objects, including capture completion
  after the root has unmounted.
- The architecture audit now enforces dependency direction, decomposition line
  budgets, ordinary-module boundaries, migrated selector roots, MainPage's
  observation boundary, and displayed/pubspec version synchronization.

## Quantitative Result

- AppState: approximately 3405 -> 2579 lines across the decomposition program.
- `desktop_workspace.dart`: 2240 -> 152 lines plus ordinary feature modules.
- `weekly_analytics_dialog.dart`: 1571 -> 293 lines plus ordinary sections.
- `progress_hub_dialog.dart`: 1778 -> 467 lines plus ordinary sections.
- `tasks_panel.dart`: 1490 -> 890 lines plus focused task modules.
- `storage_service.dart`: 1306 -> 401 lines plus persistence owners.
- `rewards_bosses_dialogs.dart`: 1326 -> 295 lines plus focused dialogs/cards.
- `skill_tree_dialogs.dart`: 1473 -> 706 lines plus editor/inspector modules.
- Largest remaining production file: AppState at 2579 lines; largest remaining
  presentation file: RoadMap inspector at 1294 lines.

## Behavior And Compatibility

- No XP, completion, Inbox `+10 XP`, recurring, goal, RoadMap, reward, or
  selection semantics changed.
- No Hive schema, type ID, box key, snapshot/manifest rule, or legacy decode
  fallback changed.
- Empty committed snapshots remain authoritative and failed startup loads still
  block automatic destructive saves.
- The existing `models.dart`, AppState, widget entry points, and desktop/mobile
  compositions remain compatible.

## Remaining Evidence-Based Work

- RoadMap still uses its established workspace `part` library. Its active root
  now has a narrow rebuild signal, but converting that entire painter/editor
  library is a separate P1 batch.
- Several presentation files remain close to 1300 lines. The audit prevents
  regression above 1350; further splits need a concrete ownership or profiling
  benefit rather than line-count-only churn.
- Native interactive heap/rebuild profiling and process-kill/disk-full storage
  scenarios remain manual/platform work. Historical RSS samples used different
  process/window evidence and are not a valid before/after comparison; use
  `MAINPAGE_MEMORY_PROFILE.md` for the reproducible scenario.

## Final Validation

- `dart run tool/verify.dart`: passed; 211 files required no formatting,
  analyzer and architecture audit were clean, all 444 tests passed, and
  `git diff --check` passed.
- `flutter build macos --release`: passed; 52.5 MB application bundle.
- `flutter build apk --debug`: passed. Flutter emitted forward-looking Kotlin
  Gradle Plugin and Java 8 compatibility warnings; no build failure occurred.
- The 2026-07-18 `flutter run -d macos --profile` pass identified and activated
  one application process (PID `6152`). Its RSS samples were
  `89648 -> 104272 -> 60688 KB` over approximately nine minutes, with no
  monotonic idle growth. Accessibility automation and DevTools heap snapshots
  were unavailable, so interactive route/dialog retention and memory reduction
  remain unverified.

See `COMPLETION_MATRIX.md` for criterion-level evidence.
