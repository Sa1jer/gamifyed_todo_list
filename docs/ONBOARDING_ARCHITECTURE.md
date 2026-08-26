# Welcome And Tutorial Architecture

Last updated: 2026-08-26

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
| Target readiness | `lib/widgets/tutorial/tutorial_target_readiness.dart` | Mounted/layout readiness with bounded frame retries and a dismissible fallback. |
| Runtime facade | `lib/app_state.dart` | Public commands, current progress, persistence scheduling, and one final notification. |
| Profile module picker | `lib/widgets/profile_dialog.dart` | Compact replay/start/skip entry point for each module. |

The files in `lib/tutorial/` must not import Flutter, widgets, AppState, or
persistence. UI navigation and `GlobalKey` targets remain presentation-owned.

## Timing And Motion

Tutorial target discovery does not use a wall-clock delay. The readiness widget
checks after layout frames, stops after a bounded number of attempts, and then
shows a safe fallback card if the target is absent in the current responsive
composition. Reduced motion removes non-essential Welcome and overlay movement;
it never hides the state transition itself.

## Responsive And Accessibility Contract

- Welcome is scroll-safe at `360`, `393`, `430`, `700`, and desktop widths.
- Primary actions remain reachable at `1.0x`, `1.3x`, and `2.0x` text scale.
- The route and CTA have explicit semantics; decorative path art is excluded.
- Dark is the polished target and light uses the existing usable semantic
  tokens.
- Optional tutorial content remains dismissible when a target is unavailable.

## Future Slots

`WelcomePage` accepts optional header and secondary actions so a future locale
or account flow can be added without rebuilding the first-run composition.
Those controls are not rendered until localization or authentication actually
exists. No account, cloud, or locale state is introduced by this implementation.

## Verification

Automated coverage characterizes fresh/existing installs, persistence across
restart, recovery precedence, legacy progress normalization, Core data/XP
isolation, independent optional modules, bounded target readiness, responsive
Welcome layout, reduced motion, and profile module selection.

Manual release QA should still verify Welcome and every tutorial module on a
real narrow Android device, desktop resizing, TalkBack/VoiceOver traversal,
keyboard focus, `2.0x` text scale, and dark/light themes.
