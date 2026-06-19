# DESIGN / Product And UI Notes

Last updated: 2026-06-19

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
- `План`: frozen until keep/rework/remove decision. Should not receive new visible complexity.
- `Карта`: RoadMap/path view. Shows stages, roads, and practice context.

Secondary top-bar entries:

- `Трофеи`: feedback after actions, not daily work to manage.
- `Статистика`: former Progress area, now secondary. Opens as dialog on desktop and as a secondary screen on mobile.

Design implication:
`Статистика` should be useful but should not compete with `Сейчас / План / Карта`.

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

### Planning

Planning is the riskiest surface for overload.

Current design tension:

- It can help users repair their system.
- It can also become an admin dashboard with too many diagnostics.

Rule until redesign decision:

- Planning is frozen: do not add new features or diagnostics.
- Do not add new visible diagnostics to Planning by default.
- Keep active quests above system analysis.
- Prefer one main improvement over a full audit.

## Tooltip / Hint Direction

Current issue:
The app has too many hover tooltips and contextual hints.

Current direction:

- Global `Подсказки при наведении` switch exists in profile settings.
- Keep accessibility semantics separate from hover-tooltip visibility.
- Avoid explaining obvious buttons repeatedly.
- Use FAQ/onboarding for deeper concepts.

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
- Clear CTA to create the first skill.

Future onboarding:

- Animated, focused, and skippable.
- Should teach the core loop by highlighting real controls.
- Should not rely on fake/demo content in production builds.

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
