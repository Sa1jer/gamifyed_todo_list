# DESIGN / Product And UI Notes

Last updated: 2026-06-20

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
- Empty `Сейчас` shows a light primer: `1. Навык -> 2. Этап -> 3. Квест`.
- Clear CTA to create the first skill.
- Empty `Карта` should gently point back to `Сейчас`, not become a separate onboarding surface.

Future onboarding:

Current `1.3.33` onboarding:

- Animated spotlight over the real `Создать первый навык` CTA.
- Shows once on fresh empty state and saves `onboardingSeen`.
- Can be replayed from profile/settings.
- Skippable and non-blocking.
- Teaches the core loop by highlighting real controls.
- Does not rely on fake/demo content in production builds.

Future tutorial polish:

- Consider multi-step spotlight only after the current one-step primer is validated.
- Keep replay optional and quiet; do not turn onboarding into a mandatory wizard.

## Release QA Rules

- Test fresh and populated flows before public builds.
- Check widths: `360`, `393`, `430`, `760`, `980+`.
- Run copy audit for old user-facing terms: `задачи`, `узлы`, `баффы`, `боссы`, `Прогресс`.
- Keep known non-blockers explicit in `TODO.md`.

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
