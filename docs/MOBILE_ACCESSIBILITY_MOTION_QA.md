# Mobile Accessibility, Motion, And Usability QA

Updated: 2026-08-18

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
- XP bars begin at their persisted value, animate later changes with bounded
  motion, and skip interpolation when reduced motion is active. Completion
  confetti is local to the feedback surface rather than a global particle
  layer.
- At `360 x 800` and `2.0x` text scale, Profile, Trophies, Statistics, Daily
  victories, Weekly analytics, and Chronicle render as full-page SafeArea
  routes. Nested Statistics routes unwind back to Statistics and then Act.
- Profile additionally has responsive coverage at `360`, `393`, and `430dp`;
  its banner/avatar hero stays in scroll flow instead of relying on a
  page-level absolute offset. Chronicle has a long-history test that verifies
  the mobile sliver list does not eagerly build distant events.
- The Overview Inbox is geometry-tested as a dock above navigation; expansion
  is height-bounded and Android Back collapses it before leaving Act.
- Welcome is covered at `360`, `393`, `430`, `700`, and desktop widths in dark
  and light themes, including `1.3x`/`2.0x` text scale and reduced motion. Its
  route/CTA semantics remain explicit and decorative path art is excluded.
- Core tutorial regression coverage verifies Skill -> Quest -> first useful
  action without automatic Task completion or XP. Optional modules are started,
  skipped, and replayed independently.
- Tutorial spotlight readiness is frame/layout based, bounded, and falls back
  to a dismissible card when a target is unavailable; there is no fixed
  two-second transition timer.

## Opt-in Frame Timing

The app does not assume or hardcode a refresh rate. Enable the bounded
profile-mode monitor with:

```bash
flutter run --profile --dart-define=RPG_FRAME_TIMINGS=true
```

The flag does not start a capture during launch. Open Debug Admin and trigger a
named preset for the interaction being measured: RoadMap orientation, RoadMap
open, Act scrolling, Inbox expansion, a Profile secondary page, or a manual
scenario. Each capture listens to the next bounded set of rendered frames and
then detaches automatically. The `rpg.frame_pacing` diagnostic reports the
scenario label, Flutter's actual display refresh rate when available, frame
count, sample duration, average and p90/p95/p99 build, raster, and total
durations, frames over the refresh-rate frame budget, and the dominant
bottleneck. The monitor does not schedule frames or run a timer.

Record Android device/model and display mode or the macOS display/window setup
with the output. A successful build or a nominal 120/144/165 Hz display is not
evidence that the app met that budget; only the measured sample is. Reduced
motion remains the fallback for non-essential transitions, not a substitute for
profiling.

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
- [ ] Repeat each matching Debug Admin frame-timing preset with
  `--dart-define=RPG_FRAME_TIMINGS=true` on 60 Hz and available high-refresh
  modes; save the labelled build/raster percentiles and over-budget count.
- [ ] Review Light Journal outdoors/at high brightness and dark mode at low
  brightness.
- [ ] Verify Profile, Trophies, Statistics, Daily victories, Weekly analytics,
  and Chronicle as full-page routes: Android Back closes one route at a time,
  text remains usable at `2.0x`, and no route transition drops frames in
  profile mode.

## Five-Scenario Usability Script — Pending Physical Run

1. **First task:** fresh state -> create skill -> create quest -> complete it;
   verify Welcome/Core finish before the real completion, then verify XP and
   `Закрыто сегодня` only after the user completes the quest.
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
- Run Welcome plus every optional tutorial module with TalkBack/VoiceOver at
  `1.0x`, `1.3x`, and `2.0x`; automated semantics do not prove comfortable
  spoken order on a physical device.

## Desktop Runtime Boundary

Window size, placement, and maximized state are intentionally native-only and
do not notify mobile or desktop Flutter domain state. The restoration policy
and physical macOS/Windows checklist are documented in
`docs/DESKTOP_WINDOW_STATE.md`. Native multi-monitor and Windows DPI validation
remain manual platform gates.
