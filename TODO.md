# TODO / Living Backlog

Last updated: 2026-06-29

This file tracks the active implementation roadmap and completed project work. Update it after every meaningful code or design change.

## Update Protocol

- Move finished checklist items to `Recently Completed` with the release or commit reference.
- Keep active work ordered from `P0` through `P6`.
- Keep each task small enough for a separate reviewable batch.
- Record uncertainty, migration risk, and manual QA requirements explicitly.

## P0 — Bugs / Stabilization

- [ ] Validate native Windows/macOS pointer tracking after skill-card hit-region alignment; capture a platform repro if compositor hover still differs.
- [ ] Correct the QHD skill quest-count badge optical alignment.
- [ ] Profile mobile theme switching after the `2x` snapshot cap and add a reduced-motion fallback only if frame timings still show jank.

## P1 — Mobile Foundation

- [ ] Add a TextTheme-based mobile typography scale and responsive constants for `360`, `393`, `430`, and `760` widths.
- [ ] Replace the mobile Today Dashboard with a trial compact next-quest card; keep a clean rollback path to skills-and-list only.
- [ ] Expand the mobile skill rail into informative squircles with level, quest count, and progress.
- [ ] Smoothly collapse mobile skill cards after a skill is selected.
- [ ] Open AddSkill and AddTask as full-screen routes below `760px`, while desktop keeps dialogs.
- [ ] Add widget coverage for overflow, truncation, navigation, and dark/light rendering at mobile widths.

## P2 — RoadMap Layout

- [ ] Add desktop `horizontal / vertical` RoadMap layout modes with a toggle near fullscreen.
- [ ] Persist the desktop layout preference as a local per-device UI setting.
- [ ] Force vertical RoadMap layout on mobile.
- [ ] Place vertical roads symmetrically: early stages above, terminal stages nearest the skill below.
- [ ] Preserve existing camera auto-fit, stage links, template behavior, and mastery logic in both orientations.
- [ ] Validate `0`, `1`, `3`, and `10+` stages across mobile, desktop, and QHD widths.

## P3 — Skill Goal Progress

- [ ] Design measurable numeric goals without replacing RoadMap stage progress implicitly.
- [ ] Explore weighted stages only after equal weighting has real usage feedback.
- [ ] Add a persisted goal-cycle state with stable ID, start time, baseline mastered stages, and completion time.
- [ ] Add a tested storage migration for legacy GoalSpec payloads.
- [ ] Introduce a persisted `RoadMapRecord` with stable ID, skill ID, goal-history link, status and timestamps.
- [ ] Add `activeRoadMapId` to Skill and migrate legacy `treeNodes` into one active RoadMap without changing node IDs.
- [ ] Move stage mutations, task links and progress calculation to the active RoadMap boundary.
- [ ] Add completed RoadMap detail UI that renders archived `CompletedRoadmap.stages` rather than only timeline summaries.
- [ ] Add template-based new RoadMap creation only after `RoadMapRecord` / `activeRoadMapId` boundaries exist.
- [ ] Keep template-based new RoadMap creation disabled until it targets only the active RoadMap instead of reusing and clearing `Skill.treeNodes`.
- [ ] Add multi-RoadMap migration, restart, task-link, template and cloud-conflict regression coverage.
- [ ] Preserve old mastered stages as history; count only unmastered or newly added stages in the new cycle.
- [ ] Show the same goal percentage consistently in skill, RoadMap, and Statistics surfaces.
- [ ] Revisit the deeper goal editor only with the measurable-goal model.
- [ ] Add an optional review prompt after goal completion.
- [ ] Add optional notes and richer filtering/sorting to completed goal history.
- [ ] Define export and future sync conflict rules for completed goal entries.
- [ ] Replace the compact mobile dialog with a full-screen goal editor if the flow grows.
- [ ] Add one quiet, non-blocking recommendation during skill creation to create a recurring ritual later.

## P4 — Reordering

- [ ] Add a list/editor stage reorder flow grouped by RoadMap road.
- [ ] Initially allow stage reorder only inside a non-branching road; reject cross-road or ambiguous DAG moves safely.
- [ ] Preserve stage IDs, linked quest `treeNodeId` values, external prerequisites, and cycle safety.
- [ ] Before cloud sync, replace local list-position persistence with an explicit conflict-resolvable skill ordering token and a compatibility plan.
- [ ] Keep direct drag-and-drop on the RoadMap canvas out of this phase.

## P5 — Task Inbox / “Задачник”

- [ ] Add recurring inbox tasks only after the plain To-do flow has usage feedback.
- [ ] Add inbox tags/categories without mixing them into skill tags.
- [ ] Add “convert inbox task to skill quest” with explicit skill selection.
- [ ] Add inbox-specific stats if users need a lightweight done count.
- [ ] Add inbox search/filter once the list can grow.
- [ ] Consider a dedicated mobile inbox page if the compact Act card becomes crowded.
- [ ] Add notification/reminder support with explicit inbox-safe settings.
- [ ] Define cloud sync conflict rules for scoped tasks before adding sync.

## P6 — Milestone Animations

- [ ] Add optional `100%` milestone sound behind interface sound settings.
- [ ] Add a user setting to disable milestone animations if the feedback feels too busy.
- [ ] Add reduced-motion behavior when the app has a motion accessibility setting.
- [ ] Explore a richer but still lightweight `100%` celebration after MVP feedback.
- [ ] Persist or surface milestone history only if users need an audit trail.
- [ ] Consider achievement integration separately from milestone feedback.

## Skills to use

- [ ] Use `refactor-batch-protocol` before every implementation batch.
- [ ] Use `flutter-bug-audit` for P0 crashes, pointer issues, camera regressions, and animation failures.
- [ ] Use `flutter-architecture-testing` for responsive UI, navigation, forms, and widget-test changes.
- [ ] Use `appstate-decomposition` only for narrow engine or mutation-boundary work; never rewrite AppState wholesale.
- [ ] Use `future-cloud-boundary` before GoalSpec, Task, ordering, timestamp, or storage migrations.
- [ ] Create `flutter-dart-current-stack` for SDK compatibility and dependency-baseline checks.
- [ ] Create `mobile-responsive-ux` for `360dp`, safe-area, typography, and adaptive route audits.
- [ ] Create `roadmap-layout-audit` for paths, camera bounds, orientation, templates, and stage identity.
- [ ] Create `goal-progress-modeling` for goal cycles, stage weighting, reset policy, and milestones.
- [ ] Create `desktop-pointer-hover-audit` for MouseRegion, transforms, overlays, and native hit testing.
- [ ] Create `animation-performance-audit` for frame timing, repaint boundaries, image capture, and reduced-motion fallbacks.

## Recently Completed

- Task Inbox / “Задачник” MVP: added explicit `TaskScope.skill/inbox`, nullable skill identity for inbox tasks, title-only quick add, isolated completion/undo/delete UI in Act, storage compatibility for legacy tasks, and regression coverage proving inbox tasks do not affect skill XP, RoadMap progress, history, daily stats, achievements, rewards, resistance, or skill quest counts.
- Milestone Animations MVP: persisted `25%`, `50%`, and `100%` goal milestone thresholds per skill/current goal, detects progress crossings from stage mastery, marks all crossed thresholds while showing only the strongest non-blocking banner for one action, and keeps sound deferred.
- Start New RoadMap MVP: after setting the next goal, users can keep the current map, add a manual stage, or explicitly create a new empty active RoadMap; the old completed map is stored as an append-only `CompletedRoadmap` snapshot and surfaced in the timeline. Template-based new RoadMap creation remains disabled pending `RoadMapRecord` / `activeRoadMapId` boundaries.
- Goal History MVP: completed goals are archived as immutable per-skill snapshots during explicit Next Goal confirmation and appear in the existing growth timeline; legacy skills load with an empty archive.
- Next Goal Flow MVP: added an explicit `100%` CTA and validated goal input; updating the goal keeps all RoadMap stages, mastery, quests, XP and IDs intact, with no schema migration or automatic reset.
- Skill Goal Progress MVP: added derived equal-weight RoadMap stage progress, neutral empty state, `100%` completion copy, skill-card and RoadMap detail UI, plus unit/widget coverage without storage changes.
- Skill Goal Progress MVP follow-up: keep `25/50/100` animations, `100%` sound, and progress in future mobile bubbles/squircles deferred to their existing P1/P6 batches.
- `1.3.47`: added centralized skill reordering that preserves selection, quests, RoadMap links, XP and stable skill IDs.
- `1.3.47`: added desktop drag handles and mobile long-press reordering with stable item keys; current local order survives save/load through the existing skill-list persistence order.
- `1.3.47`: audited stage ordering and deferred it because RoadMap rendering, template reuse and next-stage tie-breaking still depend on DAG topology plus raw `treeNodes` order.
- Mobile UX stabilization: fixed the empty status-row width reservation that truncated the `Действовать сегодня` header at narrow widths.
- Mobile UX stabilization: simplified quest rows at `<760px`, keeping title, minimum action and primary metadata while moving edit/delete to existing swipe actions.
- Mobile UX stabilization: widened compact skill chips and added a responsive seven-column AddSkill icon grid at narrow widths.
- Mobile UX stabilization: mobile RoadMap now hides fullscreen, and the template panel starts collapsed for newly selected skills.
- Mobile UX stabilization: capped theme-transition snapshots at `2x` DPR to reduce mobile frame-capture cost without replacing the transition system.
- RoadMap interaction stabilization: overview initial fit and `Отцентровать` now share actual skill-orb bounds instead of resetting to an off-center identity matrix.
- RoadMap interaction stabilization: skill-card hover regions now match the painted card, and overview skill-orbs align their visual center with layout/painter coordinates.
- RoadMap stabilization: added repeated `simple -> normal -> hard -> normal -> simple` road-isolation regression coverage.
- RoadMap stabilization: added storage roundtrip coverage for path roots, stage IDs, prerequisites and linked quest `treeNodeId`.

- `1.3.25`: moved `Progress` out of primary navigation and into the top-right secondary `Статистика` entry.
- `1.3.25`: primary navigation is now `Действовать / Планировать / Карта`; mobile bottom nav is `Сейчас / План / Карта`.
- Post-`1.3.25` local polish: `Статистика` top-bar button now uses the same visual component as `Трофеи`.
- Post-`1.3.25` local polish: Today Dashboard stat-card icons moved to the right side, vertically centered, enlarged, then nudged slightly left.
- `1.3.29`: fresh empty storage no longer seeds developer/demo skills or quests.
- `1.3.29`: added persistent `tooltipsEnabled` setting and profile switch for hover hints.
- `1.3.29`: XP values next to sliders can be edited by typing a number.
- `1.3.29`: RoadMap overview gets a quiet `Отцентровать` camera button.
- `1.3.29`: `План` was frozen pending a product decision; this is superseded by the planned `1.3.32` skill-settings experiment.
- `1.3.30`: first empty `Сейчас` screen added a light core-loop primer; later simplified to plain text without numbered chips.
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
- `1.3.40`: added debug-only hidden entry through 5 taps on the top-bar app mark.
- `1.3.40`: added read-only Debug Admin shell with placeholder sections and no AppState mutations.
- `1.3.41`: added debug-only persistence through the separate `__debug__` Hive box.
- `1.3.41`: Debug Admin now shows debug storage status and confirm-guarded debug-state clearing without touching AppState.
- `1.3.42`: added Debug State Simulator scenarios for fresh user, streak 7, all achievements, epic chest, defeated resistance and active effects.
- `1.3.42`: Debug scenarios require confirmation, update debug draft metadata and remain isolated from production storage architecture.
- Post-`1.3.42` onboarding cleanup: first-run primer no longer shows the numbered core-loop chip strip, and skill creation no longer auto-creates a quest or mandatory stage.
- Post-`1.3.42` skill creation cleanup: skill criteria editing is frozen/hidden from `AddSkillDialog`; existing checklist data is preserved for compatibility.
- Post-`1.3.42` onboarding cleanup: after creating the first skill, the tutorial now continues to the `Первый квест` CTA instead of disappearing.
- Post-`1.3.42` debug fix: `Новый пользователь` scenario now resets first-run tutorial state so onboarding appears again after debug data reset.
- Post-`1.3.42` skill form cleanup: SMARTER helper UI is frozen/hidden from `AddSkillDialog`; preview icon moved above the name field; first stage is optional.
- Post-`1.3.42` quest form cleanup: behavior, contexts and manual focus controls are frozen/hidden; XP sits under the quest title; stage link is now `Этап в дорожной карте`.
- Post-`1.3.42` RoadMap polish: stages can be renamed from a compact pencil icon next to the stage title in desktop and mobile stage panels; the old separate `Переименовать` button is removed.
- Post-`1.3.42` form polish: skill preview icon moved above the name field, palette expanded to 13 rainbow-ordered colors, and first-run dialog hints became inline.
- Post-`1.3.42` quest settings correction: `Поведение квеста`, type, habit repeat rhythm and reminders returned to advanced settings; contexts and manual focus remain hidden.
- Post-`1.3.42` onboarding correction: primary tutorial actions temporarily hide the overlay while creation dialogs are open, then continue to the next onboarding step.
- Post-`1.3.42` tutorial v2.1: core tutorial replay now starts from the first relevant missing step instead of always showing `Первый запуск`.
- Post-`1.3.42` tutorial v2.1: `Первое действие` no longer completes a quest from the tutorial card; `Понятно` advances the lesson while real quest/minimum actions still advance naturally.
- Post-`1.3.42` tutorial v2.1: step transitions now wait 2 seconds before the next spotlight fades in.
- Post-`1.3.42` tutorial v2.1: `XP и рост` points to `Карта`, RoadMap now explains the skill bubble, canvas and right-side details, and Statistics uses the same orange spotlight style as the rest of onboarding.
- Post-`1.3.42` tutorial v2.1: completing the core Statistics step now continues into `Трофеи и эффекты` instead of ending silently.
- Post-`1.3.42` tutorial v2.1: the secondary tutorial dismiss button is now `Пропустить обучение`, while primary step buttons still advance the lesson.
- Post-`1.3.42` tutorial v2.1: completing the trophies tutorial now continues into the profile/help topic.
- Post-`1.3.42` UI polish: desktop `Статистика` opens as a wider centered 16:10 dialog.
- Post-`1.3.42` UI polish: app version is visible above the app title in the top-left header.
- Post-`1.3.42` safety polish: deleting a skill now requires confirmation and warns that skill XP/level, RoadMap stages and linked quests will be deleted.
- Post-`1.3.42` RoadMap polish: focused skill orb stays centered when there are no stages, then moves right as stages appear without changing camera scaling.
- Post-`1.3.42` RoadMap polish: selected skills now show unlinked skill quests in the RoadMap inspector, with complete/minimum/edit/delete actions.
- Post-`1.3.42` RoadMap polish: RoadMap skill/stage bubbles are 20% larger; selected skill details show the path goal as subtitle, then unlinked quests first and thin collapsible stage groups below; selected stage details show only that stage's quests without an extra group header.
- Post-`1.3.43` tutorial polish: `Трофеи` now has its own orange spotlight inside the rewards dialog and closes into the profile/help tutorial step.
- Post-`1.3.43` quest polish: quests now support an optional saved description in creation/edit flows; main quest widgets show it as quiet gray inline context, while RoadMap rows stay compact.
- Post-`1.3.44` architecture audit: added `docs/APPSTATE_MAP.md` with AppState responsibility map, mutation boundaries, future sync notes and extraction risk order.
- `1.3.45`: extracted pure `AchievementEngine` evaluation from `AppState` while keeping unlock mutation, pending notifications and storage behavior in `AppState`.
- `1.3.46`: added Debug Admin achievement tools for unlock all, lock all and per-achievement toggles, with debug draft metadata only.
