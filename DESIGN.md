# DESIGN / Product And UI Notes

Last updated: 2026-06-23

This file records design direction, product guardrails, and UI decisions. Update it after every meaningful product/UI change so implementation stays aligned with the app's intended mental model.

## Product Core

The core loop remains:

`Навык -> Этап -> Квест -> Минимальный шаг -> XP -> Рост`

Every new feature should answer:

- Does this help the user make the next useful quest easier?
- Does this clarify the path of mastery?
- Does this reduce or increase UI noise?

If a feature does not serve the core loop, it should be hidden, delayed, or treated as secondary.

## Current Navigation Model

Primary modes:

- `Сейчас`: the main action surface. Shows what to do now.
- `Карта`: RoadMap/path view. Shows stages, roads, and practice context.

Secondary top-bar entries:

- `Трофеи`: feedback after actions, not daily work to manage.
- `Статистика`: former Progress area, now secondary. Opens as dialog on desktop and as a secondary screen on mobile.

Design implication:
`Статистика` should be useful but should not compete with `Сейчас / Карта`.

Current `1.3.35` nudge decision:

- Former Planning does not return as a section.
- Course correction appears as one derived `Следующая корректировка` card inside `Статистика -> История роста`.
- The card is review-driven and offers one action only.
- `Позже` is session-only and not persisted.
- Act stays action-first and does not show nudges in this iteration.

Current `1.3.36` statistics cleanup:

- `WeeklyReviewCard` and `Следующая корректировка` are grouped into one `Review цели` block.
- The block explains course correction as one small adjustment after reflection, not as a system audit.
- Deeper charts and journals stay below this block.

Current `1.3.34` Planning decision:

- `План` is frozen and removed from the app shell.
- Planning is not a primary mode and not a skill settings surface.
- Act and RoadMap no longer expose `Настроить` routes into Planning.
- `PlanningWorkspace` remains in the repository as dormant reference code only.
- If Planning returns, it should be redesigned from first principles instead of restoring the overloaded dashboard.

## Visual Decisions

### Top Bar

- `Трофеи` and `Статистика` use the same pill button visual language.
- They sit together in the top-right cluster.
- They are secondary utilities, not primary navigation tabs.
- The app version is shown quietly above the app title in the top-left header, using muted gray so it is available for QA/support without becoming navigation.

### Statistics

- Desktop `Статистика` opens as a centered, wider dialog with an approximate `16:10` proportion.
- The wider shape should make statistics feel like a secondary overview surface, not a cramped modal or a primary full-screen mode.
- Tutorial inside Statistics uses the same orange spotlight/highlight pattern as the rest of onboarding; avoid separate card styles that feel like another product.

### Today Dashboard Stat Cards

- Stat-card icons are large and placed on the right side, vertically centered.
- Text/value remains left-aligned.
- Icons should feel decorative/supportive, not like extra buttons.
- Current adjustment: icon size `28`, nudged slightly left from the right edge.

### RoadMap

- RoadMap should feel like a path toward a skill, not a generic graph editor.
- Selected skill focus mode should prioritize roads/stages and keep controls quiet.
- If no bubble is selected, a small top-right `Отцентровать` button recenters the camera.
- Template controls should not become a noisy control panel.
- Current `1.3.37`: skill bubbles remain the direct entry into RoadMap focus mode.
- Current `1.3.37`: skill-level details do not show a full task list; users choose a stage to see practice.
- Current `1.3.37`: practice rows are not quest-focus buttons; direct row actions are completion, `Минимум`, and edit.
- Current `1.3.37`: RoadMap quest rows may show `Минимум` only when a minimum step is actually available.
- RoadMap minimum action must reuse the same XP/feedback flow as `Сейчас`, not create a separate map-only action path.
- Current post-`1.3.42`: RoadMap stages can be renamed from a small pencil icon beside the stage title in desktop and mobile detail panels.
- Stage naming should stay lightweight: rename is an inline title action, not a separate button or roadmap editor mode.
- When a focused skill has no stages, its orb should sit near the center of the usable canvas area. As stages are added, the orb may move right to make room for the road, while the existing auto-fit scaling remains responsible for fitting content.
- Skill-level RoadMap details may show only quests that belong to the skill but are not linked to a RoadMap stage.
- Selected skill details show the path goal as the title subtitle, then unlinked quests first and collapsible groups for stages that have quests; selected stage details show a plain quest list without another wrapper.
- Stage count / mastered count should not appear as separate chips in selected skill details; the canvas and RoadMap itself should carry that structure visually.
- RoadMap skill and stage bubbles should be large enough to feel tactile; current baseline is 20% larger than the earlier compact map.

### Planning

Planning is the riskiest surface for overload.

Current design tension:

- It can help users repair their system.
- It can also become an admin dashboard with too many diagnostics.

Current `1.3.34` decision:

- Freeze Planning and remove user-facing entry points.
- Do not add new Planning diagnostics or settings.
- Keep setup pressure in existing lighter surfaces: creation flow, RoadMap stage actions, task edit dialogs and profile/settings.
- Do not let Planning return as a dashboard/audit center.

### Review-To-Action Nudges

Design rule:
Nudge is not a new task type, not a status, and not an inbox. It is a small moment of course correction after reflection.

Allowed:

- One card at a time.
- One reason.
- One primary CTA.
- Runtime-only dismiss.
- Derived from current skills, reviews, quests and stages.
- Placement inside `Review цели`, not as a standalone planning panel.

Not allowed:

- Lists of issues.
- Readiness dashboard.
- Persistent pending/applied/dismissed nudge state.
- Showing in `Сейчас` before the behavior is validated.
- Turning `Статистика` into a new Planning surface.

Action hierarchy:

- Actionable review focus can become a prefilled quest.
- Vague focus asks for clarification instead of creating a bad quest.
- Missing minimum step opens the existing quest with minimum-step focus.
- Active stage without practice opens a prefilled stage quest.
- Weak goal opens existing skill edit, not a SMARTER wizard.

## Tooltip / Hint Direction

Current issue:
The app has too many hover tooltips and contextual hints.

Current direction:

- Global `Подсказки при наведении` switch exists in profile settings.
- Keep accessibility semantics separate from hover-tooltip visibility.
- Avoid explaining obvious buttons repeatedly.
- Use FAQ/onboarding for deeper concepts.
- Signed navigation buttons should not repeat themselves on hover; keep tooltips for compact icon-only states and risky/unclear actions.

Potential taxonomy:

- Essential: destructive actions, unclear icon-only actions, onboarding-critical steps.
- Helpful but optional: RoadMap controls, advanced settings.
- Noisy: repeated labels, obvious hover hints, duplicate explanations.

## First-Run Principles

Fresh install must not contain developer data.

Current first-run state:

- No skills.
- No quests.
- No history.
- No trophies/effects/resistance events.
- Empty `Сейчас` shows a light primer in plain text, without the numbered core-loop chip strip.
- Clear CTA to create the first skill.
- Creating the first skill creates only the skill by default; the first stage is optional.
- The first quest is a separate guided action after the skill exists.
- Empty `Карта` should gently point back to `Сейчас`, not become a separate onboarding surface.

Tutorial system:

- Animated spotlight over the real `Создать первый навык` CTA.
- If the first path is replayed with existing data, it starts from the first useful missing step: skill, quest, or first action.
- Continues to the `Первый квест` CTA after the first skill is created.
- Continues after first quest creation to `Первое действие`, but the tutorial card does not perform the quest for the user.
- `Первое действие` uses a single `Понятно` button to continue; real quest/minimum actions still advance the flow when the user chooses to act.
- After each completed step, the next spotlight waits about 2 seconds and then fades/scales in.
- `XP и рост` points toward `Карта`, then RoadMap explains the skill bubble, the road canvas and the right-side details panel.
- Statistics opens with the same orange spotlight-style tutorial and `Завершить обучение` action instead of completing invisibly before the user sees the screen.
- Finishing the core Statistics step continues to `Трофеи и эффекты`; replaying the standalone Statistics module still ends after that module.
- `Трофеи и эффекты` teaches from inside the rewards dialog with the same orange spotlight language, then continues into the profile/help topic.
- The secondary tutorial dismiss action is named `Пропустить обучение`; buttons like `Понятно` are reserved for advancing a specific lesson step.
- Finishing the trophies topic continues to the profile/help topic so the replay path has a clear ending.
- Primary tutorial actions temporarily hide the overlay while the real creation dialog is open.
- Creation dialogs use inline hints for onboarding guidance instead of nested spotlights or wizard steps.
- Saves per-module tutorial progress in meta storage; legacy `onboardingSeen` remains as fallback for the first module.
- Can be replayed from profile/settings through `Пройти обучение заново`.
- Modules: `Первый путь`, `Сейчас`, `RoadMap`, `Статистика`, `Трофеи и эффекты`, `Профиль`.
- Skippable and non-blocking.
- Teaches by highlighting real controls when possible and using centered fallback cards when the target is not present.
- Does not rely on fake/demo content in production builds.

Future tutorial polish:

- Validate target positioning on Android widths and reduce copy where it feels repetitive.
- Keep replay optional and quiet; do not turn onboarding into a mandatory wizard.

## Skill Creation Direction

Current decision:

- `AddSkillDialog` should stay light: name, goal, icon, color and optional first stage.
- The selected skill preview icon sits between the dialog title and the skill name field, so the form immediately feels like “creating a skill identity”.
- Color choices are rainbow-ordered and include 12 options; neutral gray remains last and the extra pink/magenta option stays out of the default palette.
- New skills do not auto-create a quest.
- SMARTER helper UI is frozen/hidden from the skill form. Goal quality may return later as quiet review/nudge logic, not as a visible setup block.
- Skill checklist/criteria editing is frozen and hidden from the creation/edit dialog.
- First stage is optional and starts empty: the user can create a skill now and build the RoadMap later.
- Existing checklist data remains in models/storage for compatibility, but should not re-enter the default UX without a new product decision.

Rationale:

- The first form should not feel like a wizard.
- The user should understand the skill direction before being asked to define practice.
- The first quest belongs to the next guided step, not the skill form.
- Deleting a skill requires confirmation because it removes the skill level/XP context, RoadMap stages and linked quests.

## Quest Creation Direction

Current decision:

- `AddTaskDialog` should prioritize: quest title, XP, minimum step, then optional RoadMap/stage settings.
- `Поведение квеста` belongs in advanced settings and includes type, habit repeat rhythm and reminder.
- `Контексты` are removed from the visible quest form. Existing `Task.tags` remain only for compatibility.
- Manual priority/focus controls are frozen in the UI. Priority can remain as legacy data/tie-breaker but should not look like a primary user choice.
- Stage linking is called `Этап в дорожной карте`, not `Этап мастерства`, to match the RoadMap mental model.
- New quests start with `Минимальный шаг` disabled unless a concrete initial minimum is passed by a nudge or other prefill flow.
- Quest descriptions are optional lightweight context below XP. They should appear quietly next to the quest title in action/task widgets, but RoadMap practice rows should not show descriptions unless the user opens edit.
- `SMARTER квеста` is a quiet quality helper, not validation. It only checks what the form can know: specificity, measurable signal, easy start, growth/RoadMap link and rhythm.
- The quest save action follows the selected skill color, so creation feels attached to the skill context.

Rationale:

- The quest form should not become a configuration survey.
- XP can stay visible because it is immediate feedback, but advanced system fields should not compete with the first action.
- RoadMap linkage is useful only when it clarifies where the quest belongs.

## RoadMap Entry Direction

Current decision:

- The old `SkillTreeDialog` is no longer a user-facing entrypoint from skill cards.
- The skill-card route/tree action now opens the main RoadMap screen focused on that skill.
- Stage data and `SkillTreeNode` remain compatible under the hood; only the outdated visual surface is bypassed.

Rationale:

- There should be one RoadMap surface, not a legacy mastery-map dialog plus the modern RoadMap.
- Opening RoadMap in focus mode preserves the user intent: “show me this skill path”.

## Release QA Rules

- Test fresh and populated flows before public builds.
- Check widths: `360`, `393`, `430`, `760`, `980+`.
- Run copy audit for old user-facing terms: `задачи`, `узлы`, `баффы`, `боссы`, `Прогресс`.
- Keep known non-blockers explicit in `TODO.md`.

Current `1.3.38` release QA status:

- Regression checks are green.
- Stale user-facing `Прогресс` copy in Statistics was replaced.
- Remaining old terms are either documentation, dormant Planning/legacy stage code, or compatibility classifiers.
- Real-device/emulator width QA is still recommended before packaging a public build.

Current `1.3.39` crash-fix status:

- Achievement details must not read `AppStateProvider` from dialog builder contexts when local state is already available.
- Dialog/sheet builder contexts should be treated as potentially detached from the app provider unless explicitly wrapped.

## Debug Admin Direction

- Debug Admin is a state simulator, not an Achievement Editor.
- It must stay debug-only and hidden behind a gesture; no visible release entry.
- Planned entry: 5 taps on the top-bar app icon under `kDebugMode`.
- Persistence: separate `__debug__` Hive box with debug-only draft overrides, outside production `StorageService` and `AppState._saveAll()`.
- `AppState` must not import `DebugService`.

Current `1.3.42` debug simulator status:

- Hidden entry exists through 5 taps on the top-bar app mark under `kDebugMode`.
- Debug Admin lazy-initializes `DebugService` only when opened.
- Debug draft state stores the selected simulator scenario and remains separate from production data.
- Debug Admin shows storage status and can clear only `__debug__` after confirmation.
- Core simulator scenarios can mutate AppState only after explicit confirmation.
- Scenario state is saved through existing AppState persistence so test worlds survive restart in debug app data.
- `Новый пользователь` resets first-run tutorial state and should behave like a real fresh install.
- No production storage schema changes or `AppState -> DebugService` imports exist.

## XP Editing Direction

Where XP can be changed by slider, numeric editing should eventually be available by tapping/clicking the number.

Design rules:

- Slider remains good for quick adjustment.
- Text input is available for precision on editable XP badges.
- Both controls must stay synchronized.
- Avoid turning XP into the primary decision in basic quest creation.

## Language Lock

Preferred user-facing language:

- `Квест`, not `задача`, for user actions.
- `Этап`, not `узел`, for mastery path nodes.
- `Минимальный шаг`, not `минимальное действие`, unless compact UI requires `Минимум`.
- `Пассивный эффект`, not `бафф`, unless referring to internal/legacy names.
- `Сопротивление`, not `босс`, unless referring to legacy/internal systems.
- `Трофеи`, not generic `награды`, for feedback layer.

Code-level names may remain technical for compatibility.

## Update Discipline

After every implementation pass:

- Update `TODO.md` with what changed and what remains.
- Update this file if the change affects product language, navigation, hierarchy, or component behavior.
- Keep documentation honest: if something feels unresolved, record it instead of burying it in code.
