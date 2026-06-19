# TODO / Living Backlog

Last updated: 2026-06-19

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

## Next Planned Batches

- `1.3.32` — Planning -> Skill Settings Experiment: remove `План` from primary navigation experimentally, keep rollback path, open skill settings from Act/RoadMap.
- `1.3.33` — Animated First-Run Tutorial: spotlight real controls, show once, replay from profile.
- `1.3.34` — RoadMap + Goal Polish: make RoadMap visually and textually lead toward the skill goal, with quiet SMARTER hints.
- `1.3.35` — Release QA / Public Build Hardening: full regression, manual QA, copy audit, width checks and known non-blockers.

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

### Planning: Move To Skill Settings - Planned For 1.3.32

Problem:
`План` still risks feeling visually and functionally overloaded. It is not fully obvious what the user should do there or why it exists separately from `Сейчас` and `Карта`.

Current decision:
Planning is frozen until `1.3.32`. The chosen experiment is to remove `План` from primary navigation and turn it into skill settings.

Implementation direction:

- Keep `WorkspaceMode.plan` and `PlanningWorkspace` in code at first, so the experiment has a safe rollback path.
- Desktop opens skill settings as a large dialog.
- Mobile opens skill settings as a bottom sheet.
- Entry points: selected skill in Act/skill workspace and selected skill/stage in RoadMap.
- Job: `Структура навыка`, not dashboard/audit.

Content rules:

- Show goal, stages/RoadMap summary, active quests, and one main setup suggestion.
- Archive/full audit stays hidden by default.
- Do not add new diagnostics.
- Do not let skill settings compete with `Сейчас`.
- If the experiment feels worse, restore `План` as a primary mode using the preserved code path.

### First-Run Guided Onboarding

Problem:
Fresh install should be empty, but later the app should teach the first core loop through a polished guided experience.

Current light flow:

- Empty `Сейчас` explains `1. Навык -> 2. Этап -> 3. Квест`.
- CTA remains `Создать первый навык`.
- Existing creation flow still creates the first stage and first quest.
- `План` and `Карта` empty states point back to `Сейчас` instead of adding new setup branches.

Do not implement yet. Future direction:

- Design an animated first-run tutorial with spotlight/highlight on real controls.
- Teach: create skill -> first stage -> first quest -> minimum step -> XP/growth.
- Persist `onboardingSeen` once the spotlight tutorial is implemented.
- Let users replay onboarding from profile/settings.
- Keep tutorial skippable and non-blocking.

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

### RoadMap + Goal Polish - Planned For 1.3.34

- Make the RoadMap path feel like it leads to the skill goal, not just to a large skill bubble.
- Keep SMARTER hints quiet: show only 1-2 helpful hints, not a score dashboard.
- Use existing `GoalSpec`, `GoalEngine`, `GoalHeader` and skill edit flow.
- Do not add more RoadMap templates, drag-and-drop or a new goal model in this batch.

### Release QA / Public Build Hardening - Planned For 1.3.35

- Manual QA: fresh state, populated state, first-run tutorial, skill settings, RoadMap focus, stats/trophies.
- Width checks: `360`, `393`, `430`, `760`, `980+`.
- Copy audit: no user-facing regressions to `задачи`, `узлы`, `баффы`, `боссы`, `Прогресс`.
- Regression: `dart format lib test`, `flutter analyze`, `flutter test -r expanded --timeout 30s`.
- Record known non-blockers before public build packaging.

### Top Bar Consistency

- `Трофеи` and `Статистика` currently share the same pill component.
- Re-check top-bar overflow at compact widths after more controls are added.

## Known Non-Goals For Now

- Do not implement new gamification systems.
- Do not add RoadMap drag-and-drop.
- Do not re-expand Planning before the skill-settings experiment is validated.
- Do not seed demo data into production builds.
- Do not add a heavy onboarding wizard until the first-run design is clear.
