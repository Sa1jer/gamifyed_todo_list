# Stability And SOLID Architecture Audit

Last updated: 2026-07-06

## Scope And Baseline

This audit covers application stability, state synchronization, async and
lifecycle ownership, persistence boundaries, major presentation systems,
performance risks, dead code, and evidence-based SOLID compliance.

Baseline at `0d36f4c` (`1.3.53`) was clean:

- Flutter `3.44.3`, Dart `3.12.2`, DevTools `2.57.0`.
- `dart format lib test`: 114 files, no changes.
- `flutter analyze`: no findings.
- `flutter test -r expanded --timeout 30s`: `316/316` passed.
- `dart fix --dry-run`: nothing to fix.
- `git diff --check`: clean.

No persistence schema, XP formula, RoadMap graph rule, or state-management
framework changed in this batch.

## System Map

```text
main.dart / RPGApp
  -> MainPage and adaptive workspaces
     -> AppStateProvider
        -> AppState (application facade and mutation coordinator)
           -> pure engines (goal, progress, roadmap, achievement, boss, review)
           -> StorageService
              -> SnapshotBackend -> Hive snapshot box
              -> legacy Hive domain boxes
           -> NotificationService / SfxService

Widgets -> AppState queries and commands
Engines -> models and focused pure helpers
Storage -> models, snapshot codec and Hive
Models -> shared value helpers
```

There is no import cycle between UI, AppState, engines, and storage. During
this batch the shared priority rule was deliberately placed in
`engines/task_ordering.dart`; putting it in `utils.dart` would have created a
`models.dart <-> utils.dart` cycle.

## Risk Summary

| Priority | Finding | Result |
|---|---|---|
| P0 | Data-loss, crash, hard infinite loop | No new reproducible P0 found. Snapshot/manifest and failed-load write guards remain in place. |
| P1 | Empty committed history did not clear stale in-memory history | Fixed; committed empty state is authoritative and cache is invalidated. |
| P1 | Root startup could continue loading after `RPGApp.dispose` | Fixed with a mounted boundary after storage initialization and in its error path. |
| P1 | `selectSkill` accepted missing IDs | Fixed; stale IDs are rejected and explicit clear is available. |
| P1 | Profile active-skill count included permanent Inbox | Fixed; only RoadMap/user skills are counted. |
| P1 | Old Flutter SDKs reported `onReorderItem` source errors | Project now requires Flutter `>=3.44.3 <4.0.0`; Windows SDK alignment is documented. |
| P2 | Repeat catch-up could perform up to 3,700 synchronous iterations per task | Replaced with calendar arithmetic and at most one correction step. |
| P2 | Priority and week-boundary rules were duplicated | Centralized as pure helpers with unit coverage. |
| P2 | Mobile bottom navigation depended on all AppState for one flag | It now receives the focused `reducedMotion` value. |
| P2 | Goal deadline evaluation depended directly on wall clock | Optional `now` input added for deterministic engine tests. |
| P3 | Legacy desktop `TopBar` branch was unreachable | Dead 596-line header removed; live mobile navigation extracted and retained. |

## SOLID Matrix

### Single Responsibility Principle

#### AppState

- **Verdict:** VIOLATED, with improving boundaries.
- **Example:** `lib/app_state.dart`, `AppState`, owns profile, skills, tasks,
  completion/undo, tutorial, rewards, achievements, notifications, reset
  timers, persistence scheduling and recovery status.
- **Future risk:** changing completion or persistence can regress unrelated
  rewards, history, notification, or tutorial behavior.
- **Minimal refactor in this batch:** no wholesale split. Pure recurrence
  catch-up and task ordering remain outside mutation orchestration; selection
  invariants were narrowed in place.
- **Verification:** AppState selection/count tests, repeat helper tests, full
  completion/undo suite.

#### MainPage

- **Verdict:** PARTIALLY COMPLIANT.
- **Example:** `_MainPageState` composes workspaces and also coordinates
  tutorial overlays, reward notices, dialogs, debug entry and RoadMap focus.
- **Future risk:** navigation and tutorial changes can interact through shared
  ephemeral flags.
- **Minimal refactor:** the unreachable legacy header was removed while the
  live mobile navigation was isolated in `mobile_workspace_nav.dart`.
- **Verification:** compact mobile shell and desktop shell widget tests.

#### StorageService

- **Verdict:** PARTIALLY COMPLIANT.
- **Example:** it opens Hive, migrates legacy payloads, encodes domains, and
  implements snapshot commit/rollback.
- **Future risk:** future schema growth increases codec and migration pressure.
- **Minimal refactor:** none in this batch; changing the proven snapshot
  protocol during a global audit would be unsafe.
- **Verification:** storage service, snapshot manifest, and fault-injection
  suites.

#### RoadMap

- **Verdict:** PARTIALLY COMPLIANT.
- **Example:** `mastery_map/canvas.dart` coordinates layout output, camera,
  template visibility, painter composition, and interactions.
- **Future risk:** more canvas editing modes could restart camera work or make
  selection ownership ambiguous.
- **Minimal refactor:** rejected here. Existing signature-based camera-fit
  guard and controller disposal are correct and tested.
- **Verification:** one/two/ten-stage camera tests, branch and orientation tests.

#### Statistics

- **Verdict:** PARTIALLY COMPLIANT.
- **Example:** desktop and dialog presentations derive overlapping weekly
  views from history.
- **Future risk:** date boundaries and totals can drift between surfaces.
- **Minimal refactor:** shared Monday boundary only; a full
  `StatisticsSnapshot` extraction is deferred until profiling proves value.
- **Verification:** week-boundary unit tests and existing statistics widgets.

### Open/Closed Principle

#### Closed domain enums

- **Verdict:** COMPLIANT.
- **Example:** exhaustive switches for `WorkspaceMode`, `TaskType`,
  `RepeatFrequency`, milestone and RoadMap status are local and compiler-safe.
- **Future risk:** low while variants remain closed.
- **Minimal refactor:** none; replacing exhaustive switches with polymorphism
  would add ceremony without reducing change scope.
- **Verification:** analyzer exhaustiveness and existing variant tests.

#### Task ordering

- **Verdict:** was VIOLATED, now COMPLIANT for the shared priority rule.
- **Example:** Today, weekly analytics, and course nudges each duplicated the
  same high/medium/low rank.
- **Future risk:** one surface could invert or extend ordering differently.
- **Minimal refactor:** `engines/task_ordering.dart` exposes one pure resolver.
- **Verification:** ordering unit test and CourseNudge regression suite.

### Liskov Substitution Principle

#### SnapshotBackend

- **Verdict:** COMPLIANT.
- **Example:** Hive and in-memory/failing backends preserve read/write Future
  contracts; failures propagate to the persistence status boundary.
- **Future risk:** a backend that silently drops writes would violate snapshot
  validation assumptions.
- **Minimal refactor:** none.
- **Verification:** interrupted payload, manifest failure, corruption fallback.

#### StorageService test substitutes

- **Verdict:** PARTIALLY COMPLIANT.
- **Example:** tests subclass concrete `StorageService`; unused methods retain
  production initialization assumptions.
- **Future risk:** a new production call can make a narrow fake throw for a
  method outside its intended contract.
- **Minimal refactor:** rejected broad repository-interface migration. Focused
  `SnapshotBackend` is retained where substitution is materially useful.
- **Verification:** fault-injecting and delayed-init storage tests.

#### Widget callback contracts

- **Verdict:** PARTIALLY COMPLIANT.
- **Example:** `selectSkill` is historically a toggle despite its select-like
  name.
- **Future risk:** synchronization code can accidentally deselect an already
  selected item.
- **Minimal refactor:** keep backward-compatible toggle behavior, reject
  missing IDs, and add explicit `clearSkillSelection()` for callers that mean
  clear.
- **Verification:** selection invariant tests and mobile Inbox flow.

### Interface Segregation Principle

#### Mobile navigation

- **Verdict:** was VIOLATED, now COMPLIANT.
- **Example:** `_MobileWorkspaceNav` read the entire inherited `AppState` only
  for `reducedMotion`.
- **Future risk:** unrelated AppState notifications broaden dependency and
  complicate isolated tests.
- **Minimal refactor:** pass one immutable boolean from the shell.
- **Verification:** compact shell widget test and analyzer.

#### Major workspaces

- **Verdict:** PARTIALLY COMPLIANT.
- **Example:** desktop and RoadMap shells receive AppState plus multiple
  callbacks because they orchestrate rich interactive regions.
- **Future risk:** constructor growth and broad rebuilds with additional modes.
- **Minimal refactor:** no options bag or giant view model introduced. Focused
  data objects should be added only after rebuild profiling.
- **Verification:** responsive shell and interaction regression tests.

### Dependency Inversion Principle

#### Application side effects

- **Verdict:** PARTIALLY COMPLIANT.
- **Example:** AppState receives `StorageService`, `NotificationService`, and
  `Random`, but many mutation paths still call `DateTime.now()` directly.
- **Future risk:** deterministic reset/reward/conflict tests become harder.
- **Minimal refactor:** `GoalEngine.analyze` accepts an optional clock value;
  no global clock service or DI framework was introduced.
- **Verification:** deterministic before/after deadline test.

#### UI and infrastructure direction

- **Verdict:** COMPLIANT.
- **Example:** widgets never access Hive directly; storage does not depend on
  widgets or `BuildContext`; engines are UI-independent.
- **Future risk:** future cloud work must preserve centralized mutations and
  stable IDs.
- **Minimal refactor:** none.
- **Verification:** import map and static search.

## Crash, Hang And Lifecycle Audit

- Forced collection access was classified case-by-case. Enum label/color maps
  are exhaustive; guarded `first`/`last` accesses are safe. No new null crash
  was reproduced.
- Controller ownership is explicit in reviewed RoadMap, reward, task, skill,
  tutorial and root widgets. Disposals and mounted checks are present.
- Root async initialization lacked one mounted boundary and is fixed.
- RoadMap camera fit is post-frame but keyed by a stable signature, checks
  `mounted`, and does not create a self-sustaining frame loop.
- Save requests are observed and serialized. Continuous mutations can request
  follow-up passes, but each pass yields on storage I/O; no synchronous infinite
  loop was found. A future stress test should characterize sustained mutation.
- Repeat reset catch-up was the strongest synchronous freeze candidate. It no
  longer loops once per missed period.
- Animation controllers with repeat modes are widget-owned and disposed.

## Persistence And State Invariants

- Failed startup loads continue to block destructive writes.
- Snapshot manifests remain commit-last and fall back to the previous valid
  payload.
- An empty committed history now replaces stale memory instead of preserving
  it accidentally.
- Quick Inbox tasks remain isolated at `+10 XP`; no completion logic changed.
- Skill deletion still clears selected skill, linked tasks, bosses, chests,
  buffs, and device notifications.
- Selection rejects IDs not present in the current skill collection.

## Performance Evidence

- Full tests complete in seconds and analyzer is clean; no flaky/slow group was
  observed in the baseline.
- RoadMap painters implement focused `shouldRepaint` comparisons.
- Hover remains local widget state and does not notify AppState.
- History has an indexed-by-date cache with mutation invalidation.
- Remaining evidence gap: profile 20+ skills and large-history frame profiling
  on native Windows/macOS. No speculative selector/state migration was made.

## Dead Code Decision

- Removed: the legacy desktop `TopBar` and its private hover/button classes.
  Its only call was inside an unreachable `if (!mobileShell)` nested under the
  `!desktopShell` branch where `mobileShell` is always true.
- Preserved: the live mobile bottom navigation, extracted to its own part.
- Preserved: `PlanningWorkspace`. It has no current production entry point, but
  represents a product capability; deletion needs a separate product decision.

## Refactors Explicitly Rejected

- Splitting AppState into many notifiers: too much completion/persistence risk.
- Replacing ChangeNotifier with BLoC/Redux: no demonstrated bug requires it.
- Repository interfaces for every service: only snapshot substitution currently
  justifies an abstraction.
- Full StatisticsSnapshot extraction: profile first, then centralize proven
  expensive/duplicated calculations.
- RoadMap canvas decomposition: current camera/painter contracts are stable.
- Storage rewrite or migration: outside scope and already protected by the
  snapshot/manifest plan.

## Test Coverage Added

- Empty committed history replaces stale memory and cached totals.
- Disposed root app does not continue loading after delayed storage init.
- Invalid skill IDs cannot become selected; explicit clear is deterministic.
- Permanent Inbox is excluded from active skill count.
- Week boundaries and priority rank are shared and deterministic.
- Ten years of missed daily resets catch up directly to the next future reset.
- Goal deadline evaluation uses an injected clock in tests.

## Final Verification

- `dart format lib test`: 116 files checked, no formatting changes.
- `flutter analyze`: no issues found.
- `flutter test --reporter compact --timeout 30s`: 325/325 passed.
- `dart fix --dry-run`: nothing to fix.
- `git diff --check`: clean.
- `flutter build macos`: succeeded; produced a 52.2 MB release app. Flutter
  reported non-blocking CocoaPods cleanup guidance and an `objective_c`
  framework-name warning owned by the dependency build hook.
- `flutter build apk --debug`: succeeded. Flutter reported a future Kotlin
  built-in migration requirement for the app and two Android plugins.
- `flutter build windows`: not available from the macOS host and therefore not
  claimed as verified.
- Physical Windows/Android device QA was not performed in this batch.

## Remaining Architecture Debt

1. Characterize reward decisions before extracting a pure RewardEngine.
2. Add real-Hive process interruption and retention cleanup tests.
3. Profile AppState rebuild fan-out with 20+ skills and large history.
4. Decide whether PlanningWorkspace is returning or should be removed.
5. Introduce clock inputs only at additional time-sensitive extraction
   boundaries, not as a global service locator.
6. Add native restart/background/foreground and rapid RoadMap switching QA.
7. Decide a local privacy/export/encryption policy before distribution.

## Non-Goals

- No cloud/auth, analytics, package additions, persistence migration, visual
  redesign, XP changes, RoadMap semantics changes, or state-management rewrite.
