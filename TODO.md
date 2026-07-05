# TODO / Living Backlog

Last updated: 2026-07-05

This file tracks the active implementation roadmap and completed project work. Update it after every meaningful code or design change.

## Update Protocol

- Move finished checklist items to `Recently Completed` with the release or commit reference.
- Keep active work ordered from `P0` through `P6`.
- Keep each task small enough for a separate reviewable batch.
- Record uncertainty, migration risk, and manual QA requirements explicitly.

## P0 — Bugs / Stabilization

- [x] Add deterministic fault-injection characterization for load failure, partial domain replacement, interrupted multi-domain saves, and post-load-failure overwrite.
- [x] **P1 Storage:** add observable `PersistenceStatus`, retain dirty state after failed saves, and expose retry for startup, debounce, and lifecycle flush failures.
- [x] **P1 Storage:** prevent every automatic/destructive write after failed startup load until recovery succeeds.
- [x] Implement versioned snapshot/manifest persistence with commit marker last, validation, previous fallback, and untouched legacy boxes.
- [x] Add startup storage recovery UI for load/open-box failures and retry `init + load` without exposing raw production errors.
- [ ] Add real-Hive fault-injection and CI storage regression coverage for open failure, interrupted writes, rollback, retry idempotency, and legacy dual-read.
- [ ] Define a conservative snapshot retention/cleanup policy after multiple releases; keep at least current and previous valid payloads.
- [ ] Add native restart, process-kill, and disposable-filesystem disk-full recovery tests.
- [ ] Decide backup/export and encrypted-at-rest policy before public distribution.
- [ ] Consider legacy-box cleanup only after export/restore support and several releases of verified snapshot recovery.
- [ ] Bound or downsample profile image input before loading full bytes to avoid memory pressure from very large files.
- [ ] Validate native Windows/macOS pointer tracking after skill-card hit-region alignment; capture a platform repro if compositor hover still differs.
- [ ] Profile mobile theme switching after the `2x` snapshot cap and add a reduced-motion fallback only if frame timings still show jank.

## Reminder — Product Follow-ups After Hardening

Do not mix these product decisions into Release / Regression Hardening. Revisit them explicitly in the next product-planning pass:

- [ ] Design a measurable numeric goal model; current goals remain text and percentages are derived visually from equal-weight RoadMap stages.
- [ ] Decide whether confirming every next goal must always start a fresh `0%` RoadMap; the current flow resets only when the user chooses “Создать новую карту”.
- [ ] Add a quiet recommendation during skill creation to create at least one recurring ritual/quest.
- [ ] Decide whether milestone feedback should fire after every completed stage when it does not land exactly on `25/50/100%`.
- [ ] Add optional sound for the `100%` milestone behind sound and reduced-motion/accessibility settings.
- [ ] Validate the new compact next-action summary with real mobile use before deciding whether the expandable full “Действовать сегодня” dashboard should remain.
- [ ] Finish the mobile truncation audit and introduce a coherent `TextTheme`/responsive typography system for `360/393/430/760dp`.
- [ ] Profile theme switching on real mobile hardware; the current `2x` snapshot cap is only a partial mitigation.
- [ ] Extend stage reordering beyond isolated linear roads only after branching/shared-root/cross-road semantics and conflict handling are designed.

## P1 — Mobile Foundation

- [x] Surface a compact next-action/minimum-step summary between mobile skills and the task list, with a labelled `48dp` primary action and expandable full dashboard.
- [x] Add dirty-draft `PopScope` protection to mobile AddSkill/AddTask routes; untouched forms still close directly and keyboard dismissal remains separate from route Back.
- [x] Replace mobile TopBar/ProfileBar stacking with one SafeArea identity header and captured-state secondary-actions sheet while preserving desktop chrome.
- [x] Split mobile `Сейчас` into Overview and Skill Focus with reorderable full-width level-XP progress cards, explicit `Обзор`, and one focus surface.
- [x] Move Inbox out of the mobile skill selector into a separate animated accordion while preserving its system ID and desktop presentation.
- [x] Add mobile `Путь навыка` as the default scroll route with runtime branch pills, safe details/templates sheets, and the existing canvas as `Свободная карта`.
- [x] Redesign mobile AddSkill around a live emblem, meaningful icon semantics/runtime categories, squircle colors, dirty-draft safety, and one bottom CTA.
- [ ] Extend automated accessibility gates beyond the journal: minimum tap targets, focus order, screen-reader traversal, and `200%` text scaling across dialogs/statistics/rewards at `360/393/430dp`.
- [ ] Add a device-local last-active skill/resumption context with an obvious return to the skill chooser; do not mix it into cloud-conflict domain state.
- [ ] Add a discoverability hint for mobile task swipe actions and retire it after first successful use.
- [ ] Shorten the mandatory first-run tunnel to first skill, first quest, and first useful completion; move RoadMap, statistics, trophies, and profile into optional tutorial modules.
- [x] Replace the local-save failure cloud icon with storage-neutral, device-specific copy while preserving dirty state and retry.
- [ ] Add delayed explanatory copy for unusually long startup loading without flashing it during normal fast startup.
- [x] Add a TextTheme-based mobile typography foundation and shared responsive constants for `360`, `393`, `430`, and `760` widths.
- [x] Add widget coverage for overflow, truncation, navigation, and dark/light rendering at `360/393/430/700dp` with `1.3x` text scaling.
- [ ] Polish mobile skill squircles with richer density options and optional circular progress after usage feedback.
- [ ] Add explicit accessibility labels for remaining mobile skill-panel controls.
- [x] Add a persisted device-local reduced-motion setting combined with the platform disable-animations flag across the journal, forms, bottom navigation, and mobile RoadMap transitions.
- [ ] Decide the final mobile placement/content density for the collapsed “Действовать сегодня” block after usage feedback.
- [ ] Revisit desktop/mobile skill-panel visual parity only if the mobile direction proves useful.
- [ ] Move mobile edit-skill and edit-task flows to full-screen routes after creation routes have usage feedback.
- [ ] Consolidate remaining non-form breakpoint checks around shared responsive constants.
- [ ] Polish mobile keyboard focus traversal and accessibility labels for icon/color form controls.
- [x] Run `Light Journal Palette Polish` for the mobile journal, creation forms, reward pills, and RoadMap surfaces without changing the desktop/global theme.
- [ ] Finish adopting the shared mobile typography scale in statistics/rewards secondary surfaces after physical-device and `200%` TalkBack review.
- [ ] Promote proven mobile journal values into a full design-token and `TextTheme` pass only after Polish audit feedback.
- [ ] Design `Streak model and stats`: define current streak semantics before adding persistence or richer momentum cards.
- [ ] Polish mobile RoadMap path labels/icons and branch disclosure after physical-device usage; do not rewrite `RoadmapEngine`.
- [ ] Extract shared field validation only if more creation forms adopt the same rules.
- [ ] Define a presentation-only Quest Log MVP over existing task/skill/stage IDs; do not add models, storage schema, XP rules, or RoadMap semantics in that batch.
- [ ] Run a five-scenario mobile usability check: first task, returning user, missing minimum step, dirty-form Back, and save-failure retry.

## P2 — RoadMap Layout

- [ ] Persist the desktop layout preference as a local per-device UI setting.
- [ ] Add keyboard shortcuts for desktop RoadMap orientation only if the toolbar toggle proves insufficient.
- [ ] Profile orientation transitions with very large multi-road maps and add a reduced-motion fallback if needed.

## P2 — Desktop Visual System

- [x] Replace the desktop Act composition with a reference-led three-panel shell; `761-1023dp` keeps the same system with a collapsed right rail instead of falling back to the legacy dashboard.
- [x] Add centralized desktop dark/light tokens and responsive sidebar/rail metrics without migrating global theme data.
- [x] Add real-data daily metrics, dense active/completed quest sections, focus progress, weekly activity, and current-level XP by skill.
- [x] Preserve profile/tutorial, debug-admin, RoadMap, trophies, statistics, skill reorder/edit/delete, and quest mutation entry points in the new shell.
- [x] Stabilize right-rail hover with local keyed row state and fixed geometry.
- [x] Reintegrate desktop Inbox as a content-led neutral workspace with green semantics, gold rewards, dense rows, and Enter submission.
- [x] Rebalance laptop sidebar width, compact skill rows, and halve the visual Settings footer allocation while preserving scroll ownership.
- [x] Unify mobile/desktop quest creation order and field anatomy; use a `10-500 XP` grid and move Minimum Step into Settings.
- [x] Migrate desktop Trophies, Statistics, and Settings into the persistent shell while preserving mobile/tutorial dialog flows.
- [x] Synchronize RoadMap focus with sidebar skill selection, refine camera centering, and preserve the approved canvas painter.
- [x] Replace persistent row action glyphs with stable hover/focus ellipsis menus and simplify the first-quest empty state.
- [ ] Revisit Smarter Quest product model, value proposition, and UX before re-enabling its creation/edit controls.
- [ ] Perform physical Windows QHD validation at 125% and 150% scaling, including pointer hover, drag handles, popup placement, and text density.
- [ ] Perform native macOS screenshot comparison at 1440/1920/2560 widths and tune only presentation tokens/spacing.
- [ ] Profile sidebar/main/right-rail rebuild cost with 20+ skills and a large completion history before adding selectors or state decomposition.
- [ ] Complete native visual recovery QA for `1.3.53`: RoadMap at 1/2/many stages and 1024/1366/1920 widths, all eight Statistics details, Trophies/Settings, rapid skill switching, and five-click Admin entry on macOS plus Windows QHD.

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

- [x] Add a list/editor stage reorder flow grouped by RoadMap road.
- [x] Allow stage reorder inside a non-branching road and reject cross-road or ambiguous DAG moves safely.
- [x] Preserve stage IDs, linked quest `treeNodeId` values, prerequisites, persistence and cycle safety.
- [ ] Design branching/shared-root/cross-road structure editing before allowing those moves.
- [ ] Before cloud sync, replace local list-position persistence with an explicit conflict-resolvable skill ordering token and a compatibility plan.
- [ ] Keep direct drag-and-drop on the RoadMap canvas out of this phase.

## P5 — Task Inbox / “Задачник”

- [x] Grant quick tasks a fixed isolated `+10 XP` on mobile and desktop with symmetric undo and daily XP/completed-action accounting.
- [x] Present quick tasks as a mobile Overview-only accordion with reward pills, without selecting Inbox as a normal skill.
- [ ] Add recurring inbox tasks only after the plain To-do flow has usage feedback.
- [ ] Add inbox tags/categories without mixing them into skill tags.
- [ ] Add “convert inbox task to skill quest” with explicit skill selection.
- [ ] Add inbox-specific stats if users need a lightweight done count.
- [ ] Add inbox search/filter once the list can grow.
- [ ] Consider a dedicated mobile inbox page if the compact Act card becomes crowded.
- [ ] Add notification/reminder support with explicit inbox-safe settings.
- [ ] Define cloud sync conflict rules for scoped tasks before adding sync.

## P6 — Milestone Animations

- [ ] Decide and test per-stage milestone feedback for percentages that do not land exactly on `25/50/100%`.
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
- [x] Create `flutter-dart-current-stack` for SDK compatibility and dependency-baseline checks.
- [x] Create `mobile-responsive-ux` for `360dp`, safe-area, typography, and adaptive route audits.
- [x] Create `roadmap-layout-audit` for paths, camera bounds, orientation, templates, and stage identity.
- [x] Create `goal-progress-modeling` for goal cycles, stage weighting, reset policy, and milestones.
- [ ] Create `desktop-pointer-hover-audit` for MouseRegion, transforms, overlays, and native hit testing.
- [x] Create `animation-performance-audit` for frame timing, repaint boundaries, image capture, and reduced-motion fallbacks.

## Release / Regression Hardening

Automated baseline completed on 2026-06-30:

- [x] Record Flutter `3.44.3`, Dart `3.12.2`, DevTools `2.57.0`, macOS `15.7.7` and Xcode `26.3` baseline.
- [x] Run `dart format lib test`, `flutter analyze`, `dart fix --dry-run` and the full regression suite without analyzer/fix findings.
- [x] Run coverage baseline: 10,200 of 16,458 lines, approximately `61.98%`.
- [x] Verify RoadMap templates, goal progress/history, milestone idempotency, mobile full-screen forms, vertical mode and skill/stage reorder regression coverage.
- [x] Verify debug admin runtime guards, isolated `__debug__` storage, Android backup prohibition, release signing guard and secret-scan configuration.
- [x] Revalidate notification state after permission awaits and remove task titles from lock-screen notification payloads.
- [x] Guard dialog/animation callbacks against running after widget disposal.
- [x] Build the macOS release app successfully.
- [x] Add QHD quest-count badge centering regression coverage.
- [x] Revalidate Android SDK `36.1`, accepted licenses, Android 16 emulator startup, debug APK assembly/install, and the release signing refusal on 2026-07-02.

Release blockers and deferred maintenance:

- [ ] Replace Android/iOS/macOS `com.example...` identifiers with final owned application and bundle identifiers before distribution.
- [ ] Provide a private `android/key.properties`; release Gradle correctly refuses release assembly without signing and never falls back to debug signing.
- [ ] Replace the default Flutter Android launcher icon/basic launch artwork with final RPG To-Do assets before store distribution.
- [ ] Migrate the app and affected plugins (`audioplayers_android`, `flutter_timezone`) to Flutter Built-in Kotlin in a dedicated dependency/build-system batch before the compatibility warning becomes an error.
- [ ] Install the matching iOS platform in Xcode and configure distribution signing; the iOS no-codesign probe is currently blocked because iOS `26.2` is not installed.
- [ ] Decide and document the iOS backup policy for local productivity data; Android backup is already disabled.
- [ ] Decide whether local task/profile/goal text requires encrypted-at-rest storage and a key-management plan before public distribution.
- [ ] Review whether `SCHEDULE_EXACT_ALARM` is required for store policy and every reminder mode.
- [ ] Decouple Android notification permission from exact-alarm capability, define an inexact fallback where acceptable, and show human-readable reminder scheduling failure instead of silent degradation.
- [ ] Bump the release build number from `+1` and verify platform version metadata before shipping.
- [ ] Migrate stale iOS/macOS CocoaPods integration to Swift Package Manager only in a dedicated build-system batch; do not accept automatic Flutter project churn blindly.
- [ ] Track the `objective_c` code-asset framework-name warning with the package maintainer or a vetted dependency update.
- [ ] Run dependency upgrades separately: `file_picker 8 -> 11`, `flutter_local_notifications 21 -> 22` and `build_runner` ecosystem changes require migration review; smaller updates should also be tested as one dependency-only batch.
- [ ] Install/run Gitleaks in CI or the release workstation; `.gitleaks.toml` and static checks exist, but the binary is not installed locally.
- [ ] Add integration/e2e setup for restart persistence and native notification behavior; keep broad AppState decomposition separate.

Manual mobile checklist (`~360dp`, real device preferred):

- [ ] Home opens; identity header, compact skill selector, quick-task shortcut and selected-skill focus remain readable.
- [ ] AddSkill/AddTask full-screen routes survive keyboard open/close and save/cancel.
- [ ] Quick task attaches to `Задачник`; skill-local task attaches to the selected stable skill ID and no random stage.
- [ ] RoadMap opens vertical-only; fullscreen/orientation toggle stay hidden; centering and stage reorder controls remain usable.
- [ ] Next Goal, goal history and `25/50/100%` milestone banner fit without clipping or duplicate replay.
- [ ] Theme transition and skill-panel animations remain smooth with reduced-motion platform settings.

Manual desktop/QHD checklist:

- [ ] Home, skill hover region, drag handles and quest-count badge look correct on macOS and Windows at QHD scaling.
- [ ] AddSkill/AddTask remain dialogs; RoadMap defaults horizontal, toggles vertical and opens fullscreen correctly.
- [ ] Skill/stage reorder persists after restart and keeps selection by stable ID.
- [ ] Complete task/stage, inspect progress/milestone once, set next goal and verify archived goal history after restart.
- [ ] Verify release build has no debug-admin entry, debug logs or debug storage access.

## 1.3.52 Recovery Audit

- `1.3.52` audit result: RoadMap shell/templates, Trophies, Statistics/details, Settings, raised skill header, history-aware empty state, Admin entry, and centering were PARTIAL or MISSING despite completed TODO marks.
- `1.3.53` recovery: implemented dedicated presentation compositions over existing domain sources, bounds-based RoadMap camera fit, fixed action geometry and transitions, and an explicit non-release Admin policy.
- Automated verification is complete; native side-by-side screenshot and pointer QA remains MANUAL QA PENDING and is not counted as completed.
- Full requirement/evidence/status matrix: `docs/1.3.52_RECOVERY_AUDIT.md`.

## Recently Completed

- `1.3.53`: recovered the incomplete `1.3.52` visual migration with a real RoadMap shell/templates/context rail, complete Trophies and Statistics ecosystems, full existing Settings coverage, responsive raised skill headers, history-aware empty states, stable overflow geometry, bounds-based camera fitting, and tested debug/profile Admin entry.
- `1.3.52`: introduced workspace routes and initial wrappers, but its visual migration remained incomplete; superseded by the audited `1.3.53` recovery.
- `1.3.51`: completed Desktop Continuity & Quest Creation Refinement with stable right-rail hover, content-led desktop Inbox, unified quest form order, `10-500 XP` selection, nested Minimum Step settings, hidden SMARTER controls, continuous desktop breakpoints and denser laptop sidebar proportions.
- Desktop Visual System Redesign Epic: added an adaptive `>=761dp` desktop workspace, compact profile/navigation/skill sidebar, real daily metrics, skill-XP header, dense active/completed quest rows, and a contextual focus/history/skill-XP rail while preserving the existing mobile shell, domain logic, dialogs, RoadMap, and storage.
- Mobile Polish Audit: added device-local reduced motion, shared `360/393/430/760` metrics and mobile typography tokens, warm Light Journal surfaces, stronger light reward/accent contrast, selected bottom-navigation semantics, reading-order form traversal, and accessibility regression coverage. Physical TalkBack/profile-mode validation remains pending.
- `1.3.49`: added mobile skill long-press/swipe edit and delete actions, a safe Focus delete action, explicit edit-mode save copy, XP-based skill rings, mobile statistics close, and bottom-right RoadMap return actions.
- `1.3.49`: completed quests stay visible until the user swipes them into the persisted `Выполнено` archive; restore keeps earned XP, while uncomplete clears the archive state.
- `1.3.49`: mobile AddSkill removes duplicate field labels and uses disappearing in-field guidance for skill name and goal.
- Mobile UI Corrective Patch v3: removed mobile next-action banners, anchored the separate Inbox after an adaptive focus placeholder, animated keyed Overview/Focus transitions, removed goal progress from mobile Focus, unified active/completed compact quest rows with long-press editing and a dashed CTA, and rebuilt AddSkill around a labelled 12-icon catalog plus an exact `6 × 2` glowing color grid without domain or desktop changes.
- Corrective Patch v2: removed the mobile Focus chip strip and duplicate next-action surface, added a natural-height skill-tinted focus card with neutral quest rows and one CTA, and unified ordinary/Inbox rewards through an amber `XpRewardPill` without changing XP logic, models, storage, RoadMap, AddSkill, or desktop composition.
- Mobile Visual System Redesign Epic: introduced dark-first local journal tokens, Overview/Focus states, honest momentum, level-XP skill cards, an Inbox accordion with isolated `+10 XP`, mobile path/free-map RoadMap modes, live-emblem AddSkill, lightweight reduced-motion transitions, and `360dp/200%` regression coverage without goal-formula, RoadMap-engine, package, or desktop composition changes.
- Mobile Visual Hierarchy Redesign MVP: unified the mobile identity header and secondary-actions sheet, separated quick tasks from reorderable skill chips, preserved the global next-action source, consolidated skill focus, calmed RoadMap visuals/templates, improved AddSkill hierarchy/targets, and added responsive dark/light widget coverage without model or storage changes.
- Mobile UX Quick Wins: mobile Act now shows a compact next action before the task list, minimum steps have a direct `48dp` CTA, empty skills guide quest creation, dirty AddSkill/AddTask routes confirm discard on close/Back, and local save failures use calm device-specific recovery copy with focused widget coverage.
- Android toolchain revalidation: Flutter now detects SDK/build-tools `36.1`, JDK 21 and accepted licenses; debug APK assembled, installed and launched on an Android 16 emulator without AndroidRuntime/Flutter errors, while release assembly stopped at the intentional private-signing guard.
- Storage Reliability Epic: added observable load/save/dirty/failure status, blocking startup recovery with retry, responsive save-failure retry, immediate error observation for background saves, and failed-load write gating; added a versioned full-app snapshot with payload validation, commit marker last, previous fallback, and additive legacy migration.
- Storage reliability characterization: added deterministic fake-storage fault injection, reproduced partial clear-and-write snapshots, cross-domain inconsistency and startup-load overwrite risk, and documented a status/guard-first recovery path followed by snapshot/manifest persistence in `docs/STORAGE_RELIABILITY_PLAN.md`.
- Local workflow skills: created and validated `flutter-dart-current-stack`, `flutter-upgrade-audit`, `mobile-responsive-ux`, `roadmap-layout-audit`, `goal-progress-modeling`, and `animation-performance-audit` in the project skill library.
- Full crash/static/release audit: hardened every mutable model-list boundary, normalized invalid reminder times, made optional notification/file-picker failures non-fatal, closed a dialog controller leak, and documented storage reliability/release follow-ups in `docs/CODE_REVIEW_REPORT.md`.
- Quest creation stabilization: removed the redundant “раз в 3 дня” choice for new habits while preserving legacy edits, and normalized mutable model lists to prevent fixed-length crashes during subtask/checklist synchronization.
- RoadMap/Rewards/Inbox polish: horizontal terminal insertion now centers between orb edges, Effects opens expanded by default, and active quick-task counts use the same compact circular badge in the Inbox panel and skill lists.
- RoadMap vertical insertion polish: add-stage actions now sit between the visible upper label text and lower orb, use a fixed `170dp` spread plus shared visual geometry, and keep long and mobile paths auto-fitted without changing horizontal layout or persistence.
- RoadMap interaction polish: deleting a quest keeps its skill selected, every terminal-stage-to-skill connection exposes the existing safe extend-path action, and desktop orientation icons now match their resulting layouts.
- RoadMap progress polish: skill-orb rings now visualize derived goal completion while a separate compact bar under the level number shows XP progress toward the next level.
- Rewards polish: removed duplicate chest/effect summary cards and moved the existing expandable buffs section to the top under the simpler “Эффекты” title.
- Desktop skill-list polish: quest-count badges use explicit line-height and geometric centering for stable QHD rendering.
- RoadMap Vertical Mode MVP: desktop now switches between horizontal and vertical canvas layouts from the toolbar and fullscreen, mobile always uses vertical roads, the skill anchors the top while terminal and earlier stages continue downward, vertical bezier links and insertion actions preserve the existing DAG, and adaptive camera auto-fit covers `0`, `1`, `3`, and `10` stage scenarios without model/storage changes.
- Mobile Skill Experience MVP: mobile Act now starts with informative skill squircles showing level, active quest count and existing RoadMap goal progress; selecting by stable skill ID transitions to compact chips, while “Действовать сегодня” moves below tasks and starts collapsed. Desktop composition and data/storage models remain unchanged.
- Mobile AddSkill/AddTask creation: routes below `760px` now reuse the existing forms in full-screen `SafeArea` pages with scroll/keyboard safety, visible validation, stable skill/stage context, cancel/save navigation, and desktop dialog preservation.
- Task Inbox / “Задачник” MVP: added a permanent system skill with stable ID, title-only quick add, isolated completion/undo/delete UI in Act, storage compatibility for legacy tasks, and regression coverage proving quick tasks update only profile/today XP and completed-action count without affecting skill XP, RoadMap progress, history, achievements, rewards, resistance, or normal skill quest counts.
- Milestone Animations MVP: persisted `25%`, `50%`, and `100%` goal milestone thresholds per skill/current goal, detects progress crossings from stage mastery, marks all crossed thresholds while showing only the strongest non-blocking banner for one action, and keeps sound deferred.
- Start New RoadMap MVP: after setting the next goal, users can keep the current map, add a manual stage, or explicitly create a new empty active RoadMap; the old completed map is stored as an append-only `CompletedRoadmap` snapshot and surfaced in the timeline. Template-based new RoadMap creation remains disabled pending `RoadMapRecord` / `activeRoadMapId` boundaries.
- Goal History MVP: completed goals are archived as immutable per-skill snapshots during explicit Next Goal confirmation and appear in the existing growth timeline; legacy skills load with an empty archive.
- Next Goal Flow MVP: added an explicit `100%` CTA and validated goal input; updating the goal keeps all RoadMap stages, mastery, quests, XP and IDs intact, with no schema migration or automatic reset.
- Skill Goal Progress MVP: added derived equal-weight RoadMap stage progress, neutral empty state, `100%` completion copy, skill-card and RoadMap detail UI, plus unit/widget coverage without storage changes.
- Skill Goal Progress MVP follow-up: keep `25/50/100` animations, `100%` sound, and progress in future mobile bubbles/squircles deferred to their existing P1/P6 batches.
- `1.3.47`: added centralized skill reordering that preserves selection, quests, RoadMap links, XP and stable skill IDs.
- `1.3.47`: added desktop drag handles and mobile long-press reordering with stable item keys; current local order survives save/load through the existing skill-list persistence order.
- `1.3.47`: audited stage ordering and deferred it because RoadMap rendering, template reuse and next-stage tie-breaking still depend on DAG topology plus raw `treeNodes` order.
- Reorder & Structure Editing MVP: linear RoadMap roads can now be reordered from a dedicated list editor; the operation rewires prerequisites while preserving stable stage IDs, linked quests, mastery, XP and persisted order.
- Reorder follow-up: canvas drag/drop, branching/shared-root edits, cross-road moves, keyboard reordering and sync-friendly explicit order tokens remain deferred.
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
