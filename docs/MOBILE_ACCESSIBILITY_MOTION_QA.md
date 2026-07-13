# Mobile Accessibility, Motion, And Usability QA

Updated: 2026-07-03

## Automated Coverage

- Responsive journal smoke coverage: `360`, `393`, `430`, `700`, and `760dp`.
- Text scaling: journal at `1.3x` and compact `360dp` at `2.0x`.
- AddSkill icon/color controls expose meaningful labels and selected state.
- Quest checkbox and XP reward pill expose action/reward semantics.
- Bottom navigation exposes the selected tab.
- RoadMap stages expose title, state, and linked-quest progress.
- App and platform reduced-motion requests both produce zero-duration mobile
  transitions; the app preference persists in device-local metadata.
- Dark/light palette tokens have regression checks for strong-text and reward
  contrast.

## Physical Android Gate — Pending

Run on a real Android phone in profile mode. Record model, Android version,
refresh rate, and whether any interaction exceeds the frame budget.

- [ ] Launch with TalkBack and traverse profile, momentum, skill card, Inbox,
  bottom navigation, Focus quest, checkbox, reward, and RoadMap node.
- [ ] Confirm decorative icons are not announced twice and controls are read in
  visual order.
- [ ] Increase Android font and display size; repeat at effective `1.3x` and
  `2.0x` without clipped primary actions.
- [ ] Verify one-handed tap targets, swipe actions, and long-press edit do not
  conflict with quest checkboxes.
- [ ] Enable Android reduced motion, then app `Снизить анимации`; inspect
  Overview/Focus, Inbox, AddSkill, RoadMap, and theme switching.
- [ ] In `flutter run --profile`, inspect Overview scrolling, Focus open/close,
  completion/undo, Inbox expansion, keyboard open/close, RoadMap scrolling, and
  dark/light switching in DevTools Performance.
- [ ] Review Light Journal outdoors/at high brightness and dark mode at low
  brightness.
- [ ] Verify Profile, Trophies, Statistics, Daily victories, Weekly analytics,
  and Chronicle as full-page routes: Android Back closes one route at a time,
  text remains usable at `2.0x`, and no route transition drops frames in
  profile mode.

## Five-Scenario Usability Script — Pending Physical Run

1. **First task:** fresh state -> create skill -> create quest -> complete it;
   verify XP and `Закрыто сегодня`.
2. **Returning user:** open existing state -> choose skill -> inspect/complete a
   quest -> return to Overview; selection and Back remain predictable.
3. **Missing minimum step:** open a quest without a minimum action; verify the
   UI remains calm, readable, and does not imply one exists.
4. **Dirty-form Back:** edit AddSkill, AddTask, and existing task; Android Back
   must preserve the draft until discard is confirmed.
5. **Save-failure retry:** inject an existing fake-storage failure; verify
   device-specific copy, preserved dirty state, and successful retry.

## Deferred Findings

- Complete TalkBack traversal and `200%` tests for statistics and rewards after
  the physical pass; their information density needs observation, not blind
  compression.
- Profile mobile theme-switch frame timing before changing the existing
  snapshot transition.
- Revisit RoadMap branch disclosure and long labels only from physical-device
  evidence; do not rewrite `RoadmapEngine` or graph semantics in a polish batch.
