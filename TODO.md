# TODO / Living Backlog

Last updated: 2026-06-20

This file tracks technical details, completed work, open tasks, and remaining work sorted by priority. Update it after every meaningful code or design change, even when the change is small.

## Update Protocol

- Add finished work to `Recently Completed`.
- Keep new work sorted by priority: `P0` release/data safety, `P1` core UX, `P2` product structure, `P3` polish.
- If a task is intentionally not implemented yet, keep it in backlog with acceptance criteria.
- Do not hide uncertainty: note risks, unknown files, and follow-up checks.

## Recently Completed

- `1.3.25`: moved `Progress` out of primary navigation and into the top-right secondary `Статистика` entry.
- `1.3.25`: primary navigation is now `Действовать / Планировать / Карта`; mobile bottom nav is `Сейчас / План / Карта`.
- Post-`1.3.25` local polish: `Статистика` top-bar button now uses the same visual component as `Трофеи`.
- Post-`1.3.25` local polish: Today Dashboard stat-card icons moved to the right side, vertically centered, enlarged, then nudged slightly left.
- `1.3.29`: fresh empty storage no longer seeds developer/demo skills or quests.
- `1.3.29`: added persistent `tooltipsEnabled` setting and profile switch for hover hints.
- `1.3.29`: XP values next to sliders can be edited by typing a number.
- `1.3.29`: RoadMap overview gets a quiet `Отцентровать` camera button.
- `1.3.29`: `План` was frozen pending a product decision; this is superseded by the planned `1.3.32` skill-settings experiment.
- `1.3.30`: first empty `Сейчас` screen now shows a light core-loop primer: `1. Навык -> 2. Этап -> 3. Квест`.
- `1.3.30`: empty `План` and `Карта` copy now gently points new users back to `Сейчас` instead of acting like separate setup flows.
- `1.3.30`: post-1.3.29 polish replaced stale `Прогресс` wording in Today Dashboard with secondary `Статистика` language.
- `1.3.31`: reduced navigation tooltip noise: signed top-bar/bottom-nav buttons no longer repeat their own labels, while compact icon-only states keep hints.
- `1.3.32`: moved `План` out of primary navigation experimentally and exposed it as `Настройка навыка` from Act/RoadMap.
- `1.3.33`: added a show-once animated first-run spotlight over the real `Создать первый навык` CTA, with replay from profile settings.
- `1.3.34`: froze Planning and removed its user-facing entry points from Act/RoadMap/app shell; Planning code remains dormant for reference only.
- `1.3.35`: added derived-only `CourseNudgeEngine` and `Следующая корректировка` in `Статистика -> История роста`.
- `1.3.35`: weekly review now feeds one actionable nudge instead of a generic saved-review snackbar.
- `1.3.35`: nudge dismiss is runtime-only (`Позже` lasts for the current session, with no storage model).
- `1.3.35`: `AddTaskDialog` supports nudge prefill for title/minimum step and focused minimum editing.
- `1.3.36`: grouped weekly review and `Следующая корректировка` into one quiet `Review цели` block inside `Статистика`.
- `1.3.36`: added regression coverage that course nudges stay out of `Сейчас` and only appear in `Статистика`.
- `1.3.37`: RoadMap skill bubbles stay as direct RoadMap entry points; practice rows no longer open quest focus on row tap.
- `1.3.37`: RoadMap stage/practice rows can start an available `Минимум` through the existing XP/feedback flow.
- `1.3.38`: completed release QA hardening pass: bumped version, fixed stale `Прогресс` copy in Statistics, reran copy audit and full regression suite.
- `1.3.39`: fixed achievement details crash caused by using `AppStateProvider.of(ctx)` inside a dialog builder context.
- `1.3.39`: added locked/unlocked achievement detail regression tests and audited similar provider-context patterns.

## Next Planned Batches

- `1.3.40` — Debug shell + hidden entry: create debug-only panel entry via 5 taps on the top-bar app icon, without scenarios yet.
- `1.3.41` — Debug persistence: separate `__debug__` Hive box with debug-only overrides, outside `StorageService` and `AppState._saveAll()`.

## P0 - Release / Data Safety

### Fresh Install Must Be Empty - Done In 1.3.29

Resolved:
An external tester received a build that already contained skills created during development. On a first launch with no saved app data, the app must not show developer skills, quests, profile progress, trophies, effects, resistance events, or history.

Implemented:

- Removed automatic `_initDefaults()` call from empty `loadSavedData()`.
- Kept `seedDefaults: true` as explicit test/debug-only path.
- Added fresh-state test for empty skills, tasks, history, rewards/effects, resistance and default profile.
- Updated widget smoke test to expect empty first-run CTA.
- Checked repo for bundled Hive/app save artifacts; none found.

Acceptance:

- Fresh install opens empty core flow.
- No developer-created skills or quests appear.
- Tests cover empty storage startup.
- Future onboarding may guide creation, but must not rely on seeded data.

## P1 - Core UX Improvements

### Global Tooltip Toggle - Done In 1.3.29

Resolved:
There are too many hover tooltips. They can make the app feel noisy, especially on desktop.

Implemented:

- Added `tooltipsEnabled` setting in `StorageService` meta and `AppState`.
- Wrapped root app content in `TooltipVisibility`.
- Added profile switch `Подсказки при наведении`.
- Kept tooltip texts in code so users can turn hints back on.

Acceptance:

- User can disable most hover tooltips.
- Critical confirmations and labels still exist where needed.
- No screen becomes harder to use because a necessary explanation disappeared.

### RoadMap Camera Center Button - Done In 1.3.29

Resolved:
When no bubble is selected in `Карта`, user needs a quick way to re-center the camera.

Implemented:

- Added top-right `Отцентровать` button in RoadMap overview mode.
- Button animates existing camera controller back to overview identity.
- Hidden automatically in selected skill/stage mode.

Acceptance:

- In overview mode, button is visible and clickable.
- Camera returns to a sane centered overview.
- No layout conflict on mobile/narrow widths.

### Direct XP Number Editing - Done In 1.3.29

Resolved:
XP can be adjusted with a slider in some places, but numeric input is needed for precision.

Implemented:

- Added shared numeric edit dialog.
- XP badge next to quest XP slider is clickable.
- XP badge next to stage XP slider is clickable.
- XP badge in RoadMap `Практики и XP` dialog is clickable.
- Input is clamped to the same min/max as the sliders.

Acceptance:

- User can edit XP by typing a number.
- Invalid values are clamped or rejected gently.
- Slider updates after text input and text updates after slider movement.

## P2 - Product Structure Decisions

### Planning: Frozen And Removed From App Flow - Implemented In 1.3.34

Problem:
`План` still risks feeling visually and functionally overloaded. It is not fully obvious what the user should do there or why it exists separately from `Сейчас` and `Карта`.

Current decision:
`План` is frozen. It is not a primary mode, not a skill settings surface, and not linked from Act or RoadMap.

Implemented:

- Removed `WorkspaceMode.plan` from the app shell.
- Removed `Настроить` entry points from Act skill workspace.
- Removed RoadMap skill/stage entry points into Planning.
- Stopped importing `PlanningWorkspace` from `MainPage`.
- Kept `PlanningWorkspace` files in the repository as frozen reference/rollback material only.

Content rules:

- Do not add new Planning features.
- Do not reintroduce Planning buttons in Act/RoadMap without an explicit product decision.
- If the feature returns, redesign it from first principles instead of restoring the overloaded dashboard.
- Core setup should happen through creation flow, RoadMap stage actions, and lightweight edit dialogs.

### Review-To-Action Nudge Loop - Implemented In 1.3.35

Resolved:
Former Planning should not return as a dashboard. Course correction now appears only after review / inside `Статистика -> История роста`.

Implemented:

- Added derived-only `CourseNudgeEngine`; no Hive/storage lifecycle and no new persisted entity.
- `CourseNudgeCard` shows one small correction: title, reason, one primary CTA and `Позже`.
- Priority: actionable review focus -> missing minimum step -> active stage without active quest -> weak SMARTER goal.
- Vague review focus does not become a quest automatically; it asks the user to clarify focus.
- `doReview` is not a nudge card; overdue review expands/highlights `WeeklyReviewCard`.
- `Позже` is runtime-only and returns after app restart.
- Act does not show course nudges in `1.3.35`.

Acceptance:

- No list of diagnostics.
- No Planning tab, overlay, skill settings surface or dashboard returns.
- Nudge disappears when the underlying issue is fixed.
- New quest nudges open `AddTaskDialog` with prefilled title/minimum/stage context where available.

### First-Run Guided Onboarding - Implemented In 1.3.33

Problem:
Fresh install should be empty, but later the app should teach the first core loop through a polished guided experience.

Current light flow:

- Empty `Сейчас` explains `1. Навык -> 2. Этап -> 3. Квест`.
- CTA remains `Создать первый навык`.
- Existing creation flow still creates the first stage and first quest.
- `Карта` empty state points back to `Сейчас` instead of adding a separate setup branch.

Implemented:

- Added animated spotlight/highlight over the real `Создать первый навык` control.
- Tutorial teaches: create skill -> first stage -> first quest -> minimum step -> XP/growth.
- Persisted `onboardingSeen` in storage meta.
- Added replay entry in profile interface settings.
- Kept tutorial skippable and non-blocking.

Acceptance:

- First run does not feel abandoned even without demo data.
- Tutorial explains the core loop without adding permanent UI clutter.
- User can skip and still understand how to create the first action.

## P3 - Polish / Consistency

### Tooltip And Hint Audit

- Global toggle exists; next pass can still identify hints that repeat obvious labels.
- Navigation pass done in `1.3.31`: signed primary/bottom-nav and secondary top-bar buttons no longer show duplicate hover labels.
- Continue removing or shortening noisy tooltips only when the visible UI already explains the action.
- Keep deeper explanations in FAQ/onboarding/settings, not on every hover.

### Today Dashboard Visual Polish

- Confirm stat-card icon placement on desktop and mobile after the recent right-side icon change.
- Watch for truncation in Russian labels at narrow widths.

### RoadMap + Goal Polish - Implemented In 1.3.37

Resolved:
RoadMap skill bubbles should keep their direct “open the path” behavior. The accidental focus problem belongs to practice rows: tapping a quest row should not open a separate quest focus. Practice rows also needed a direct way to do the minimum step without turning the map into a full task editor.

Implemented:

- Skill bubbles remain direct RoadMap entry points; tapping a sphere opens the focused path.
- Skill-level inspector no longer lists all skill quests; it shows path/goal context and asks the user to choose a stage.
- Stage/practice rows are passive containers; only the completion circle, `Минимум`, and edit icon perform actions.
- Stage/practice rows show `Минимум` only when the task has an available minimum step.
- RoadMap minimum action uses the existing `MainPage._onMinimumAction` path, preserving XP bubbles, feedback and reward side-effects.
- Mobile RoadMap follows the same rule: select skills/stages normally, but practice rows do not open a quest focus.

Acceptance:

- Clicking the skill bubble opens the RoadMap focus as before.
- Clicking a practice row does not open quest focus.
- `Минимум` appears only for eligible active quests and completes only the minimum step.

### Statistics Cleanup - Implemented In 1.3.36

Resolved:
After `1.3.35`, `Следующая корректировка` was useful but could visually read like the beginning of a new Planning panel.

Implemented:

- Wrapped `WeeklyReviewCard` and `CourseNudgeCard` in one `Review цели` block.
- Clarified copy: review checks the course and offers at most one small correction.
- Kept deeper stats below the growth story/review flow.
- Added widget regression that Act does not show `Следующая корректировка`, while Statistics does.

Acceptance:

- `Статистика` still reads as growth history first.
- Review/nudge is a small correction moment, not a dashboard.
- `Сейчас` remains action-first and nudge-free.

### Release QA / Public Build Hardening - Done In 1.3.38

Completed:

- Bumped release version to `1.3.38+1`.
- Replaced stale user-facing Statistics copy that still said `Прогресс`.
- Ran copy audit for old user-facing terms: `задачи`, `узлы`, `баффы`, `боссы`, `Прогресс`.
- Ran regression checks: `dart format lib test`, `flutter analyze`, `flutter test -r expanded --timeout 30s`.
- Confirmed Planning remains frozen and has no app-shell entry point.

Known non-blockers before packaging:

- `PlanningWorkspace` code and old Planning copy still exist as dormant rollback/reference code, but are not reachable from the app shell.
- `shared.dart` still recognizes legacy words like `бафф` and `босс` in a keyword classifier for compatibility.
- `dialogs/skill_tree_dialogs.dart` still contains legacy tree/stage dialog code and generic text like `Прогресс освоения`; this is not the main RoadMap surface.
- Manual visual width QA should still be repeated on real device/emulator widths before a public store-style build.

### Top Bar Consistency

- `Трофеи` and `Статистика` currently share the same pill component.
- Re-check top-bar overflow at compact widths after more controls are added.

### Achievement Details Crash - Done In 1.3.39

Resolved:
Clicking an achievement could crash because the details dialog builder used `AppStateProvider.of(ctx)`, and that builder context is not guaranteed to contain the inherited provider.

Implemented:

- `_AchievementCard._showDetails()` now uses the existing `isDark` value and locally computed `txt/sub` colors.
- Added widget coverage for locked and unlocked achievement details.
- Audited `AppStateProvider.of(ctx/dialogContext/sheetContext/_)` patterns. Remaining `ctx` usages are outside builder contexts or intentionally wrapped with a provider.

Acceptance:

- Locked achievement details open without crash.
- Unlocked achievement details open without crash.
- Debug Admin work remains a later batch and does not touch AchievementsDialog in this fix.

## Known Non-Goals For Now

- Do not implement new gamification systems.
- Do not add RoadMap drag-and-drop.
- Do not re-expand Planning without a new product decision.
- Do not seed demo data into production builds.
- Do not add a heavy onboarding wizard until the first-run design is clear.
