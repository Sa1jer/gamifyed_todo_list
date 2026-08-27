# Welcome And Tutorial Architecture

Last updated: 2026-08-27

## Product Boundary

First-run guidance has three deliberately separate layers:

1. **Welcome** explains the product promise and local-data boundary before the
   application shell appears.
2. **Core tutorial** teaches only `Навык -> Квест -> первое полезное действие`.
3. **Optional modules** explain Act, RoadMap, Growth, Trophies, and Profile on
   demand. Completing or skipping one optional module never starts another.

Welcome and tutorials do not create sample Skills or Tasks, complete a Task,
grant XP, or alter Goal, RoadMap, reward, history, or Inbox semantics. The Core
final step is an acknowledgement: the user can complete a real action later.

## Startup Order

```text
application start
  -> StorageService load
  -> PersistenceGate
       -> load failure: recovery UI
       -> successful load: AppState decides Welcome visibility
            -> unseen fresh install: Welcome
            -> existing install or Welcome seen: application shell
```

Recovery always wins. Welcome is never rendered while startup data is failed or
unresolved. Pressing `Начать` saves the device-local Welcome marker and starts
the first relevant Core step without changing domain data.

## State And Compatibility

- `welcomeSeen` is a device-local preference owned by `StorageService`. It is
  intentionally outside `StorageSnapshot`, Hive domain payloads, and future
  account/cloud conflict state.
- `onboardingSeen` and `TutorialProgress` keep their existing persisted shape
  for backward compatibility.
- A saved install with existing profile/domain/tutorial evidence is treated as
  already welcomed, so an upgrade never forces the new Welcome screen on an
  established user.
- Legacy Core step IDs remain readable. Progress that already reached the old
  XP/RoadMap/Statistics continuation is normalized to completed Core v2 rather
  than restarting the user.
- Resetting or replaying tutorials does not reset Welcome. Debug/fresh-state
  tools may explicitly reset both when they intentionally simulate a new
  install.

## Ownership

| Area | Owner | Responsibility |
|---|---|---|
| Static module and step copy | `lib/tutorial/tutorial_catalog.dart` | Framework-free tutorial knowledge and legacy Core IDs. |
| Progression and normalization | `lib/tutorial/tutorial_coordinator.dart` | Pure compatibility, next-step, and default-Core policy. |
| Welcome copy | `lib/tutorial/welcome_copy.dart` | Central product copy without widget dependencies. |
| Welcome presentation | `lib/widgets/welcome_page.dart` | Responsive, accessible full-screen route and future action slots. |
| Target readiness | `lib/widgets/tutorial/tutorial_target_readiness.dart` | Shared mounted/layout probe with a wall-clock deadline and safe fallback. |
| Runtime sequencing | `lib/widgets/main_page/first_run_tutorial.dart` | Session-only phases, target presentation, focus, motion, and fallback mode. |
| Navigation binding | `lib/widgets/main_page/shell.dart` | Opens real workspaces/dialogs and advances only after the destination target is laid out. |
| Runtime facade | `lib/app_state.dart` | Public commands, current progress, persistence scheduling, and one final notification. |
| Profile module picker | `lib/widgets/profile_dialog.dart` | Compact replay/start/skip entry point for each module. |

The files in `lib/tutorial/` must not import Flutter, widgets, AppState, or
persistence. UI navigation and `GlobalKey` targets remain presentation-owned.

## Tutorial V3 Runtime

The session-only runtime has explicit phases: `idle`, `transitioning`,
`waitingForTarget`, `presenting`, `completing`, and `completed`. Only
`TutorialProgress` is persisted. Runtime phases never create another tutorial
state model and remain safe for legacy v2 progress.

Target readiness uses `TutorialTargetProbe`: mounted `RenderBox` state is
checked on layout events and short periodic probes, while a `1200ms` wall-clock
deadline bounds the wait. The deadline is not a visual delay and does not count
frames, so 60 Hz and high-refresh displays receive the same readiness window.
An unavailable target becomes a dismissible Coach Card instead of trapping the
user.

Navigation follows this order:

```text
CTA -> transitioning -> open real destination -> wait for laid-out target
    -> commit old step -> wait/present next step
```

The RoadMap chapter hides the old overlay while its workspace changes. The
Profile chapter opens the real Profile surface and completes from inline
guidance inside it. No arbitrary two-second delay or one-frame progression
callback owns navigation.

Tutorial v3 uses three presentation modes:

- `spotlight`: a real, current control such as `+ Навык`, `+ Квест`, or an
  available desktop `Минимальный шаг`;
- `coachCard`: a concept without a reliable control, including Minimum Action
  when current data has no such action;
- `inlineGuidance`: guidance inside real creation/Profile surfaces.

Active spotlight geometry is re-read after every real rendered frame, so
scrolling and resizing cannot leave a stale rectangle. Coach Cards use a light
scrim and avoid the spotlight `saveLayer`. `Escape` dismisses tutorial UI on
desktop. Reduced motion removes translation and uses the stable final state.

After the third Core acknowledgement, persisted Core progress is already
complete. A compact session-only banner says that optional topics are available
in Profile, dismisses automatically, and never requires a fourth continuation
action. It grants no XP, trophy, chest, or reward.

## Responsive And Accessibility Contract

- Welcome is scroll-safe at `360`, `393`, `430`, `700`, and desktop widths.
- Primary actions remain reachable at `1.0x`, `1.3x`, and `2.0x` text scale.
- The route and CTA have explicit semantics; decorative path art is excluded.
- Dark is the polished target and light uses the existing usable semantic
  tokens.
- Optional tutorial content remains dismissible when a target is unavailable.
- The Core completion banner is a live region but does not block the app.
- Coach/spotlight panels receive keyboard focus and support `Escape`.

## Future Slots

`WelcomePage` accepts optional header and secondary actions so a future locale
or account flow can be added without rebuilding the first-run composition.
Those controls are not rendered until localization or authentication actually
exists. No account, cloud, or locale state is introduced by this implementation.

## Verification

Automated coverage characterizes fresh/existing installs, persistence across
restart, recovery precedence, legacy progress normalization, Core data/XP
isolation, automatic non-blocking Core completion, independent optional
modules, wall-clock target readiness, RoadMap transition ordering, real Profile
inline completion, actual/fallback Minimum Action targeting, `Escape`,
responsive Welcome layout, reduced motion, and profile module selection.

Manual release QA should still verify Welcome and every tutorial module on a
real narrow Android device, desktop resizing, TalkBack/VoiceOver traversal,
keyboard focus, `2.0x` text scale, and dark/light themes.
